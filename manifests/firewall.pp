# this should be included by all of our systems
class profile::firewall {
  $use_shorewall = hiera('profile::firewall::use_shorewall', false)

  if $use_shorewall {
    include profile::firewall::shorewall
  } else {
    include profile::firewall::iptables
  }
}
