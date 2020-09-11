# https://www.terraform.io/docs/providers/azurerm/index.html
# https://github.com/terraform-providers/terraform-provider-azurerm/releases
provider "azurerm" {
  # version = "=2.5.0"
  features {}
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
