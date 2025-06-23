// main.bicep - Starter template for Exercise 1
// Module 13 - Infrastructure as Code with Bicep

// TODO: Add parameter for App Service Plan name
// Hint: Use @description decorator
// @description('...')
// param appServicePlanName string = ...

// TODO: Add parameter for Web App name
// @description('...')
// param webAppName string = ...

// TODO: Add parameter for location with default value
// @description('The location for all resources')
// param location string = ...

// TODO: Add parameter for App Service Plan SKU
// Use @allowed decorator to restrict values
// @description('...')
// @allowed([...])
// param sku string = 'F1'

// TODO: Add parameter for runtime stack
// param linuxFxVersion string = 'PYTHON|3.11'

// TODO: Add parameter to enable/disable Application Insights
// @description('Enable Application Insights')
// param enableApplicationInsights bool = true

// TODO: Add parameter for environment with validation
// @allowed(['dev', 'staging', 'prod'])
// param environment string = 'dev'

// TODO: Create tags variable using var keyword
// var tags = {
//   Environment: ...
//   ManagedBy: ...
//   // Add more tags
// }

// TODO: Create App Service Plan resource
// resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
//   name: ...
//   location: ...
//   tags: ...
//   sku: {
//     name: ...
//   }
//   kind: ...
//   properties: {
//     reserved: ... // true for Linux
//   }
// }

// TODO: Create Application Insights resource (conditionally)
// Use 'if' keyword for conditional deployment
// resource appInsights 'Microsoft.Insights/components@2020-02-02' = if (...) {
//   name: ...
//   location: ...
//   tags: ...
//   kind: 'web'
//   properties: {
//     Application_Type: 'web'
//     Request_Source: 'rest'
//   }
// }

// TODO: Create Web App resource
// resource webApp 'Microsoft.Web/sites@2023-01-01' = {
//   name: ...
//   location: ...
//   tags: ...
//   properties: {
//     serverFarmId: ... // Reference App Service Plan
//     siteConfig: {
//       linuxFxVersion: ...
//       appSettings: ... // Add Application Insights settings if enabled
//     }
//     httpsOnly: true
//   }
// }

// TODO: Add outputs
// output webAppUrl string = ...
// output webAppName string = ...
// output appServicePlanName string = ...
// output appInsightsInstrumentationKey string = ... // Only if enabled

// Starter code structure:
@description('Your description here')
param parameterName string = 'default-value'

// Add your resources below
