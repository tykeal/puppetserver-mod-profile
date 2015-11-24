class profile::nexus {
  include ::profile::java
  include ::nexus

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
  $ssl_cert_name = hiera('nginx::ssl_cert_name')
  $ssl_cert_chain = hiera('nginx::ssl_cert_chain')

  $nexus_context = hiera('nexus::nexus_context', '/nexus')

  if ($nexus_context != '/') {
    $vhost_cfg_prepend = {
      'rewrite' => "^/$ ${nexus_context} permanent",
    }
    $add_nginx_location = true
  } else {
    $add_nginx_location = false
  }

  # Export the Nexus vhost
  @@nginx::resource::vhost { "nginx_nexus-${nexus_sitename}":
    ensure            => present,
    server_name       => [[$nexus_sitename,],],
    access_log        => "/var/log/nginx/nexus-${nexus_sitename}_access.log",
    error_log         => "/var/log/nginx/nexus-${nexus_sitename}_error.log",
    proxy             => "http://${::fqdn}:${nexus_port}",
    tag               => $nginx_export,
    ssl               => true,
    rewrite_to_https  => true,
    ssl_cert          => "/etc/pki/tls/certs/${ssl_cert_name}-${ssl_cert_chain}.pem",
    ssl_key           => "/etc/pki/tls/private/${ssl_cert_name}.pem",
    vhost_cfg_prepend => $vhost_cfg_prepend,
    proxy_set_header  => [
      'Host $host',
      'X-Real-IP $remote_addr',
      'X-Forwarded-For $proxy_add_x_forwarded_for',
      'X-Forwarded-Proto $scheme',
      'X-Forwarded-Port $server_port',
      'Accept-Encoding ""',
    ],
    add_header                    => {
      'Strict-Transport-Security' => 'max-age=1209600',
    },
  }

  if ($add_nginx_location) {
    @@nginx::resource::location { "nginx_nexus-${nexus_sitename}-context":
      ensure    => present,
      ssl       => true,
      ssl_only  => true,
      vhost     => "nginx_nexus-${nexus_sitename}",
      location  => $nexus_context,
      autoindex => 'off',
      proxy     => "http://${::fqdn}:${nexus_port}",
      tag       => $nginx_export,
    }
  }
}
