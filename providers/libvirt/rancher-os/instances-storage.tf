data "template_file" "storage_commands" {
  count    = join("", var.packages) == "" ? 0 : 1
  template = file("${path.module}/cloud-init/commands.tpl")
}

data "template_file" "storage_cloud-init" {
  count    = var.storages
  template = file("${path.module}/cloud-init/cloud-init.yaml.tpl")

  vars = {
    authorized_keys    = join("\n", formatlist("  - %s", var.authorized_keys))
    username           = var.username
    password           = var.password
    hostname           = "${var.stack_name}-storage-${count.index}"
    hostname_from_dhcp = var.hostname_from_dhcp == true && var.cpi_enable == false ? "yes" : "no"
    ntp_servers        = join("\n", formatlist("    - %s", var.ntp_servers))
    dns_nameservers    = join("\n", formatlist("    - %s", var.dns_nameservers))
    packages           = join("\n", formatlist("  - %s", var.packages))
    commands           = join("\n", data.template_file.storage_commands.*.rendered)
  }
}

resource "libvirt_volume" "storage" {
  count          = var.storages
  name           = "${var.stack_name}-storage-volume-${count.index}"
  pool           = var.pool
  size           = var.storage_disk_size
  base_volume_id = libvirt_volume.image.id
}

resource "libvirt_cloudinit_disk" "storage" {
  # needed when 0 storage nodes are defined
  count     = var.storages
  name      = "${var.stack_name}-storage-cloudinit-disk-${count.index}"
  pool      = var.pool
  user_data = data.template_file.storage_cloud-init[count.index].rendered
}

# Create the machine
resource "libvirt_domain" "storage" {
  count  = var.storages
  name   = "${var.stack_name}-storage-domain-${count.index}"
  memory = var.storage_memory
  vcpu   = var.storage_vcpu
  # emulator = "/usr/bin/qemu-system-x86_64"
  cloudinit = element(
    libvirt_cloudinit_disk.storage.*.id,
    count.index
  )
  depends_on = [libvirt_domain.lb, ]

  network_interface {
    network_name   = var.network_name
    network_id     = var.network_name == "" ? libvirt_network.network.0.id : null
    hostname       = "${var.stack_name}-storage-${count.index}"
    wait_for_lease = true
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  cpu = {
    mode = "host-passthrough"
  }

  disk {
    volume_id = element(
      libvirt_volume.storage.*.id,
      count.index
    )
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }
}

# resource "null_resource" "storage_wait_cloudinit" {
#   count      = var.storages
#   depends_on = [libvirt_domain.storage,]

#   connection {
#     host = element(
#       libvirt_domain.storage.*.network_interface.0.addresses.0,
#       count.index
#     )
#     user     = var.username
#     password = var.password
#     type     = "ssh"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo cloud-init status --wait > /dev/null",
#     ]
#   }
# }

# resource "null_resource" "storage_wait_set_hostname" {
#   count      = var.storages
#   depends_on = [libvirt_domain.storage, ]

#   connection {
#     host = element(
#       libvirt_domain.storage.*.network_interface.0.addresses.0,
#       count.index
#     )
#     user     = var.username
#     password = var.password
#     type     = "ssh"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo hostnamectl set-hostname ${var.stack_name}-storage-${count.index}",
#     ]
#   }
# }

# resource "null_resource" "storage_reboot" {
#   count      = var.storages
#   depends_on = [null_resource.storage_wait_cloudinit,]

#   provisioner "local-exec" {
#     environment = {
#       user = var.username
#       host = element(
#         libvirt_domain.storage.*.network_interface.0.addresses.0,
#         count.index
#       )
#     }

#     command = <<EOT
# ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $user@$host sudo reboot || :
# # wait for ssh ready after reboot
# until nc -zv $host 22; do sleep 5; done
# ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -oConnectionAttempts=60 $user@$host /usr/bin/true
# EOT

#   }
# }
