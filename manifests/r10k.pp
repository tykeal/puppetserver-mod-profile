class profile::r10k {
  include ::r10k
  include ::r10k::postrun_command

  # get around the fact that ::r10k::postrun_command doesn't seem to
  # know about the new config path for where to modify puppet.conf
  file { '/etc/puppet':
    ensure => link,
    target => 'puppetlabs/puppet',
    before => Class['::r10k::postrun_command'],
  }
}
