# Class profile::hardware::simech
# Hardware monitoring for Silicon Mechanics systems
class profile::hardware::simech {
  $nagios_plugin_dir = hiera('nagios_plugin_dir')

  # get data needed for exported creating services
  $nagios_tag = hiera('nagios::client::nagiostag', '')
  $defaultserviceconfig = hiera('nagios::client::defaultserviceconfig',
    $::nagios::params::defaultserviceconfig)

  # Nagios software raid checks
  # Only add software raid checks if 1 =< partitions is linux_raid_member
  if String($::partitions) =~ 'linux_raid_member' {

    file {"${nagios_plugin_dir}/check_md_raid":
      ensure   => present,
      owner    => 'root',
      group    => 'root',
      mode     => '0755',
      selrole  => 'object_r',
      seltype  => 'nagios_checkdisk_plugin_exec_t',
      seluser  => 'system_u',
      selrange => 's0',
      source   => "puppet:///modules/${module_name}/hardware/check_md_raid",
    }
    nrpe::command {
      'check_md_raid':
      # lint:ignore:80chars
      command => "${nagios_plugin_dir}/check_md_raid",
      # lint:endignore
      require => File["${nagios_plugin_dir}/check_md_raid"],
    }

    nagios::resource { "NRPE-MD-RAID-${::hostname}":
      resource_type      => 'service',
      defaultresourcedef => $defaultserviceconfig,
      nagiostag          => $nagios_tag,
      resourcedef        => {
        service_description => 'NRPE - Software Raid',
        check_command       => 'check_nrpe!check_md_raid',
      },
    }

  }

  # IPMI nagios check
  $ipmi_user = hiera('ipmi::user', '')
  $ipmi_pass = hiera('ipmi::password', '')
  ensure_packages(['freeipmi','perl-IPC-Run'])

  # allow nrpe daemon to run sudo to be able access ipmi status info
  include ::selinux::base
  selboolean { 'nagios_run_sudo':
    value      => 'on',
    persistent => true,
  }
  # Selinux module for nrpe checks
  #selinux::module {'mynagiosipmi':
  #  source => "puppet:///modules/${module_name}/hardware/mynagiosipmi.te",
  #}

  file {"${nagios_plugin_dir}/check_ipmi_sensor":
    ensure   => present,
    owner    => 'root',
    group    => 'root',
    mode     => '0755',
    selrole  => 'object_r',
    seltype  => 'nagios_unconfined_plugin_exec_t',
    seluser  => 'system_u',
    selrange => 's0',
    source   => "puppet:///modules/${module_name}/hardware/check_ipmi_sensor",
    # lint:ignore:80chars
    require  => Package['freeipmi','perl-IPC-Run'],
    # lint:endignore
  }
  nrpe::command {
    'check_ipmi_sensor':
    # lint:ignore:80chars
    command => "${nagios_plugin_dir}/check_ipmi_sensor -H localhost",
    sudo    => true,
    # lint:endignore
    require => File["${nagios_plugin_dir}/check_ipmi_sensor"],
  }

  nagios::resource { "NRPE-IPMI-SENSOR-${::hostname}":
    resource_type      => 'service',
    defaultresourcedef => $defaultserviceconfig,
    nagiostag          => $nagios_tag,
    resourcedef        => {
      service_description => 'NRPE - IPMI Sensor',
      check_command       => 'check_nrpe!check_ipmi_sensor',
    },
  }

  # SMART nagios check
  ensure_packages(['nagios-plugins-ide_smart'])
  # Check for each disk that is not a Flash Disk
  $::disks.each | $disk |{
    # lint:ignore:variable_scope
    if $disk[1]['model'] != 'Flash Disk'{
      nrpe::command {
        "check_ide_smart_${disk[0]}":
          # lint:ignore:80chars
          command => "${nagios_plugin_dir}/check_ide_smart -d /dev/${disk[0]}",
          sudo    => true,
          # lint:endignore
      }

      nagios::resource { "NRPE-SMART-${disk[0]}-${::hostname}":
        resource_type      => 'service',
        defaultresourcedef => $defaultserviceconfig,
        nagiostag          => $nagios_tag,
        resourcedef        => {
          service_description => "NRPE - Smart ${disk[0]}",
          check_command       => "check_nrpe!check_ide_smart_${disk[0]}",
        },
      }
    }
    # lint:endignore
  }
}
