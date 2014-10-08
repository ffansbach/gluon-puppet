define gluon::mesh_vpn (
    $ensure         = 'present',
    $community      = $name,

    $ip_address     = undef,
    $netmask        = '255.255.255.0',

    $ip6_address    = undef,
    $ip6_prefix     = undef,

    $fastd_port     = 10000,

    $forward_iface  = false,
) {
    include gluon

    network::interface { "br_$community":
        auto            => false,
        bridge_ports    => 'none',
        ipaddress       => $ip_address,
        netmask         => $netmask,
        post_up         => [
            "ip -6 a a $ip6_address/64 dev br_$community",
            "test -d /srv/netmon-$community && ip -6 a a ${ip6_prefix}42/64 dev br_$community"
        ],
        before          => Network::Interface["bat_$community"],
    }

    network::interface { "bat_$community":
        auto            => false,
        address         => false,
        family          => 'inet6',
        method          => 'manual',
        pre_up          => [
            "batctl -m bat_$community if add mesh_$community",
            "batctl -m bat_$community gw server",
            "ifup br_$community",
        ],
        up              => [
            "ip link set bat_$community up",
        ],
        post_up         => [
            "brctl addif br_$community bat_$community",
            "batctl -m bat_$community it 10000",
        ],
        pre_down        => [
            "brctl delif br_$community bat_$community || true",
        ],
        down            => [
            "ip link set bat_$community down",
        ],
        post_down       => [
            "ifdown br_$community || true",
        ],
        before          => Service['fastd'],
    }

    firewall { "100 mark $community traffic":
        table           => 'mangle',
        chain           => 'PREROUTING',
        proto           => 'all',
        iniface         => "br_$community",
        jump            => 'MARK',
        set_mark        => '0x2342/0xffffffff',
    }

    firewall { "110 allow forward $community traffic":
        table           => 'filter',
        chain           => 'FORWARD',
        proto           => 'all',
        iniface         => "br_$community",
        source          => "$ip_address/$netmask",
        outiface        => $forward_iface,
        action          => accept,
    }

    firewall { "110 allow replies to forwarded $community traffic":
        table           => 'filter',
        chain           => 'FORWARD',
        proto           => 'all',
        iniface         => $forward_iface,
        outiface        => "br_$community",
        destination     => "$ip_address/$netmask",
        action          => accept,
    }

    firewall { "120 masquerade $community traffic":
        table           => 'nat',
        chain           => 'POSTROUTING',
        proto           => 'all',
        source          => "$ip_address/$netmask",
        outiface        => $forward_iface,
        jump            => 'MASQUERADE',
    }

    file { "/etc/fastd/$community":
        ensure      => directory,
        require     => Package['fastd'],
    }

    file { "/etc/fastd/$community/peers":
        ensure      => directory,
    }

    exec { "/root/fastd-$community-key.txt":
        command     => "/usr/bin/fastd --generate-key >> /root/fastd-$community-key.txt",
        creates     => "/root/fastd-$community-key.txt",
        require     => Package['fastd'],
    }

    exec { "/etc/fastd/$community/secret.conf":
        command     => "/bin/sed -ne '/Secret:/ { s/Secret: /secret \"/; s/$/\";/; p }' /root/fastd-$community-key.txt > /etc/fastd/$community/secret.conf",
        creates     => "/etc/fastd/$community/secret.conf",
        require     => [ 
            Exec["/root/fastd-$community-key.txt"],
            File["/etc/fastd/$community"],
        ]
    }

    file { "/etc/fastd/$community/fastd.conf":
        ensure      => present,
        content     => template('gluon/fastd.conf'),
        notify      => Service['fastd'],
        before      => Service['fastd'],
    }

    concat::fragment { "radvd-$community":
        target      => "/etc/radvd.conf",
        content     => template('gluon/radvd.conf'),
    }
}
