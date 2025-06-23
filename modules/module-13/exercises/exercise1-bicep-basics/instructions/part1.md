# Exercise 1: Bicep Fundamentals - Part 1

## 🎯 Objective

Create your first Azure Bicep template to deploy a basic web application infrastructure.

## 📚 Background

Azure Bicep is a domain-specific language (DSL) for deploying Azure resources declaratively. It's a transparent abstraction over ARM templates, providing a cleaner syntax while maintaining the same capabilities.

### Key Concepts:
- **Resources**: Azure services you want to deploy
- **Parameters**: Input values that make templates reusable
- **Variables**: Values computed within the template
- **Outputs**: Values returned after deployment

## 🛠️ Step 1: Create the Basic Structure

### 1.1 Initialize Your Bicep File

Create a new file called `main.bicep` in the starter directory:

```bicep
// main.bicep - Web Application Infrastructure
// Module 13 - Exercise 1: Bicep Fundamentals

// Set the target scope
targetScope = 'resourceGroup'

// TODO: Add parameters

// TODO: Add variables

// TODO: Add resources

// TODO: Add outputs
```

### 1.2 Define Parameters

Add parameters to make your template flexible:

**Copilot Prompt:**
```
Add Bicep parameters for:
- appName (string): Base name for all resources
- environment (string): Environment name with allowed values dev, test, prod
- location (string): Azure region with default to resource group location
- skuName (string): App Service Plan SKU with default F1
```

**Expected Result:**
```bicep
@description('Base name for all resources')
@minLength(3)
@maxLength(24)
param appName string

@description('Environment name')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string

@description('Azure region for resources')
param location string = resourceGroup().location

@description('App Service Plan SKU')
@allowed([
  'F1'  // Free
  'B1'  // Basic
  'S1'  // Standard
  'P1'  // Premium
])
param skuName string = 'F1'
```

## 🛠️ Step 2: Add Variables

### 2.1 Define Naming Variables

Create consistent naming for all resources:

**Copilot Prompt:**
```
Create Bicep variables for resource names:
- Unique suffix using uniqueString function
- App Service Plan name
- Web App name
- Storage Account name (lowercase, no hyphens)
- Include environment in names
```

**Expected Result:**
```bicep
// Variables for consistent naming
var uniqueSuffix = uniqueString(resourceGroup().id)
var appServicePlanName = 'asp-${appName}-${environment}-${uniqueSuffix}'
var webAppName = 'app-${appName}-${environment}-${uniqueSuffix}'
var storageAccountName = toLower('st${appName}${environment}${take(uniqueSuffix, 6)}')
```

## 🛠️ Step 3: Create Core Resources

### 3.1 App Service Plan

Deploy the App Service Plan:

**Copilot Prompt:**
```
Create a Bicep resource for App Service Plan:
- Use the appServicePlanName variable
- Set location from parameter
- Use skuName parameter for tier
- Add tags for environment and createdBy
```

**Expected Result:**
```bicep
// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  tags: {
    environment: environment
    createdBy: 'Bicep'
    module: 'module-13'
  }
  sku: {
    name: skuName
    capacity: 1
  }
  properties: {
    reserved: false // Windows
  }
}
```

### 3.2 Web Application

Deploy the Web App:

**Copilot Prompt:**
```
Create a Bicep resource for Web App:
- Reference the App Service Plan
- Enable HTTPS only
- Set .NET 6 as runtime
- Add application settings for environment
- Include managed identity
```

**Expected Result:**
```bicep
// Web Application
resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
  tags: {
    environment: environment
    createdBy: 'Bicep'
    module: 'module-13'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      netFrameworkVersion: 'v6.0'
      appSettings: [
        {
          name: 'ENVIRONMENT'
          value: environment
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: 'placeholder' // We'll add App Insights in Part 2
        }
      ]
    }
  }
}
```

### 3.3 Storage Account

Add a Storage Account for static assets:

**Copilot Prompt:**
```
Create a Bicep resource for Storage Account:
- Use storageAccountName variable
- Standard_LRS replication
- Enable HTTPS traffic only
- Set minimum TLS version to 1.2
- Add blob service with container
```

**Expected Result:**
```bicep
// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  tags: {
    environment: environment
    createdBy: 'Bicep'
    module: 'module-13'
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

// Blob Service
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  parent: storageAccount
  name: 'default'
}

// Container for web assets
resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  parent: blobService
  name: 'web-assets'
  properties: {
    publicAccess: 'Blob'
  }
}
```

## 🛠️ Step 4: Add Basic Outputs

### 4.1 Define Outputs

Return important values from the deployment:

```bicep
// Outputs
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output webAppName string = webApp.name
output storageAccountName string = storageAccount.name
output resourceGroupName string = resourceGroup().name
```

## ✅ Checkpoint

Before proceeding to Part 2, ensure:
- [ ] Your Bicep file has no syntax errors (check with Bicep extension)
- [ ] All resources are properly defined
- [ ] Parameters and variables are used consistently
- [ ] Basic outputs are configured

### Test Your Template

Validate your template without deploying:

```bash
# Validate the template
az bicep build --file main.bicep

# Preview what would be deployed
az deployment group what-if \
  --resource-group myResourceGroup \
  --template-file main.bicep \
  --parameters appName=myapp environment=dev
```

## 🎯 Summary

In Part 1, you've:
- ✅ Created a basic Bicep template structure
- ✅ Defined parameters for flexibility
- ✅ Added core infrastructure resources
- ✅ Implemented basic security settings
- ✅ Set up outputs for resource information

## ⏭️ Next Steps

Proceed to [Part 2](./part2.md) where you'll:
- Add Azure SQL Database
- Implement secure connection strings
- Add Application Insights
- Create a parameter file
- Deploy to Azure

---

💡 **Tip**: Save your work frequently and use the Bicep extension's formatting feature (Alt+Shift+F) to keep your code clean!