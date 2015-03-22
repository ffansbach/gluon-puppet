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
# - The $site_config option, whether to provide a gluon site directory
# - The $city_name to use throughout site/site.conf
# - The $dhcp_range_start and $dhcp_range_end
# - The $dhcp_leasetime
# - The $mtu of the mesh vpn device
# - The $gateway_ipaddr of this gateway (used by other nodes to connect to here)
# - The $github_repo to sync peers files to and from
# - The $github_owner of the repo.
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
    $mtu                = 1426,

    $dhcp_range_start   = undef,
    $dhcp_range_end     = undef,
    $dhcp_leasetime     = '10m',

    $github_owner       = undef,
    $github_repo        = undef,

    $gateway_ipaddr     = $ipaddress_eth0,

    $site_config                = true,
    $site_config_ssl            = false,
    $site_config_ssl_key        = $::apache::default_ssl_key,
    $site_config_ssl_cert       = $::apache::default_ssl_cert,
    $site_config_ssl_chain      = $::apache::default_ssl_chain,
    $site_config_ssl_ca         = $::apache::default_ssl_ca,
    $auto_update_pubkey         = undef,
    $auto_update_seckey_file    = undef,

    $enable_radvd	= true,
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

    # run all traffic from the mesh through the from_mesh mangle chain,
    # which finally marks it for policy based routing (i.e. to vpn provider)
    firewall { "150 possibly mark $community traffic":
        table           => 'mangle',
        chain           => 'PREROUTING',
        proto           => 'all',
        iniface         => "br_$community",
        jump            => 'from_mesh',
    }

    # don't mark traffic from other meshes to this one
    firewall { "100 accept mesh to $community traffic":
        table           => 'mangle',
        chain           => 'from_mesh',
        proto           => 'all',
        destination     => "$ip4_address/$ip4_netmask",
        jump            => RETURN,
    }

    # run all traffic from this mesh through "from_mesh" filter chain
    firewall { "110 handle outbound $community traffic":
        table           => 'filter',
        chain           => 'FORWARD',
        proto           => 'all',
        iniface         => "br_$community",
        source          => "$ip4_address/$ip4_netmask",
        jump            => 'from_mesh',
    }

    # pick traffic from "to_mesh" chain to this mesh
    firewall { "110 pick to_mesh traffic for $community":
        table           => 'filter',
        chain           => 'to_mesh',
        proto           => 'all',
        outiface        => "br_$community",
        destination     => "$ip4_address/$ip4_netmask",
        action          => accept,
    }

    # masquerade outgoing traffic from community's iprange
    firewall { "100 masquerade $community traffic":
        table           => 'nat',
        chain           => 'POSTROUTING',
        proto           => 'all',
        source          => "$ip4_address/$ip4_netmask",
        jump            => 'from_mesh',
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
    #
    if $enable_radvd {
	concat::fragment { "radvd-$community":
	    target      => "/etc/radvd.conf",
	    content     => template('gluon/radvd.conf'),
	}
    }


    if $site_config {
        include gluon::apache_common

        gluon::site_config { $name:
            city_name           => $city_name,
            ip4_address         => $ip4_address,
            ip4_netmask         => $ip4_netmask,
            ip6_address         => $ip6_address,
            ip6_prefix          => $ip6_prefix,
            ntp_server          => $ip6_address,
            fastd_port          => $fastd_port,
            auto_update_pubkey  => $auto_update_pubkey,
            mtu                 => $mtu,

            ssl                 => $site_config_ssl,
            ssl_key             => $site_config_ssl_key,
            ssl_cert            => $site_config_ssl_cert,
            ssl_chain           => $site_config_ssl_chain,
            ssl_ca              => $site_config_ssl_ca,
        }
    }


    if $github_owner and $github_repo {
        exec { "/etc/fastd/$community/peers/.git":
            command     => "/usr/bin/git init-db",
            cwd         => "/etc/fastd/$community/peers",
            creates     => "/etc/fastd/$community/peers/.git",
            require     => File["/etc/fastd/$community/peers"],
            user        => "freifunker",
        }

        exec { "/etc/fastd/$community/peers/.git/origin":
            command     => "git remote rm origin; git remote add origin 'git@github.com:$github_owner/$github_repo.git'",
            cwd         => "/etc/fastd/$community/peers",
            path        => "/usr/bin:/bin",
            unless      => "test \"`git remote show -n origin | sed -n '/Fetch URL/ { s/.*: //; p }'`\" = 'git@github.com:$github_owner/$github_repo.git'",
            require     => Exec["/etc/fastd/$community/peers/.git"],
            user        => "freifunker",
        }

        exec { "/etc/fastd/$community/peers/$hostname":
            command     => "/bin/sed -ne '/Public:/ { s/Public: /key \"/; s/$/\";\\nremote $gateway_ipaddr:$fastd_port;/; p }' /root/fastd-$community-key.txt > /etc/fastd/$community/peers/$hostname",
            creates     => "/etc/fastd/$community/peers/$hostname",
            require     => Exec["/root/fastd-$community-key.txt"],
        }

        cron { "sync_push_$community":
            command => "cd /etc/fastd/$community/peers/; \
                git pull --rebase origin master; \
                export GIT_AUTHOR_NAME=\"Gluon Gateway Robot\"; \
                export GIT_AUTHOR_EMAIL=\"freifunker@`hostname -f`\"; \
                export GIT_COMMITTER_NAME=\"Gluon Gateway Robot\"; \
                export GIT_COMMITTER_EMAIL=\"freifunker@`hostname -f`\"; \
                if test `git status --porcelain | wc -l` -gt 0; then \
                    git add .; \
                    git commit -m 'auto-commit'; \
                    git push origin master; \
                fi",
            user    => "freifunker",
            minute  => "*/15",
        }

    }

    if $dhcp_range_start and $dhcp_range_end {
        file { "/etc/dnsmasq.d/$community.conf":
            ensure      => present,
            content     => template('gluon/dnsmasq.conf'),
            notify      => Service['dnsmasq'],
            require     => Package['dnsmasq'],
        }
    }

    concat::fragment { "ffgw-on-$community":
	target      => "/usr/local/sbin/ffgw-on",
	content     => "batctl -m bat_$community gw server\n",
    }

    concat::fragment { "ffgw-off-$community":
	target      => "/usr/local/sbin/ffgw-off",
	content     => "batctl -m bat_$community gw off\n",
    }


    
    concat::fragment { "nagios-$community-dns":
	target      => "/etc/nagios3/conf.d/gluon_localhost.cfg",
	content     => "define service {
                            host                            localhost
                            service_description             $community DNS
                            check_command                   check_mesh_dns!$ip4_address
                            use                             generic-service
                    }\n",
    }

    concat::fragment { "nagios-$community-promisc-bat":
	target      => "/etc/nagios3/conf.d/gluon_localhost.cfg",
	content     => "define service {
                            host                            localhost
                            service_description             $community Promiscuous Batman
                            check_command                   check_ifpromisc!bat_$community
                            use                             generic-service
                    }\n",
    }

    concat::fragment { "nagios-$community-promisc-br":
	target      => "/etc/nagios3/conf.d/gluon_localhost.cfg",
	content     => "define service {
                            host                            localhost
                            service_description             $community Promiscuous Bridge
                            check_command                   check_ifpromisc!br_$community
                            use                             generic-service
                    }\n",
    }

    concat::fragment { "nagios-$community-promisc-mesh":
	target      => "/etc/nagios3/conf.d/gluon_localhost.cfg",
	content     => "define service {
                            host                            localhost
                            service_description             $community Promiscuous Mesh
                            check_command                   check_ifpromisc!mesh_$community
                            use                             generic-service
                    }\n",
    }

    concat::fragment { "nagios-$community-fastd":
	target      => "/etc/nagios3/conf.d/gluon_localhost.cfg",
	content     => "define service {
                            host                            localhost
                            service_description             $community FastD
                            check_command                   check_fastd!$community
                            use                             generic-service
                    }\n",
    }
}
