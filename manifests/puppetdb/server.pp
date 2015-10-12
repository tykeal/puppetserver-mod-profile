class profile::puppetdb::server {
  include ::puppetdb::server

  firewall { '010 accept puppetdb traffic':
    proto  => 'tcp',
    dport  => '8081',
    state  => ['NEW'],
    action => accept,
  }
}
