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

  $cacerts = hiera('ldap::client::cacerts', undef)
  if (is_hash($cacerts)) {
    $cacerts.each |String $cacert, Hash $options| {
      sslmgmt::ca_dh { $cacert:
        * => $options,
      }

      # futz around with figuring out the actual cert file that was just created
      if (has_key($options, 'customstore') and
          (has_key($options['customstore'], 'certfilename') or
          has_key($options['customstore'], 'certpath'))) {
        if has_key($options['customestore'], 'certfilename') {
          $_certname = $options['customstore']['certfilename']
        }
        else
        {
          $_certpath = $options['customstore']['certpath']
          $_certname = "${_certpath}/${cacert}.pem"
        }
      }
      else
      {
        include ::sslmgmt::params

        $_certpath = $::sslmgmt::params::pkistore['default']['certpath']
        $_certname = "${_certpath}/${cacert}.pem"
      }

      nsstools::add_cert { $cacert:
        certdir => $tls_cacertdir,
        cert    => $_certname,
        require => Sslmgmt::Ca_dh[$cacert],
      }
    }
  }
}
