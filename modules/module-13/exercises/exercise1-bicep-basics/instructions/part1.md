# Exercise 1: Bicep Basics (⭐ Easy)

## Objective
Create your first Infrastructure as Code (IaC) template using Azure Bicep to deploy a simple web application infrastructure.

## Duration
30-45 minutes

## Prerequisites
- Azure CLI installed and configured
- VS Code with Bicep extension
- Basic understanding of Azure resources

## Part 1: Introduction to Bicep

### What is Bicep?
Bicep is a domain-specific language (DSL) for deploying Azure resources declaratively. It aims to simplify the authoring experience with cleaner syntax compared to ARM templates.

### Key Concepts
1. **Resources**: Azure services you want to deploy
2. **Parameters**: Input values for customization
3. **Variables**: Computed values within the template
4. **Outputs**: Values returned after deployment

## Part 2: Create Your First Bicep Template

### Step 1: Create the Project Structure
```bash
# Create directories
mkdir -p exercise1-bicep-basics/{starter,solution}
cd exercise1-bicep-basics/starter

# Create main bicep file
touch main.bicep
```

### Step 2: Define Basic Parameters
Open `main.bicep` and add the following:

```bicep
// Parameters for customization
@description('The name of the App Service Plan')
param appServicePlanName string = 'asp-${uniqueString(resourceGroup().id)}'

@description('The name of the Web App')
param webAppName string = 'webapp-${uniqueString(resourceGroup().id)}'

@description('The location for all resources')
param location string = resourceGroup().location
```

**Copilot Prompt Suggestion:**
"Create Azure Bicep parameters for an App Service deployment with unique naming and location defaulting to resource group location"

### Step 3: Add the App Service Plan Resource
```bicep
// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'F1'  // Free tier
  }
  kind: 'linux'
  properties: {
    reserved: true  // Required for Linux
  }
}
```

### Step 4: Add the Web App Resource
```bicep
// Web App
resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'
    }
  }
}
```

### Step 5: Add Outputs
```bicep
// Outputs for reference
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output webAppName string = webApp.name
```

## Part 3: Deploy Your Infrastructure

### Step 1: Login to Azure
```bash
az login
az account set --subscription "Your Subscription Name"
```

### Step 2: Create Resource Group
```bash
# Create a resource group
az group create \
  --name rg-module13-exercise1 \
  --location eastus
```

### Step 3: Deploy the Bicep Template
```bash
# Deploy the template
az deployment group create \
  --resource-group rg-module13-exercise1 \
  --template-file main.bicep \
  --name deployment1
```

### Step 4: Verify Deployment
```bash
# Check deployment status
az deployment group show \
  --resource-group rg-module13-exercise1 \
  --name deployment1 \
  --query properties.provisioningState

# List created resources
az resource list \
  --resource-group rg-module13-exercise1 \
  --output table
```

## Part 4: Enhance Your Template

### Add Parameters for Flexibility
Update your template to include:

1. **SKU Parameter** with allowed values:
```bicep
@allowed([
  'F1'
  'B1'
  'S1'
  'P1v2'
])
param sku string = 'F1'
```

2. **Environment Tag**:
```bicep
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'
```

**Copilot Prompt Suggestion:**
"Add Bicep parameter decorators for SKU selection with allowed values F1, B1, S1, P1v2 and environment tags"

### Add Tags to Resources
```bicep
var tags = {
  Environment: environment
  ManagedBy: 'Bicep'
  Module: '13'
}

// Update resources to include tags
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  // ... existing properties
  tags: tags
}
```

## Validation Checklist
- [ ] Bicep template validates without errors
- [ ] Resources deploy successfully
- [ ] Web App URL is accessible
- [ ] Tags are properly applied
- [ ] Outputs show correct values

## Common Issues and Solutions

### Issue 1: Name Already Exists
**Solution**: Use `uniqueString()` function to generate unique names

### Issue 2: SKU Not Available
**Solution**: Check regional availability or use a different SKU

### Issue 3: Deployment Fails
**Solution**: Check activity log for detailed error messages

## Next Steps
Continue to Part 2 for more advanced features including:
- Conditional deployments
- Modules and reusability
- Parameter files
- Complex dependencies