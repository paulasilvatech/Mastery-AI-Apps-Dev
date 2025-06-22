# 📋 ARM Templates

This directory contains Azure Resource Manager (ARM) templates for legacy support. While the workshop primarily uses Bicep (the newer, more concise syntax), these ARM templates are provided for environments that require JSON-based ARM templates.

## 📁 Structure

```
arm-templates/
├── README.md              # This file
├── azuredeploy.json       # Main deployment template
├── parameters/            # Parameter files for different environments
│   ├── dev.parameters.json
│   ├── staging.parameters.json
│   └── prod.parameters.json
└── modules/              # Reusable ARM template modules
    ├── storage.json
    ├── compute.json
    └── ai-services.json
```

## 🔄 Conversion from Bicep

The ARM templates in this directory are automatically generated from the Bicep templates using:

```bash
# Convert a single Bicep file to ARM
az bicep build --file ../bicep/main.bicep --outfile azuredeploy.json

# Convert all Bicep modules
for file in ../bicep/modules/*.bicep; do
    basename=$(basename "$file" .bicep)
    az bicep build --file "$file" --outfile "modules/${basename}.json"
done
```

## 🚀 Deployment

### Using Azure CLI

```bash
# Deploy to a resource group
az deployment group create \
    --resource-group rg-workshop-dev \
    --template-file azuredeploy.json \
    --parameters @parameters/dev.parameters.json

# Deploy at subscription level
az deployment sub create \
    --location eastus \
    --template-file azuredeploy.json \
    --parameters @parameters/dev.parameters.json
```

### Using PowerShell

```powershell
# Deploy to a resource group
New-AzResourceGroupDeployment `
    -ResourceGroupName "rg-workshop-dev" `
    -TemplateFile "azuredeploy.json" `
    -TemplateParameterFile "parameters/dev.parameters.json"

# Deploy at subscription level
New-AzSubscriptionDeployment `
    -Location "eastus" `
    -TemplateFile "azuredeploy.json" `
    -TemplateParameterFile "parameters/dev.parameters.json"
```

## 📝 Template Structure

### Main Template (azuredeploy.json)

The main template orchestrates the deployment of all resources:

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        // Parameter definitions
    },
    "variables": {
        // Variable definitions
    },
    "resources": [
        // Resource definitions
    ],
    "outputs": {
        // Output definitions
    }
}
```

### Parameter Files

Parameter files allow you to deploy the same template to different environments:

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "environment": {
            "value": "dev"
        },
        "location": {
            "value": "eastus"
        }
    }
}
```

## 🔍 Validation

Before deploying, validate your templates:

```bash
# Validate at resource group level
az deployment group validate \
    --resource-group rg-workshop-dev \
    --template-file azuredeploy.json \
    --parameters @parameters/dev.parameters.json

# What-if deployment (preview changes)
az deployment group what-if \
    --resource-group rg-workshop-dev \
    --template-file azuredeploy.json \
    --parameters @parameters/dev.parameters.json
```

## 🏷️ Tags

All resources deployed through these templates include standard tags:

- `Environment`: dev/staging/prod
- `Module`: Module number (1-30)
- `Workshop`: Mastery AI Code Development
- `ManagedBy`: ARM
- `CostCenter`: Training

## ⚠️ Important Notes

1. **Bicep is Preferred**: These ARM templates are provided for compatibility only. Use Bicep templates when possible.

2. **Auto-Generation**: Don't manually edit the generated ARM templates. Make changes in the Bicep source files and regenerate.

3. **Version Control**: Both Bicep source and generated ARM templates are version controlled for transparency.

4. **Complexity**: ARM templates are more verbose than Bicep. For complex scenarios, the JSON can become difficult to manage.

## 📚 Resources

- [ARM Template Documentation](https://docs.microsoft.com/azure/azure-resource-manager/templates/)
- [ARM Template Reference](https://docs.microsoft.com/azure/templates/)
- [Template Functions](https://docs.microsoft.com/azure/azure-resource-manager/templates/template-functions)
- [Best Practices](https://docs.microsoft.com/azure/azure-resource-manager/templates/best-practices)

## 🔄 Migration Path

If you're currently using ARM templates and want to migrate to Bicep:

1. Use the decompile command:
   ```bash
   az bicep decompile --file azuredeploy.json
   ```

2. Review and refactor the generated Bicep file

3. Test thoroughly before replacing ARM templates

---

**Note**: For new deployments, please use the Bicep templates in the `../bicep` directory. These ARM templates are maintained for backward compatibility only.
