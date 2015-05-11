# this should be included by all of our systems
class profile::firewall {
  resources { 'firewall':
    purge => true,
  }
  Firewall {
    before  => Class['local_fw::post'],
    require => Class['local_fw::pre'],
  }
  class { ['local_fw::pre', 'local_fw::post']: }
  class { '::firewall': }
}
