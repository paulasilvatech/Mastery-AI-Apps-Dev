# Terraform Configuration for Mastery AI Workshop
# Supports all 30 modules with flexible resource creation

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
  
  backend "azurerm" {
    # Configured via backend.tf or environment variables
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Data sources
data "azurerm_client_config" "current" {}

# Main resource group
resource "azurerm_resource_group" "workshop" {
  name     = "rg-workshop-module${var.module_number}-${var.environment}-${random_string.suffix.result}"
  location = var.location

  tags = local.common_tags
}

# Module-specific resources based on module number
module "fundamentals" {
  count  = var.module_number <= 5 ? 1 : 0
  source = "./modules/fundamentals"
  
  resource_group_name = azurerm_resource_group.workshop.name
  location           = var.location
  environment        = var.environment
  module_number      = var.module_number
  suffix            = random_string.suffix.result
  
  tags = local.common_tags
}

module "intermediate" {
  count  = var.module_number >= 6 && var.module_number <= 10 ? 1 : 0
  source = "./modules/intermediate"
  
  resource_group_name = azurerm_resource_group.workshop.name
  location           = var.location
  environment        = var.environment
  module_number      = var.module_number
  suffix            = random_string.suffix.result
  
  tags = local.common_tags
}

module "advanced" {
  count  = var.module_number >= 11 && var.module_number <= 15 ? 1 : 0
  source = "./modules/advanced"
  
  resource_group_name = azurerm_resource_group.workshop.name
  location           = var.location
  environment        = var.environment
  module_number      = var.module_number
  suffix            = random_string.suffix.result
  
  tags = local.common_tags
}

module "enterprise" {
  count  = var.module_number >= 16 && var.module_number <= 20 ? 1 : 0
  source = "./modules/enterprise"
  
  resource_group_name = azurerm_resource_group.workshop.name
  location           = var.location
  environment        = var.environment
  module_number      = var.module_number
  suffix            = random_string.suffix.result
  
  tags = local.common_tags
}

module "ai_agents" {
  count  = var.module_number >= 21 && var.module_number <= 25 ? 1 : 0
  source = "./modules/ai-agents"
  
  resource_group_name = azurerm_resource_group.workshop.name
  location           = var.location
  environment        = var.environment
  module_number      = var.module_number
  suffix            = random_string.suffix.result
  
  tags = local.common_tags
}

module "enterprise_mastery" {
  count  = var.module_number >= 26 && var.module_number <= 30 ? 1 : 0
  source = "./modules/enterprise-mastery"
  
  resource_group_name = azurerm_resource_group.workshop.name
  location           = var.location
  environment        = var.environment
  module_number      = var.module_number
  suffix            = random_string.suffix.result
  
  tags = local.common_tags
}

# Shared Key Vault for all modules
resource "azurerm_key_vault" "workshop" {
  name                = "kv-workshop-${var.environment}-${random_string.suffix.result}"
  location            = azurerm_resource_group.workshop.location
  resource_group_name = azurerm_resource_group.workshop.name
  tenant_id          = data.azurerm_client_config.current.tenant_id
  
  sku_name = "standard"
  
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  enabled_for_disk_encryption     = true
  
  enable_rbac_authorization = true
  purge_protection_enabled  = false
  
  tags = local.common_tags
}

# Application Insights for monitoring
resource "azurerm_application_insights" "workshop" {
  name                = "ai-workshop-${var.environment}-${random_string.suffix.result}"
  location            = azurerm_resource_group.workshop.location
  resource_group_name = azurerm_resource_group.workshop.name
  application_type    = "web"
  
  tags = local.common_tags
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "workshop" {
  name                = "law-workshop-${var.environment}-${random_string.suffix.result}"
  location            = azurerm_resource_group.workshop.location
  resource_group_name = azurerm_resource_group.workshop.name
  sku                = "PerGB2018"
  retention_in_days   = 30
  
  tags = local.common_tags
}

# Local values
locals {
  common_tags = {
    Environment = var.environment
    Module      = "Module ${var.module_number}"
    Workshop    = "Mastery AI Code Development"
    ManagedBy   = "Terraform"
    CostCenter  = "Training"
    Owner       = var.owner_email
  }
}
