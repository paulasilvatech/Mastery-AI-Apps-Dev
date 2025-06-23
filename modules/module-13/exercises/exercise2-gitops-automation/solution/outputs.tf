# outputs.tf - Output definitions for deployed resources

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

output "webapp_url" {
  description = "URL of the deployed web app"
  value       = module.webapp.url
}

output "webapp_identity_principal_id" {
  description = "Principal ID of the web app's managed identity"
  value       = module.webapp.identity_principal_id
}

output "database_server_fqdn" {
  description = "FQDN of the database server"
  value       = module.database.server_fqdn
}

output "database_name" {
  description = "Name of the database"
  value       = module.database.database_name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.network.vnet_id
}

output "subnet_ids" {
  description = "IDs of all subnets"
  value = {
    web  = module.network.subnet_web_id
    app  = module.network.subnet_app_id
    data = module.network.subnet_data_id
  }
}

output "deployment_info" {
  description = "Deployment information summary"
  value = {
    environment    = var.environment
    project        = var.project_name
    location       = var.location
    deployed_at    = timestamp()
    resource_count = length(azurerm_resource_group.main.tags)
  }
} 