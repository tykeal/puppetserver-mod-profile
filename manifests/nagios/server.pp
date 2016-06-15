# Nagios server profile
class profile::nagios::server {
  include ::nagios
  include ::profile::apache
  include ::profile::apache::php

  # Do not include auth_kerb for lfcorehosts
  unless hiera('lfcorehost', false) {
    include ::profile::apache::auth_kerb
  }

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
  # Nagios checks
  # We need access to some default configs
  include ::nagios::params
  $nagios_plugin_dir = hiera('nagios_plugin_dir')

  # get data needed for exported creating services
  $nagios_tag = hiera('nagios::client::nagiostag', '')
  $defaultserviceconfig = hiera('nagios::client::defaultserviceconfig',
    $::nagios::params::defaultserviceconfig)

  ::nrpe::command {
    'check_proc_nagios':
      command => "${nagios_plugin_dir}/check_procs -c 1: -C nagios"
  }


  # Opsgenie Scripts need some perl packages
  ensure_resource('package',
    ['perl-libwww-perl','perl-JSON-XS','perl-LWP-Protocol-https'],
      {'ensure' => 'present'}
  )

  $nagios_virtual_resources = hiera('nagios::virtual_resources', undef)
  if ($nagios_virtual_resources) {
    validate_hash($nagios_virtual_resources)
    #lint:ignore:80chars
    create_resources('profile::nagios::virtual_nodes', $nagios_virtual_resources)
    #lint:endignore
  }

}
