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

  $port=hiera('bacula::director::port',9101)
  validate_integer($port)

  firewall { '060 accept bacula connections':
    proto  => 'tcp',
    port   => $port,
    state  => ['NEW'],
    action => 'accept'
  }
}
