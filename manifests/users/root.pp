class profile::users::root {
  file { '/root/.bashrc':
    ensure => present,
    source => 'puppet:///modules/profile/users/dotfiles/root-dot.bashrc',
  }

  file { '/root/.bash_logout':
    ensure => absent,
  }
}
