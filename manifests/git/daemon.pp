# class profile::git::daemon
class profile::git::daemon {
  include ::profile::git
  include ::xinetd

  Class['::profile::git'] ->
  Class['::profile::git::daemon']

  # always default to normal upstream git package
  $gitpackage = hiera('git::package_name', 'git')
  $git_daemon = "${gitpackage}-daemon"

  $gitd_user = hiera('gitd::user', 'nobody')
  $gitd_group = hiera('gitd::group', 'nobody')
  validate_string($gitd_user)
  validate_string($gitd_group)

  # install the appropriate git daemon
  ensure_packages ( [
      $git_daemon,
    ],
      {
        ensure => 'present'
      }
    )

  $gitd_repos_path = hiera('gitd::repopath', '/var/lib/git')
  validate_absolute_path($gitd_repos_path)

  $gitd_server_args = hiera('gitd::xinetd::server_args',
    # lint:ignore:80chars
    "--base-path=${gitd_repos_path} --init-timeout=10 --timeout=600 --export-all --syslog --inetd --verbose")
    # lint:endignore
  validate_string($gitd_server_args)

  $gitd_xinetd_cps = hiera('gitd::xinetd::cps', '4096 10')
  validate_string($gitd_xinetd_cps)

  ::profile::firewall::rule { 'git daemon traffic from all':
    priority => '050',
    proto    => 'tcp',
    dport    => '9418',
    state    => ['NEW'],
    action   => 'accept',
  }

  xinetd::service { 'git':
    server         => '/usr/libexec/git-core/git-daemon',
    port           => 9418,
    user           => $gitd_user,
    group          => $gitd_group,
    log_type       => 'SYSLOG daemon info',
    log_on_success => 'PID HOST DURATION EXIT',
    log_on_failure => 'HOST',
    server_args    => $gitd_server_args,
    cps            => $gitd_xinetd_cps,
    per_source     => 'UNLIMITED',
    instances      => 'UNLIMITED',
    require        => Package[$git_daemon],
  }

  # Nagios configuration
  include ::nagios::params
  $nagios_plugin_dir = hiera('nagios_plugin_dir')
  # get data needed for exported creating services
  $nagios_tag = hiera('nagios::client::nagiostag', '')
  $defaultserviceconfig = hiera('nagios::client::defaultserviceconfig',
    $::nagios::params::defaultserviceconfig)

  # Monitor git service
  nrpe::command {
    'check_gitd_local_port':
      command => "${nagios_plugin_dir}/check_tcp -H localhost -p 9418"
  }

  nagios::resource { "NRPE-Gitd-TCP-${::fqdn}":
    resource_type      => 'service',
    defaultresourcedef => $defaultserviceconfig,
    nagiostag          => $nagios_tag,
    resourcedef        => {
      service_description => 'NRPE - Gitd TCP port 9418 Listening',
      check_command       => 'check_nrpe!check_gitd_local_port',
    },
  }
}
