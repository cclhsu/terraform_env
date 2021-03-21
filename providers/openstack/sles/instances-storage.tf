data "template_file" "storage_repositories" {
  count    = length(var.repositories)
  template = file("${path.module}/cloud-init/repository.tpl")

  vars = {
    repository_url = element(
      values(var.repositories),
      count.index
    )
    repository_name = element(
      keys(var.repositories),
      count.index
    )
  }
}

data "template_file" "storage_register_scc" {
  count    = var.caasp_registry_code == "" ? 0 : 1
  template = file("${path.module}/cloud-init/register-scc.tpl")

  vars = {
    caasp_registry_code = var.caasp_registry_code
    rmt_server_name     = var.rmt_server_name
  }
}

data "template_file" "storage_register_rmt" {
  count    = var.rmt_server_name == "" ? 0 : 1
  template = file("${path.module}/cloud-init/register-rmt.tpl")

  vars = {
    rmt_server_name = var.rmt_server_name
  }
}

data "template_file" "storage_commands" {
  count    = join("", var.packages) == "" ? 0 : 1
  template = file("${path.module}/cloud-init/commands.tpl")

  vars = {
    packages = join(" ", var.packages)
  }
}

data "template_file" "storage_cloud-init" {
  template = file("${path.module}/cloud-init/cloud-init.yaml.tpl")

  vars = {
    authorized_keys = join("\n", formatlist("  - %s", var.authorized_keys))
    repositories    = length(var.repositories) == 0 ? "\n" : join("\n", data.template_file.storage_repositories.*.rendered)
    register_scc    = var.caasp_registry_code != "" && var.rmt_server_name == "" ? join("\n", data.template_file.storage_register_scc.*.rendered) : ""
    register_rmt    = var.rmt_server_name == "" ? join("\n", data.template_file.storage_register_rmt.*.rendered) : ""
    username        = var.username
    password        = var.password
    ntp_servers     = join("\n", formatlist("    - %s", var.ntp_servers))
    dns_nameservers = join("\n", formatlist("    - %s", var.dns_nameservers))
    # packages        = join("\n", formatlist("  - %s", var.packages))
    commands = join("\n", data.template_file.storage_commands.*.rendered)
  }
}

resource "openstack_blockstorage_volume_v2" "storage_vol" {
  count = var.storages_vol_enabled ? var.storages : 0
  size  = var.storages_vol_size
  name  = "vol_${element(openstack_compute_instance_v2.storage.*.name, count.index)}"
}

resource "openstack_compute_volume_attach_v2" "storage_vol_attach" {
  count       = var.storages_vol_enabled ? var.storages : 0
  instance_id = element(openstack_compute_instance_v2.storage.*.id, count.index)
  volume_id = element(
    openstack_blockstorage_volume_v2.storage_vol.*.id,
    count.index
  )
}

resource "openstack_compute_instance_v2" "storage" {
  count      = var.storages
  name       = "caasp-storage-${var.stack_name}-${count.index}"
  image_name = var.image_name
  key_pair   = var.key_pair

  depends_on = [
    openstack_networking_network_v2.network,
    openstack_networking_subnet_v2.subnet,
  ]

  flavor_name = var.storage_size

  network {
    name = var.internal_net
  }

  security_groups = [
    openstack_networking_secgroup_v2.common.name,
    openstack_networking_secgroup_v2.storage_nodes.name,
  ]

  user_data = data.template_file.storage_cloud-init[count.index].rendered
}

resource "openstack_networking_floatingip_v2" "storage_ext" {
  count = var.storages
  pool  = var.external_net
}

resource "openstack_compute_floatingip_associate_v2" "storage_ext_ip" {
  depends_on = [openstack_compute_instance_v2.storage, ]
  count      = var.storages
  floating_ip = element(
    openstack_networking_floatingip_v2.storage_ext.*.address,
    count.index
  )
  instance_id = element(openstack_compute_instance_v2.storage.*.id, count.index)
}

resource "null_resource" "storage_wait_cloudinit" {
  depends_on = [
    openstack_compute_instance_v2.storage,
    openstack_compute_floatingip_associate_v2.storage_ext_ip,
  ]
  count = var.storages

  connection {
    host = element(
      openstack_compute_floatingip_associate_v2.storage_ext_ip.*.floating_ip,
      count.index
    )
    user = var.username
    type = "ssh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait > /dev/null",
    ]
  }
}

resource "null_resource" "storage_reboot" {
  depends_on = [null_resource.storage_wait_cloudinit, ]
  count      = var.storages

  provisioner "local-exec" {
    environment = {
      user = var.username
      host = element(
        openstack_compute_floatingip_associate_v2.storage_ext_ip.*.floating_ip,
        count.index
      )
    }

    command = <<EOT
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $user@$host sudo reboot || :
# wait for ssh ready after reboot
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -oConnectionAttempts=60 $user@$host /usr/bin/true
EOT

  }
}
