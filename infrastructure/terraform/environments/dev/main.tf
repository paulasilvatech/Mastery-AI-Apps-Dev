# Development Environment Main Configuration

# Configure Terraform settings
terraform {
  required_version = ">= 1.5.0"
}

# Local variables
locals {
  environment = "dev"
  location    = var.location
  
  common_tags = merge(var.tags, {
    Environment = local.environment
    ManagedBy   = "Terraform"
    Project     = "MasteryAIWorkshop"
  })
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${local.environment}"
  location = local.location
  tags     = local.common_tags
}

# AI Services Module
module "ai_services" {
  source = "../../modules/ai-services"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  environment        = local.environment
  project_name       = var.project_name
  
  openai_config = {
    sku_name = "S0"
    deployments = [
      {
        name       = "gpt-4"
        model_name = "gpt-4"
        version    = "0613"
        capacity   = 10
      },
      {
        name       = "text-embedding"
        model_name = "text-embedding-ada-002"
        version    = "2"
        capacity   = 10
      }
    ]
  }
  
  search_config = {
    sku             = "basic"
    replica_count   = 1
    partition_count = 1
  }
  
  cosmosdb_config = {
    offer_type           = "Standard"
    kind                 = "GlobalDocumentDB"
    consistency_level    = "Session"
    enable_serverless    = true
    enable_vector_search = true
  }
  
  tags = local.common_tags
}

# Compute Module
module "compute" {
  source = "../../modules/compute"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  environment        = local.environment
  project_name       = var.project_name
  
  app_service_plan_config = {
    sku_name = "B1"
    os_type  = "Linux"
  }
  
  function_app_config = {
    runtime_version = "4"
    runtime_stack   = "python"
    python_version  = "3.11"
  }
  
  tags = local.common_tags
}

# Storage Module
module "storage" {
  source = "../../modules/storage"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  environment        = local.environment
  project_name       = var.project_name
  
  storage_config = {
    account_tier             = "Standard"
    account_replication_type = "LRS"
    containers = [
      "data",
      "models",
      "logs"
    ]
  }
  
  tags = local.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  environment        = local.environment
  project_name       = var.project_name
  
  log_analytics_config = {
    sku               = "PerGB2018"
    retention_in_days = 30
  }
  
  application_insights_config = {
    application_type = "web"
  }
  
  tags = local.common_tags
}

# Networking Module (simplified for dev)
module "networking" {
  source = "../../modules/networking"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  environment        = local.environment
  project_name       = var.project_name
  
  vnet_config = {
    address_space = ["10.0.0.0/16"]
    subnets = {
      default = {
        address_prefixes = ["10.0.1.0/24"]
      }
      compute = {
        address_prefixes = ["10.0.2.0/24"]
      }
    }
  }
  
  enable_private_endpoints = false  # Disabled for dev to reduce costs
  
  tags = local.common_tags
}

# Auto-shutdown policy for VMs (cost optimization)
resource "azurerm_dev_test_global_vm_shutdown_schedule" "auto_shutdown" {
  for_each = var.enable_auto_shutdown ? { for vm in module.compute.virtual_machines : vm.name => vm } : {}
  
  virtual_machine_id = each.value.id
  location          = azurerm_resource_group.main.location
  enabled           = true
  
  daily_recurrence_time = "1900"  # 7 PM
  timezone              = "Eastern Standard Time"
  
  notification_settings {
    enabled = false
  }
}
