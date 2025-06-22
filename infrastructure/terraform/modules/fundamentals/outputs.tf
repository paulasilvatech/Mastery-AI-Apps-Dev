# Outputs for Fundamentals Module (Modules 1-5)

# Storage Account Outputs
output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.fundamentals.name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.fundamentals.id
}

output "storage_account_key" {
  description = "Primary access key for the storage account"
  value       = azurerm_storage_account.fundamentals.primary_access_key
  sensitive   = true
}

output "storage_account_connection_string" {
  description = "Connection string for the storage account"
  value       = azurerm_storage_account.fundamentals.primary_connection_string
  sensitive   = true
}

output "storage_container_names" {
  description = "Names of created storage containers"
  value = [
    azurerm_storage_container.workshop_files.name,
    azurerm_storage_container.code_samples.name
  ]
}

output "file_share_name" {
  description = "Name of the file share"
  value       = azurerm_storage_share.fundamentals.name
}

# Web App Outputs (Module 3+)
output "app_service_plan_id" {
  description = "ID of the App Service Plan"
  value       = var.module_number >= 3 ? azurerm_service_plan.fundamentals[0].id : null
}

output "web_app_name" {
  description = "Name of the web app"
  value       = var.module_number >= 3 ? azurerm_linux_web_app.fundamentals[0].name : null
}

output "web_app_url" {
  description = "URL of the web app"
  value       = var.module_number >= 3 ? "https://${azurerm_linux_web_app.fundamentals[0].default_hostname}" : null
}

output "web_app_hostname" {
  description = "Default hostname of the web app"
  value       = var.module_number >= 3 ? azurerm_linux_web_app.fundamentals[0].default_hostname : null
}

output "web_app_identity_principal_id" {
  description = "Principal ID of the web app's managed identity"
  value       = var.module_number >= 3 ? azurerm_linux_web_app.fundamentals[0].identity[0].principal_id : null
}

# Static Web App Outputs (Module 4+)
output "static_web_app_name" {
  description = "Name of the Static Web App"
  value       = var.module_number >= 4 ? azurerm_static_site.fundamentals[0].name : null
}

output "static_web_app_url" {
  description = "URL of the Static Web App"
  value       = var.module_number >= 4 ? azurerm_static_site.fundamentals[0].default_host_name : null
}

output "static_web_app_api_key" {
  description = "API key for the Static Web App"
  value       = var.module_number >= 4 ? azurerm_static_site.fundamentals[0].api_key : null
  sensitive   = true
}

# Function App Outputs (Module 5)
output "function_app_name" {
  description = "Name of the Function App"
  value       = var.module_number >= 5 ? azurerm_linux_function_app.fundamentals[0].name : null
}

output "function_app_url" {
  description = "URL of the Function App"
  value       = var.module_number >= 5 ? "https://${azurerm_linux_function_app.fundamentals[0].default_hostname}" : null
}

output "function_app_hostname" {
  description = "Default hostname of the Function App"
  value       = var.module_number >= 5 ? azurerm_linux_function_app.fundamentals[0].default_hostname : null
}

output "function_app_identity_principal_id" {
  description = "Principal ID of the Function App's managed identity"
  value       = var.module_number >= 5 ? azurerm_linux_function_app.fundamentals[0].identity[0].principal_id : null
}

# Cosmos DB Outputs (Module 4+)
output "cosmos_db_account_name" {
  description = "Name of the Cosmos DB account"
  value       = var.module_number >= 4 ? azurerm_cosmosdb_account.fundamentals[0].name : null
}

output "cosmos_db_endpoint" {
  description = "Endpoint URL of the Cosmos DB account"
  value       = var.module_number >= 4 ? azurerm_cosmosdb_account.fundamentals[0].endpoint : null
}

output "cosmos_db_primary_key" {
  description = "Primary key of the Cosmos DB account"
  value       = var.module_number >= 4 ? azurerm_cosmosdb_account.fundamentals[0].primary_key : null
  sensitive   = true
}

output "cosmos_db_connection_strings" {
  description = "Connection strings for the Cosmos DB account"
  value       = var.module_number >= 4 ? azurerm_cosmosdb_account.fundamentals[0].connection_strings : null
  sensitive   = true
}

output "cosmos_db_database_name" {
  description = "Name of the Cosmos DB database"
  value       = var.module_number >= 4 ? azurerm_cosmosdb_sql_database.fundamentals[0].name : null
}

output "cosmos_db_container_name" {
  description = "Name of the Cosmos DB container"
  value       = var.module_number >= 4 ? azurerm_cosmosdb_sql_container.fundamentals[0].name : null
}

# Logic App Outputs (Module 5)
output "logic_app_name" {
  description = "Name of the Logic App"
  value       = var.module_number >= 5 ? azurerm_logic_app_workflow.fundamentals[0].name : null
}

output "logic_app_id" {
  description = "ID of the Logic App"
  value       = var.module_number >= 5 ? azurerm_logic_app_workflow.fundamentals[0].id : null
}

output "logic_app_callback_url" {
  description = "Callback URL of the Logic App"
  value       = var.module_number >= 5 ? azurerm_logic_app_workflow.fundamentals[0].access_endpoint : null
  sensitive   = true
}

# Communication Service Outputs (Module 5)
output "communication_service_name" {
  description = "Name of the Communication Service"
  value       = var.module_number >= 5 ? azurerm_communication_service.fundamentals[0].name : null
}

output "communication_service_connection_string" {
  description = "Connection string for the Communication Service"
  value       = var.module_number >= 5 ? azurerm_communication_service.fundamentals[0].primary_connection_string : null
  sensitive   = true
}

# Summary outputs for easy reference
output "module_resources_summary" {
  description = "Summary of created resources for this module"
  value = {
    module_number = var.module_number
    environment   = var.environment
    storage_account = {
      name = azurerm_storage_account.fundamentals.name
      containers = [
        azurerm_storage_container.workshop_files.name,
        azurerm_storage_container.code_samples.name
      ]
      file_share = azurerm_storage_share.fundamentals.name
    }
    web_resources = var.module_number >= 3 ? {
      app_service_plan = azurerm_service_plan.fundamentals[0].name
      web_app = azurerm_linux_web_app.fundamentals[0].name
      web_app_url = "https://${azurerm_linux_web_app.fundamentals[0].default_hostname}"
    } : null
    static_web_app = var.module_number >= 4 ? {
      name = azurerm_static_site.fundamentals[0].name
      url = azurerm_static_site.fundamentals[0].default_host_name
    } : null
    database = var.module_number >= 4 ? {
      cosmos_account = azurerm_cosmosdb_account.fundamentals[0].name
      database = azurerm_cosmosdb_sql_database.fundamentals[0].name
      container = azurerm_cosmosdb_sql_container.fundamentals[0].name
    } : null
    serverless = var.module_number >= 5 ? {
      function_app = azurerm_linux_function_app.fundamentals[0].name
      logic_app = azurerm_logic_app_workflow.fundamentals[0].name
      communication_service = azurerm_communication_service.fundamentals[0].name
    } : null
  }
}

# Connection information for applications
output "app_connection_info" {
  description = "Connection information for applications"
  value = {
    storage = {
      account_name = azurerm_storage_account.fundamentals.name
      endpoint = azurerm_storage_account.fundamentals.primary_blob_endpoint
    }
    cosmos_db = var.module_number >= 4 ? {
      endpoint = azurerm_cosmosdb_account.fundamentals[0].endpoint
      database = azurerm_cosmosdb_sql_database.fundamentals[0].name
      container = azurerm_cosmosdb_sql_container.fundamentals[0].name
    } : null
    communication = var.module_number >= 5 ? {
      name = azurerm_communication_service.fundamentals[0].name
    } : null
  }
  sensitive = true
}

# URLs for quick access
output "quick_access_urls" {
  description = "Quick access URLs for workshop resources"
  value = {
    web_app = var.module_number >= 3 ? "https://${azurerm_linux_web_app.fundamentals[0].default_hostname}" : null
    static_web_app = var.module_number >= 4 ? "https://${azurerm_static_site.fundamentals[0].default_host_name}" : null
    function_app = var.module_number >= 5 ? "https://${azurerm_linux_function_app.fundamentals[0].default_hostname}" : null
    storage_explorer = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${azurerm_storage_account.fundamentals.id}/storageexplorer"
  }
}

# Get current client config for tenant ID
data "azurerm_client_config" "current" {}
