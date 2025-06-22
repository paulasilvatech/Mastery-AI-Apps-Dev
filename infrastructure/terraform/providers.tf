# Configure the Azure Provider
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.42.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
    
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Configure the Azure Active Directory Provider
provider "azuread" {
  # Configuration options
}

# Configure the GitHub Provider
provider "github" {
  # Configuration options
  # token = var.github_token # Set via GITHUB_TOKEN env var
}

# Configure the Random Provider
provider "random" {
  # Configuration options
}
