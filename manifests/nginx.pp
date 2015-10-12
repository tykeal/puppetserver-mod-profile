class profile::nginx {
  include ::nginx

  # Collect the resources that have been exported
  $resourcetag = hiera('nginx::resourcetag')
  validate_string($resourcetag)

  Nginx::Resource::Upstream <<| tag == $resourcetag |>>

  Nginx::Resource::Vhost <<| tag == $resourcetag |>>

  Nginx::Resource::Location <<| tag == $resourcetag |>>

  # we expect our nginx systems to be doing SSL if not
  # This only happens if nginx::sslcerts is a hash though
  $sslcerts = hiera('nginx::sslcerts')
  if (is_hash($sslcerts)) {
    # configure all the defined certs
    create_resources(sslmgmt::cert, $sslcerts)
  }

  # ca cert / dhparam files to push
  $cacerts = hiera('nginx::cacerts')
  if (is_hash($cacerts)) {
    # push all the ca certs / dhparam files
    create_resources(sslmgmt::ca_dh, $cacerts)
  }

  # for now until we come up with a way to nicely read out all the ports
  # we listen on, we'll just automatically open 80 & 443
  firewall { '030 accept incoming HTTP and HTTPS traffic':
    proto  => 'tcp',
    dport  => ['80', '443'],
    state  => ['NEW'],
    action => accept,
  }

  # since we use our nginx systems as proxies, they should always allow
  # httpd_can_network_connect
  selboolean { 'httpd_can_network_connect':
    persistent => true,
    value      => on,
  }
}
