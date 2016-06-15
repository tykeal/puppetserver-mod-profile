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

  # Force nexus service to use old redhat service provider
  Service <| tag == 'nexus::service' |> {
    provider => 'redhat',
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

  if (is_string($ssl_cert_name) and is_string($ssl_cert_chain)) {
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
      'rewrite' => "^/$ ${nexus_context} permanent",
    }
    $add_nginx_location = true
  } else {
    $add_nginx_location = false
  }

  # Nexus artifacts tend to be semi large. We need to up the default
  # client_max_body_size from 10m to something more useful. 512m is a
  # good starting point
  #
  # Yes the hiera to internal variable doesn't match up, it's done on
  # purpose ;)
  $nginx_uploadlimit = hiera('nexus::upload_limit', '512m')

  # default hsts to 180 days (SSLLabs recommended)
  $hsts_age = hiera('nginx::max-age', '15552000')

  # It's possible that we may end up needing to handle special case rewrite
  # rules. It would be great if we didn't have to, but such is life
  $nginx_rewrite_rules = hiera('nginx::rewrite_rules', [])

  # Export the Nexus vhost
  @@nginx::resource::vhost { "nginx_nexus-${nexus_sitename}":
    ensure            => present,
    server_name       => [[$nexus_sitename,],],
    access_log        => "/var/log/nginx/nexus-${nexus_sitename}_access.log",
    error_log         => "/var/log/nginx/nexus-${nexus_sitename}_error.log",
    proxy             => "http://${::fqdn}:${nexus_port}",
    proxy_set_header  => [
      'Host $host',
      'X-Real-IP $remote_addr',
      'X-Forwarded-For $proxy_add_x_forwarded_for',
      'X-Forwarded-Proto $scheme',
      'X-Forwarded-Port $server_port',
      'Accept-Encoding ""',
    ],
    ssl               => $_ssl,
    rewrite_to_https  => $_ssl,
    ssl_cert          => $_ssl_cert,
    ssl_key           => $_ssl_key,
    ssl_dhparam       => $_ssl_dhparam,
    tag               => $nginx_export,
    vhost_cfg_prepend => $vhost_cfg_prepend,
    rewrite_rules     => $nginx_rewrite_rules,
    add_header        => $_add_header,
  }

  if ($add_nginx_location) {
    @@nginx::resource::location { "nginx_nexus-${nexus_sitename}-context":
      ensure    => present,
      ssl       => true,
      ssl_only  => true,
      vhost     => "nginx_nexus-${nexus_sitename}",
      location  => $nexus_context,
      autoindex => 'off',
      priority  => 501,
      proxy     => "http://${::fqdn}:${nexus_port}",
      tag       => $nginx_export,
    }
  }

  $content_location = $nexus_context ? {
    '/'     => '/content',
    default => "${nexus_context}/content",
  }

  $staging_location = $nexus_context ? {
    '/'     => '/service/local/staging',
    default => "${nexus_context}/service/local/staging",
  }

  $increase_upload = {
    'client_max_body_size' => $nginx_uploadlimit,
  }

  @@nginx::resource::location { "nginx_nexus_${nexus_sitename}-content":
    ensure              => present,
    ssl                 => true,
    ssl_only            => true,
    vhost               => "nginx_nexus-${nexus_sitename}",
    location            => $content_location,
    autoindex           => 'off',
    priority            => 502,
    proxy               => "http://${::fqdn}:${nexus_port}",
    location_cfg_append => $increase_upload,
    tag                 => $nginx_export,
  }

  @@nginx::resource::location { "nginx_nexus_${nexus_sitename}-staging":
    ensure              => present,
    ssl                 => true,
    ssl_only            => true,
    vhost               => "nginx_nexus-${nexus_sitename}",
    location            => $staging_location,
    autoindex           => 'off',
    priority            => 502,
    proxy               => "http://${::fqdn}:${nexus_port}",
    location_cfg_append => $increase_upload,
    tag                 => $nginx_export,
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
