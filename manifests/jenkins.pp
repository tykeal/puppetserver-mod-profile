# == Class: profile::jenkins
#
# Defines the standard jenkins profile used
#
class profile::jenkins {
  include ::profile::java
  include ::jenkins

  # Make sure that the jenkins service is managed via the redhat
  # provider and not the detected systemd provider on EL7 systems
  Service <| tag == 'jenkins::service' |> {
    provider => 'redhat',
  }

  $jenkins_sitename = hiera('nginx::export::vhost')
  validate_string($jenkins_sitename)

  $jenkins_port = hiera('jenkins::port')
  # Validate that the port is non-priv and doesn't exceed max port num
  validate_integer($jenkins_port, 65535, 1024)

  $nginx_export = hiera('nginx::exporttag')
  validate_string($nginx_export)

  # This allows us to merge jenkins (using prefixes) under a single
  # vhost Any Jenkins that is being merged into a single vhost that is
  # not "managing" the vhost itself should set this to true in hiera and
  # MUST set a prefix
  $nginx_merged_vhost = hiera('nginx::export::merged_vhost', false)

  # need to load the SSL information so that it can be used
  $ssl_cert_name = hiera('nginx::ssl_cert_name')
  $ssl_cert_chain = hiera('nginx::ssl_cert_chain')

  # we don't force all of our sites to use more secure dhparam settings
  # we should, but doing so now would break a lot of stuff!
  $ssl_dhparam = hiera('nginx::ssl_dhparam', undef)
  if ($ssl_dhparam) {
    $_ssl_dhparam = "/etc/pki/tls/certs/${ssl_dhparam}.pem"
  } else {
    $_ssl_dhparam = undef
  }

  $jenkins_config = hiera('jenkins::config_hash')
  validate_hash($jenkins_config)

  if (has_key($jenkins_config, 'PREFIX') and
      has_key($jenkins_config['PREFIX'], 'value')) {
    $jenkins_prefix = $jenkins_config['PREFIX']['value']
    validate_string($jenkins_prefix)

    if $nginx_merged_vhost {
      $vhost_cfg_prepend = {
        'proxy_buffering' => 'off',
      }
    } else {
      $vhost_cfg_prepend = {
        'proxy_buffering' => 'off',
        'rewrite' => "^/$ ${jenkins_prefix} permanent",
      }
    }
  } else {
    # Merged vhosts MUST set a prefix
    if $nginx_merged_vhost {
      fail('Jenkins definitions flagged as merged MUST set a prefix')
    } else {
      $jenkins_prefix = false
      $vhost_cfg_prepend = {
        'proxy_buffering' => 'off',
      }
    }
  }

  @@nginx::resource::vhost { "nginx_jenkins-${jenkins_sitename}":
    ensure => 'absent',
  }

  # default hsts to 180 days (SSLLabs recommended)
  $hsts_age = hiera('nginx::max-age', '15552000')

  # Export the Jenkins vhost but only if nginx_merged_vhost is false
  unless ($nginx_merged_vhost) {
    @@nginx::resource::vhost { "nginx-${jenkins_sitename}":
      ensure            => present,
      server_name       => [[$jenkins_sitename,],],
      # lint:ignore:80chars
      access_log        => "/var/log/nginx/jenkins-${jenkins_sitename}_access.log",
      error_log         => "/var/log/nginx/jenkins-${jenkins_sitename}_error.log",
      # lint:endignore
      autoindex         => 'off',
      proxy             => "http://${::fqdn}:${jenkins_port}",
      tag               => $nginx_export,
      ssl               => true,
      rewrite_to_https  => true,
      # lint:ignore:80chars
      ssl_cert          => "/etc/pki/tls/certs/${ssl_cert_name}-${ssl_cert_chain}.pem",
      # lint:endignore
      ssl_key           => "/etc/pki/tls/private/${ssl_cert_name}.pem",
      ssl_dhparam       => $_ssl_dhparam,
      vhost_cfg_prepend => $vhost_cfg_prepend,
      proxy_set_header  => [
          'Host $host',
          'X-Real-IP $remote_addr',
          'X-Forwarded-For $proxy_add_x_forwarded_for',
          'X-Forwarded-Proto $scheme',
          'X-Forwarded-Port $server_port',
          'Accept-Encoding ""',
        ],
      add_header        => {
        'Strict-Transport-Security' => "max-age=${hsts_age}",
        },
    }
  }

  if ($jenkins_prefix) {
    @@nginx::resource::location { "nginx_jenkins-${jenkins_sitename}-prefix-${jenkins_prefix}":
      ensure           => present,
      ssl              => true,
      ssl_only         => true,
      vhost            => "nginx-${jenkins_sitename}",
      location         => $jenkins_prefix,
      autoindex        => 'off',
      proxy            => "http://${::fqdn}:${jenkins_port}",
      tag              => $nginx_export,
      proxy_set_header => [
          'Host $host',
          'X-Real-IP $remote_addr',
          'X-Forwarded-For $proxy_add_x_forwarded_for',
          'X-Forwarded-Proto $scheme',
          'X-Forwarded-Port $server_port',
          'Accept-Encoding ""',
        ],
    }
  }

  $groovy_loc = '/etc/jenkins'

  # jenkins configuration via groovy
  file { $groovy_loc:
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
    mode   => '0750',
  }

  # we need a location to store generated SSH keys for groovy
  file { "${groovy_loc}/.ssh":
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
    mode   => '0700',
  }

  # create a jenkins_admin ssh key set if one doesn't exist
  exec { 'Create jenkins_admin SSH key':
    path    => '/usr/bin',
    # lint:ignore:80chars
    command => "ssh-keygen -t rsa -N '' -f ${groovy_loc}/.ssh/jenkins_admin -C 'Local Jenkins Admin'",
    # lint:endignore
    creates => "${groovy_loc}/.ssh/jenkins_admin",
    require => File["${groovy_loc}/.ssh"],
  }

  $jenkins_auth = hiera('jenkins::auth')
  validate_string($jenkins_auth)

  # load in the needed hiera config for doing the auth setup
  case $jenkins_auth {
    'ldap':   {
                $jenkins_ldap = hiera('jenkins::ldap')
                validate_hash($jenkins_ldap)
              }
    default: { fail('Unknown jenkins::auth type') }
  }

  # for the present we will assume that all jenkins systems will use
  # the matrix authorization strategy
  $jenkins_matrix = hiera('jenkins::matrixstrategy')
  validate_hash($jenkins_matrix)

  # get the ssh auth setup script in place
  file { "${groovy_loc}/set_jenkins_admin_ssh.groovy":
    ensure => file,
    owner  => 'jenkins',
    group  => 'jenkins',
    source => "puppet:///modules/${module_name}/jenkins/set_jenkins_admin_ssh.groovy",
  }

  # put the auth setup groovy script down on system
  file { "${groovy_loc}/set_${jenkins_auth}_auth.groovy":
    ensure  => file,
    owner   => 'jenkins',
    group   => 'jenkins',
    content => template("${module_name}/jenkins/set_${jenkins_auth}_auth.groovy.erb"),
  }

  # our administrative credentials for jenkins (used after we've run
  # basic security setup)
  $jenkinsadmin = hiera('jenkins::admin')
  validate_string($jenkinsadmin)

  if (! $::jenkins_auth_needed) {
    # basic security has not yet been setup, this should be a one time
    # thing

    if ($jenkins_prefix) {
      $url_prefix = $jenkins_prefix
    } else {
      $url_prefix = ''
    }

    # ssh auth needs to be setup before security is executed
    profile::jenkins::run_groovy { 'set_jenkins_admin_ssh':
      use_auth    => false,
      # lint:ignore:80chars
      script_args => "${jenkinsadmin} `cat ${groovy_loc}/.ssh/jenkins_admin.pub`",
      # lint:endignore
      url_prefix  => $url_prefix,
      require     =>  [
                        File["${groovy_loc}/set_jenkins_admin_ssh.groovy"],
                        Exec['Create jenkins_admin SSH key'],
                      ],
    }

    profile::jenkins::run_groovy { "set_${jenkins_auth}_auth":
      use_auth   => false,
      url_prefix => $url_prefix,
      require    => [
                      File["${groovy_loc}/set_${jenkins_auth}_auth.groovy"],
                      Profile::Jenkins::Run_groovy['set_jenkins_admin_ssh'],
                    ],
    }

    # flag that we need auth from now on but only after our auth setting
    # has been done
    external_facts::fact { 'jenkins_auth_needed':
      require => Profile::Jenkins::Run_groovy["set_${jenkins_auth}_auth"],
    }
  }
  else {
    # we need too always reset that auth is needed for any runs after
    # the first one or the fact will get removed and the next puppet run
    # will try to start from scratch and fail (this time we have no
    # extra requirement on when the fact gets set
    external_facts::fact { 'jenkins_auth_needed': }
  }

  # Monitoring
  include ::nagios::params
  $nagios_plugin_dir = hiera('nagios_plugin_dir')

  $nagios_tag = hiera('nagios::client::nagiostag', '')
  $defaultserviceconfig = hiera('nagios::client::defaultserviceconfig',
    $::nagios::params::defaultserviceconfig)

  $jenkins_dir = hiera('nrpe::jenkins_dir', '/var/lib/jenkins')
  validate_string($jenkins_dir)

  # Check Jenkins Process exists
  # NOTE: Upstream Jenkins module does not currently support moving the
  # Jenkins homedir.
  nrpe::command { 'check_jenkins_process':
    command => "${nagios_plugin_dir}/check_procs -c 1:1 -C java --argument-array='-DJENKINS_HOME=${jenkins_dir}'"
  }

  ::nagios::resource { "NRPE-Jenkins-Process-${::fqdn}":
    resource_type      => 'service',
    defaultresourcedef => $defaultserviceconfig,
    nagiostag          => $nagios_tag,
    resourcedef        => {
      service_description => 'NRPE - Jenkins Process',
      check_command       => 'check_nrpe!check_jenkins_process',
    },
  }

  $jenkins_dir_warn = hiera('nrpe::jenkins_dir_warn', 15)
  $jenkins_dir_crit = hiera('nrpe::jenkins_dir_crit', 5)
  validate_integer($jenkins_dir_warn)
  validate_integer($jenkins_dir_crit)

  # Check Jenkins is not filling up disk
  nrpe::command { 'check_jenkins_disk_space':
    command => "${nagios_plugin_dir}/check_disk -M -w ${jenkins_dir_warn}% -c ${jenkins_dir_crit}% ${jenkins_dir}"
  }

  ::nagios::resource { "NRPE-Jenkins-Home-Disk-Space-${::fqdn}":
    resource_type      => 'service',
    defaultresourcedef => $defaultserviceconfig,
    nagiostag          => $nagios_tag,
    resourcedef        => {
      service_description => "NRPE - ${jenkins_dir} disk space",
      check_command       => 'check_nrpe!check_jenkins_disk_space',
    },
  }

  if ($jenkins_prefix) {
    $jenkins_nagios_url = $jenkins_prefix
  } else {
    $jenkins_nagios_url = '/'
  }

  # Check Jenkins can be reached by HTTP on the network
  ::nagios::resource { "HTTP-Jenkins-${::fqdn}":
    resource_type      => 'service',
    defaultresourcedef => $defaultserviceconfig,
    nagiostag          => $nagios_tag,
    resourcedef        => {
      service_description => 'HTTP - Jenkins Web UI',
      check_command       => "check_http!-p ${jenkins_port} -u ${jenkins_nagios_url} 'Jenkins'",
    },
  }

  # Jenkins systems running nodepool have to run a ZMQ event publisher. This
  # defaults to port 8888. In any case, with or without ZMQ we're going to open
  # the port
  $zmqport = hiera('jenkins::zmqport', 8888)
  validate_integer($zmqport)

  firewall { '550 accept Jenkins ZMQ traffic':
    proto  => 'tcp',
    dport  => $zmqport,
    state  => ['NEW'],
    action => accept,
  }
}
