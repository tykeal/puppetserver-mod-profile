class profile::cobbler::kickstarts {
  # Preparing kickstart files
  $kickstarts_dir = hiera(
    'cobbler::kickstarts_dir',
    '/var/lib/cobbler/kickstarts'
  )

  file {$kickstarts_dir:
    ensure       => 'present',
    owner        => 'root',
    group        => 'root',
    mode         => '0644',
    purge        => true,
    recurse      => true,
    recurselimit => 1,
    seltype      => 'cobbler_var_lib_t',
    seluser      => 'system_u',
    selrole      => 'object_r',
    source       => 'puppet:///modules/profile/cobbler/kickstarts',
    require      => Class['cobbler'],
  }

}
