class profile::helios {
  include ::uwsgi
  include ::python


  $base_dir = hiera('helios::basedir',  '/opt/helios-web')
  $user     = hiera('helios::user',     'helios')
  $group    = hiera('helios::group',    'helios')
  $port     = hiera('helios::port',     ['8080'])
  # lint:ignore:80chars
  $repo_url = hiera('helios::repo_url', 'https://github.com/benadida/helios-server.git')
  $repo_ref = hiera('helios::repo_ref', 'f5dc954c12eacbeb221646511e47537307a941aa')
  # lint:endignore

  $db_engine_pkgs = ['MySQL-python', 'postgresql-devel']

  validate_absolute_path($base_dir)
  validate_array($port)
  validate_string($user)
  validate_string($group)
  validate_string($repo_url)
  validate_string($repo_ref)

  user {$user:
    ensure     => 'present',
    comment    => 'Helios web user',
    managehome => true,
    shell      => '/bin/bash',
  }
  file { [$base_dir, "${base_dir}/helios"]:
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => '0755',
    require => User[$user],
  }
  vcsrepo {"${base_dir}/helios":
    ensure   => 'present',
    owner    => $user,
    group    => $group,
    provider => 'git',
    source   => $repo_url,
    revision => $repo_ref,
    require  => [
      User[$user],
      File[$base_dir],
    ]
  }

  package {$db_engine_pkgs:
    ensure => 'present',
  }

  ::python::virtualenv {"${base_dir}/virtualenv":
    ensure       => 'present',
    version      => 'system',
    systempkgs   => true,
    requirements => "${base_dir}/helios/requirements.txt",
    owner        => $user,
    group        => $group,
    cwd          => "${base_dir}/virtualenv",
    timeout      => 0,
    require      => [
      Vcsrepo["${base_dir}/helios"],
      Package[$db_engine_pkgs],
    ],
  }

  firewall { '030 accept incoming uwsgi traffic':
    proto  => 'tcp',
    port   => $port,
    state  => ['NEW'],
    action => accept,
  }
}
