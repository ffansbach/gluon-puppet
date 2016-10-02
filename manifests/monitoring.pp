class gluon::monitoring {
    package { [ 'nagios3', 'nagios-plugins-standard', 'nagios-plugins-basic' ]:
        ensure  => present,
    }

    file { '/etc/apache2/conf.d':
        ensure  => directory,
    }

    file { '/etc/apache2/conf.d/nagios3.conf':
        ensure  => symlink,
        target  => '/etc/nagios3/apache2.conf',
    }

    service { 'nagios3':
        ensure      => running,
        require     => Package['nagios3'],
    }

    concat { '/etc/nagios3/conf.d/gluon_localhost.cfg':
        ensure      => present,
        notify      => Service['nagios3'],
    }

    concat::fragment { "nagios-check-mesh-dns":
	target      => "/etc/nagios3/conf.d/gluon_localhost.cfg",
	content     => "define command{
                            command_name    check_mesh_dns
                            command_line    /usr/lib/nagios/plugins/check_dns -H $fqdn -s '\$ARG1$'
                    }\n",
    }

    concat::fragment { "nagios-apt-updates":
	target      => "/etc/nagios3/conf.d/gluon_localhost.cfg",
	content     => "define service {
                            host                            localhost
                            service_description             APT
                            check_command                   check_apt
                            use                             generic-service
                    }\n",
    }

    file { '/usr/lib/nagios/plugins/check_ifpromisc':
        ensure      => present,
        mode        => 0755,
        content     => '#!/bin/sh
if [ "$1" = "" ]; then
  echo "Usage: $0 <IFNAME>"
  exit 3
fi
line="`sudo /usr/local/sbin/ifpromisc $1`"
if [ "$line" = "" ]; then
  echo "interface $1 not found"
  exit 3
fi
if [ "$line" = "$1: not promisc and no PF_PACKET sockets" ]; then
  echo "OK $line"
  exit 0
fi
echo "$line"
exit 2
'
    }

    concat::fragment { "nagios-check-ifpromisc":
	target      => "/etc/nagios3/conf.d/gluon_localhost.cfg",
	content     => "define command{
                            command_name    check_ifpromisc
                            command_line    /usr/lib/nagios/plugins/check_ifpromisc '\$ARG1$'
                    }\n",
    }

    file_line { 'sudo-check_ifpromisc':
        ensure  => present,
        path    => '/etc/sudoers',
        line    => 'nagios ALL = (ALL) NOPASSWD: /usr/local/sbin/ifpromisc *',
    }

    file { '/usr/lib/nagios/plugins/check_ifping':
        ensure      => present,
        mode        => 0755,
        content     => '#!/bin/bash
interface="$1"; shift
ipaddr="${1-8.8.8.8}"; shift

outfile="`mktemp`"
ping -I"${interface}" "${ipaddr}" -c 3 -w 1 -i 0.2 > "${outfile}"
result=$?

grep -e "transmitted" "${outfile}"
rm -f "${outfile}"

exit $result
'
    }

    concat::fragment { "check_ifping":
	target      => "/etc/nagios3/conf.d/gluon_localhost.cfg",
	content     => "define command {
			    command_name    check_ifping
			    command_line    /usr/lib/nagios/plugins/check_ifping '\$ARG1$'
		    }\n",
    }


    concat::fragment { "nagios-check-fastd":
	target      => "/etc/nagios3/conf.d/gluon_localhost.cfg",
	content     => "define command{
                            command_name    check_fastd
                            command_line    /usr/lib/nagios/plugins/check_procs  -C fastd -a '/\$ARG1$/'  -c 1:1
                    }\n",
    }
}
