class profile::mcollective {
  include ::mcollective

  # A system level ruby is required for mcollective fact gathering
  # instead of doing an ensure_packages we'll use the safer include of
  # the ruby module which installs both ruby and rubygems by default
  # which is exactly what is needed
  include ::ruby

  Sslmgmt::Ca_dh <||> ->
  Sslmgmt::Cert <||> ->
  File <| title == "${mcollective::confdir}/server_public.pem" |> ->
  File <| title == "${mcollective::confdir}/server_private.pem" |>

  $mcollective_certs = hiera_hash('mcollective::certs', undef)
  if is_hash($mcollective_certs) {
    create_resources( sslmgmt::cert, $mcollective_certs )
  }

  $mcollective_clientcerts = hiera_hash('mcollective::clientcerts', undef)
  if is_hash($mcollective_clientcerts) {
    create_resources( sslmgmt::ca_dh, $mcollective_clientcerts )
  }

  file {'/usr/local/libexec/mcollective':
    ensure => directory,
  }
  file {'/opt/puppetlabs/mcollective':
    ensure => directory,
  }
  file {'/opt/puppetlabs/mcollective/plugins/':
    ensure  => directory,
    require => File['/opt/puppetlabs/mcollective']
  }

  $mcollective_plugins = hiera_hash('mcollective::plugins', undef)
  if is_hash($mcollective_plugins) {
    create_resources( mcollective::plugin, $mcollective_plugins )
  }

  $mcollective_users = hiera_hash('mcollective::users', undef)
  if is_hash($mcollective_users) {
    create_resources( mcollective::user, $mcollective_users )
  }

  package { 'puppet':
    ensure   => 'installed',
    provider => 'gem',
  }

  package { 'facter':
    ensure   => 'installed',
    provider => 'gem',
  }
}
