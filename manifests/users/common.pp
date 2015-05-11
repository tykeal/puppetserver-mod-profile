class profile::users::common {
  # users define does a hiera lookup composition of users_${name} by
  # default
  ::users { 'common': }

  # one of our common users is lfadmin (for historical reasons and until
  # we can safely and cleanly move to LDAP users
  # this user has a few specific file configuration modifications that
  # we want taken care of
  file { '/home/lfadmin/.vimrc':
    ensure  => present,
    source  => 'puppet:///modules/profile/users/dotfiles/dot.vimrc',
    require => ::Users['common'],
  }

  file { '/home/lfadmin/.bashrc':
    ensure  => present,
    source  => 'puppet:///modules/profile/users/dotfiles/lfadmin-dot.bashrc',
    require => ::Users['common'],
  }

  file { '/home/lfadmin/.bash_logout':
    ensure  => absent,
    require => ::Users['common'],
  }
}
