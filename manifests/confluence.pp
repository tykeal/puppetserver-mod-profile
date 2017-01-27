# class profile::confluence
class profile::confluence {
  include ::profile::java
  include ::mysql_java_connector
  include ::confluence

  # Make sure that java gets setup before confluence
  Class['::profile::java'] ->
  Class['::mysql_java_connector'] ->
  Class['::confluence']

  # Confluence refuses to start if the mysql_java_connector is a symlink, we can
  # To work around this we forcibly copy the installed connector into the
  # correct place

  # no default version as the confluence module requires the version be set
  $confluence_version = hiera('confluence::version')

  # grab the mysql_java_connector variables directly out of the class as it's
  # the only way to sanely acquire it since they don't use a params class :(
  $mysql_java_connector_version = $::mysql_java_connector::version
  $mysql_java_connector_install_dir = $::mysql_java_connector::installdir

  # lint:ignore:80chars
  file { "/opt/confluence/atlassian-confluence-${confluence_version}/confluence/WEB-INF/lib/mysql-connector-java-${mysql_java_connector_version}-bin.jar":
    ensure => file,
    source => "${mysql_java_connector_install_dir}/mysql-connector-java-${mysql_java_connector_version}/mysql-connector-java-${mysql_java_connector_version}-bin.jar",
    notify => Service['confluence'],
  }
  # lint:endignore

  $confluence_port = hiera('confluence::tomcat_port', '8090')
  validate_integer($confluence_port, 65535, 1024)

  # Export an nginx site if we need to
  $nginx_export = hiera('nginx::exporttag', undef)
  if ($nginx_export and is_string($nginx_export)) {
    # Get the site name. This is a required parameter if exporting nginx
    $confluence_sitename = hiera('nginx::export::vhost')
    validate_string($confluence_sitename)

    # default hsts to 180 days (SSLLabs recommended)
    $hsts_age = hiera('nginx::max-age', '15552000')

    # optional nginx customizations
    $nginx_customizations = hiera('nginx::customization', undef)

    # need to load the SSL information so that it can be used
    $ssl_cert_name = hiera('nginx::ssl_cert_name', undef)
    $ssl_cert_chain = hiera('nginx::ssl_cert_chain', undef)

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

    # we don't force all of our sites to use more secure dhparam settings
    # we should, but doing so now would break a lot of stuff!
    $ssl_dhparam = hiera('nginx::ssl_dhparam', undef)
    if ($ssl_dhparam) {
      $_ssl_dhparam = "/etc/pki/tls/certs/${ssl_dhparam}.pem"
    } else {
      $_ssl_dhparam = undef
    }

    # nginx site configuration
    $nginx_configuration = {
      "confluence-${confluence_sitename}" => {
        ensure           => present,
        server_name      => [[$confluence_sitename,],],
        # lint:ignore:80chars
        access_log       => "/var/log/nginx/confluence-${confluence_sitename}_access.log",
        error_log        => "/var/log/nginx/confluence-${confluence_sitename}_error.og",
        # lint:endignore
        autoindex        => 'off',
        proxy            => "http://${::fqdn}:${confluence_port}",
        tag              => $nginx_export,
        ssl              => $_ssl,
        rewrite_to_https => $_ssl,
        ssl_cert         => $_ssl_cert,
        ssl_key          => $_ssl_key,
        ssl_dhparam      => $_ssl_dhparam,
        proxy_set_header => [
            'Host $host',
            'X-Real-IP $remote_addr',
            'X-Forwarded-For $proxy_add_x_forwarded_for',
            'X-Forwarded-Proto $scheme',
            'X-Forwarded-Port $server_port',
            'Accept-Encoding ""',
          ],
        add_header       => $_add_header,
      },
    }

    # if there are any nginx customizations we need them now
    if ($nginx_customizations) {
      if is_hash($nginx_customizations) {
        $_nginx_customization = $nginx_customizations
      } else {
        $_nginx_customization = {}
      }
    } else {
      $_nginx_customization = {}
    }

    # export the nginx vhost
    $nginx_configuration.each |$resource, $options| {
      @@nginx::resource::vhost { $resource:
        * =>  $_nginx_customization + $nginx_configuration
    }
  }

  # Database setup
  $db_settings = hiera('confluence::db_settings', undef)
  if ($db_settings) {
    validate_hash($db_settings)

    validate_string($db_settings['db_tag'])
    validate_string($db_settings['database'])
    validate_string($db_settings['username'])
    validate_string($db_settings['password'])

    # export the database configuration
    @@::mysql::db { "${db_settings['database']}_${::fqdn}":
      user     => $db_settings['username'],
      password => $db_settings['password'],
      dbname   => $db_settings['database'],
      host     => $::ipaddress,
      grant    => [ 'ALL' ],
      collate  => 'utf8_bin',
      tag      => $db_settings['db_tag'],
    }

    # Create extra DB exports / mappings if needed
    if (has_key($db_settings, 'extra_db_hosts')) {
      validate_hash($db_settings['extra_db_hosts'])

      each($db_settings['extra_db_hosts']) |$conn_host| {
        @@mysql::db { "${db_settings['database']}_${::fqdn}_${conn_host}":
          user     => $db_settings['username'],
          password => $db_settings['password'],
          dbname   => $db_settings['database'],
          host     => $::ipaddress,
          grant    => [ 'ALL' ],
          collate  => 'utf8_bin',
          tag      => $db_settings['db_tag'],
        }
      }
    }
  }

  ::profile::firewall::rule { 'accept incoming confluence traffic':
    priority => '500',
    proto    => 'tcp',
    dport    => $confluence_port,
    state    => ['NEW'],
    action   => accept,
  }
}
