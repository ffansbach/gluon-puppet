# Definition: gluon
#
# This class prepares the node for installation of one (ore more) Mesh VPN servers
#
# You usually don't need to declare/include this class directly,
# just declare gluon::mesh_vpn instances and it will include this class as needed.
#
class gluon (
    $gateway            = true,
    $peers_basedir      = '/home/freifunker/peers',
    $github_owner       = undef,
    $github_repo        = undef,
) {
    # include universe_factory apt repository for batman & fastd packages
    apt::key { 'universe_factory':
        id      => '6664E7BDA6B669881EC52E7516EF3F64CB201D9C',
        server  => 'pgp.mit.edu',
    }

    apt::source { 'universe_factory':
        location    => 'http://repo.universe-factory.net/debian/',
        release     => 'sid',
        repos       => 'main',
        require     => Apt::Key['universe_factory'],
    }

    include "gluon::batman"
    include "gluon::monitoring"

    if $gateway {
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
    }

    # install haveged for proper entropy
    package { 'haveged':
        ensure      => 'present',
    }

    service { 'haveged':
        ensure      => running,
	enable      => true,
	require     => Package['haveged'],
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

    file { "/home/freifunker/bin/":
        ensure      => directory,
        owner       => "freifunker",
        group       => "freifunker",
    }

    file { '/home/freifunker/bin/sync-peers':
        ensure      => present,
        source      => 'puppet:///modules/gluon/sync-peers',
        mode        => '0755',
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

    # configure git for freifunker
    exec { "git-author-name":
       path    => ['/usr/bin', '/usr/sbin', '/bin'],
       command => 'git config --global user.name "Gluon Gateway Robot"',
       unless  => "git config --global --get user.name|grep 'Gluon Gateway Robot'",
       user    => 'freifunker',
       environment => ["HOME=/home/freifunker"],
    }
    exec { "git-author-email":
       path    => ['/usr/bin', '/usr/sbin', '/bin'],
       command => 'git config --global user.email "freifunker@$(hostname -f)"',
       unless  => "git config --global --get user.email|grep 'freifunker@$(hostname -f)'",
       user    => 'freifunker',
       environment => ["HOME=/home/freifunker"],
    }

    file { $peers_basedir:
        ensure      => directory,
        group       => 'freifunker',
        mode        => '0775',
    }

    if $github_owner and $github_repo {
        exec { "$peers_basedir/.git":
            command     => "/usr/bin/git clone https://github.com/$github_owner/$github_repo.git .",
            cwd         => "$peers_basedir",
            creates     => "$peers_basedir/.git",
            require     => File["$peers_basedir"],
            user        => "freifunker",
        }

        cron { "sync_push":
            command => "/home/freifunker/bin/sync-peers",
            user    => "freifunker",
            minute  => "*/15",
        }
    }

    exec { "freifunker-ssh-key":
        command     => "/usr/bin/ssh-keygen -qf /home/freifunker/.ssh/id_rsa -N ''",
        creates     => "/home/freifunker/.ssh/id_rsa",
        user        => "freifunker",
        environment => "HOME=/home/freifunker/",
    }

    if $gateway {
        # install dnsmasq dns/dhcp server
        package { 'dnsmasq':
            ensure      => present,
        }

        file { "/etc/dnsmasq.d/_options.conf":
            ensure      => present,
            source      => 'puppet:///modules/gluon/dnsmasq-options.conf',
            notify      => Service['dnsmasq'],
            require     => Package['dnsmasq'],
        }

        service { 'dnsmasq':
            ensure      => running,
            enable      => true,
            require     => [ Package['dnsmasq'] ],
        }
    }


    # configure policy based routing
    # FIXME shouldn't overwrite /etc/rc.local
    file { '/etc/rc.local':
        ensure      => present,
        source      => 'puppet:///modules/gluon/rc.local',
        mode        => '0755',
    }


    if $gateway {
        # install ntp service
        package { 'ntp':
            ensure      => present,
        }


        # vpn gateway control scripts
        concat { '/usr/local/sbin/ffgw-on':
            ensure      => present,
            mode        => '0755',
        }

        concat::fragment { "ffgw-on-base":
        target      => "/usr/local/sbin/ffgw-on",
        content     => "#! /bin/sh\n# auto-generated by puppet\npuppet agent --enable\niptables -D INPUT -p udp --dport bootps -j REJECT\n",
        }

        concat { '/usr/local/sbin/ffgw-off':
            ensure      => present,
            mode        => '0755',
        }

        concat::fragment { "ffgw-off-base":
        target      => "/usr/local/sbin/ffgw-off",
        content     => "#! /bin/sh\n# auto-generated by puppet\npuppet agent --disable\niptables -I INPUT -p udp --dport bootps -j REJECT\n",
        }
    }

    # install cron-apt
    package { 'cron-apt':
        ensure      => present,
    }

    package { [ 'gawk', 'g++', 'subversion', 'libncurses5-dev', 'zlib1g-dev' ]:
        ensure      => present,
    }
}
