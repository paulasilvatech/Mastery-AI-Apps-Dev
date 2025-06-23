# main.tf - Main Terraform configuration
# TODO: Implement main configuration

# Terraform and provider configuration
terraform {
  required_version = ">= 1.6.0"
  
  # TODO: Add backend configuration
  # backend "azurerm" {
  #   resource_group_name  = ""
  #   storage_account_name = ""
  #   container_name       = ""
  #   key                  = ""
  # }
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85.0"
    }
  }
}

# Azure Provider
provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = local.tags
}

# TODO: Add module calls
# module "network" {
#   source = "./modules/network"
#   ...
# }

# module "webapp" {
#   source = "./modules/webapp"
#   ...
# }

# module "database" {
#   source = "./modules/database"
#   ...
# } 