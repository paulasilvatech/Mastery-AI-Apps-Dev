# Output definitions for development environment

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# AI Services Outputs
output "openai_endpoint" {
  description = "Azure OpenAI endpoint"
  value       = module.ai_services.openai_endpoint
}

output "openai_key" {
  description = "Azure OpenAI access key"
  value       = module.ai_services.openai_key
  sensitive   = true
}

output "search_endpoint" {
  description = "Azure AI Search endpoint"
  value       = module.ai_services.search_endpoint
}

output "search_admin_key" {
  description = "Azure AI Search admin key"
  value       = module.ai_services.search_admin_key
  sensitive   = true
}

output "cosmosdb_endpoint" {
  description = "Cosmos DB endpoint"
  value       = module.ai_services.cosmosdb_endpoint
}

output "cosmosdb_key" {
  description = "Cosmos DB primary key"
  value       = module.ai_services.cosmosdb_key
  sensitive   = true
}

# Storage Outputs
output "storage_account_name" {
  description = "Storage account name"
  value       = module.storage.storage_account_name
}

output "storage_account_key" {
  description = "Storage account primary key"
  value       = module.storage.storage_account_key
  sensitive   = true
}

output "storage_blob_endpoint" {
  description = "Storage blob endpoint"
  value       = module.storage.blob_endpoint
}

# Compute Outputs
output "app_service_plan_id" {
  description = "App Service Plan ID"
  value       = module.compute.app_service_plan_id
}

output "function_app_name" {
  description = "Function App name"
  value       = module.compute.function_app_name
}

output "function_app_default_hostname" {
  description = "Function App default hostname"
  value       = module.compute.function_app_default_hostname
}

# Monitoring Outputs
output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = module.monitoring.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = module.monitoring.connection_string
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = module.monitoring.log_analytics_workspace_id
}

# Networking Outputs
output "vnet_id" {
  description = "Virtual Network ID"
  value       = module.networking.vnet_id
}

output "subnet_ids" {
  description = "Map of subnet IDs"
  value       = module.networking.subnet_ids
}

# Environment Configuration
output "environment_config" {
  description = "Environment configuration summary"
  value = {
    environment          = local.environment
    project_name        = var.project_name
    location            = local.location
    auto_shutdown       = var.enable_auto_shutdown
    resource_group_name = azurerm_resource_group.main.name
  }
}
