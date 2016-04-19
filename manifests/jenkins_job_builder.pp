# class profile::jenkins_job_builder
class profile::jenkins_job_builder {
  include ::jjb

  #include ::jenkins_job_builder

  ## Extra ini configs this is not nearly as clean as I would like but
  ## given the current shortcomings of the module it's the best I can do
  ## to make sure we can add extra config bits
  #$extra_configs = hiera('jenkins_job_builder::extra_configs', undef)
  #if ($extra_configs)
  #{
  #  validate_hash($extra_configs)
  #  $jjb_config_defaults = {
  #    path => '/etc/jenkins_jobs/jenkins_jobs.ini',
  #  }

  #  create_ini_settings($extra_configs, $jjb_config_defaults)
  #}

  $jjb_users = hiera('users_jenkins_job_builder', undef)
  if ($jjb_users) {
    validate_hash($jjb_users)

    ::users { 'jenkins_job_builder': }
  }
}
