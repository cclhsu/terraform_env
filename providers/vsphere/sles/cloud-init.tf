data "local_file" "network_cloud-init" {
  filename = "${path.module}/cloud-init/network-config.tpl"
}
