# Exercise 1: Bicep Basics - Complete Solution

This is the complete solution for Exercise 1 of Module 13, demonstrating Azure Bicep fundamentals.

## 📁 Project Structure

```
solution/
├── main.bicep               # Complete Bicep template
├── modules/                 # Reusable Bicep modules
│   ├── appService.bicep    # App Service module
│   └── monitoring.bicep    # Application Insights module
├── parameters/              # Environment-specific parameters
│   ├── dev.parameters.json
│   ├── staging.parameters.json
│   └── prod.parameters.json
├── scripts/                 # Deployment scripts
│   ├── deploy.sh           # Main deployment script
│   └── cleanup.sh          # Resource cleanup script
└── README.md               # This file
```

## 🏗️ Architecture

The solution deploys:
- **App Service Plan**: Hosting environment for web applications
- **Web App**: Linux-based web application with Python runtime
- **Application Insights**: Optional monitoring and telemetry
- **Resource Tags**: Consistent tagging strategy

## ✨ Features Demonstrated

### 1. **Parameters**
- String parameters with descriptions
- Parameters with default values
- Allowed values using decorators
- Boolean parameters for conditional deployments

### 2. **Variables**
- Complex object variables
- String interpolation
- Computed values

### 3. **Resources**
- App Service Plan with configurable SKU
- Web App with Linux runtime
- Conditional Application Insights deployment
- Resource dependencies

### 4. **Modules**
- Reusable Bicep modules
- Module parameters and outputs
- Module composition

### 5. **Outputs**
- Resource properties
- Computed URLs
- Conditional outputs

## 🚀 Deployment

### Quick Deploy

```bash
# Deploy to dev environment
./scripts/deploy.sh dev

# Deploy to staging
./scripts/deploy.sh staging

# Deploy to production
./scripts/deploy.sh prod
```

### Manual Deployment

```bash
# Create resource group
az group create \
  --name rg-bicep-exercise1 \
  --location eastus2

# Deploy with parameters file
az deployment group create \
  --resource-group rg-bicep-exercise1 \
  --template-file main.bicep \
  --parameters @parameters/dev.parameters.json
```

### What-If Deployment

```bash
# Preview changes before deploying
az deployment group what-if \
  --resource-group rg-bicep-exercise1 \
  --template-file main.bicep \
  --parameters @parameters/dev.parameters.json
```

## 📋 Parameters

| Parameter | Description | Default | Allowed Values |
|-----------|-------------|---------|----------------|
| appServicePlanName | Name of the App Service Plan | Generated | - |
| webAppName | Name of the Web App | Generated | - |
| location | Azure region | Resource Group location | - |
| sku | App Service Plan SKU | F1 | F1, B1, B2, S1, S2, S3, P1v2, P2v2, P3v2 |
| linuxFxVersion | Runtime stack | PYTHON\|3.11 | - |
| enableApplicationInsights | Deploy App Insights | true | true/false |
| environment | Environment name | dev | dev, staging, prod |

## 🏷️ Tagging Strategy

All resources are tagged with:
- **Environment**: dev/staging/prod
- **ManagedBy**: Bicep
- **Module**: 13
- **Exercise**: 1
- **CostCenter**: Based on environment
- **Owner**: Based on environment

## 🧪 Testing

### Validate Template

```bash
# Build and validate
az bicep build --file main.bicep

# Validate deployment
az deployment group validate \
  --resource-group rg-bicep-exercise1 \
  --template-file main.bicep
```

### Test Application

After deployment:
1. Get the web app URL from outputs
2. Navigate to the URL in a browser
3. Verify the default page loads
4. Check Application Insights data (if enabled)

## 🧹 Cleanup

```bash
# Delete all resources
./scripts/cleanup.sh

# Or manually delete resource group
az group delete --name rg-bicep-exercise1 --yes
```

## 📚 Key Learnings

1. **Bicep Syntax**: Clean, readable infrastructure as code
2. **Parameters**: Making templates reusable
3. **Conditions**: Deploying resources based on parameters
4. **Modules**: Creating reusable components
5. **Best Practices**: Naming, tagging, and organization

## 🔄 Enhancements

This solution can be extended with:
- Custom domain configuration
- SSL certificates
- Deployment slots
- Auto-scaling rules
- Advanced monitoring alerts
- CI/CD integration

## 📖 Additional Resources

- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Bicep Learning Path](https://docs.microsoft.com/learn/paths/bicep-deploy/)
- [Bicep GitHub Repository](https://github.com/Azure/bicep)