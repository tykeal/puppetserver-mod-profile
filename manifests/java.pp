class profile::java {
  include ::java

  $codeaurora_ca_cert = hiera('codeaurora_ca_cert', false)

  if ($codeaurora_ca_cert) {
    validate_bool($codeaurora_ca_cert)

    $java_ks_password = hiera('java_ks::password', 'changeit')
    validate_string($java_ks_password)

    sslmgmt::ca_dh { 'codeaurora-org-ca':
      pkistore => 'default',
    }

    java_ks { 'codeaurora-org-ca:cert':
      ensure       => latest,
      certificate  => '/etc/pki/tls/certs/codeaurora-org-ca.pem',
      trustcacerts => true,
      password     => $java_ks_password,
      target       => '/usr/lib/jvm/jre/lib/security/cacerts',
    }
  }
}
