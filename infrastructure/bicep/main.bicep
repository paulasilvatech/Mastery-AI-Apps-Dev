// main.bicep - Main infrastructure template for Mastery AI Workshop
targetScope = 'resourceGroup'

@description('The environment name (dev, staging, prod)')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string = 'dev'

@description('The location for all resources')
param location string = resourceGroup().location

@description('The base name for all resources')
param baseName string = 'mastery-ai-workshop'

@description('Enable AI services')
param enableAIServices bool = true

@description('Enable monitoring')
param enableMonitoring bool = true

// Variables
var resourcePrefix = '${baseName}-${environment}'
var tags = {
  Environment: environment
  Project: 'Mastery AI Workshop'
  ManagedBy: 'Bicep'
}

// Storage Account for workshop assets
module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    storageAccountName: replace('${resourcePrefix}storage', '-', '')
    location: location
    tags: tags
  }
}

// Container Registry for Docker images
module containerRegistry 'modules/container-registry.bicep' = {
  name: 'containerRegistry'
  params: {
    registryName: replace('${resourcePrefix}acr', '-', '')
    location: location
    tags: tags
  }
}

// Key Vault for secrets
module keyVault 'modules/key-vault.bicep' = {
  name: 'keyVault'
  params: {
    keyVaultName: '${resourcePrefix}-kv'
    location: location
    tags: tags
  }
}

// Azure OpenAI Service (if AI services enabled)
module openAI 'modules/openai.bicep' = if (enableAIServices) {
  name: 'openAI'
  params: {
    openAIName: '${resourcePrefix}-openai'
    location: location
    tags: tags
  }
}

// Azure AI Search (if AI services enabled)
module aiSearch 'modules/ai-search.bicep' = if (enableAIServices) {
  name: 'aiSearch'
  params: {
    searchServiceName: '${resourcePrefix}-search'
    location: location
    tags: tags
  }
}

// Application Insights (if monitoring enabled)
module monitoring 'modules/monitoring.bicep' = if (enableMonitoring) {
  name: 'monitoring'
  params: {
    appInsightsName: '${resourcePrefix}-insights'
    workspaceName: '${resourcePrefix}-workspace'
    location: location
    tags: tags
  }
}

// Outputs
output storageAccountName string = storage.outputs.storageAccountName
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer
output keyVaultUri string = keyVault.outputs.keyVaultUri
output openAIEndpoint string = enableAIServices ? openAI.outputs.endpoint : ''
output aiSearchEndpoint string = enableAIServices ? aiSearch.outputs.endpoint : ''
output appInsightsConnectionString string = enableMonitoring ? monitoring.outputs.connectionString : ''
