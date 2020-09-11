resource "openstack_networking_secgroup_v2" "worker_nodes" {
  name        = "${var.stack_name}-worker_nodes_secgroup"
  description = "Common security group for CaaSP worker nodes"
}

resource "openstack_networking_secgroup_rule_v2" "worker_etcd_client_communication" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 2379
  port_range_max    = 2379
  remote_ip_prefix  = var.subnet_cidr
  security_group_id = openstack_networking_secgroup_v2.worker_nodes.id
}

resource "openstack_networking_secgroup_rule_v2" "worker_etcd_server_to_server" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 2380
  port_range_max    = 2380
  remote_ip_prefix  = var.subnet_cidr
  security_group_id = openstack_networking_secgroup_v2.worker_nodes.id
}

resource "openstack_networking_secgroup_rule_v2" "worker_api_server" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.worker_nodes.id
}
