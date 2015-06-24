class profile::smtp {
  # force load of ::augeas or a satellite system configuration will fail
  include ::augeas

  # primary postfix configuration
  include ::postfix

  # load any extra configurations that need to happen
  $postfix_configs = hiera_hash('postfix::configs', undef)
  if is_hash($postfix_configs) {
    create_resources(::postfix::config, $postfix_configs)
  }

  $postfix_transports = hiera_hash('postfix::transports', undef)
  if is_hash($postfix_transports) {
    create_resources(::postfix::transport, $postfix_transports)
  }

  $postfix_virtuals = hiera_hash('postfix::virtuals', undef)
  if is_hash($postfix_virtuals) {
    create_resources(::postfix::virtual, $postfix_virtuals)
  }

  # handle opening the firewall when we're an mta (we don't need this
  # for satellite systems)
  $mta = hiera('postfix::mta', false)
  if ($mta) {
    # SMTP operates on port 25 by definition, if the server isn't
    # operating on that port there is likely an issue
    firewall { '025 accept all SMTP traffic':
      proto  => 'tcp',
      port   => ['25'],
      state  => ['NEW'],
      action => accept,
    }
  }
}
