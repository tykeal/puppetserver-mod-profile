class profile::selinux {
  include ::selinux::base

  $recipients=hiera('selinux::audit_recipients','root@localhost')

  file { '/usr/local/bin/avc-audit-report':
    ensure  => present,
    content => template("${module_name}/selinux/avc-audit-report.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { '/etc/cron.d/avc-audit-report.cron':
    ensure   => present,
    source   => 'puppet:///modules/profile/selinux/avc-audit-report.cron',
    owner    => 'root',
    group    => 'root',
    mode     => '0644',
    require  => File['/usr/local/bin/avc-audit-report'],
    checksum => 'md5',
  }

}
