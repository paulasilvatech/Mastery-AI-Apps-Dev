# Terraform module for Fundamentals track (Modules 1-5)
# Creates basic resources for learning GitHub Copilot fundamentals

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

# Storage Account for exercises
resource "azurerm_storage_account" "fundamentals" {
  name                     = "st${var.module_number}${var.environment}${substr(var.suffix, 0, 6)}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  min_tls_version                = "TLS1_2"
  enable_https_traffic_only      = true
  allow_nested_items_to_be_public = false
  
  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["DELETE", "GET", "HEAD", "MERGE", "POST", "OPTIONS", "PUT"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
  }
  
  tags = var.tags
}

# Storage Container for workshop files
resource "azurerm_storage_container" "workshop_files" {
  name                  = "workshop-files"
  storage_account_name  = azurerm_storage_account.fundamentals.name
  container_access_type = "private"
}

# Storage Container for code samples
resource "azurerm_storage_container" "code_samples" {
  name                  = "code-samples"
  storage_account_name  = azurerm_storage_account.fundamentals.name
  container_access_type = "private"
}

# App Service Plan (for modules 3+)
resource "azurerm_service_plan" "fundamentals" {
  count               = var.module_number >= 3 ? 1 : 0
  name                = "asp-module${var.module_number}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name           = var.environment == "prod" ? "P1v3" : "B1"
  
  tags = var.tags
}

# Web App (for modules 3+)
resource "azurerm_linux_web_app" "fundamentals" {
  count               = var.module_number >= 3 ? 1 : 0
  name                = "app-module${var.module_number}-${var.environment}-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.fundamentals[0].id

  site_config {
    always_on = var.environment != "dev"
    
    application_stack {
      python_version = "3.11"
    }
    
    app_command_line = "python app.py"
  }

  app_settings = {
    "STORAGE_ACCOUNT_NAME"       = azurerm_storage_account.fundamentals.name
    "STORAGE_ACCOUNT_KEY"        = azurerm_storage_account.fundamentals.primary_access_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.app_insights_connection_string
    "ENVIRONMENT"                = var.environment
    "MODULE_NUMBER"              = var.module_number
    "COPILOT_ENABLED"           = "true"
  }

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true
    
    application_logs {
      file_system_level = "Information"
    }
    
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }

  tags = var.tags
}

# Static Web App (for modern web exercises)
resource "azurerm_static_site" "fundamentals" {
  count               = var.module_number >= 4 ? 1 : 0
  name                = "swa-module${var.module_number}-${var.environment}-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = "East US 2" # Static Web Apps have limited regions
  sku_tier           = "Free"
  sku_size           = "Free"
  
  tags = var.tags
}

# File Share for collaborative exercises
resource "azurerm_storage_share" "fundamentals" {
  name                 = "workshop-share"
  storage_account_name = azurerm_storage_account.fundamentals.name
  quota                = 50
}

# Function App (for serverless exercises in module 5)
resource "azurerm_linux_function_app" "fundamentals" {
  count               = var.module_number >= 5 ? 1 : 0
  name                = "func-module${var.module_number}-${var.environment}-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.fundamentals[0].id
  storage_account_name       = azurerm_storage_account.fundamentals.name
  storage_account_access_key = azurerm_storage_account.fundamentals.primary_access_key

  site_config {
    application_stack {
      python_version = "3.11"
    }
    
    cors {
      allowed_origins = ["*"]
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"              = "python"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.app_insights_connection_string
    "STORAGE_ACCOUNT_NAME"                  = azurerm_storage_account.fundamentals.name
    "STORAGE_ACCOUNT_KEY"                   = azurerm_storage_account.fundamentals.primary_access_key
    "ENVIRONMENT"                           = var.environment
    "MODULE_NUMBER"                         = var.module_number
  }

  tags = var.tags
}

# Cosmos DB Account (for data exercises in fundamentals)
resource "azurerm_cosmosdb_account" "fundamentals" {
  count               = var.module_number >= 4 ? 1 : 0
  name                = "cosmos-module${var.module_number}-${var.environment}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableServerless"
  }

  tags = var.tags
}

# Cosmos DB Database
resource "azurerm_cosmosdb_sql_database" "fundamentals" {
  count               = var.module_number >= 4 ? 1 : 0
  name                = "workshop-db"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.fundamentals[0].name
}

# Cosmos DB Container
resource "azurerm_cosmosdb_sql_container" "fundamentals" {
  count               = var.module_number >= 4 ? 1 : 0
  name                = "workshop-container"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.fundamentals[0].name
  database_name       = azurerm_cosmosdb_sql_database.fundamentals[0].name
  partition_key_path  = "/id"
}

# Logic App for workflow exercises
resource "azurerm_logic_app_workflow" "fundamentals" {
  count               = var.module_number >= 5 ? 1 : 0
  name                = "logic-module${var.module_number}-${var.environment}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Communication Service for notifications
resource "azurerm_communication_service" "fundamentals" {
  count               = var.module_number >= 5 ? 1 : 0
  name                = "comm-module${var.module_number}-${var.environment}-${var.suffix}"
  resource_group_name = var.resource_group_name
  data_location       = "United States"

  tags = var.tags
}

# Role assignments for managed identity
resource "azurerm_role_assignment" "storage_contributor" {
  count                = var.module_number >= 3 ? 1 : 0
  scope                = azurerm_storage_account.fundamentals.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_web_app.fundamentals[0].identity[0].principal_id
}
