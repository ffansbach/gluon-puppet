# Definition: gluon::mesh_vpn
#
# This class installs a Mesh VPN server
#
# Parameters:
# - The $community name
# - The $ip4_address of this gateway within the Mesh network
# - The $ip4_netmask wrt. $ip4_address
# - The $ip6_address of this gateway within the Mesh network; /64 mask is assumed
# - The $ip6_prefix of the Mesh network with trailing double colons
# - The $fastd_port to configure fastd to listen on
# - The $forward_iface to which to forward all traffic; i.e. the tun device of your VPN
# - The $forward_accept list of IPv4 addresses to which to route without using the VPN
# - The $site_config option, whether to provide a gluon site directory
# - The $city_name to use throughout site/site.conf
# - The $auto_update_pubkey to list in the gluon site/site.conf
# - The $auto_update_seckey_file which contains the secret key to $auto_update_pubkey,
#       used to automatically sign sysupgrade manifest.  Leave empty to sign manually.
#
# Actions:
# - Install a Freifunk Mesh VPN server
#
# Requires:
# - The gluon class
#
# Sample Usage:
#
#  gluon::mesh_vpn { 'ffan':
#      ip6_address     => '2001:470:5168::2',
#      ip6_prefix      => '2001:470:5168::',
#      ip4_address     => '10.123.1.2',
#      ip4_netmask     => '255.255.255.0',
#      forward_iface   => 'tun+',
#      forward_accept  => [ '176.9.120.153/32', '176.9.129.236/32' ],
#  }
#
define gluon::mesh_vpn (
    $ensure             = 'present',
    $community          = $name,
    $city_name          = undef,

    $ip4_address        = undef,
    $ip4_netmask        = '255.255.255.0',

    $ip6_address        = undef,
    $ip6_prefix         = undef,

    $fastd_port         = 10000,

    $forward_iface      = false,
    $forward_accept     = [],

    $site_config                = true,
    $auto_update_pubkey         = undef,
    $auto_update_seckey_file    = undef,
) {
    include gluon


    # needed network interfaces
    #  - a batman device for the community
    #  - a bridge, which wraps the batman device
    network::interface { "br_$community":
        auto            => false,
        bridge_ports    => 'none',
        ipaddress       => $ip4_address,
        netmask         => $ip4_netmask,
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


    #
    # firewalling rules
    #

    # mark any traffic from the mesh to the internet with 0x2342;
    # used for policy based routing (to either tor or vpn) later on
    firewall { "200 mark $community traffic":
        table           => 'mangle',
        chain           => 'PREROUTING',
        proto           => 'all',
        iniface         => "br_$community",
        jump            => 'MARK',
        set_mark        => '0x2342/0xffffffff',
    }

    # ... and allow passing the traffic back and forth through forwarding filter
    firewall { "110 allow forward $community traffic":
        table           => 'filter',
        chain           => 'FORWARD',
        proto           => 'all',
        iniface         => "br_$community",
        source          => "$ip4_address/$ip4_netmask",
        outiface        => $forward_iface,
        action          => accept,
    }

    firewall { "110 allow replies to forwarded $community traffic":
        table           => 'filter',
        chain           => 'FORWARD',
        proto           => 'all',
        iniface         => $forward_iface,
        outiface        => "br_$community",
        destination     => "$ip4_address/$ip4_netmask",
        action          => accept,
    }

    # last not least masquerade outgoing traffic
    firewall { "120 masquerade $community traffic":
        table           => 'nat',
        chain           => 'POSTROUTING',
        proto           => 'all',
        source          => "$ip4_address/$ip4_netmask",
        outiface        => $forward_iface,
        jump            => 'MASQUERADE',
    }

    # special exception is traffic that may be routed directly,
    # according to $forward_accept parameter.
    mesh_forward { $forward_accept:
        community       => $community,
        mesh_net        => "$ip4_address/$ip4_netmask",
    }



    #
    # configure fastd instance
    #
    file { "/etc/fastd/$community":
        ensure      => directory,
        require     => Package['fastd'],
    }

    file { "/etc/fastd/$community/peers":
        ensure      => directory,
        group       => 'freifunker',
        mode        => 775,
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


    #
    # configure ipv6 router advertising daemon
    # FIXME probably should be possible to be disabled
    #
    concat::fragment { "radvd-$community":
        target      => "/etc/radvd.conf",
        content     => template('gluon/radvd.conf'),
    }


    if $site_config {
        gluon::site_config { $name:
            city_name           => $city_name,
            ip4_address         => $ip4_address,
            ip4_netmask         => $ip4_netmask,
            ip6_address         => $ip6_address,
            ip6_prefix          => $ip6_prefix,
            ntp_server          => $ip6_address,
            fastd_port          => $fastd_port,
            auto_update_pubkey  => $auto_update_pubkey,
        }
    }
}



# helper definition to map $forward_accept array of gluon::mesh_vpn type
# should *not* be used directly from external manifests
define mesh_forward ($community, $mesh_net) {
    firewall { "100 accept $community traffic to $name":
        table           => 'mangle',
        chain           => 'PREROUTING',
        proto           => 'all',
        iniface         => "br_$community",
        destination     => $name,
        action          => accept,
    }

    firewall { "110 allow forward $community traffic to $name":
        table           => 'filter',
        chain           => 'FORWARD',
        proto           => 'all',
        iniface         => "br_$community",
        source          => $mesh_net,
        destination     => $name,
        action          => accept,
    }

    firewall { "110 allow replies to forwarded $community traffic to $name":
        table           => 'filter',
        chain           => 'FORWARD',
        proto           => 'all',
        source          => $name,
        outiface        => "br_$community",
        destination     => $mesh_net,
        action          => accept,
    }

    firewall { "120 masquerade $community traffic to $name":
        table           => 'nat',
        chain           => 'POSTROUTING',
        proto           => 'all',
        source          => $mesh_net,
        destination     => $name,
        jump            => 'MASQUERADE',
    }
}
