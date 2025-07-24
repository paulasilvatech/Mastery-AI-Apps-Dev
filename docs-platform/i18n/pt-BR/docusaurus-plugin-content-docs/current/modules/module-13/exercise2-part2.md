---
sidebar_position: 3
title: "Exercise 2: Part 2"
description: "## 📝 Part 3: Main Configuration"
---

# Exercício 2: Multi-ambiente Infrastructure with Terraform (Partee 2)

## 📝 Partee 3: Main Configuration

### Step 5: Create Main Terraform Configuration

Now create the main configuration that uses the modules:

**💡 Copilot Prompt Suggestion:**
```hcl
# Create main.tf that:
# - Uses the network and webapp modules
# - Creates a resource group
# - Adds a SQL database for data storage
# - Includes Key Vault for secrets
# - Uses variables for environment-specific values
```

**Expected Copilot Output:**
```hcl
# main.tf - Main Terraform configuration

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = merge(local.common_tags, var.tags, {
    Environment = var.environment
  })
}

# Network Module
module "network" {
  source = "./modules/network"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  vnet_address_space  = var.vnet_address_space
  tags                = merge(local.common_tags, var.tags)
}

# Web Application Module
module "webapp" {
  source = "./modules/webapp"
  
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  environment           = var.environment
  app_name              = var.project_name
  app_service_plan_sku  = var.app_service_plan_sku
  enable_staging_slot   = var.environment == "prod"
  enable_autoscale      = var.environment == "prod"
  tags                  = merge(local.common_tags, var.tags)
}

# SQL Server
resource "azurerm_mssql_server" "main" {
  name                         = "sql-${var.project_name}-${var.environment}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = random_password.sql_admin.result
  tags                         = merge(local.common_tags, var.tags)

  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = data.azurerm_client_config.current.object_id
  }
}

# SQL Database
resource "azurerm_mssql_database" "main" {
  name           = "sqldb-${var.project_name}-${var.environment}"
  server_id      = azurerm_mssql_server.main.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb    = var.database_size_gb
  sku_name       = var.database_sku
  zone_redundant = var.environment == "prod"
  tags           = merge(local.common_tags, var.tags)
}

# SQL Firewall Rules
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                        = "kv-${var.project_name}-${var.environment}"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  enabled_for_disk_encryption = false
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = var.environment == "prod" ? 90 : 7
  purge_protection_enabled    = var.environment == "prod"
  sku_name                    = "standard"
  tags                        = merge(local.common_tags, var.tags)

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
    ]
  }

  # Grant access to Web App
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = module.webapp.web_app_identity

    secret_permissions = [
      "Get", "List"
    ]
  }
}

# Store SQL password in Key Vault
resource "azurerm_key_vault_secret" "sql_password" {
  name         = "sql-admin-password"
  value        = random_password.sql_admin.result
  key_vault_id = azurerm_key_vault.main.id
}

# Random password for SQL admin
resource "random_password" "sql_admin" {
  length  = 16
  special = true
}

# Data sources
data "azurerm_client_config" "current" {}

# Outputs
output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "web_app_url" {
  value = module.webapp.web_app_url
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "key_vault_uri" {
  value = azurerm_key_vault.main.vault_uri
}
```

### Step 6: Create Variables File

Define the variables for the main configuration:

**💡 Copilot Prompt Suggestion:**
```hcl
# Create variables.tf with:
# - All required variables for main.tf
# - Appropriate types and descriptions
# - Default values where sensible
# - Validation rules for critical inputs
```

**Expected Copilot Output:**
```hcl
# variables.tf - Variable definitions

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  validation {
    condition     = length(var.project_name) &lt;= 10 && can(regex("^[a-z0-9]+$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric and max 10 characters."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus2"
}

variable "vnet_address_space" {
  description = "Virtual network address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "app_service_plan_sku" {
  description = "App Service Plan SKU"
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
  description = "SQL Database SKU"
  type        = string
  default     = "S0"
}

variable "database_size_gb" {
  description = "SQL Database size in GB"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
```

## 📝 Partee 4: ambiente-Specific Configurations

### Step 7: Create ambiente Variable Files

Create separate variable files for each ambiente:

**💡 Copilot Prompt Suggestion:**
```hcl
# Create three environment-specific variable files:
# 1. environments/dev.tfvars - Minimal resources
# 2. environments/staging.tfvars - Production-like but smaller
# 3. environments/prod.tfvars - Full production setup
```

**Expected Copilot Output:**

**ambientes/dev.tfvars:**
```hcl
# Development environment configuration
project_name = "workshop13"
environment  = "dev"
location     = "eastus2"

vnet_address_space = ["10.0.0.0/16"]

app_service_plan_sku = {
  tier = "Basic"
  size = "B1"
}

database_sku     = "Basic"
database_size_gb = 2

tags = {
  Environment = "Development"
  CostCenter  = "Development"
  AutoShutdown = "true"
}
```

**ambientes/staging.tfvars:**
```hcl
# Staging environment configuration
project_name = "workshop13"
environment  = "staging"
location     = "eastus2"

vnet_address_space = ["10.1.0.0/16"]

app_service_plan_sku = {
  tier = "Standard"
  size = "S2"
}

database_sku     = "S2"
database_size_gb = 50

tags = {
  Environment = "Staging"
  CostCenter  = "QA"
  AutoShutdown = "false"
}
```

**ambientes/prod.tfvars:**
```hcl
# Production environment configuration
project_name = "workshop13"
environment  = "prod"
location     = "eastus2"

vnet_address_space = ["10.2.0.0/16"]

app_service_plan_sku = {
  tier = "PremiumV3"
  size = "P1v3"
}

database_sku     = "S4"
database_size_gb = 250

tags = {
  Environment  = "Production"
  CostCenter   = "Operations"
  AutoShutdown = "false"
  Compliance   = "Required"
  SLA          = "99.9"
}
```

### Step 8: Create implantação Scripts

Create scripts to deploy each ambiente:

**💡 Copilot Prompt Suggestion:**
```bash
# Create a deployment script that:
# - Initializes Terraform with backend config
# - Validates the configuration
# - Plans with environment-specific vars
# - Applies with approval
# - Handles different environments
# File: deploy.sh
```

**Expected Copilot Output:**
```bash
#!/bin/bash
# deploy.sh - Deploy Terraform infrastructure

set -e

# Function to display usage
usage() {
    echo "Usage: $0 -e <environment> [-a] [-d]"
    echo "  -e: Environment (dev|staging|prod)"
    echo "  -a: Auto-approve (skip plan confirmation)"
    echo "  -d: Destroy infrastructure"
    exit 1
}

# Parse arguments
AUTO_APPROVE=""
DESTROY=false
ENVIRONMENT=""

while getopts "e:ad" opt; do
    case $opt in
        e) ENVIRONMENT=$OPTARG ;;
        a) AUTO_APPROVE="-auto-approve" ;;
        d) DESTROY=true ;;
        *) usage ;;
    esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "❌ Invalid environment: $ENVIRONMENT"
    usage
fi

# Load backend configuration
if [ ! -f "backend-config.txt" ]; then
    echo "❌ Backend configuration not found. Run setup-backend.sh first."
    exit 1
fi

echo "🚀 Deploying to $ENVIRONMENT environment..."

# Initialize Terraform with backend config
echo "📦 Initializing Terraform..."
terraform init \
    -backend-config="backend-config.txt" \
    -backend-config="key=${ENVIRONMENT}/terraform.tfstate" \
    -reconfigure

# Validate configuration
echo "✅ Validating configuration..."
terraform validate

# Plan or destroy
if [ "$DESTROY" = true ]; then
    echo "🗑️  Planning destruction..."
    terraform plan -destroy \
        -var-file="environments/${ENVIRONMENT}.tfvars" \
        -out="${ENVIRONMENT}.tfplan"
else
    echo "📋 Planning deployment..."
    terraform plan \
        -var-file="environments/${ENVIRONMENT}.tfvars" \
        -out="${ENVIRONMENT}.tfplan"
fi

# Show plan summary
echo -e "\n📊 Plan Summary:"
terraform show -no-color ${ENVIRONMENT}.tfplan | grep -E "Plan:|No changes"

# Apply plan
if [ -z "$AUTO_APPROVE" ]; then
    read -p "Do you want to apply this plan? (yes/no): " -n 3 -r
    echo
    if [[ ! $REPLY =~ ^yes$ ]]; then
        echo "❌ Deployment cancelled"
        exit 0
    fi
fi

echo "🔨 Applying plan..."
terraform apply ${ENVIRONMENT}.tfplan

# Clean up plan file
rm -f ${ENVIRONMENT}.tfplan

echo "✅ Deployment complete!"

# Show outputs
echo -e "\n📤 Outputs:"
terraform output -json | jq
```

## 🧪 implantação and Testing

### Step 9: Deploy to desenvolvimento

Deploy the desenvolvimento ambiente:

```bash
# Make script executable
chmod +x deploy.sh

# Deploy dev environment
./deploy.sh -e dev

# Verify resources
az resource list --resource-group rg-workshop13-dev --output table
```

### Step 10: Test Multi-ambiente

Create a test script to validate all ambientes:

**💡 Copilot Prompt Suggestion:**
```python
# Create a Python script that:
# - Connects to each environment's resources
# - Validates web app is accessible
# - Checks database connectivity
# - Verifies Key Vault access
# - Reports environment health
```

**Expected Test Script:**
```python
#!/usr/bin/env python3
# test_environments.py - Test multi-environment deployment

import os
import sys
import json
import requests
import subprocess
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.mgmt.resource import ResourceManagementClient

def get_terraform_output(environment):
    """Get Terraform outputs for an environment"""
    # Initialize with correct state
    subprocess.run([
        "terraform", "init",
        "-backend-config=backend-config.txt",
        f"-backend-config=key={environment}/terraform.tfstate"
    ], capture_output=True)
    
    # Get outputs
    result = subprocess.run(
        ["terraform", "output", "-json"],
        capture_output=True,
        text=True
    )
    return json.loads(result.stdout)

def test_web_app(url):
    """Test if web app is accessible"""
    try:
        response = requests.get(url, timeout=10)
        return response.status_code &lt; 500
    except:
        return False

def test_key_vault(vault_uri):
    """Test Key Vault access"""
    try:
        credential = DefaultAzureCredential()
        client = SecretClient(vault_url=vault_uri, credential=credential)
        # Try to list secrets (won't have any yet, but tests access)
        secrets = list(client.list_properties_of_secrets())
        return True
    except:
        return False

def test_environment(environment):
    """Test all resources in an environment"""
    print(f"\n🧪 Testing {environment} environment...")
    
    try:
        outputs = get_terraform_output(environment)
        
        # Test web app
        web_app_url = outputs['web_app_url']['value']
        web_app_ok = test_web_app(web_app_url)
        print(f"  Web App ({web_app_url}): {'✅' if web_app_ok else '❌'}")
        
        # Test Key Vault
        key_vault_uri = outputs['key_vault_uri']['value']
        kv_ok = test_key_vault(key_vault_uri)
        print(f"  Key Vault: {'✅' if kv_ok else '❌'}")
        
        # SQL Server (just check it exists in outputs)
        sql_fqdn = outputs['sql_server_fqdn']['value']
        print(f"  SQL Server: ✅ ({sql_fqdn})")
        
        return web_app_ok and kv_ok
    except Exception as e:
        print(f"  ❌ Error testing environment: {e}")
        return False

def main():
    """Test all environments"""
    environments = ['dev', 'staging', 'prod']
    results = {}
    
    for env in environments:
        # Check if environment is deployed
        rg_name = f"rg-workshop13-{env}"
        rg_exists = subprocess.run(
            ["az", "group", "exists", "--name", rg_name],
            capture_output=True,
            text=True
        ).stdout.strip() == "true"
        
        if rg_exists:
            results[env] = test_environment(env)
        else:
            print(f"\n⏭️  Skipping {env} - not deployed")
            results[env] = None
    
    # Summary
    print("\n📊 Test Summary:")
    for env, result in results.items():
        if result is None:
            print(f"  {env}: Not deployed")
        elif result:
            print(f"  {env}: ✅ All tests passed")
        else:
            print(f"  {env}: ❌ Some tests failed")

if __name__ == "__main__":
    main()
```

## 🎯 Exercício Completion

Congratulations! You've successfully:
- ✅ Set up remote state management
- ✅ Created reusable Terraform modules
- ✅ Implemented multi-ambiente configurations
- ✅ Deployed infrastructure with ambiente-specific settings
- ✅ Automated implantação with scripts

## 🔍 Key Takeaways

1. **Módulo Reusability**: Compartilhar code across ambientes
2. **State Isolation**: Each ambiente has its own state
3. **Variable Management**: Environment-specific configurations
4. **Automation**: Scripts ensure consistent implantaçãos
5. **Testing**: Validate each ambiente independently

## 🚀 Extension Challenges

1. Add a CDN module for static content
2. Implement blue-green implantação support
3. Add cost estimation to the implantação script
4. Create a disaster recovery ambiente

## 📚 Additional Recursos

- [Terraform Melhores Práticas](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [Azure Provider Documentação](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Módulo Registry](https://registry.terraform.io/browse/modules)

## ⏭️ Próximos Passos

Ready for the ultimate challenge? Move on to [Exercício 3: Completar GitOps Pipeline](/docs/modules/module-13/exercise3-overview)

---

*Remember: Good Terraform code is modular, reusable, and environment-agnostic!*