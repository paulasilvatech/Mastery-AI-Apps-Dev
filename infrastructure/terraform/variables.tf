# Variables for Mastery AI Workshop Terraform Configuration

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US 2"
  
  validation {
    condition = contains([
      "East US", "East US 2", "West US 2", "West US 3",
      "Central US", "North Central US", "South Central US",
      "West Central US", "Canada Central", "Canada East",
      "Brazil South", "North Europe", "West Europe",
      "France Central", "Germany West Central", "Norway East",
      "Switzerland North", "UK South", "UK West",
      "Australia East", "Australia Southeast", "Central India",
      "East Asia", "Southeast Asia", "Japan East", "Japan West",
      "Korea Central", "South Africa North"
    ], var.location)
    error_message = "Location must be a valid Azure region."
  }
}

variable "module_number" {
  description = "Workshop module number (1-30)"
  type        = number
  default     = 1
  
  validation {
    condition     = var.module_number >= 1 && var.module_number <= 30
    error_message = "Module number must be between 1 and 30."
  }
}

variable "owner_email" {
  description = "Email of the resource owner"
  type        = string
  default     = "workshop@example.com"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.owner_email))
    error_message = "Owner email must be a valid email address."
  }
}

variable "enable_monitoring" {
  description = "Enable monitoring resources (Application Insights, Log Analytics)"
  type        = bool
  default     = true
}

variable "enable_security" {
  description = "Enable security features (Key Vault, private endpoints)"
  type        = bool
  default     = true
}

variable "ai_features_enabled" {
  description = "Enable AI-specific resources (OpenAI, Cognitive Services)"
  type        = bool
  default     = false
}

variable "container_features_enabled" {
  description = "Enable container resources (AKS, Container Registry)"
  type        = bool
  default     = false
}

variable "data_features_enabled" {
  description = "Enable data resources (CosmosDB, SQL Database)"
  type        = bool
  default     = false
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "Training"
}

variable "auto_shutdown_enabled" {
  description = "Enable auto-shutdown for dev resources"
  type        = bool
  default     = true
}

variable "backup_enabled" {
  description = "Enable backup for production resources"
  type        = bool
  default     = false
}

# Conditional feature enablement based on module number
locals {
  # Fundamentals track (1-5): Basic resources
  fundamentals_features = var.module_number <= 5 ? {
    storage_enabled     = true
    web_app_enabled    = var.module_number >= 3
    key_vault_enabled  = true
    monitoring_enabled = var.enable_monitoring
  } : {}
  
  # Intermediate track (6-10): Web and API resources
  intermediate_features = var.module_number >= 6 && var.module_number <= 10 ? {
    app_service_enabled    = true
    database_enabled       = true
    redis_enabled         = var.module_number >= 8
    api_management_enabled = var.module_number >= 9
  } : {}
  
  # Advanced track (11-15): Cloud-native resources
  advanced_features = var.module_number >= 11 && var.module_number <= 15 ? {
    kubernetes_enabled     = true
    container_registry_enabled = true
    service_bus_enabled    = var.module_number >= 12
    functions_enabled      = var.module_number >= 13
  } : {}
  
  # Enterprise track (16-20): Enterprise resources
  enterprise_features = var.module_number >= 16 && var.module_number <= 20 ? {
    ai_search_enabled      = true
    cognitive_services_enabled = true
    cosmos_db_enabled      = var.module_number >= 17
    synapse_enabled        = var.module_number >= 18
    security_center_enabled = var.module_number >= 19
  } : {}
  
  # AI Agents track (21-25): AI and agent resources
  ai_agent_features = var.module_number >= 21 && var.module_number <= 25 ? {
    openai_enabled         = true
    ai_foundry_enabled     = var.module_number >= 22
    container_apps_enabled = var.module_number >= 23
    event_grid_enabled     = var.module_number >= 24
  } : {}
  
  # Enterprise Mastery track (26-30): Complete enterprise setup
  mastery_features = var.module_number >= 26 ? {
    all_features_enabled   = true
    premium_tiers_enabled  = var.environment == "prod"
    backup_enabled         = var.backup_enabled
    disaster_recovery_enabled = var.environment == "prod"
  } : {}
}

# Resource naming variables
variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "workshop"
}

variable "resource_suffix" {
  description = "Suffix for resource names (auto-generated if empty)"
  type        = string
  default     = ""
}

# Network configuration
variable "vnet_address_space" {
  description = "Virtual network address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_configs" {
  description = "Subnet configurations"
  type = map(object({
    address_prefixes = list(string)
    service_endpoints = list(string)
  }))
  default = {
    web = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Web", "Microsoft.Storage"]
    }
    data = {
      address_prefixes  = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    }
    agents = {
      address_prefixes  = ["10.0.3.0/24"]
      service_endpoints = ["Microsoft.CognitiveServices", "Microsoft.EventGrid"]
    }
    kubernetes = {
      address_prefixes  = ["10.0.4.0/23"]
      service_endpoints = ["Microsoft.ContainerRegistry"]
    }
  }
}

# SKU configurations by environment
variable "sku_configs" {
  description = "SKU configurations by environment"
  type = map(object({
    app_service_plan_sku = string
    sql_database_sku     = string
    storage_account_sku  = string
    cosmos_db_throughput = number
  }))
  default = {
    dev = {
      app_service_plan_sku = "B1"
      sql_database_sku     = "Basic"
      storage_account_sku  = "Standard_LRS"
      cosmos_db_throughput = 400
    }
    staging = {
      app_service_plan_sku = "S1"
      sql_database_sku     = "S0"
      storage_account_sku  = "Standard_GRS"
      cosmos_db_throughput = 800
    }
    prod = {
      app_service_plan_sku = "P1v3"
      sql_database_sku     = "S2"
      storage_account_sku  = "Premium_LRS"
      cosmos_db_throughput = 1000
    }
  }
}

# Security configurations
variable "allowed_ip_ranges" {
  description = "Allowed IP ranges for security rules"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict in production
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints for PaaS services"
  type        = bool
  default     = false # Enable for production
}

# Feature flags for each track
variable "feature_flags" {
  description = "Feature flags for workshop tracks"
  type = object({
    enable_copilot_features     = bool
    enable_github_integration   = bool
    enable_advanced_monitoring  = bool
    enable_cost_optimization   = bool
  })
  default = {
    enable_copilot_features     = true
    enable_github_integration   = true
    enable_advanced_monitoring  = true
    enable_cost_optimization   = true
  }
}
