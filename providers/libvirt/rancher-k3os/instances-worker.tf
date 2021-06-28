data "template_file" "worker_commands" {
  count    = join("", var.packages) == "" ? 0 : 1
  template = file("${path.module}/cloud-init/commands.tpl")
}

data "template_file" "worker_cloud-init" {
  count    = var.workers
  template = file("${path.module}/cloud-init/cloud-init.yaml.tpl")

  vars = {
    authorized_keys    = join("\n", formatlist("  - %s", var.authorized_keys))
    username           = var.username
    password           = var.password
    hostname           = "${var.stack_name}-worker-${count.index}"
    hostname_from_dhcp = var.hostname_from_dhcp == true && var.cpi_enable == false ? "yes" : "no"
    ntp_servers        = join("\n", formatlist("    - %s", var.ntp_servers))
    dns_nameservers    = join("\n", formatlist("    - %s", var.dns_nameservers))
    packages           = join("\n", formatlist("  - %s", var.packages))
    commands           = join("\n", data.template_file.worker_commands.*.rendered)
  }
}

resource "libvirt_volume" "worker" {
  count          = var.workers
  name           = "${var.stack_name}-worker-volume-${count.index}"
  pool           = var.pool
  size           = var.worker_disk_size
  base_volume_id = libvirt_volume.image.id
}

resource "libvirt_cloudinit_disk" "worker" {
  # needed when 0 worker nodes are defined
  count     = var.workers
  name      = "${var.stack_name}-worker-cloudinit-disk-${count.index}"
  pool      = var.pool
  user_data = data.template_file.worker_cloud-init[count.index].rendered
}

# Create the machine
resource "libvirt_domain" "worker" {
  count  = var.workers
  name   = "${var.stack_name}-worker-domain-${count.index}"
  memory = var.worker_memory
  vcpu   = var.worker_vcpu
  # emulator = "/usr/bin/qemu-system-x86_64"
  cloudinit = element(
    libvirt_cloudinit_disk.worker.*.id,
    count.index
  )
  depends_on = [
    libvirt_domain.lb,
    null_resource.lb_push_http_server_cfg,
    libvirt_domain.master,
    null_resource.wait_for_cluster
  ]

  network_interface {
    network_name   = var.network_name
    network_id     = var.network_name == "" ? libvirt_network.network.0.id : null
    hostname       = "${var.stack_name}-worker-${count.index}"
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

  # kernel = libvirt_volume.kernel.id
  # initrd = libvirt_volume.initrd.id
  # squashfs = libvirt_volume.squashfs.id

  # cmdline = [
  #   {
  #     # "k3os.mode"               = "install"
  #     "k3os.fallback_mode"      = "install"
  #     "k3os.install.config_url" = format("http://%s:80/cloud-init-agent.yaml", libvirt_domain.lb.0.network_interface.0.addresses.0)
  #     "k3os.install.silent"     = true
  #     "k3os.install.device"     = "/dev/vda"
  #     "k3os.server_url"         = format("https://%s:6443", libvirt_domain.master.0.network_interface.0.addresses.0)
  #     "k3os.password"           = var.password
  #     "k3os.token"              = random_password.k3s_token.result
  #   },
  # ]

  disk {
    volume_id = element(
      libvirt_volume.worker.*.id,
      count.index
    )
  }

  # disk {
  #   file = libvirt_volume.iso.id
  # }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }
}

# resource "null_resource" "worker_wait_cloudinit" {
#   count      = var.workers
#   depends_on = [libvirt_domain.worker,]

#   connection {
#     host = element(
#       libvirt_domain.worker.*.network_interface.0.addresses.0,
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

# resource "null_resource" "worker_wait_set_hostname" {
#   count      = var.workers
#   depends_on = [libvirt_domain.worker, ]

#   connection {
#     host = element(
#       libvirt_domain.worker.*.network_interface.0.addresses.0,
#       count.index
#     )
#     user     = var.username
#     password = var.password
#     type     = "ssh"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo hostnamectl set-hostname ${var.stack_name}-worker-${count.index}",
#     ]
#   }
# }

# resource "null_resource" "worker_reboot" {
#   count      = var.workers
#   depends_on = [null_resource.worker_wait_cloudinit,]

#   provisioner "local-exec" {
#     environment = {
#       user = var.username
#       host = element(
#         libvirt_domain.worker.*.network_interface.0.addresses.0,
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
