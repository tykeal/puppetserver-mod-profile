# class profile::cobbler::apache
class profile::cobbler::apache {
  # Apache profile
  include ::profile::apache

  # Apache modules required for cobbler
  include ::apache::mod::wsgi
  include ::apache::mod::proxy
  include ::apache::mod::proxy_http
}
