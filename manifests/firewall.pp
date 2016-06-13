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

  $firewall_chains = hiera_hash('firewall::chains', undef)
  if (is_hash($firewall_chains)) {
    create_resources(firewallchain, $firewall_chains)
  }

  $firewall_rules = hiera_hash('firewall::rules', undef)
  if (is_hash($firewall_rules)) {
    create_resources(firewall, $firewall_rules)
  }
}
