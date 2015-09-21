class profile::shellenv {

  # Include the zone in the shell prompt
  file { '/etc/profile.d/show-my-zone.sh':
    ensure  => present,
    source  => 'puppet:///modules/profile/shellenv/show-my-zone.sh',
  }

}
