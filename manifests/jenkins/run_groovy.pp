# == Define: profile::jenkins::run_groovy
#
# This define is used for running a groovy script against a jenkins
# master
#
# === Parameters:
#
# [*groovy_script*]
#   The name of the groovy script in /etc/jenkins to be run.
#   This defaults to the title of the define.
#   NOTE: the name used should _not_ have a .groovy suffix as this will
#   be appended during the run.
#   NOTE: Scripts are expected to be able to be run idempotently! As
#   such please make sure the scripts do their own validation that they
#   need to make changes!
#
# [*script_args*]
#   Arguments to be passed to the groovy script. Defaults to an empty
#   string
#
# [*use_auth*]
#   Should authentication be used? Default: true
#   If true then a jenkins login using /etc/jenkins/jenkinsadmin.txt as
#   the password file will be done before the groovy script is actually
#   run. After the run a logout will be performed
#
# === Examples
#
# profile::jenkins::run_groovy { 'set_ldap_auth':
#   use_auth     => false,
# }
#
define profile::jenkins::run_groovy (
  $groovy_script = $title,
  $script_args   = '',
  $use_auth      = true,
) {
  # We can't seem to do a relationship lock against ::jenkins so we'll
  # just do an include (this should _hopefully_ take care of our issues)
  include ::jenkins

  if $::jenkins::service_ensure == 'stopped' or $::jenkins::service_ensure == false {
    fail('Management of Jenkins via groovy requires \$::jenkins::service_ensure to be set to \'running\'')
  }

  $groovy_loc  = $::profile::jenkins::groovy_loc
  $jenkins_cli = $::jenkins::cli::cmd

  # set our SSH identity if we need auth
  if ($use_auth) {
    $auth_cmd = "-i ${groovy_loc}/.ssh/jenkins_admin"
  }
  else {
    $auth_cmd = ''
  }

  # execute the script
  exec { "jenkins groovy for ${title}":
    path      => ['/usr/bin', '/usr/sbin', '/bin'],
    command   => "${jenkins_cli} ${auth_cmd} groovy ${groovy_loc}/${groovy_script}.groovy ${script_args}",
    logoutput => false,
  }
}
