# Hardware profile for iron
class profile::hardware {

  if $::manufacturer =~ /(?i-mx:dell.*)/ {
    include ::dell
    include ::dell::openmanage
    include ::epel

    package { 'nagios-plugins-openmanage':
      ensure  => installed,
      require => Yumrepo['epel'],
    }
  }

}
