define gluon::netmon_setting (
    $ensure = 'present',
    $community,
    $key,
    $value = undef
) {
    if($ensure == 'present') {
	exec { "_gluon_netmon_setting_${name}_update":
	    command     => "echo \"UPDATE config SET value = \\\"${value}\\\", update_date = NOW() WHERE name = \\\"${key}\\\";\" | mysql -B netmon_$community",
	    logoutput   => true,
	    unless      => "test \"`echo \\\"SELECT value FROM config WHERE name = '${key}';\\\" | mysql -BN netmon_${community}`\" = \"${value}\"",
	    environment => "HOME=${::root_home}",
	    path        => "/usr/bin:/bin",
	    require     => [ Exec["netmon_$community-config"], Exec["_gluon_netmon_setting_${name}_insert"] ],
	}

	exec { "_gluon_netmon_setting_${name}_insert":
	    command     => "echo \"INSERT INTO config SET name = \\\"${key}\\\", value = \\\"${value}\\\", create_date = NOW(), update_date = NOW();\" | mysql -B netmon_$community",
	    logoutput   => true,
	    onlyif      => "test \"`echo \\\"SELECT COUNT(*) FROM config WHERE name = '${key}';\\\" | mysql -BN netmon_${community}`\" = \"0\"",
	    environment => "HOME=${::root_home}",
	    path        => "/usr/bin:/bin",
	    require     => Exec["netmon_$community-config"],
	}
    }
    else {
	exec { "_gluon_netmon_setting_${name}_insert":
	    command     => "echo \"DELETE FROM config WHERE name = \\\"${key}\\\";\" | mysql -B netmon_$community",
	    logoutput   => true,
	    unless      => "test \"`echo \\\"SELECT COUNT(*) FROM config WHERE name = '${key}';\\\" | mysql -BN netmon_${community}`\" = \"0\"",
	    environment => "HOME=${::root_home}",
	    path        => "/usr/bin:/bin",
	    require     => Exec["netmon_$community-config"],
	}
    }
}
