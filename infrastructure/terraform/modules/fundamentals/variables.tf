# Variables for Fundamentals Module (Modules 1-5)

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
  description = "Workshop module number (1-5)"
  type        = number
  
  validation {
    condition     = var.module_number >= 1 && var.module_number <= 5
    error_message = "Module number must be between 1 and 5 for fundamentals track."
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

variable "app_insights_connection_string" {
  description = "Application Insights connection string"
  type        = string
  default     = ""
}

variable "enable_static_web_app" {
  description = "Enable Static Web App for modern web exercises"
  type        = bool
  default     = true
}

variable "enable_function_app" {
  description = "Enable Function App for serverless exercises"
  type        = bool
  default     = true
}

variable "enable_cosmos_db" {
  description = "Enable Cosmos DB for data exercises"
  type        = bool
  default     = true
}

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "Storage account tier must be Standard or Premium."
  }
}

variable "storage_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
  
  validation {
    condition = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_replication_type)
    error_message = "Storage replication type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "app_service_sku" {
  description = "App Service plan SKU"
  type        = string
  default     = "B1"
  
  validation {
    condition = contains([
      "F1", "D1", "B1", "B2", "B3", 
      "S1", "S2", "S3", 
      "P1v2", "P2v2", "P3v2", 
      "P1v3", "P2v3", "P3v3"
    ], var.app_service_sku)
    error_message = "App Service SKU must be a valid Azure App Service plan SKU."
  }
}

variable "enable_cors" {
  description = "Enable CORS for web applications"
  type        = bool
  default     = true
}

variable "cors_allowed_origins" {
  description = "Allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}

variable "python_version" {
  description = "Python version for web apps"
  type        = string
  default     = "3.11"
  
  validation {
    condition     = contains(["3.8", "3.9", "3.10", "3.11"], var.python_version)
    error_message = "Python version must be one of: 3.8, 3.9, 3.10, 3.11."
  }
}

variable "enable_https_only" {
  description = "Enable HTTPS only for web apps"
  type        = bool
  default     = true
}

variable "enable_detailed_logging" {
  description = "Enable detailed logging for web apps"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 7
  
  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 90
    error_message = "Log retention days must be between 1 and 90."
  }
}

variable "cosmos_consistency_level" {
  description = "Cosmos DB consistency level"
  type        = string
  default     = "BoundedStaleness"
  
  validation {
    condition = contains([
      "Eventual", "Session", "BoundedStaleness", "Strong", "ConsistentPrefix"
    ], var.cosmos_consistency_level)
    error_message = "Cosmos DB consistency level must be valid."
  }
}

variable "enable_serverless_cosmos" {
  description = "Enable serverless mode for Cosmos DB"
  type        = bool
  default     = true
}

variable "file_share_quota" {
  description = "File share quota in GB"
  type        = number
  default     = 50
  
  validation {
    condition     = var.file_share_quota >= 1 && var.file_share_quota <= 102400
    error_message = "File share quota must be between 1 and 102400 GB."
  }
}

variable "communication_service_data_location" {
  description = "Data location for Communication Service"
  type        = string
  default     = "United States"
  
  validation {
    condition = contains([
      "United States", "Europe", "Australia", "United Kingdom"
    ], var.communication_service_data_location)
    error_message = "Communication Service data location must be valid."
  }
}

# Feature flags for specific modules
variable "module_features" {
  description = "Feature flags for specific modules"
  type = object({
    module_1_basics        = bool
    module_2_suggestions   = bool
    module_3_web_apps     = bool
    module_4_data_apps    = bool
    module_5_serverless   = bool
  })
  default = {
    module_1_basics        = true
    module_2_suggestions   = true
    module_3_web_apps     = true
    module_4_data_apps    = true
    module_5_serverless   = true
  }
}

# Auto-shutdown configuration for dev environment
variable "auto_shutdown_config" {
  description = "Auto-shutdown configuration for dev resources"
  type = object({
    enabled = bool
    time    = string
    timezone = string
  })
  default = {
    enabled  = true
    time     = "19:00"
    timezone = "UTC"
  }
}
