# class profile::ldap::server
class profile::ldap::server {
  include ::ldap::server

  firewall { '30 accept LDAP traffic':
    proto  => 'tcp',
    dport  => ['389', '636'],
    state  => ['NEW'],
    action => accept,
  }
}
