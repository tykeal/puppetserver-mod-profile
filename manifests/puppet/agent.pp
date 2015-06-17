class profile::puppet::agent {
  # we always enforce our puppet server instead of allowing the server
  # to just auto-discover off of the 'puppet' DNS lookup
  $puppetserver = hiera('puppetserver')
  validate_string($puppetserver)

  Ini_setting {
    path    => "${::settings::confdir}/puppet.conf",
    ensure  => present,
    notify  => Service['puppet'],
  }

  ini_setting { 'puppet.conf/agent/report':
    section => 'agent',
    setting => 'report',
    value   => true,
  }

  ini_setting { 'puppet.conf/agent/server':
    section => 'agent',
    setting => 'server',
    value   => $puppetserver
  }

  # load settings that should be in the global puppet main section
  $puppetmain = hiera('puppet::main', undef)
  if is_hash($puppetmain) {
    # apply any settings that may be coming in
    $puppetmain.each |String $conf_setting, String $conf_value| {
      ini_setting { "puppet.conf/main/${conf_setting":
        section => 'main',
        setting => $conf_setting,
        value   => $conf_value,
      }
    }
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
