class profile::puppetserver {
  # manage puppetserver via puppet module
  class { '::puppetserver': }

  # make sure that eyaml is installed and configured
  class { '::puppetserver::hiera::eyaml':
    method  => 'gpg',
    require => Class['::puppetserver::install'],
  }

  # allow access to puppet server port 8140
  firewall { '010 accept puppet master traffic':
    proto  => 'tcp',
    port   => '8140',
    state  => ['NEW'],
    action => accept,
  }

  include ::puppetdb::master::config
}
