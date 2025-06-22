// AI Services module for Mastery AI Workshop
// Provides Azure AI services for modules 16+

@description('Location for all resources')
param location string

@description('Environment name (dev, staging, prod)')
param environment string

@description('Module number (16-30)')
param moduleNumber int

@description('Suffix for resource names')
param suffix string

@description('Tags to apply to resources')
param tags object = {}

@description('SKU for Azure OpenAI Service')
@allowed(['S0'])
param openAiSku string = 'S0'

@description('SKU for AI Search Service')
@allowed(['free', 'basic', 'standard', 'standard2', 'standard3', 'storage_optimized_l1', 'storage_optimized_l2'])
param aiSearchSku string = environment == 'prod' ? 'standard' : 'basic'

@description('SKU for Cognitive Services')
@allowed(['F0', 'S0', 'S1', 'S2', 'S3'])
param cognitiveServicesSku string = environment == 'prod' ? 'S1' : 'S0'

// Azure OpenAI Service (Modules 17+)
resource openAiService 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = if (moduleNumber >= 17) {
  name: 'openai-module${moduleNumber}-${environment}-${suffix}'
  location: location
  sku: {
    name: openAiSku
  }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: 'openai-m${moduleNumber}-${environment}-${suffix}'
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
  tags: tags
}

// OpenAI Model Deployments
resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = if (moduleNumber >= 17) {
  parent: openAiService
  name: 'gpt-4'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: 'turbo-2024-04-09'
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    raiPolicyName: 'Microsoft.Default'
  }
}

resource gpt35TurboDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = if (moduleNumber >= 17) {
  parent: openAiService
  name: 'gpt-35-turbo'
  sku: {
    name: 'Standard'
    capacity: 30
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-35-turbo'
      version: '0613'
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    raiPolicyName: 'Microsoft.Default'
  }
  dependsOn: [gpt4Deployment]
}

resource embeddingDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = if (moduleNumber >= 17) {
  parent: openAiService
  name: 'text-embedding-ada-002'
  sku: {
    name: 'Standard'
    capacity: 30
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'text-embedding-ada-002'
      version: '2'
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    raiPolicyName: 'Microsoft.Default'
  }
  dependsOn: [gpt35TurboDeployment]
}

resource dalleDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = if (moduleNumber >= 18) {
  parent: openAiService
  name: 'dall-e-3'
  sku: {
    name: 'Standard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'dall-e-3'
      version: '3.0'
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    raiPolicyName: 'Microsoft.Default'
  }
  dependsOn: [embeddingDeployment]
}

// Azure AI Search Service (Modules 16+)
resource aiSearchService 'Microsoft.Search/searchServices@2023-11-01' = if (moduleNumber >= 16) {
  name: 'srch-m${moduleNumber}-${environment}-${suffix}'
  location: location
  sku: {
    name: aiSearchSku
  }
  properties: {
    replicaCount: environment == 'prod' ? 2 : 1
    partitionCount: 1
    hostingMode: 'default'
    publicNetworkAccess: 'enabled'
    networkRuleSet: {
      ipRules: []
    }
    encryptionWithCmk: {
      enforcement: 'Unspecified'
    }
    disableLocalAuth: false
    authOptions: {
      apiKeyOnly: {}
    }
  }
  tags: tags
}

// Cognitive Services Multi-Service Account (Modules 16+)
resource cognitiveServices 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = if (moduleNumber >= 16) {
  name: 'cog-module${moduleNumber}-${environment}-${suffix}'
  location: location
  sku: {
    name: cognitiveServicesSku
  }
  kind: 'CognitiveServices'
  properties: {
    customSubDomainName: 'cog-m${moduleNumber}-${environment}-${suffix}'
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
  tags: tags
}

// Computer Vision Service (Modules 18+)
resource computerVision 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = if (moduleNumber >= 18) {
  name: 'cv-module${moduleNumber}-${environment}-${suffix}'
  location: location
  sku: {
    name: cognitiveServicesSku
  }
  kind: 'ComputerVision'
  properties: {
    customSubDomainName: 'cv-m${moduleNumber}-${environment}-${suffix}'
    publicNetworkAccess: 'Enabled'
  }
  tags: tags
}

// Form Recognizer Service (Modules 19+)
resource formRecognizer 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = if (moduleNumber >= 19) {
  name: 'fr-module${moduleNumber}-${environment}-${suffix}'
  location: location
  sku: {
    name: cognitiveServicesSku
  }
  kind: 'FormRecognizer'
  properties: {
    customSubDomainName: 'fr-m${moduleNumber}-${environment}-${suffix}'
    publicNetworkAccess: 'Enabled'
  }
  tags: tags
}

// Language Service (Modules 17+)
resource languageService 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = if (moduleNumber >= 17) {
  name: 'lang-module${moduleNumber}-${environment}-${suffix}'
  location: location
  sku: {
    name: cognitiveServicesSku
  }
  kind: 'TextAnalytics'
  properties: {
    customSubDomainName: 'lang-m${moduleNumber}-${environment}-${suffix}'
    publicNetworkAccess: 'Enabled'
  }
  tags: tags
}

// Speech Service (Modules 20+)
resource speechService 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = if (moduleNumber >= 20) {
  name: 'speech-module${moduleNumber}-${environment}-${suffix}'
  location: location
  sku: {
    name: cognitiveServicesSku
  }
  kind: 'SpeechServices'
  properties: {
    customSubDomainName: 'speech-m${moduleNumber}-${environment}-${suffix}'
    publicNetworkAccess: 'Enabled'
  }
  tags: tags
}

// Translator Service (Modules 19+)
resource translatorService 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = if (moduleNumber >= 19) {
  name: 'trans-module${moduleNumber}-${environment}-${suffix}'
  location: location
  sku: {
    name: cognitiveServicesSku
  }
  kind: 'Translator'
  properties: {
    customSubDomainName: 'trans-m${moduleNumber}-${environment}-${suffix}'
    publicNetworkAccess: 'Enabled'
  }
  tags: tags
}

// Content Safety Service (Modules 18+)
resource contentSafety 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = if (moduleNumber >= 18) {
  name: 'cs-module${moduleNumber}-${environment}-${suffix}'
  location: location
  sku: {
    name: cognitiveServicesSku
  }
  kind: 'ContentSafety'
  properties: {
    customSubDomainName: 'cs-m${moduleNumber}-${environment}-${suffix}'
    publicNetworkAccess: 'Enabled'
  }
  tags: tags
}

// AI Foundry Hub (Modules 22+)
resource aiFoundryHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = if (moduleNumber >= 22) {
  name: 'aih-module${moduleNumber}-${environment}-${suffix}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: 'AI Foundry Hub - Module ${moduleNumber}'
    description: 'AI Foundry Hub for Workshop Module ${moduleNumber}'
    storageAccount: ''  // Will be provided by main template
    keyVault: ''        // Will be provided by main template
    applicationInsights: '' // Will be provided by main template
    publicNetworkAccess: 'Enabled'
    managedNetwork: {
      isolationMode: 'Disabled'
    }
  }
  kind: 'Hub'
  tags: tags
}

// AI Foundry Project (Modules 23+)
resource aiFoundryProject 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = if (moduleNumber >= 23) {
  name: 'aip-module${moduleNumber}-${environment}-${suffix}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: 'AI Foundry Project - Module ${moduleNumber}'
    description: 'AI Foundry Project for Workshop Module ${moduleNumber}'
    hubResourceId: moduleNumber >= 22 ? aiFoundryHub.id : ''
    publicNetworkAccess: 'Enabled'
  }
  kind: 'Project'
  tags: tags
}

// Private Endpoints (Production only)
resource openAiPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = if (moduleNumber >= 17 && environment == 'prod') {
  name: 'pe-openai-${environment}-${suffix}'
  location: location
  properties: {
    subnet: {
      id: '' // Will be provided by networking module
    }
    privateLinkServiceConnections: [
      {
        name: 'openai-connection'
        properties: {
          privateLinkServiceId: openAiService.id
          groupIds: ['account']
        }
      }
    ]
  }
  tags: tags
}

// Outputs
output openAiServiceId string = moduleNumber >= 17 ? openAiService.id : ''
output openAiServiceName string = moduleNumber >= 17 ? openAiService.name : ''
output openAiEndpoint string = moduleNumber >= 17 ? openAiService.properties.endpoint : ''
output openAiApiKey string = moduleNumber >= 17 ? openAiService.listKeys().key1 : ''

output aiSearchServiceId string = moduleNumber >= 16 ? aiSearchService.id : ''
output aiSearchServiceName string = moduleNumber >= 16 ? aiSearchService.name : ''
output aiSearchEndpoint string = moduleNumber >= 16 ? 'https://${aiSearchService.name}.search.windows.net' : ''
output aiSearchApiKey string = moduleNumber >= 16 ? aiSearchService.listAdminKeys().primaryKey : ''
output aiSearchQueryKey string = moduleNumber >= 16 ? aiSearchService.listQueryKeys().value[0].key : ''

output cognitiveServicesId string = moduleNumber >= 16 ? cognitiveServices.id : ''
output cognitiveServicesEndpoint string = moduleNumber >= 16 ? cognitiveServices.properties.endpoint : ''
output cognitiveServicesApiKey string = moduleNumber >= 16 ? cognitiveServices.listKeys().key1 : ''

output computerVisionEndpoint string = moduleNumber >= 18 ? computerVision.properties.endpoint : ''
output computerVisionApiKey string = moduleNumber >= 18 ? computerVision.listKeys().key1 : ''

output formRecognizerEndpoint string = moduleNumber >= 19 ? formRecognizer.properties.endpoint : ''
output formRecognizerApiKey string = moduleNumber >= 19 ? formRecognizer.listKeys().key1 : ''

output languageServiceEndpoint string = moduleNumber >= 17 ? languageService.properties.endpoint : ''
output languageServiceApiKey string = moduleNumber >= 17 ? languageService.listKeys().key1 : ''

output speechServiceEndpoint string = moduleNumber >= 20 ? speechService.properties.endpoint : ''
output speechServiceApiKey string = moduleNumber >= 20 ? speechService.listKeys().key1 : ''

output translatorApiKey string = moduleNumber >= 19 ? translatorService.listKeys().key1 : ''

output contentSafetyEndpoint string = moduleNumber >= 18 ? contentSafety.properties.endpoint : ''
output contentSafetyApiKey string = moduleNumber >= 18 ? contentSafety.listKeys().key1 : ''

output aiFoundryHubId string = moduleNumber >= 22 ? aiFoundryHub.id : ''
output aiFoundryProjectId string = moduleNumber >= 23 ? aiFoundryProject.id : ''

// Resource summary for easy reference
output aiServicesDeployed array = [
  moduleNumber >= 16 ? 'AI Search' : null
  moduleNumber >= 16 ? 'Cognitive Services Multi-Service' : null
  moduleNumber >= 17 ? 'Azure OpenAI' : null
  moduleNumber >= 17 ? 'Language Service' : null
  moduleNumber >= 18 ? 'Computer Vision' : null
  moduleNumber >= 18 ? 'Content Safety' : null
  moduleNumber >= 19 ? 'Form Recognizer' : null
  moduleNumber >= 19 ? 'Translator' : null
  moduleNumber >= 20 ? 'Speech Service' : null
  moduleNumber >= 22 ? 'AI Foundry Hub' : null
  moduleNumber >= 23 ? 'AI Foundry Project' : null
]

output openAiModelsDeployed array = moduleNumber >= 17 ? [
  'gpt-4'
  'gpt-35-turbo'
  'text-embedding-ada-002'
  moduleNumber >= 18 ? 'dall-e-3' : null
] : []
