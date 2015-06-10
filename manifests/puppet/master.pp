class profile::puppet::master {
  Ini_setting {
    section => 'master',
    path    => "${::settings::confdir}/puppet.conf",
    ensure  => present,
  }

  $puppetmaster = hiera('puppet::master')
  validate_hash($puppetmaster)

  # Puppet 4 supports lambda functions, this allows us an easy way to
  # loop over the keys of a hash and create resources that we wouldn't
  # be able to using create_resources
  $puppetmaster.each |String $conf_setting, String $conf_value| {
    ini_setting { "puppet.conf/master/${conf_setting}":
      setting => $conf_setting,
      value   => $conf_value,
    }
  }

  # push opsgenie configuration
  $opsgenie = hiera('opsgenie')
  validate_hash($opsgenie)

  file { "${::settings::confdir}/opsgenie.yaml":
    ensure  => file,
    mode    => '0640',
    owner   => 'puppet',
    group   => 'puppet',
    content => template("${module_name}/opsgenie/opsgenie.yaml.erb"),
  }
}
