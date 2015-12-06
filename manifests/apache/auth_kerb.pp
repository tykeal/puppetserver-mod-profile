# Apache auth_kerb profile
class profile::apache::auth_kerb {
  include ::profile::apache
  include ::apache::mod::auth_kerb
}
