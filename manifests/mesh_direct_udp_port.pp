define gluon::mesh_direct_udp_port (
    $ensure = 'present',
) {
    gluon::mesh_direct_port { "mesh_direct_port/udp/$name":
	port => $name,
	proto => 'udp',
    }
}
