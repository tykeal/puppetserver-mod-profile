# class profile::puppetlabsrepo
class profile::puppetlabsrepo {

  # Cleanup old puppetlabs-release that's still on some older el7 machines
  package { 'puppetlabs-release':
    ensure   => absent,
  }

  # We don't want this package since we're managing it below with yumrepos
  package { 'puppetlabs-release-pc1':
    ensure   => absent,
  }

  yumrepo { 'puppetlabs-pc1':
    baseurl  => 'http://yum.puppetlabs.com/el/7/PC1/$basearch',
    descr    => 'Puppet Labs PC1 Repository el 7 - $basearch',
    gpgkey   => 'http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs',
    enabled  => 1,
    gpgcheck => 1,
    require  => Package['puppetlabs-release-pc1'],
  }

  # We probably don't need this, but it's in the rpm provided repo so I left it
  yumrepo { 'puppetlabs-pc1-source':
    baseurl        => 'http://yum.puppetlabs.com/el/7/PC1/SRPMS',
    descr          => 'Puppet Labs PC1 Repository el 7 - Source',
    gpgkey         => 'http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs',
    enabled        => 0,
    failovermethod => 'priority',
    gpgcheck       => 1,
    require        => Package['puppetlabs-release-pc1'],
  }

}
