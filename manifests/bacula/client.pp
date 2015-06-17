class profile::bacula::client {
  include ::bacula::client

  $port=hiera('bacula::client::port',9102)
  validate_integer($port)

  firewall { '061 accept incoming bacula client traffic':
    proto  => 'tcp',
    port   => $port,
    state  => ['NEW'],
    action => accept,
  }

}
