# Module 13 - Complete GitHub Copilot Agent Guide
## Part 2: Exercise 2 (Terraform for Multi-Cloud Infrastructure)

### 🎯 Learning Objectives

In this comprehensive guide, you'll learn:
- Terraform fundamentals and HashiCorp Configuration Language (HCL)
- Multi-cloud infrastructure management (Azure + AWS)
- State management and remote backends
- Module development for reusable infrastructure
- Advanced patterns: workspaces, data sources, provisioners
- Migration strategies from cloud-specific tools to Terraform
- Cost optimization across multiple clouds
- Security best practices for multi-cloud environments

### 🤖 Understanding Terraform with GitHub Copilot

**What is Terraform?**
- Infrastructure as Code tool that works across multiple cloud providers
- Declarative language (HCL) that describes desired state
- Manages infrastructure lifecycle: create, update, destroy
- Maintains state to track real-world resources

**Why use Copilot for Terraform?**
- Generate complex multi-cloud configurations
- Learn provider-specific resource syntax
- Implement best practices across clouds
- Create reusable modules efficiently

---

## 📚 Exercise 2 Overview: Multi-Cloud Infrastructure

In this exercise, you'll build:
1. **Multi-cloud foundation**: Azure + AWS setup
2. **Network connectivity**: Cross-cloud VPN/peering
3. **Unified monitoring**: Multi-cloud observability
4. **Disaster recovery**: Cross-cloud backup strategy
5. **Cost management**: Multi-cloud optimization

Let's start with setting up your Terraform environment.

---

## 🚀 Repository Setup for Exercise 2

### Step 1: Create Terraform Repository

**💡 Educational Note**: We'll create a dedicated repository for Terraform multi-cloud infrastructure. This separation from application code follows infrastructure-as-code best practices.

#### Copilot Agent Prompt:
```markdown
@workspace Create a comprehensive setup guide for a Terraform multi-cloud repository. Include:

1. Repository creation steps for "terraform-multicloud-infrastructure"
2. Directory structure for managing Azure and AWS resources
3. Module organization for reusability
4. State management configuration
5. Environment separation strategy
6. Security considerations for multi-cloud

Explain why Terraform requires different organizational patterns than cloud-specific tools.
```

#### Expected Output:
```markdown
# Terraform Multi-Cloud Repository Setup

## Repository Creation
1. Create new repository: `terraform-multicloud-infrastructure`
2. Description: "Multi-cloud infrastructure with Terraform - Azure and AWS"
3. Initialize with:
   - ✅ README.md
   - ✅ .gitignore (Terraform template)
   - ✅ MIT License
   - ⚠️ Set to Private (contains infrastructure definitions)

## Why Different from Bicep?
- **Multi-Provider**: Must handle different cloud APIs
- **State Management**: Critical for tracking resources
- **Module System**: Different abstraction model
- **Environment Handling**: More complex strategies needed

## Clone Repository:
```bash
git clone https://github.com/YOUR_USERNAME/terraform-multicloud-infrastructure.git
cd terraform-multicloud-infrastructure
```
```

### Step 2: Project Structure Setup

#### Copilot Agent Prompt:
```markdown
@workspace Create the complete Terraform project structure for multi-cloud infrastructure that includes:

1. Environments directory with dev/staging/prod separation
2. Modules directory for reusable components
3. Providers directory for cloud-specific configurations
4. Scripts for automation and setup
5. Documentation structure
6. Testing framework setup

Explain the purpose of each directory and how they work together.
```

#### Expected Output:
```
terraform-multicloud-infrastructure/
├── environments/              # Environment-specific configurations
│   ├── dev/
│   │   ├── main.tf          # Dev environment entry point
│   │   ├── variables.tf     # Dev-specific variables
│   │   ├── outputs.tf       # Dev outputs
│   │   ├── terraform.tfvars.example
│   │   └── backend.tf       # State backend config
│   ├── staging/
│   └── prod/
├── modules/                   # Reusable infrastructure modules
│   ├── network/              # Multi-cloud network module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   ├── azure.tf         # Azure-specific resources
│   │   ├── aws.tf           # AWS-specific resources
│   │   └── README.md
│   ├── compute/
│   ├── storage/
│   ├── database/
│   └── monitoring/
├── scripts/                   # Helper scripts
│   ├── setup-backend.sh      # Initialize state backend
│   ├── init-providers.sh     # Provider setup
│   └── destroy-all.sh        # Cleanup script
├── docs/
│   ├── architecture/
│   ├── modules/
│   └── runbooks/
├── tests/                     # Terratest files
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml
│       └── terraform-apply.yml
├── .gitignore
├── .pre-commit-config.yaml
├── Makefile
└── README.md
```

### Step 3: Terraform and Tool Installation

**💡 Educational Note**: Terraform requires specific tooling for multi-cloud development. We'll install everything needed for both Azure and AWS.

#### Copilot Agent Prompt:
```markdown
@workspace Create installation instructions for Terraform multi-cloud development that includes:

1. Terraform installation with version management
2. Azure CLI and AWS CLI setup
3. Authentication configuration for both clouds
4. Additional tools: tflint, tfsec, terraform-docs, checkov
5. VS Code extensions for Terraform
6. Pre-commit hooks setup

Include platform-specific instructions (Windows, macOS, Linux, Codespaces).
```

#### Expected Output:
```markdown
# Terraform Multi-Cloud Installation Guide

## Required Tools

| Tool | Purpose | Version |
|------|---------|---------|
| Terraform | Infrastructure provisioning | >= 1.5.0 |
| Azure CLI | Azure authentication | >= 2.50 |
| AWS CLI | AWS authentication | >= 2.13 |
| tflint | Terraform linting | >= 0.47 |
| tfsec | Security scanning | >= 1.28 |
| checkov | Policy as code | >= 2.4 |

## GitHub Codespaces Setup (Recommended)

Create `.devcontainer/devcontainer.json`:
```json
{
  "name": "Terraform Multi-Cloud",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/terraform:1": {
      "version": "1.6",
      "tflint": "latest",
      "terragrunt": "latest"
    },
    "ghcr.io/devcontainers/features/aws-cli:1": {},
    "ghcr.io/devcontainers/features/azure-cli:1": {},
    "ghcr.io/devcontainers/features/python:1": {}
  },
  "postCreateCommand": "pip install checkov terraform-docs && pre-commit install",
  "customizations": {
    "vscode": {
      "extensions": [
        "hashicorp.terraform",
        "ms-azuretools.vscode-azureterraform",
        "amazonwebservices.aws-toolkit-vscode",
        "github.copilot",
        "github.copilot-chat"
      ]
    }
  }
}
```

## macOS Installation
```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tools
brew install terraform
brew install azure-cli
brew install awscli
brew install tflint
brew install terraform-docs
brew install pre-commit
brew install checkov
brew install tfsec
```

## Windows Installation
```powershell
# Using Chocolatey (as Administrator)
choco install terraform -y
choco install azure-cli -y
choco install awscli -y
choco install tflint -y
choco install python -y

# Python tools
pip install checkov terraform-docs pre-commit
```

## Authentication Setup

### Azure
```bash
# Interactive login
az login

# Service Principal (for CI/CD)
az ad sp create-for-rbac --name terraform-sp --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID

# Set environment variables
export ARM_CLIENT_ID="<app-id>"
export ARM_CLIENT_SECRET="<password>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"
export ARM_TENANT_ID="<tenant-id>"
```

### AWS
```bash
# Configure CLI
aws configure

# Or use environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```
```

---

## 🛠️ Exercise 2: Building Multi-Cloud Infrastructure

### Step 4: Provider Configuration

**💡 Educational Note**: Managing multiple cloud providers requires careful configuration. We'll set up both Azure and AWS providers with proper versioning and authentication.

#### Copilot Agent Prompt:
```markdown
@workspace Create a multi-cloud provider configuration that includes:

1. Azure provider with features configuration
2. AWS provider with multiple regions
3. Provider version constraints
4. Authentication methods
5. Default tags for both providers
6. Provider aliases for multi-region

Explain how Terraform manages multiple providers and state.
```

#### Expected Provider Configuration:

**environments/dev/versions.tf:**
```hcl
# =====================================================
# Provider Requirements and Versions
# =====================================================
# This file defines the required providers and their
# versions for consistent deployments

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.31.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
  }
}
```

**environments/dev/providers.tf:**
```hcl
# =====================================================
# Multi-Cloud Provider Configuration
# =====================================================
# Configure both Azure and AWS providers with best
# practices for authentication and tagging

# Azure Provider Configuration
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    
    key_vault {
      purge_soft_delete_on_destroy = false
      recover_soft_deleted_key_vaults = true
    }
    
    virtual_machine {
      delete_os_disk_on_deletion = true
      graceful_shutdown = false
    }
  }
  
  # Authentication via environment variables or Azure CLI
  # subscription_id = var.azure_subscription_id
}

# AWS Provider - Primary Region
provider "aws" {
  region = var.aws_primary_region
  
  # Authentication via environment variables or IAM role
  
  default_tags {
    tags = {
      Environment  = var.environment
      Project      = var.project_name
      ManagedBy    = "Terraform"
      Owner        = var.owner_email
      CostCenter   = var.cost_center
      CreatedDate  = timestamp()
    }
  }
}

# AWS Provider - DR Region
provider "aws" {
  alias  = "dr"
  region = var.aws_dr_region
  
  default_tags {
    tags = {
      Environment  = var.environment
      Project      = var.project_name
      ManagedBy    = "Terraform"
      Owner        = var.owner_email
      Region       = "DR"
    }
  }
}
```

### Step 5: Network Module

**💡 Educational Note**: We'll create a reusable network module that works across both Azure and AWS, abstracting cloud-specific differences.

#### Copilot Agent Prompt:
```markdown
@workspace Create a multi-cloud network module that:

1. Creates VNet/VPC based on cloud provider
2. Manages subnets with consistent naming
3. Implements security groups/NSGs
4. Sets up routing tables
5. Configures NAT gateways/instances
6. Implements network flow logs
7. Provides consistent outputs

Include detailed comments explaining cloud networking differences.
```

#### Expected Network Module:

**modules/network/variables.tf:**
```hcl
# =====================================================
# Network Module Variables
# =====================================================

variable "cloud_provider" {
  description = "Cloud provider (azure or aws)"
  type        = string
  
  validation {
    condition     = contains(["azure", "aws"], var.cloud_provider)
    error_message = "Cloud provider must be azure or aws"
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "region" {
  description = "Cloud region"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for VNet/VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_config" {
  description = "Subnet configuration"
  type = map(object({
    cidr_block    = string
    public        = bool
    nat_gateway   = bool
  }))
  
  default = {
    public = {
      cidr_block  = "10.0.1.0/24"
      public      = true
      nat_gateway = true
    }
    private = {
      cidr_block  = "10.0.2.0/24"
      public      = false
      nat_gateway = false
    }
    database = {
      cidr_block  = "10.0.3.0/24"
      public      = false
      nat_gateway = false
    }
  }
}

variable "enable_flow_logs" {
  description = "Enable network flow logs"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

**modules/network/main.tf:**
```hcl
# =====================================================
# Multi-Cloud Network Module
# =====================================================
# This module creates networking resources for either
# Azure or AWS based on the cloud_provider variable

locals {
  # Common naming convention
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Combine tags
  common_tags = merge(
    var.tags,
    {
      Module      = "network"
      Environment = var.environment
    }
  )
}

# ==================== AZURE RESOURCES ====================
# Create resource group for Azure resources
resource "azurerm_resource_group" "network" {
  count = var.cloud_provider == "azure" ? 1 : 0
  
  name     = "rg-${local.name_prefix}-network"
  location = var.region
  tags     = local.common_tags
}

# Azure Virtual Network
resource "azurerm_virtual_network" "main" {
  count = var.cloud_provider == "azure" ? 1 : 0
  
  name                = "vnet-${local.name_prefix}"
  location            = var.region
  resource_group_name = azurerm_resource_group.network[0].name
  address_space       = [var.cidr_block]
  
  tags = local.common_tags
}

# Azure Subnets
resource "azurerm_subnet" "main" {
  for_each = var.cloud_provider == "azure" ? var.subnet_config : {}
  
  name                 = "subnet-${each.key}"
  resource_group_name  = azurerm_resource_group.network[0].name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = [each.value.cidr_block]
}

# Azure Network Security Groups
resource "azurerm_network_security_group" "main" {
  for_each = var.cloud_provider == "azure" ? var.subnet_config : {}
  
  name                = "nsg-${each.key}-${local.name_prefix}"
  location            = var.region
  resource_group_name = azurerm_resource_group.network[0].name
  
  tags = local.common_tags
}

# Azure NSG Rules - Allow internal traffic
resource "azurerm_network_security_rule" "allow_vnet" {
  for_each = var.cloud_provider == "azure" ? var.subnet_config : {}
  
  name                        = "AllowVnetInBound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = azurerm_resource_group.network[0].name
  network_security_group_name = azurerm_network_security_group.main[each.key].name
}

# Associate NSGs with Subnets
resource "azurerm_subnet_network_security_group_association" "main" {
  for_each = var.cloud_provider == "azure" ? var.subnet_config : {}
  
  subnet_id                 = azurerm_subnet.main[each.key].id
  network_security_group_id = azurerm_network_security_group.main[each.key].id
}

# ==================== AWS RESOURCES ====================
# AWS VPC
resource "aws_vpc" "main" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(
    local.common_tags,
    {
      Name = "vpc-${local.name_prefix}"
    }
  )
}

# AWS Internet Gateway
resource "aws_internet_gateway" "main" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  vpc_id = aws_vpc.main[0].id
  
  tags = merge(
    local.common_tags,
    {
      Name = "igw-${local.name_prefix}"
    }
  )
}

# AWS Subnets
resource "aws_subnet" "main" {
  for_each = var.cloud_provider == "aws" ? var.subnet_config : {}
  
  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = each.value.public
  
  # Distribute subnets across availability zones
  availability_zone = data.aws_availability_zones.available[0].names[
    index(keys(var.subnet_config), each.key) % length(data.aws_availability_zones.available[0].names)
  ]
  
  tags = merge(
    local.common_tags,
    {
      Name = "subnet-${each.key}-${local.name_prefix}"
      Type = each.value.public ? "public" : "private"
    }
  )
}

# AWS Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  for_each = var.cloud_provider == "aws" ? {
    for k, v in var.subnet_config : k => v
    if v.nat_gateway
  } : {}
  
  domain = "vpc"
  
  tags = merge(
    local.common_tags,
    {
      Name = "eip-nat-${each.key}-${local.name_prefix}"
    }
  )
}

# AWS NAT Gateways
resource "aws_nat_gateway" "main" {
  for_each = var.cloud_provider == "aws" ? {
    for k, v in var.subnet_config : k => v
    if v.nat_gateway
  } : {}
  
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.main[each.key].id
  
  tags = merge(
    local.common_tags,
    {
      Name = "nat-${each.key}-${local.name_prefix}"
    }
  )
  
  depends_on = [aws_internet_gateway.main]
}

# AWS Route Tables
resource "aws_route_table" "public" {
  count = var.cloud_provider == "aws" ? 1 : 0
  
  vpc_id = aws_vpc.main[0].id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }
  
  tags = merge(
    local.common_tags,
    {
      Name = "rt-public-${local.name_prefix}"
    }
  )
}

resource "aws_route_table" "private" {
  for_each = var.cloud_provider == "aws" ? {
    for k, v in var.subnet_config : k => v
    if !v.public
  } : {}
  
  vpc_id = aws_vpc.main[0].id
  
  tags = merge(
    local.common_tags,
    {
      Name = "rt-private-${each.key}-${local.name_prefix}"
    }
  )
}

# Add routes to NAT gateways for private subnets
resource "aws_route" "private_nat" {
  for_each = var.cloud_provider == "aws" ? {
    for k, v in var.subnet_config : k => v
    if !v.public && v.nat_gateway
  } : {}
  
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main["public"].id
}

# AWS Route Table Associations
resource "aws_route_table_association" "public" {
  for_each = var.cloud_provider == "aws" ? {
    for k, v in var.subnet_config : k => v
    if v.public
  } : {}
  
  subnet_id      = aws_subnet.main[each.key].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "private" {
  for_each = var.cloud_provider == "aws" ? {
    for k, v in var.subnet_config : k => v
    if !v.public
  } : {}
  
  subnet_id      = aws_subnet.main[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

# Data source for AWS availability zones
data "aws_availability_zones" "available" {
  count = var.cloud_provider == "aws" ? 1 : 0
  state = "available"
}
```

**modules/network/outputs.tf:**
```hcl
# =====================================================
# Network Module Outputs
# =====================================================
# Provide consistent outputs regardless of cloud provider

output "network_id" {
  description = "Network ID (VNet ID for Azure, VPC ID for AWS)"
  value = var.cloud_provider == "azure" ? (
    length(azurerm_virtual_network.main) > 0 ? azurerm_virtual_network.main[0].id : null
  ) : (
    length(aws_vpc.main) > 0 ? aws_vpc.main[0].id : null
  )
}

output "network_name" {
  description = "Network name"
  value = var.cloud_provider == "azure" ? (
    length(azurerm_virtual_network.main) > 0 ? azurerm_virtual_network.main[0].name : null
  ) : (
    length(aws_vpc.main) > 0 ? aws_vpc.main[0].id : null
  )
}

output "subnet_ids" {
  description = "Map of subnet IDs"
  value = var.cloud_provider == "azure" ? {
    for k, v in azurerm_subnet.main : k => v.id
  } : {
    for k, v in aws_subnet.main : k => v.id
  }
}

output "cidr_block" {
  description = "Network CIDR block"
  value = var.cidr_block
}

output "cloud_provider" {
  description = "Cloud provider used"
  value = var.cloud_provider
}

output "security_group_ids" {
  description = "Security group IDs (NSG IDs for Azure)"
  value = var.cloud_provider == "azure" ? {
    for k, v in azurerm_network_security_group.main : k => v.id
  } : {}
}
```

### Step 6: State Management Configuration

**💡 Educational Note**: Terraform state is critical for tracking infrastructure. We'll configure remote state storage with locking for team collaboration.

#### Copilot Agent Prompt:
```markdown
@workspace Create Terraform state management configuration that includes:

1. Azure Storage backend setup for state files
2. State locking with Azure Blob Storage
3. Encryption at rest
4. State file organization per environment
5. Migration strategy from local to remote state
6. Backup and recovery procedures

Explain why remote state is critical for team collaboration.
```

#### Expected State Configuration:

**scripts/setup-backend.sh:**
```bash
#!/bin/bash
# =====================================================
# Setup Terraform Backend in Azure
# =====================================================
# This script creates the required Azure resources for
# storing Terraform state files securely

set -euo pipefail

# Configuration
RESOURCE_GROUP="rg-terraform-state"
STORAGE_ACCOUNT="stterraform${RANDOM}"
CONTAINER_NAME="tfstate"
LOCATION="eastus2"

echo "🚀 Setting up Terraform backend in Azure..."

# Create resource group
echo "Creating resource group..."
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --tags Purpose=TerraformState ManagedBy=Script

# Create storage account
echo "Creating storage account..."
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --tags Purpose=TerraformState

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT \
  --query '[0].value' -o tsv)

# Create blob container
echo "Creating blob container..."
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT \
  --account-key $ACCOUNT_KEY \
  --public-access off

# Enable versioning and soft delete
echo "Configuring blob service properties..."
az storage account blob-service-properties update \
  --account-name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 7

echo "✅ Backend setup complete!"
echo ""
echo "Add this to your backend.tf:"
echo "terraform {"
echo "  backend \"azurerm\" {"
echo "    resource_group_name  = \"$RESOURCE_GROUP\""
echo "    storage_account_name = \"$STORAGE_ACCOUNT\""
echo "    container_name       = \"$CONTAINER_NAME\""
echo "    key                  = \"<environment>.tfstate\""
echo "  }"
echo "}"
```

**environments/dev/backend.tf:**
```hcl
# =====================================================
# Terraform Backend Configuration
# =====================================================
# Store state in Azure Storage with encryption and locking

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformXXXXX" # Replace with actual
    container_name       = "tfstate"
    key                  = "dev.tfstate"
    
    # These ensure state is encrypted and locked
    use_azuread_auth = true  # Use Azure AD auth instead of keys
  }
}
```

### Step 7: Main Infrastructure Configuration

**💡 Educational Note**: Now we'll tie everything together in the main configuration, using our modules to create multi-cloud infrastructure.

#### Copilot Agent Prompt:
```markdown
@workspace Create the main Terraform configuration for the dev environment that:

1. Uses the network module for both Azure and AWS
2. Creates storage resources in both clouds
3. Sets up cross-cloud connectivity
4. Implements monitoring and logging
5. Configures cost alerts
6. Uses data sources for existing resources

Include comments explaining multi-cloud patterns.
```

#### Expected Main Configuration:

**environments/dev/main.tf:**
```hcl
# =====================================================
# Multi-Cloud Infrastructure - Development Environment
# =====================================================
# This configuration creates infrastructure in both
# Azure and AWS with cross-cloud connectivity

locals {
  project_name = "multicloud"
  environment  = "dev"
  
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner_email
    CostCenter  = var.cost_center
  }
}

# ==================== AZURE INFRASTRUCTURE ====================
# Azure Network
module "azure_network" {
  source = "../../modules/network"
  
  cloud_provider = "azure"
  environment    = local.environment
  project_name   = local.project_name
  region         = var.azure_primary_region
  cidr_block     = var.azure_cidr_block
  
  subnet_config = {
    public = {
      cidr_block  = cidrsubnet(var.azure_cidr_block, 8, 1)
      public      = true
      nat_gateway = false
    }
    private = {
      cidr_block  = cidrsubnet(var.azure_cidr_block, 8, 2)
      public      = false
      nat_gateway = false
    }
    database = {
      cidr_block  = cidrsubnet(var.azure_cidr_block, 8, 3)
      public      = false
      nat_gateway = false
    }
  }
  
  enable_flow_logs = var.enable_flow_logs
  tags            = local.common_tags
}

# ==================== AWS INFRASTRUCTURE ====================
# AWS Network
module "aws_network" {
  source = "../../modules/network"
  
  cloud_provider = "aws"
  environment    = local.environment
  project_name   = local.project_name
  region         = var.aws_primary_region
  cidr_block     = var.aws_cidr_block
  
  subnet_config = {
    public = {
      cidr_block  = cidrsubnet(var.aws_cidr_block, 8, 1)
      public      = true
      nat_gateway = true
    }
    private = {
      cidr_block  = cidrsubnet(var.aws_cidr_block, 8, 2)
      public      = false
      nat_gateway = false
    }
    database = {
      cidr_block  = cidrsubnet(var.aws_cidr_block, 8, 3)
      public      = false
      nat_gateway = false
    }
  }
  
  enable_flow_logs = var.enable_flow_logs
  tags            = local.common_tags
}

# ==================== CROSS-CLOUD CONNECTIVITY ====================
# This section would implement VPN or private connectivity between clouds
# For this example, we'll create the foundation for Site-to-Site VPN

# Azure VPN Gateway Public IP
resource "azurerm_public_ip" "vpn_gateway" {
  name                = "pip-vpn-${local.project_name}-${local.environment}"
  location            = var.azure_primary_region
  resource_group_name = azurerm_resource_group.connectivity.name
  allocation_method   = "Static"
  sku                = "Standard"
  
  tags = local.common_tags
}

# Azure Resource Group for Connectivity
resource "azurerm_resource_group" "connectivity" {
  name     = "rg-connectivity-${local.project_name}-${local.environment}"
  location = var.azure_primary_region
  tags     = local.common_tags
}

# AWS Customer Gateway (representing Azure VPN)
resource "aws_customer_gateway" "azure" {
  bgp_asn    = 65000
  ip_address = azurerm_public_ip.vpn_gateway.ip_address
  type       = "ipsec.1"
  
  tags = merge(
    local.common_tags,
    {
      Name = "cgw-azure-${local.project_name}-${local.environment}"
    }
  )
}

# ==================== MONITORING ====================
# Create unified monitoring across both clouds

# Azure Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${local.project_name}-${local.environment}"
  location            = var.azure_primary_region
  resource_group_name = azurerm_resource_group.monitoring.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  
  tags = local.common_tags
}

# Azure Resource Group for Monitoring
resource "azurerm_resource_group" "monitoring" {
  name     = "rg-monitoring-${local.project_name}-${local.environment}"
  location = var.azure_primary_region
  tags     = local.common_tags
}

# AWS CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/multicloud/${local.environment}"
  retention_in_days = 30
  
  tags = local.common_tags
}

# ==================== COST MANAGEMENT ====================
# Set up cost alerts for both clouds

# Azure Consumption Budget
resource "azurerm_consumption_budget_subscription" "main" {
  name            = "budget-${local.project_name}-${local.environment}"
  subscription_id = data.azurerm_subscription.current.id
  
  amount     = var.azure_budget_amount
  time_grain = "Monthly"
  
  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
    end_date   = timeadd(formatdate("YYYY-MM-01'T'00:00:00Z", timestamp()), "8760h") # 1 year
  }
  
  notification {
    enabled   = true
    threshold = 80
    operator  = "GreaterThan"
    
    contact_emails = [var.owner_email]
  }
  
  notification {
    enabled   = true
    threshold = 100
    operator  = "GreaterThan"
    
    contact_emails = [var.owner_email]
  }
}

# AWS Budget
resource "aws_budgets_budget" "main" {
  name         = "budget-${local.project_name}-${local.environment}"
  budget_type  = "COST"
  limit_amount = var.aws_budget_amount
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.owner_email]
  }
}

# ==================== DATA SOURCES ====================
# Reference existing resources

data "azurerm_subscription" "current" {}

data "aws_caller_identity" "current" {}
```

### Step 8: Variables and Outputs

#### Copilot Agent Prompt:
```markdown
@workspace Create comprehensive variables and outputs files for the dev environment that:

1. Define all required variables with descriptions and validations
2. Include sensitive variable handling
3. Create tfvars example file
4. Define outputs for resource information
5. Include output descriptions and sensitive markings

Explain variable organization best practices.
```

#### Expected Variables and Outputs:

**environments/dev/variables.tf:**
```hcl
# =====================================================
# Development Environment Variables
# =====================================================

# General Variables
variable "owner_email" {
  description = "Email address of the infrastructure owner"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.owner_email))
    error_message = "Must be a valid email address"
  }
}

variable "cost_center" {
  description = "Cost center for billing purposes"
  type        = string
}

# Azure Variables
variable "azure_primary_region" {
  description = "Primary Azure region"
  type        = string
  default     = "eastus2"
}

variable "azure_cidr_block" {
  description = "CIDR block for Azure VNet"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.azure_cidr_block, 0))
    error_message = "Must be a valid CIDR block"
  }
}

variable "azure_budget_amount" {
  description = "Monthly budget amount for Azure in USD"
  type        = number
  default     = 100
}

# AWS Variables
variable "aws_primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_dr_region" {
  description = "AWS disaster recovery region"
  type        = string
  default     = "us-west-2"
}

variable "aws_cidr_block" {
  description = "CIDR block for AWS VPC"
  type        = string
  default     = "10.1.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.aws_cidr_block, 0))
    error_message = "Must be a valid CIDR block"
  }
}

variable "aws_budget_amount" {
  description = "Monthly budget amount for AWS in USD"
  type        = string
  default     = "100"
}

# Feature Flags
variable "enable_flow_logs" {
  description = "Enable network flow logs"
  type        = bool
  default     = true
}

variable "enable_cross_cloud_vpn" {
  description = "Enable VPN connection between Azure and AWS"
  type        = bool
  default     = false
}

# Sensitive Variables
variable "vpn_shared_key" {
  description = "Shared key for VPN connection"
  type        = string
  sensitive   = true
  default     = ""
}
```

**environments/dev/terraform.tfvars.example:**
```hcl
# =====================================================
# Development Environment Configuration
# =====================================================
# Copy this file to terraform.tfvars and fill in values

# Required Variables
owner_email = "your.email@company.com"
cost_center = "TECH-001"

# Azure Configuration
azure_primary_region = "eastus2"
azure_cidr_block    = "10.0.0.0/16"
azure_budget_amount = 100

# AWS Configuration
aws_primary_region = "us-east-1"
aws_dr_region     = "us-west-2"
aws_cidr_block    = "10.1.0.0/16"
aws_budget_amount = "100"

# Feature Flags
enable_flow_logs       = true
enable_cross_cloud_vpn = false

# Sensitive Variables (use environment variables or secrets)
# export TF_VAR_vpn_shared_key="your-secure-key"
```

**environments/dev/outputs.tf:**
```hcl
# =====================================================
# Development Environment Outputs
# =====================================================

# Network Outputs
output "azure_network_id" {
  description = "Azure VNet ID"
  value       = module.azure_network.network_id
}

output "azure_subnet_ids" {
  description = "Azure subnet IDs"
  value       = module.azure_network.subnet_ids
}

output "aws_network_id" {
  description = "AWS VPC ID"
  value       = module.aws_network.network_id
}

output "aws_subnet_ids" {
  description = "AWS subnet IDs"
  value       = module.aws_network.subnet_ids
}

# Monitoring Outputs
output "azure_log_analytics_workspace_id" {
  description = "Azure Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "aws_cloudwatch_log_group" {
  description = "AWS CloudWatch Log Group name"
  value       = aws_cloudwatch_log_group.main.name
}

# Connectivity Outputs
output "azure_vpn_gateway_ip" {
  description = "Azure VPN Gateway public IP"
  value       = azurerm_public_ip.vpn_gateway.ip_address
}

# Cost Management
output "monthly_budgets" {
  description = "Monthly budget amounts by cloud"
  value = {
    azure = var.azure_budget_amount
    aws   = var.aws_budget_amount
    total = var.azure_budget_amount + tonumber(var.aws_budget_amount)
  }
}
```

### Step 9: Deployment Scripts

**💡 Educational Note**: Automation scripts help standardize deployments and reduce errors. We'll create scripts for common Terraform operations.

#### Copilot Agent Prompt:
```markdown
@workspace Create deployment automation scripts that:

1. Initialize Terraform with backend configuration
2. Plan with cost estimation
3. Apply with approval process
4. Destroy with safety checks
5. State management operations
6. Multi-environment deployment

Include error handling and logging.
```

#### Expected Deployment Scripts:

**scripts/deploy.sh:**
```bash
#!/bin/bash
# =====================================================
# Terraform Deployment Script
# =====================================================
# This script handles Terraform deployments with
# safety checks and cost estimation

set -euo pipefail

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Parse arguments
ENVIRONMENT="${1:-dev}"
ACTION="${2:-plan}"

# Validate environment
if [[ ! -d "$ROOT_DIR/environments/$ENVIRONMENT" ]]; then
    log_error "Environment '$ENVIRONMENT' not found"
    exit 1
fi

# Change to environment directory
cd "$ROOT_DIR/environments/$ENVIRONMENT"

# Initialize Terraform
log_info "Initializing Terraform..."
terraform init -upgrade

# Format check
log_info "Checking Terraform formatting..."
terraform fmt -check -recursive || {
    log_warn "Formatting issues found. Run 'terraform fmt -recursive'"
}

# Validate configuration
log_info "Validating Terraform configuration..."
terraform validate

# Run tflint
if command -v tflint &> /dev/null; then
    log_info "Running TFLint..."
    tflint --init
    tflint
fi

# Run security scan
if command -v tfsec &> /dev/null; then
    log_info "Running security scan..."
    tfsec . --soft-fail
fi

# Execute action
case $ACTION in
    "plan")
        log_info "Creating Terraform plan..."
        terraform plan -out=tfplan
        
        # Cost estimation
        if command -v infracost &> /dev/null; then
            log_info "Estimating costs..."
            infracost breakdown --path tfplan
        fi
        ;;
        
    "apply")
        log_info "Applying Terraform changes..."
        
        # Check if plan exists
        if [[ ! -f tfplan ]]; then
            log_error "No plan file found. Run 'deploy.sh $ENVIRONMENT plan' first"
            exit 1
        fi
        
        # Show plan summary
        terraform show -no-color tfplan | grep -E "^  # |^Plan:"
        
        # Confirm
        read -p "Do you want to apply these changes? (yes/no): " -r
        if [[ $REPLY == "yes" ]]; then
            terraform apply tfplan
            rm -f tfplan
            log_info "Deployment complete!"
        else
            log_warn "Deployment cancelled"
        fi
        ;;
        
    "destroy")
        log_warn "Preparing to DESTROY infrastructure..."
        
        # Show resources
        terraform state list
        
        # Double confirmation
        read -p "Are you SURE you want to destroy? Type 'destroy-$ENVIRONMENT': " -r
        if [[ $REPLY == "destroy-$ENVIRONMENT" ]]; then
            terraform destroy -auto-approve
            log_info "Infrastructure destroyed"
        else
            log_warn "Destroy cancelled"
        fi
        ;;
        
    *)
        log_error "Unknown action: $ACTION"
        echo "Usage: $0 <environment> <plan|apply|destroy>"
        exit 1
        ;;
esac
```

### Step 10: Testing Infrastructure

#### Copilot Agent Prompt:
```markdown
@workspace Create infrastructure tests using Terratest that:

1. Test network module for both Azure and AWS
2. Verify resource creation
3. Test connectivity between resources
4. Validate security rules
5. Test tagging compliance
6. Performance testing setup

Include Go test files and documentation.
```

#### Expected Test Implementation:

**tests/network_test.go:**
```go
// =====================================================
// Network Module Tests
// =====================================================
// Test the network module across both cloud providers

package test

import (
    "testing"
    "fmt"
    
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/gruntwork-io/terratest/modules/azure"
    "github.com/gruntwork-io/terratest/modules/aws"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestNetworkModule(t *testing.T) {
    t.Parallel()
    
    // Test both Azure and AWS
    providers := []string{"azure", "aws"}
    
    for _, provider := range providers {
        provider := provider // Capture range variable
        
        t.Run(fmt.Sprintf("NetworkModule_%s", provider), func(t *testing.T) {
            t.Parallel()
            
            // Configure Terraform options
            terraformOptions := &terraform.Options{
                TerraformDir: "../modules/network",
                Vars: map[string]interface{}{
                    "cloud_provider": provider,
                    "environment":    "test",
                    "project_name":   "terratest",
                    "region":         getTestRegion(provider),
                    "cidr_block":     "10.99.0.0/16",
                },
                NoColor: true,
            }
            
            // Clean up resources
            defer terraform.Destroy(t, terraformOptions)
            
            // Deploy infrastructure
            terraform.InitAndApply(t, terraformOptions)
            
            // Get outputs
            networkID := terraform.Output(t, terraformOptions, "network_id")
            subnetIDs := terraform.OutputMap(t, terraformOptions, "subnet_ids")
            
            // Verify resources exist
            assert.NotEmpty(t, networkID)
            assert.NotEmpty(t, subnetIDs)
            
            // Provider-specific validations
            if provider == "azure" {
                testAzureNetwork(t, terraformOptions)
            } else {
                testAWSNetwork(t, terraformOptions)
            }
        })
    }
}

func testAzureNetwork(t *testing.T, opts *terraform.Options) {
    // Azure-specific tests
    networkName := terraform.Output(t, opts, "network_name")
    
    // Verify VNet exists
    exists := azure.VirtualNetworkExists(t, networkName, "")
    assert.True(t, exists, "Azure VNet should exist")
}

func testAWSNetwork(t *testing.T, opts *terraform.Options) {
    // AWS-specific tests
    vpcID := terraform.Output(t, opts, "network_id")
    
    // Verify VPC exists
    vpc := aws.GetVpcById(t, vpcID, "us-east-1")
    assert.NotNil(t, vpc, "AWS VPC should exist")
}

func getTestRegion(provider string) string {
    if provider == "azure" {
        return "eastus2"
    }
    return "us-east-1"
}
```

---

## 🚀 Challenge: Multi-Cloud Disaster Recovery

### Final Challenge Prompt:

#### Copilot Agent Prompt:
```markdown
@workspace Create a complete disaster recovery solution that:

1. Implements cross-cloud data replication
2. Automated failover procedures
3. RTO/RPO monitoring
4. Cost-optimized DR resources
5. Regular DR testing automation
6. Documentation and runbooks

This should work across both Azure and AWS with minimal manual intervention.
```

---

## 📚 Key Learnings from Exercise 2

### Terraform Fundamentals Mastered
1. **Provider Management**: Handling multiple cloud providers
2. **Module Development**: Creating reusable components
3. **State Management**: Remote state with locking
4. **Resource Dependencies**: Understanding implicit/explicit dependencies
5. **Data Sources**: Using existing resources

### Multi-Cloud Patterns Applied
1. **Consistent Naming**: Across different cloud conventions
2. **Network Architecture**: Cloud-agnostic network design
3. **Security Baseline**: Consistent security across clouds
4. **Cost Management**: Unified budget controls
5. **Monitoring Strategy**: Centralized observability

### Best Practices Implemented
1. **Environment Separation**: Isolated state per environment
2. **Version Control**: Everything in Git
3. **Automated Testing**: Infrastructure validation
4. **Documentation**: Self-documenting code
5. **Security Scanning**: Automated compliance checks

## 🎯 Next Steps

You've successfully completed Exercise 2! You now understand:
- Terraform fundamentals and HCL
- Multi-cloud infrastructure patterns
- Module development and reusability
- State management strategies
- Infrastructure testing

Continue to Exercise 3 where you'll implement GitOps pipelines for automated infrastructure deployment!

**Remember**: Infrastructure as Code is about consistency and automation. Every manual step is a potential failure point.