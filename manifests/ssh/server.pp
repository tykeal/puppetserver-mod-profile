class profile::ssh::server {
  # all systems need to have ssh configured
  # for now we only configure sshd
  class { '::ssh::server': }

  $ssh_server_options = hiera('ssh::server::options')

  # make sure we accept SSH traffic through the firewall
  firewall { '005 accept all SSH traffic':
    proto  => 'tcp',
    port   => $ssh_server_options['Port'],
    state  => ['NEW'],
    action => accept,
  }
}
