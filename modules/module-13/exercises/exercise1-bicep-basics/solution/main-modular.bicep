// main-modular.bicep - Modular version using Bicep modules
// Module 13 - Infrastructure as Code with Bicep

@description('The name of the App Service Plan')
param appServicePlanName string = 'asp-${uniqueString(resourceGroup().id)}'

@description('The name of the Web App')
param webAppName string = 'webapp-${uniqueString(resourceGroup().id)}'

@description('The location for all resources')
param location string = resourceGroup().location

@description('The SKU of the App Service Plan')
@allowed([
  'F1'
  'B1'
  'B2'
  'S1'
  'S2'
  'S3'
  'P1v2'
  'P2v2'
  'P3v2'
])
param sku string = 'F1'

@description('The runtime stack of the web app')
param linuxFxVersion string = 'PYTHON|3.11'

@description('Enable Application Insights')
param enableApplicationInsights bool = true

@description('Environment tag')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

// Tags to apply to all resources
var tags = {
  Environment: environment
  ManagedBy: 'Bicep'
  Module: '13'
  Exercise: '1'
  DeploymentType: 'Modular'
}

// App Settings based on Application Insights
var appSettings = enableApplicationInsights ? [
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: monitoring.outputs.connectionString
  }
  {
    name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
    value: '~3'
  }
  {
    name: 'XDT_MicrosoftApplicationInsights_Mode'
    value: 'Recommended'
  }
] : []

// Deploy App Service module
module appService 'modules/appService.bicep' = {
  name: 'appServiceModule'
  params: {
    appServicePlanName: appServicePlanName
    webAppName: webAppName
    location: location
    sku: sku
    linuxFxVersion: linuxFxVersion
    appSettings: appSettings
    tags: tags
  }
}

// Deploy Application Insights module (conditionally)
module monitoring 'modules/monitoring.bicep' = if (enableApplicationInsights) {
  name: 'monitoringModule'
  params: {
    appInsightsName: '${webAppName}-insights'
    location: location
    applicationType: 'web'
    tags: tags
  }
}

// Outputs
output webAppUrl string = appService.outputs.webAppUrl
output webAppName string = appService.outputs.webAppName
output appServicePlanId string = appService.outputs.appServicePlanId
output appInsightsInstrumentationKey string = enableApplicationInsights ? monitoring.outputs.instrumentationKey : 'Not enabled'
output appInsightsConnectionString string = enableApplicationInsights ? monitoring.outputs.connectionString : 'Not enabled' 
