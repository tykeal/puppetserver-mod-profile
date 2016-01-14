class profile::mysql::server {
  include ::mysql::server

  $resourcetag = hiera('mysql::resourcetag')
  validate_string($resourcetag)
  # We need access to some default configs
  include ::nagios::params

  $nagios_plugin_dir = hiera('nagios_plugin_dir')

  # get data needed for exported creating services
  $nagios_tag = hiera('nagios::client::nagiostag', '')
  $defaultserviceconfig = hiera('nagios::client::defaultserviceconfig',
    $::nagios::params::defaultserviceconfig)

  # collect database definitions that have been exported by other
  # profiles
  Mysql::Db <<| tag == $resourcetag |>>

  # Unless someone can give me a good reason for us to use a port that
  # isn't the default this profile isn't going to support it, instead it
  # will just open a port
  firewall { '050 accept mysql connections':
    proto  => 'tcp',
    dport  => '3306',
    state  => ['NEW'],
    action => 'accept'
  }

  nrpe::command {
    'check_mysqld_running':
      command => "${nagios_plugin_dir}/check_procs -c 1:1 -C mysqld"
  }

  nagios::resource { "NRPE-MySQL-Server-Process-${::fqdn}":
    resource_type         => 'service',
    defaultresourcedef    => $defaultserviceconfig,
    nagiostag             => $nagios_tag,
    resourcedef           => {
      service_description => 'NRPE - MySQL Server Process',
      check_command       => 'check_nrpe!check_mysqld_running',
    },
  }

  nrpe::command {
    'check_mysql_disk_free':
      command => "${nagios_plugin_dir}/check_disk -M -w 15% -c 5% /var/lib/mysql"
  }

  nagios::resource { "NRPE-MySQL-Free-Disk-${::fqdn}":
    resource_type         => 'service',
    defaultresourcedef    => $defaultserviceconfig,
    nagiostag             => $nagios_tag,
    resourcedef           => {
      service_description => 'NRPE - MySQL Free Disk',
      check_command       => 'check_nrpe!check_mysql_disk_free',
    },
  }

  if hiera('mysql::has_replication', false) {
    # get password for nagios check
    $pt_heartbeat_pass = hiera('mysql::pt_heartbeat_pass')

    nrpe::command {
      'check_mysql_slavestatus':
        command => "${nagios_plugin_dir}/check_mysql_slavestatus -H 127.0.0.1 -P 3306 -u pt-heartbeat -p ${pt_heartbeat_pass}"
    }

    nagios::resource { "NRPE-MySQL-Slave-Status-${::fqdn}":
      resource_type         => 'service',
      defaultresourcedef    => $defaultserviceconfig,
      nagiostag             => $nagios_tag,
      resourcedef           => {
        service_description => 'NRPE - MySQL Slave Status',
        check_command       => 'check_nrpe!check_mysql_slavestatus',
      },
    }
  }
}
