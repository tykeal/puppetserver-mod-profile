class profile::bacula::director {
  include ::bacula::director

  $port=hiera('bacula::director::port',9101)
  validate_integer($port)

  firewall { '060 accept bacula connections':
    proto  => 'tcp',
    port   => $port,
    state  => ['NEW'],
    action => 'accept'
  }
}
