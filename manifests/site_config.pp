define gluon::site_config (
    $ensure                 = 'present',
    $community              = $name,

    $city_name              = undef,
    $site_domain            = "site.freifunk-$city_name.de",
    $community_domain       = "freifunk-$city_name.de",

    $ip4_address            = undef,
    $ip4_netmask            = undef,
    $ip6_prefix             = undef,

    $ntp_server             = undef,
    $fastd_port             = undef,

    $site_name              = "Freifunk $city_name",
    $ssid                   = "$city_name.freifunk.net",
    $mesh_ssid              = "mesh.$city_name.freifunk.net",
    $gateway_ipaddr         = $ipaddress_eth0,

    $ssl                    = false,
    $ssl_cert               = $::apache::default_ssl_cert,
    $ssl_key                = $::apache::default_ssl_key,
    $ssl_chain              = $::apache::default_ssl_chain,
    $ssl_ca                 = $::apache::default_ssl_ca,

    $auto_update_pubkey     = undef,
    $reg_email_addr         = "key@freifunk-$city_name.de",

    $community_url          = "https://freifunk-$city_name.de/",
) {
    file { "/srv/gluon-$community/autogen.sh":
        ensure      => present,
        content     => template('gluon/autogen.sh'),
        mode        => 755,
    }

    file { "/srv/gluon-$community/site/":
        ensure      => directory
    }

    file { "/srv/gluon-$community/gen-site.conf.sh":
        ensure      => present,
        content     => template('gluon/site.conf'),
        mode        => 755,
        notify      => Exec["/srv/gluon-$community/site/site.conf"],
        require     => Exec["/root/fastd-$community-key.txt"],
    }

    exec { "/srv/gluon-$community/site/site.conf":
        command     => "/srv/gluon-$community/gen-site.conf.sh > /srv/gluon-$community/site/site.conf",
        path        => "/bin:/usr/bin",
        refreshonly => true,
    }

    file { "/srv/gluon-$community/site/site.mk":
        ensure      => present,
        source      => "puppet:///modules/gluon/site.mk",
    }

    file { "/srv/gluon-$community/site/modules":
        ensure      => present,
        source      => "puppet:///modules/gluon/modules",
    }

    apache::vhost { $site_domain:
        ip              => '*',
        port            => 80,
        add_listen      => false,
        docroot         => "/srv/gluon-$community",
        servername      => $site_domain,

        docroot_group   => "freifunker",
        docroot_mode    => 775,
    }

    if $ssl {
        apache::vhost { "$site_domain-ssl":
            ip              => '*',
            port            => 443,
            ssl             => true,
            docroot         => "/srv/gluon-$community",
            servername      => $site_domain,

            docroot_group   => "freifunker",
            docroot_mode    => 775,

            ssl_cert        => $ssl_cert,
            ssl_key         => $ssl_key,
            ssl_chain       => $ssl_chain,
            ssl_ca          => $ssl_ca,
        }
    }
}
