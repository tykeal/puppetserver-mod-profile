# Class profile::gerrit
class profile::gerrit {
  include ::profile::java
  include ::profile::git

  include ::gerrit

  # grab the gerrit configuration so we know what to do for nginx
  $gerrit_config = hiera('gerrit::override_options')
  validate_hash($gerrit_config)

  # Export any additional mysql hosts if they exists
  $extra_db_hosts = hiera('gerrit::extra_hosts', undef)
  if ($extra_db_hosts) {
    validate_array($extra_db_hosts)

    if (has_key($gerrit_config, 'database')) {
      if (has_key($gerrit_config['database'], 'database')) {
        $db_name = $gerrit_config['database']['database']
      }
      else
      {
        fail('No database name defined')
      }

      if (has_key($gerrit_config['database'], 'username')) {
        $db_user = $gerrit_config['database']['username']
      }
      else
      {
        fail('No database user defined')
      }
    }
    else
    {
      fail('Extra DB hosts defined but no database configuration defined')
    }

    $gerrit_secure_config = hiera('gerrit::override_secure_options')
    validate_hash($gerrit_secure_config)

    if (has_key($gerrit_secure_config, 'database')) {
      if (has_key($gerrit_secure_config['database'], 'password')) {
        $db_pass = $gerrit_secure_config['database']['password']
      }
      else
      {
        fail('No database password defined')
      }
    }
    else
    {
      # lint:ignore:80chars
      fail('Extra DB hosts defined but no secure database configuration defined')
      # lint:endignore
    }

    $db_tag = hiera('gerrit::db_tag', '')

    # Create extra database exports / mappings
    each($extra_db_hosts) |$conn_host| {
      @@mysql::db { "${db_name}_${::fqdn}_${conn_host}":
        user     => $db_user,
        password => $db_pass,
        dbname   => $db_name,
        host     => $conn_host,
        grant    => [ 'ALL' ],
        tag      => $db_tag,
      }
    }
  }

  # we need to make sure that the canonicalWebUrl and listenUrl are set
  validate_string($gerrit_config['gerrit']['canonicalWebUrl'])
  validate_string($gerrit_config['httpd']['listenUrl'])

  # lint:ignore:80chars
  $urlParser = '^(proxy-)?(http|https):\/\/(([a-z0-9]+[\-\.]{1}[a-z0-9]+*\.[a-z]{2,})|\*)(:([0-9]{1,5}))?(\/.*)?$'
  # lint:endignore

  $sitename = regsubst($gerrit_config['gerrit']['canonicalWebUrl'],
    $urlParser, '\3', 'EI')
  $backend_listenport = regsubst($gerrit_config['httpd']['listenUrl'],
    $urlParser, '\6', 'EI')

  # assume that a) a suburl is being used and b) that it matches on the
  # listenUrl side
  $suburl = regsubst($gerrit_config['gerrit']['canonicalWebUrl'],
    $urlParser, '\7', 'EI')

  $nginx_export_vhost = hiera('nginx::export_vhost', true)
  validate_bool($nginx_export_vhost)

  if ($nginx_export_vhost) {
    # need to load the SSL information so that it can be used
    $ssl_cert_name = hiera('nginx::ssl_cert_name')
    $ssl_cert_chain = hiera('nginx::ssl_cert_chain')
    $ssl_dhparam = hiera('nginx::ssl_dhparam')

    # default hsts to 180 days (SSLLabs recommended)
    $hsts_age = hiera('nginx::max-age', '15552000')
    @@nginx::resource::vhost { "nginx_gerrit-${::fqdn}":
      # lint:ignore:arrow_alignment
      ensure                        => present,
      server_name                   => [[$sitename,],],
      # lint:ignore:80chars
      access_log                    => "/var/log/nginx/gerrit-${sitename}_access.log",
      error_log                     => "/var/log/nginx/gerrit-${sitename}_error.log",
      # lint:endignore
      raw_append                    => "rewrite ^/\$ \$scheme://\$host${suburl}/;",
      autoindex                     => 'off',
      proxy                         => "http://${::fqdn}:${backend_listenport}",
      tag                           => hiera('nginx::exporttag'),
      ssl                           => true,
      # lint:ignore:80chars
      ssl_cert                      => "/etc/pki/tls/certs/${ssl_cert_name}-${ssl_cert_chain}.pem",
      ssl_key                       => "/etc/pki/tls/private/${ssl_cert_name}.pem",
      # lint:endignore
      ssl_dhparam                   => "/etc/pki/tls/certs/${ssl_dhparam}.pem",
      rewrite_to_https              => true,
      add_header                    => {
      # lint:endignore
        'Strict-Transport-Security' => "max-age=${hsts_age}",
        },
    }

    @@nginx::resource::location { "nginx_gerrit-${::fqdn}_${suburl}":
      ensure           => present,
      ssl              => true,
      ssl_only         => true,
      vhost            => "nginx_gerrit-${::fqdn}",
      location         => $suburl,
      proxy            => "http://${::fqdn}:${backend_listenport}",
      tag              => hiera('nginx::exporttag'),
      proxy_set_header => [
          'X-Forwarded-For $proxy_add_x_forwarded_for',
          'Host $host',
        ],
    }
  }

  # Monitoring
  include ::nagios::params

  $nagios_plugin_dir = hiera('nagios_plugin_dir')
  $nagios_tag = hiera('nagios::client::nagiostag', '')
  $defaultserviceconfig = hiera('nagios::client::defaultserviceconfig',
    $::nagios::params::defaultserviceconfig)

  if ( has_key($gerrit_config, 'sshd') ) {
    if ( has_key($gerrit_config['sshd'], 'listenAddress') ) {
      validate_string($gerrit_config['sshd']['listenAddress'])
      $git_port_expr = '^.*:([0-9]{1,5})$'
      $git_port = regsubst($gerrit_config['sshd']['listenAddress'],
        $git_port_expr, '\1', 'EI')
    } else {
      # default port
      $git_port = 29418
    }
  } else {
    # default port
    $git_port = 29418
  }

  # Verify the Gerrit SSH/git service is responding
  # NOTE: This is not testing any reverse proxy configuration!
  ::nagios::resource { "Gerrit-SSH-Status-${::fqdn}":
    # lint:ignore:arrow_alignment
    resource_type         => 'service',
    defaultresourcedef    => $defaultserviceconfig,
    nagiostag             => $nagios_tag,
    resourcedef           => {
    # lint:endignore
      service_description => 'Gerrit SSH - git Status',
      check_command       => "check_ssh!-t 30 -p ${git_port}",
    },
  }

  # Verify that Gerrit's webUI is responding
  # NOTE: This is not testing any reverse proxy configuration!
  ::nagios::resource { "Gerrit-WebUI-Status-${::fqdn}":
    # lint:ignore:arrow_alignment
    resource_type         => 'service',
    defaultresourcedef    => $defaultserviceconfig,
    nagiostag             => $nagios_tag,
    resourcedef           => {
    # lint:endignore
      service_description => 'Gerrit WebUI',
      # lint:ignore:80chars
      check_command       => "check_http!-p ${backend_listenport} -u ${suburl}/#q/status:open,n,z -s 'Gerrit Code Review'",
      # lint:endignore
    },
  }

  # Create ssh user key for gerrit user
  include ::gerrit::params
  $gerrit_user  = hiera('gerrit::gerrit_user', $::gerrit::params::gerrit_user)
  $gerrit_group = hiera('gerrit::gerrit_group', $::gerrit::params::gerrit_group)
  $gerrit_home  = hiera('gerrit::gerrit_home', $::gerrit::params::gerrit_home)

  exec { "Create ${gerrit_user} user SSH key":
    path    => '/usr/bin',
    # lint:ignore:80chars
    command => "ssh-keygen -t rsa -N '' -C '${gerrit_user}@${::fqdn}' -f ${gerrit_home}/.ssh/id_rsa",
    # lint:endignore
    creates => "${gerrit_home}/.ssh/id_rsa",
    user    => $gerrit_user,
    require => [ File["${gerrit_home}/.ssh"], Class['gerrit'] ],
  }

  $grok_enable = hiera('gerrit::grokmirror::enable', false)
  validate_bool($grok_enable)

  if $grok_enable {
    include ::profile::gerrit::grokmirror
  }
}
