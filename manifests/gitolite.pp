# class ::profile::gitolite
class profile::gitolite {
  include ::profile::git
  include ::gitolite

  # Make sure that profile git happens before gitolite
  Class['::profile::git'] ->
  Class['::gitolite']
}
