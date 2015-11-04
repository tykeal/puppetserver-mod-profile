class profile::clm {
  include ::java
  include ::clm

  $clm_config = hiera('clm::clm_config', undef)
  if ($clm_config) {
    validate_hash($clm_config)
    if (has_key($clm_config, 'http')) {
      validate_hash($clm_config['http'])
      if (has_key($clm_config['http'], 'port')) {
        $clm_port = $clm_config['http']['port']
      } else {
        $clm_port = '8070'
      }
    } else {
      $clm_port = '8070'
    }
  } else {
    $clm_port = '8070'
  }

  firewall { '050 accept incoming traffic for CLM Server':
    proto  => 'tcp',
    dport  => [$clm_port],
    state  => ['NEW'],
    action => accept,
  }

  # nginx setup
  $export_nginx = hiera('clm::export_nginx', false)
  if ($export_nginx) {
    $ssl_cert_name = hiera('nginx::ssl_cert_name')
    $ssl_cert_chain = hiera('nginx::ssl_cert_chain')
    $ssl_dhparam = hiera('nginx::ssl_dhparam')
    $nginx_exporttag = hiera('nginx::exporttag')
    $clm_sitename = hiera('clm::sitename')

    @@nginx::resource::vhost { "nginx_clm-${clm_sitename}":
      ensure           => present,
      server_name      => [[$clm_sitename,],],
      access_log       => "/var/log/nginx/clm-${clm_sitename}_access.log",
      error_log        => "/var/log/nginx/clm-${clm_sitename}_error.log",
      rewrite_to_https => true,
      ssl              => true,
      # lint:ignore:80chars
      ssl_cert         => "/etc/pki/tls/certs/${ssl_cert_name}-${ssl_cert_chain}.pem",
      # lint:endignore
      ssl_key          => "/etc/pki/tls/private/${ssl_cert_name}.pem",
      ssl_dhparam      => "/etc/pki/tls/certs/${ssl_dhparam}.pem",
      autoindex        => 'off',
      proxy            => "http://${::fqdn}:${clm_port}",
      tag              => $nginx_exporttag,
    }
  }

  Class['::java'] ->
  Class['::clm']
}
