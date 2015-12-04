define profile::nexus::third_party_plugin (
  $plugin_source
) {
  # get nexus info
  include ::nexus::params

  $nexus_user = hiera('nexus::nexus_user',
                  $nexus::params::nexus_user)
  $nexus_group = hiera('nexus::nexus_group',
                  $nexus::params::nexus_group)
  $nexus_work_dir = hiera('nexus::nexus_work_dir',
                      "${nexus::params::nexus_root}/sonatype-work/nexus")

  validate_string($nexus_user)
  validate_group($nexus_group)
  validate_absolute_path($nexus_work_dir)

  validate_re($plugin_source, [ '^file:', '^puppet:', '^https?:' ])

  $plugin_dir = "${nexus_work_dir}/plugin-repository"
  $plugin_cache = "${nexus_work_dir}/plugin_cache"

  if $plugin_source =~ /^(file|puppet)/ {
    if $plugin_source =~ /\.jar$/ {
      file { $name:
        ensure => file,
        path   => "${plugin_dir}/${name}.jar",
        source => $plugin_source,
        owner  => $nexus_user,
        group  => $nexus_group,
        notify => Service['nexus::service'],
      }
    } else {
      # source plugin for local deployment
      file { $name:
        ensure  => directory,
        path    => "${plugin_dir}/${name}",
        source  => $plugin_source,
        owner   => $nexus_user,
        group   => $nexus_group,
        recurse => true,
        notify  => Service['nexus::service'],
      }
    }
  } else {

    if $plugin_source =~ /\.jar$/ {
      include ::wget

      ::wget::fetch { "download ${name} nexus plugin":
        source      => $plugin_source,
        destination => "${plugin_dir}/${name}.jar",
        flags       => ['--timestamping'],
        timeout     => 0,
        verbose     => false,
        notify      => Service['nexus::service'],
      }
    } else {
      # archived bundles should only be zip
      validate_re($plugin_source, ['\.zip$'])

      ensure_resource('file', $plugin_cache, {
        'ensure' => 'directory',
      })

      archive { "install ${name} nexus plugin":
        url              => $plugin_source,
        target           => $plugin_dir,
        follow_redirects => true,
        extension        => 'zip',
        src_target       => $plugin_cache,
        root_dir         => $plugin_dir,
        notify           => Service['nexus::service'],
      }
    }
  }
}
