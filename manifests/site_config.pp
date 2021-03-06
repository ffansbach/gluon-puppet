define gluon::site_config (
    $ensure                 = 'present',
    $community              = $name,
    $gluon_version          = '2019.1.3',

    $city_name              = undef,
    $site_domain            = "site.freifunk-$city_name.de",
    $community_domain       = "freifunk-$city_name.de",

    $ip4_address            = undef,
    $ip4_netmask            = undef,
    $ip6_address            = undef,
    $ip6_prefix             = undef,
    $ip6_gateway            = undef,

    $ntp_server             = undef,
    $fastd_port             = undef,
    $mtu                    = 1426,
    $cipher                 = 'salsa2012+gmac',
    $peers_dir              = undef,

    $site_name              = "Freifunk $city_name",
    $ssid                   = "$city_name.freifunk.net",
    $mesh_ssid              = "mesh.$city_name.freifunk.net",
    $mesh_bssid             = "02:44:CA:FF:23:42",
    $mesh_bssid24           = "12:CA:FF:EE:23:42",
    $gateway_ipaddr         = $ipaddress_eth0,
    $domain_seed            = undef,

    $ssl                    = false,
    $ssl_cert               = $::apache::default_ssl_cert,
    $ssl_key                = $::apache::default_ssl_key,
    $ssl_chain              = $::apache::default_ssl_chain,
    $ssl_ca                 = $::apache::default_ssl_ca,

    $auto_update_pubkey     = undef,
    $reg_email_addr         = "key@freifunk-$city_name.de",

    $community_url          = "https://freifunk-$city_name.de/",
) {
    file { "/srv/firmware-$community":
        ensure      => directory,
        group       => "freifunker",
        mode        => 775,
    }

    file { "/srv/gluon-$community":
        ensure      => directory,
        group       => "freifunker",
        mode        => 775,
    }

    file { "/srv/gluon-$community/autogen.sh":
        ensure      => present,
        content     => template('gluon/autogen.sh'),
        mode        => 755,
    }

    file { "/srv/gluon-$community/propagate.sh":
        ensure      => present,
        content     => template('gluon/propagate.sh'),
        mode        => 755,
    }

    file { "/srv/gluon-$community/site/":
        ensure      => directory
    }

    file { "/srv/gluon-$community/site/i18n/":
        ensure      => directory
    }

    file { "/srv/gluon-$community/site/domains/":
        ensure      => directory
    }

    file { "/srv/gluon-$community/gen-domains.conf.sh":
        ensure      => present,
        content     => template('gluon/domains.conf'),
        mode        => 755,
        notify      => Exec["/srv/gluon-$community/site/domains/batman_legacy.conf"],
        require     => Exec["/root/fastd-$community-key.txt"],
    }

    file { "/srv/gluon-$community/site/site.conf":
        ensure      => present,
        content     => template('gluon/site.conf'),
    }

    file { "/srv/gluon-$community/site/i18n/de.po":
        ensure      => present,
        content     => template('gluon/i18n/de.po'),
    }

    file { "/srv/gluon-$community/site/i18n/en.po":
        ensure      => present,
        content     => template('gluon/i18n/en.po'),
    }

    exec { "/srv/gluon-$community/site/domains/batman_legacy.conf":
        command     => "/srv/gluon-$community/gen-domains.conf.sh",
        path        => "/bin:/usr/bin",
        refreshonly => true,
    }

    file { "/srv/gluon-$community/site/site.mk":
        ensure      => present,
        content     => template('gluon/site.mk'),
    }

    file { "/srv/gluon-$community/site/modules":
        ensure      => present,
        source      => "puppet:///modules/gluon/modules",
    }

    file { "/srv/site-$community":
        source      => "puppet:///modules/gluon/site-wwwroot",
        recurse     => true,
    }

    file { "/srv/site-$community/index.html":
        ensure      => present,
        content     => template('gluon/index.html'),
    }

    file { "/srv/site-$community/router-anmelden/index.php":
        content     => template('gluon/site-wwwroot/index.php'),
    }

    file { "/srv/site-$community/router-anmelden/kill-helper":
        content     => template('gluon/site-wwwroot/kill-helper'),
        mode        => 755,
    }

    file { "/srv/site-$community/api/node.php":
        content     => template('gluon/site-wwwroot/node.php'),
    }

    file_line { "sudo-fastd-$community":
        path        => '/etc/sudoers',
        line        => "%freifunker ALL=(root) NOPASSWD: /srv/site-$community/router-anmelden/kill-helper",
    }

    $directories = [
        {
            provider       => 'directory',
            path           => "/srv/site-$community",
            options        => ['Indexes','FollowSymLinks','MultiViews'],
            allow_override => 'None',
            directoryindex => '',
        },
        {
            provider       => 'directory',
            path           => "/srv/gluon-$community/site",
            options        => ['Indexes','FollowSymLinks','MultiViews'],
            allow_override => 'None',
            directoryindex => '',
        },
        {
            provider       => 'directory',
            path           => "/srv/gluon-$community/images",
            options        => ['Indexes','FollowSymLinks','MultiViews'],
            allow_override => 'None',
            directoryindex => '',
        },
        {
            provider       => 'directory',
            path           => "/srv/images-$community",
            options        => ['Indexes','FollowSymLinks','MultiViews'],
            allow_override => 'None',
            directoryindex => '',
        },
        {
            provider       => 'directory',
            path           => "/srv/firmware-$community",
            options        => ['Indexes','FollowSymLinks','MultiViews'],
            allow_override => 'None',
            directoryindex => '',
        },
    ]

    apache::vhost { $ip6_address:
        ip              => $ip6_address,
        servername      => $ip6_address,
        port            => 80,
        add_listen      => false,
        docroot         => "/srv/site-$community",

        aliases         => [
            { alias => "/site", path => "/srv/gluon-$community/site/" },
            { alias => "/images", path => "/srv/images-$community/" },
            { alias => "/firmware", path => "/srv/firmware-$community/" },
        ],
        directories     => $directories,
    }

    apache::vhost { $site_domain:
        ip              => '*',
        servername      => $site_domain,
        port            => 80,
        add_listen      => false,
        docroot         => "/srv/site-$community",

        aliases         => [
            { alias => "/site", path => "/srv/gluon-$community/site/" },
            { alias => "/images", path => "/srv/images-$community/" },
            { alias => "/firmware", path => "/srv/firmware-$community/" },
        ],
        directories     => $directories,
    }

    if $ssl {
        apache::vhost { "$site_domain-ssl":
            ip              => '*',
            servername      => $site_domain,
            port            => 443,
            ssl             => true,
            docroot         => "/srv/site-$community",

            ssl_cert        => $ssl_cert,
            ssl_key         => $ssl_key,
            ssl_chain       => $ssl_chain,
            ssl_ca          => $ssl_ca,

            aliases         => [
                { alias => "/site", path => "/srv/gluon-$community/site/" },
                { alias => "/images", path => "/srv/images-$community/" },
                { alias => "/firmware", path => "/srv/firmware-$community/" },
            ],
            directories     => $directories,
        }
    }
}
