class profile::puppet::master {
  Ini_setting {
    section => 'master',
    path    => "${::settings::confdir}/puppet.conf",
    ensure  => present,
  }

  $puppetmaster = hiera('puppet::master')
  validate_hash($puppetmaster)

  # since r10k seems to have issues with parser = future being turned on
  # we can't use a lambda to loop over the settings using a define
  ini_setting { 'puppet.conf/master/reports':
    setting => 'reports',
    value   => $puppetmaster['reports'],
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
