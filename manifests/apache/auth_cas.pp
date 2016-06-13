# Apache auth_cas profile
class profile::apache::auth_cas {
  include ::profile::apache
  include ::apache::mod::auth_cas
}
