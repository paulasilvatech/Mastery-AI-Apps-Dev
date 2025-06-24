# Module 07 - Complete Azure Deployment Guide with Bicep

## 🎯 Overview

Deploy all three Module 07 exercises to Azure using Infrastructure as Code (IaC) with Bicep templates. This guide provides production-ready deployments with security, scalability, and monitoring.

## 🚀 Prerequisites for Azure Deployment

### Agent Mode Setup Verification

```markdown
# Copilot Agent Prompt:
Create a comprehensive Azure deployment prerequisites checker:

1. Local Requirements:
   - Azure CLI installed and configured
   - Bicep CLI installed
   - Docker Desktop (for container deployments)
   - Valid Azure subscription
   - GitHub account for Actions

2. Azure Requirements:
   - Resource providers registered
   - Sufficient quota in region
   - Cost estimation
   - Security permissions

3. Create a script that:
   - Validates all tools
   - Checks Azure login
   - Lists available regions
   - Estimates monthly costs
   - Creates resource groups
   - Sets up service principal

Include error handling and remediation steps.
```

## 📦 Exercise 1: Todo App Azure Deployment

### Complete Bicep Template

```bicep
// File: infrastructure/exercise1/main.bicep
// Deploy a full-stack Todo application to Azure

@description('Environment name')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Unique suffix for resource names')
param uniqueSuffix string = uniqueString(resourceGroup().id)

// Variables
var appName = 'todo-app-${environment}-${uniqueSuffix}'
var backendAppName = '${appName}-api'
var frontendAppName = '${appName}-web'

// App Service Plan for Backend
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${appName}-plan'
  location: location
  sku: {
    name: environment == 'prod' ? 'P1v3' : 'B1'
    tier: environment == 'prod' ? 'PremiumV3' : 'Basic'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// Backend Web App (Python/FastAPI)
resource backendWebApp 'Microsoft.Web/sites@2022-03-01' = {
  name: backendAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'
      appSettings: [
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'CORS_ORIGINS'
          value: 'https://${frontendWebApp.properties.defaultHostName}'
        }
        {
          name: 'DATABASE_URL'
          value: 'sqlite:///./todos.db' // For dev, use Azure SQL for prod
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
      ]
      alwaysOn: environment == 'prod'
      ftpsState: 'Disabled'
      http20Enabled: true
    }
    httpsOnly: true
  }
}

// Frontend Static Web App
resource frontendWebApp 'Microsoft.Web/staticSites@2022-03-01' = {
  name: frontendAppName
  location: location
  sku: {
    name: environment == 'prod' ? 'Standard' : 'Free'
    tier: environment == 'prod' ? 'Standard' : 'Free'
  }
  properties: {
    repositoryUrl: 'https://github.com/YOUR_GITHUB/todo-app'
    branch: 'main'
    stagingEnvironmentPolicy: 'Enabled'
    allowConfigFileUpdates: true
    provider: 'GitHub'
    enterpriseGradeCdnStatus: 'Enabled'
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${appName}-insights'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    RetentionInDays: environment == 'prod' ? 90 : 30
    IngestionMode: 'ApplicationInsights'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Outputs
output backendUrl string = 'https://${backendWebApp.properties.defaultHostName}'
output frontendUrl string = 'https://${frontendWebApp.properties.defaultHostName}'
output appInsightsKey string = appInsights.properties.InstrumentationKey
```

### Deployment Script

```bash
#!/bin/bash
# File: infrastructure/exercise1/deploy.sh

# Copilot Agent Prompt:
# Create a complete deployment script that:
# 1. Creates resource group
# 2. Validates Bicep template
# 3. Deploys infrastructure
# 4. Deploys application code
# 5. Runs health checks
# 6. Shows URLs and connection strings

RESOURCE_GROUP="rg-module07-exercise1"
LOCATION="eastus2"
ENVIRONMENT="dev"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Deploy infrastructure
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file main.bicep \
  --parameters environment=$ENVIRONMENT \
  --query "[properties.outputs.backendUrl.value, properties.outputs.frontendUrl.value]" \
  --output table
```

### GitHub Actions Workflow

```yaml
# File: .github/workflows/deploy-exercise1.yml
name: Deploy Exercise 1 - Todo App

on:
  push:
    branches: [main]
    paths:
      - 'exercises/exercise-1-todo/**'
  workflow_dispatch:

env:
  AZURE_RESOURCE_GROUP: rg-module07-exercise1
  LOCATION: eastus2

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Deploy Infrastructure
      uses: azure/arm-deploy@v1
      with:
        resourceGroupName: ${{ env.AZURE_RESOURCE_GROUP }}
        template: ./infrastructure/exercise1/main.bicep
        parameters: environment=prod
    
    - name: Deploy Backend
      uses: azure/webapps-deploy@v2
      with:
        app-name: todo-app-api
        package: ./exercises/exercise-1-todo/solution/backend
    
    - name: Build and Deploy Frontend
      run: |
        cd exercises/exercise-1-todo/solution/frontend
        npm install
        npm run build
        # Deploy to Static Web App
```

**💡 Exploration Tip**: Add Azure SQL Database to replace SQLite for production use!

## 📦 Exercise 2: Smart Notes Azure Deployment

### Complete Bicep Template

```bicep
// File: infrastructure/exercise2/main.bicep
// Deploy Smart Notes application with advanced features

@description('Environment name')
param environment string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Enable AI features')
param enableAI bool = true

var appName = 'smart-notes-${environment}'

// Static Web App for the Notes Application
resource notesApp 'Microsoft.Web/staticSites@2022-03-01' = {
  name: '${appName}-web'
  location: location
  sku: {
    name: environment == 'prod' ? 'Standard' : 'Free'
  }
  properties: {
    repositoryUrl: 'https://github.com/YOUR_GITHUB/smart-notes'
    branch: environment == 'prod' ? 'main' : 'develop'
    buildProperties: {
      appLocation: 'exercises/exercise-2-notes/solution/frontend'
      apiLocation: 'api'
      outputLocation: 'dist'
    }
  }
}

// Optional: Function App for Advanced Features
resource functionApp 'Microsoft.Web/sites@2022-03-01' = if (enableAI) {
  name: '${appName}-functions'
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: functionPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
        {
          name: 'COGNITIVE_SERVICES_KEY'
          value: cognitiveServices.listKeys().key1
        }
      ]
    }
  }
}

// Consumption Plan for Functions
resource functionPlan 'Microsoft.Web/serverfarms@2022-03-01' = if (enableAI) {
  name: '${appName}-func-plan'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

// Cognitive Services for AI Features
resource cognitiveServices 'Microsoft.CognitiveServices/accounts@2022-12-01' = if (enableAI) {
  name: '${appName}-cognitive'
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'CognitiveServices'
  properties: {
    apiProperties: {
      statisticsEnabled: false
    }
  }
}

// Storage Account for Note Attachments
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: '${replace(appName, '-', '')}storage'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }
}

// CDN for Global Performance
resource cdn 'Microsoft.Cdn/profiles@2021-06-01' = if (environment == 'prod') {
  name: '${appName}-cdn'
  location: 'global'
  sku: {
    name: 'Standard_Microsoft'
  }
}

output appUrl string = 'https://${notesApp.properties.defaultHostName}'
output storageConnectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
```

### Advanced Deployment with AI Features

```markdown
# Copilot Agent Prompt:
Create a deployment script for Smart Notes that:

1. Deploys core infrastructure
2. Configures AI services:
   - Text analytics for auto-tagging
   - Translation for multi-language
   - OCR for image-to-text
3. Sets up CDN for performance
4. Configures custom domain
5. Implements backup strategy
6. Sets up monitoring alerts

Include cost optimization for dev/prod environments.
```

**💡 Exploration Tip**: Add Azure Search for advanced full-text search capabilities!

## 📦 Exercise 3: AI Recipe Assistant Azure Deployment

### Production-Ready Bicep Template

```bicep
// File: infrastructure/exercise3/main.bicep
// Deploy AI Recipe Assistant with enterprise features

@description('Environment configuration')
param environment string = 'dev'

@description('OpenAI API Key')
@secure()
param openAIApiKey string

@description('Location for resources')
param location string = resourceGroup().location

var appName = 'ai-recipes-${environment}'

// Key Vault for Secrets
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: '${appName}-kv'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: true
  }
}

// Store OpenAI Key in Key Vault
resource openAISecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'openai-api-key'
  properties: {
    value: openAIApiKey
  }
}

// App Service Plan with Autoscaling
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${appName}-plan'
  location: location
  sku: {
    name: environment == 'prod' ? 'P1v3' : 'B2'
    capacity: environment == 'prod' ? 2 : 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// Autoscale Settings
resource autoScale 'Microsoft.Insights/autoscalesettings@2022-10-01' = if (environment == 'prod') {
  name: '${appName}-autoscale'
  location: location
  properties: {
    targetResourceUri: appServicePlan.id
    enabled: true
    profiles: [
      {
        name: 'Scale based on CPU'
        capacity: {
          minimum: '2'
          maximum: '10'
          default: '2'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 70
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
  }
}

// Backend API App
resource backendApp 'Microsoft.Web/sites@2022-03-01' = {
  name: '${appName}-api'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'
      appSettings: [
        {
          name: 'OPENAI_API_KEY'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=openai-api-key)'
        }
        {
          name: 'REDIS_CONNECTION'
          value: '${redisCache.properties.hostName}:6380,password=${redisCache.listKeys().primaryKey},ssl=True,abortConnect=False'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'RATE_LIMIT_PER_MINUTE'
          value: environment == 'prod' ? '60' : '10'
        }
      ]
      alwaysOn: true
      http20Enabled: true
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

// Redis Cache for API Responses
resource redisCache 'Microsoft.Cache/redis@2022-06-01' = {
  name: '${appName}-redis'
  location: location
  properties: {
    sku: {
      name: environment == 'prod' ? 'Premium' : 'Basic'
      family: environment == 'prod' ? 'P' : 'C'
      capacity: environment == 'prod' ? 1 : 0
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    redisConfiguration: {
      'maxmemory-policy': 'allkeys-lru'
    }
  }
}

// API Management for Rate Limiting and Security
resource apiManagement 'Microsoft.ApiManagement/service@2021-08-01' = if (environment == 'prod') {
  name: '${appName}-apim'
  location: location
  sku: {
    name: 'Consumption'
    capacity: 0
  }
  properties: {
    publisherEmail: 'admin@example.com'
    publisherName: 'AI Recipe Platform'
  }
}

// Frontend Static Web App
resource frontendApp 'Microsoft.Web/staticSites@2022-03-01' = {
  name: '${appName}-web'
  location: location
  sku: {
    name: environment == 'prod' ? 'Standard' : 'Free'
  }
  properties: {
    repositoryUrl: 'https://github.com/YOUR_GITHUB/ai-recipes'
    branch: 'main'
    buildProperties: {
      appLocation: 'exercises/exercise-3-recipes/solution/frontend'
      apiLocation: ''
      outputLocation: 'dist'
      appBuildCommand: 'npm run build'
      apiBuildCommand: ''
    }
  }
}

// Application Insights with Alerts
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${appName}-insights'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    RetentionInDays: 90
  }
}

// Alert for High API Usage
resource highApiUsageAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${appName}-high-api-usage'
  location: 'global'
  properties: {
    severity: 2
    enabled: true
    scopes: [
      appInsights.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'High API calls'
          metricName: 'requests/count'
          dimensions: []
          operator: 'GreaterThan'
          threshold: 1000
          timeAggregation: 'Count'
        }
      ]
    }
    actions: []
  }
}

// Outputs
output apiUrl string = 'https://${backendApp.properties.defaultHostName}'
output webUrl string = 'https://${frontendApp.properties.defaultHostName}'
output keyVaultName string = keyVault.name
output appInsightsKey string = appInsights.properties.InstrumentationKey
```

### Complete Deployment Automation

```yaml
# File: .github/workflows/deploy-exercise3.yml
name: Deploy AI Recipe Assistant

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deployment environment'
        required: true
        default: 'dev'
        type: choice
        options:
          - dev
          - staging
          - prod

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Validate Bicep
      run: |
        az bicep build --file infrastructure/exercise3/main.bicep
    
    - name: Estimate Costs
      run: |
        # Add cost estimation script
        echo "Estimated monthly cost: $50-200"

  deploy-infrastructure:
    needs: validate
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'dev' }}
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Create Resource Group
      run: |
        az group create \
          --name rg-ai-recipes-${{ github.event.inputs.environment || 'dev' }} \
          --location eastus2
    
    - name: Deploy Infrastructure
      id: deploy
      run: |
        az deployment group create \
          --resource-group rg-ai-recipes-${{ github.event.inputs.environment || 'dev' }} \
          --template-file infrastructure/exercise3/main.bicep \
          --parameters environment=${{ github.event.inputs.environment || 'dev' }} \
          --parameters openAIApiKey=${{ secrets.OPENAI_API_KEY }}

  deploy-backend:
    needs: deploy-infrastructure
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    
    - name: Deploy to App Service
      uses: azure/webapps-deploy@v2
      with:
        app-name: ai-recipes-${{ github.event.inputs.environment || 'dev' }}-api
        package: ./exercises/exercise-3-recipes/solution/backend

  deploy-frontend:
    needs: deploy-infrastructure
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
    
    - name: Build Frontend
      run: |
        cd exercises/exercise-3-recipes/solution/frontend