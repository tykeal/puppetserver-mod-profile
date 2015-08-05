class profile::nagios::client {
#  include ::nagios::client

  # configure nrpe on clients
  include ::nrpe

  # open up the firewall on clients for nrpe
  $nrpe_port = hiera('nrpe::server_port', '5666')
  validate_integer($nrpe_port)

  $nrpe_hosts = hiera('nrpe::allowed_hosts', ['127.0.0.1'])
  validate_array($nrpe_hosts)

  # allowed hosts is an array and iptables doesn't do multi-ip in a
  # single rule so we're gonna lambda
  $nrpe_hosts.each |String $host| {
    firewall { "100 allow ${host} to nrpe":
      proto  => 'tcp',
      state  => ['NEW'],
      action => 'accept',
      port   => $nrpe_port,
      source => $host,
    }
  }

  # load all the nrpe::commands from all levels on the hierarchy. Most
  # specific instance of a given definition wins per standard "native"
  # merging
  $nrpe_commands = hiera_hash('nrpe::commands', undef)

  if ($nrpe_commands) {
    validate_hash($nrpe_commands)
    create_resources('nrpe::command', $nrpe_commands)
  }
}
