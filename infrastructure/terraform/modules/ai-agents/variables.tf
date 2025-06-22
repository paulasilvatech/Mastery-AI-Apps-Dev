# Variables for AI Agents Module (Modules 21-25)

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "module_number" {
  description = "Workshop module number (21-25)"
  type        = number
  
  validation {
    condition     = var.module_number >= 21 && var.module_number <= 25
    error_message = "Module number must be between 21 and 25 for AI agents track."
  }
}

variable "suffix" {
  description = "Suffix for resource names"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
}

variable "application_insights_id" {
  description = "Application Insights ID"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault ID"
  type        = string
}

# OpenAI Configuration
variable "openai_sku" {
  description = "SKU for Azure OpenAI Service"
  type        = string
  default     = "S0"
  
  validation {
    condition     = contains(["S0"], var.openai_sku)
    error_message = "OpenAI SKU must be S0."
  }
}

variable "openai_models" {
  description = "OpenAI models to deploy"
  type = list(object({
    name    = string
    version = string
    capacity = number
  }))
  default = [
    {
      name     = "gpt-4"
      version  = "turbo-2024-04-09"
      capacity = 10
    },
    {
      name     = "gpt-35-turbo"
      version  = "0613"
      capacity = 30
    },
    {
      name     = "text-embedding-ada-002"
      version  = "2"
      capacity = 30
    }
  ]
}

# AI Search Configuration
variable "ai_search_sku" {
  description = "SKU for AI Search Service"
  type        = string
  default     = "basic"
  
  validation {
    condition = contains([
      "free", "basic", "standard", "standard2", "standard3",
      "storage_optimized_l1", "storage_optimized_l2"
    ], var.ai_search_sku)
    error_message = "AI Search SKU must be valid."
  }
}

variable "ai_search_replica_count" {
  description = "Number of replicas for AI Search"
  type        = number
  default     = 1
  
  validation {
    condition     = var.ai_search_replica_count >= 1 && var.ai_search_replica_count <= 12
    error_message = "Replica count must be between 1 and 12."
  }
}

variable "ai_search_partition_count" {
  description = "Number of partitions for AI Search"
  type        = number
  default     = 1
  
  validation {
    condition     = contains([1, 2, 3, 4, 6, 12], var.ai_search_partition_count)
    error_message = "Partition count must be 1, 2, 3, 4, 6, or 12."
  }
}

# Container Registry Configuration
variable "container_registry_sku" {
  description = "SKU for Container Registry"
  type        = string
  default     = "Basic"
  
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.container_registry_sku)
    error_message = "Container Registry SKU must be Basic, Standard, or Premium."
  }
}

variable "container_registry_admin_enabled" {
  description = "Enable admin user for Container Registry"
  type        = bool
  default     = true
}

# Service Bus Configuration
variable "service_bus_sku" {
  description = "SKU for Service Bus"
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.service_bus_sku)
    error_message = "Service Bus SKU must be Basic, Standard, or Premium."
  }
}

variable "service_bus_capacity" {
  description = "Capacity for Service Bus Premium SKU"
  type        = number
  default     = 1
  
  validation {
    condition     = var.service_bus_capacity >= 1 && var.service_bus_capacity <= 16
    error_message = "Service Bus capacity must be between 1 and 16."
  }
}

# Cosmos DB Configuration
variable "cosmos_db_consistency_level" {
  description = "Cosmos DB consistency level"
  type        = string
  default     = "Session"
  
  validation {
    condition = contains([
      "Eventual", "Session", "BoundedStaleness", "Strong", "ConsistentPrefix"
    ], var.cosmos_db_consistency_level)
    error_message = "Cosmos DB consistency level must be valid."
  }
}

variable "cosmos_db_enable_serverless" {
  description = "Enable serverless mode for Cosmos DB"
  type        = bool
  default     = true
}

variable "cosmos_db_enable_vector_search" {
  description = "Enable vector search for Cosmos DB"
  type        = bool
  default     = true
}

# Redis Cache Configuration
variable "redis_cache_sku" {
  description = "SKU for Redis Cache"
  type        = string
  default     = "Basic"
  
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.redis_cache_sku)
    error_message = "Redis Cache SKU must be Basic, Standard, or Premium."
  }
}

variable "redis_cache_capacity" {
  description = "Capacity for Redis Cache"
  type        = number
  default     = 0
  
  validation {
    condition     = var.redis_cache_capacity >= 0 && var.redis_cache_capacity <= 6
    error_message = "Redis Cache capacity must be between 0 and 6."
  }
}

# Function App Configuration
variable "function_app_plan_sku" {
  description = "SKU for Function App Service Plan"
  type        = string
  default     = "Y1"
  
  validation {
    condition     = contains(["Y1", "EP1", "EP2", "EP3"], var.function_app_plan_sku)
    error_message = "Function App plan SKU must be Y1, EP1, EP2, or EP3."
  }
}

variable "function_app_runtime" {
  description = "Runtime for Function App"
  type        = string
  default     = "python"
  
  validation {
    condition     = contains(["python", "node", "dotnet"], var.function_app_runtime)
    error_message = "Function App runtime must be python, node, or dotnet."
  }
}

variable "function_app_runtime_version" {
  description = "Runtime version for Function App"
  type        = string
  default     = "3.11"
}

# API Management Configuration
variable "api_management_sku" {
  description = "SKU for API Management"
  type        = string
  default     = "Developer"
  
  validation {
    condition = contains([
      "Developer", "Basic", "Standard", "Premium", "Consumption"
    ], var.api_management_sku)
    error_message = "API Management SKU must be valid."
  }
}

variable "api_management_capacity" {
  description = "Capacity for API Management"
  type        = number
  default     = 1
}

# Machine Learning Configuration
variable "enable_machine_learning" {
  description = "Enable Azure Machine Learning workspace"
  type        = bool
  default     = false
}

variable "machine_learning_sku" {
  description = "SKU for Machine Learning compute"
  type        = string
  default     = "Basic"
}

# Feature flags for each module
variable "module_features" {
  description = "Feature flags for specific modules"
  type = object({
    module_21_intro_agents     = bool
    module_22_custom_agents    = bool
    module_23_mcp_protocol     = bool
    module_24_multi_agent      = bool
    module_25_advanced_patterns = bool
  })
  default = {
    module_21_intro_agents     = true
    module_22_custom_agents    = true
    module_23_mcp_protocol     = true
    module_24_multi_agent      = true
    module_25_advanced_patterns = true
  }
}

# Security Configuration
variable "enable_private_endpoints" {
  description = "Enable private endpoints for services"
  type        = bool
  default     = false
}

variable "allowed_ip_ranges" {
  description = "Allowed IP ranges for security rules"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_managed_identity" {
  description = "Enable managed identity for services"
  type        = bool
  default     = true
}

# Networking Configuration
variable "virtual_network_id" {
  description = "Virtual network ID for private endpoints"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Subnet ID for private endpoints"
  type        = string
  default     = ""
}

# Cost Optimization
variable "enable_auto_shutdown" {
  description = "Enable auto-shutdown for dev resources"
  type        = bool
  default     = true
}

variable "auto_shutdown_time" {
  description = "Time for auto-shutdown (24-hour format)"
  type        = string
  default     = "19:00"
}

variable "auto_shutdown_timezone" {
  description = "Timezone for auto-shutdown"
  type        = string
  default     = "UTC"
}

# Monitoring Configuration
variable "enable_diagnostic_logs" {
  description = "Enable diagnostic logs for all services"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 30
  
  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 730
    error_message = "Log retention days must be between 1 and 730."
  }
}

# Backup Configuration
variable "enable_backup" {
  description = "Enable backup for stateful services"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 30
}
