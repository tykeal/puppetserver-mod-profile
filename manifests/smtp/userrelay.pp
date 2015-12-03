# Custom class that generally replicates ::postfix::mta but works around
# the issue of transport_maps being force defined. Basically we just
# don't define it or the postfix::hash that goes along with it
class profile::smtp::userrelay {
  # setup the variables that ::postfix::mta would normally setup along
  # with the defaults that would usually happen
  $mydestination = hiera('postfix::mydestination', '$myorigin')
  $mynetworks    = hiera('postfix::mynetworks',
                          '127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128')
  # Special case to defaulting to direct, normally relayhost _must_ be
  # defined but there is a high probability that a mailman3 system will
  # be configured for direct delivery
  $relayhost     = hiera('postfix::relayhost', 'direct')

  validate_re($relayhost, '^\S+$',
              'Wrong value for $relayhost')
  validate_re($mydestination, '^\S+(?:\s*\S+)*$',
              'Wrong value for $mydestination')
  validate_re($mynetworks, '^(?:\S+?(?:(?:,\s)|(?:\s))?)*$',
              'Wrong value for $mynetworks')

  # If direct is specified then relayhost should be blank
  if ($relayhost == 'direct') {
    postfix::config { 'relayhost': ensure => 'blank' }
  }
  else {
    postfix::config { 'relayhost': value => $relayhost }
  }

  postfix::config {
    'mydestination':       value => $mydestination;
    'mynetworks':          value => $mynetworks;
    # lint:ignore:80chars
    'virtual_alias_maps':  value => 'hash:/etc/postfix/virtual, ldap:/etc/postfix/ldap-aliases';
    # lint:endignore
  }

  postfix::hash { '/etc/postfix/virtual':
    ensure => 'present',
  }

  # load virtual alias maps
  $virtual_aliases = hiera_hash('postfix::virtual', undef)
  if ($virtual_aliases) {
    ensure_hash($virtual_aliases)
    create_resources('postfix::virtual', $virtual_aliases)
  }
}
