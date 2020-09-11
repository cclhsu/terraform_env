# resource "libvirt_pool" "pool" {
#   name = var.pool
#   type = "dir"
#   path = "/tmp/terraform-provider-libvirt-pool-${var.pool}"
# }

# We fetch the latest centos release image from their mirrors
resource "libvirt_volume" "lb_image" {
  name   = "${var.stack_name}-lb-${basename(var.lb_image_uri)}"
  source = var.lb_image_uri
  pool   = var.pool
  format = "qcow2"
}

data "template_file" "haproxy_apiserver_backends_lb" {
  count    = var.create_lb ? 1 : 0
  template = "server $${fqdn} $${ip}:6443\n"

  vars = {
    fqdn = "${var.stack_name}-lb-${count.index}.${var.dns_domain}",
    ip   = libvirt_domain.lb[count.index].network_interface.0.addresses.0,
  }
}

data "template_file" "lb_haproxy_cfg" {
  count    = var.create_lb ? 1 : 0
  template = file("${path.module}/cloud-init/haproxy.cfg.tpl")

  vars = {
    apiserver_backends = join(
      "  ",
      data.template_file.haproxy_apiserver_backends_lb.*.rendered,
    )
  }
}

data "template_file" "lb_commands" {
  count    = var.create_lb ? 1 : 0
  template = file("${path.module}/cloud-init/commands.tpl")
}

data "template_file" "lb_cloud-init" {
  count    = var.create_lb ? 1 : 0
  template = file("${path.module}/cloud-init/lb.tpl")

  vars = {
    authorized_keys    = join("\n", formatlist("  - %s", var.authorized_keys))
    username           = var.username
    password           = var.password
    hostname           = "${var.stack_name}-lb"
    hostname_from_dhcp = var.hostname_from_dhcp == true && var.cpi_enable == false ? "yes" : "no"
    ntp_servers        = join("\n", formatlist("    - %s", var.ntp_servers))
    dns_nameservers    = join("\n", formatlist("    - %s", var.dns_nameservers))
    packages           = join("\n", formatlist("  - %s", var.packages))
    commands           = join("\n", data.template_file.lb_commands.*.rendered)
  }
}

resource "libvirt_volume" "lb" {
  count          = var.create_lb ? 1 : 0
  name           = "${var.stack_name}-lb-volume"
  pool           = var.pool
  size           = var.lb_disk_size
  base_volume_id = libvirt_volume.lb_image.id
}

resource "libvirt_cloudinit_disk" "lb" {
  count = var.create_lb ? 1 : 0
  name  = "${var.stack_name}-lb-cloudinit-disk"
  pool  = var.pool

  user_data = data.template_file.lb_cloud-init[count.index].rendered
}

# Create the machine
resource "libvirt_domain" "lb" {
  count     = var.create_lb ? 1 : 0
  name      = "${var.stack_name}-lb-domain"
  memory    = var.lb_memory
  vcpu      = var.lb_vcpu
  cloudinit = libvirt_cloudinit_disk.lb[0].id

  network_interface {
    network_name   = var.network_name
    network_id     = var.network_name == "" ? libvirt_network.network.0.id : null
    hostname       = "${var.stack_name}-lb"
    wait_for_lease = true
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
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
      libvirt_volume.lb.*.id,
      count.index,
    )
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }
}

# resource "null_resource" "lb_wait_cloudinit" {
#   count      = var.create_lb ? 1 : 0
#   depends_on = [libvirt_domain.lb,]

#   connection {
#     host = element(
#       libvirt_domain.lb.*.network_interface.0.addresses.0,
#       count.index,
#     )
#     user     = var.username
#     password = var.password
#     type     = "ssh"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "cloud-init status --wait > /dev/null",
#     ]
#   }
# }

resource "null_resource" "lb_wait_set_hostname" {
  count      = var.create_lb ? 1 : 0
  depends_on = [libvirt_domain.lb, ]

  connection {
    host = element(
      libvirt_domain.lb.*.network_interface.0.addresses.0,
      count.index,
    )
    user     = var.username
    password = var.password
    type     = "ssh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname ${var.stack_name}-lb",
    ]
  }
}

# resource "null_resource" "lb_push_haproxy_cfg" {
#   count      = var.create_lb ? 1 : 0
#   depends_on = [null_resource.lb_wait_cloudinit,]

#   triggers = {
#     lb_count = var.create_lb ? 1 : 0
#   }

#   connection {
#     host = element(
#       libvirt_domain.lb.*.network_interface.0.addresses.0,
#       count.index,
#     )
#     user  = var.username
#     type  = "ssh"
#     agent = true
#   }

#   provisioner "file" {
#     content     = data.template_file.lb_haproxy_cfg.rendered
#     destination = "/tmp/haproxy.cfg"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo mv /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg",
#       "sudo systemctl enable haproxy && sudo systemctl restart haproxy",
#     ]
#   }
# }
