class profile::bacula::client {
  include ::bacula::client
  include ::bacula::params

  $port=hiera('bacula::client::port',9102)
  validate_integer($port)

  $bacula_jobs = hiera_hash('bacula::job', undef)
  if is_hash($bacula_jobs) {
    create_resources(::bacula::job, $bacula_jobs)
  }

  firewall { '061 accept incoming bacula client traffic':
    proto  => 'tcp',
    port   => $port,
    state  => ['NEW'],
    action => accept,
  }

  file { '/bacula':
    ensure   => directory,
    owner    => 'bacula',
    group    => 'bacula',
    mode     => '0660',
    seltype  => 'bacula_store_t',
    seluser  => 'system_u',
    selrole  => 'object_r',
    require  => Package['::bacula::params::bacula_client_packages'],
  }

}
