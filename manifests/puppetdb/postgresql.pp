class profile::puppetdb::postgresql {
  include ::puppetdb::database::postgresql

  firewall { '010 accept postgresql traffic':
    proto  => 'tcp',
    port   => '5432',
    state  => ['NEW'],
    action => accept,
  }
}
