# AI Services Module - Main Configuration

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  default_tags = {
    Module      = "ai-services"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
  
  tags = merge(local.default_tags, var.tags)
}

# Azure OpenAI Service
resource "azurerm_cognitive_account" "openai" {
  name                = "${local.name_prefix}-openai"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "OpenAI"
  sku_name            = var.openai_config.sku_name

  custom_subdomain_name = "${local.name_prefix}-openai"
  
  identity {
    type = "SystemAssigned"
  }

  network_acls {
    default_action = var.enable_private_endpoints ? "Deny" : "Allow"
    ip_rules       = var.allowed_ip_addresses
  }

  tags = local.tags
}

# OpenAI Deployments
resource "azurerm_cognitive_deployment" "openai_deployments" {
  for_each = { for idx, deployment in var.openai_config.deployments : deployment.name => deployment }

  name                 = each.value.name
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = each.value.model_name
    version = each.value.version
  }

  scale {
    type     = "Standard"
    capacity = each.value.capacity
  }
}

# Azure AI Search
resource "azurerm_search_service" "search" {
  name                = "${local.name_prefix}-search"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.search_config.sku
  replica_count       = var.search_config.replica_count
  partition_count     = var.search_config.partition_count

  public_network_access_enabled = !var.enable_private_endpoints
  
  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "${local.name_prefix}-cosmos"
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = var.cosmosdb_config.offer_type
  kind                = var.cosmosdb_config.kind

  consistency_policy {
    consistency_level = var.cosmosdb_config.consistency_level
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  # Enable vector search capabilities
  capabilities {
    name = "EnableServerless"
  }

  dynamic "capabilities" {
    for_each = var.cosmosdb_config.enable_vector_search ? [1] : []
    content {
      name = "EnableNoSQLVectorSearch"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  public_network_access_enabled = !var.enable_private_endpoints

  tags = local.tags
}

# Cosmos DB Database
resource "azurerm_cosmosdb_sql_database" "database" {
  name                = "workshop-db"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmos.name
}

# Cosmos DB Container for Vector Storage
resource "azurerm_cosmosdb_sql_container" "vectors" {
  name                  = "vectors"
  resource_group_name   = var.resource_group_name
  account_name          = azurerm_cosmosdb_account.cosmos.name
  database_name         = azurerm_cosmosdb_sql_database.database.name
  partition_key_path    = "/id"
  partition_key_version = 1

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    excluded_path {
      path = "/\"_etag\"/?"
    }
  }
}

# Application Insights
resource "azurerm_application_insights" "insights" {
  name                = "${local.name_prefix}-insights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = var.application_insights_config.application_type
  retention_in_days   = var.application_insights_config.retention_in_days
  sampling_percentage = var.application_insights_config.sampling_percentage

  tags = local.tags
}

# Key Vault for storing secrets
resource "azurerm_key_vault" "vault" {
  count = var.enable_key_vault ? 1 : 0

  name                = "${replace(local.name_prefix, "-", "")}kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = var.environment == "prod"
  soft_delete_retention_days      = var.environment == "prod" ? 90 : 7

  network_acls {
    default_action = var.enable_private_endpoints ? "Deny" : "Allow"
    bypass         = "AzureServices"
    ip_rules       = var.allowed_ip_addresses
  }

  tags = local.tags
}

# Store secrets in Key Vault
resource "azurerm_key_vault_secret" "openai_key" {
  count = var.enable_key_vault ? 1 : 0

  name         = "openai-key"
  value        = azurerm_cognitive_account.openai.primary_access_key
  key_vault_id = azurerm_key_vault.vault[0].id

  depends_on = [azurerm_key_vault_access_policy.terraform]
}

resource "azurerm_key_vault_secret" "search_key" {
  count = var.enable_key_vault ? 1 : 0

  name         = "search-admin-key"
  value        = azurerm_search_service.search.primary_key
  key_vault_id = azurerm_key_vault.vault[0].id

  depends_on = [azurerm_key_vault_access_policy.terraform]
}

resource "azurerm_key_vault_secret" "cosmos_key" {
  count = var.enable_key_vault ? 1 : 0

  name         = "cosmos-key"
  value        = azurerm_cosmosdb_account.cosmos.primary_key
  key_vault_id = azurerm_key_vault.vault[0].id

  depends_on = [azurerm_key_vault_access_policy.terraform]
}

# Key Vault access policy for Terraform
resource "azurerm_key_vault_access_policy" "terraform" {
  count = var.enable_key_vault ? 1 : 0

  key_vault_id = azurerm_key_vault.vault[0].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Purge"
  ]
}

# Data sources
data "azurerm_client_config" "current" {}
