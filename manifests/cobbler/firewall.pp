class profile::cobbler::firewall {
  # Allow tftp
  firewall { '101 - Allow tftp connections':
    ensure => 'present',
    action => 'accept',
    chain  => 'INPUT',
    proto  => 'udp',
    dport  => '69',
    state  => 'NEW',
  }
}
