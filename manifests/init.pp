class gluon {
    package { 'bridge-utils':
        ensure => present,
    }

    sysctl { 'net.ipv4.ip_forward':
        value => '1'
    }

    sysctl { 'net.ipv6.conf.all.forwarding':
        value => '1'
    }

    apt::key { 'universe_factory':
        key         => '16EF3F64CB201D9C',
        key_server  => 'pgp.mit.edu',
    }

    apt::source { 'universe_factory':
        location    => 'http://repo.universe-factory.net/debian/',
        release     => 'sid',
        repos       => 'main',
        include_src => false,
        require     => Apt::Key['universe_factory'],
    }

    package { 'batman-adv-dkms':
        ensure      => present,
        require     => Apt::Source['universe_factory'],
    }

    package { 'batctl':
        ensure      => present,
        require     => Apt::Source['universe_factory'],
    }

    file { '/usr/local/sbin/install-batman-adv':
        ensure      => present,
        source      => 'puppet:///modules/gluon/install-batman-adv',
        mode        => 0755,
    }

    exec { 'install-batman-adv':
        command     => '/usr/local/sbin/install-batman-adv',
        unless      => '/usr/bin/test -f "/root/batman-adv-`uname -r`.stamp"',
        require     => File['/usr/local/sbin/install-batman-adv'],
    }

    kmod::load { 'batman-adv':
        require     => Exec['install-batman-adv'],
    }

    package { 'fastd':
        ensure      => 'present',
        require     => Apt::Source['universe_factory'],
    }

    class { 'apache':
        mpm_module      => 'prefork',
    }

    class { 'apache::mod::php':
    }

    package { 'dnsmasq':
        ensure      => present,
    }

    package { [ 'php5-mysql', 'php5-gmp', 'php5-curl', 'php5-gd' ]:
        ensure  => present,
    }

    package { 'rrdtool':
        ensure  => present,
    }

    package { 'exim4':
        ensure  => present,
    }

    service { 'fastd':
        ensure      => running,
        enable      => true,
        require     => Package['fastd'],
    }

    service { 'dnsmasq':
        ensure      => running,
        enable      => true,
        require     => [ Package['dnsmasq'] ],
    }

    file { '/etc/rc.local':
        ensure      => present,
        source      => 'puppet:///modules/gluon/rc.local',
        mode        => 0755,
    }

    package { 'radvd':
        ensure      => present,
    }

    concat { '/etc/radvd.conf':
        ensure      => present,
        notify      => Service['radvd'],
    }

    service { 'radvd':
        ensure      => running,
        require     => Package['radvd'],
    }
}
