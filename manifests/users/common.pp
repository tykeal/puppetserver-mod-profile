class profile::users::common {
  # users define does a hiera lookup composition of users_${name} by
  # default
  ::users { 'common': }
}
