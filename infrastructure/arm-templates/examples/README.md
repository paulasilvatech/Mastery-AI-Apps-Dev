# ARM Template Examples

This directory contains example deployments demonstrating various scenarios and use cases.

## 📋 Available Examples

### dev-environment.json
Complete development environment setup including:
- Basic tier services
- Single region deployment
- Cost-optimized configuration
- Auto-shutdown policies

### staging-environment.json
Production-like environment with:
- Standard tier services
- High availability setup
- Full monitoring stack
- Backup configurations

### prod-environment.json
Full production deployment featuring:
- Premium tier services
- Multi-region setup
- Zone redundancy
- Complete security hardening

### minimal-deployment.json
Bare minimum resources for testing:
- Storage account only
- Basic networking
- Minimal cost footprint

### ai-workshop-complete.json
Complete workshop infrastructure:
- All AI services
- Full compute stack
- Enterprise networking
- Comprehensive monitoring

## 🚀 Using Examples

### Deploy an Example
```bash
# Deploy development environment
az deployment group create \
  --resource-group rg-workshop-dev \
  --template-file examples/dev-environment.json \
  --parameters environment=dev

# Deploy with custom parameters
az deployment group create \
  --resource-group rg-workshop-staging \
  --template-file examples/staging-environment.json \
  --parameters @custom-parameters.json
```

### Validate Before Deployment
```bash
# Validate template
az deployment group validate \
  --resource-group rg-workshop \
  --template-file examples/prod-environment.json

# What-if analysis
az deployment group what-if \
  --resource-group rg-workshop \
  --template-file examples/prod-environment.json
```

## 📁 Example Structure

Each example follows this pattern:
```
example-name.json
├── Parameters section with clear defaults
├── Variables for computed values
├── Resources organized by type
└── Outputs for integration points
```

## 🎯 Use Cases

### Development Teams
Start with `dev-environment.json`:
- Quick setup
- Low cost
- Easy teardown

### POC/Demo
Use `minimal-deployment.json`:
- Fastest deployment
- Minimal resources
- Easy to explain

### Production Planning
Reference `prod-environment.json`:
- Best practices
- Security hardening
- High availability

### Training/Workshops
Deploy `ai-workshop-complete.json`:
- All features enabled
- Learning-friendly
- Reset-friendly

## 💡 Customization Tips

### Modify for Your Needs
1. Copy example template
2. Adjust parameters section
3. Add/remove resources
4. Update outputs

### Common Modifications
```json
// Change SKUs
"sku": {
  "name": "Basic"  // Change to "Standard" or "Premium"
}

// Adjust regions
"location": "[parameters('location')]"  // Accept as parameter

// Scale resources
"capacity": 1  // Increase for production

// Enable features
"properties": {
  "enableFeatureX": true
}
```

## 🏷️ Tagging Strategy

All examples use consistent tagging:
```json
"tags": {
  "Environment": "[parameters('environment')]",
  "Project": "MasteryAIWorkshop",
  "ManagedBy": "ARM",
  "CostCenter": "[parameters('costCenter')]",
  "DeployedBy": "[parameters('deployedBy')]",
  "DeploymentDate": "[utcNow()]"
}
```

## 📊 Cost Estimates

| Example | Estimated Monthly Cost |
|---------|----------------------|
| minimal-deployment | ~$50 |
| dev-environment | ~$200 |
| staging-environment | ~$800 |
| prod-environment | ~$3000+ |
| ai-workshop-complete | ~$500 |

*Costs vary by region and usage patterns*

## 🔒 Security Notes

- Examples include basic security
- Review and enhance for production
- Never commit real credentials
- Use Key Vault for secrets
- Enable diagnostic logs

## 📝 Contributing Examples

To add new examples:
1. Follow naming convention: `scenario-purpose.json`
2. Include comprehensive parameters
3. Add inline documentation
4. Test in multiple regions
5. Document in this README
