class profile::ovirt {

  firewall { '101 ovirt physdev-is-bridged':
    ensure              => 'present',
    action              => 'accept',
    chain               => 'FORWARD',
    physdev_is_bridged  => 'true',
    proto               => 'all',
  }

}
