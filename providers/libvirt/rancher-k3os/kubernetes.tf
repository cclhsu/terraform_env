resource "random_password" "k3s_token" {
  length = 16
}

# resource "null_resource" "wait_for_cluster" {
#   provisioner "local-exec" {
#     command     = var.wait_for_cluster_cmd
#     interpreter = var.wait_for_cluster_interpreter
#     environment = {
#       ENDPOINT = format("https://%s:6443", libvirt_domain.master.0.network_interface.0.addresses.0)
#     }
#   }
# }

# resource "null_resource" "wait_for_kubeconfig" {
#   depends_on = [
#     null_resource.wait_for_cluster,
#   ]

#   provisioner "local-exec" {
#     command = "ssh -o StrictHostKeyChecking=no ${var.username}@${libvirt_domain.master.0.network_interface.0.addresses.0} 'for i in `seq 1 60`; do test -f /etc/rancher/k3s/k3s.yaml && exit 0 || true; sleep 5; done; echo TIMEOUT && exit 1'"
#   }
# }

# resource "null_resource" "wait_for_master_node_ready" {
#   depends_on = [
#     null_resource.wait_for_kubeconfig,
#   ]

#   provisioner "local-exec" {
#     command = "ssh -o StrictHostKeyChecking=no ${var.username}@${libvirt_domain.master.0.network_interface.0.addresses.0} 'for i in `seq 1 60`; do kubectl get nodes | grep master | sed -e 's/  */ /g' | cut -d ' ' -f 2 | grep Ready | wc -l && exit 0 || true; sleep 5; done; echo TIMEOUT && exit 1'"
#   }
# }

# resource "null_resource" "get_kubeconfig" {
#   depends_on = [
#     null_resource.wait_for_kubeconfig,
#   ]

#   provisioner "local-exec" {
#     # command = "ssh -o StrictHostKeyChecking=no ${var.username}@${libvirt_domain.master.0.network_interface.0.addresses.0} cat /etc/rancher/k3s/k3s.yaml > ${path.cwd}/kubeconfig.yaml"
#     command = "rm -f ~/.kube/config; ssh -o StrictHostKeyChecking=no ${var.username}@${libvirt_domain.master.0.network_interface.0.addresses.0} cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config"
#   }
# }

# resource "null_resource" "fix_kubeconfig" {
#   depends_on = [
#     null_resource.get_kubeconfig,
#   ]

#   provisioner "local-exec" {
#     # command = "sed -i -e 's/127.0.0.1/${libvirt_domain.master.0.network_interface.0.addresses.0}/' ${path.cwd}/kubeconfig.yaml"
#     command = "sed -i -e 's/127.0.0.1/${libvirt_domain.master.0.network_interface.0.addresses.0}/' ~/.kube/config"
#   }
# }

# data "local_file" "kubeconfig" {
#   # filename = "${path.cwd}/kubeconfig.yaml"
#   filename = pathexpand("~/.kube/config")

#   depends_on = [
#     null_resource.fix_kubeconfig,
#   ]
# }
