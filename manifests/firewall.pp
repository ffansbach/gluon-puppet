class gluon::firewall (
    $forward_iface,
    $direct_iface,
) {
    # auto-install firewall rules on boot
    package { 'iptables-persistent':
        ensure => present,
    }

    ### FILTER RULES ###

    firewallchain { 'from_mesh:filter:IPv4':
        ensure  => present,
    }

    firewallchain { 'to_mesh:filter:IPv4':
        ensure  => present,
    }

    firewall { "100 run vpn reply traffic through to_mesh":
        table           => 'filter',
        chain           => 'FORWARD',
        proto           => 'all',
        iniface         => $forward_iface,
        jump            => 'to_mesh',
    }

    firewall { "100 allow mesh to mesh traffic":
        table           => 'filter',
        chain           => 'from_mesh',
        proto           => 'all',
        jump            => 'to_mesh',
    }

    firewall { "200 allow mesh to vpn exit":
        table           => 'filter',
        chain           => 'from_mesh',
        proto           => 'all',
        outiface        => $forward_iface,
        action          => accept,
    }

    firewall { "500 disallow other traffic from mesh":
        table           => 'filter',
        chain           => 'from_mesh',
        proto           => 'all',
        action          => 'reject',
    }


    ### MANGLE RULES ###

    firewallchain { 'from_mesh:mangle:IPv4':
        ensure  => present,
    }

    firewall { "900 mark mesh to vpn traffic":
        table           => 'mangle',
        chain           => 'from_mesh',
        proto           => 'all',
        jump            => 'MARK',
        set_mark        => '0x2342/0xffffffff',
    }


    ### NAT RULES ###

    firewallchain { 'from_mesh:nat:IPv4':
        ensure  => present,
    }

    firewall { "100 masquerade $community traffic":
        table           => 'nat',
        chain           => 'from_mesh',
        proto           => 'all',
        outiface        => $forward_iface,
        jump            => 'MASQUERADE',
    }
}
