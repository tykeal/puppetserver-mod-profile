class profile::bacula::client {
  include ::bacula::client

  $port=hiera('bacula::client::port',9102)
  validate_integer($port)

  $bacula_jobs = hiera('bacula::job', undef)
  if is_hash($bacula_jobs) {
    create_resources(::bacula::job, $bacula_jobs)
  }

  firewall { '061 accept incoming bacula client traffic':
    proto  => 'tcp',
    port   => $port,
    state  => ['NEW'],
    action => accept,
  }

}
