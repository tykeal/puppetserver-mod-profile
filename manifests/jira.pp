# jira configuration
class profile::jira {
  # Jira requires java to be installed
  include ::profile::java
  include ::jira
  # Enable jira facts so that upgrades can be performed via puppet
  include ::jira::facts

  # Since we use MySQL in general in our environments we'll just assume
  # we're doing MySQL for now
  #
  # Require that the db{name,user,password} all be set in hiera or bomb
  $jira_dbname = hiera('jira::dbname')
  validate_string($jira_dbname)
  $jira_dbuser = hiera('jira::dbuser')
  validate_string($jira_dbuser)
  $jira_dbpassword = hiera('jira::dbpassword')
  validate_string($jira_dbpassword)

  # custom (required) variable for our environment
  $jira_dbtag = hiera('jira::dbtag')
  validate_string($jira_dbtag)

  @@::mysql::db { "${jira_dbname}_${::fqdn}":
    user     => $jira_dbuser,
    password => $jira_dbpassword,
    dbname   => $jira_dbname,
    host     => $::ipaddress,
    grant    => [ 'ALL' ],
    collate  => 'utf8_bin',
    tag      => $jira_dbtag,
  }

  # Extra db hosts if needed
  $extra_db_hosts = hiera('jira::extra_hosts', undef)
  if ($extra_db_hosts) {
    validate_array($extra_db_hosts)

    # Create extra database exports / mappings
    each($extra_db_hosts) |$conn_host| {
      @@mysql::db { "${jira_dbname}_${::fqdn}_${conn_host}":
        user     => $jira_dbuser,
        password => $jira_dbpassword,
        dbname   => $jira_dbname,
        host     => $conn_host,
        grant    => [ 'ALL' ],
        collate  => 'utf8_bin',
        tag      => $jira_dbtag,
      }
    }
  }

  Class['::java'] -> Class['::jira']

  # configure the firewall
  $jira_tomcat_port = hiera('jira::tomcatPort', 8080)
  validate_integer($jira_tomcat_port)

  firewall { '050 accept jira traffic':
    proto  => 'tcp',
    dport  => $jira_tomcat_port,
    state  => ['NEW'],
    action => accept,
  }

  $jira_native_ssl = hiera('jira::tomcatNativeSsl', false)
  validate_bool($jira_native_ssl)

  if ($jira_native_ssl) {
    $jira_tomcat_https_port = hiera('jira::tomcatHttpsPort', 8443)
    validate_integer($jira_tomcat_https_port)

    firewall { '050 accept jira HTTPS traffic':
      proto  => 'tcp',
      dport  => $jira_tomcat_https_port,
      state  => ['NEW'],
      action => accept,
    }
  }

  # export nginx bits if they are defined
  $nginx_export = hiera('nginx::exporttag', undef)
  if ($nginx_export)
  {
    validate_string($nginx_export)

    # default hsts to 180 days (SSLLabs recommended)
    $hsts_age = hiera('nginx::max-age', '15552000')

    $ssl_cert_name = hiera('nginx::ssl_cert_name', undef)
    $ssl_cert_chain = hiera('nginx::ssl_cert_chain', undef)
    $ssl_dhparam = hiera('nginx::ssl_dhparam', undef)

    if ($ssl_cert_name and $ssl_cert_chain) {
      $_ssl_cert = "/etc/pki/tls/certs/${ssl_cert_name}-${ssl_cert_chain}.pem"
      $_ssl_key = "/etc/pki/tls/private/${ssl_cert_name}.pem"
      $_ssl = true
      $_add_header = {
        'Strict-Transport-Security' => "max-age=${hsts_age}",
      }
    } else {
      $_ssl_cert = undef
      $_ssl_key = undef
      $_ssl = false
      $_add_header = undef
    }

    if ($ssl_dhparam) {
      $_ssl_dhparam = "/etc/pki/tls/certs/${ssl_dhparam}.pem"
    } else {
      $_ssl_dhparam = undef
    }

    $jira_proxy = hiera('jira::proxy')
    validate_hash($jira_proxy)

    $jira_sitename = $jira_proxy['proxyName']

    # Export the vhost
    @@nginx::resource::vhost { "nginx-${jira_sitename}":
      ensure             => present,
      server_name        => [[$jira_sitename,],],
      access_log         => "/var/log/nginx/jira-${jira_sitename}_access.log",
      error_log          => "/var/log/nginx/jira-${jira_sitename}_error.log",
      autoindex          => 'off',
      proxy              => "http://${::fqdn}:${jira_tomcatPort}",
      proxy_read_timeout => '300',
      rewrite_to_https   => $_ssl,
      ssl                => $_ssl,
      ssl_cert           => $_ssl_cert,
      ssl_key            => $_ssl_key,
      ssl_dhparam        => $_ssl_dhparam,
      tag                => $nginx_export,
      add_header         => {
        'proxy_redirect' => 'off',
      },
      proxy_set_header   => [
        'Host $host',
        'X-Real-IP $remote_addr',
        'X-Forwarded-For $proxy_add_x_forwarded_for',
        'X-Forwarded-Proto $scheme',
        'X-Forwarded-Port $server_port',
        'Accept-Encoding ""',
      ],
    }
  }
}

