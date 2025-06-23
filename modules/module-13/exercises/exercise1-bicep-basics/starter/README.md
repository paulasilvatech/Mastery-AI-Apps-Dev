# Exercise 1: Bicep Basics - Starter

This is the starter code for Exercise 1 of Module 13, where you'll learn Azure Bicep basics.

## 📁 Project Structure

```
starter/
├── main.bicep            # Main Bicep template (to complete)
├── modules/              # Bicep modules (to create)
├── parameters/           # Parameter files
└── scripts/              # Deployment scripts
```

## 🎯 Objectives

In this exercise, you will:
1. Create a basic Bicep template
2. Use parameters and variables
3. Create reusable modules
4. Deploy resources with conditions
5. Use loops for multiple resources
6. Output important values

## 📝 TODOs

- [ ] Complete the main.bicep template
- [ ] Add parameter definitions
- [ ] Create App Service Plan resource
- [ ] Create Web App resource
- [ ] Add Application Insights (conditionally)
- [ ] Configure outputs
- [ ] Test deployment

## 🚀 Getting Started

1. Open `main.bicep` and follow the TODO comments
2. Use Bicep VS Code extension for IntelliSense
3. Validate your template:
   ```bash
   az bicep build --file main.bicep
   ```
4. Deploy to Azure:
   ```bash
   ./scripts/deploy.sh
   ```

## 📚 Resources

- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Bicep Playground](https://bicepdemo.z22.web.core.windows.net/)
- [Azure Resource Reference](https://docs.microsoft.com/azure/templates/) 