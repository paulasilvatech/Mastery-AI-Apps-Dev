// Reusable Web App Module
// This module creates a web app with best practices

@description('The name of the web app')
param webAppName string

@description('The location for the web app')
param location string = resourceGroup().location

@description('The resource ID of the App Service Plan')
param appServicePlanId string

@description('The runtime stack for the web app')
@allowed([
  'DOTNET|6.0'
  'DOTNET|7.0'
  'NODE|18-lts'
  'NODE|16-lts'
  'PYTHON|3.9'
  'PYTHON|3.10'
  'JAVA|17'
  'JAVA|11'
])
param runtimeStack string = 'DOTNET|6.0'

@description('Enable Application Insights')
param enableApplicationInsights bool = true

@description('Application Insights Instrumentation Key')
param appInsightsInstrumentationKey string = ''

@description('Environment-specific app settings')
param appSettings object = {}

@description('Enable managed identity')
param enableManagedIdentity bool = true

@description('Enable HTTPS only')
param httpsOnly bool = true

@description('Minimum TLS version')
@allowed([
  '1.0'
  '1.1'
  '1.2'
])
param minTlsVersion string = '1.2'

@description('Tags to apply to the resource')
param tags object = {}

// Variables
var defaultAppSettings = {
  WEBSITE_NODE_DEFAULT_VERSION: '~18'
  APPLICATIONINSIGHTS_CONNECTION_STRING: enableApplicationInsights && !empty(appInsightsInstrumentationKey) ? 'InstrumentationKey=${appInsightsInstrumentationKey}' : ''
}

var allAppSettings = union(defaultAppSettings, appSettings)

// Web App Resource
resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  kind: 'app'
  tags: tags
  identity: enableManagedIdentity ? {
    type: 'SystemAssigned'
  } : null
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: httpsOnly
    siteConfig: {
      linuxFxVersion: runtimeStack
      minTlsVersion: minTlsVersion
      ftpsState: 'Disabled'
      http20Enabled: true
      appSettings: [for setting in items(allAppSettings): {
        name: setting.key
        value: setting.value
      }]
      alwaysOn: true
      webSocketsEnabled: false
      use32BitWorkerProcess: false
      healthCheckPath: '/health'
    }
    clientAffinityEnabled: false
  }
}

// Outputs
@description('The resource ID of the web app')
output webAppId string = webApp.id

@description('The name of the web app')
output webAppName string = webApp.name

@description('The default hostname of the web app')
output webAppHostname string = webApp.properties.defaultHostName

@description('The principal ID of the managed identity')
output principalId string = enableManagedIdentity ? webApp.identity.principalId : ''

@description('The outbound IP addresses of the web app')
output outboundIpAddresses string = webApp.properties.outboundIpAddresses 
