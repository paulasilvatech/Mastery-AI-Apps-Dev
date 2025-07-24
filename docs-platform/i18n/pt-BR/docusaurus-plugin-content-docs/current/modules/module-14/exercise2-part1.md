---
sidebar_position: 2
title: "Exercise 2: Part 1"
description: "**Duration:** 45-60 minutes"
---

# Exercício 2: Multi-ambiente implantação (⭐⭐)

**Duração:** 45-60 minutos  
**Difficulty:** Médio  
**Success Rate:** 80%

## 🎯 Objetivos de Aprendizagem

In this exercise, you will:
- Create multi-stage implantação pipelines
- Implement ambiente-specific configurations
- Use GitHub Environments with protection rules
- Deploy to Azure App Service
- Implement blue-green implantação strategy
- Add automated smoke tests
- Configure rollback mechanisms

## 📋 Scenario

Your team wants to implement a proper implantação pipeline with multiple ambientes (desenvolvimento, staging, produção). Each ambiente should have its own configuration, approval process, and implantação strategy. You'll deploy to Azure App Service with zero-downtime implantaçãos.

## 🏗️ Architecture Visão Geral

```mermaid
graph TB
    A[Code Push] --&gt; B[CI Pipeline]
    B --&gt; C{Branch?}
    C --&gt;|develop| D[Deploy to Dev]
    C --&gt;|main| E[Deploy to Staging]
    E --&gt; F[Manual Approval]
    F --&gt; G[Deploy to Production]
    
    D --&gt; H[Smoke Tests]
    E --&gt; I[Integration Tests]
    G --&gt; J[Health Checks]
    
    G --&gt; K{Deployment Strategy}
    K --&gt; L[Blue/Green Swap]
    K --&gt; M[Canary Release]
    
    style F fill:#f96,stroke:#333,stroke-width:4px
    style L fill:#9f6,stroke:#333,stroke-width:2px
```

## 📝 Partee 1: Setting Up Multi-ambiente Infrastructure

### Step 1: Create Azure Recursos

First, let's create a Bicep template for our infrastructure:

**infrastructure/main.bicep:**

**Copilot Prompt Suggestion:**
```bicep
// Create Azure infrastructure for multi-environment deployment:
// - Resource group parameters for dev, staging, prod
// - App Service Plan with Standard tier
// - App Service with deployment slots for blue-green
// - Application Insights for each environment
// - Key Vault for secrets
// - Storage account for artifacts
// Use parameter files for environment-specific values
// Include tags for environment and cost tracking
```

**Expected Output:**
```bicep
@description('The environment name')
@allowed(['dev', 'staging', 'prod'])
param environmentName string

@description('The location for all resources')
param location string = resourceGroup().location

@description('The name prefix for all resources')
param namePrefix string = 'workshop'

@description('The SKU for App Service Plan')
param appServicePlanSku string = environmentName == 'prod' ? 'P1V3' : 'B1'

// Variables
var appServicePlanName = '${namePrefix}-asp-${environmentName}'
var appServiceName = '${namePrefix}-app-${environmentName}'
var appInsightsName = '${namePrefix}-ai-${environmentName}'
var keyVaultName = '${namePrefix}-kv-${environmentName}'
var storageAccountName = '${namePrefix}st${environmentName}'

// Tags
var tags = {
  Environment: environmentName
  Project: 'CICD-Workshop'
  ManagedBy: 'Bicep'
  CostCenter: 'Engineering'
}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: appServicePlanSku
    capacity: environmentName == 'prod' ? 2 : 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    RetentionInDays: environmentName == 'prod' ? 90 : 30
  }
}

// App Service
resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: appServiceName
  location: location
  tags: tags
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'
      alwaysOn: environmentName != 'dev'
      ftpsState: 'Disabled'
      http20Enabled: true
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'ENVIRONMENT'
          value: environmentName
        }
      ]
    }
    httpsOnly: true
  }
}

// Deployment slot for production (blue-green deployment)
resource deploymentSlot 'Microsoft.Web/sites/slots@2023-01-01' = if (environmentName == 'prod') {
  parent: appService
  name: 'staging'
  location: location
  tags: tags
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'
      alwaysOn: true
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'ENVIRONMENT'
          value: '${environmentName}-staging'
        }
      ]
    }
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: environmentName == 'prod' ? 90 : 7
    accessPolicies: []
  }
}

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: environmentName == 'prod' ? 'Standard_GRS' : 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

// Outputs
output appServiceName string = appService.name
output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
output deploymentSlotName string = environmentName == 'prod' ? deploymentSlot.name : ''
output keyVaultName string = keyVault.name
output storageAccountName string = storageAccount.name
```

### Step 2: Create ambiente-Specific Parameter Files

**infrastructure/parameters.dev.json:**
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environmentName": {
      "value": "dev"
    },
    "namePrefix": {
      "value": "workshop"
    }
  }
}
```

**infrastructure/parameters.staging.json:**
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environmentName": {
      "value": "staging"
    },
    "namePrefix": {
      "value": "workshop"
    }
  }
}
```

**infrastructure/parameters.prod.json:**
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environmentName": {
      "value": "prod"
    },
    "namePrefix": {
      "value": "workshop"
    },
    "appServicePlanSku": {
      "value": "P1V3"
    }
  }
}
```

### Step 3: Create implantação Workflow

Now let's create a comprehensive implantação workflow:

**.github/workflows/deploy.yml:**

**Copilot Prompt Suggestion:**
```yaml
# Create a deployment workflow that:
# - Triggers on successful CI pipeline completion
# - Has separate jobs for dev, staging, and production
# - Uses GitHub Environments with protection rules
# - Deploys infrastructure using Bicep
# - Deploys application to Azure App Service
# - Runs smoke tests after deployment
# - Implements blue-green deployment for production
# - Includes rollback capability
# - Uses Azure CLI for deployment
# - Stores deployment history
```

**Expected Output (Partee 1):**
```yaml
name: Deploy to Azure

on:
  workflow_run:
    workflows: ["CI Pipeline"]
    types:
      - completed
    branches:
      - main
      - develop
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        default: 'dev'
        type: choice
        options:
          - dev
          - staging
          - prod

env:
  AZURE_WEBAPP_PACKAGE_PATH: '.'
  PYTHON_VERSION: '3.11'

jobs:
  prepare-deployment:
    name: Prepare Deployment
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'success' || github.event_name == 'workflow_dispatch' }}
    outputs:
      environment: ${{ steps.determine-env.outputs.environment }}
      version: ${{ steps.version.outputs.version }}
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Determine environment
      id: determine-env
      run: |
        if [[ "${{ github.event_name }}" == "workflow_dispatch" ]]; then
          echo "environment=${{ github.event.inputs.environment }}" &gt;&gt; $GITHUB_OUTPUT
        elif [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
          echo "environment=staging" &gt;&gt; $GITHUB_OUTPUT
        elif [[ "${{ github.ref }}" == "refs/heads/develop" ]]; then
          echo "environment=dev" &gt;&gt; $GITHUB_OUTPUT
        else
          echo "environment=dev" &gt;&gt; $GITHUB_OUTPUT
        fi
    
    - name: Generate version
      id: version
      run: |
        VERSION="${{ github.run_number }}-${GITHUB_SHA::7}"
        echo "version=$VERSION" &gt;&gt; $GITHUB_OUTPUT
        echo "Deployment version: $VERSION"

  deploy-infrastructure:
    name: Deploy Infrastructure - ${{ needs.prepare-deployment.outputs.environment }}
    runs-on: ubuntu-latest
    needs: prepare-deployment
    environment: 
      name: ${{ needs.prepare-deployment.outputs.environment }}
    outputs:
      appServiceName: ${{ steps.deploy.outputs.appServiceName }}
      appServiceUrl: ${{ steps.deploy.outputs.appServiceUrl }}
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Create Resource Group
      run: |
        az group create \
          --name "rg-workshop-${{ needs.prepare-deployment.outputs.environment }}" \
          --location "eastus"
    
    - name: Deploy Bicep Template
      id: deploy
      run: |
        outputs=$(az deployment group create \
          --resource-group "rg-workshop-${{ needs.prepare-deployment.outputs.environment }}" \
          --template-file infrastructure/main.bicep \
          --parameters infrastructure/parameters.${{ needs.prepare-deployment.outputs.environment }}.json \
          --query properties.outputs \
          --output json)
        
        echo "appServiceName=$(echo $outputs | jq -r .appServiceName.value)" &gt;&gt; $GITHUB_OUTPUT
        echo "appServiceUrl=$(echo $outputs | jq -r .appServiceUrl.value)" &gt;&gt; $GITHUB_OUTPUT
    
    - name: Update deployment summary
      run: |
        echo "## Infrastructure Deployment 🏗️" &gt;&gt; $GITHUB_STEP_SUMMARY
        echo "- **Environment:** ${{ needs.prepare-deployment.outputs.environment }}" &gt;&gt; $GITHUB_STEP_SUMMARY
        echo "- **App Service:** ${{ steps.deploy.outputs.appServiceName }}" &gt;&gt; $GITHUB_STEP_SUMMARY
        echo "- **URL:** ${{ steps.deploy.outputs.appServiceUrl }}" &gt;&gt; $GITHUB_STEP_SUMMARY
```

**Continuar to Partee 2 for application implantação and testing...**