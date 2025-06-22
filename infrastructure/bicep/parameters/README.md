# 📋 Bicep Parameters

This directory contains parameter files for different environments.

## 📁 Files

- `dev.parameters.json` - Development environment parameters
- `staging.parameters.json` - Staging environment parameters  
- `prod.parameters.json` - Production environment parameters

## 🚀 Usage

Deploy with specific parameter file:
```bash
az deployment group create \
  --resource-group rg-workshop-dev \
  --template-file ../main.bicep \
  --parameters @dev.parameters.json
```

## 🔒 Security

⚠️ **Never commit sensitive values in parameter files!**

Use Key Vault references instead:
```json
{
  "adminPassword": {
    "reference": {
      "keyVault": {
        "id": "/subscriptions/.../providers/Microsoft.KeyVault/vaults/mykeyvault"
      },
      "secretName": "admin-password"
    }
  }
}
```

## 🏷️ Environment Differences

### Development
- Smaller SKUs
- No redundancy
- Shorter retention
- Auto-shutdown enabled

### Staging
- Production-like configuration
- Reduced scale
- Full monitoring

### Production
- High availability
- Zone redundancy
- Extended retention
- Full backup policies
