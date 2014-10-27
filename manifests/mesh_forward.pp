define gluon::mesh_forward (
    $ensure = 'present',
    $destination = $name,
) {
    firewall { "200 accept traffic to $name":
        ensure          => $ensure,
        table           => 'mangle',
        chain           => 'from_mesh',
        proto           => 'all',
        destination     => $destination,
        action          => accept,
    }

    firewall { "150 allow forward to $name":
        ensure          => $ensure,
        table           => 'filter',
        chain           => 'from_mesh',
        proto           => 'all',
        destination     => $destination,
        action          => accept,
    }

    firewall { "155 allow replies from $name to mesh":
        ensure          => $ensure,
        table           => 'filter',
        chain           => 'FORWARD',
        proto           => 'all',
        source          => $destination,
        jump            => 'to_mesh',
    }

    firewall { "120 masquerade mesh traffic to $name":
        ensure          => $ensure,
        table           => 'nat',
        chain           => 'from_mesh',
        proto           => 'all',
        destination     => $destination,
        jump            => 'MASQUERADE',
    }
}
