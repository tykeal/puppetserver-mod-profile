class profile::cobbler::selinux {
  # Setting up selinux booleans for cobbler
  selboolean {[
    'cobbler_can_network_connect',
    'httpd_can_network_connect_cobbler',
    'httpd_serve_cobbler_files'
  ]:
    persistent => true,
    value      => on,
  }

  include selinux::base
  # Fcontext for tftpboot directory
  selinux::fcontext {'/var/lib/tftpboot/boot':
    ensure    => 'present',
    recursive => true,
    setype    => 'cobbler_var_lib_t',
  }

}
