// Key Vault Module
// This module creates a Key Vault with enterprise security configurations

@description('The name of the Key Vault')
@minLength(3)
@maxLength(24)
param keyVaultName string

@description('The location for the Key Vault')
param location string = resourceGroup().location

@description('Enable soft delete protection')
param enableSoftDelete bool = true

@description('Number of days to retain soft deleted vaults')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 90

@description('Enable purge protection')
param enablePurgeProtection bool = true

@description('Enable RBAC authorization (recommended over access policies)')
param enableRbacAuthorization bool = true

@description('SKU name for the Key Vault')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('Network ACLs default action')
@allowed([
  'Allow'
  'Deny'
])
param networkAclsDefaultAction string = 'Deny'

@description('Allowed IP addresses for Key Vault access')
param allowedIpAddresses array = []

@description('Allowed subnet resource IDs for Key Vault access')
param allowedSubnetResourceIds array = []

@description('Enable diagnostic settings')
param enableDiagnostics bool = true

@description('Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string = ''

@description('Tags to apply to the Key Vault')
param tags object = {}

@description('Object ID of the user/service principal to grant initial access')
param initialAccessObjectId string = ''

@description('Enable Key Vault for VM deployment')
param enabledForDeployment bool = false

@description('Enable Key Vault for disk encryption')
param enabledForDiskEncryption bool = false

@description('Enable Key Vault for template deployment')
param enabledForTemplateDeployment bool = true

// Variables
var diagnosticSettingsName = 'diag-${keyVaultName}'

// IP rules formatting
var ipRules = [for ip in allowedIpAddresses: {
  value: ip
}]

// Virtual network rules formatting
var virtualNetworkRules = [for subnet in allowedSubnetResourceIds: {
  id: subnet
}]

// Key Vault Resource
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: skuName
    }
    tenantId: subscription().tenantId
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection
    enableRbacAuthorization: enableRbacAuthorization
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: networkAclsDefaultAction
      ipRules: ipRules
      virtualNetworkRules: virtualNetworkRules
    }
    accessPolicies: enableRbacAuthorization ? [] : [
      {
        tenantId: subscription().tenantId
        objectId: initialAccessObjectId
        permissions: {
          keys: [
            'get'
            'list'
            'update'
            'create'
            'import'
            'delete'
            'recover'
            'backup'
            'restore'
          ]
          secrets: [
            'get'
            'list'
            'set'
            'delete'
            'recover'
            'backup'
            'restore'
          ]
          certificates: [
            'get'
            'list'
            'update'
            'create'
            'import'
            'delete'
            'recover'
            'backup'
            'restore'
            'managecontacts'
            'manageissuers'
            'getissuers'
            'listissuers'
            'setissuers'
            'deleteissuers'
          ]
        }
      }
    ]
  }
}

// Diagnostic Settings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics && !empty(logAnalyticsWorkspaceId)) {
  name: diagnosticSettingsName
  scope: keyVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
      {
        category: 'AzurePolicyEvaluationDetails'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
    ]
  }
}

// RBAC Role Assignments (if RBAC is enabled and initial access is provided)
resource keyVaultAdministratorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableRbacAuthorization && !empty(initialAccessObjectId)) {
  name: guid(keyVault.id, initialAccessObjectId, 'Key Vault Administrator')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483') // Key Vault Administrator
    principalId: initialAccessObjectId
    principalType: 'ServicePrincipal'
  }
}

// Private Endpoint (optional, if subnet is provided)
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (length(allowedSubnetResourceIds) > 0) {
  name: 'pe-${keyVaultName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: allowedSubnetResourceIds[0]
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-${keyVaultName}'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

// Private DNS Zone Group (for private endpoint)
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = if (length(allowedSubnetResourceIds) > 0) {
  name: 'default'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-vaultcore-azure-net'
        properties: {
          privateDnsZoneId: resourceId('Microsoft.Network/privateDnsZones', 'privatelink.vaultcore.azure.net')
        }
      }
    ]
  }
}

// Outputs
@description('The resource ID of the Key Vault')
output keyVaultId string = keyVault.id

@description('The name of the Key Vault')
output keyVaultName string = keyVault.name

@description('The URI of the Key Vault')
output keyVaultUri string = keyVault.properties.vaultUri

@description('The private endpoint ID (if created)')
output privateEndpointId string = length(allowedSubnetResourceIds) > 0 ? privateEndpoint.id : ''

@description('Key Vault SKU')
output sku string = keyVault.properties.sku.name

@description('Whether RBAC authorization is enabled')
output rbacEnabled bool = keyVault.properties.enableRbacAuthorization 
