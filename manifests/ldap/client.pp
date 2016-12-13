# class profile::ldap::client
class profile::ldap::client {
  include ::nsstools
  include ::openldap::client

  # configure the openldap cacert store
  $tls_cacertdir = hiera('openldap::client::tls_cacertdir',
    '/etc/openldap/certs')

  # create the nss database
  $nss_ldap_cacert_pass = hiera('nsstools::ldap_cacert_pass',
    fqdn_rand_string(50, '', 'OpenLDAP CACert Password'))
  nsstools::create { $tls_cacertdir:
    password => $nss_ldap_cacert_pass,
  }
}
