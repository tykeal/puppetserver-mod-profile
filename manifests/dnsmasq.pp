class profile::dnsmasq {
  include ::dnsmasq

  # load any config changes that this host may specifically have defined
  $dnsmasq_confs = hiera_hash('dnsmasq::conf', undef)
  if is_hash($dnsmasq_confs) {
    create_resources(::dnsmasq::conf, $dnsmasq_confs)
  }

  # load any specific dnsmasq host entries
  $dnsmasq_hosts = hiera_hash('dnsmasq::host', undef)
  if is_hash($dnsmasq_hosts) {
    create_resources(::dnsmasq::host, $dnsmasq_hsots)
  }

  # load any defined dhcp_host entries
  $dnsmasq_dhcp_hosts = hiera_hash('dnsmasq::dhcp_host', undef)
  if is_hash($dnsmasq_dhcp_hosts) {
    create_resources(::dnsmasq::dhcp_host, $dnsmasq_dhcp_hosts)
  }
}
