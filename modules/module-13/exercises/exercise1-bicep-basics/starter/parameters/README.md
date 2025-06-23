# Parameters Files

This directory contains parameter files for different environments.

## 📝 TODO: Complete the parameter files

Edit `dev.parameters.json` to add the following parameters:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "appServicePlanName": {
      "value": "asp-bicep-dev"
    },
    "webAppName": {
      "value": "webapp-bicep-dev-[unique-suffix]"
    },
    "sku": {
      "value": "F1"
    },
    "environment": {
      "value": "dev"
    },
    "enableApplicationInsights": {
      "value": false
    }
  }
}
```

## 🚀 Usage

Deploy with parameters file:
```bash
az deployment group create \
  --resource-group rg-bicep-exercise1 \
  --template-file ../main.bicep \
  --parameters @dev.parameters.json
``` 