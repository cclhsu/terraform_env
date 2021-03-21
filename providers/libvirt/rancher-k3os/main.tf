# instance the provider
provider "libvirt" {
  uri = var.libvirt_keyfile == "" ? var.libvirt_uri : "${var.libvirt_uri}?keyfile=${var.libvirt_keyfile}"
}

# resource "libvirt_pool" "pool" {
#   name = var.pool
#   type = "dir"
#   path = "/tmp/terraform-provider-libvirt-pool-${var.pool}"
# }

# We fetch the latest rancher-k3os release image from their mirrors
resource "libvirt_volume" "image" {
  name   = "${var.stack_name}-${basename(var.image_uri)}"
  source = var.image_uri
  pool   = var.pool
  format = "qcow2"
}

# resource "libvirt_volume" "kernel" {
#   name   = "kernel-${var.stack_name}"
#   # source = "https://github.com/rancher/k3os/releases/download/${var.k3os_version}/k3os-vmlinuz-amd64"
#   source = var.kernel_uri
#   pool   = var.pool
#   format = "raw"
# }

# resource "libvirt_volume" "initrd" {
#   name   = "initrd-${var.stack_name}"
#   # source = "https://github.com/rancher/k3os/releases/download/${var.k3os_version}/k3os-initrd-amd64"
#   source = var.initrd_uri
#   pool   = var.pool
#   format = "raw"
# }

# resource "libvirt_volume" "iso" {
#   name   = "k3os-amd64-${var.stack_name}.iso"
#   # source = "https://github.com/rancher/k3os/releases/download/${var.k3os_version}/k3os-amd64.iso"
#   source = var.iso_uri
#   pool   = var.pool
#   format = "iso"
# }
