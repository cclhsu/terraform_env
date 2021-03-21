data "template_file" "etcd_repositories" {
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

data "template_file" "etcd_commands" {
  count    = join("", var.packages) == "" ? 0 : 1
  template = file("${path.module}/cloud-init/commands.tpl")

  vars = {
    packages = join(" ", var.packages)
  }
}

data "template_file" "etcd_cloud-init" {
  count    = var.etcds
  template = file("${path.module}/cloud-init/cloud-init.yaml.tpl")

  vars = {
    authorized_keys    = join("\n", formatlist("  - %s", var.authorized_keys))
    username           = var.username
    password           = var.password
    hostname           = "${var.stack_name}-etcd-${count.index}"
    hostname_from_dhcp = var.hostname_from_dhcp == true && var.cpi_enable == false ? "yes" : "no"
    ntp_servers        = join("\n", formatlist("    - %s", var.ntp_servers))
    dns_nameservers    = join("\n", formatlist("    - %s", var.dns_nameservers))
    repositories       = length(var.repositories) == 0 ? "\n" : join("\n", data.template_file.etcd_repositories.*.rendered)
    packages           = join("\n", formatlist("  - %s", var.packages))
    commands           = join("\n", data.template_file.etcd_commands.*.rendered)
  }
}

resource "libvirt_volume" "etcd" {
  count          = var.etcds
  name           = "${var.stack_name}-etcd-volume-${count.index}"
  pool           = var.pool
  size           = var.etcd_disk_size
  base_volume_id = libvirt_volume.image.id
}

resource "libvirt_cloudinit_disk" "etcd" {
  # needed when 0 etcd nodes are defined
  count     = var.etcds
  name      = "${var.stack_name}-etcd-cloudinit-disk-${count.index}"
  pool      = var.pool
  user_data = data.template_file.etcd_cloud-init[count.index].rendered
}

# Create the machine
resource "libvirt_domain" "etcd" {
  count  = var.etcds
  name   = "${var.stack_name}-etcd-domain-${count.index}"
  memory = var.etcd_memory
  vcpu   = var.etcd_vcpu
  # emulator = "/usr/bin/qemu-system-x86_64"
  cloudinit = element(
    libvirt_cloudinit_disk.etcd.*.id,
    count.index
  )
  depends_on = [libvirt_domain.lb, ]

  network_interface {
    network_name   = var.network_name
    network_id     = var.network_name == "" ? libvirt_network.network.0.id : null
    hostname       = "${var.stack_name}-etcd-${count.index}"
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
      libvirt_volume.etcd.*.id,
      count.index
    )
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }
}

# resource "null_resource" "etcd_wait_cloudinit" {
#   count      = var.etcds
#   depends_on = [libvirt_domain.etcd,]

#   connection {
#     host = element(
#       libvirt_domain.etcd.*.network_interface.0.addresses.0,
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

# resource "null_resource" "etcd_wait_set_hostname" {
#   count      = var.etcds
#   depends_on = [libvirt_domain.etcd, ]

#   connection {
#     host = element(
#       libvirt_domain.etcd.*.network_interface.0.addresses.0,
#       count.index
#     )
#     user     = var.username
#     password = var.password
#     type     = "ssh"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo hostnamectl set-hostname ${var.stack_name}-etcd-${count.index}",
#     ]
#   }
# }

# resource "null_resource" "etcd_reboot" {
#   count      = var.etcds
#   depends_on = [null_resource.etcd_wait_cloudinit,]

#   provisioner "local-exec" {
#     environment = {
#       user = var.username
#       host = element(
#         libvirt_domain.etcd.*.network_interface.0.addresses.0,
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
