class profile::mailman3 {
  include ::mailman3::core
  include ::mailman3::web

  # module is not complete, we are pulling in some
  # needed modules here in the meantime
  include ::profile::smtp
  include ::uwsgi

  $allowed_hosts = hiera('mailman3::web::allowed_hosts')
  validate_string($allowed_hosts)

  $port   = hiera('mailman3::web::uwsgi_port')
  validate_array($port)

  # firewall rule for mailman3-web

  firewall { '030 accept incoming uwsgi traffic':
    proto  => 'tcp',
    port   => $port,
    state  => ['NEW'],
    source => $allowed_hosts,
    action => accept,
  }
}
