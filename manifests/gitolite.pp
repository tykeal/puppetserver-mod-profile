# class ::profile::gitolite
class profile::gitolite {
  include ::profile::git
  include ::gitolite

  if hiera('gitolite::public_mirror', false) {
    include ::profile::git::daemon
  }

  # Make sure that profile git happens before gitolite
  Class['::profile::git'] ->
  Class['::gitolite']
}
