class profile::cobbler::dhcp {
  $settings = hiera('cobbler::cobbler_config', {})

  validate_hash($settings)

  # if cobbler manages dhcp
  if $settings['manage_dhcp'] == 1 {
    package {'dhcp':
      ensure => 'installed',
    }
    include selinux::base
    selinux::module {'mycobbler':
      source => 'puppet:///modules/profile/cobbler/selinux/mycobbler.te',
    }
  }
}
