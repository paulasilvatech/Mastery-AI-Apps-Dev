# Exercise 2: Terraform Multi-Environment - Part 1

## 🎯 Objective

Create reusable Terraform modules for infrastructure components that can be shared across multiple environments.

## 📚 Background

Terraform modules are self-contained packages of Terraform configurations that are managed as a group. They enable:
- **Reusability**: Write once, use many times
- **Consistency**: Same patterns across environments
- **Abstraction**: Hide complexity behind simple interfaces
- **Versioning**: Control module updates

## 🛠️ Step 1: Set Up Module Structure

### 1.1 Create Module Directories

```bash
# From the starter directory
mkdir -p modules/network
mkdir -p modules/webapp
mkdir -p modules/database
```

### 1.2 Initialize Network Module

Create `modules/network/variables.tf`:

**Copilot Prompt:**
```
Create Terraform variables for a network module:
- resource_prefix (string): Prefix for all resources
- location (string): Azure region
- address_space (string): CIDR for VNet
- subnet_prefixes (list): List of subnet CIDRs
- tags (map): Resource tags
```

**Expected Result:**
```hcl
# modules/network/variables.tf

variable "resource_prefix" {
  description = "Prefix for all resource names"
  type        = string
  validation {
    condition     = length(var.resource_prefix) <= 10
    error_message = "Resource prefix must be 10 characters or less."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US 2"
}

variable "address_space" {
  description = "Address space for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_prefixes" {
  description = "List of subnet address prefixes"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
```

### 1.3 Create Network Resources

Create `modules/network/main.tf`:

**Copilot Prompt:**
```
Create Terraform resources for Azure networking:
- Resource group
- Virtual network with address space
- Subnets based on subnet_prefixes variable
- Network security group with basic rules
- Use proper naming with resource_prefix
```

**Expected Result:**
```hcl
# modules/network/main.tf

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.resource_prefix}-rg"
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.resource_prefix}-vnet"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = [var.address_space]
  tags                = var.tags
}

# Subnets
resource "azurerm_subnet" "main" {
  count                = length(var.subnet_prefixes)
  name                 = "${var.resource_prefix}-subnet-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_prefixes[count.index]]
}

# Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "${var.resource_prefix}-nsg"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = var.tags

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
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
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with subnets
resource "azurerm_subnet_network_security_group_association" "main" {
  count                     = length(azurerm_subnet.main)
  subnet_id                 = azurerm_subnet.main[count.index].id
  network_security_group_id = azurerm_network_security_group.main.id
}
```

### 1.4 Define Network Outputs

Create `modules/network/outputs.tf`:

```hcl
# modules/network/outputs.tf

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "subnet_ids" {
  description = "List of subnet IDs"
  value       = azurerm_subnet.main[*].id
}

output "nsg_id" {
  description = "ID of the network security group"
  value       = azurerm_network_security_group.main.id
}
```

## 🛠️ Step 2: Create Web App Module

### 2.1 Web App Variables

Create `modules/webapp/variables.tf`:

**Copilot Prompt:**
```
Create Terraform variables for a web app module:
- app_name (string): Application name
- resource_group_name (string): Existing RG name
- location (string): Azure location
- app_service_plan_tier (string): SKU tier with validation
- app_service_plan_size (string): SKU size
- app_settings (map): Application settings
- subnet_id (string): Subnet for VNet integration (optional)
- tags (map): Resource tags
```

**Expected Result:**
```hcl
# modules/webapp/variables.tf

variable "app_name" {
  description = "Name of the web application"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "app_service_plan_tier" {
  description = "Tier of the App Service Plan"
  type        = string
  default     = "Basic"
  validation {
    condition = contains(["Free", "Shared", "Basic", "Standard", "Premium", "PremiumV2", "PremiumV3"], var.app_service_plan_tier)
    error_message = "App Service Plan tier must be a valid Azure tier."
  }
}

variable "app_service_plan_size" {
  description = "Size of the App Service Plan"
  type        = string
  default     = "B1"
}

variable "app_settings" {
  description = "Application settings for the web app"
  type        = map(string)
  default     = {}
}

variable "subnet_id" {
  description = "Subnet ID for VNet integration"
  type        = string
  default     = ""
}

variable "enable_monitoring" {
  description = "Enable Application Insights"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

### 2.2 Web App Resources

Create `modules/webapp/main.tf`:

**Copilot Prompt:**
```
Create Terraform resources for Azure web app:
- App Service Plan with dynamic SKU
- Web App with .NET 6, managed identity, HTTPS only
- Application Insights if monitoring enabled
- VNet integration if subnet provided
- Include locals for naming
```

**Expected Result:**
```hcl
# modules/webapp/main.tf

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Local values for consistent naming
locals {
  app_service_plan_name = "${var.app_name}-asp"
  web_app_name         = "${var.app_name}-app"
  app_insights_name    = "${var.app_name}-ai"
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = local.app_service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Windows"
  sku_name           = "${substr(var.app_service_plan_tier, 0, 1)}${var.app_service_plan_size}"
  tags               = var.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  count               = var.enable_monitoring ? 1 : 0
  name                = local.app_insights_name
  resource_group_name = var.resource_group_name
  location            = var.location
  application_type    = "web"
  tags               = var.tags
}

# Web App
resource "azurerm_windows_web_app" "main" {
  name                = local.web_app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id
  tags               = var.tags

  site_config {
    always_on        = var.app_service_plan_tier != "Free" && var.app_service_plan_tier != "Shared"
    ftps_state       = "Disabled"
    http2_enabled    = true
    minimum_tls_version = "1.2"
    
    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v6.0"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = merge(
    var.app_settings,
    var.enable_monitoring ? {
      "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.main[0].instrumentation_key
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main[0].connection_string
    } : {}
  )

  https_only = true
}

# VNet Integration (if subnet provided)
resource "azurerm_app_service_virtual_network_swift_connection" "main" {
  count          = var.subnet_id != "" ? 1 : 0
  app_service_id = azurerm_windows_web_app.main.id
  subnet_id      = var.subnet_id
}
```

### 2.3 Web App Outputs

Create `modules/webapp/outputs.tf`:

```hcl
# modules/webapp/outputs.tf

output "web_app_id" {
  description = "ID of the web app"
  value       = azurerm_windows_web_app.main.id
}

output "web_app_name" {
  description = "Name of the web app"
  value       = azurerm_windows_web_app.main.name
}

output "web_app_url" {
  description = "Default URL of the web app"
  value       = "https://${azurerm_windows_web_app.main.default_hostname}"
}

output "web_app_identity_principal_id" {
  description = "Principal ID of the web app's managed identity"
  value       = azurerm_windows_web_app.main.identity[0].principal_id
}

output "app_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = var.enable_monitoring ? azurerm_application_insights.main[0].instrumentation_key : ""
  sensitive   = true
}
```

## 🛠️ Step 3: Create Database Module (Optional)

### 3.1 Database Module Structure

Create a basic database module structure for production environments:

```bash
# Create files
touch modules/database/variables.tf
touch modules/database/main.tf
touch modules/database/outputs.tf
```

**Note**: We'll implement the database module in Part 2 for production environments only.

## ✅ Checkpoint

Before proceeding to Part 2, ensure:
- [ ] Network module is complete with all three files
- [ ] Web app module is complete with all three files
- [ ] Module variables have proper validation
- [ ] Outputs expose necessary values for module consumers
- [ ] No syntax errors (run `terraform fmt` in each module)

### Validate Module Syntax

```bash
# Format and validate each module
for module in network webapp; do
  echo "Validating $module module..."
  cd modules/$module
  terraform fmt
  terraform init
  terraform validate
  cd ../..
done
```

## 🎯 Summary

In Part 1, you've:
- ✅ Created a reusable network module
- ✅ Built a flexible web app module
- ✅ Implemented proper variable validation
- ✅ Defined clear module interfaces with outputs
- ✅ Applied infrastructure as code best practices

## ⏭️ Next Steps

Proceed to [Part 2](./part2.md) where you'll:
- Configure remote state backend
- Create environment-specific configurations
- Implement the modules for multiple environments
- Add the database module for production
- Deploy all three environments

---

💡 **Tip**: Well-designed modules are like LEGO blocks - they should be easy to combine in different ways to build various infrastructure patterns!