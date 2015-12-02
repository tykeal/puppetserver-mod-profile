# Nagios server profile
class profile::nagios::server {
  include ::nagios
  include ::profile::apache
  include ::profile::apache::php

  # Do not include auth_kerb for lfcorehosts
  unless hiera('lfcorehost', false) {
    include ::profile::apache::auth_kerb
  }

  $myvhosts = hiera('apache::vhosts', {})
  create_resources('apache::vhost', $myvhosts)

  selinux::module { 'mynagios':
    source  => "puppet:///modules/${module_name}/nagios/mynagios.te",
  }

  file { '/usr/local/bin/opsgenie-nagios.pl':
    ensure  => file,
    source  => "puppet:///modules/${module_name}/nagios/opsgenie-nagios.pl",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    seltype => 'bin_t',
    seluser => 'system_u',
    selrole => 'object_r',
  }

  file { '/usr/local/bin/opsgenie.pl':
    ensure  => file,
    source  => "puppet:///modules/${module_name}/nagios/opsgenie.pl",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    seltype => 'bin_t',
    seluser => 'system_u',
    selrole => 'object_r',
  }

  # Opsgenie Scripts need some perl packages
  ensure_resource('package',
    ['perl-libwww-perl','perl-JSON-XS'],
      {'ensure' => 'present'}
  )
}
