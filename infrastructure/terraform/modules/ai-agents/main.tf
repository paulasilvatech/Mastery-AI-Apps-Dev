# Terraform module for AI Agents track (Modules 21-25)
# Creates AI and agent resources for advanced AI development

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

# Data sources
data "azurerm_client_config" "current" {}

# Azure OpenAI Service
resource "azurerm_cognitive_account" "openai" {
  name                = "openai-module${var.module_number}-${var.environment}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "OpenAI"
  sku_name           = var.openai_sku

  custom_subdomain_name         = "openai-m${var.module_number}-${var.environment}-${var.suffix}"
  public_network_access_enabled = true

  tags = var.tags
}

# OpenAI Deployments
resource "azurerm_cognitive_deployment" "gpt4" {
  name                 = "gpt-4"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "gpt-4"
    version = "turbo-2024-04-09"
  }

  scale {
    type = "Standard"
  }
}

resource "azurerm_cognitive_deployment" "gpt35_turbo" {
  name                 = "gpt-35-turbo"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "gpt-35-turbo"
    version = "0613"
  }

  scale {
    type = "Standard"
  }
}

resource "azurerm_cognitive_deployment" "text_embedding" {
  name                 = "text-embedding-ada-002"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "text-embedding-ada-002"
    version = "2"
  }

  scale {
    type = "Standard"
  }
}

# Azure AI Search for vector operations
resource "azurerm_search_service" "ai_search" {
  name                = "srch-m${var.module_number}-${var.environment}-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                = var.ai_search_sku
  
  local_authentication_enabled = true
  authentication_failure_mode  = null

  tags = var.tags
}

# Container Registry for agent deployments
resource "azurerm_container_registry" "agents" {
  name                = "crm${var.module_number}${var.environment}${substr(var.suffix, 0, 6)}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                = var.container_registry_sku
  admin_enabled      = true

  tags = var.tags
}

# Container Apps Environment for agent hosting
resource "azurerm_container_app_environment" "agents" {
  count               = var.module_number >= 23 ? 1 : 0
  name                = "cae-agents-${var.environment}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id

  tags = var.tags
}

# Event Grid Topic for agent communication
resource "azurerm_eventgrid_topic" "agent_events" {
  count               = var.module_number >= 24 ? 1 : 0
  name                = "egt-agents-${var.environment}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Service Bus Namespace for agent messaging
resource "azurerm_servicebus_namespace" "agents" {
  count               = var.module_number >= 24 ? 1 : 0
  name                = "sb-agents-${var.environment}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                = var.service_bus_sku

  tags = var.tags
}

# Service Bus Queue for agent tasks
resource "azurerm_servicebus_queue" "agent_tasks" {
  count        = var.module_number >= 24 ? 1 : 0
  name         = "agent-tasks"
  namespace_id = azurerm_servicebus_namespace.agents[0].id

  enable_partitioning = true
}

# Service Bus Topic for agent notifications
resource "azurerm_servicebus_topic" "agent_notifications" {
  count        = var.module_number >= 24 ? 1 : 0
  name         = "agent-notifications"
  namespace_id = azurerm_servicebus_namespace.agents[0].id

  enable_partitioning = true
}

# Cosmos DB for agent state management
resource "azurerm_cosmosdb_account" "agents" {
  count               = var.module_number >= 22 ? 1 : 0
  name                = "cosmos-agents-${var.environment}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableServerless"
  }

  capabilities {
    name = "EnableNoSQLVectorSearch"
  }

  tags = var.tags
}

# Cosmos DB Database for agents
resource "azurerm_cosmosdb_sql_database" "agents" {
  count               = var.module_number >= 22 ? 1 : 0
  name                = "agents-db"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.agents[0].name
}

# Cosmos DB Container for agent state
resource "azurerm_cosmosdb_sql_container" "agent_state" {
  count               = var.module_number >= 22 ? 1 : 0
  name                = "agent-state"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.agents[0].name
  database_name       = azurerm_cosmosdb_sql_database.agents[0].name
  partition_key_path  = "/agentId"

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    included_path {
      path = "/included/?"
    }

    excluded_path {
      path = "/excluded/?"
    }
  }

  unique_key {
    paths = ["/agentId", "/sessionId"]
  }
}

# Cosmos DB Container for agent conversations
resource "azurerm_cosmosdb_sql_container" "agent_conversations" {
  count               = var.module_number >= 22 ? 1 : 0
  name                = "agent-conversations"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.agents[0].name
  database_name       = azurerm_cosmosdb_sql_database.agents[0].name
  partition_key_path  = "/conversationId"

  # Vector embedding policy for conversation search
  analytical_storage_ttl = 2592000 # 30 days
}

# Azure Functions for agent execution (Module 23+)
resource "azurerm_storage_account" "agent_functions" {
  count                    = var.module_number >= 23 ? 1 : 0
  name                     = "stagentfunc${substr(var.suffix, 0, 6)}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}

resource "azurerm_service_plan" "agent_functions" {
  count               = var.module_number >= 23 ? 1 : 0
  name                = "asp-agent-functions-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name           = "Y1" # Consumption plan
}

resource "azurerm_linux_function_app" "agent_orchestrator" {
  count               = var.module_number >= 23 ? 1 : 0
  name                = "func-agent-orch-${var.environment}-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  storage_account_name       = azurerm_storage_account.agent_functions[0].name
  storage_account_access_key = azurerm_storage_account.agent_functions[0].primary_access_key
  service_plan_id           = azurerm_service_plan.agent_functions[0].id

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    "OPENAI_ENDPOINT"               = azurerm_cognitive_account.openai.endpoint
    "OPENAI_API_KEY"                = azurerm_cognitive_account.openai.primary_access_key
    "AI_SEARCH_ENDPOINT"            = azurerm_search_service.ai_search.endpoint
    "AI_SEARCH_API_KEY"             = azurerm_search_service.ai_search.primary_key
    "COSMOS_ENDPOINT"               = var.module_number >= 22 ? azurerm_cosmosdb_account.agents[0].endpoint : ""
    "COSMOS_KEY"                    = var.module_number >= 22 ? azurerm_cosmosdb_account.agents[0].primary_key : ""
    "SERVICEBUS_CONNECTION_STRING"  = var.module_number >= 24 ? azurerm_servicebus_namespace.agents[0].default_primary_connection_string : ""
    "ENVIRONMENT"                   = var.environment
    "MODULE_NUMBER"                 = var.module_number
  }

  tags = var.tags
}

# Azure Machine Learning Workspace for agent training (Module 25)
resource "azurerm_machine_learning_workspace" "agents" {
  count               = var.module_number >= 25 ? 1 : 0
  name                = "mlw-agents-${var.environment}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_insights_id = var.application_insights_id
  key_vault_id           = var.key_vault_id
  storage_account_id     = azurerm_storage_account.agent_functions[0].id
  container_registry_id  = azurerm_container_registry.agents.id

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Redis Cache for agent session management
resource "azurerm_redis_cache" "agents" {
  count               = var.module_number >= 22 ? 1 : 0
  name                = "redis-agents-${var.environment}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = 0
  family              = "C"
  sku_name           = "Basic"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  redis_configuration {
  }

  tags = var.tags
}

# API Management for agent APIs
resource "azurerm_api_management" "agents" {
  count               = var.module_number >= 25 ? 1 : 0
  name                = "apim-agents-${var.environment}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = "Workshop Agents"
  publisher_email     = "admin@workshop.local"

  sku_name = var.environment == "prod" ? "Standard_1" : "Developer_1"

  tags = var.tags
}

# Role Assignments
resource "azurerm_role_assignment" "function_app_openai" {
  count                = var.module_number >= 23 ? 1 : 0
  scope                = azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_linux_function_app.agent_orchestrator[0].identity[0].principal_id
}

resource "azurerm_role_assignment" "function_app_search" {
  count                = var.module_number >= 23 ? 1 : 0
  scope                = azurerm_search_service.ai_search.id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = azurerm_linux_function_app.agent_orchestrator[0].identity[0].principal_id
}

resource "azurerm_role_assignment" "function_app_cosmos" {
  count                = var.module_number >= 23 && var.module_number >= 22 ? 1 : 0
  scope                = azurerm_cosmosdb_account.agents[0].id
  role_definition_name = "Cosmos DB Built-in Data Contributor"
  principal_id         = azurerm_linux_function_app.agent_orchestrator[0].identity[0].principal_id
}
