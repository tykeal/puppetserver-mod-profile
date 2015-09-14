class profile::ovirt::node {

  $ovirt = hiera('ovirt', undef)

  firewall { '101 ovirt physdev-is-bridged':
    ensure              => 'present',
    action              => 'accept',
    chain               => 'FORWARD',
    physdev_is_bridged  => 'true',
    proto               => 'all',
  }

  firewall { '101 allow vdsm connections':
    ensure => 'present',
    action => 'accept',
    chain  => 'INPUT',
    proto  => 'tcp',
    source => $ovirt['engine_ip'],
    dport  => '54321',
  }

  firewall { '101 allow snmp connections':
    ensure => 'present',
    action => 'accept',
    chain  => 'INPUT',
    proto  => 'udp',
    source => $ovirt['engine_ip'],
    dport  => '161',
  }

  firewall { '101 allow libvirt tls connections':
    ensure => 'present',
    action => 'accept',
    chain  => 'INPUT',
    proto  => 'tcp',
    source => $ovirt['engine_ip'],
    dport  => '16514',
  }

  firewall { '101 allow guest console connections':
    ensure => 'present',
    action => 'accept',
    chain  => 'INPUT',
    proto  => 'tcp',
    source => $ovirt['engine_ip'],
    dport  => '5900-6923',
  }

  firewall { '101 allow migration connections':
    ensure => 'present',
    action => 'accept',
    chain  => 'INPUT',
    proto  => 'tcp',
    dport  => '49152-49216',
  }

  sysctl { 'vdsm':
    ensure => present,
  }

}
