class profile::cobbler::snippets {
  $snippets_dir = hiera(
    'cobbler::snippets_dir',
    '/var/lib/cobbler/snippets'
  )
  # purge => false as we have a lot of cobbler's snippets there already
  # just add lf_* snippets from cobbler profile
  file {$snippets_dir:
    ensure       => 'present',
    owner        => 'root',
    group        => 'root',
    mode         => '0644',
    purge        => false,
    recurse      => true,
    recurselimit => 1,
    seltype      => 'cobbler_var_lib_t',
    seluser      => 'system_u',
    selrole      => 'object_r',
    source       => 'puppet:///modules/profile/cobbler/snippets',
    require      => Class['cobbler'],
  }
}
