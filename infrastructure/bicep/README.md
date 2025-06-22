# 🔷 Azure Bicep Infrastructure

This directory contains Azure Bicep templates for deploying the Mastery AI Workshop infrastructure.

## 📋 Overview

Bicep is a declarative language for deploying Azure resources. It provides:
- 🎯 Simpler syntax than ARM templates
- 🔍 Better type safety and intellisense
- 🧩 Modular architecture
- 🔄 Direct ARM template compilation

## 📁 Directory Structure

```
bicep/
├── main.bicep              # Main deployment template
├── modules/                # Reusable Bicep modules
│   ├── storage.bicep      # Storage account module
│   └── README.md          # Module documentation
└── parameters/            # Environment-specific parameters
    ├── dev.parameters.json
    ├── staging.parameters.json
    └── prod.parameters.json
```

## 🚀 Quick Start

### Deploy to Development
```bash
# Using Azure CLI
az deployment group create \
  --resource-group rg-workshop-dev \
  --template-file main.bicep \
  --parameters @parameters/dev.parameters.json

# Using PowerShell
New-AzResourceGroupDeployment `
  -ResourceGroupName "rg-workshop-dev" `
  -TemplateFile "main.bicep" `
  -TemplateParameterFile "parameters/dev.parameters.json"
```

### Validate Before Deployment
```bash
# Validate syntax
az bicep build --file main.bicep

# What-if deployment
az deployment group what-if \
  --resource-group rg-workshop-dev \
  --template-file main.bicep \
  --parameters @parameters/dev.parameters.json
```

## 🔧 Main Template (main.bicep)

The main template orchestrates the deployment of all workshop resources:

```bicep
// Example structure
param projectName string = 'masteryai'
param environment string = 'dev'
param location string = resourceGroup().location

// Deploy storage module
module storage 'modules/storage.bicep' = {
  name: 'storageModule'
  params: {
    storageAccountName: '${projectName}${environment}'
    location: location
  }
}

// Outputs
output storageAccountName string = storage.outputs.name
```

## 🧩 Modules

### Available Modules
- `storage.bicep` - Storage accounts with containers
- More modules planned...

### Using Modules
```bicep
module moduleName 'modules/moduleName.bicep' = {
  name: 'uniqueDeploymentName'
  params: {
    param1: value1
    param2: value2
  }
}
```

## 📋 Parameters

### Parameter Files
Environment-specific parameter files are stored in `parameters/`:
- `dev.parameters.json` - Development environment
- `staging.parameters.json` - Staging environment  
- `prod.parameters.json` - Production environment

### Parameter Structure
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "projectName": {
      "value": "masteryai"
    },
    "environment": {
      "value": "dev"
    }
  }
}
```

## 🏷️ Best Practices

### 1. Naming Conventions
```bicep
// Use parameter for flexibility
param projectName string = 'masteryai'
param environment string = 'dev'

// Construct names
var storageAccountName = '${toLower(projectName)}${toLower(environment)}${uniqueString(resourceGroup().id)}'
```

### 2. Resource Tags
```bicep
param tags object = {
  Project: 'MasteryAIWorkshop'
  Environment: environment
  ManagedBy: 'Bicep'
  DeploymentDate: utcNow()
}

// Apply to all resources
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  tags: tags
  // ...
}
```

### 3. Conditional Deployments
```bicep
param deployResource bool = true

resource conditionalResource 'Microsoft.ResourceType@version' = if (deployResource) {
  // Resource properties
}
```

### 4. Outputs
```bicep
output resourceId string = resource.id
output connectionString string = resource.properties.connectionString
@secure()
output secretValue string = resource.listKeys().keys[0].value
```

## 🔄 CI/CD Integration

### GitHub Actions
```yaml
- name: Deploy Bicep
  uses: azure/arm-deploy@v1
  with:
    resourceGroupName: rg-workshop-${{ env.ENVIRONMENT }}
    template: ./infrastructure/bicep/main.bicep
    parameters: ./infrastructure/bicep/parameters/${{ env.ENVIRONMENT }}.parameters.json
```

### Azure DevOps
```yaml
- task: AzureResourceManagerTemplateDeployment@3
  inputs:
    deploymentScope: 'Resource Group'
    resourceGroupName: 'rg-workshop-$(environment)'
    templateLocation: 'Linked artifact'
    csmFile: '$(System.DefaultWorkingDirectory)/infrastructure/bicep/main.bicep'
    csmParametersFile: '$(System.DefaultWorkingDirectory)/infrastructure/bicep/parameters/$(environment).parameters.json'
```

## 🆚 Bicep vs ARM vs Terraform

| Feature | Bicep | ARM Templates | Terraform |
|---------|-------|---------------|-----------|
| Syntax | Simple | Verbose JSON | HCL |
| Azure Native | ✅ Yes | ✅ Yes | ❌ No |
| Multi-Cloud | ❌ No | ❌ No | ✅ Yes |
| State Management | ❌ No | ❌ No | ✅ Yes |
| Learning Curve | 📈 Medium | 📈 High | 📈 Medium |

## 🐛 Troubleshooting

### Common Issues

1. **Deployment Failures**
   ```bash
   # Get detailed error
   az deployment group show \
     --resource-group rg-workshop-dev \
     --name deploymentName
   ```

2. **Parameter Mismatches**
   - Ensure parameter file matches template parameters
   - Check parameter types and constraints

3. **Module Not Found**
   - Use relative paths for local modules
   - Ensure module file exists

## 📚 Resources

- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Bicep Playground](https://bicepdemo.z22.web.core.windows.net/)
- [Azure Quickstart Templates](https://github.com/Azure/azure-quickstart-templates)
- [Bicep Examples](https://github.com/Azure/bicep/tree/main/docs/examples)

## 🤝 Contributing

To add new Bicep templates:
1. Create module in `modules/`
2. Add parameters to `parameters/`
3. Update main.bicep if needed
4. Document in module README
5. Test deployment
