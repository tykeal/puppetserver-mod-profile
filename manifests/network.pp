# configure network via hiera
class profile::network {
  include ::network
  include ::network::hiera
}
