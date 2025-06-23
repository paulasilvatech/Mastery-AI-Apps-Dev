// advanced.bicep - Advanced Bicep features (Complete Solution)
// Module 13 - Infrastructure as Code with Bicep

@description('Base name for the web apps')
param baseAppName string = 'myapp'

@description('Number of web app instances to create')
@minValue(1)
@maxValue(5)
param instanceCount int = 3

@description('The location for all resources')
param location string = resourceGroup().location

@description('Environment names for each instance')
param environments array = [
  'dev'
  'test'
  'staging'
]

@description('Enable Application Insights for non-dev environments')
param enableMonitoring bool = true

// SKU mapping based on environment
var skuMap = {
  dev: 'F1'
  test: 'B1'
  staging: 'S1'
  prod: 'P1v2'
}

// Tags for all resources
var tags = {
  ManagedBy: 'Bicep'
  Module: '13'
  Exercise: '1-Advanced'
  DeploymentType: 'Loop'
}

// Single App Service Plan for all apps
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${baseAppName}-plan'
  location: location
  tags: tags
  sku: {
    name: 'S1' // Using S1 to support multiple apps
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// Create multiple web apps using a loop
resource webApps 'Microsoft.Web/sites@2023-01-01' = [for i in range(0, instanceCount): {
  name: '${baseAppName}-${environments[i]}-${uniqueString(resourceGroup().id)}'
  location: location
  tags: union(tags, {
    Environment: environments[i]
  })
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.11'
      appSettings: environments[i] != 'dev' && enableMonitoring ? [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights[i].properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
      ] : []
    }
    httpsOnly: true
  }
}]

// Create Application Insights for non-dev environments
resource appInsights 'Microsoft.Insights/components@2020-02-02' = [for i in range(0, instanceCount): if (environments[i] != 'dev' && enableMonitoring) {
  name: '${baseAppName}-${environments[i]}-insights'
  location: location
  tags: union(tags, {
    Environment: environments[i]
  })
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    RetentionInDays: environments[i] == 'staging' ? 90 : 30
    WorkspaceResourceId: logWorkspace.id
  }
}]

// Shared Log Analytics Workspace
resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enableMonitoring) {
  name: '${baseAppName}-workspace'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Using modules in a loop (alternative approach)
module webAppModules 'modules/appService.bicep' = [for (env, i) in environments: if (i >= instanceCount) {
  name: 'webApp-${env}-module'
  params: {
    appServicePlanName: '${baseAppName}-${env}-plan'
    webAppName: '${baseAppName}-${env}-modular'
    location: location
    sku: contains(skuMap, env) ? skuMap[env] : 'F1'
    tags: union(tags, {
      Environment: env
      DeploymentMethod: 'Module'
    })
  }
}]

// Reference existing resources (example)
resource existingResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: resourceGroup().name
  scope: subscription()
}

// Complex outputs using loops and conditions
output webAppUrls array = [for i in range(0, instanceCount): 'https://${webApps[i].properties.defaultHostName}']
output webAppNames array = [for i in range(0, instanceCount): webApps[i].name]
output appInsightsKeys array = [for i in range(0, instanceCount): environments[i] != 'dev' && enableMonitoring ? appInsights[i].properties.InstrumentationKey : 'Not enabled']

// Environment configuration as array of objects
output environmentConfiguration array = [for i in range(0, instanceCount): {
  environment: environments[i]
  webAppName: webApps[i].name
  webAppUrl: 'https://${webApps[i].properties.defaultHostName}'
  monitoringEnabled: environments[i] != 'dev' && enableMonitoring
  appInsightsKey: environments[i] != 'dev' && enableMonitoring ? appInsights[i].properties.InstrumentationKey : 'N/A'
}]

// Output resource group information
output resourceGroupInfo object = {
  name: existingResourceGroup.name
  location: existingResourceGroup.location
  id: existingResourceGroup.id
} 
