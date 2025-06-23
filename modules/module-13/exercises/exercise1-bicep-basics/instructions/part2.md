# Exercise 1: Bicep Basics - Part 2

## Advanced Features and Best Practices

### Adding Application Insights

Application Insights provides monitoring and telemetry for your web application.

```bicep
// Add this parameter
@description('Enable Application Insights')
param enableApplicationInsights bool = true

// Add the Application Insights resource
resource appInsights 'Microsoft.Insights/components@2020-02-02' = if (enableApplicationInsights) {
  name: '${webAppName}-insights'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

// Update the web app to use Application Insights
resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: webAppName
  location: location
  tags: tags
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      appSettings: enableApplicationInsights ? [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
      ] : []
    }
    httpsOnly: true  // Security best practice
  }
}
```

**Copilot Prompt Suggestion:**
"Add conditional Application Insights deployment to Bicep template with connection string configuration in App Service settings"

### Parameter Files for Different Environments

Create parameter files to manage different environments easily.

#### Development Parameters (parameters.dev.json)
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "appServicePlanName": {
      "value": "asp-module13-dev"
    },
    "webAppName": {
      "value": "webapp-module13-dev"
    },
    "sku": {
      "value": "F1"
    },
    "environment": {
      "value": "dev"
    }
  }
}
```

#### Production Parameters (parameters.prod.json)
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "appServicePlanName": {
      "value": "asp-module13-prod"
    },
    "webAppName": {
      "value": "webapp-module13-prod"
    },
    "sku": {
      "value": "P1v2"
    },
    "environment": {
      "value": "prod"
    }
  }
}
```

### Deploy with Parameter Files
```bash
# Deploy to dev environment
az deployment group create \
  --resource-group rg-module13-dev \
  --template-file main.bicep \
  --parameters @parameters.dev.json

# Deploy to production
az deployment group create \
  --resource-group rg-module13-prod \
  --template-file main.bicep \
  --parameters @parameters.prod.json
```

### Creating a Deployment Script

Create a reusable deployment script (`deploy.sh`):

```bash
#!/bin/bash
# Deployment script for Bicep template

# Default values
RESOURCE_GROUP="rg-module13-exercise1"
LOCATION="eastus"
ENVIRONMENT="dev"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -g|--resource-group)
      RESOURCE_GROUP="$2"
      shift 2
      ;;
    -e|--environment)
      ENVIRONMENT="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Create resource group
echo "Creating resource group: $RESOURCE_GROUP"
az group create --name $RESOURCE_GROUP --location $LOCATION

# Deploy template
echo "Deploying Bicep template for $ENVIRONMENT environment"
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file main.bicep \
  --parameters @parameters.$ENVIRONMENT.json \
  --name "deployment-$(date +%Y%m%d-%H%M%S)"

# Show outputs
echo "Deployment outputs:"
az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name deployment-latest \
  --query properties.outputs
```

**Copilot Prompt Suggestion:**
"Create a bash deployment script for Bicep templates with argument parsing for resource group and environment selection"

## Best Practices Implementation

### 1. Resource Naming Convention
```bicep
// Use consistent naming patterns
var resourcePrefix = 'workshop13'
var uniqueSuffix = uniqueString(resourceGroup().id)

var appServicePlanName = 'asp-${resourcePrefix}-${environment}-${uniqueSuffix}'
var webAppName = 'app-${resourcePrefix}-${environment}-${uniqueSuffix}'
```

### 2. Dependency Management
```bicep
// Explicit dependencies (usually not needed with Bicep)
resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: webAppName
  location: location
  dependsOn: [
    appServicePlan  // Bicep handles this automatically
  ]
  // ...
}
```

### 3. Using Modules for Reusability
Create a module for the web app (`modules/webapp.bicep`):

```bicep
// webapp.bicep - Reusable module
param webAppName string
param location string
param appServicePlanId string
param linuxFxVersion string = 'PYTHON|3.11'
param tags object = {}

resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: webAppName
  location: location
  tags: tags
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
      linuxFxVersion: linuxFxVersion
    }
    httpsOnly: true
  }
}

output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
```

Use the module in your main template:
```bicep
module webAppModule 'modules/webapp.bicep' = {
  name: 'webAppDeployment'
  params: {
    webAppName: webAppName
    location: location
    appServicePlanId: appServicePlan.id
    tags: tags
  }
}
```

## Testing and Validation

### 1. Validate Template Syntax
```bash
az bicep build --file main.bicep
```

### 2. What-If Deployment
```bash
az deployment group what-if \
  --resource-group rg-module13-exercise1 \
  --template-file main.bicep \
  --parameters @parameters.dev.json
```

### 3. Test Deployment
Create a test script (`test-deployment.sh`):
```bash
#!/bin/bash
# Test the deployed resources

RESOURCE_GROUP=$1
WEB_APP_NAME=$(az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name deployment-latest \
  --query properties.outputs.webAppName.value -o tsv)

# Test web app is responding
URL="https://${WEB_APP_NAME}.azurewebsites.net"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" $URL)

if [ $STATUS -eq 200 ]; then
  echo "✅ Web app is running successfully at $URL"
else
  echo "❌ Web app returned status code: $STATUS"
fi
```

## Challenge Extensions

1. **Add Deployment Slots**: Implement staging slots for blue-green deployments
2. **Custom Domain**: Add custom domain configuration
3. **Auto-scaling**: Configure auto-scaling rules based on CPU usage
4. **Key Vault Integration**: Store connection strings in Key Vault

## Summary

You've learned:
- ✅ Bicep syntax and structure
- ✅ Parameterization for flexibility
- ✅ Conditional deployments
- ✅ Environment-specific configurations
- ✅ Best practices for IaC
- ✅ Testing and validation approaches

Continue to Exercise 2 for GitOps integration!