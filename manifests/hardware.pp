# Hardware profile for iron
class profile::hardware {
  # We need access to some default configs
  include ::nagios::params

  $nagios_plugin_dir = hiera('nagios_plugin_dir')

  # get data needed for exported creating services
  $nagios_tag = hiera('nagios::client::nagiostag', '')
  $defaultserviceconfig = hiera('nagios::client::defaultserviceconfig',
    $::nagios::params::defaultserviceconfig)

  case $::manufacturer {
    /(?i-mx:dell.*)/: {
      include ::profile::hardware::dell
    }
    'Silicon Mechanics': {
      include ::profile::hardware::simech
    }
    default: {
      # nothing to do
    }
  }

  # If has_srv_partition is true, monitor its size
  #lint:ignore:80chars
  $has_srv_partition = hiera('nagios::has_srv_partition', false)
  #lint:endignore
  if ($has_srv_partition) {
    validate_bool($has_srv_partition)
    #lint:ignore:80chars
    $srv_partition_warn = hiera('nagios::srv_partition_warn', 15)
    #lint:endignore
    validate_integer($srv_partition_warn)
    #lint:ignore:80chars
    $srv_partition_crit = hiera('nagios::srv_partition_crit', 5)
    #lint:endignore
    validate_integer($srv_partition_crit)

    nrpe::command {
      'check_disk_srv':
      #lint:ignore:80chars
      command => "${nagios_plugin_dir}/check_disk -M -w ${nagios::srv_partition_warn}% -c ${nagios::srv_partition_crit}% /srv"
      #lint:endignore
    }

    nagios::resource { "NRPE-Srv-Free-Disk-${::fqdn}":
      resource_type      => 'service',
      defaultresourcedef => $defaultserviceconfig,
      nagiostag          => $nagios_tag,
      resourcedef        => {
        service_description => 'NRPE - Srv Free Disk',
        check_command       => 'check_nrpe!check_disk_srv',
      },
    }
  }


}
