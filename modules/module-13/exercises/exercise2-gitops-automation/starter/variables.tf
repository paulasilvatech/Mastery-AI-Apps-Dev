# variables.tf - Variable definitions

variable "project_name" {
  description = "Project name"
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

# TODO: Add more variables as needed
# variable "app_service_sku" {
#   description = "App Service Plan SKU"
#   type        = string
#   default     = "B1"
# }

# Local tags
locals {
  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Module      = "13"
    Exercise    = "2"
  }
} 