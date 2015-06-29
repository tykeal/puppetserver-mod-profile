class profile::bacula::storage {
  include ::bacula::storage

  $port=hiera('bacula::storage::port',9103)
  validate_integer($port)

  $bacula_pools = hiera_hash('bacula::pool', undef)
  if is_hash($bacula_pools) {
    create_resources('@@bacula::director::pool', $bacula_pools)
  }

  firewall { '060 accept bacula storage connections':
    proto  => 'tcp',
    port   => $port,
    state  => ['NEW'],
    action => 'accept'
  }

}
