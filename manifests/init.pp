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
    include "gluon::firewall"



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

    user { 'freifunker':
        ensure      => present,
        gid         => 'freifunker',
        managehome  => true,
    }

    file { "/home/freifunker":
        ensure      => directory,
        owner       => "freifunker",
        group       => "freifunker",
    }

    file { "/home/freifunker/.ssh/":
        ensure      => directory,
        owner       => "freifunker",
        group       => "freifunker",
    }

    file { "/home/freifunker/.ssh/known_hosts":
        ensure      => present,
        content     => "|1|IwcxiCc7BkaDcmD9L1wTFum+naM=|ROZQO+Mse4jREuOfXGZ8RnKXnEo= ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==\n",
        replace     => false,
        owner       => "freifunker",
        group       => "freifunker",
    }

    exec { "freifunker-ssh-key":
        command     => "/usr/bin/ssh-keygen -qf /home/freifunker/.ssh/id_rsa -N ''",
        creates     => "/home/freifunker/.ssh/id_rsa",
        user        => "freifunker",
        environment => "HOME=/home/freifunker/",
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

    concat::fragment { "radvd-$community":
	target      => "/etc/radvd.conf",
	content     => "",
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
