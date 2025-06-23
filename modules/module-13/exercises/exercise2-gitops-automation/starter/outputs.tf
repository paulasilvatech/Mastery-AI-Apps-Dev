# outputs.tf - Output definitions

# TODO: Add outputs for deployed resources

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# TODO: Add more outputs
# output "webapp_url" {
#   description = "URL of the deployed web app"
#   value       = module.webapp.url
# }

# output "database_connection_string" {
#   description = "Database connection string"
#   value       = module.database.connection_string
#   sensitive   = true
# } 