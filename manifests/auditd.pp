class profile::auditd {
  include ::auditd

  if hiera('auditd::enable_syslog', false) {
    include ::auditd::audisp::syslog
  }

}
