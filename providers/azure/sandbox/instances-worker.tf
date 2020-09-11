# https://www.terraform.io/docs/providers/azurerm/r/network_interface.html
resource "azurerm_network_interface" "worker" {
  count               = var.workers
  name                = "${var.stack_name}-worker-${count.index}-nic"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.nodes.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.create_bastionhost ? null : element(azurerm_public_ip.worker.*.id, count.index)
  }
}

# https://www.terraform.io/docs/providers/azurerm/r/network_interface_security_group_association.html
resource "azurerm_network_interface_security_group_association" "worker" {
  count                     = var.workers
  network_interface_id      = element(azurerm_network_interface.worker.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.worker.id
}

# https://www.terraform.io/docs/providers/azurerm/r/linux_virtual_machine.html
# https://www.terraform.io/docs/providers/azurerm/r/linux_virtual_machine_scale_set.html
resource "azurerm_linux_virtual_machine" "worker" {
  count                 = var.workers
  name                  = "${var.stack_name}-worker-${count.index}-vm"
  resource_group_name   = azurerm_resource_group.resource_group.name
  location              = azurerm_resource_group.resource_group.location
  zone                  = var.enable_zone ? var.azure_availability_zones[count.index % length(var.azure_availability_zones)] : null
  size                  = var.worker_vm_size
  network_interface_ids = [element(azurerm_network_interface.worker.*.id, count.index), ]

  admin_username = var.username
  admin_ssh_key {
    username   = var.username
    public_key = var.authorized_keys.0
    # public_key = file("~/.ssh/id_rsa.pub")
  }
  admin_password                  = var.password
  disable_password_authentication = (var.password == "") ? true : false
  custom_data                     = data.template_cloudinit_config.cfg.rendered

  os_disk {
    name                 = "${var.stack_name}-worker-${count.index}-disk"
    caching              = "ReadOnly"
    storage_account_type = var.worker_storage_account_type
    disk_size_gb         = var.worker_disk_size
  }

  source_image_reference {
    publisher = "SUSE"
    offer     = "sles-15-sp2-chost-byos"
    sku       = "gen2"
    version   = data.azurerm_platform_image.sles_chost_byos.version
  }
  priority        = var.worker_use_spot_instance ? "Spot" : "Regular"
  eviction_policy = var.worker_use_spot_instance ? "Deallocate" : null

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [source_image_id]
  }
}
