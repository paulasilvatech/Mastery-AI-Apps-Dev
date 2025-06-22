# AI Services Module - Variables

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
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "masteryai"
}

# OpenAI Configuration
variable "openai_config" {
  description = "Azure OpenAI service configuration"
  type = object({
    sku_name = string
    deployments = list(object({
      name       = string
      model_name = string
      version    = string
      capacity   = number
    }))
  })
  default = {
    sku_name = "S0"
    deployments = [
      {
        name       = "gpt-4"
        model_name = "gpt-4"
        version    = "0613"
        capacity   = 10
      },
      {
        name       = "gpt-35-turbo"
        model_name = "gpt-35-turbo"
        version    = "0613"
        capacity   = 20
      },
      {
        name       = "text-embedding"
        model_name = "text-embedding-ada-002"
        version    = "2"
        capacity   = 10
      }
    ]
  }
}

# Azure AI Search Configuration
variable "search_config" {
  description = "Azure AI Search configuration"
  type = object({
    sku             = string
    replica_count   = number
    partition_count = number
  })
  default = {
    sku             = "standard"
    replica_count   = 1
    partition_count = 1
  }
}

# Cosmos DB Configuration
variable "cosmosdb_config" {
  description = "Cosmos DB configuration"
  type = object({
    offer_type           = string
    kind                 = string
    consistency_level    = string
    enable_vector_search = bool
  })
  default = {
    offer_type           = "Standard"
    kind                 = "GlobalDocumentDB"
    consistency_level    = "Session"
    enable_vector_search = true
  }
}

# Application Insights Configuration
variable "application_insights_config" {
  description = "Application Insights configuration"
  type = object({
    application_type    = string
    retention_in_days   = number
    sampling_percentage = number
  })
  default = {
    application_type    = "web"
    retention_in_days   = 90
    sampling_percentage = 100
  }
}

# Security Configuration
variable "enable_private_endpoints" {
  description = "Enable private endpoints for services"
  type        = bool
  default     = false
}

variable "allowed_ip_addresses" {
  description = "List of allowed IP addresses for service access"
  type        = list(string)
  default     = []
}

variable "enable_key_vault" {
  description = "Enable Key Vault for secret storage"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
