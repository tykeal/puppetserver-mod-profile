# Reverses the staging repos
class profile::nexus::reverse_staging {
  include ::profile::python::venv
  include ::profile::git

  $lftools_venv = hiera('lftools::venv', '/opt/venv-lftools')
  $lftools_package = hiera('lftools::package', 'lftools')
  $lftools_ensure = hiera('lftools::ensure', 'latest')

  ::python::virtualenv { $lftools_venv:
    ensure     => present,
    version    => 'system',
    systempkgs => false,
    owner      => 'root',
    group      => 'root',
    cwd        => $lftools_venv,
  }

  ::python::pip { $lftools_package:
    ensure     => $lftools_ensure,
    virtualenv => $lftools_venv
  }

  # we'll just assume https since that's what our environment uses for
  # production systems
  $nginx_vhost = hiera('nginx::export::vhost')
  $nexus_admin = hiera('nexus::admin', 'admin')
  $nexus_pass = hiera('nexus::admin_pass')

  file { '/etc/reorder_staging-settings.yaml':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    # yamllint disable-line rule:line-length
    content => template("${module_name}/nexus/reorder_staging-settings.yaml.erb"),
  }
}
