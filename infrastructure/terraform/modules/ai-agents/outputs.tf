# Outputs for AI Agents Module (Modules 21-25)

# Azure OpenAI Outputs
output "openai_service_id" {
  description = "ID of the Azure OpenAI service"
  value       = azurerm_cognitive_account.openai.id
}

output "openai_service_name" {
  description = "Name of the Azure OpenAI service"
  value       = azurerm_cognitive_account.openai.name
}

output "openai_endpoint" {
  description = "Endpoint URL of the Azure OpenAI service"
  value       = azurerm_cognitive_account.openai.endpoint
  sensitive   = true
}

output "openai_api_key" {
  description = "Primary API key for Azure OpenAI service"
  value       = azurerm_cognitive_account.openai.primary_access_key
  sensitive   = true
}

output "openai_deployments" {
  description = "Deployed OpenAI models"
  value = {
    gpt4 = {
      name = azurerm_cognitive_deployment.gpt4.name
      model = azurerm_cognitive_deployment.gpt4.model[0].name
      version = azurerm_cognitive_deployment.gpt4.model[0].version
    }
    gpt35_turbo = {
      name = azurerm_cognitive_deployment.gpt35_turbo.name
      model = azurerm_cognitive_deployment.gpt35_turbo.model[0].name
      version = azurerm_cognitive_deployment.gpt35_turbo.model[0].version
    }
    text_embedding = {
      name = azurerm_cognitive_deployment.text_embedding.name
      model = azurerm_cognitive_deployment.text_embedding.model[0].name
      version = azurerm_cognitive_deployment.text_embedding.model[0].version
    }
  }
}

# AI Search Outputs
output "ai_search_service_id" {
  description = "ID of the AI Search service"
  value       = azurerm_search_service.ai_search.id
}

output "ai_search_service_name" {
  description = "Name of the AI Search service"
  value       = azurerm_search_service.ai_search.name
}

output "ai_search_endpoint" {
  description = "Endpoint URL of the AI Search service"
  value       = "https://${azurerm_search_service.ai_search.name}.search.windows.net"
}

output "ai_search_primary_key" {
  description = "Primary admin key for AI Search service"
  value       = azurerm_search_service.ai_search.primary_key
  sensitive   = true
}

output "ai_search_query_keys" {
  description = "Query keys for AI Search service"
  value       = azurerm_search_service.ai_search.query_keys
  sensitive   = true
}

# Container Registry Outputs
output "container_registry_id" {
  description = "ID of the Container Registry"
  value       = azurerm_container_registry.agents.id
}

output "container_registry_name" {
  description = "Name of the Container Registry"
  value       = azurerm_container_registry.agents.name
}

output "container_registry_login_server" {
  description = "Login server URL of the Container Registry"
  value       = azurerm_container_registry.agents.login_server
}

output "container_registry_admin_username" {
  description = "Admin username for Container Registry"
  value       = azurerm_container_registry.agents.admin_username
  sensitive   = true
}

output "container_registry_admin_password" {
  description = "Admin password for Container Registry"
  value       = azurerm_container_registry.agents.admin_password
  sensitive   = true
}

# Container Apps Environment Outputs (Module 23+)
output "container_apps_environment_id" {
  description = "ID of the Container Apps Environment"
  value       = var.module_number >= 23 ? azurerm_container_app_environment.agents[0].id : null
}

output "container_apps_environment_name" {
  description = "Name of the Container Apps Environment"
  value       = var.module_number >= 23 ? azurerm_container_app_environment.agents[0].name : null
}

output "container_apps_environment_domain" {
  description = "Default domain of the Container Apps Environment"
  value       = var.module_number >= 23 ? azurerm_container_app_environment.agents[0].default_domain : null
}

# Event Grid Outputs (Module 24+)
output "event_grid_topic_id" {
  description = "ID of the Event Grid Topic"
  value       = var.module_number >= 24 ? azurerm_eventgrid_topic.agent_events[0].id : null
}

output "event_grid_topic_endpoint" {
  description = "Endpoint of the Event Grid Topic"
  value       = var.module_number >= 24 ? azurerm_eventgrid_topic.agent_events[0].endpoint : null
  sensitive   = true
}

output "event_grid_topic_access_key" {
  description = "Access key for the Event Grid Topic"
  value       = var.module_number >= 24 ? azurerm_eventgrid_topic.agent_events[0].primary_access_key : null
  sensitive   = true
}

# Service Bus Outputs (Module 24+)
output "service_bus_namespace_id" {
  description = "ID of the Service Bus Namespace"
  value       = var.module_number >= 24 ? azurerm_servicebus_namespace.agents[0].id : null
}

output "service_bus_namespace_name" {
  description = "Name of the Service Bus Namespace"
  value       = var.module_number >= 24 ? azurerm_servicebus_namespace.agents[0].name : null
}

output "service_bus_connection_string" {
  description = "Connection string for the Service Bus Namespace"
  value       = var.module_number >= 24 ? azurerm_servicebus_namespace.agents[0].default_primary_connection_string : null
  sensitive   = true
}

output "service_bus_queue_name" {
  description = "Name of the Service Bus Queue"
  value       = var.module_number >= 24 ? azurerm_servicebus_queue.agent_tasks[0].name : null
}

output "service_bus_topic_name" {
  description = "Name of the Service Bus Topic"
  value       = var.module_number >= 24 ? azurerm_servicebus_topic.agent_notifications[0].name : null
}

# Cosmos DB Outputs (Module 22+)
output "cosmos_db_account_id" {
  description = "ID of the Cosmos DB Account"
  value       = var.module_number >= 22 ? azurerm_cosmosdb_account.agents[0].id : null
}

output "cosmos_db_account_name" {
  description = "Name of the Cosmos DB Account"
  value       = var.module_number >= 22 ? azurerm_cosmosdb_account.agents[0].name : null
}

output "cosmos_db_endpoint" {
  description = "Endpoint URL of the Cosmos DB Account"
  value       = var.module_number >= 22 ? azurerm_cosmosdb_account.agents[0].endpoint : null
}

output "cosmos_db_primary_key" {
  description = "Primary key of the Cosmos DB Account"
  value       = var.module_number >= 22 ? azurerm_cosmosdb_account.agents[0].primary_key : null
  sensitive   = true
}

output "cosmos_db_connection_strings" {
  description = "Connection strings for the Cosmos DB Account"
  value       = var.module_number >= 22 ? azurerm_cosmosdb_account.agents[0].connection_strings : null
  sensitive   = true
}

output "cosmos_db_database_name" {
  description = "Name of the Cosmos DB Database"
  value       = var.module_number >= 22 ? azurerm_cosmosdb_sql_database.agents[0].name : null
}

output "cosmos_db_containers" {
  description = "Names of Cosmos DB Containers"
  value = var.module_number >= 22 ? {
    agent_state = azurerm_cosmosdb_sql_container.agent_state[0].name
    agent_conversations = azurerm_cosmosdb_sql_container.agent_conversations[0].name
  } : null
}

# Function App Outputs (Module 23+)
output "function_app_id" {
  description = "ID of the Function App"
  value       = var.module_number >= 23 ? azurerm_linux_function_app.agent_orchestrator[0].id : null
}

output "function_app_name" {
  description = "Name of the Function App"
  value       = var.module_number >= 23 ? azurerm_linux_function_app.agent_orchestrator[0].name : null
}

output "function_app_url" {
  description = "URL of the Function App"
  value       = var.module_number >= 23 ? "https://${azurerm_linux_function_app.agent_orchestrator[0].default_hostname}" : null
}

output "function_app_identity_principal_id" {
  description = "Principal ID of the Function App's managed identity"
  value       = var.module_number >= 23 ? azurerm_linux_function_app.agent_orchestrator[0].identity[0].principal_id : null
}

# Machine Learning Outputs (Module 25)
output "machine_learning_workspace_id" {
  description = "ID of the Machine Learning Workspace"
  value       = var.module_number >= 25 ? azurerm_machine_learning_workspace.agents[0].id : null
}

output "machine_learning_workspace_name" {
  description = "Name of the Machine Learning Workspace"
  value       = var.module_number >= 25 ? azurerm_machine_learning_workspace.agents[0].name : null
}

# Redis Cache Outputs (Module 22+)
output "redis_cache_id" {
  description = "ID of the Redis Cache"
  value       = var.module_number >= 22 ? azurerm_redis_cache.agents[0].id : null
}

output "redis_cache_name" {
  description = "Name of the Redis Cache"
  value       = var.module_number >= 22 ? azurerm_redis_cache.agents[0].name : null
}

output "redis_cache_hostname" {
  description = "Hostname of the Redis Cache"
  value       = var.module_number >= 22 ? azurerm_redis_cache.agents[0].hostname : null
}

output "redis_cache_ssl_port" {
  description = "SSL port of the Redis Cache"
  value       = var.module_number >= 22 ? azurerm_redis_cache.agents[0].ssl_port : null
}

output "redis_cache_primary_access_key" {
  description = "Primary access key for Redis Cache"
  value       = var.module_number >= 22 ? azurerm_redis_cache.agents[0].primary_access_key : null
  sensitive   = true
}

# API Management Outputs (Module 25)
output "api_management_id" {
  description = "ID of the API Management service"
  value       = var.module_number >= 25 ? azurerm_api_management.agents[0].id : null
}

output "api_management_name" {
  description = "Name of the API Management service"
  value       = var.module_number >= 25 ? azurerm_api_management.agents[0].name : null
}

output "api_management_gateway_url" {
  description = "Gateway URL of the API Management service"
  value       = var.module_number >= 25 ? azurerm_api_management.agents[0].gateway_url : null
}

output "api_management_portal_url" {
  description = "Developer portal URL of the API Management service"
  value       = var.module_number >= 25 ? azurerm_api_management.agents[0].portal_url : null
}

# Storage Account Outputs (Module 23+)
output "storage_account_name" {
  description = "Name of the storage account for Function Apps"
  value       = var.module_number >= 23 ? azurerm_storage_account.agent_functions[0].name : null
}

output "storage_account_connection_string" {
  description = "Connection string for the storage account"
  value       = var.module_number >= 23 ? azurerm_storage_account.agent_functions[0].primary_connection_string : null
  sensitive   = true
}

# Connection Information for Applications
output "app_connection_info" {
  description = "Connection information for agent applications"
  value = {
    openai = {
      endpoint = azurerm_cognitive_account.openai.endpoint
      deployments = {
        gpt4 = azurerm_cognitive_deployment.gpt4.name
        gpt35_turbo = azurerm_cognitive_deployment.gpt35_turbo.name
        embedding = azurerm_cognitive_deployment.text_embedding.name
      }
    }
    ai_search = {
      endpoint = "https://${azurerm_search_service.ai_search.name}.search.windows.net"
      service_name = azurerm_search_service.ai_search.name
    }
    container_registry = {
      login_server = azurerm_container_registry.agents.login_server
      name = azurerm_container_registry.agents.name
    }
    cosmos_db = var.module_number >= 22 ? {
      endpoint = azurerm_cosmosdb_account.agents[0].endpoint
      database = azurerm_cosmosdb_sql_database.agents[0].name
      containers = {
        state = azurerm_cosmosdb_sql_container.agent_state[0].name
        conversations = azurerm_cosmosdb_sql_container.agent_conversations[0].name
      }
    } : null
    redis = var.module_number >= 22 ? {
      hostname = azurerm_redis_cache.agents[0].hostname
      ssl_port = azurerm_redis_cache.agents[0].ssl_port
    } : null
    service_bus = var.module_number >= 24 ? {
      namespace = azurerm_servicebus_namespace.agents[0].name
      queue = azurerm_servicebus_queue.agent_tasks[0].name
      topic = azurerm_servicebus_topic.agent_notifications[0].name
    } : null
    event_grid = var.module_number >= 24 ? {
      topic_endpoint = azurerm_eventgrid_topic.agent_events[0].endpoint
    } : null
  }
  sensitive = true
}

# Module Resources Summary
output "module_resources_summary" {
  description = "Summary of created resources for this module"
  value = {
    module_number = var.module_number
    environment   = var.environment
    track         = "AI Agents"
    core_services = {
      openai = azurerm_cognitive_account.openai.name
      ai_search = azurerm_search_service.ai_search.name
      container_registry = azurerm_container_registry.agents.name
    }
    data_services = var.module_number >= 22 ? {
      cosmos_db = azurerm_cosmosdb_account.agents[0].name
      redis_cache = azurerm_redis_cache.agents[0].name
    } : null
    compute_services = var.module_number >= 23 ? {
      container_apps_environment = azurerm_container_app_environment.agents[0].name
      function_app = azurerm_linux_function_app.agent_orchestrator[0].name
    } : null
    messaging_services = var.module_number >= 24 ? {
      service_bus = azurerm_servicebus_namespace.agents[0].name
      event_grid = azurerm_eventgrid_topic.agent_events[0].name
    } : null
    ml_services = var.module_number >= 25 ? {
      ml_workspace = azurerm_machine_learning_workspace.agents[0].name
      api_management = azurerm_api_management.agents[0].name
    } : null
  }
}

# Quick Access URLs
output "quick_access_urls" {
  description = "Quick access URLs for workshop resources"
  value = {
    function_app = var.module_number >= 23 ? "https://${azurerm_linux_function_app.agent_orchestrator[0].default_hostname}" : null
    api_management = var.module_number >= 25 ? azurerm_api_management.agents[0].gateway_url : null
    developer_portal = var.module_number >= 25 ? azurerm_api_management.agents[0].portal_url : null
    container_registry = "https://${azurerm_container_registry.agents.login_server}"
    azure_portal_openai = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${azurerm_cognitive_account.openai.id}"
    azure_portal_search = "https://portal.azure.com/#@${data.azurerm_client_config.current.tenant_id}/resource${azurerm_search_service.ai_search.id}"
  }
}

# Deployment Status
output "deployment_status" {
  description = "Status of deployed components by module"
  value = {
    module_21_complete = true
    module_22_complete = var.module_number >= 22
    module_23_complete = var.module_number >= 23
    module_24_complete = var.module_number >= 24
    module_25_complete = var.module_number >= 25
    all_features_deployed = var.module_number >= 25
  }
}
