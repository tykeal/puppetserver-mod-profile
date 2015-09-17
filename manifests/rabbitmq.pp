class profile::rabbitmq {
  include ::rabbitmq
  include ::erlang

  selboolean { 'nis_enabled':
    persistent => true,
    value      => on,
  }

  $ssl_port=hiera('rabbitmq::ssl_stomp_port',61614)
  validate_integer($ssl_port)

  firewall { '050 accept incoming rabbitmq/stomp/mco ssl traffic':
    proto  => 'tcp',
    port   => $ssl_port,
    state  => ['NEW'],
    action => accept,
  }

  file { '/etc/rabbitmq/ssl/ca.crt':
    ensure   => present,
    owner    => 'rabbitmq',
    group    => 'rabbitmq',
    seltype  => 'cert_t',
    seluser  => 'system_u',
    selrole  => 'object_r',
    mode     => '0600',
    source   => "file://${::settings::cacert}"
  }

  file { "/etc/rabbitmq/ssl/${::fqdn}.crt":
    ensure   => present,
    owner    => 'rabbitmq',
    group    => 'rabbitmq',
    seltype  => 'cert_t',
    seluser  => 'system_u',
    selrole  => 'object_r',
    mode     => '0600',
    source   => "file://${::settings::certdir}/${::fqdn}.pem"
  }

  file { "/etc/rabbitmq/ssl/${::fqdn}.key":
    ensure   => present,
    owner    => 'rabbitmq',
    group    => 'rabbitmq',
    seltype  => 'cert_t',
    seluser  => 'system_u',
    selrole  => 'object_r',
    mode     => '0600',
    source   => "file://${::settings::privatedir}/${::fqdn}.pem"
  }

  file { 'rabitmqadmin':
    path     => "${rabbitmq::rabbitmq_home}/rabbitmqadmin",
    ensure   => present,
    owner    => 'root',
    group    => 'root',
    seltype  => 'rabbitmq_var_lib_t',
    seluser  => 'unconfined_u',
    selrole  => 'object_r',
    mode     => '0755',
    source   => "puppet:///modules/${module_name}/rabbitmq/rabbitmqadmin",
  }

  $rabbitmq_vhosts = hiera_hash('rabbitmq::rabbitmq_vhost', undef)
  if is_hash($rabbitmq_vhosts) {
    create_resources( rabbitmq_vhost, $rabbitmq_vhosts )
  }

  $rabbitmq_exchanges = hiera_hash('rabbitmq::rabbitmq_exchange', undef)
  if is_hash($rabbitmq_exchanges) {
    create_resources( rabbitmq_exchange, $rabbitmq_exchanges )
  }

  $rabbitmq_users = hiera_hash('rabbitmq::rabbitmq_user', undef)
  if is_hash($rabbitmq_users) {
    create_resources( rabbitmq_user, $rabbitmq_users )
  }

  $rabbitmq_user_permissions = hiera_hash('rabbitmq::rabbitmq_user_permissions', undef)
  if is_hash($rabbitmq_user_permissions) {
    create_resources( rabbitmq_user_permissions, $rabbitmq_user_permissions )
  }

  $rabbitmq_plugins = hiera_hash('rabbitmq::rabbitmq_plugin', undef)
  if is_hash($rabbitmq_plugins) {
    create_resources( rabbitmq_plugin, $rabbitmq_plugins )
  }
}
