# Exercise 1: Bicep Basics

## 📋 Overview

This exercise introduces you to Azure Bicep fundamentals. You'll learn how to create, deploy, and manage Azure resources using Infrastructure as Code (IaC) with Bicep's declarative syntax.

## 🎯 Learning Objectives

By completing this exercise, you will:

- ✅ Understand Bicep syntax and structure
- ✅ Create parameterized Bicep templates
- ✅ Use variables and functions in Bicep
- ✅ Deploy resources conditionally
- ✅ Implement loops for multiple resource creation
- ✅ Create reusable Bicep modules
- ✅ Configure outputs for integration
- ✅ Follow Bicep best practices

## 📁 Structure

```
exercise1-bicep-basics/
├── README.md               # This file
├── instructions/           # Step-by-step instructions
│   ├── part1.md           # Basic Bicep concepts
│   └── part2.md           # Advanced features
├── starter/               # Starting templates
│   ├── main.bicep         # Main template with TODOs
│   ├── advanced.bicep     # Advanced features practice
│   ├── parameters/        # Parameter files
│   └── scripts/           # Deployment scripts
├── solution/              # Complete implementation
│   ├── main.bicep         # Complete basic template
│   ├── main-modular.bicep # Modular version
│   ├── advanced.bicep     # Advanced features solution
│   ├── modules/           # Reusable modules
│   ├── parameters/        # Environment parameters
│   └── scripts/           # Complete scripts
└── setup.sh              # Environment setup script
```

## 🚀 Getting Started

### Prerequisites

1. **Azure Subscription**: Active Azure subscription
2. **Azure CLI**: Version 2.40.0 or later
   ```bash
   az --version
   ```
3. **Bicep CLI**: Latest version (installed with Azure CLI)
   ```bash
   az bicep version
   ```
4. **VS Code**: With Bicep extension
5. **Git**: For version control

### Quick Start

1. **Set up your environment**:
   ```bash
   cd exercise1-bicep-basics
   ./setup.sh
   ```

2. **Open the starter template**:
   ```bash
   code starter/main.bicep
   ```

3. **Follow the TODOs** in the template

4. **Deploy your solution**:
   ```bash
   cd starter/scripts
   ./deploy.sh
   ```

## 📚 Exercise Parts

### Part 1: Basic Bicep Template
- Create App Service Plan
- Deploy Web App
- Configure parameters
- Add outputs

**Time**: ~30 minutes

### Part 2: Advanced Features
- Conditional deployments
- Resource loops
- Bicep modules
- Complex outputs

**Time**: ~45 minutes

## 🎓 Key Concepts

### 1. **Parameters**
```bicep
@description('The name of the web app')
param webAppName string
```

### 2. **Variables**
```bicep
var appServicePlanName = 'asp-${webAppName}'
```

### 3. **Resources**
```bicep
resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
  }
}
```

### 4. **Outputs**
```bicep
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
```

## 📊 Success Criteria

- [ ] ✅ Bicep template validates without errors
- [ ] ✅ Resources deploy successfully
- [ ] ✅ All parameters are properly defined
- [ ] ✅ Conditional logic works correctly
- [ ] ✅ Outputs return expected values
- [ ] ✅ Tags are applied consistently
- [ ] ✅ Solution follows naming conventions

## 🏆 Bonus Challenges

1. **Multi-region deployment**: Deploy to multiple Azure regions
2. **Custom domain**: Add custom domain configuration
3. **Deployment slots**: Configure staging slots
4. **Auto-scaling**: Add scaling rules
5. **Key Vault integration**: Store secrets securely

## 🛠️ Troubleshooting

### Common Issues

1. **SKU not available**:
   - Free tier (F1) limited to one per subscription
   - Try B1 or S1 SKU instead

2. **Name conflicts**:
   - Web app names must be globally unique
   - Use `uniqueString()` function

3. **Region limitations**:
   - Not all SKUs available in all regions
   - Check [Azure Products by Region](https://azure.microsoft.com/regions/services/)

### Debug Commands

```bash
# Validate template
az bicep build --file main.bicep

# What-if deployment
az deployment group what-if \
  --resource-group rg-bicep-exercise1 \
  --template-file main.bicep

# View deployment operations
az deployment group operation list \
  --resource-group rg-bicep-exercise1 \
  --name deploymentName
```

## 📖 Resources

- 📚 [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- 🎮 [Bicep Playground](https://bicepdemo.z22.web.core.windows.net/)
- 📝 [Bicep Best Practices](https://docs.microsoft.com/azure/azure-resource-manager/bicep/best-practices)
- 🎯 [Bicep Learning Path](https://docs.microsoft.com/learn/paths/bicep-deploy/)
- 📖 [Azure Resource Reference](https://docs.microsoft.com/azure/templates/)

## 🤝 Need Help?

1. Check the solution code for reference
2. Review the [Module 13 Best Practices](../../best-practices.md)
3. Use Bicep linter warnings as guidance
4. Ask in the course discussion forum

## ⏭️ Next Steps

After completing this exercise:
1. Review the complete solution
2. Try the bonus challenges
3. Move on to [Exercise 2: GitOps Automation](../exercise2-gitops-automation/)
4. Practice with your own scenarios

---

**Remember**: Infrastructure as Code is about repeatability and consistency. Take time to understand each concept before moving forward! 🚀
