define gluon::site_config (
    $ensure         = 'present',
    $community      = $name,

    $city_name      = undef,

    $ip4_address    = undef,
    $ip4_netmask    = undef,
    $ip6_prefix     = undef,

    $ntp_server     = undef,
    $fastd_port     = undef,

    $site_name      = "Freifunk $city_name",
    $ssid           = "$city_name.freifunk.net",
    $mesh_ssid      = "mesh.$city_name.freifunk.net",
    $gateway_ipaddr = $ipaddress_eth0,

    $auto_update_server = undef,
    $auto_update_pubkey = undef,

    $reg_email_addr     = "key@freifunk-$city_name.de",
    $reg_form_url       = "https://site.freifunk-$city_name.de/router-anmelden/",
    $community_url      = "https://freifunk-$city_name.de/",
) {
    #if $city_name and !$site_name {
    #    $site_name = "Freifunk $city_name"
    #}

    file { "/srv/gluon-$community/":
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
}
