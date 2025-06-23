# main.tf - Main Terraform configuration for multi-environment deployment

terraform {
  required_version = ">= 1.6.0"
  
  backend "azurerm" {
    # Backend configuration provided via -backend-config flags
  }
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = var.environment == "prod" ? true : false
    }
    key_vault {
      purge_soft_delete_on_destroy    = var.environment == "prod" ? false : true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = local.tags
}

# Key Vault for secrets
resource "azurerm_key_vault" "main" {
  name                        = "kv-${var.project_name}-${var.environment}-${random_string.suffix.result}"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = var.environment == "prod" ? 90 : 7
  purge_protection_enabled    = var.environment == "prod" ? true : false
  sku_name                    = "standard"
  tags                        = local.tags

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = var.allowed_ips
  }
}

# Random suffix for unique naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Data source for current Azure config
data "azurerm_client_config" "current" {}

# Network Module
module "network" {
  source = "./modules/network"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  vnet_address_space  = var.vnet_address_space
  tags                = local.tags
}

# Web App Module
module "webapp" {
  source = "./modules/webapp"
  
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  environment                = var.environment
  app_name                   = var.project_name
  app_service_plan_sku       = var.app_service_plan_sku
  subnet_id                  = module.network.subnet_web_id
  key_vault_id               = azurerm_key_vault.main.id
  database_connection_string = module.database.connection_string
  enable_staging_slot        = var.environment == "prod" ? true : false
  enable_autoscale           = var.environment == "prod" ? true : false
  tags                       = local.tags
}

# Database Module
module "database" {
  source = "./modules/database"
  
  resource_group_name     = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  environment             = var.environment
  server_name             = "${var.project_name}-${var.environment}"
  database_name           = var.project_name
  subnet_id               = module.network.subnet_data_id
  key_vault_id            = azurerm_key_vault.main.id
  sku_name                = var.database_sku
  enable_geo_replication  = var.environment == "prod" ? true : false
  backup_retention_days   = var.environment == "prod" ? 35 : 7
  tags                    = local.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "ai-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  tags                = local.tags
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.environment == "prod" ? 90 : 30
  tags                = local.tags
}

# Connect App Insights to Log Analytics
resource "azurerm_application_insights_workbook" "main" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "workbook-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  display_name        = "${var.project_name} Dashboard - ${var.environment}"
  
  data_json = jsonencode({
    version = "Notebook/1.0"
    items = [{
      type = 1
      content = {
        json = "# ${var.project_name} Application Dashboard\n\nEnvironment: ${var.environment}"
      }
    }]
  })
  
  tags = local.tags
}

# Diagnostic settings for resources
resource "azurerm_monitor_diagnostic_setting" "webapp" {
  name                       = "diag-${var.project_name}-webapp-${var.environment}"
  target_resource_id         = module.webapp.app_service_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  metric {
    category = "AllMetrics"
  }
} 