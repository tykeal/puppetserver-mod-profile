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
    $client_password=hiera('bacula::client::password', undef)

    file { "${conf_dir}/conf.d/legacy_puppet.conf":
      ensure  => file,
      owner   => 'root',
      group   => 'bacula',
      mode    => '0640',
      content => template("${module_name}/bacula/legacy_puppet.conf.erb"),
    }

    concat::fragment { 'bacula-director-extra':
      order   => '999999',
      target  => "${conf_dir}/bacula-dir.conf",
      content => "@/etc/bacula/conf.d/legacy_puppet.conf\n",
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

  file {'/var/lib/pgsql/pgbackup.sh
    owner  => 'postgres',
    group  => 'postgres',
    mode   => '0700',
    source => "puppet:///modules/${module_name}/bacula/pgbackup.sh",
    require => Class[::postgresql::server]
  }

  cron { pgbackup:
    command => "/var/lib/pgsql/pgbackup.sh",
    user    => postgres,
    hour    => 3,
    minute  => 0,
    require => File['/var/lib/pgsql/pgbackup.sh']
  }

}
