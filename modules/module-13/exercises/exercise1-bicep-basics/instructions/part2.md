# Exercise 1: Bicep Fundamentals - Part 2

## 🎯 Objective

Enhance your Bicep template with database resources, monitoring, and secure configurations.

## 📚 Continuing from Part 1

In Part 1, you created the basic infrastructure. Now you'll add:
- Azure SQL Database with server
- Application Insights for monitoring
- Secure connection strings
- Parameter file for different environments

## 🛠️ Step 5: Add Database Resources

### 5.1 Add Database Parameters

Add these parameters after your existing ones:

**Copilot Prompt:**
```
Add Bicep parameters for SQL Database:
- sqlAdminUsername (string): SQL admin username
- sqlAdminPassword (secure string): SQL admin password with minLength 8
- databaseSku (string): Database SKU with default Basic
```

**Expected Result:**
```bicep
@description('SQL Server administrator username')
@minLength(4)
param sqlAdminUsername string

@description('SQL Server administrator password')
@secure()
@minLength(8)
param sqlAdminPassword string

@description('SQL Database SKU')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param databaseSku string = 'Basic'
```

### 5.2 Create SQL Server

Add the SQL Server resource:

**Copilot Prompt:**
```
Create Bicep resource for SQL Server:
- Unique name using variables
- Use provided admin credentials
- Enable Azure AD authentication
- Set minimum TLS version to 1.2
- Add firewall rule for Azure services
```

**Expected Result:**
```bicep
// Variables for SQL resources
var sqlServerName = 'sql-${appName}-${environment}-${uniqueSuffix}'
var databaseName = 'db-${appName}-${environment}'

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: {
    environment: environment
    createdBy: 'Bicep'
    module: 'module-13'
  }
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

// Firewall rule to allow Azure services
resource sqlFirewallRule 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}
```

### 5.3 Create SQL Database

Add the database:

**Copilot Prompt:**
```
Create Bicep resource for SQL Database:
- Reference the SQL Server as parent
- Use databaseSku parameter
- Set appropriate collation
- Enable automatic tuning
- Add diagnostic settings placeholder
```

**Expected Result:**
```bicep
// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  tags: {
    environment: environment
    createdBy: 'Bicep'
    module: 'module-13'
  }
  sku: {
    name: databaseSku
    tier: databaseSku
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: databaseSku == 'Basic' ? 2147483648 : 268435456000 // 2GB for Basic, 250GB for others
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: false
    readScale: 'Disabled'
    requestedBackupStorageRedundancy: 'Local'
  }
}
```

## 🛠️ Step 6: Add Monitoring

### 6.1 Application Insights

Add monitoring capabilities:

**Copilot Prompt:**
```
Create Bicep resources for Application Insights:
- Log Analytics Workspace
- Application Insights instance
- Link to the web app
```

**Expected Result:**
```bicep
// Variables for monitoring
var logAnalyticsName = 'log-${appName}-${environment}-${uniqueSuffix}'
var appInsightsName = 'appi-${appName}-${environment}-${uniqueSuffix}'

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  tags: {
    environment: environment
    createdBy: 'Bicep'
    module: 'module-13'
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: {
    environment: environment
    createdBy: 'Bicep'
    module: 'module-13'
  }
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    RetentionInDays: 30
  }
}
```

### 6.2 Update Web App Configuration

Update the web app to use Application Insights:

```bicep
// Update the existing webApp resource - modify the appSettings array
siteConfig: {
  netFrameworkVersion: 'v6.0'
  appSettings: [
    {
      name: 'ENVIRONMENT'
      value: environment
    }
    {
      name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
      value: appInsights.properties.InstrumentationKey
    }
    {
      name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
      value: appInsights.properties.ConnectionString
    }
    {
      name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
      value: '~3'
    }
  ]
  connectionStrings: [
    {
      name: 'DefaultConnection'
      connectionString: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${databaseName};Persist Security Info=False;User ID=${sqlAdminUsername};Password=${sqlAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
      type: 'SQLAzure'
    }
  ]
}
```

## 🛠️ Step 7: Create Parameter File

### 7.1 Development Parameters

Create `parameters.dev.json`:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "appName": {
      "value": "workshop13"
    },
    "environment": {
      "value": "dev"
    },
    "skuName": {
      "value": "F1"
    },
    "sqlAdminUsername": {
      "value": "sqladmin"
    },
    "databaseSku": {
      "value": "Basic"
    }
  }
}
```

### 7.2 Production Parameters

Create `parameters.prod.json`:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "appName": {
      "value": "workshop13"
    },
    "environment": {
      "value": "prod"
    },
    "skuName": {
      "value": "S1"
    },
    "sqlAdminUsername": {
      "value": "sqladmin"
    },
    "databaseSku": {
      "value": "Standard"
    }
  }
}
```

## 🛠️ Step 8: Enhanced Outputs

### 8.1 Update Outputs Section

Replace the outputs with more comprehensive information:

```bicep
// Outputs
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output webAppName string = webApp.name
output storageAccountName string = storageAccount.name
output sqlServerName string = sqlServer.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output databaseName string = sqlDatabase.name
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output resourceGroupName string = resourceGroup().name
```

## 🚀 Step 9: Deploy Your Infrastructure

### 9.1 Create Resource Group

```bash
# Set variables
RESOURCE_GROUP="rg-module13-exercise1-dev"
LOCATION="eastus2"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION
```

### 9.2 Deploy the Template

```bash
# Deploy using parameter file
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file main.bicep \
  --parameters @parameters.dev.json \
  --parameters sqlAdminPassword="P@ssw0rd123!" \
  --name "exercise1-deployment-$(date +%Y%m%d%H%M%S)"
```

### 9.3 Verify Deployment

```bash
# Check deployment status
az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name exercise1-deployment-* \
  --query properties.provisioningState

# List all resources
az resource list \
  --resource-group $RESOURCE_GROUP \
  --output table
```

## ✅ Validation

Verify your deployment:

1. **Web App Access:**
   ```bash
   # Get web app URL
   az webapp show \
     --resource-group $RESOURCE_GROUP \
     --name $(az webapp list -g $RESOURCE_GROUP --query "[0].name" -o tsv) \
     --query defaultHostName -o tsv
   ```

2. **Database Connection:**
   - Navigate to SQL Database in Azure Portal
   - Use Query Editor to test connection

3. **Application Insights:**
   - Check Live Metrics in Azure Portal
   - Verify telemetry is being collected

## 🎯 Summary

In Part 2, you've:
- ✅ Added Azure SQL Database with security
- ✅ Implemented Application Insights monitoring
- ✅ Created parameter files for multiple environments
- ✅ Deployed infrastructure to Azure
- ✅ Validated all resources are working

## 🏆 Bonus Challenges

Try these additional improvements:

1. **Add Key Vault:**
   - Store SQL password securely
   - Reference in Bicep using Key Vault reference

2. **Enable Backup:**
   - Configure automated SQL backup
   - Set retention policies

3. **Add Alerts:**
   - Create metric alerts for high CPU
   - Set up email notifications

## 🧹 Cleanup

When you're done experimenting:

```bash
# Delete the resource group
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

## 📚 Additional Resources

- [Bicep Best Practices](https://learn.microsoft.com/azure/azure-resource-manager/bicep/best-practices)
- [Bicep Functions Reference](https://learn.microsoft.com/azure/azure-resource-manager/bicep/bicep-functions)
- [Azure Resource Reference](https://learn.microsoft.com/azure/templates/)

---

🎉 **Congratulations!** You've completed Exercise 1 and built your first production-ready Bicep template!

**Next Steps:** Proceed to Exercise 2 to learn Terraform and multi-environment deployments.