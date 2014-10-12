define gluon::site_config (
    $ensure                 = 'present',
    $community              = $name,

    $city_name              = undef,
    $site_domain            = "site.freifunk-$city_name.de",
    $community_domain       = "freifunk-$city_name.de",

    $ip4_address            = undef,
    $ip4_netmask            = undef,
    $ip6_address            = undef,
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
    ]

    apache::vhost { $ip6_address:
        ip              => $ip6_address,
        servername      => $ip6_address,
        port            => 80,
        add_listen      => false,
        docroot         => "/srv/site-$community",

        aliases         => [
            { alias => "/site/", path => "/srv/gluon-$community/site/" },
            { alias => "/images/", path => "/srv/gluon-$community/images/" },
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
            { alias => "/site/", path => "/srv/gluon-$community/site/" },
            { alias => "/images/", path => "/srv/gluon-$community/images/" },
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
                { alias => "/site/", path => "/srv/gluon-$community/site/" },
                { alias => "/images/", path => "/srv/gluon-$community/images/" },
            ],
            directories     => $directories,
        }
    }
}
