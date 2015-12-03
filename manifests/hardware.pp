# Hardware profile for iron
class profile::hardware {

  $nagios_plugin_dir = hiera('nagios_plugin_dir')

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

    nagios::client::hostservices { "NRPE-DELL-OMSA-${::hostname}":
      service_description => 'NRPE - Dell Hardware',
      check_command       => 'check_nrpe!check_openmanage'
    }

  }

}
