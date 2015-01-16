define gluon::mesh_direct_port (
    $ensure = 'present',
    $proto = 'tcp',
    $port = undef
) {
    firewall { "200 accept traffic to $port/$proto":
        ensure          => $ensure,
        table           => 'mangle',
        chain           => 'from_mesh',
        proto           => $proto,
	dport		=> $port,
        action          => accept,
    }

    firewall { "150 allow forward to $port/$proto":
        ensure          => $ensure,
        table           => 'filter',
        chain           => 'from_mesh',
        proto           => $proto,
	dport		=> $port,
        action          => accept,
    }

    firewall { "155 allow replies from $port/$proto to mesh":
        ensure          => $ensure,
        table           => 'filter',
        chain           => 'FORWARD',
        proto           => $proto,
        sport		=> $port,
        jump            => 'to_mesh',
    }

    firewall { "120 masquerade mesh traffic to $port/$proto":
        ensure          => $ensure,
        table           => 'nat',
        chain           => 'from_mesh',
        proto           => $proto,
	dport		=> $port,
	outiface	=> $::gluon::firewall::direct_iface,
        jump            => 'MASQUERADE',
    }
}

