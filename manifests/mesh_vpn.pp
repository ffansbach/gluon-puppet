define gluon::mesh_vpn (
    $ensure         = 'present',
    $community      = $name,

    $ip_address     = undef,
    $netmask        = '255.255.255.0',

    $ip6_address    = undef,

    $fastd_port     = 10000,
) {
    include gluon

    network::interface { "br-$community":
        auto            => false,
        bridge_ports    => 'none',
        ipaddress       => $ip_address,
        netmask         => $netmask,
        post_up         => [
            "iptables -t mangle -I PREROUTING -i br-$community -j MARK --set-mark 0x2342/0xffffffff",
            "ip -6 a a $ip6_address/64 dev br-$community",
        ],
        before          => Network::Interface["bat-$community"],
    }

    network::interface { "bat-$community":
        auto            => false,
        address         => false,
        family          => 'inet6',
        method          => 'manual',
        pre_up          => [
            "batctl -m bat-$community if add mesh-$community",
            "batctl -m bat-$community gw server",
            "ifup br-$community",
        ],
        up              => [
            "ip link set bat-$community up",
        ],
        post_up         => [
            "brctl addif br-$community bat-$community",
            "batctl -m bat-$community it 10000",
        ],
        pre_down        => [
            "brctl delif br-$community bat-$community || true",
        ],
        down            => [
            "ip link set bat-$community down",
        ],
        post_down       => [
            "ifdown br-$community || true",
        ],
        before          => Service['fastd'],
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

}
