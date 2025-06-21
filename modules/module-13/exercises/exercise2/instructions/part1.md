# Exercise 2: Multi-Environment Infrastructure with Terraform (⭐⭐ Medium)

## 🎯 Exercise Overview

In this exercise, you'll create a multi-environment infrastructure setup using Terraform. You'll learn how to manage different environments (dev, staging, prod) with shared modules, remote state management, and environment-specific configurations.

**Duration**: 45-60 minutes  
**Difficulty**: ⭐⭐ Medium  
**Success Rate**: 80%

## 🎓 Learning Objectives

By completing this exercise, you will:
- Structure Terraform code for multiple environments
- Use Terraform modules for code reusability
- Implement remote state management with Azure Storage
- Configure environment-specific variables
- Apply Terraform best practices with Copilot assistance

## 📋 Scenario

Your organization needs a scalable infrastructure setup that supports:
- Multiple environments (dev, staging, production)
- Consistent infrastructure across environments
- Different sizing and features per environment
- Centralized state management
- Secure secret handling

You'll build this using Terraform with a modular approach.

## 🏗️ Architecture

```mermaid
graph TB
    subgraph "Terraform Structure"
        A[main.tf] --> B[Modules]
        B --> C[Network Module]
        B --> D[Compute Module]
        B --> E[Database Module]
        B --> F[Monitoring Module]
    end
    
    subgraph "Environments"
        G[terraform.tfvars.dev]
        H[terraform.tfvars.staging]
        I[terraform.tfvars.prod]
    end
    
    subgraph "State Management"
        J[Azure Storage Account]
        K[dev.tfstate]
        L[staging.tfstate]
        M[prod.tfstate]
        J --> K
        J --> L
        J --> M
    end
    
    A --> G
    A --> H
    A --> I
    
    style A fill:#e1f5e1
    style B fill:#e3f2fd
    style J fill:#fff3e0
```

## 🛠️ Prerequisites Check

```bash
# Verify Terraform installation
terraform version

# Ensure Azure CLI is configured
az account show

# Create directory structure
mkdir -p exercises/exercise2-terraform-environments/{modules,environments}
cd exercises/exercise2-terraform-environments
```

## 📝 Part 1: Set Up Remote State Backend

### Step 1: Create State Storage

First, create an Azure Storage Account for Terraform state:

**💡 Copilot Prompt Suggestion:**
```bash
# Create a bash script that:
# - Creates a resource group for Terraform state
# - Creates a storage account with unique name
# - Creates a container for state files
# - Outputs the storage account details
# Include error handling and idempotency
```

**Expected Copilot Output:**
```bash
#!/bin/bash
# setup-backend.sh - Set up Terraform state backend

set -e

# Variables
STATE_RESOURCE_GROUP="rg-terraform-state"
LOCATION="eastus2"
RANDOM_SUFFIX=$(date +%s | tail -c 5)
STORAGE_ACCOUNT_NAME="tfstate${RANDOM_SUFFIX}"
CONTAINER_NAME="tfstate"

echo "🚀 Setting up Terraform backend storage..."

# Create resource group
echo "Creating resource group: $STATE_RESOURCE_GROUP"
az group create \
  --name $STATE_RESOURCE_GROUP \
  --location $LOCATION \
  --output none || echo "Resource group already exists"

# Create storage account
echo "Creating storage account: $STORAGE_ACCOUNT_NAME"
az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $STATE_RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob \
  --output none

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $STATE_RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT_NAME \
  --query '[0].value' -o tsv)

# Create blob container
echo "Creating container: $CONTAINER_NAME"
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --account-key $ACCOUNT_KEY \
  --output none

# Enable versioning
az storage account blob-service-properties update \
  --account-name $STORAGE_ACCOUNT_NAME \
  --resource-group $STATE_RESOURCE_GROUP \
  --enable-versioning true \
  --output none

# Output configuration
echo -e "\n✅ Backend storage created successfully!"
echo -e "\n📝 Add this to your Terraform backend configuration:"
echo "terraform {"
echo "  backend \"azurerm\" {"
echo "    resource_group_name  = \"$STATE_RESOURCE_GROUP\""
echo "    storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
echo "    container_name       = \"$CONTAINER_NAME\""
echo "    key                  = \"env/terraform.tfstate\""
echo "  }"
echo "}"

# Save to file for reference
cat > backend-config.txt <<EOF
resource_group_name  = "$STATE_RESOURCE_GROUP"
storage_account_name = "$STORAGE_ACCOUNT_NAME"
container_name       = "$CONTAINER_NAME"
EOF

echo -e "\n💾 Configuration saved to backend-config.txt"
```

### Step 2: Create Provider Configuration

Create the main Terraform configuration with backend setup:

**💡 Copilot Prompt Suggestion:**
```hcl
# Create a Terraform provider configuration that:
# - Configures Azure provider with required features
# - Sets up backend for remote state
# - Includes required provider versions
# - Adds common tags for all resources
# File: providers.tf
```

**Expected Copilot Output:**
```hcl
# providers.tf - Provider and backend configuration

terraform {
  required_version = ">= 1.6.0"
  
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
  
  # Backend configuration will be initialized with -backend-config
  backend "azurerm" {}
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Common tags for all resources
locals {
  common_tags = {
    ManagedBy   = "Terraform"
    Module      = "Module-13"
    Repository  = "mastery-ai-workshop"
    CostCenter  = "Training"
  }
}
```

## 📝 Part 2: Create Reusable Modules

### Step 3: Network Module

Create a reusable network module:

**💡 Copilot Prompt Suggestion:**
```hcl
# Create a Terraform module for networking that:
# - Creates a VNet with configurable address space
# - Creates subnets for web, app, and data tiers
# - Includes NSG with basic rules
# - Outputs subnet IDs and VNet ID
# Path: modules/network/main.tf
```

**Expected Copilot Output:**
```hcl
# modules/network/main.tf - Network module

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# Subnets
resource "azurerm_subnet" "web" {
  name                 = "subnet-web-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space[0], 8, 1)]
}

resource "azurerm_subnet" "app" {
  name                 = "subnet-app-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space[0], 8, 2)]
}

resource "azurerm_subnet" "data" {
  name                 = "subnet-data-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space[0], 8, 3)]
  
  delegation {
    name = "sql-delegation"
    service_delegation {
      name = "Microsoft.Sql/managedInstances"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

# Network Security Groups
resource "azurerm_network_security_group" "web" {
  name                = "nsg-web-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

# Outputs
output "vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "subnet_web_id" {
  value = azurerm_subnet.web.id
}

output "subnet_app_id" {
  value = azurerm_subnet.app.id
}

output "subnet_data_id" {
  value = azurerm_subnet.data.id
}
```

### Step 4: Web App Module

Create a module for web applications:

**💡 Copilot Prompt Suggestion:**
```hcl
# Create a Terraform module for web apps that:
# - Creates App Service Plan with configurable SKU
# - Creates Web App with .NET 8 runtime
# - Includes Application Insights
# - Adds staging slot for production
# - Configures auto-scaling for production
# Path: modules/webapp/main.tf
```

**Expected Copilot Output:**
```hcl
# modules/webapp/main.tf - Web application module

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
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

variable "enable_staging_slot" {
  description = "Enable staging slot"
  type        = bool
  default     = false
}

variable "enable_autoscale" {
  description = "Enable auto-scaling"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "asp-${var.app_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku.size
  tags                = var.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "ai-${var.app_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  tags                = var.tags
}

# Web App
resource "azurerm_linux_web_app" "main" {
  name                = "app-${var.app_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true
  tags                = var.tags

  site_config {
    always_on = var.app_service_plan_sku.tier != "Free" && var.app_service_plan_sku.tier != "Shared"
    
    application_stack {
      dotnet_version = "8.0"
    }
  }

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.main.instrumentation_key
  }

  identity {
    type = "SystemAssigned"
  }
}

# Staging Slot (Production only)
resource "azurerm_linux_web_app_slot" "staging" {
  count           = var.enable_staging_slot ? 1 : 0
  name            = "staging"
  app_service_id  = azurerm_linux_web_app.main.id
  https_only      = true
  tags            = var.tags

  site_config {
    always_on = true
    
    application_stack {
      dotnet_version = "8.0"
    }
  }

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.main.instrumentation_key
  }

  identity {
    type = "SystemAssigned"
  }
}

# Auto-scale settings (Production only)
resource "azurerm_monitor_autoscale_setting" "main" {
  count               = var.enable_autoscale ? 1 : 0
  name                = "autoscale-${var.app_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_service_plan.main.id
  tags                = var.tags

  profile {
    name = "defaultProfile"
    
    capacity {
      default = 2
      minimum = 2
      maximum = 10
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}

# Outputs
output "web_app_id" {
  value = azurerm_linux_web_app.main.id
}

output "web_app_url" {
  value = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "web_app_identity" {
  value = azurerm_linux_web_app.main.identity[0].principal_id
}

output "app_insights_key" {
  value     = azurerm_application_insights.main.instrumentation_key
  sensitive = true
}
```