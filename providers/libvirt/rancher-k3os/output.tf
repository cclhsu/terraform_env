output "username" {
  value = var.username
}

output "ip_load_balancer" {
  value = var.create_lb ? zipmap(
    libvirt_domain.lb.*.network_interface.0.hostname,
    libvirt_domain.lb.*.network_interface.0.addresses.0
  ) : {}
}

output "ip_etcds" {
  value = zipmap(
    libvirt_domain.etcd.*.network_interface.0.hostname,
    libvirt_domain.etcd.*.network_interface.0.addresses.0,
  )
}

output "ip_storages" {
  value = zipmap(
    libvirt_domain.storage.*.network_interface.0.hostname,
    libvirt_domain.storage.*.network_interface.0.addresses.0,
  )
}

output "ip_masters" {
  value = zipmap(
    libvirt_domain.master.*.network_interface.0.hostname,
    libvirt_domain.master.*.network_interface.0.addresses.0,
  )
}

output "ip_workers" {
  value = zipmap(
    libvirt_domain.worker.*.network_interface.0.hostname,
    libvirt_domain.worker.*.network_interface.0.addresses.0,
  )
}

# output "cluster_endpoint" {
#   value = format("https://%s:6443", libvirt_domain.master.*.network_interface.0.addresses.0)
# }

# output "kubeconfig" {
#   value = data.local_file.kubeconfig.content
# }

# output "kubeconfig_filename" {
#   value = data.local_file.kubeconfig.filename
# }
