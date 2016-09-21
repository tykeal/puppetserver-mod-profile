# Abstracted defined class to define firewall rules that can be used
# both with iptables and shorewall
define profile::firewall::rule (
  $priority,
  $proto,
  $dport,
  $state    = ['NEW'],
  $source   = undef,
  $sport    = undef,
  $action   = 'accept',
  $ipv4     = true,
  $ipv6     = false,
  $iniface  = undef,
  $outiface = undef,
) {
  $use_shorewall = hiera('profile::firewall::use_shorewall', false)

  if $use_shorewall {
    if $source {
      $_source = "all:${source}"
    } else {
      $_source = 'all'
    }

    if is_array($dport) {
      $_dport = join($dport, ',')
    } else {
      $_dport = "${dport}"
    }

    if is_array($sport) {
      $_sport = join($sport, ',')
    } else {
      $_sport = "${sport}"
    }

    # iptables rules take lowercase, but otherwise map directly
    $_action = upcase($action)

    # shorewall doesn't like rules starting below 1, so we
    # We force local rules to come after all others by bumping order to 9's
    $_order = "9${priority}"

    # if ipv6 is set to true, but ::shorewall::ipv6 is false, turn it off
    if ($ipv6 and $::shorewall::ipv6) {
      $_ipv6 = true
    } else {
      $_ipv6 = false
    }

    shorewall::rule { "${priority} ${action} ${name}":
      proto  => $proto,
      port   => $_dport,
      sport  => $_sport,
      source => $_source,
      dest   => 'local',
      action => $_action,
      order  => $_order,
      ipv4   => $ipv4,
      ipv6   => $_ipv6,
    }
  } else {
    firewall  { "${priority} ${action} ${name}":
      proto    => $proto,
      dport    => $dport,
      state    => $state,
      source   => $source,
      action   => $action,
      iniface  => $iniface,
      outiface => $outiface,
    }
  }
}
