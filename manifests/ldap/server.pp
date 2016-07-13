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
    create_resources('::openldap::server::schema', $ldap_schema)
  }

  # deploy custom schemas
  $custom_schema = hiera_hash('openldap::server:schema::definition', undef)
  if (is_hash($custom_schema)) {
    $custom_schema.each |$schema_name, $schema| {
      if has_key($schema, 'content') {
        # lint:ignore:variable_scope
        $_content = $schema['schema']
        # lint:endignore
      } else {
        $_content = undef
      }

      if has_key($schema, 'source') {
        # lint:ignore:variable_scope
        $_source = $schema['source']
        # lint:endignore
      } else {
        $_source = undef
      }

      $schema_path = $::osfamily ? {
        'Debian' => "/etc/ldap/schema/${schema_name}.schema",
        'Redhat' => "/etc/openldap/schema/${schema_name}.schema",
      }

      file { "custom ${schema_name}":
        ensure  => file,
        path    => $schema_path,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => $_content,
        source  => $_source,
      }
    }
  }

  firewall { '30 accept LDAP traffic':
    proto  => 'tcp',
    dport  => ['389', '636'],
    state  => ['NEW'],
    action => accept,
  }
}
