# Exercise 2: Terraform Multi-Environment - Part 2

## 🎯 Objective

Implement multi-environment infrastructure using the modules created in Part 1, with proper state management and environment-specific configurations.

## 📚 Continuing from Part 1

In Part 1, you created reusable modules. Now you'll:
- Set up remote state management
- Create environment configurations
- Implement workspaces for environment isolation
- Deploy to multiple environments

## 🛠️ Step 4: Configure Remote State Backend

### 4.1 Create Backend Storage

First, create a storage account for Terraform state:

```bash
# Run this script to create backend storage
cat > setup-backend.sh << 'EOF'
#!/bin/bash

# Variables
RESOURCE_GROUP="rg-terraform-state"
STORAGE_ACCOUNT="stterraform$RANDOM"
CONTAINER_NAME="tfstate"
LOCATION="eastus2"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account
az storage account create \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT \
  --sku Standard_LRS \
  --encryption-services blob

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT \
  --query '[0].value' -o tsv)

# Create blob container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT \
  --account-key $ACCOUNT_KEY

# Output configuration
echo "Backend configuration:"
echo "  resource_group_name  = \"$RESOURCE_GROUP\""
echo "  storage_account_name = \"$STORAGE_ACCOUNT\""
echo "  container_name       = \"$CONTAINER_NAME\""
echo "  key                  = \"terraform.tfstate\""
EOF

chmod +x setup-backend.sh
./setup-backend.sh
```

### 4.2 Create Backend Configuration

Create `backend.tf` in the root directory:

```hcl
# backend.tf

terraform {
  backend "azurerm" {
    # These values will be provided during init
    # or set via backend config file
  }
}
```

Create `backend-config.hcl` (add to .gitignore):

```hcl
# backend-config.hcl
# Add this file to .gitignore!

resource_group_name  = "rg-terraform-state"
storage_account_name = "stterraformXXXXX"  # Replace with your storage account
container_name       = "tfstate"
key                  = "terraform.tfstate"
```

## 🛠️ Step 5: Create Environment Configurations

### 5.1 Create Provider Configuration

Create `providers.tf`:

```hcl
# providers.tf

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "random" {}
```

### 5.2 Create Main Configuration

Create `main.tf`:

**Copilot Prompt:**
```
Create Terraform main configuration that:
- Uses workspace name for environment
- Calls network module
- Calls webapp module
- Adds database module only for staging/prod
- Uses locals for environment-specific values
```

**Expected Result:**
```hcl
# main.tf

# Determine environment from workspace
locals {
  environment = terraform.workspace == "default" ? "dev" : terraform.workspace
  
  # Environment-specific configurations
  env_config = {
    dev = {
      location              = "eastus2"
      address_space         = "10.0.0.0/16"
      subnet_prefixes       = ["10.0.1.0/24", "10.0.2.0/24"]
      app_service_plan_tier = "Basic"
      app_service_plan_size = "B1"
      enable_database       = false
    }
    staging = {
      location              = "eastus2"
      address_space         = "10.1.0.0/16"
      subnet_prefixes       = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
      app_service_plan_tier = "Standard"
      app_service_plan_size = "S1"
      enable_database       = true
    }
    prod = {
      location              = "eastus2"
      address_space         = "10.2.0.0/16"
      subnet_prefixes       = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24", "10.2.4.0/24"]
      app_service_plan_tier = "PremiumV3"
      app_service_plan_size = "P1v3"
      enable_database       = true
    }
  }
  
  config = local.env_config[local.environment]
  
  common_tags = {
    Environment = local.environment
    ManagedBy   = "Terraform"
    Module      = "Module-13"
    Exercise    = "Exercise-2"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
}

# Random suffix for unique naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Network Module
module "network" {
  source = "./modules/network"
  
  resource_prefix = "${var.project_name}-${local.environment}"
  location        = local.config.location
  address_space   = local.config.address_space
  subnet_prefixes = local.config.subnet_prefixes
  tags            = local.common_tags
}

# Web App Module
module "webapp" {
  source = "./modules/webapp"
  
  app_name               = "${var.project_name}-${local.environment}-${random_string.suffix.result}"
  resource_group_name    = module.network.resource_group_name
  location               = module.network.resource_group_location
  app_service_plan_tier  = local.config.app_service_plan_tier
  app_service_plan_size  = local.config.app_service_plan_size
  subnet_id              = local.environment == "prod" ? module.network.subnet_ids[0] : ""
  enable_monitoring      = true
  tags                   = local.common_tags
  
  app_settings = {
    "ENVIRONMENT"           = local.environment
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }
}

# Database Module (Staging and Prod only)
module "database" {
  source = "./modules/database"
  count  = local.config.enable_database ? 1 : 0
  
  resource_group_name = module.network.resource_group_name
  location            = module.network.resource_group_location
  server_name         = "sql-${var.project_name}-${local.environment}-${random_string.suffix.result}"
  database_name       = "db-${var.project_name}"
  admin_username      = var.sql_admin_username
  admin_password      = var.sql_admin_password
  sku_name           = local.environment == "prod" ? "S2" : "S0"
  tags               = local.common_tags
}
```

### 5.3 Create Variables

Create `variables.tf`:

```hcl
# variables.tf

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "workshop13"
}

variable "sql_admin_username" {
  description = "SQL Server administrator username"
  type        = string
  default     = "sqladmin"
  sensitive   = true
}

variable "sql_admin_password" {
  description = "SQL Server administrator password"
  type        = string
  sensitive   = true
}
```

### 5.4 Create Outputs

Create `outputs.tf`:

```hcl
# outputs.tf

output "environment" {
  description = "Current environment"
  value       = local.environment
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.network.resource_group_name
}

output "web_app_url" {
  description = "URL of the web application"
  value       = module.webapp.web_app_url
}

output "web_app_identity" {
  description = "Managed identity principal ID"
  value       = module.webapp.web_app_identity_principal_id
}

output "database_server" {
  description = "Database server FQDN"
  value       = local.config.enable_database ? module.database[0].server_fqdn : "N/A"
}
```

## 🛠️ Step 6: Create Database Module

### 6.1 Database Variables

Create `modules/database/variables.tf`:

```hcl
# modules/database/variables.tf

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "server_name" {
  description = "Name of the SQL server"
  type        = string
}

variable "database_name" {
  description = "Name of the database"
  type        = string
}

variable "admin_username" {
  description = "Administrator username"
  type        = string
}

variable "admin_password" {
  description = "Administrator password"
  type        = string
  sensitive   = true
}

variable "sku_name" {
  description = "SKU name for the database"
  type        = string
  default     = "S0"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
```

### 6.2 Database Resources

Create `modules/database/main.tf`:

```hcl
# modules/database/main.tf

resource "azurerm_mssql_server" "main" {
  name                         = var.server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password
  minimum_tls_version          = "1.2"
  tags                         = var.tags

  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = data.azurerm_client_config.current.object_id
  }
}

resource "azurerm_mssql_database" "main" {
  name           = var.database_name
  server_id      = azurerm_mssql_server.main.id
  sku_name       = var.sku_name
  tags           = var.tags
  
  threat_detection_policy {
    state                      = "Enabled"
    email_addresses           = []
    retention_days            = 30
  }
}

# Firewall rule for Azure services
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

data "azurerm_client_config" "current" {}
```

### 6.3 Database Outputs

Create `modules/database/outputs.tf`:

```hcl
# modules/database/outputs.tf

output "server_id" {
  description = "ID of the SQL server"
  value       = azurerm_mssql_server.main.id
}

output "server_fqdn" {
  description = "Fully qualified domain name of the SQL server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "database_id" {
  description = "ID of the database"
  value       = azurerm_mssql_database.main.id
}

output "database_name" {
  description = "Name of the database"
  value       = azurerm_mssql_database.main.name
}

output "connection_string" {
  description = "Database connection string"
  value       = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Persist Security Info=False;User ID=${var.admin_username};Password=${var.admin_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  sensitive   = true
}
```

## 🛠️ Step 7: Deploy Environments

### 7.1 Initialize Terraform

```bash
# Initialize with backend config
terraform init -backend-config=backend-config.hcl
```

### 7.2 Create and Deploy Dev Environment

```bash
# Create dev workspace (default)
terraform workspace select default

# Plan deployment
terraform plan -var="sql_admin_password=P@ssw0rd123!" -out=dev.tfplan

# Apply
terraform apply dev.tfplan
```

### 7.3 Create and Deploy Staging Environment

```bash
# Create staging workspace
terraform workspace new staging

# Plan deployment
terraform plan -var="sql_admin_password=P@ssw0rd123!" -out=staging.tfplan

# Apply
terraform apply staging.tfplan
```

### 7.4 Create and Deploy Production Environment

```bash
# Create production workspace
terraform workspace new prod

# Plan deployment
terraform plan -var="sql_admin_password=P@ssw0rd123!" -out=prod.tfplan

# Apply
terraform apply prod.tfplan
```

## ✅ Validation

Verify your deployments:

```bash
# List workspaces
terraform workspace list

# Check outputs for each environment
for env in default staging prod; do
  echo "\n=== $env environment ==="
  terraform workspace select $env
  terraform output -json
done
```

## 🎯 Summary

In Part 2, you've:
- ✅ Configured remote state management
- ✅ Created environment-specific configurations
- ✅ Implemented workspace-based environments
- ✅ Added conditional resources (database)
- ✅ Deployed three separate environments

## 🏆 Bonus Challenges

1. **Add Key Vault**:
   - Create a Key Vault module
   - Store SQL password securely
   - Reference from web app

2. **Implement CI/CD**:
   - Create GitHub Actions workflow
   - Automate deployments
   - Add approval gates

3. **Cost Optimization**:
   - Add auto-shutdown for dev
   - Implement tagging policy
   - Create cost alerts

## 🧹 Cleanup

To destroy all environments:

```bash
# Destroy each environment
for env in prod staging default; do
  terraform workspace select $env
  terraform destroy -auto-approve
done

# Delete the backend storage (optional)
az group delete --name rg-terraform-state --yes --no-wait
```

---

🎉 **Congratulations!** You've successfully implemented a multi-environment infrastructure using Terraform modules and workspaces!

**Next Steps:** Proceed to Exercise 3 to implement complete GitOps automation for your infrastructure.