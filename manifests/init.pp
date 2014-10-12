# Definition: gluon
#
# This class prepares the node for installation of one (ore more) Mesh VPN servers
#
# You usually don't need to declare/include this class directly,
# just declare gluon::mesh_vpn instances and it will include this class as needed.
#
class gluon {
    # include universe_factory apt repository for batman & fastd packages
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

    include "gluon::batman"


    # install bridge-utils to configure bridge interface wrapping batman device
    package { 'bridge-utils':
        ensure => present,
    }


    # configure ip forwarding for IPv4 & IPv6
    sysctl { 'net.ipv4.ip_forward':
        value => '1'
    }

    sysctl { 'net.ipv6.conf.all.forwarding':
        value => '1'
    }


    # install fastd vpn service
    package { 'fastd':
        ensure      => 'present',
        require     => Apt::Source['universe_factory'],
    }

    service { 'fastd':
        ensure      => running,
        enable      => true,
        require     => Package['fastd'],
    }

    # seperate group for peers folders so people can add files there
    group { 'freifunker':
        ensure      => present,
    }


    # install dnsmasq dns/dhcp server
    package { 'dnsmasq':
        ensure      => present,
    }

    service { 'dnsmasq':
        ensure      => running,
        enable      => true,
        require     => [ Package['dnsmasq'] ],
    }


    # install apache & php stack
    class { 'apache':
        mpm_module      => 'prefork',
        manage_user     => false,
    }

    user { 'www-data':
        ensure          => present,
        groups          => [ 'freifunker' ],
        require         => Group['freifunker'],
    }

    class { 'apache::mod::php':
    }

    package { [ 'php5-mysql', 'php5-gmp', 'php5-curl', 'php5-gd' ]:
        ensure  => present,
    }


    # netmon needs rrdtool
    package { 'rrdtool':
        ensure  => present,
    }


    # netmon needs a mail transfer agent
    package { 'exim4':
        ensure  => present,
    }


    # configure policy based routing
    # FIXME shouldn't overwrite /etc/rc.local
    file { '/etc/rc.local':
        ensure      => present,
        source      => 'puppet:///modules/gluon/rc.local',
        mode        => 0755,
    }


    # install radvd and prepare config collection
    # snippets for /etc/radvd.conf provided by gluon::mesh_vpn
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


    # install ntp service
    package { 'ntp':
        ensure      => present,
    }
}
