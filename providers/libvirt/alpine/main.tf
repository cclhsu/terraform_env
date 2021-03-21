# instance the provider
provider "libvirt" {
  uri = var.libvirt_keyfile == "" ? var.libvirt_uri : "${var.libvirt_uri}?keyfile=${var.libvirt_keyfile}"
}

# resource "libvirt_pool" "pool" {
#   name = var.pool
#   type = "dir"
#   path = "/tmp/terraform-provider-libvirt-pool-${var.pool}"
# }

# We fetch the latest alpine release image from their mirrors
resource "libvirt_volume" "image" {
  name   = "${var.stack_name}-${basename(var.image_uri)}"
  source = var.image_uri
  pool   = var.pool
  format = "qcow2"
}
