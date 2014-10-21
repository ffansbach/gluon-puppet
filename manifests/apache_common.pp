# Definition: gluon::apache_common
#
# This class prepares the node for apache configurations needed by Mesh VPN servers
# and netmon.
#
# You usually don't need to declare/include this class directly,
# just declare gluon::mesh_vpn instances and it will include this class as needed.
#
class gluon::apache_common {
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
}
