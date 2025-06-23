// advanced.bicep - Advanced Bicep features to practice
// Module 13 - Infrastructure as Code with Bicep

// TODO: Complete this template to deploy multiple web apps using loops

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

// TODO: Create an App Service Plan
// Hint: You only need one plan for all apps

// TODO: Use a loop to create multiple web apps
// Hint: Use the syntax: resource symbolicName 'type@version' = [for iterator in collection: { }]
// Example structure:
// resource webApps 'Microsoft.Web/sites@2023-01-01' = [for i in range(0, instanceCount): {
//   name: '${baseAppName}-${environments[i]}'
//   location: location
//   properties: {
//     serverFarmId: appServicePlan.id
//     ...
//   }
// }]

// TODO: Create outputs for all web app URLs
// Hint: Use array comprehension in outputs
// output webAppUrls array = [for i in range(0, instanceCount): webApps[i].properties.defaultHostName]

// BONUS TODO: Add conditional logic
// - Only create Application Insights for non-dev environments
// - Add different SKUs based on environment

// BONUS TODO: Use existing resources
// Example of referencing an existing resource:
// resource existingVNet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
//   name: 'existing-vnet-name'
// }

// BONUS TODO: Use modules in a loop
// Deploy the appService module multiple times:
// module webAppModules 'modules/appService.bicep' = [for env in environments: {
//   name: 'webApp-${env}'
//   params: {
//     ...
//   }
// }] 
