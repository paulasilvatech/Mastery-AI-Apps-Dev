# Exercise 1: Deploy Azure Resources with Bicep (Part 2)

## 📝 Part 2: Deploy and Verify

### Step 4: Create Resource Group

First, create a resource group for your deployment:

```bash
# Set variables
RESOURCE_GROUP="rg-workshop-module13"
LOCATION="eastus2"

# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --tags "Module=13" "Purpose=Workshop"
```

### Step 5: Deploy the Template

Now deploy your Bicep template:

```bash
# Deploy the Bicep template
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file main.bicep \
  --parameters @main.parameters.dev.json \
  --name "workshop-deployment-$(date +%s)"
```

**💡 Copilot Prompt Suggestion:**
```bash
# Create a deployment script that:
# - Validates the template first
# - Shows what will be deployed (what-if)
# - Deploys with proper naming
# - Captures outputs to variables
# Include error handling
```

**Expected Copilot Output:**
```bash
#!/bin/bash
# deploy.sh - Deploy Bicep template with validation

set -e  # Exit on error

# Configuration
RESOURCE_GROUP="rg-workshop-module13"
TEMPLATE_FILE="main.bicep"
PARAMETERS_FILE="main.parameters.dev.json"
DEPLOYMENT_NAME="workshop-deploy-$(date +%Y%m%d-%H%M%S)"

echo "🔍 Validating Bicep template..."
if az deployment group validate \
  --resource-group $RESOURCE_GROUP \
  --template-file $TEMPLATE_FILE \
  --parameters @$PARAMETERS_FILE; then
  echo "✅ Template validation successful"
else
  echo "❌ Template validation failed"
  exit 1
fi

echo -e "\n📋 Running what-if analysis..."
az deployment group what-if \
  --resource-group $RESOURCE_GROUP \
  --template-file $TEMPLATE_FILE \
  --parameters @$PARAMETERS_FILE

echo -e "\n🚀 Deploying resources..."
DEPLOYMENT_OUTPUT=$(az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file $TEMPLATE_FILE \
  --parameters @$PARAMETERS_FILE \
  --name $DEPLOYMENT_NAME \
  --output json)

# Extract outputs
WEB_APP_URL=$(echo $DEPLOYMENT_OUTPUT | jq -r '.properties.outputs.webAppUrl.value')
WEB_APP_NAME=$(echo $DEPLOYMENT_OUTPUT | jq -r '.properties.outputs.webAppName.value')

echo -e "\n✅ Deployment complete!"
echo "Web App URL: $WEB_APP_URL"
echo "Web App Name: $WEB_APP_NAME"
```

### Step 6: Verify Deployment

After deployment, verify your resources:

```bash
# List all resources in the resource group
az resource list \
  --resource-group $RESOURCE_GROUP \
  --output table

# Check web app status
WEB_APP_NAME=$(az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name $DEPLOYMENT_NAME \
  --query properties.outputs.webAppName.value \
  --output tsv)

az webapp show \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query "{name:name, state:state, url:defaultHostName}" \
  --output table
```

## 📝 Part 3: Enhance with Copilot

### Step 7: Add Advanced Features

Let's enhance our template with additional features using Copilot.

**💡 Copilot Prompt Suggestion:**
```bicep
// Add to the existing Bicep template:
// - Deployment slots for staging
// - Auto-scaling rules for production
// - Diagnostic settings for all resources
// - Key Vault for storing secrets
// Make it conditional based on environment
```

**Expected Copilot Enhancement:**
```bicep
// Add these resources to your main.bicep

// Key Vault for secrets
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${appName}-${environment}'
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
    softDeleteRetentionInDays: environment == 'prod' ? 90 : 7
    accessPolicies: []
  }
}

// Staging slot for production environment
resource stagingSlot 'Microsoft.Web/sites/slots@2023-01-01' = if (environment == 'prod') {
  parent: webApp
  name: 'staging'
  location: location
  tags: tags
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'
    }
  }
}

// Auto-scaling settings for production
resource autoScaleSettings 'Microsoft.Insights/autoscalesettings@2022-10-01' = if (environment == 'prod') {
  name: 'autoscale-${webAppName}'
  location: location
  tags: tags
  properties: {
    targetResourceUri: appServicePlan.id
    enabled: true
    profiles: [
      {
        name: 'Auto scale based on CPU'
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
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
            }
            scaleAction: {
              direction: 'Decrease'
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

// Diagnostic settings for web app
resource webAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: webApp
  name: 'webAppDiagnostics'
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Log Analytics Workspace (referenced above)
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'log-${appName}-${environment}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: environment == 'prod' ? 90 : 30
  }
}
```

### Step 8: Deploy Enhanced Version

Deploy the enhanced template:

```bash
# Deploy the enhanced template
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file main.bicep \
  --parameters @main.parameters.dev.json \
  --name "enhanced-deployment-$(date +%s)" \
  --mode Complete
```

## 🧪 Validation Tests

Create a test script to validate your deployment:

**💡 Copilot Prompt Suggestion:**
```python
# Create a Python test script that:
# - Checks if all resources exist
# - Validates web app is responding
# - Ensures storage account is accessible
# - Verifies Application Insights is collecting data
# Use Azure SDK for Python
```

**Expected Test Script:**
```python
#!/usr/bin/env python3
# test_deployment.py - Validate Bicep deployment

import sys
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.web import WebSiteManagementClient
from azure.mgmt.storage import StorageManagementClient
from azure.mgmt.applicationinsights import ApplicationInsightsManagementClient
import requests
import os

# Configuration
SUBSCRIPTION_ID = os.environ.get('AZURE_SUBSCRIPTION_ID')
RESOURCE_GROUP = "rg-workshop-module13"

def test_resources_exist():
    """Check if all expected resources exist"""
    credential = DefaultAzureCredential()
    resource_client = ResourceManagementClient(credential, SUBSCRIPTION_ID)
    
    resources = list(resource_client.resources.list_by_resource_group(RESOURCE_GROUP))
    resource_types = [r.type for r in resources]
    
    expected_types = [
        'Microsoft.Web/serverfarms',
        'Microsoft.Web/sites',
        'Microsoft.Storage/storageAccounts',
        'Microsoft.Insights/components'
    ]
    
    for expected in expected_types:
        assert any(expected in rt for rt in resource_types), f"Missing resource type: {expected}"
    
    print("✅ All expected resources exist")

def test_web_app_responding():
    """Check if web app is responding"""
    credential = DefaultAzureCredential()
    web_client = WebSiteManagementClient(credential, SUBSCRIPTION_ID)
    
    web_apps = list(web_client.web_apps.list_by_resource_group(RESOURCE_GROUP))
    assert len(web_apps) > 0, "No web apps found"
    
    web_app = web_apps[0]
    url = f"https://{web_app.default_host_name}"
    
    response = requests.get(url, timeout=30)
    assert response.status_code < 500, f"Web app returned error: {response.status_code}"
    
    print(f"✅ Web app is responding at {url}")

def main():
    """Run all tests"""
    try:
        test_resources_exist()
        test_web_app_responding()
        print("\n🎉 All tests passed!")
        return 0
    except AssertionError as e:
        print(f"\n❌ Test failed: {e}")
        return 1
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
```

## 🎯 Exercise Completion

Congratulations! You've successfully:
- ✅ Created a Bicep template with Copilot assistance
- ✅ Deployed resources to Azure
- ✅ Enhanced the template with advanced features
- ✅ Validated the deployment

## 🔍 Key Takeaways

1. **Bicep Simplicity**: Bicep's declarative syntax is cleaner than ARM JSON
2. **AI Acceleration**: Copilot can generate complex IaC templates quickly
3. **Parameterization**: Use parameters for environment-specific configurations
4. **Validation First**: Always validate before deploying
5. **Incremental Enhancement**: Start simple, add features progressively

## 🚀 Extension Challenges

Try these additional challenges:
1. Add a Redis cache for session management
2. Implement a CDN for static content delivery
3. Create separate parameter files for staging and prod
4. Add network security with private endpoints

## 📚 Additional Resources

- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Bicep Playground](https://bicepdemo.z22.web.core.windows.net/)
- [Azure Quickstart Templates](https://github.com/Azure/azure-quickstart-templates)

## ⏭️ Next Steps

Ready for more? Move on to [Exercise 2: Terraform Multi-Environment Setup](../exercise2-terraform-environments/)

---

*Remember: Infrastructure as Code is about repeatability and reliability. Every deployment should be predictable!*