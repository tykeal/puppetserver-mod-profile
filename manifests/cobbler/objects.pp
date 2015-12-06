class profile::cobbler::objects {
  # Gathering cobbler's objects data from hiera
  $distros          = hiera('cobbler::distros', {})
  $repos            = hiera('cobbler::repos', {})
  $profiles         = hiera('cobbler::profiles', {})
  $systems          = hiera('cobbler::systems', {})
  # Default values for different objects
  $default_distros  = hiera('cobbler::default::distros', {})
  $default_repos    = hiera('cobbler::default::repos', {})
  $default_profiles = hiera('cobbler::default::profiles', {})
  $default_systems  = hiera('cobbler::default::systems', {})

  validate_hash(
    $distros,
    $repos,
    $profiles,
    $systems,
    $default_distros,
    $default_repos,
    $default_profiles,
    $default_systems
  )

  # Creating resources
  create_resources(
    'cobbler_distro',
    $distros,
    $default_distros
  )

  create_resources(
    'cobbler_repo',
    $repos,
    $default_repos
  )

  create_resources(
    'cobbler_profile',
    $profiles,
    $default_profiles
  )

  create_resources(
    'cobbler_system',
    $systems,
    $default_systems
  )
}
