class profile::cobbler::dhcp {
  $settings = hiera('cobbler::cobbler_config', {})

  validate_hash($settings)

  # if cobbler manages dhcp
  if $settings['manage_dhcp'] == 1 {
    package {'dhcp':
      ensure => 'installed',
    }
  }
}
