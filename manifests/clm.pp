# class profile::clm
class profile::clm {
  include ::profile::java
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
    $nginx_exporttag = hiera('nginx::exporttag')
    $clm_sitename = hiera('clm::sitename')

    # CLM scans are usually rather small, but some of our projects are getting
    # large enough that they run into upload limit problems. Let's set a global
    # default to 100m for CLM and then make it so we can tune it if needed
    $nginx_uploadlimit = hiera('clm::upload_limit', '100m')

    $location_cfg_append = {
      'client_max_body_size' => $nginx_uploadlimit,
    }

    # configure vhost options similar to nexus
    $vhost_cfg_prepend = {
      'proxy_send_timeout' => '120',
      'proxy_buffering'    => 'off',
      'keepalive_timeout'  => '5 5',
      'tcp_nodelay'        => 'on',
    }

    # default hsts to 180 days (SSLLabs recommended)
    $hsts_age = hiera('nginx::max-age', '15552000')

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

    @@nginx::resource::vhost { "nginx_clm-${clm_sitename}":
      ensure              => present,
      server_name         => [[$clm_sitename,],],
      access_log          => "/var/log/nginx/clm-${clm_sitename}_access.log",
      error_log           => "/var/log/nginx/clm-${clm_sitename}_error.log",
      # flag ipv6 as enabled. This will enable it if possible on the nginx
      # host side
      ipv6_enable         => true,
      ipv6_listen_options => '',
      location_cfg_append => $location_cfg_append,
      ssl                 => $_ssl,
      rewrite_to_https    => $_ssl,
      ssl_cert            => $_ssl_cert,
      ssl_key             => $_ssl_key,
      ssl_dhparam         => $_ssl_dhparam,
      autoindex           => 'off',
      vhost_cfg_prepend   => $vhost_cfg_prepend
      proxy               => "http://${::fqdn}:${clm_port}",
      # Sonatype suggests setting at least 600 timeout for CLM
      proxy_read_timeout  => '600',
      tag                 => $nginx_exporttag,
    }
  }

  Class['::java']
  -> Class['::clm']
}
