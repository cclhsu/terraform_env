# output "bastion_host" {
#   value = var.create_bastionhost ? azurerm_bastion_host.bastionhost.0.dns_name : "creation disabled"
# }

# output "loadbalancer" {
#   value = {
#     "public_ip" : azurerm_public_ip.lb.ip_address,
#     "fqdn" : azurerm_public_ip.lb.fqdn,
#   }
# }

# # output "etcds" {
# #   value = { for vm in azurerm_linux_virtual_machine.etcd :
# #     "${vm.computer_name}.${var.dnsdomain}" => {
# #       "public_ip" : vm.public_ip_address,
# #       "private_ip" : vm.private_ip_address,
# #     }
# #   }
# # }


# # output "storages" {
# #   value = { for vm in azurerm_linux_virtual_machine.storage :
# #     "${vm.computer_name}.${var.dnsdomain}" => {
# #       "public_ip" : vm.public_ip_address,
# #       "private_ip" : vm.private_ip_address,
# #     }
# #   }
# # }

# output "masters" {
#   value = { for vm in azurerm_linux_virtual_machine.master :
#     "${vm.computer_name}.${var.dnsdomain}" => {
#       "public_ip" : vm.public_ip_address,
#       "private_ip" : vm.private_ip_address,
#     }
#   }
# }

# output "workers" {
#   value = { for vm in azurerm_linux_virtual_machine.worker :
#     "${vm.computer_name}.${var.dnsdomain}" => {
#       # "public_ip":  vm.public_ip_address,
#       "private_ip" : vm.private_ip_address,
#     }
#   }
# }

# ---

output "username" {
  value = var.username
}

output "bastion_host" {
  value = var.create_bastionhost ? azurerm_bastion_host.bastionhost.0.dns_name : "creation disabled"
}

output "ip_load_balancer" {
  value = {
    "public_ip" : azurerm_public_ip.lb.ip_address,
    "fqdn" : azurerm_public_ip.lb.fqdn,
  }
}

# output "etcds_public_ip" {
#   value = zipmap(
#     azurerm_linux_virtual_machine.etcd.*.name,
#     azurerm_linux_virtual_machine.etcd.*.public_ip_address,
#   )
# }

# output "etcds_private_ip" {
#   value = zipmap(
#     azurerm_linux_virtual_machine.etcd.*.name,
#     azurerm_linux_virtual_machine.etcd.*.private_ip_address,
#   )
# }

# output "storages_public_ip" {
#   value = zipmap(
#     azurerm_linux_virtual_machine.storage.*.name,
#     azurerm_linux_virtual_machine.storage.*.public_ip_address,
#   )
# }

# output "storages_private_ip" {
#   value = zipmap(
#     azurerm_linux_virtual_machine.storage.*.name,
#     azurerm_linux_virtual_machine.storage.*.private_ip_address
#   )
# }

output "masters_public_ip" {
  value = zipmap(
    azurerm_linux_virtual_machine.master.*.name,
    azurerm_linux_virtual_machine.master.*.public_ip_address,
  )
}

output "masters_private_ip" {
  value = zipmap(
    azurerm_linux_virtual_machine.master.*.name,
    azurerm_linux_virtual_machine.master.*.private_ip_address,
  )
}

# Should remove for production for security reason
output "workers_public_ip" {
  value = zipmap(
    azurerm_linux_virtual_machine.worker.*.name,
    azurerm_linux_virtual_machine.worker.*.public_ip_address,
  )
}

output "workers_private_ip" {
  value = zipmap(
    azurerm_linux_virtual_machine.worker.*.name,
    azurerm_linux_virtual_machine.worker.*.private_ip_address
  )
}

output "route_table" {
  value = var.cpi_enable ? azurerm_route_table.nodes[0].name : null
}
