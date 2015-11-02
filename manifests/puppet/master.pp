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

  # push report configurations
  if (has_key($puppetmaster, 'reports')) {

    # push opsgenie configuration, but only if it's setup as a report
    if ($puppetmaster['reports'].match(/opsgenie/)) {
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

    # push tagmail configuration, but only if it's setup as a report
    if ($puppetmaster['reports'].match(/tagmail/)) {
      # tagmail is being configured, our config will be at tagmail::conf
      # this will be written out as an ini file
      $tagmailconf = hiera('tagmail::conf')
      validate_hash($tagmailconf)

      # tagmail::conf must have two sections transport (a hash) and
      # tagmap (an array of hashes)
      validate_hash($tagmailconf['transport'])
      validate_array($tagmailconf['tagmap'])

      file { "${::settings::confdir}/tagmail.conf":
        ensure  => file,
        content => template("${module_name}/tagmail/tagmail.conf.erb"),
      }
    }

    # local report storage causes build up of reports on disk we want a
    # way to clean these up sanely
    if ($puppetmaster['reports'].match(/store/)) {
      # step 1 determine if report cleaning is going to be manual or not
      $puppet_report_ttl = hiera('puppet::master::report_ttl', '1w')

      if ($puppet_report_ttl != 'manual')
      {
        # cleaning is not manual

        # step 2 create a cron job that fires once a day to set a custom
        # fact
        file { '/etc/cron.daily/flag_puppet_tidy':
          ensure => file,
          owner  => 'root',
          group  => 'root',
          mode   => '0744',
          source => "puppet:///modules/${module_name}/flag_puppet_tidy",
        }

        # Now that the fact is set to fire once per day, if it's true
        # we'll execute the tidy operation, but only once a day.
        if ($::flag_puppet_tidy) {
          tidy { 'tidy puppet reports':
            path    => '/opt/puppetlabs/server/data/puppetserver/reports',
            age     => $puppet_report_ttl,
            recurse => true,
            matches => [ '*.yaml' ],
            rmdirs  => true,
          }
        }
      }
    } else {
      # No stored reports, as such we want to make sure the daily cron
      # job to flag the tidy operation doesn't exist, otherwise we're
      # going to get regular removal notices from the external_facts
      # since this is not a puppet managed external_fact (on purpose)
      file { '/etc/cron.daily/flag_puppet_tidy':
        ensure => absent,
      }
    }
  }
}
