define profile::yum::versionlock::modify (
  $ensure = present,
  $path   = '/etc/yum/pluginconf.d/versionlock.list'
) {

  if ($name =~ /^[0-9]+:.+\*$/) {
    $_name = $name
  } elsif ($name =~ /^[0-9]+:.+-.+-.+\./) {
    $_name= "${name}*"
  } else {
    fail('Package name must be formatted as \'EPOCH:NAME-VERSION-RELEASE.ARCH\'')
  }

  case $ensure {
    present,absent,exclude: {
      if ($ensure == present) or ($ensure == absent) {
        file_line { "versionlock.list-${name}":
          ensure => $ensure,
          line   => $_name,
          path   => $path,
        }
      }

      if ($ensure == exclude) or ($ensure == absent) {
        file_line { "versionlock.list-!${name}":
          ensure => $ensure,
          line   => "!${_name}",
          path   => $path,
        }
      }
    }

    default: {
      fail("Invalid ensure state: ${ensure}")
    }
  }
}

