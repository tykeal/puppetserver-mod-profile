class profile::admin {
  include ::epel

  # administrative packages that we want on systems that don't need full
  # blown modules for managing them
  package { [
      'htop',
      'iftop',
      'iotop',
    ]:
    ensure  => installed,
    require => Class['::epel'],
  }
}
