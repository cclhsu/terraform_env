# https://www.terraform.io/docs/providers/openstack/r/images_image_v2.html
# resource "openstack_images_image_v2" "ubuntu" {
#   name             = "Ubuntu 16.04"
#   image_source_url = "https://releases.rancher.com/os/latest/rancheros-openstack.img"
#   container_format = "bare"
#   disk_format      = "qcow2"

#   properties = {
#     key = "value"
#   }
# }

# data "openstack_images_image_v2" "ubuntu" {
#   name        = "Ubuntu 16.04"
#   most_recent = true

#   properties = {
#     key = "value"
#   }
# }

# resource "openstack_images_image_v2" "hgi-image" {
#   name             = "${var.env}-${var.region}-${var.setup}-${var.image_name}"
#   image_source_url = "${var.image_url_base}/${var.image_name}"
#   container_format = "${var.image_container_format}"
#   disk_format      = "${var.image_disk_format}"

#   properties {
#     user = "beastie"
#   }
# }
