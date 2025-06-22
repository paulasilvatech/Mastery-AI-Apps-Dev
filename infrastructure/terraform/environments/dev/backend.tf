# Backend configuration for storing Terraform state

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stmasteryaitfstate"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
    
    # Use Azure AD authentication
    use_azuread_auth = true
  }
}

# Note: Before running terraform init, ensure:
# 1. The storage account exists
# 2. You have proper permissions
# 3. You're authenticated with Azure CLI: az login
#
# To create the backend storage:
# ./scripts/setup-terraform-backend.sh
