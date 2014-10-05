define gluon::netmon (
    $ensure                 = "present",
    $community              = $name,

    $netmon_domain          = undef,
    $city_name              = undef,
    $community_essid        = undef,
    $mail_sender_address    = undef,
) {
    exec { "clone-netmon-$community":
        creates => "/srv/netmon-$community",
        command => "/usr/bin/git clone http://git.freifunk-ol.de/root/netmon.git netmon-$community",
        cwd     => "/srv",
    }

    apache::vhost { $netmon_domain:
        docroot     => "/srv/netmon-$community",
        servername  => $netmon_domain,
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

    exec{ "netmon_$community-config":
        command     => "/usr/bin/mysql netmon_$community < /srv/netmon-$community/config/preseed.sql",
        logoutput   => true,
        environment => "HOME=${::root_home}",
        refreshonly => true,
        require     => File["/srv/netmon-$community/config/preseed.sql"],
        subscribe   => Exec["netmon_$community-import"],
      }

}
