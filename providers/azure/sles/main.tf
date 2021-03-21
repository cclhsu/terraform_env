# https://www.terraform.io/docs/providers/azurerm/index.html
# https://github.com/terraform-providers/terraform-provider-azurerm/releases
provider "azurerm" {
  features {}
  # version="=2.7.0"
}

# https://www.terraform.io/docs/providers/azurerm/r/resource_group.html
resource "azurerm_resource_group" "resource_group" {
  name     = "${var.stack_name}-resource-group"
  location = var.azure_location
}

# https://www.terraform.io/docs/providers/azurerm/d/platform_image.html
# az vm image list --output table
# az image list -o table
data "azurerm_platform_image" "sles_chost_byos" {
  location  = azurerm_resource_group.resource_group.location
  publisher = "SUSE"
  offer     = "sles-15-sp2-chost-byos"
  sku       = "gen2"
}

# # Use this for first time upload
# # https://www.terraform.io/docs/providers/azurerm/r/image.html
# resource "azurerm_image" "sles_chost_byos" {
#   name     = "sles-15-sp2-chost-byos"
#   location = "Southeast Asia"
#   # resource_group_name = "${var.stack_name}-resource-group"
#   resource_group_name = "sles001-resource-group"

#   os_disk {
#     os_type  = "Linux"
#     os_state = "Generalized"
#     blob_uri = "https://sles001rgsa.blob.core.windows.net/slesspx/slesspx.vhd"
#     size_gb  = 30
#   }
# }

# # Use this for existing image
# # https://www.terraform.io/docs/providers/azurerm/d/image.html
# data "azurerm_image" "sles_chost_byos" {
#   name                = "sles-15-sp2-chost-byos"
#   resource_group_name = "sles001-resource-group"

#   # name = "SLES15-SP2-CHOST-BYOS.x86_64-0.9.12-Azure-Build1.4.vhd"
#   # resource_group_name = "OPENQA-UPLOAD"
# }

data "azurerm_subscription" "current" {
}

data "azurerm_role_definition" "contributor" {
  name = "Contributor"
}
