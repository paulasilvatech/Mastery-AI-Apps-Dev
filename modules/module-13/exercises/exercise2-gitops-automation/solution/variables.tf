# variables.tf - Variable definitions for multi-environment deployment

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "gitops-demo"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US 2"
}

variable "vnet_address_space" {
  description = "Address space for virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "allowed_ips" {
  description = "IP addresses allowed to access Key Vault"
  type        = list(string)
  default     = []
}

variable "app_service_plan_sku" {
  description = "SKU for App Service Plan"
  type = object({
    tier = string
    size = string
  })
  default = {
    tier = "Basic"
    size = "B1"
  }
}

variable "database_sku" {
  description = "SKU for Azure SQL Database"
  type        = string
  default     = "Basic"
}

variable "admin_username" {
  description = "Administrator username for SQL Server"
  type        = string
  default     = "sqladmin"
  sensitive   = true
}

locals {
  tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Module      = "13"
      Exercise    = "2"
      CreatedBy   = "GitOps"
    },
    var.additional_tags
  )
  
  # Environment-specific settings
  is_production = var.environment == "prod"
  
  # Naming convention
  resource_prefix = "${var.project_name}-${var.environment}"
}

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
} 