# 🏗️ Bicep Infrastructure Templates for Workshop

## Main Bicep Template

### infrastructure/bicep/main.bicep

```bicep
// Main orchestration template for workshop infrastructure
targetScope = 'subscription'

@description('The environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

@description('The Azure region for resources')
param location string = 'eastus2'

@description('The workshop module number (1-30)')
@minValue(1)
@maxValue(30)
param moduleNumber int

@description('Unique suffix for resource names')
param suffix string = uniqueString(subscription().subscriptionId, environment)

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-workshop-module${moduleNumber}-${environment}-${suffix}'
  location: location
  tags: {
    Environment: environment
    Module: 'Module ${moduleNumber}'
    Workshop: 'Mastery AI Code Development'
    ManagedBy: 'Bicep'
  }
}

// Module-specific deployments
module fundamentals './modules/fundamentals.bicep' = if (moduleNumber >= 1 && moduleNumber <= 5) {
  scope: rg
  name: 'fundamentals-deployment'
  params: {
    location: location
    environment: environment
    moduleNumber: moduleNumber
    suffix: suffix
  }
}

module intermediate './modules/intermediate.bicep' = if (moduleNumber >= 6 && moduleNumber <= 10) {
  scope: rg
  name: 'intermediate-deployment'
  params: {
    location: location
    environment: environment
    moduleNumber: moduleNumber
    suffix: suffix
  }
}

module advanced './modules/advanced.bicep' = if (moduleNumber >= 11 && moduleNumber <= 15) {
  scope: rg
  name: 'advanced-deployment'
  params: {
    location: location
    environment: environment
    moduleNumber: moduleNumber
    suffix: suffix
  }
}

module enterprise './modules/enterprise.bicep' = if (moduleNumber >= 16 && moduleNumber <= 20) {
  scope: rg
  name: 'enterprise-deployment'
  params: {
    location: location
    environment: environment
    moduleNumber: moduleNumber
    suffix: suffix
  }
}

module agents './modules/agents.bicep' = if (moduleNumber >= 21 && moduleNumber <= 25) {
  scope: rg
  name: 'agents-deployment'
  params: {
    location: location
    environment: environment
    moduleNumber: moduleNumber
    suffix: suffix
  }
}

module mastery './modules/mastery.bicep' = if (moduleNumber >= 26 && moduleNumber <= 30) {
  scope: rg
  name: 'mastery-deployment'
  params: {
    location: location
    environment: environment
    moduleNumber: moduleNumber
    suffix: suffix
  }
}

// Outputs
output resourceGroupName string = rg.name
output resourceGroupId string = rg.id
```

## Module-Specific Templates

### infrastructure/bicep/modules/fundamentals.bicep

```bicep
// Resources for Fundamentals track (Modules 1-5)
param location string
param environment string
param moduleNumber int
param suffix string

// Storage account for exercises
resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'st${moduleNumber}${environment}${suffix}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
  }
  tags: {
    Module: 'Module ${moduleNumber}'
    Track: 'Fundamentals'
  }
}

// App Service Plan for web exercises
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = if (moduleNumber >= 3) {
  name: 'asp-module${moduleNumber}-${environment}'
  location: location
  sku: {
    name: environment == 'prod' ? 'P1v3' : 'B1'
    tier: environment == 'prod' ? 'PremiumV3' : 'Basic'
  }
  properties: {
    reserved: true // Linux
  }
}

// Key Vault for secrets
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${moduleNumber}-${environment}-${suffix}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
  }
}

output storageAccountName string = storage.name
output appServicePlanId string = appServicePlan.id
output keyVaultName string = keyVault.name
```

### infrastructure/bicep/modules/agents.bicep

```bicep
// Resources for AI Agents track (Modules 21-25)
param location string
param environment string
param moduleNumber int
param suffix string

// Azure OpenAI Service
resource openAI 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: 'openai-module${moduleNumber}-${environment}'
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: 'openai-m${moduleNumber}-${environment}-${suffix}'
    publicNetworkAccess: 'Enabled'
  }
}

// Azure AI Search for vector operations
resource aiSearch 'Microsoft.Search/searchServices@2023-11-01' = {
  name: 'srch-m${moduleNumber}-${environment}-${suffix}'
  location: location
  sku: {
    name: environment == 'prod' ? 'standard' : 'basic'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
  }
}

// Container Instance for MCP Server
resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = if (moduleNumber == 23) {
  name: 'ci-mcp-server-${environment}'
  location: location
  properties: {
    sku: 'Standard'
    containers: [
      {
        name: 'mcp-server'
        properties: {
          image: 'ghcr.io/workshop/mcp-server:latest'
          ports: [
            {
              port: 8080
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              memoryInGB: 1
              cpu: 1
            }
          }
          environmentVariables: [
            {
              name: 'ENVIRONMENT'
              value: environment
            }
          ]
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: 'Always'
    ipAddress: {
      type: 'Public'
      ports: [
        {
          port: 8080
          protocol: 'TCP'
        }
      ]
      dnsNameLabel: 'mcp-${moduleNumber}-${environment}-${suffix}'
    }
  }
}

// Service Bus for agent communication
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: 'sb-agents-${environment}-${suffix}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    minimumTlsVersion: '1.2'
  }
}

resource agentQueue 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  parent: serviceBusNamespace
  name: 'agent-messages'
  properties: {
    maxDeliveryCount: 10
    enablePartitioning: false
  }
}

// Outputs
output openAIEndpoint string = openAI.properties.endpoint
output openAIId string = openAI.id
output aiSearchEndpoint string = 'https://${aiSearch.name}.search.windows.net'
output mcpServerUrl string = moduleNumber == 23 ? 'http://${containerGroup.properties.ipAddress.fqdn}:8080' : ''
output serviceBusConnectionString string = 'Endpoint=sb://${serviceBusNamespace.name}.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=${listKeys('${serviceBusNamespace.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBusNamespace.apiVersion).primaryKey}'
```

### infrastructure/bicep/modules/monitoring.bicep

```bicep
// Shared monitoring resources
param location string
param environment string
param suffix string

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'log-workshop-${environment}-${suffix}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: environment == 'prod' ? 90 : 30
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-workshop-${environment}-${suffix}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    IngestionMode: 'LogAnalytics'
  }
}

// Action Group for alerts
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-workshop-${environment}'
  location: 'global'
  properties: {
    enabled: true
    groupShortName: 'Workshop'
    emailReceivers: [
      {
        name: 'WorkshopAdmin'
        emailAddress: 'admin@workshop.com'
        useCommonAlertSchema: true
      }
    ]
  }
}

// Cost alert
resource budgetAlert 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: 'budget-workshop-${environment}'
  properties: {
    timePeriod: {
      startDate: '2024-01-01'
    }
    timeGrain: 'Monthly'
    amount: environment == 'prod' ? 1000 : 100
    category: 'Cost'
    notifications: {
      actual_GreaterThan_80_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactGroups: [
          actionGroup.id
        ]
        thresholdType: 'Actual'
      }
    }
  }
}

// Outputs
output logAnalyticsId string = logAnalytics.id
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
```

### infrastructure/bicep/modules/networking.bicep

```bicep
// Network infrastructure for advanced modules
param location string
param environment string
param suffix string

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-workshop-${environment}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-apps'
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'subnet-agents'
        properties: {
          addressPrefix: '10.0.2.0/24'
          delegations: []
        }
      }
      {
        name: 'subnet-data'
        properties: {
          addressPrefix: '10.0.3.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-workshop-${environment}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

// Outputs
output vnetId string = vnet.id
output subnetIds object = {
  apps: vnet.properties.subnets[0].id
  agents: vnet.properties.subnets[1].id
  data: vnet.properties.subnets[2].id
}
```

## Parameter Files

### infrastructure/bicep/parameters/dev.parameters.json

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environment": {
      "value": "dev"
    },
    "location": {
      "value": "eastus2"
    },
    "moduleNumber": {
      "value": 1
    }
  }
}
```

## Deployment Scripts

### scripts/deploy-infrastructure.sh

```bash
#!/bin/bash
# Deploy infrastructure for a specific module

set -e

# Parameters
MODULE_NUMBER=${1:-1}
ENVIRONMENT=${2:-dev}
LOCATION=${3:-eastus2}

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "🚀 Deploying infrastructure for Module $MODULE_NUMBER ($ENVIRONMENT environment)"

# Login check
if ! az account show &>/dev/null; then
    echo "⚠️  Please login to Azure first:"
    az login
fi

# Set subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "📍 Using subscription: $SUBSCRIPTION_ID"

# Deploy
DEPLOYMENT_NAME="workshop-module${MODULE_NUMBER}-${ENVIRONMENT}-$(date +%Y%m%d%H%M%S)"

az deployment sub create \
    --name "$DEPLOYMENT_NAME" \
    --location "$LOCATION" \
    --template-file infrastructure/bicep/main.bicep \
    --parameters \
        environment="$ENVIRONMENT" \
        location="$LOCATION" \
        moduleNumber="$MODULE_NUMBER" \
    --output table

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Infrastructure deployed successfully!${NC}"
    
    # Get outputs
    RG_NAME=$(az deployment sub show -n "$DEPLOYMENT_NAME" --query properties.outputs.resourceGroupName.value -o tsv)
    echo "📦 Resource Group: $RG_NAME"
    
    # List resources
    echo "📋 Resources created:"
    az resource list -g "$RG_NAME" --query "[].{Name:name, Type:type}" -o table
else
    echo -e "${RED}❌ Deployment failed${NC}"
    exit 1
fi
```

### scripts/cleanup-infrastructure.sh

```bash
#!/bin/bash
# Clean up infrastructure for a specific module

set -e

MODULE_NUMBER=${1:-1}
ENVIRONMENT=${2:-dev}

echo "🧹 Cleaning up infrastructure for Module $MODULE_NUMBER ($ENVIRONMENT environment)"

# Find resource groups
RG_PATTERN="rg-workshop-module${MODULE_NUMBER}-${ENVIRONMENT}-*"
RESOURCE_GROUPS=$(az group list --query "[?starts_with(name, 'rg-workshop-module${MODULE_NUMBER}-${ENVIRONMENT}')].name" -o tsv)

if [ -z "$RESOURCE_GROUPS" ]; then
    echo "✅ No resource groups found matching pattern: $RG_PATTERN"
    exit 0
fi

echo "Found resource groups to delete:"
echo "$RESOURCE_GROUPS"

read -p "Are you sure you want to delete these resource groups? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    for RG in $RESOURCE_GROUPS; do
        echo "🗑️  Deleting resource group: $RG"
        az group delete --name "$RG" --yes --no-wait
    done
    echo "✅ Cleanup initiated. Resources will be deleted in the background."
else
    echo "❌ Cleanup cancelled"
    exit 1
fi
```

## GitOps Integration

### .github/workflows/deploy-infrastructure.yml

```yaml
name: Deploy Infrastructure

on:
  workflow_dispatch:
    inputs:
      module_number:
        description: 'Module number (1-30)'
        required: true
        type: number
        default: 1
      environment:
        description: 'Environment'
        required: true
        type: choice
        options:
          - dev
          - staging
          - prod

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Deploy Infrastructure
        uses: azure/arm-deploy@v1
        with:
          deploymentName: workshop-m${{ inputs.module_number }}-${{ inputs.environment }}
          region: eastus2
          scope: subscription
          template: ./infrastructure/bicep/main.bicep
          parameters: >
            environment=${{ inputs.environment }}
            moduleNumber=${{ inputs.module_number }}
            location=eastus2
      
      - name: Output Resource Group
        run: |
          echo "✅ Infrastructure deployed for Module ${{ inputs.module_number }}"
          echo "Environment: ${{ inputs.environment }}"
```

## Cost Optimization Tags

All resources include standard tags for cost tracking:

```bicep
tags: {
  Environment: environment
  Module: 'Module ${moduleNumber}'
  Workshop: 'Mastery AI Code Development'
  ManagedBy: 'Bicep'
  CostCenter: 'Training'
  AutoShutdown: environment == 'dev' ? 'true' : 'false'
}
```

These templates provide a complete infrastructure foundation for the entire workshop, with proper parameterization, security, and cost controls.
