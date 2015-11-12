# This is the base profile. This should be included by all roles that we
# have in use
class profile::base {
  include ::profile::admin
  include ::profile::auditd
  include ::profile::bacula::client
  include ::profile::external_facts
  include ::profile::firewall
  include ::profile::hardware
  include ::profile::nagios::client
  include ::profile::ntp
  include ::profile::pam
  include ::profile::puppetlabsrepo
  include ::profile::puppet::agent
  include ::profile::resolv_conf
  include ::profile::rkhunter
  include ::profile::rsyslog::client
  include ::profile::screen
  include ::profile::selinux
  include ::profile::smtp
  include ::profile::ssh::server
  include ::profile::sudo
  include ::profile::sysctl
  include ::profile::timezone
  include ::profile::vim
  include ::profile::shellenv
  include ::profile::yum::versionlock

  # load profiles needed for lfcore
  if hiera('lfcorehost', false) {
    include ::profile::users::common
    include ::profile::users::root
  } else {
    include ::profile::totp::client
  }

  # load profile for GCE
  if hiera('gcehost', false) {
    include ::profile::gce
  }


  # hiera driven custom profile / class loads
  $custom_profiles = hiera_array('custom_profiles', undef)
  if ($custom_profiles) {
    hiera_include('custom_profiles')
  }

  # clean-up ::1 hosts entry unless we need ipv6
  # this is a temporary measure until we verify if adding
  # ghoneycutt/hosts will break totp::client since it pushes a forced
  # hosts entry. It might be apropo to make that module just depend on
  # ghoneycutt/hosts....
  $enable_ipv6 = hiera('enable_ipv6', false)
  unless ($enable_ipv6) {
    file_line { 'remove localhost6 from hosts':
      ensure => absent,
      path   => '/etc/hosts',
      line   => '::1 localhost', # required and matchable by match
      match  => '^::1',
    }
  }
}
