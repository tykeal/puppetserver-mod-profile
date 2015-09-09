class profile::rsyslog::client {
  include ::rsyslog::client

  file { '/etc/rsyslog.d/listen.conf':
    ensure => 'absent'
  }

}
