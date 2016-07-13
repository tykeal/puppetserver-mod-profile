# class profile::ldap::server
class profile::ldap::server {
  include ::openldap::server

  $ldap_access = hiera_hash('openldap::server::access', undef)
  if (is_hash($ldap_access)) {
    create_resources('::openldap::server::access', $ldap_access)
  }

  $ldap_database = hiera_hash('openldap::server::database', undef)
  if (is_hash($ldap_database)) {
    create_resources('::openldap::server::database', $ldap_database)
  }

  $ldap_dbindex = hiera_hash('openldap::server::dbindex', undef)
  if (is_hash($ldap_dbindex)) {
    create_resources('::openldap::server::dbindex', $ldap_dbindex)
  }

  $ldap_globalconf = hiera_hash('openldap::server::globalconf', undef)
  if (is_hash($ldap_globalconf)) {
    create_resources('::openldap::server::globalconf', $ldap_globalconf)
  }

  $ldap_module = hiera_hash('openldap::server::module', undef)
  if (is_hash($ldap_module)) {
    create_resources('::openldap::server::module', $ldap_module)
  }

  $ldap_overlay = hiera_hash('openldap::server::overlay', undef)
  if (is_hash($ldap_overlay)) {
    create_resources('::openldap::server::overlay', $ldap_overlay)
  }

  $ldap_schema = hiera_hash('openldap::server::schema', undef)
  if (is_hash($ldap_schema)) {
    create_resource('::openldap::server::schema', $ldap_schema)
  }

  firewall { '30 accept LDAP traffic':
    proto  => 'tcp',
    dport  => ['389', '636'],
    state  => ['NEW'],
    action => accept,
  }
}
