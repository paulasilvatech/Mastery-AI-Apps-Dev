# 🧩 Bicep Modules

This directory contains reusable Bicep modules for the Mastery AI Workshop infrastructure.

## 📋 Available Modules

### storage.bicep
Basic storage account module with:
- Blob containers
- Hierarchical namespace support
- Security configurations

## 🚀 Usage

### Import in Main Template
```bicep
module storage 'modules/storage.bicep' = {
  name: 'storageModule'
  params: {
    storageAccountName: 'mystorageaccount'
    location: resourceGroup().location
    tags: tags
  }
}
```

### Direct Deployment
```bash
az deployment group create \
  --resource-group rg-workshop \
  --template-file modules/storage.bicep \
  --parameters storageAccountName=myaccount
```

## 📁 Module Structure

Each module should follow this pattern:

```bicep
// Parameters
@description('Description of parameter')
param parameterName string

// Variables
var variableName = 'value'

// Resources
resource resourceName 'Microsoft.Provider/type@version' = {
  name: name
  location: location
  properties: {
    // properties
  }
}

// Outputs
output outputName string = resource.property
```

## 🔧 Creating New Modules

1. **Naming Convention**: `resourceType.bicep` (e.g., `appService.bicep`)
2. **Documentation**: Include parameter descriptions
3. **Validation**: Add parameter validation where appropriate
4. **Outputs**: Export necessary values for integration
5. **Tags**: Always accept tags parameter

### Module Template
```bicep
@description('Resource name')
param name string

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Resource tags')
param tags object = {}

// Add your resources here

output id string = resource.id
output name string = resource.name
```

## 🏷️ Best Practices

1. **Parameterization**: Make modules flexible with parameters
2. **Defaults**: Provide sensible defaults where possible
3. **Validation**: Use decorators for parameter validation
4. **Dependencies**: Minimize inter-module dependencies
5. **Security**: Never hard-code secrets or sensitive data

## 📚 Module Catalog

### Compute Modules (Planned)
- `appService.bicep` - App Service with plan
- `functionApp.bicep` - Function App with storage
- `aks.bicep` - Azure Kubernetes Service cluster
- `containerInstance.bicep` - Container instances

### Networking Modules (Planned)
- `vnet.bicep` - Virtual network with subnets
- `nsg.bicep` - Network security groups
- `privateEndpoint.bicep` - Private endpoint configuration
- `applicationGateway.bicep` - Application gateway

### Data Modules (Planned)
- `sqlDatabase.bicep` - Azure SQL Database
- `cosmosDb.bicep` - Cosmos DB account
- `redis.bicep` - Redis cache

### AI/ML Modules (Planned)
- `openAi.bicep` - Azure OpenAI service
- `cognitiveSearch.bicep` - Azure AI Search
- `appInsights.bicep` - Application Insights

## 🔄 Module Versioning

When updating modules:
1. Test changes thoroughly
2. Update documentation
3. Maintain backward compatibility
4. Document breaking changes

## 🧪 Testing Modules

```bash
# Validate syntax
az bicep build --file modules/moduleName.bicep

# What-if deployment
az deployment group what-if \
  --resource-group rg-test \
  --template-file modules/moduleName.bicep \
  --parameters @parameters.json
```

## 📖 Additional Resources

- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Bicep Module Registry](https://github.com/Azure/bicep-registry-modules)
- [Best Practices](https://docs.microsoft.com/azure/azure-resource-manager/bicep/best-practices)
