class profile::nagios::client {
  include ::nagios::client

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
      dport  => $nrpe_port,
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

  $nagios_plugin_path = hiera('nagios_plugin_path', '/usr/lib64/nagios/plugins')
  # we have a few nrpe commands that have need of dynamically generated
  # variables which we can't do in hiera

  #### check_total_procs

  # The following values are what CAF was using, LFCore had lower values
  $procwarn = $::processorcount * 28 + 600
  $procmax = $::processorcount * 32 + 800

  nrpe::command { 'check_total_procs':
    command => "${nagios_plugin_path}/check_procs -w ${procwarn} -c ${procmax}",
  }

  #### check_load
  $varwarn = 2
  $varcrit = 3

  if ($::processorcount < 6) {
    $warn01min = 12
    $warn05min = 10
    $warn15min = 8
    $crit01min = 22
    $crit05min = 18
    $crit15min = 14
  }
  else {
    $warn01min = $::processorcount * $varwarn
    $warn05min = $warn01min - $varwarn
    $warn15min = $warn01min - (2 * $varwarn)
    $crit01min = $::processorcount * $varcrit
    $crit05min = $crit01min - $varcrit
    $crit15min = $crit01min - (2 * $varcrit)
  }

  nrpe::command { 'check_load':
    command => "${nagios_plugin_path}/check_load -w ${warn01min},${warn05min},${warn15min} -c ${crit01min},${crit05min},${crit15min}"
  }
}
