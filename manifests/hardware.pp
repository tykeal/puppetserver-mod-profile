# Hardware profile for iron
class profile::hardware {
  # We need access to some default configs
  include ::nagios::params

  $nagios_plugin_dir = hiera('nagios_plugin_dir')

  # get data needed for exported creating services
  $nagios_tag = hiera('nagios::client::nagiostag', '')
  $defaultserviceconfig = hiera('nagios::client::defaultserviceconfig',
    $::nagios::params::defaultserviceconfig)

  if $::manufacturer =~ /(?i-mx:dell.*)/ {
    include ::dell
    include ::dell::openmanage
    include ::epel

    package { 'nagios-plugins-openmanage':
      ensure  => installed,
      require => Yumrepo['epel'],
    }

    nrpe::command {
      'check_dell_openmanage':
        # lint:ignore:80chars
        command => "${nagios_plugin_dir}/check_openmanage -t 60 -e --htmlinfo -b pdisk_cert=all/pdisk_foreign=all/bat_charge=all"
        # lint:endignore
    }

    nagios::resource { "NRPE-DELL-OMSA-${::hostname}":
      resource_type         => 'service',
      defaultresourcedef    => $defaultserviceconfig,
      nagiostag             => $nagios_tag,
      resourcedef           => {
        service_description => 'NRPE - Dell Hardware',
        check_command       => 'check_nrpe!check_dell_openmanage',
      },
    }
  }

}
