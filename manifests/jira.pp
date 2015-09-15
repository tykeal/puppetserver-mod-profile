class profile::jira {
  # Jira requires java to be installed
  include ::java
  include ::jira

  # Since we use MySQL in general in our environments we'll just assume
  # we're doing MySQL for now
  #
  # Require that the db{name,user,password} all be set in hiera or bomb
  $jira_dbname = hiera('jira::dbname')
  validate_string($jira_dbname)
  $jira_dbuser = hiera('jira::dbuser')
  validate_string($jira_dbuser)
  $jira_dbpassword = hiera('jira::dbpassword')
  validate_string($jira_dbpassword)

  # custom (required) variable for our environment
  $jira_dbtag = hiera('jira::dbtag')
  validate_string($jira_dbtag)

  @@::mysql::db { "${jira_dbname}_${::fqdn}":
    user     => $jira_dbuser,
    password => $jira_dbpassword,
    dbname   => $jira_dbname,
    host     => $::ipaddress,
    grant    => [ 'ALL' ],
    collate  => 'utf8_bin',
    tag      => $jira_dbtag,
  }

  Class['::java'] -> Class['::jira']

  # configure the firewall
  $jira_tomcatPort = hiera('jira::tomcatPort', 8080)
  validate_integer($jira_tomcatPort)

  firewall { '050 accept jira traffic':
    proto  => 'tcp',
    port   => $jira_tomcatPort,
    state  => ['NEW'],
    action => accept,
  }

  $jira_nativeSSL = hiera('jira::tomcatNativeSsl', false)
  validate_bool($jira_nativeSSL)

  if ($jira_nativeSSL) {
    $jira_tomcatHttpsPort = hiera('jira::tomcatHttpsPort', 8443)
    validate_integer($jira_tomcatHttpsPort)

    firewall { '050 accept jira HTTPS traffic':
      proto  => 'tcp',
      port   => $jira_tomcatHttpsPort,
      state  => ['NEW'],
      action => accept,
    }
  }
}

