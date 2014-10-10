define gluon::netmon (
    $ensure                 = "present",
    $community              = $name,

    $netmon_domain          = undef,
    $city_name              = undef,
    $community_essid        = undef,
    $mail_sender_address    = undef,

    $map_lng                = 10.570568561602705,
    $map_lat                = 49.30287809839658,
    $map_zoom               = 13,

    $admin_nickname         = undef,
    $admin_password         = undef,
    $admin_apikey           = undef,
    $admin_email            = undef,

    $ssl                    = false,
    $ssl_cert               = $::apache::default_ssl_cert,
    $ssl_key                = $::apache::default_ssl_key,
    $ssl_chain              = $::apache::default_ssl_chain,
    $ssl_ca                 = $::apache::default_ssl_ca,

) {
    exec { "clone-netmon-$community":
        creates => "/srv/netmon-$community",
        command => "/usr/bin/git clone http://git.freifunk-ol.de/root/netmon.git netmon-$community",
        cwd     => "/srv",

        # kind of a hack, this provides feedback to the network interface post-up
        # code, which provides a netmon ip address, if netmon is used.
        before  => Network::Interface["br_$community"],
    }

    apache::vhost { $netmon_domain:
        ip              => '*',
        port            => 80,
        add_listen      => false,
        docroot         => "/srv/netmon-$community",
        servername      => $netmon_domain,
        serveraliases   => [ "netmon.$community_essid" ],
    }

    if $ssl {
        apache::vhost { "$netmon_domain-ssl":
            ip              => '*',
            port            => 443,
            ssl		    => true,
            docroot         => "/srv/netmon-$community",
            servername      => $netmon_domain,
            serveraliases   => [ "netmon.$community_essid" ],

            ssl_cert        => $ssl_cert,
            ssl_key         => $ssl_key,
            ssl_chain       => $ssl_chain,
            ssl_ca          => $ssl_ca,
        }
    }

    file { "/srv/netmon-$community":
        mode    => 644,
        owner   => "www-data",
        require => Exec["clone-netmon-$community"],
    }

    file { "/srv/netmon-$community/config":
        mode    => 644,
        owner   => "www-data",
    }

    file { "/srv/netmon-$community/config/config.local.inc.php":
        ensure  => present,
        content => template('gluon/netmon-config.inc.php'),
        owner   => "www-data",
    }

    mysql::db { "netmon_$community":
        user        => "netmon_$community",
        password    => "foobar",
        sql         => "/srv/netmon-$community/netmon.sql",
    }

    file { "/srv/netmon-$community/config/preseed.sql":
        ensure      => present,
        content     => template("gluon/netmon-config.sql"),
    }

    exec { "netmon_$community-config":
        command     => "/usr/bin/mysql netmon_$community < /srv/netmon-$community/config/preseed.sql",
        logoutput   => true,
        environment => "HOME=${::root_home}",
        refreshonly => true,
        require     => File["/srv/netmon-$community/config/preseed.sql"],
        subscribe   => Exec["netmon_$community-import"],
    }

    cron { "crawl_$community":
        command => "/usr/bin/php /srv/netmon-$community/cronjobs.php",
        user    => root,
        minute  => '*/10'
    }

    file { "/srv/netmon-$community/templates/base/html/header.tpl.html":
        source      => "puppet:///modules/gluon/header.tpl.html",
        require     => Exec["clone-netmon-$community"],
    }

    exec { "/srv/netmon-$community/lib/core/menus.class.php":
        command     => "sed -ie '/FF-Map 3D/d' /srv/netmon-$community/lib/core/menus.class.php",
        onlyif      => "grep -qe 'FF-Map 3D' /srv/netmon-$community/lib/core/menus.class.php",
        path        => "/bin:/usr/bin",
        require     => Exec["clone-netmon-$community"],
    }
}
