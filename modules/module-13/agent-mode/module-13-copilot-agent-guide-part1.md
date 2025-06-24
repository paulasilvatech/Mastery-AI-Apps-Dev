# Module 13 - Complete GitHub Copilot Agent Guide
## Part 1: Infrastructure as Code Fundamentals & Exercise 1 (Azure Bicep)

### 🎯 Learning Objectives

In this comprehensive guide, you'll learn:
- Infrastructure as Code (IaC) principles and why they matter
- How to use GitHub Copilot Agent Mode for infrastructure development
- Azure Bicep fundamentals and advanced patterns
- GitOps workflows for infrastructure automation
- Best practices for secure, scalable infrastructure

### 🤖 Understanding IaC with GitHub Copilot

**What is Infrastructure as Code?**
- Define and manage infrastructure through code instead of manual processes
- Version control your infrastructure like application code
- Automate deployment and ensure consistency
- Enable collaboration and review processes

**Why use Copilot for IaC?**
- Generate complex templates quickly
- Learn cloud service configurations
- Implement security best practices
- Create reusable modules

---

## 📚 Module 13 Overview: Infrastructure as Code

In this module, you'll master three critical skills:
1. **Exercise 1**: Azure Bicep for native Azure IaC
2. **Exercise 2**: Terraform for multi-cloud infrastructure
3. **Exercise 3**: GitOps pipelines for automated deployment

Let's start with understanding IaC fundamentals.

---

## 🚀 Initial Setup: Preparing Your IaC Environment

### Step 1: Create Your IaC Repository

**💡 Educational Note**: We'll create a dedicated repository for infrastructure code. This separation allows different teams to manage application and infrastructure code independently while maintaining clear boundaries.

#### Copilot Agent Prompt:
```markdown
@workspace Create a comprehensive setup guide for an Infrastructure as Code repository. Include:

1. Repository creation steps for "infrastructure-as-code-workshop"
2. Directory structure following best practices for IaC projects
3. Essential configuration files (.gitignore, README.md, .editorconfig)
4. Pre-commit hooks for IaC validation
5. Documentation structure for infrastructure
6. Security considerations for IaC repositories

Explain why we separate infrastructure from application code and the benefits of this approach.
```

#### Expected Output:
```markdown
# Infrastructure as Code Repository Setup

## Why Separate Infrastructure Repository?

1. **Clear Ownership**: Infrastructure teams can manage independently
2. **Security**: Different access controls for infrastructure vs application
3. **Audit Trail**: Clear history of infrastructure changes
4. **Reusability**: Share infrastructure modules across projects
5. **Compliance**: Easier to enforce infrastructure policies

## Repository Creation

1. Create new repository: `infrastructure-as-code-workshop`
2. Description: "Infrastructure as Code with Bicep, Terraform, and GitOps"
3. Initialize with:
   - ✅ README.md
   - ✅ .gitignore (Terraform template)
   - ✅ MIT License (for learning)
   - ⚠️ Set to Private (infrastructure code is sensitive)

## Initial Repository Structure
```
infrastructure-as-code-workshop/
├── .github/
│   ├── workflows/           # CI/CD pipelines
│   ├── CODEOWNERS          # Who owns what infrastructure
│   └── pull_request_template.md
├── bicep/                   # Exercise 1: Azure Bicep
│   ├── modules/            # Reusable Bicep modules
│   ├── environments/       # Environment-specific configs
│   └── scripts/           # Deployment scripts
├── terraform/              # Exercise 2: Terraform
│   ├── modules/           # Reusable Terraform modules
│   ├── environments/      # Environment configurations
│   └── backend/          # State storage config
├── gitops/                # Exercise 3: GitOps configs
│   ├── applications/      # App deployments
│   ├── infrastructure/    # Infra deployments
│   └── policies/         # Policy definitions
├── scripts/               # Utility scripts
│   ├── setup-local.sh    # Local environment setup
│   ├── validate-all.sh   # Validate all IaC
│   └── cost-estimate.sh  # Estimate costs
├── docs/                  # Documentation
│   ├── architecture/      # Architecture decisions
│   ├── runbooks/         # Operational procedures
│   └── disaster-recovery/ # DR plans
├── tests/                 # Infrastructure tests
├── .gitignore            # IaC-specific ignores
├── .pre-commit-config.yaml # Pre-commit hooks
└── README.md             # Project overview
```

## Essential .gitignore for IaC
```gitignore
# Terraform
*.tfstate
*.tfstate.*
**/.terraform/*
*.tfvars
!*.tfvars.example
crash.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Bicep
*.azrm.json

# Environment files
.env
.env.*
!.env.example

# Cloud credentials
**/credentials
**/credentials.json
**/.aws/
**/.azure/

# OS files
.DS_Store
Thumbs.db

# IDE
.vscode/*
!.vscode/extensions.json
!.vscode/settings.json.example
.idea/

# Logs
*.log
logs/

# Temporary files
*.tmp
*.temp
*.bak
```

## Pre-commit Configuration
```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_docs
      - id: terraform_tflint
      
  - repo: https://github.com/Azure/bicep
    rev: v0.23.1
    hooks:
      - id: bicep-build
      - id: bicep-format
      
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: detect-private-key
      - id: check-merge-conflict
```

## Security Best Practices
1. **Never commit secrets** - Use secret management services
2. **Enable branch protection** - Require reviews for main
3. **Use signed commits** - Verify infrastructure changes
4. **Implement CODEOWNERS** - Control who can modify what
5. **Regular security scans** - Check for misconfigurations
```

### Step 2: Install Required Tools

**💡 Educational Note**: Unlike application development, IaC requires specific CLI tools for each platform. We'll install everything needed for all three exercises.

#### Copilot Agent Prompt:
```markdown
@workspace Create a comprehensive tool installation guide that covers:

1. Azure CLI and Bicep installation for all platforms (Windows, macOS, Linux, Codespaces)
2. Terraform installation with version management
3. Additional tools: tflint, terraform-docs, checkov
4. VS Code extensions for IaC development
5. Authentication setup for Azure
6. Verification commands to ensure everything works

Include troubleshooting steps for common installation issues and explain why each tool is necessary.
```

#### Expected Output:
```markdown
# IaC Tools Installation Guide

## Required Tools Overview

| Tool | Purpose | Required For |
|------|---------|--------------|
| Azure CLI | Azure service management | All exercises |
| Bicep CLI | Compile Bicep to ARM | Exercise 1 |
| Terraform | Multi-cloud IaC | Exercise 2 |
| tflint | Terraform linting | Exercise 2 |
| terraform-docs | Generate documentation | Exercise 2 |
| Checkov | Security scanning | All exercises |
| Git | Version control | All exercises |

## Platform-Specific Installation

### Option 1: GitHub Codespaces (Recommended)
```bash
# Create a .devcontainer/devcontainer.json
{
  "name": "IaC Development",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/azure-cli:1": {
      "version": "latest"
    },
    "ghcr.io/devcontainers/features/terraform:1": {
      "version": "1.6",
      "tflint": "latest",
      "terragrunt": "latest"
    },
    "ghcr.io/devcontainers/features/python:1": {
      "version": "3.11"
    }
  },
  "postCreateCommand": "bash scripts/setup-codespace.sh",
  "customizations": {
    "vscode": {
      "extensions": [
        "hashicorp.terraform",
        "ms-azuretools.vscode-bicep",
        "ms-azuretools.vscode-azureresourcemanager",
        "github.copilot",
        "github.copilot-chat"
      ]
    }
  }
}
```

### Option 2: Windows Installation
```powershell
# Using PowerShell as Administrator

# 1. Install Chocolatey (if not installed)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 2. Install Azure CLI
choco install azure-cli -y

# 3. Install Bicep
az bicep install
az bicep upgrade

# 4. Install Terraform
choco install terraform -y

# 5. Install additional tools
choco install python -y
pip install checkov terraform-docs

# 6. Install VS Code extensions
code --install-extension hashicorp.terraform
code --install-extension ms-azuretools.vscode-bicep
code --install-extension ms-azuretools.vscode-azureresourcemanager
code --install-extension github.copilot
code --install-extension github.copilot-chat
```

### Option 3: macOS Installation
```bash
# Using Homebrew

# 1. Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install Azure CLI
brew update && brew install azure-cli

# 3. Install Bicep
az bicep install
az bicep upgrade

# 4. Install Terraform
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# 5. Install additional tools
brew install tflint terraform-docs
pip3 install checkov

# 6. Install VS Code extensions (if VS Code installed via brew)
code --install-extension hashicorp.terraform
code --install-extension ms-azuretools.vscode-bicep
```

### Option 4: Linux (Ubuntu/Debian)
```bash
# 1. Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# 2. Install Bicep
az bicep install
az bicep upgrade

# 3. Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install terraform

# 4. Install additional tools
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
pip3 install checkov terraform-docs
```

## Tool Verification
```bash
# Run these commands to verify installation
az --version              # Azure CLI
az bicep version          # Bicep CLI
terraform version         # Terraform
tflint --version         # TFLint
terraform-docs --version # Terraform Docs
checkov --version        # Checkov

# Verify Azure authentication
az login                  # Browser-based login
az account show          # Show current subscription
```

## VS Code Configuration
Create `.vscode/settings.json`:
```json
{
  "files.associations": {
    "*.bicep": "bicep",
    "*.tf": "terraform",
    "*.tfvars": "terraform"
  },
  "terraform.languageServer": {
    "enable": true
  },
  "bicep.enableLanguageServer": true,
  "[bicep]": {
    "editor.defaultFormatter": "ms-azuretools.vscode-bicep"
  },
  "[terraform]": {
    "editor.defaultFormatter": "hashicorp.terraform"
  },
  "editor.formatOnSave": true
}
```

## Why Each Tool Matters

1. **Azure CLI**: Manages Azure resources and authenticates deployments
2. **Bicep**: Simpler syntax than ARM templates, native Azure support
3. **Terraform**: Multi-cloud support, large ecosystem
4. **Linting Tools**: Catch errors before deployment
5. **Checkov**: Security scanning prevents misconfigurations
6. **Documentation Tools**: Keep infrastructure documented
```

### Step 3: Azure Environment Setup

**💡 Educational Note**: Before deploying infrastructure, we need to set up our Azure environment properly. This includes creating resource groups, setting up proper naming conventions, and understanding Azure's organizational structure.

#### Copilot Agent Prompt:
```markdown
@workspace Create an Azure environment setup guide that includes:

1. Azure subscription setup and verification
2. Resource group creation strategy
3. Naming conventions following Azure best practices
4. Tag strategy for resource organization
5. Cost management setup with budgets and alerts
6. Service principal creation for automation
7. Role-based access control (RBAC) setup

Explain Azure's resource hierarchy and why proper organization matters for enterprise environments.
```

#### Expected Output:
```markdown
# Azure Environment Setup Guide

## Azure Resource Hierarchy

```
Management Group
└── Subscription
    └── Resource Group
        └── Resources (VMs, Storage, etc.)
```

**Why This Matters:**
- **Management Groups**: Organize multiple subscriptions
- **Subscriptions**: Billing and access boundary
- **Resource Groups**: Lifecycle and permissions boundary
- **Resources**: Actual Azure services

## Initial Setup Script
```bash
#!/bin/bash
# setup-azure-environment.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Setting up Azure environment for IaC workshop${NC}"

# 1. Verify Azure login
echo -e "${YELLOW}Checking Azure authentication...${NC}"
if ! az account show &>/dev/null; then
    echo -e "${RED}Not logged in to Azure. Running 'az login'...${NC}"
    az login
fi

# 2. Display current subscription
CURRENT_SUB=$(az account show --query name -o tsv)
echo -e "${GREEN}Current subscription: $CURRENT_SUB${NC}"

# 3. Create resource groups for different environments
LOCATION="eastus2"
BASE_NAME="iac-workshop"

echo -e "${YELLOW}Creating resource groups...${NC}"
for ENV in dev staging prod; do
    RG_NAME="rg-${BASE_NAME}-${ENV}"
    echo -e "Creating resource group: $RG_NAME"
    
    az group create \
        --name $RG_NAME \
        --location $LOCATION \
        --tags Environment=$ENV Project=IaCWorkshop ManagedBy=Bicep CostCenter=Training
done

# 4. Set up cost management
echo -e "${YELLOW}Setting up cost alerts...${NC}"
# Note: Requires Cost Management Reader role
BUDGET_NAME="budget-${BASE_NAME}"
az consumption budget create \
    --amount 100 \
    --budget-name $BUDGET_NAME \
    --category Cost \
    --time-grain Monthly \
    --start-date $(date +%Y-%m-01) \
    --end-date $(date -d "next year" +%Y-%m-01) \
    --resource-group "rg-${BASE_NAME}-dev" \
    --notifications-enabled true \
    --notification-threshold 80 \
    --notification-email your-email@example.com \
    2>/dev/null || echo "Cost budget already exists or insufficient permissions"
```

## Naming Conventions

### Resource Naming Pattern
```
{resource-type}-{workload/app}-{environment}-{region}-{instance}
```

### Examples:
- **Resource Group**: `rg-iacworkshop-prod-eastus2`
- **Virtual Network**: `vnet-iacworkshop-prod-eastus2-001`
- **Storage Account**: `stiacworkshopprodeus2001` (no hyphens)
- **App Service**: `app-iacworkshop-prod-eastus2-001`

### Resource Type Prefixes:
```
rg-     Resource Group
vnet-   Virtual Network
snet-   Subnet
pip-    Public IP
nsg-    Network Security Group
vm-     Virtual Machine
vmss-   VM Scale Set
st      Storage Account (no hyphens)
app-    App Service
plan-   App Service Plan
kv-     Key Vault
sql-    SQL Database
```

## Tagging Strategy

### Required Tags:
```json
{
  "Environment": "dev|staging|prod",
  "Project": "ProjectName",
  "Owner": "email@company.com",
  "CostCenter": "CC-1234",
  "ManagedBy": "Terraform|Bicep|Portal",
  "CreatedDate": "2024-01-15",
  "ExpiryDate": "2024-12-31"
}
```

### Tag Policy Implementation:
```json
{
  "properties": {
    "displayName": "Require Environment tag",
    "policyType": "Custom",
    "mode": "Indexed",
    "parameters": {
      "allowedEnvironments": {
        "type": "Array",
        "metadata": {
          "displayName": "Allowed environments",
          "description": "The list of allowed environments"
        },
        "defaultValue": ["dev", "staging", "prod"]
      }
    },
    "policyRule": {
      "if": {
        "not": {
          "field": "tags['Environment']",
          "in": "[parameters('allowedEnvironments')]"
        }
      },
      "then": {
        "effect": "deny"
      }
    }
  }
}
```

## Service Principal Setup
```bash
# Create service principal for automation
SP_NAME="sp-iac-workshop"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create SP with Contributor role
az ad sp create-for-rbac \
    --name $SP_NAME \
    --role Contributor \
    --scopes /subscriptions/$SUBSCRIPTION_ID \
    --sdk-auth > azure-credentials.json

echo -e "${YELLOW}⚠️  Save azure-credentials.json securely!${NC}"
echo -e "${YELLOW}⚠️  Add to GitHub Secrets as AZURE_CREDENTIALS${NC}"
echo -e "${RED}⚠️  Delete local file after saving to secrets!${NC}"
```

## RBAC Best Practices

### Principle of Least Privilege
```bash
# Create custom role for IaC deployments
az role definition create --role-definition '{
  "Name": "IaC Deployment Operator",
  "Description": "Can deploy infrastructure but not access data",
  "Actions": [
    "Microsoft.Resources/deployments/*",
    "Microsoft.Resources/subscriptions/resourceGroups/*",
    "Microsoft.Web/sites/*",
    "Microsoft.Storage/storageAccounts/*",
    "Microsoft.Network/*",
    "Microsoft.Compute/virtualMachines/*"
  ],
  "NotActions": [
    "Microsoft.Storage/storageAccounts/listKeys/action",
    "Microsoft.Storage/storageAccounts/regenerateKey/action"
  ],
  "AssignableScopes": [
    "/subscriptions/${SUBSCRIPTION_ID}"
  ]
}'
```
```

---

## 🛠️ Exercise 1: Azure Bicep Fundamentals

### Understanding Bicep

**💡 Educational Note**: Bicep is Azure's domain-specific language (DSL) for deploying Azure resources. It's a transparent abstraction over ARM templates, offering cleaner syntax while maintaining the same capabilities.

#### Copilot Agent Prompt:
```markdown
@workspace Explain Azure Bicep fundamentals and create a learning progression:

1. What is Bicep and why use it over ARM templates?
2. Bicep syntax basics with examples
3. Key concepts: parameters, variables, resources, outputs
4. Type system and intellisense benefits
5. Comparison with Terraform
6. When to use Bicep vs other IaC tools

Create a simple "Hello World" Bicep example that demonstrates core concepts.
```

#### Expected Output:
```markdown
# Azure Bicep Fundamentals

## What is Bicep?

Bicep is a declarative language for deploying Azure resources. Think of it as a more human-friendly way to write ARM templates.

### ARM Template (JSON):
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "storageAccountName": {
      "type": "string"
    }
  },
  "resources": [
    {
      "type": "Microsoft.Storage/storageAccounts",
      "apiVersion": "2021-04-01",
      "name": "[parameters('storageAccountName')]",
      "location": "[resourceGroup().location]",
      "sku": {
        "name": "Standard_LRS"
      },
      "kind": "StorageV2"
    }
  ]
}
```

### Same in Bicep:
```bicep
param storageAccountName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}
```

## Why Bicep?

1. **Simpler Syntax**: 50-70% less code than ARM
2. **Type Safety**: Compile-time validation
3. **Intellisense**: Full IDE support
4. **Modularity**: Easy to create reusable modules
5. **No State Management**: Unlike Terraform, no state file needed
6. **Native Azure**: First-class support for all Azure services

## Hello World Example

```bicep
// hello-world.bicep
// This example demonstrates all core Bicep concepts

// === PARAMETERS ===
// Parameters are inputs to your template
@description('Name of the storage account')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('The environment for resources')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

// === VARIABLES ===
// Variables are computed values used in the template
var storageSkuMap = {
  dev: 'Standard_LRS'
  staging: 'Standard_GRS'
  prod: 'Standard_RAGRS'
}

var tags = {
  Environment: environment
  ManagedBy: 'Bicep'
  CreatedOn: utcNow('yyyy-MM-dd')
}

// === RESOURCES ===
// Resources are the Azure services you want to create
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: storageSkuMap[environment]
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// === OUTPUTS ===
// Outputs are values returned after deployment
output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output primaryEndpoint string = storageAccount.properties.primaryEndpoints.blob
```

## Deploying Your First Bicep Template

```bash
# 1. Create resource group
az group create --name rg-bicep-demo --location eastus2

# 2. Deploy the template
az deployment group create \
  --resource-group rg-bicep-demo \
  --template-file hello-world.bicep \
  --parameters storageAccountName=stbicepdemo123 environment=dev

# 3. View outputs
az deployment group show \
  --resource-group rg-bicep-demo \
  --name hello-world \
  --query properties.outputs
```

## Bicep vs Terraform

| Feature | Bicep | Terraform |
|---------|-------|-----------|
| **Cloud Support** | Azure only | Multi-cloud |
| **State Management** | No state file | Requires state file |
| **Language** | DSL for Azure | HCL (HashiCorp Configuration Language) |
| **Learning Curve** | Easier for Azure users | Steeper but more flexible |
| **Community** | Growing | Large and mature |
| **Modules** | Native support | Extensive registry |

## When to Use Bicep

✅ **Use Bicep when:**
- Working exclusively with Azure
- Want simplest possible syntax
- Need tight integration with Azure features
- Don't want to manage state files
- Team is already familiar with ARM

❌ **Consider alternatives when:**
- Need multi-cloud support
- Want extensive community modules
- Require advanced state management
- Need complex provisioning logic
```

### Step 4: Building Your First Real Bicep Template

**💡 Educational Note**: Now we'll build a complete web application infrastructure using Bicep, demonstrating parameters, variables, resources, and outputs.

#### Copilot Agent Prompt:
```markdown
@workspace Create a complete Bicep template for a web application infrastructure that includes:

1. App Service Plan with environment-based sizing
2. Web App with application settings
3. Storage Account for static files
4. Application Insights for monitoring
5. Key Vault for secrets
6. Proper networking with private endpoints (optional for prod)

Include:
- Parameter validation and descriptions
- Environment-specific configurations (dev/staging/prod)
- Security best practices
- Cost optimization strategies
- Comprehensive outputs
- Deployment script

Explain each section with educational comments about Bicep features and Azure best practices.
```

#### Expected Bicep Implementation:

**main.bicep:**
```bicep
// =====================================================
// Web Application Infrastructure Template
// =====================================================
// This template demonstrates Bicep best practices for
// deploying a complete web application infrastructure
// with security, monitoring, and environment-specific
// configurations.

// ==================== PARAMETERS ====================
// Parameters are the inputs to your template. They make
// your infrastructure reusable across environments.

@description('The name of your application')
@minLength(3)
@maxLength(24)
param appName string

@description('The environment type')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string = 'dev'

@description('The Azure region for resources')
param location string = resourceGroup().location

@description('The administrator email for alerts')
param adminEmail string

@secure()
@description('SQL Server administrator password')
param sqlAdminPassword string

@description('Enable private endpoints for production')
param enablePrivateEndpoints bool = environment == 'prod'

// ==================== VARIABLES ====================
// Variables help compute values based on parameters
// and reduce repetition in your template.

// Naming convention variables
var resourcePrefix = '${appName}-${environment}'
var storageAccountName = toLower(replace('st${appName}${environment}', '-', ''))

// Environment-specific configurations
var environmentConfig = {
  dev: {
    appServicePlanSku: 'B1'     // Basic tier for dev
    appServicePlanCapacity: 1    // Single instance
    sqlDatabaseSku: 'Basic'      // Basic SQL tier
    enableAlerts: false          // No alerts in dev
  }
  staging: {
    appServicePlanSku: 'S1'      // Standard tier
    appServicePlanCapacity: 2    // 2 instances
    sqlDatabaseSku: 'S0'         // Standard SQL
    enableAlerts: true           // Enable alerts
  }
  prod: {
    appServicePlanSku: 'P1v3'    // Premium tier
    appServicePlanCapacity: 3    // 3 instances minimum
    sqlDatabaseSku: 'S2'         // Higher SQL tier
    enableAlerts: true           // Full monitoring
  }
}

// Select configuration based on environment
var config = environmentConfig[environment]

// Common tags for all resources
var commonTags = {
  Environment: environment
  Application: appName
  ManagedBy: 'Bicep'
  CostCenter: 'Engineering'
  DeploymentDate: utcNow('yyyy-MM-dd')
}

// ==================== RESOURCES ====================
// Resources are the actual Azure services being deployed

// App Service Plan - The hosting environment
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'plan-${resourcePrefix}'
  location: location
  tags: commonTags
  sku: {
    name: config.appServicePlanSku
    capacity: config.appServicePlanCapacity
  }
  properties: {
    reserved: false // Windows plan
  }
}

// Application Insights - Monitoring and diagnostics
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'ai-${resourcePrefix}'
  location: location
  tags: commonTags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'IbizaWebAppExtensionCreate'
  }
}

// Key Vault - Secure secret storage
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: 'kv-${resourcePrefix}'
  location: location
  tags: commonTags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForDeployment: true
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: environment == 'prod' ? 90 : 7
    enableRbacAuthorization: true
    networkAcls: {
      defaultAction: enablePrivateEndpoints ? 'Deny' : 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Storage Account - For static files and backups
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  tags: commonTags
  sku: {
    name: environment == 'prod' ? 'Standard_GRS' : 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: enablePrivateEndpoints ? 'Deny' : 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Web App - The actual application
resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: 'app-${resourcePrefix}'
  location: location
  tags: commonTags
  identity: {
    type: 'SystemAssigned' // Managed identity for secure access
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      alwaysOn: environment != 'dev' // Save costs in dev
      http20Enabled: true
      ftpsState: 'Disabled' // Security best practice
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: environment
        }
        {
          name: 'StorageAccount:ConnectionString'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'KeyVault:Uri'
          value: keyVault.properties.vaultUri
        }
      ]
    }
  }
}

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: 'sql-${resourcePrefix}'
  location: location
  tags: commonTags
  properties: {
    administratorLogin: 'sqladmin'
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: enablePrivateEndpoints ? 'Disabled' : 'Enabled'
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: 'db-${appName}'
  location: location
  tags: commonTags
  sku: {
    name: config.sqlDatabaseSku
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648 // 2 GB
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: false
    readScale: 'Disabled'
    requestedBackupStorageRedundancy: environment == 'prod' ? 'Geo' : 'Local'
  }
}

// Diagnostic settings for Web App
resource webAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${webApp.name}'
  scope: webApp
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Log Analytics Workspace for centralized logging
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'log-${resourcePrefix}'
  location: location
  tags: commonTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: environment == 'prod' ? 90 : 30
  }
}

// Action Group for alerts
resource actionGroup 'Microsoft.Insights/actionGroups@2022-06-01' = if (config.enableAlerts) {
  name: 'ag-${resourcePrefix}'
  location: 'global'
  tags: commonTags
  properties: {
    groupShortName: 'AppAlerts'
    enabled: true
    emailReceivers: [
      {
        name: 'AdminEmail'
        emailAddress: adminEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

// Metric Alert for high CPU
resource cpuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (config.enableAlerts) {
  name: 'alert-high-cpu-${resourcePrefix}'
  location: 'global'
  tags: commonTags
  properties: {
    severity: 2
    enabled: true
    scopes: [
      appServicePlan.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighCPU'
          metricName: 'CpuPercentage'
          dimensions: []
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// ==================== MODULES ====================
// Modules allow you to encapsulate and reuse
// common infrastructure patterns

// Network module for production environments
module networkModule 'modules/network.bicep' = if (enablePrivateEndpoints) {
  name: 'network-deployment'
  params: {
    resourcePrefix: resourcePrefix
    location: location
    tags: commonTags
  }
}

// ==================== OUTPUTS ====================
// Outputs provide information about the deployed
// resources for use in other templates or scripts

output webAppName string = webApp.name
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output webAppPrincipalId string = webApp.identity.principalId
output storageAccountName string = storageAccount.name
output keyVaultUri string = keyVault.properties.vaultUri
output sqlServerName string = sqlServer.name
output sqlDatabaseName string = sqlDatabase.name
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString
```

### Step 5: Creating Reusable Modules

**💡 Educational Note**: Modules are the key to scalable infrastructure. They encapsulate common patterns and make your infrastructure DRY (Don't Repeat Yourself).

#### Copilot Agent Prompt:
```markdown
@workspace Create a reusable Bicep module for networking that:

1. Creates a Virtual Network with proper address space
2. Creates subnets for different tiers (web, app, data)
3. Creates Network Security Groups with rules
4. Supports private endpoints
5. Is parameterized for different environments

Show how to call this module from the main template and explain module best practices.
```

#### Expected Module:

**modules/network.bicep:**
```bicep
// =====================================================
// Reusable Network Module
// =====================================================
// This module creates a standard network configuration
// that can be reused across different applications

// ==================== PARAMETERS ====================
@description('Resource name prefix')
param resourcePrefix string

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Virtual network address space')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Enable DDoS protection')
param enableDdosProtection bool = false

@description('Tags to apply to resources')
param tags object = {}

// ==================== VARIABLES ====================
var subnetConfig = [
  {
    name: 'subnet-web'
    addressPrefix: cidrSubnet(vnetAddressPrefix, 24, 0) // 10.0.0.0/24
    nsgRules: [
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
    ]
  }
  {
    name: 'subnet-app'
    addressPrefix: cidrSubnet(vnetAddressPrefix, 24, 1) // 10.0.1.0/24
    nsgRules: []
  }
  {
    name: 'subnet-data'
    addressPrefix: cidrSubnet(vnetAddressPrefix, 24, 2) // 10.0.2.0/24
    nsgRules: []
  }
]

// ==================== RESOURCES ====================

// Network Security Groups
resource networkSecurityGroups 'Microsoft.Network/networkSecurityGroups@2022-07-01' = [for subnet in subnetConfig: {
  name: 'nsg-${subnet.name}-${resourcePrefix}'
  location: location
  tags: tags
  properties: {
    securityRules: subnet.nsgRules
  }
}]

// Virtual Network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: 'vnet-${resourcePrefix}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    enableDdosProtection: enableDdosProtection
    subnets: [for (subnet, i) in subnetConfig: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: {
          id: networkSecurityGroups[i].id
        }
        privateEndpointNetworkPolicies: 'Disabled'
      }
    }]
  }
}

// ==================== OUTPUTS ====================
output vnetId string = virtualNetwork.id
output vnetName string = virtualNetwork.name
output subnetIds object = {
  web: virtualNetwork.properties.subnets[0].id
  app: virtualNetwork.properties.subnets[1].id
  data: virtualNetwork.properties.subnets[2].id
}
```

### Step 6: Deployment and Validation

#### Copilot Agent Prompt:
```markdown
@workspace Create comprehensive deployment scripts and procedures:

1. Pre-deployment validation script
2. Deployment script with proper error handling
3. Post-deployment validation
4. Rollback procedures
5. Cost estimation before deployment
6. Security scanning with Checkov
7. Documentation generation

Include both PowerShell and Bash versions for cross-platform support.
```

#### Expected Deployment Scripts:

**scripts/deploy-infrastructure.sh:**
```bash
#!/bin/bash
# =====================================================
# Infrastructure Deployment Script
# =====================================================
# This script handles the complete deployment lifecycle
# with validation, deployment, and verification steps

set -euo pipefail # Exit on error, undefined vars, pipe failures

# ==================== CONFIGURATION ==================
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BICEP_DIR="$ROOT_DIR/bicep"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ==================== FUNCTIONS ====================
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate prerequisites
validate_prerequisites() {
    log_info "Validating prerequisites..."
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI not found. Please install it first."
        exit 1
    fi
    
    # Check Bicep
    if ! az bicep version &> /dev/null; then
        log_error "Bicep not installed. Run: az bicep install"
        exit 1
    fi
    
    # Check if logged in
    if ! az account show &> /dev/null; then
        log_error "Not logged in to Azure. Run: az login"
        exit 1
    fi
    
    log_success "Prerequisites validated"
}

# Validate Bicep templates
validate_templates() {
    log_info "Validating Bicep templates..."
    
    # Build all Bicep files to check for errors
    find "$BICEP_DIR" -name "*.bicep" -type f | while read -r file; do
        log_info "Validating: $(basename "$file")"
        if ! az bicep build --file "$file" --stdout > /dev/null; then
            log_error "Validation failed for $file"
            exit 1
        fi
    done
    
    log_success "All templates validated"
}

# Security scan with Checkov
security_scan() {
    log_info "Running security scan..."
    
    if command -v checkov &> /dev/null; then
        # Convert Bicep to ARM for scanning
        local temp_dir=$(mktemp -d)
        az bicep build --file "$BICEP_DIR/main.bicep" --outfile "$temp_dir/main.json"
        
        # Run Checkov scan
        checkov -f "$temp_dir/main.json" --framework arm --output cli --quiet || true
        
        rm -rf "$temp_dir"
    else
        log_warning "Checkov not installed, skipping security scan"
    fi
}

# Estimate costs
estimate_costs() {
    log_info "Estimating deployment costs..."
    
    # This is a placeholder - in real scenarios, you'd use Azure Pricing API
    # or tools like Infracost
    log_warning "Cost estimation not implemented. Approximate costs:"
    echo "  - App Service Plan (B1): ~\$55/month"
    echo "  - Storage Account: ~\$20/month"
    echo "  - SQL Database (Basic): ~\$5/month"
    echo "  - Application Insights: ~\$2.30/GB"
    echo "  Total estimate: ~\$85-100/month for dev environment"
}

# Deploy infrastructure
deploy_infrastructure() {
    local environment=$1
    local resource_group=$2
    local app_name=$3
    
    log_info "Deploying infrastructure..."
    log_info "Environment: $environment"
    log_info "Resource Group: $resource_group"
    log_info "Application: $app_name"
    
    # Create resource group if it doesn't exist
    if ! az group show --name "$resource_group" &> /dev/null; then
        log_info "Creating resource group..."
        az group create \
            --name "$resource_group" \
            --location eastus2 \
            --tags Environment="$environment" ManagedBy="Bicep"
    fi
    
    # Generate unique deployment name
    local deployment_name="deploy-$(date +%Y%m%d-%H%M%S)"
    
    # Deploy main template
    log_info "Starting deployment: $deployment_name"
    
    if az deployment group create \
        --name "$deployment_name" \
        --resource-group "$resource_group" \
        --template-file "$BICEP_DIR/main.bicep" \
        --parameters appName="$app_name" \
                    environment="$environment" \
                    adminEmail="admin@example.com" \
                    sqlAdminPassword="$(openssl rand -base64 32)" \
        --mode Complete; then
        
        log_success "Deployment completed successfully!"
        
        # Get outputs
        log_info "Deployment outputs:"
        az deployment group show \
            --name "$deployment_name" \
            --resource-group "$resource_group" \
            --query properties.outputs -o json
    else
        log_error "Deployment failed!"
        exit 1
    fi
}

# Post-deployment validation
validate_deployment() {
    local resource_group=$1
    
    log_info "Validating deployment..."
    
    # Check if key resources exist
    local resources=$(az resource list --resource-group "$resource_group" --query "[].type" -o tsv)
    
    local required_resources=(
        "Microsoft.Web/serverfarms"
        "Microsoft.Web/sites"
        "Microsoft.Storage/storageAccounts"
        "Microsoft.Insights/components"
    )
    
    for resource in "${required_resources[@]}"; do
        if echo "$resources" | grep -q "$resource"; then
            log_success "Found: $resource"
        else
            log_error "Missing: $resource"
        fi
    done
}

# ==================== MAIN ====================
main() {
    log_info "Starting infrastructure deployment process..."
    
    # Parse arguments
    if [ $# -lt 3 ]; then
        echo "Usage: $0 <environment> <resource-group> <app-name>"
        echo "Example: $0 dev rg-myapp-dev myapp"
        exit 1
    fi
    
    local environment=$1
    local resource_group=$2
    local app_name=$3
    
    # Validate environment
    if [[ ! "$environment" =~ ^(dev|staging|prod)$ ]]; then
        log_error "Invalid environment: $environment (must be dev, staging, or prod)"
        exit 1
    fi
    
    # Run deployment steps
    validate_prerequisites
    validate_templates
    security_scan
    estimate_costs
    
    # Confirm deployment
    echo
    read -p "Do you want to proceed with deployment? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Deployment cancelled"
        exit 0
    fi
    
    deploy_infrastructure "$environment" "$resource_group" "$app_name"
    validate_deployment "$resource_group"
    
    log_success "Deployment process completed!"
}

# Run main function
main "$@"
```

---

## 📚 Key Learnings from Exercise 1

### Bicep Fundamentals Mastered
1. **Declarative Syntax**: Define what you want, not how to create it
2. **Resource Dependencies**: Bicep automatically determines deployment order
3. **Type Safety**: Compile-time validation prevents runtime errors
4. **Parameterization**: Make templates reusable across environments
5. **Modularization**: Break complex infrastructure into manageable pieces

### Best Practices Applied
1. **Naming Conventions**: Consistent, descriptive resource names
2. **Tagging Strategy**: Organize resources for cost and management
3. **Security by Default**: HTTPS, encryption, managed identities
4. **Environment Parity**: Similar configs with appropriate sizing
5. **Monitoring Built-in**: Logs, metrics, and alerts from day one

### Skills Developed
- Writing clean, maintainable Bicep code
- Creating reusable infrastructure modules
- Implementing security best practices
- Cost optimization strategies
- Automated deployment pipelines

## 🎯 Next Steps

You've successfully completed Exercise 1! You now understand:
- Azure Bicep fundamentals
- Infrastructure as Code principles
- Azure resource deployment
- Module-based architecture
- Deployment automation

Continue to Exercise 2 where you'll learn Terraform for multi-cloud infrastructure!

**Remember**: Infrastructure as Code is about repeatability and reliability. Every deployment should be predictable and reversible!