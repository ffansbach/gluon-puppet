define gluon::netmon (
    $ensure         = 'present',
    $community      = $name,
) {
    exec { 'clone-netmon':
        creates => '/srv/netmon',
        command => '/usr/bin/git clone http://git.freifunk-ol.de/root/netmon.git',
        cwd     => '/srv',
    }

    apache::vhost { 'netmon.freifunk-ansbach.de':
        docroot     => '/srv/netmon',
        servername  => 'netmon.freifunk-ansbach.de',
    }

    file { '/srv/netmon':
        mode    => 644,
        owner   => 'www-data',
        require => Exec['clone-netmon'],
    }

    file { '/srv/netmon/config':
        mode    => 644,
        owner   => 'www-data',
        require => Exec['clone-netmon'],
    }

    #class { '::mysql::server':
    #    old_root_password => 'matebier',
    #    root_password => 'matebier',
    #    restart => true,
    #}
    #
    #mysql_user { 'netmon@localhost':
    #    ensure => present,
    #    password_hash => '*9B500343BC52E2911172EB52AE5CF4847604C6E5', # foobar
    #    #require => Class['::mysql::server'],
    #}
    #
    #mysql_grant { 'netmon@localhost/netmon.*':
    #    ensure => present,
    #    privileges => [ 'ALL' ],
    #    table => 'netmon.*',
    #    user => 'netmon@localhost',
    #    require => Mysql_user['netmon@localhost'],
    #}

