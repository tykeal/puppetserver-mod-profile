# libvirt node profile
class profile::libvirt::node {
  include '::network::hiera'
  include '::libvirt'

  $networks = hiera('libvirt_networks', {})
  validate_hash($networks)
  if ($networks) {
    create_resources('::libvirt::network', $networks)
  }

  $pools = hiera('libvirt_pools', {})
  validate_hash($pools)
  if ($pools) {
    create_resources('::libvirt_pool', $pools)
  }
}
