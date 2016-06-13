class profile::jenkins_job_builder {
  include ::python
  include ::jjb

  $jjb_users = hiera('users_jenkins_job_builder', undef)
  if ($jjb_users) {
    validate_hash($jjb_users)

    ::users { 'jenkins_job_builder': }
  }
}
