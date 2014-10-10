class gluon::batman {
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
}
