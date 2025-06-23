# Exercise 1: Bicep Basics - Complete Solution

## Overview

This solution demonstrates a production-ready Bicep template for deploying an Azure Web App with App Service Plan and Application Insights.

## Features Implemented

### 1. Parameterization
- All resource names are parameterized with sensible defaults
- SKU selection with allowed values for validation
- Environment tagging (dev/staging/prod)
- Runtime stack configuration

### 2. Best Practices
- Unique naming using `uniqueString()` function
- Consistent tagging across all resources
- HTTPS-only enforcement
- Conditional deployment of Application Insights
- Proper output values for integration

### 3. Security
- HTTPS enforced by default
- No hardcoded secrets
- Secure connection strings

## Files

- `main.bicep` - Main template file
- `deploy.sh` - Deployment script with parameters
- `parameters.dev.json` - Development environment parameters
- `parameters.prod.json` - Production environment parameters

## Deployment

### Using the deployment script:
```bash
# Default deployment (dev environment, F1 SKU)
./deploy.sh

# Production deployment
./deploy.sh -e prod -s P1v2

# Custom resource group and location
./deploy.sh -g my-rg -l westus2
```

### Manual deployment:
```bash
# Create resource group
az group create --name rg-module13 --location eastus

# Deploy with dev parameters
az deployment group create \
  --resource-group rg-module13 \
  --template-file main.bicep \
  --parameters @parameters.dev.json

# Deploy with inline parameters
az deployment group create \
  --resource-group rg-module13 \
  --template-file main.bicep \
  --parameters sku=S1 environment=staging
```

## Validation

1. **Check deployment outputs:**
   ```bash
   az deployment group show \
     --resource-group rg-module13 \
     --name main \
     --query properties.outputs
   ```

2. **Verify resources:**
   ```bash
   az resource list \
     --resource-group rg-module13 \
     --output table
   ```

3. **Test the web app:**
   - Navigate to the output URL
   - Should see default Azure App Service page
   - Check Application Insights for telemetry

## Key Learning Points

1. **Parameterization**: Makes templates reusable across environments
2. **Conditions**: Use `if()` for optional resources
3. **Functions**: `uniqueString()` ensures unique names
4. **Outputs**: Essential for automation and integration
5. **Tags**: Critical for cost management and organization

## Common Issues

1. **SKU Conflicts**: Free tier (F1) limited to one per subscription/region
2. **Naming Conflicts**: Use `uniqueString()` to avoid collisions
3. **Region Availability**: Not all SKUs available in all regions

## Next Steps

- Add custom domain configuration
- Implement deployment slots for blue-green deployments
- Add Azure Key Vault integration for secrets
- Configure auto-scaling rules
- Implement monitoring alerts