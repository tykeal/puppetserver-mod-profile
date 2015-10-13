class yum::versionlock {

  $vlocks = hiera_hash('versionlock', undef)

  package { 'yum-plugin-versionlock':
    ensure => installed
  }

  if ($vlocks) {
    validate_hash($vlocks)
    create_resources(yum::versionlock::modify, $vlocks)
  }

}

