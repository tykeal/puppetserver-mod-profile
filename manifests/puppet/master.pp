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

  # Assuming that reports are being stored locally on disk (along with
  # probably puppetdb, let's do regular tidy operations on the reports
  # we'll default to 1 week unless it's overridden in hiera
  # If reports should not be auto-cleaned then the hiera value should be
  # set to 'manual'
  $puppet_report_ttl = hiera('puppet::master::report_ttl', '1w')

  if ($puppet_report_ttl != 'manual')
  {
    tidy { 'tidy puppet reports':
      path    => '/opt/puppetlabs/server/data/puppetserver/reports',
      age     => $puppet_report_ttl,
      recurse => true,
      matches => [ '*.yaml' ],
      rmdirs  => true,
    }
  }
}
