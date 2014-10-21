# Definition: gluon::netmon_common
#
# This class prepares the node for (multiple) Netmon installations.
#
# You usually don't need to declare/include this class directly,
# just declare gluon::netmon instances and it will include this class as needed.
#
class gluon::netmon_common {
    include gluon::apache_common

    # netmon needs rrdtool
    package { 'rrdtool':
        ensure  => present,
    }


    # netmon needs a mail transfer agent
    package { 'exim4':
        ensure  => present,
    }
}
