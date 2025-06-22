# 📋 ARM Templates (Legacy Support)

This directory contains Azure Resource Manager (ARM) templates for legacy support. While we recommend using Bicep or Terraform for new deployments, these templates are provided for organizations that require ARM template compatibility.

## ⚠️ Important Note

ARM templates are considered legacy. For new projects, please use:
- **Bicep** (recommended): See `/infrastructure/bicep/`
- **Terraform**: See `/infrastructure/terraform/`

## 📁 Structure

```
arm-templates/
├── azuredeploy.json           # Main deployment template
├── azuredeploy.parameters.json # Parameter file template
├── modules/                   # Nested templates
│   ├── ai-services.json      # AI services template
│   ├── compute.json          # Compute resources
│   ├── networking.json       # Network infrastructure
│   └── storage.json          # Storage resources
└── examples/                  # Example deployments
```

## 🚀 Deployment

### Using Azure CLI
```bash
# Create resource group
az group create --name rg-workshop-dev --location eastus

# Deploy template
az deployment group create \
  --resource-group rg-workshop-dev \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json
```

### Using PowerShell
```powershell
# Create resource group
New-AzResourceGroup -Name "rg-workshop-dev" -Location "East US"

# Deploy template
New-AzResourceGroupDeployment `
  -ResourceGroupName "rg-workshop-dev" `
  -TemplateFile "azuredeploy.json" `
  -TemplateParameterFile "azuredeploy.parameters.json"
```

## 🔄 Migration to Bicep

To convert these ARM templates to Bicep:

```bash
# Install Bicep CLI
az bicep install

# Decompile ARM template to Bicep
az bicep decompile --file azuredeploy.json
```

## 📊 Template Components

### Main Template (azuredeploy.json)
Orchestrates the deployment of all workshop resources:
- Resource naming conventions
- Dependency management
- Output values for application configuration

### AI Services Module
Deploys:
- Azure OpenAI Service
- Azure Cognitive Search
- Cosmos DB
- Application Insights

### Compute Module
Provisions:
- Azure Kubernetes Service (AKS)
- Azure Functions
- Container Instances

### Networking Module
Creates:
- Virtual Networks
- Subnets
- Network Security Groups
- Private Endpoints

### Storage Module
Sets up:
- Storage Accounts
- Blob Containers
- File Shares
- Table Storage

## 🏷️ Parameter Files

Create environment-specific parameter files:
- `azuredeploy.parameters.dev.json`
- `azuredeploy.parameters.staging.json`
- `azuredeploy.parameters.prod.json`

## 🔒 Security Considerations

1. Never commit parameter files with secrets
2. Use Key Vault references for sensitive values
3. Enable diagnostic logging
4. Implement proper RBAC

## 🆘 Common Issues

### Template Size Limits
ARM templates have a 4MB limit. Use linked templates for large deployments.

### Circular Dependencies
Ensure proper dependency ordering using `dependsOn` properties.

### API Version Compatibility
Always use the latest stable API versions for resources.

## 📚 Resources

- [ARM Template Documentation](https://docs.microsoft.com/azure/azure-resource-manager/templates/)
- [Template Reference](https://docs.microsoft.com/azure/templates/)
- [Best Practices](https://docs.microsoft.com/azure/azure-resource-manager/templates/best-practices)
