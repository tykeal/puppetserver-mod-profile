# Class: profile::zuul
class profile::zuul {
  include ::profile::python::venv
  include ::zuul

  $zuul_override = hiera('zuul::config_override', undef)
  if ($zuul_override) {
    validate_hash($zuul_override)

    if has_key($zuul_override, 'gearman_server') {
      if has_key($zuul_override['gearman_server'], 'start') {
        $open_gearmanport = $zuul_override['gearman_server']['start']
      }
    } else {
      $open_gearmanport = true
    }
  }

  if $open_gearmanport {
    firewall { '050 accept all gearman traffic':
      proto  => 'tcp',
      dport  => 7430, #zuul doesn't support listening on a different port
      state  => ['NEW'],
      action => accept,
    }
  }
}
