class profile::users::root {
  $roothiera = hiera('root_config')
  validate_hash($roothiera)

  mailalias { 'root':
    ensure    => present,
    recipient => $roothiera['mailalias'],
  }

  file { '/root/.vimrc':
    ensure => present,
    source => 'puppet:///modules/profile/users/dotfiles/dot.vimrc',
  }

  file { '/root/.bashrc':
    ensure => present,
    source => 'puppet:///modules/profile/users/dotfiles/root-dot.bashrc',
  }

  file { '/root/.bash_logout':
    ensure => absent,
  }
}
