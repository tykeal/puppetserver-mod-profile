class profile::gerrit {
  include ::gerrit

  # grab the gerrit configuration so we know what to do for nginx
  $gerrit_config = hiera('gerrit::override_options')
  validate_hash($gerrit_config)

  # we need to make sure that the canonicalWebUrl and listenUrl are set
  validate_string($gerrit_config['gerrit']['canonicalWebUrl'])
  validate_string($gerrit_config['httpd']['listenUrl'])

  $urlParser = '^(proxy-)?(http|https):\/\/(([a-z0-9]+[\-\.]{1}[a-z0-9]+*\.[a-z]{2,})|\*)(:([0-9]{1,5}))?(\/.*)?$'

  $sitename = regsubst($gerrit_config['gerrit']['canonicalWebUrl'], $urlParser, '\3', 'EI')
  $backend_listenport = regsubst($gerrit_config['httpd']['listenUrl'], $urlParser, '\6', 'EI')

  # assume that a) a suburl is being used and b) that it matches on the
  # listenUrl side
  $suburl = regsubst($gerrit_config['gerrit']['canonicalWebUrl'], $urlParser, '\7', 'EI')

  # need to load the SSL information so that it can be used
  $ssl_cert_name = hiera('nginx::ssl_cert_name')
  $ssl_cert_chain = hiera('nginx::ssl_cert_chain')
  $ssl_dhparam = hiera('nginx::ssl_dhparam')

  @@nginx::resource::vhost { "nginx_gerrit-${::fqdn}":
    ensure                        => present,
    server_name                   => [[$sitename,],],
    access_log                    => "/var/log/nginx/gerrit-${sitename}_access.log",
    error_log                     => "/var/log/nginx/gerrit-${sitename}_error.log",
    raw_append                    => "rewrite ^/\$ \$scheme://\$host${suburl}/;",
    autoindex                     => 'off',
    proxy                         => "http://${::fqdn}:${backend_listenport}",
    tag                           => hiera('nginx::exporttag'),
    ssl                           => true,
    ssl_cert                      => "/etc/pki/tls/certs/${ssl_cert_name}-${ssl_cert_chain}.pem",
    ssl_key                       => "/etc/pki/tls/private/${ssl_cert_name}.pem",
    ssl_dhparam                   => "/etc/pki/tls/certs/${ssl_dhparam}.pem",
    rewrite_to_https              => true,
    add_header                    => {
      'Strict-Transport-Security' => 'max-age=1209600'
      },
  }

  @@nginx::resource::location { "nginx_gerrit-${::fqdn}_${suburl}":
    ensure           => present,
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
