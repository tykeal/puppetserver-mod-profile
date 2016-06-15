class profile::cobbler {
  # Main cobbler class
  # Parameters should be defined in hiera
  include ::cobbler

  include ::profile::cobbler::dhcp
  include ::profile::cobbler::selinux
  include ::profile::cobbler::firewall
  include ::profile::cobbler::kickstarts
  include ::profile::cobbler::snippets
  include ::profile::cobbler::objects

  # Apache configuration
  include ::profile::cobbler::apache

  # Cobbler's classes order
  Class['::cobbler'] ->
  Class['::profile::cobbler::apache'] ->
  Class['::profile::cobbler::selinux'] ->
  Class['::profile::cobbler::firewall'] ->
  Class[
    '::profile::cobbler::dhcp',
    '::profile::cobbler::kickstarts',
    '::profile::cobbler::snippets',
    '::profile::cobbler::objects'
  ]
}
