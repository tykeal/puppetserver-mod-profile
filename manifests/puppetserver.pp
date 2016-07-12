# class profile::puppetserver
class profile::puppetserver {
  # manage puppetserver via puppet module
#  class { '::puppetserver': }

  # make sure that eyaml is installed and configured
#  class { '::puppetserver::hiera::eyaml':
#    method  => 'gpg',
#    require => Class['::puppetserver::install'],
#  }

  # allow access to puppet server port 8140
  firewall { '010 accept puppet master traffic':
    proto  => 'tcp',
    dport  => '8140',
    state  => ['NEW'],
    action => accept,
  }

  include ::puppetdb::master::config

  # Script for easy decommissioning of nodes
  file { '/usr/local/bin/decommission_node.sh':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0600',
    source => "puppet:///modules/${module_name}/puppet/decommission_node.sh"
  }
}
