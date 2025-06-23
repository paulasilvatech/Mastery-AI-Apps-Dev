// Monitoring Module
// This module creates Application Insights and Log Analytics workspace

@description('The base name for monitoring resources')
param baseName string

@description('The location for resources')
param location string = resourceGroup().location

@description('Log Analytics workspace retention in days')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('Application type for Application Insights')
@allowed([
  'web'
  'other'
])
param applicationType string = 'web'

@description('Enable public network access')
param enablePublicNetworkAccess bool = true

@description('Tags to apply to resources')
param tags object = {}

// Variables
var logAnalyticsName = 'log-${baseName}'
var appInsightsName = 'appi-${baseName}'

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    publicNetworkAccessForIngestion: enablePublicNetworkAccess ? 'Enabled' : 'Disabled'
    publicNetworkAccessForQuery: enablePublicNetworkAccess ? 'Enabled' : 'Disabled'
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: applicationType
  tags: tags
  properties: {
    Application_Type: applicationType
    WorkspaceResourceId: logAnalytics.id
    publicNetworkAccessForIngestion: enablePublicNetworkAccess ? 'Enabled' : 'Disabled'
    publicNetworkAccessForQuery: enablePublicNetworkAccess ? 'Enabled' : 'Disabled'
  }
}

// Diagnostic Settings for Log Analytics
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${logAnalyticsName}'
  scope: logAnalytics
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'Audit'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: retentionInDays
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: retentionInDays
        }
      }
    ]
  }
}

// Outputs
@description('The resource ID of the Log Analytics workspace')
output logAnalyticsId string = logAnalytics.id

@description('The workspace ID of Log Analytics')
output logAnalyticsWorkspaceId string = logAnalytics.properties.customerId

@description('The name of the Log Analytics workspace')
output logAnalyticsName string = logAnalytics.name

@description('The resource ID of Application Insights')
output appInsightsId string = appInsights.id

@description('The instrumentation key of Application Insights')
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey

@description('The connection string of Application Insights')
output appInsightsConnectionString string = appInsights.properties.ConnectionString

@description('The name of Application Insights')
output appInsightsName string = appInsights.name 
