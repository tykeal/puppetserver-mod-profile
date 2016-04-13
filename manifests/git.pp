class profile::git {
  # add in IUS repo so we can install git2u
  include ::ius

  include ::git
}
