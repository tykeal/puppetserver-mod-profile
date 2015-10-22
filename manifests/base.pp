# This is the base profile. This should be included by all roles that we
# have in use
class profile::base {
  include ::profile::admin
  include ::profile::auditd
  include ::profile::external_facts
  include ::profile::firewall
  include ::profile::hardware
  include ::profile::nagios::client
  # do not config ntp temporarily
#  include ::profile::ntp
  include ::profile::pam
  include ::profile::puppetlabsrepo
  include ::profile::puppet::agent
  include ::profile::resolv_conf
  include ::profile::rkhunter
  include ::profile::rsyslog::client
  include ::profile::screen
  include ::profile::selinux
  # do not config smtp temporarily
#  include ::profile::smtp
  include ::profile::ssh::server
  include ::profile::sudo
  include ::profile::sysctl
  include ::profile::timezone
  include ::profile::vim
  include ::profile::shellenv
  include ::profile::yum::versionlock

  include ::profile::users::common

  if hiera('enable_totp', false) {
    include ::profile::totp::client
  }

  # hiera driven custom profile / class loads
  $custom_profiles = hiera_array('custom_profiles', undef)
  if ($custom_profiles) {
    hiera_include('custom_profiles')
  }
}
