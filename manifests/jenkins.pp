class profile::jenkins {
  include ::jenkins

  $jenkins_sitename = hiera('nginx::export::vhost')
  validate_string($jenkins_sitename)

  $jenkins_port = hiera('jenkins::port')
  # we would validate_string here but apparently we end up with a fixnum
  # instead of a string for the port value which fails validation. As
  # there is no validate_integer or validate_numeric of any type we're
  # just going to have to go a different route
  if ( ! is_integer($jenkins_port) ) {
    fail ("jenkins port value '${jenkins_port}' is not an integer")
  }

  $nginx_export = hiera('nginx::exporttag')
  validate_string($nginx_export)

  # need to load the SSL information so that it can be used
  $ssl_cert_name = hiera('nginx::ssl_cert_name')
  $ssl_cert_chain = hiera('nginx::ssl_cert_chain')

  # Export the Jenkins vhost
  @@nginx::resource::vhost { "nginx_jenkins-${::fqdn}":
    ensure                          => present,
    server_name                     => [[$jenkins_sitename,],],
    access_log                      => "/var/log/nginx/jenkins-${jenkins_sitename}_access.log",
    error_log                       => "/var/log/nginx/jenkins-${jenkins_sitename}_error.log",
    autoindex                       => 'off',
    proxy                           => "http://${::fqdn}:${jenkins_port}",
    tag                             => $nginx_export,
    ssl                             => true,
    ssl_cert                        => "/etc/pki/tls/certs/${ssl_cert_name}-${ssl_cert_chain}.pem",
    ssl_key                         => "/etc/pki/tls/private/${ssl_cert_name}.pem",
    rewrite_to_https                => true,
    add_header                      => {
        'Strict-Transport-Security' => 'max-age=1209600',
      },
    proxy_set_header                => [
      'Host $host',
      'X-Real-IP $remote_addr',
      'X-Forwarded-For $proxy_add_x_forwarded_for',
      'X-Forwarded-Proto $scheme',
      'X-Forwarded-Port $server_port',
      'Accept-Encoding ""',
      ],
    vhost_cfg_prepend               => {
       'proxy_buffering' => 'off',
      },
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
    command => "ssh-keygen -t rsa -N '' -f ${groovy_loc}/.ssh/jenkins_admin -C 'Local Jenkins Admin'",
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
    default: { fail("Unknown jenkins::auth type") }
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

    # ssh auth needs to be setup before security is executed
    profile::jenkins::run_groovy { 'set_jenkins_admin_ssh':
      use_auth    => false,
      script_args => "${jenkinsadmin} `cat ${groovy_loc}/.ssh/jenkins_admin.pub`",
      require     =>  [
                        File["${groovy_loc}/set_jenkins_admin_ssh.groovy"],
                        Exec['Create jenkins_admin SSH key'],
                      ],
    }

    profile::jenkins::run_groovy { "set_${jenkins_auth}_auth":
      use_auth => false,
      require  => [
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
}
