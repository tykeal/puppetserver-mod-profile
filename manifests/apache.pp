# class profile::apache
class profile::apache {
  include ::apache

  # Vhosts
  $vhosts = hiera('apache::vhosts', {})
  validate_hash($vhosts)
  create_resources('apache::vhost', $vhosts)

  # for now until we come up with a way to nicely read out all the ports
  # we listen on, we'll just automatically open 80 & 443
  firewall { '030 accept incoming HTTP and HTTPS traffic':
    proto  => 'tcp',
    dport  => ['80', '443'],
    state  => ['NEW'],
    action => accept,
  }

  # since our apache systems are usually hosting DB connected apps,
  # make sure they can connect to DBs
  selboolean { 'httpd_can_network_connect_db':
    persistent => true,
    value      => on,
  }

  # export resources for an upstream nginx reverse proxy, but only if there is a
  # export tag defined
  $nginx_export = hiera('nginx::exporttag', undef)
  if is_string($nginx_export) {
    # ssl info, this assumes that if there are multiple sites that they all
    # share the same cert (splat certs)
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

    $ssl_dhparam = hiera('nginx::ssl_dhparam', undef)
    if ($ssl_dhparam) {
      $_ssl_dhparam = "/etc/pki/tls/certs/${ssl_dhparam}.pem"
    } else {
      $_ssl_dhparam = undef
    }


    # export the nginx vhost for all sites defined
    each(keys($vhosts)) |$site| {
      # assume that $site is the servername
      if has_key($vhosts[$site], 'servername') {
        $_servername = $vhosts[$site]['servername']
      } else {
        $_servername = $site
      }

      if has_key($vhosts[$site], 'port') {
        $_port = $vhosts[$site]['port']
      } else {
        $_port = '80'
      }

      @@nginx::resource::vhost { "apache-${site}":
        ensure           => present,
        server_name      => $_servername,
        access_log       => "/var/log/nginx/${_servername}_access.log",
        error_log        => "/var/log/nginx/${_servername}_error.log",
        autoindex        => 'off',
        proxy            => "http://${::fqdn}:${_port}",
        proxy_set_header => [
            'Host $host',
            'X-Real-IP $remote_addr',
            'X-Forwarded-For $proxy_add_x_forwarded_for',
            'X-Forwarded-Proto $scheme',
            'X-Forwarded-Port $server_port',
            'Accept-Encoding ""',
          ],
        ssl              => $_ssl,
        rewrite_to_https => $_ssl,
        ssl_cert         => $_ssl_cert,
        ssl_key          => $_ssl_key,
        ssl_dhparam      => $_ssl_dhparam,
        add_header       => $_add_header,
      }
    }
  }
}
