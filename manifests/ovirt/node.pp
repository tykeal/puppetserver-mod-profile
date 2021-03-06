# Ovirt node profile
class profile::ovirt::node {

  $ovirt = hiera('ovirt', undef)

  package { 'ovirt-release35':
    ensure   => installed,
    source   => 'http://resources.ovirt.org/pub/yum-repo/ovirt-release35.rpm',
    provider => rpm,
  }

  sudo::conf { 'vdsm':
    priority => 50,
    source   => "puppet:///modules/${module_name}/ovirt/vdsm",
  }

  sudo::conf { 'ovirt-ha':
    priority => 60,
    source   => "puppet:///modules/${module_name}/ovirt/ovirt-ha",
  }

  file_line {'peerdns_fix':
    line => 'PEERDNS=no',
    path => '/etc/sysconfig/network-scripts/ifcfg-ovirtmgmt',
  }

  firewall { '101 ovirt physdev-is-bridged':
    ensure             => 'present',
    action             => 'accept',
    chain              => 'FORWARD',
    physdev_is_bridged => true,
    proto              => 'all',
  }

  firewall { '101 allow vdsm connections':
    ensure => 'present',
    action => 'accept',
    chain  => 'INPUT',
    proto  => 'tcp',
    source => $ovirt['allowed_nodes'],
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
    source => $ovirt['allowed_nodes'],
    dport  => '16514',
  }

  firewall { '101 allow guest console connections':
    ensure => 'present',
    action => 'accept',
    chain  => 'INPUT',
    proto  => 'tcp',
    source => $ovirt['allowed_guests'],
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
