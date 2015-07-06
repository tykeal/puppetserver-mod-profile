class profile::bacula::director {
  include ::bacula::director

  $bacula_schedules = hiera_hash('bacula::schedule', undef)
  if is_hash($bacula_schedules) {
    create_resources(::bacula::schedule, $bacula_schedules)
  }

  $bacula_jobdefs = hiera_hash('bacula::jobdefs', undef)
  if is_hash($bacula_jobdefs) {
    create_resources(::bacula::jobdefs, $bacula_jobdefs)
  }

  $bacula_pools = hiera_hash('bacula::director::pool', undef)
  if is_hash($bacula_pools) {
    create_resources('@@bacula::director::pool', $bacula_pools)
  }

  if hiera('collabbacula', false) {

    $conf_dir=hiera('bacula::params::conf_dir','/etc/bacula',)
    validate_string($conf_dir)

    concat::fragment { 'bacula-director-extra':
      order   => '999999',
      target  => "${conf_dir}/bacula-dir.conf",
      content => '@/etc/bacula/conf.d/myconf.conf'
      require => Class['::bacula::director']
    }
  }

  $port=hiera('bacula::director::port',9101)
  validate_integer($port)

  firewall { '060 accept bacula connections':
    proto  => 'tcp',
    port   => $port,
    state  => ['NEW'],
    action => 'accept'
  }
}
