class profile::cobbler {
  # Main cobbler class
  # Parameters should be defined in hiera
  include ::cobbler

  include ::profile::cobbler::dhcp
  include ::profile::cobbler::selinux
  # Pending this as we don't have kickstarts files yet
  #include ::profile::cobbler::kickstarts
  include ::profile::cobbler::objects

  Class['cobbler'] ->
  Class[
    '::profile::cobbler::dhcp',
    #'::profile::cobbler::kickstarts',
    '::profile::cobbler::selinux',
    '::profile::cobbler::objects'
  ]
}
