# modules/network/main.tf - Network module

# TODO: Implement network module
# This module should create:
# - Virtual Network
# - Subnets (web, app, data)
# - Network Security Groups
# - NSG associations

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# TODO: Add VNet resource
# resource "azurerm_virtual_network" "main" {
#   name                = "vnet-${var.environment}"
#   ...
# }

# TODO: Add outputs
# output "vnet_id" {
#   value = azurerm_virtual_network.main.id
# } 