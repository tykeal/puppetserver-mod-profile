# class profile::ldap::client
class profile::ldap::client {
  include ::nsstools
  include ::openldap::client
}
