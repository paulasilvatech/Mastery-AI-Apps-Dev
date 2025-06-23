# modules/network/outputs.tf - Network module outputs

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "subnet_web_id" {
  description = "ID of the web subnet"
  value       = azurerm_subnet.web.id
}

output "subnet_app_id" {
  description = "ID of the app subnet"
  value       = azurerm_subnet.app.id
}

output "subnet_data_id" {
  description = "ID of the data subnet"
  value       = azurerm_subnet.data.id
}

output "nsg_web_id" {
  description = "ID of the web network security group"
  value       = azurerm_network_security_group.web.id
}

output "nsg_app_id" {
  description = "ID of the app network security group"
  value       = azurerm_network_security_group.app.id
}

output "nsg_data_id" {
  description = "ID of the data network security group"
  value       = azurerm_network_security_group.data.id
} 