data "template_file" "worker_repositories" {
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

data "template_file" "worker_register_scc" {
  count    = var.caasp_registry_code == "" ? 0 : 1
  template = file("${path.module}/cloud-init/register-scc.tpl")

  vars = {
    caasp_registry_code = var.caasp_registry_code

    # no need to enable the SLE HA product on this kind of nodes
    ha_registry_code = ""
  }
}

data "template_file" "worker_register_rmt" {
  count    = var.rmt_server_name == "" ? 0 : 1
  template = file("${path.module}/cloud-init/register-rmt.tpl")

  vars = {
    rmt_server_name = var.rmt_server_name
  }
}

data "template_file" "worker_commands" {
  count    = join("", var.packages) == "" ? 0 : 1
  template = file("${path.module}/cloud-init/commands.tpl")

  vars = {
    packages = join(" ", var.packages)
  }
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
    repositories       = length(var.repositories) == 0 ? "\n" : join("\n", data.template_file.worker_repositories.*.rendered)
    register_scc       = var.caasp_registry_code != "" && var.rmt_server_name == "" ? join("\n", data.template_file.worker_register_scc.*.rendered) : ""
    register_rmt       = var.rmt_server_name == "" ? join("\n", data.template_file.worker_register_rmt.*.rendered) : ""
    commands           = join("\n", data.template_file.worker_commands.*.rendered)
    # packages           = join("\n", formatlist("  - %s", var.packages))
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
  depends_on = [libvirt_domain.lb, ]

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

  disk {
    volume_id = element(
      libvirt_volume.worker.*.id,
      count.index
    )
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }
}

resource "null_resource" "worker_wait_cloudinit" {
  depends_on = [libvirt_domain.worker, ]
  count      = var.workers

  connection {
    host = element(
      libvirt_domain.worker.*.network_interface.0.addresses.0,
      count.index
    )
    user     = var.username
    password = var.password
    type     = "ssh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait > /dev/null",
    ]
  }
}

resource "null_resource" "worker_reboot" {
  depends_on = [null_resource.worker_wait_cloudinit, ]
  count      = var.workers

  provisioner "local-exec" {
    environment = {
      user = var.username
      host = element(
        libvirt_domain.worker.*.network_interface.0.addresses.0,
        count.index
      )
    }

    command = <<EOT
export sshopts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -oConnectionAttempts=60"
if ! ssh $sshopts $user@$host 'sudo needs-restarting -r'; then
    ssh $sshopts $user@$host sudo reboot || :
    export delay=5
    # wait for node reboot completed
    while ! ssh $sshopts $user@$host 'sudo needs-restarting -r'; do
        sleep $delay
        delay=$((delay+1))
        [ $delay -gt 30 ] && exit 1
    done
fi
EOT
  }
}
