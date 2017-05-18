# Class: profile::nexus
class profile::nexus {
  include ::profile::java
  include ::nexus

  # install nexus plugins if needed
  $nexus_plugins = hiera('nexus::plugins', undef)

  if $nexus_plugins {
    validate_hash($nexus_plugins)
  #  create_resources('profile::nexus::third_party_plugin',
  #    $nexus_plugins)
  }

  # Nexus systems may, or may not host yum or apt repos
  # Let's make sure they have the required components to do so
  ensure_packages([
    'createrepo',
    'dpkg',
    'dpkg-dev',
    'dpkg-devel',
  ])

  # Nexus needs a special directory for setting lock files as well as
  # for where it stores the license information if it's a pro setup
  include ::nexus::params

  $nexus_root = hiera('nexus::nexus_root', $::nexus::params::nexus_root)
  $nexus_user = hiera('nexus::nexus_user', $::nexus::params::nexus_user)
  $nexus_group = hiera('nexus::nexus_group', $::nexus::params::nexus_group)

  # Make sure that the $nexus_root/.java directory exists and is owned by
  # Nexus. Nexus should be able to handle the rest of the setup
  file { "${nexus_root}/.java":
    ensure => directory,
    owner  => $nexus_user,
    group  => $nexus_group,
    mode   => '0770',
  }

  # The apt repo plugin for nexus is seriously flawed, or at least not working
  # correctly all the time. So, let's get a temporary solution put in place for
  # generating the repos for use with cron
  file { '/usr/local/bin/buildapt.sh':
    ensure => file,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    source => "puppet:///modules/${module_name}/nexus/buildapt.sh",
  }

  $nexus_port = hiera('nexus::nexus_port', 8081)
  validate_integer($nexus_port)

  firewall { '050 accept nexus traffic':
    proto  => 'tcp',
    dport  => $nexus_port,
    state  => ['NEW'],
    action => accept,
  }

  #######
  # NGINX CONFIGURATION
  #######
  $nexus_sitename = hiera('nginx::export::vhost')
  validate_string($nexus_sitename)

  $nginx_export = hiera('nginx::exporttag')
  validate_string($nginx_export)

  # need to load SSL information so that it can be used
  $ssl_cert_name = hiera('nginx::ssl_cert_name', undef)
  $ssl_cert_chain = hiera('nginx::ssl_cert_chain', undef)

  if ($ssl_cert_name and $ssl_cert_chain) {
    $_ssl_cert = "/etc/pki/tls/certs/${ssl_cert_name}-${ssl_cert_chain}.pem"
    $_ssl_key = "/etc/pki/tls/private/${ssl_cert_name}.pem"
    $_ssl = true

    # default hsts to 180 days (SSLLabs recommended)
    $hsts_age = hiera('nginx::max-age', '15552000')

    $_add_header = {
      'Strict-Transport-Security' => "max-age=${hsts_age}",
    }
  } else {
    $_ssl_cert = undef
    $_ssl = false
    $_add_header = undef
  }

  # we don't force all of our sites to use more secure dhparam settings
  # we should, but doing so now would break a lot of stuff!
  $ssl_dhparam = hiera('nginx::ssl_dhparam', undef)
  if ($ssl_dhparam) {
    $_ssl_dhparam = "/etc/pki/tls/certs/${ssl_dhparam}.pem"
  } else {
    $_ssl_dhparam = undef
  }

  $nexus_context = hiera('nexus::nexus_context', '/nexus')

  if ($nexus_context != '/') {
    $vhost_cfg_prepend = {
      'rewrite'            => "^/$ ${nexus_context} permanent",
      'proxy_send_timeout' => '120',
      'proxy_buffering'    => 'off',
      'keepalive_timeout'  => '5 5',
      'tcp_nodelay'        => 'on',
    }
    $add_nginx_location = true
  } else {
    $vhost_cfg_prepend = {
      'proxy_send_timeout' => '120',
      'proxy_buffering'    => 'off',
      'keepalive_timeout'  => '5 5',
      'tcp_nodelay'        => 'on',
    }
    $add_nginx_location = false
  }

  # Nexus artifacts tend to be semi large. We need to up the default
  # client_max_body_size from 10m to something more useful. 512m is a
  # good starting point
  #
  # Yes the hiera to internal variable doesn't match up, it's done on
  # purpose ;)
  $nginx_uploadlimit = hiera('nexus::upload_limit', '512m')

  # It's possible that we may end up needing to handle special case rewrite
  # rules. It would be great if we didn't have to, but such is life
  $nginx_rewrite_rules = hiera('nginx::rewrite_rules', [])

  # setup the proxy headers
  $proxy_set_header = [
    'Host $host',
    'X-Real-IP $remote_addr',
    'X-Forwarded-For $proxy_add_x_forwarded_for',
    'X-Forwarded-Proto $scheme',
    'X-Forwarded-Port $server_port',
    'Accept-Encoding ""',
  ]

  # Export the Nexus vhost
  @@nginx::resource::vhost { "nginx_nexus-${nexus_sitename}":
    ensure              => present,
    server_name         => [[$nexus_sitename,],],
    access_log          => "/var/log/nginx/nexus-${nexus_sitename}_access.log",
    error_log           => "/var/log/nginx/nexus-${nexus_sitename}_error.log",
    # flag ipv6 as enabled. This will enable if it is possible on the nginx host
    # side
    ipv6_enable         => true,
    ipv6_listen_options => '',
    proxy               => "http://${::fqdn}:${nexus_port}",
    proxy_set_header    => $proxy_set_header,
    ssl                 => $_ssl,
    rewrite_to_https    => $_ssl,
    ssl_cert            => $_ssl_cert,
    ssl_key             => $_ssl_key,
    ssl_dhparam         => $_ssl_dhparam,
    tag                 => $nginx_export,
    vhost_cfg_prepend   => $vhost_cfg_prepend,
    rewrite_rules       => $nginx_rewrite_rules,
    add_header          => $_add_header,
  }

  if ($add_nginx_location) {
    @@nginx::resource::location { "nginx_nexus-${nexus_sitename}-context":
      ensure             => present,
      ssl                => true,
      ssl_only           => true,
      vhost              => "nginx_nexus-${nexus_sitename}",
      location           => $nexus_context,
      autoindex          => 'off',
      priority           => 501,
      proxy              => "http://${::fqdn}:${nexus_port}",
      proxy_read_timeout => '300',
      tag                => $nginx_export,
    }
  }

  $content_location = $nexus_context ? {
    '/'     => '/content',
    default => "${nexus_context}/content",
  }

  $service_location = $nexus_context ? {
    '/'     => '/service/local',
    default => "${nexus_context}/service/local",
  }

  $increase_upload = {
    'client_max_body_size' => $nginx_uploadlimit,
  }

  @@nginx::resource::location { "nginx_nexus_${nexus_sitename}-content":
    ensure              => present,
    ssl                 => $_ssl,
    ssl_only            => $_ssl,
    vhost               => "nginx_nexus-${nexus_sitename}",
    location            => $content_location,
    autoindex           => 'off',
    priority            => 502,
    proxy               => "http://${::fqdn}:${nexus_port}",
    proxy_read_timeout  => '300',
    location_cfg_append => $increase_upload,
    tag                 => $nginx_export,
  }

  @@nginx::resource::location { "nginx_nexus_${nexus_sitename}-service":
    ensure              => present,
    ssl                 => $_ssl,
    ssl_only            => $_ssl,
    vhost               => "nginx_nexus-${nexus_sitename}",
    location            => $service_location,
    autoindex           => 'off',
    priority            => 502,
    proxy               => "http://${::fqdn}:${nexus_port}",
    proxy_read_timeout  => '300',
    location_cfg_append => $increase_upload,
    tag                 => $nginx_export,
  }

  # hosted docker registries have to run on their own ports
  $docker_ports = hiera_array('nexus::docker_ports', [])
  $docker_ports.each |String $docker_port| {
    @@nginx::resource::vhost { "nginx_nexus-docker-${nexus_sitename}-${docker_port}":
      ensure              => present,
      server_name         => [[$nexus_sitename,],],
      listen_port         => $docker_port,
      # if we have certs then we need to force the ssl port setting both to the
      # same will cause it to only server on SSL
      ssl_port            => $docker_port,
      access_log          => "/var/log/nexus-${nexus_sitename}-${docker_port}_access.log",
      error_log           => "/var/log/nexus-${nexus_sitename}-${docker_port}_error.log",
      # flag ipv6 as enabled. This will enable if it is possible on the nginx host
      # side
      ipv6_enable         => true,
      ipv6_listen_options => '',
      proxy               => "http://${::fqdn}:${docker_port}",
      proxy_set_header    => $proxy_set_header,
      ssl                 => $_ssl,
      rewrite_to_https    => $_ssl,
      ssl_cert            => $_ssl_cert,
      ssl_key             => $_ssl_key,
      ssl_dhparam         => $_ssl_dhparam,
      tag                 => $nginx_export,
      add_header          => $_add_header,
    }

    ::profile::firewall::rule { "Nexus docker port ${docker_port}":
      priority => '050',
      proto    => 'tcp',
      dport    => $docker_port,
      state    => ['NEW'],
      action   => 'accept',
    }
  }

  # Monitoring
  include ::nagios::params
  $nagios_plugin_dir = hiera('nagios_plugin_dir')

  $nagios_tag = hiera('nagios::client::nagiostag', '')
  $defaultserviceconfig = hiera('nagios::client::defaultserviceconfig',
    $::nagios::params::defaultserviceconfig)

  ::nagios::resource { "HTTP - Nexus - ${nexus_sitename}":
    resource_type      => 'service',
    defaultresourcedef => $defaultserviceconfig,
    nagiostag          => $nagios_tag,
    resourcedef        => {
      service_description => "HTTP - ${nexus_sitename}",
      # lint:ignore:80chars
      check_command       => "check_http!-p ${nexus_port} -u /index.html -s 'Sonatype Nexus'",
      # lint:endignore
    }
  }
}
