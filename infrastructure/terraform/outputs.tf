# Outputs for Mastery AI Workshop Terraform Configuration

# Resource Group Information
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.workshop.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.workshop.id
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.workshop.location
}

# Common Resources
output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.workshop.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.workshop.vault_uri
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.workshop.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.workshop.connection_string
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = azurerm_log_analytics_workspace.workshop.id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics workspace name"
  value       = azurerm_log_analytics_workspace.workshop.name
}

# Module-specific outputs
output "fundamentals_outputs" {
  description = "Outputs from fundamentals module"
  value = var.module_number <= 5 ? (
    length(module.fundamentals) > 0 ? module.fundamentals[0] : {}
  ) : {}
}

output "intermediate_outputs" {
  description = "Outputs from intermediate module"
  value = var.module_number >= 6 && var.module_number <= 10 ? (
    length(module.intermediate) > 0 ? module.intermediate[0] : {}
  ) : {}
}

output "advanced_outputs" {
  description = "Outputs from advanced module"
  value = var.module_number >= 11 && var.module_number <= 15 ? (
    length(module.advanced) > 0 ? module.advanced[0] : {}
  ) : {}
}

output "enterprise_outputs" {
  description = "Outputs from enterprise module"
  value = var.module_number >= 16 && var.module_number <= 20 ? (
    length(module.enterprise) > 0 ? module.enterprise[0] : {}
  ) : {}
}

output "ai_agents_outputs" {
  description = "Outputs from AI agents module"
  value = var.module_number >= 21 && var.module_number <= 25 ? (
    length(module.ai_agents) > 0 ? module.ai_agents[0] : {}
  ) : {}
}

output "enterprise_mastery_outputs" {
  description = "Outputs from enterprise mastery module"
  value = var.module_number >= 26 ? (
    length(module.enterprise_mastery) > 0 ? module.enterprise_mastery[0] : {}
  ) : {}
}

# Workshop Information
output "workshop_info" {
  description = "Workshop deployment information"
  value = {
    module_number = var.module_number
    environment   = var.environment
    location      = var.location
    track = var.module_number <= 5 ? "Fundamentals" : (
      var.module_number <= 10 ? "Intermediate" : (
        var.module_number <= 15 ? "Advanced" : (
          var.module_number <= 20 ? "Enterprise" : (
            var.module_number <= 25 ? "AI Agents" : "Enterprise Mastery"
          )
        )
      )
    )
    deployment_time = timestamp()
    tags           = local.common_tags
  }
}

# URLs and Endpoints (when applicable)
output "app_service_url" {
  description = "App Service URL (if created)"
  value = var.module_number >= 6 && var.module_number <= 10 ? (
    length(module.intermediate) > 0 ? try(module.intermediate[0].app_service_url, null) : null
  ) : (
    var.module_number >= 3 && var.module_number <= 5 ? (
      length(module.fundamentals) > 0 ? try(module.fundamentals[0].app_service_url, null) : null
    ) : null
  )
}

output "api_management_gateway_url" {
  description = "API Management Gateway URL (if created)"
  value = var.module_number >= 9 && var.module_number <= 10 ? (
    length(module.intermediate) > 0 ? try(module.intermediate[0].api_management_gateway_url, null) : null
  ) : null
}

output "kubernetes_cluster_name" {
  description = "Kubernetes cluster name (if created)"
  value = var.module_number >= 11 && var.module_number <= 15 ? (
    length(module.advanced) > 0 ? try(module.advanced[0].kubernetes_cluster_name, null) : null
  ) : null
}

output "openai_endpoint" {
  description = "Azure OpenAI endpoint (if created)"
  value = var.module_number >= 17 ? (
    var.module_number <= 20 ? (
      length(module.enterprise) > 0 ? try(module.enterprise[0].openai_endpoint, null) : null
    ) : (
      var.module_number <= 25 ? (
        length(module.ai_agents) > 0 ? try(module.ai_agents[0].openai_endpoint, null) : null
      ) : (
        length(module.enterprise_mastery) > 0 ? try(module.enterprise_mastery[0].openai_endpoint, null) : null
      )
    )
  ) : null
  sensitive = true
}

output "ai_search_endpoint" {
  description = "Azure AI Search endpoint (if created)"
  value = var.module_number >= 16 ? (
    var.module_number <= 20 ? (
      length(module.enterprise) > 0 ? try(module.enterprise[0].ai_search_endpoint, null) : null
    ) : (
      var.module_number <= 25 ? (
        length(module.ai_agents) > 0 ? try(module.ai_agents[0].ai_search_endpoint, null) : null
      ) : (
        length(module.enterprise_mastery) > 0 ? try(module.enterprise_mastery[0].ai_search_endpoint, null) : null
      )
    )
  ) : null
}

# Database Connection Strings (sensitive)
output "sql_connection_string" {
  description = "SQL Database connection string (if created)"
  value = var.module_number >= 6 ? (
    var.module_number <= 10 ? (
      length(module.intermediate) > 0 ? try(module.intermediate[0].sql_connection_string, null) : null
    ) : (
      var.module_number <= 15 ? (
        length(module.advanced) > 0 ? try(module.advanced[0].sql_connection_string, null) : null
      ) : null
    )
  ) : null
  sensitive = true
}

output "cosmos_db_connection_string" {
  description = "Cosmos DB connection string (if created)"
  value = var.module_number >= 17 ? (
    var.module_number <= 20 ? (
      length(module.enterprise) > 0 ? try(module.enterprise[0].cosmos_db_connection_string, null) : null
    ) : (
      var.module_number <= 25 ? (
        length(module.ai_agents) > 0 ? try(module.ai_agents[0].cosmos_db_connection_string, null) : null
      ) : (
        length(module.enterprise_mastery) > 0 ? try(module.enterprise_mastery[0].cosmos_db_connection_string, null) : null
      )
    )
  ) : null
  sensitive = true
}

# Storage Account Information
output "storage_account_name" {
  description = "Storage account name"
  value = length(module.fundamentals) > 0 ? try(module.fundamentals[0].storage_account_name, null) : null
}

output "storage_account_key" {
  description = "Storage account primary key"
  value = length(module.fundamentals) > 0 ? try(module.fundamentals[0].storage_account_key, null) : null
  sensitive = true
}

# Container Registry (for advanced modules)
output "container_registry_name" {
  description = "Container Registry name (if created)"
  value = var.module_number >= 11 ? (
    var.module_number <= 15 ? (
      length(module.advanced) > 0 ? try(module.advanced[0].container_registry_name, null) : null
    ) : (
      var.module_number <= 25 ? (
        length(module.ai_agents) > 0 ? try(module.ai_agents[0].container_registry_name, null) : null
      ) : (
        length(module.enterprise_mastery) > 0 ? try(module.enterprise_mastery[0].container_registry_name, null) : null
      )
    )
  ) : null
}

output "container_registry_login_server" {
  description = "Container Registry login server (if created)"
  value = var.module_number >= 11 ? (
    var.module_number <= 15 ? (
      length(module.advanced) > 0 ? try(module.advanced[0].container_registry_login_server, null) : null
    ) : (
      var.module_number <= 25 ? (
        length(module.ai_agents) > 0 ? try(module.ai_agents[0].container_registry_login_server, null) : null
      ) : (
        length(module.enterprise_mastery) > 0 ? try(module.enterprise_mastery[0].container_registry_login_server, null) : null
      )
    )
  ) : null
}

# Cost Information
output "estimated_monthly_cost" {
  description = "Estimated monthly cost in USD (rough estimate)"
  value = {
    environment = var.environment
    cost_estimate = var.environment == "dev" ? "$50-100" : (
      var.environment == "staging" ? "$100-200" : "$200-400"
    )
    cost_center = var.cost_center
    note = "Actual costs may vary based on usage patterns"
  }
}

# Deployment Summary
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    resource_group = azurerm_resource_group.workshop.name
    module_track = var.module_number <= 5 ? "Fundamentals" : (
      var.module_number <= 10 ? "Intermediate" : (
        var.module_number <= 15 ? "Advanced" : (
          var.module_number <= 20 ? "Enterprise" : (
            var.module_number <= 25 ? "AI Agents" : "Enterprise Mastery"
          )
        )
      )
    )
    environment = var.environment
    location    = var.location
    resources_created = [
      "Resource Group",
      "Key Vault",
      "Application Insights",
      "Log Analytics Workspace"
    ]
    next_steps = [
      "Verify resources in Azure Portal",
      "Test connectivity to created services",
      "Begin module exercises",
      "Configure CI/CD pipelines"
    ]
  }
}
