define gluon::mesh_direct_tcp_port (
    $ensure = 'present',
) {
    gluon::mesh_direct_port { "mesh_direct_port/tcp/$name":
	port => $name,
	proto => 'tcp',
    }
}
