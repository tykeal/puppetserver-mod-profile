class profile::ssh {
  # all systems need to have ssh configured
  # for now we only configure sshd
  include ::ssh

  $ssh_server_options = hiera('ssh::server_options', undef)

  if ($ssh_server_options) {
    validate_hash($ssh_server_options)

    if has_key($ssh_server_options, 'Port')
    {
      $dport = $ssh_server_options['Port']
    }
    else
    {
      $dport = 22
    }
  }
  else
  {
    $dport = 22
  }

  # make sure we accept SSH traffic through the firewall
  firewall { '005 accept all SSH traffic':
    proto  => 'tcp',
    dport  => $dport,
    state  => ['NEW'],
    action => accept,
  }
}
