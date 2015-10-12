class profile::totp::server {
  include ::totpcgi
  include ::totpcgi::client

  $port=hiera('totpcgi::port', 8443)
  validate_integer($port)

  firewall { '060 accept totp connections':
    proto  => 'tcp',
    dport  => $port,
    state  => ['NEW'],
    action => 'accept'
  }
}
