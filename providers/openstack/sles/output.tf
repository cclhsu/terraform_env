output "username" {
  value = var.username
}

output "hostname_load_balancer" {
  value = openstack_lb_loadbalancer_v2.lb.name
}

output "hostnames_etcds" {
  value = openstack_compute_instance_v2.etcd.*.name
}

output "hostnames_storages" {
  value = openstack_compute_instance_v2.storage.*.name
}

output "hostnames_masters" {
  value = openstack_compute_instance_v2.master.*.name
}

output "hostnames_workers" {
  value = openstack_compute_instance_v2.worker.*.name
}

output "ip_load_balancer" {
  value = openstack_networking_floatingip_v2.lb_ext.address
}

output "ip_internal_load_balancer" {
  value = openstack_lb_loadbalancer_v2.lb.vip_address
}

output "ip_etcds" {
  value = openstack_networking_floatingip_v2.etcd_ext.*.address
}

output "ip_storages" {
  value = openstack_networking_floatingip_v2.storage_ext.*.address
}

output "ip_masters" {
  value = openstack_networking_floatingip_v2.master_ext.*.address
}

output "ip_workers" {
  value = openstack_networking_floatingip_v2.worker_ext.*.address
}

# output "ip_load_balancer" {
#   value = "${zipmap(list(openstack_lb_loadbalancer_v2.lb.name), list(openstack_networking_floatingip_v2.lb_ext.address))}"
# }

# output "ip_internal_load_balancer" {
#   value = openstack_lb_loadbalancer_v2.lb.vip_address
# }

# output "ip_etcds" {
#   value = "${zipmap(openstack_compute_instance_v2.etcd.*.name, openstack_networking_floatingip_v2.etcd_ext.*.address)}"
# }

# output "ip_storages" {
#   value = "${zipmap(openstack_compute_instance_v2.storage.*.name, openstack_networking_floatingip_v2.storage_ext.*.address)}"
# }

# output "ip_masters" {
#   value = "${zipmap(openstack_compute_instance_v2.master.*.name, openstack_networking_floatingip_v2.master_ext.*.address)}"
# }

# output "ip_workers" {
#   value = "${zipmap(openstack_compute_instance_v2.worker.*.name, openstack_networking_floatingip_v2.worker_ext.*.address)}"
# }
