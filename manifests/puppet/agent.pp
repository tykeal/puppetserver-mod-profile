class profile::puppet::agent {
  # we always enforce our puppet server instead of allowing the server
  # to just auto-discover off of the 'puppet' DNS lookup
  $puppetserver = hiera('puppetserver')
  validate_string($puppetserver)

  Ini_setting {
    section => 'agent',
    path    => "${::settings::confdir}/puppet.conf",
    ensure  => present,
    notify  => Service['puppet'],
  }

  ini_setting { 'puppet.conf/agent/report':
    setting => 'report',
    value   => true,
  }

  ini_setting { 'puppet.conf/agent/server':
    setting => 'server',
    value   => $puppetserver
  }

  # Always make sure puppet agent is running
  # if the agent needs to be disabled, then 'puppet agent --disable'
  # should be executed on the host, preferably with a reason
  service { 'puppet':
    ensure => running,
    enable => true,
  }
}

# vim: tw=72 :
