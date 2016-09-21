# This is used mainly by VPN/firewall systems
class profile::firewall::shorewall {
  include ::shorewall

  if $::shorewall::ipv4 {
    service { 'iptables':
      ensure => stopped,
      enable => false,
    }
  }

  if $::shorewall::ipv6 {
    service { 'ip6tables':
      ensure => stopped,
      enable => false,
    }
  }

  file { '/etc/shorewall/macro.IPA':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    seltype => 'shorewall_etc_t',
    seluser => 'system_u',
    selrole => 'object_r',
    source  => "puppet:///modules/${module_name}/shorewall/macro.IPA",
    require => Package['shorewall'],
  }

  file { '/etc/shorewall/macro.MCO':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    seltype => 'shorewall_etc_t',
    seluser => 'system_u',
    selrole => 'object_r',
    source  => "puppet:///modules/${module_name}/shorewall/macro.MCO",
    require => Package['shorewall'],
  }

  file { '/etc/shorewall/macro.Totpcgi':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    seltype => 'shorewall_etc_t',
    seluser => 'system_u',
    selrole => 'object_r',
    source  => "puppet:///modules/${module_name}/shorewall/macro.Totpcgi",
    require => Package['shorewall'],
  }

  file { '/etc/shorewall/macro.RELP':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    seltype => 'shorewall_etc_t',
    seluser => 'system_u',
    selrole => 'object_r',
    source  => "puppet:///modules/${module_name}/shorewall/macro.RELP",
    require => Package['shorewall'],
  }

  file { '/etc/shorewall/macro.Nagios':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    seltype => 'shorewall_etc_t',
    seluser => 'system_u',
    selrole => 'object_r',
    source  => "puppet:///modules/${module_name}/shorewall/macro.Nagios",
    require => Package['shorewall'],
  }

  shorewall::config { 'STARTUP_ENABLED':
    value => 'Yes',
  }

  $shorewall_configs = hiera('shorewall::configs', {})
  validate_hash($shorewall_configs)
  create_resources('shorewall::config', $shorewall_configs)

  $shorewall_ifaces = hiera('shorewall::ifaces')
  validate_hash($shorewall_ifaces)
  create_resources('shorewall::iface', $shorewall_ifaces)

  $shorewall_zones = hiera('shorewall::zones')
  validate_hash($shorewall_zones)
  create_resources('shorewall::zone', $shorewall_zones)

  $shorewall_policies = hiera_hash('shorewall::policies')
  validate_hash($shorewall_policies)
  create_resources('shorewall::policy', $shorewall_policies)

  $shorewall_masqs = hiera('shorewall::masqs', {})
  validate_hash($shorewall_masqs)
  create_resources('shorewall::masq', $shorewall_masqs)

  $shorewall_tunnels = hiera('shorewall::tunnels', {})
  validate_hash($shorewall_tunnels)
  create_resources('shorewall::tunnel', $shorewall_tunnels)

  $shorewall_proxyarps = hiera('shorewall::proxyarps', {})
  validate_hash($shorewall_proxyarps)
  create_resources('shorewall::proxyarp', $shorewall_proxyarps)

  $shorewall_rules = hiera_hash('shorewall::rules', {})
  validate_hash($shorewall_rules)
  create_resources('shorewall::rule', $shorewall_rules)

  $shorewall_routestoppeds = hiera('shorewall::routestoppeds', {})
  validate_hash($shorewall_routestoppeds)
  create_resources('shorewall::routestopped', $shorewall_routestoppeds)

}
