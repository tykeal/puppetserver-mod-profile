class profile::bacula::storage {
  include ::bacula::storage

  $port=hiera('bacula::director::port',9103)
  validate_integer($port)

  firewall { '060 accept bacula storage connections':
    proto  => 'tcp',
    port   => $port,
    state  => ['NEW'],
    action => 'accept'
  }

}
