class profile::smtp {
  $configurerelay = hiera('configurerelay')
  validate_bool($configurerelay)

  if $configurerelay {
    # default to configuring mail relay
    include ::postfix::relay
  }
  else {
    # fully manage the mail config
    # this requires a full postfix::config definition in hiera
    include ::postfix::config
  }
}
