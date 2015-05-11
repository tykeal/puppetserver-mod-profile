class profile::mysql::server {
  include ::mysql::server

  $resourcetag = hiera('mysql::resourcetag')
  validate_string($resourcetag)

  # collect database definitions that have been exported by other
  # profiles
  Mysql::Db <<| tag == $resourcetag |>>

  # Unless someone can give me a good reason for us to use a port that
  # isn't the default this profile isn't going to support it, instead it
  # will just open a port
  firewall { '050 accept mysql connections':
    proto  => 'tcp',
    port   => '3306',
    state  => ['NEW'],
    action => 'accept'
  }
}
