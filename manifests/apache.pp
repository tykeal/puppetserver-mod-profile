class profile::apache {
  include ::apache

  # for now until we come up with a way to nicely read out all the ports
  # we listen on, we'll just automatically open 80 & 443
  firewall { '030 accept incoming HTTP and HTTPS traffic':
    proto  => 'tcp',
    dport  => ['80', '443'],
    state  => ['NEW'],
    action => accept,
  }

  # since our apache systems are usually hosting DB connected apps,
  # make sure they can connect to DBs
  selboolean { 'httpd_can_network_connect_db':
    persistent => true,
    value      => on,
  }
}
