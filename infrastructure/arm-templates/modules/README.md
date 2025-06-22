# ARM Template Modules

This directory contains nested ARM templates for modular deployments.

## Available Modules

### ai-services.json
Deploys Azure AI services including:
- Azure OpenAI Service
- Azure Cognitive Search
- Cosmos DB
- Application Insights

### compute.json
Provisions compute resources:
- Azure Kubernetes Service
- Azure Functions
- Container Instances
- App Service Plans

### networking.json
Creates network infrastructure:
- Virtual Networks
- Subnets
- Network Security Groups
- Private Endpoints

### storage.json
Sets up storage resources:
- Storage Accounts
- Blob Containers
- File Shares
- Table Storage

## Usage

### As Nested Template
```json
{
  "type": "Microsoft.Resources/deployments",
  "apiVersion": "2021-04-01",
  "name": "storageModule",
  "properties": {
    "mode": "Incremental",
    "templateLink": {
      "uri": "[concat(parameters('_artifactsLocation'), '/modules/storage.json')]"
    },
    "parameters": {
      "storageAccountName": {
        "value": "[variables('storageAccountName')]"
      },
      "location": {
        "value": "[parameters('location')]"
      }
    }
  }
}
```

### Direct Deployment
```bash
az deployment group create \
  --resource-group rg-workshop \
  --template-file modules/storage.json \
  --parameters storageAccountName=myaccount
```

## Module Standards

Each module should:
1. Be self-contained
2. Accept standard parameters (location, tags)
3. Output resource IDs and connection strings
4. Handle dependencies internally
5. Include parameter validation

## Creating New Modules

Follow this template structure:
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "metadata": {
    "description": "Module description",
    "author": "Your name"
  },
  "parameters": {
    // Standard parameters
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]",
      "metadata": {
        "description": "Location for resources"
      }
    },
    "tags": {
      "type": "object",
      "defaultValue": {},
      "metadata": {
        "description": "Resource tags"
      }
    }
    // Module-specific parameters
  },
  "variables": {
    // Module variables
  },
  "resources": [
    // Module resources
  ],
  "outputs": {
    // Module outputs
  }
}
```

## Best Practices

1. **Naming**: Use clear, descriptive names
2. **Parameters**: Minimize required parameters
3. **Defaults**: Provide sensible defaults
4. **Outputs**: Export all useful information
5. **Dependencies**: Use dependsOn carefully
6. **Conditions**: Support optional features

## Testing Modules

```bash
# Validate template
az deployment group validate \
  --resource-group rg-test \
  --template-file modules/module-name.json

# What-if deployment
az deployment group what-if \
  --resource-group rg-test \
  --template-file modules/module-name.json
```
