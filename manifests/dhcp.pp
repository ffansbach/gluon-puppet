define gluon::dhcp (
    $ensure         = 'present',
    $community      = $name,

    $range_start    = undef,
    $range_end      = undef,
    $leasetime      = '10m',
) {
    file { "/etc/dnsmasq.d/$community.conf":
        ensure      => present,
        content     => template('gluon/dnsmasq.conf'),
        notify      => Service['dnsmasq'],
        require     => Package['dnsmasq'],
    }
}
