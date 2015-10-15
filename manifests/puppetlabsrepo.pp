# class profile::puppetlabsrepo
class profile::puppetlabsrepo {
  package { 'puppetlabs-release':
    ensure   => installed,
    source   => 'http://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm',
    provider => rpm,
  }
}
