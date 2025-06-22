# 🌍 Terraform Infrastructure

This directory contains Terraform configurations for the Mastery AI Code Development Workshop infrastructure.

## 📁 Structure

```
terraform/
├── environments/          # Environment-specific configurations
│   ├── dev/              # Development environment
│   ├── staging/          # Staging environment
│   └── prod/             # Production environment
├── modules/              # Reusable Terraform modules
│   ├── ai-services/      # Azure AI services module
│   ├── compute/          # Compute resources (AKS, Functions)
│   ├── networking/       # Network infrastructure
│   ├── storage/          # Storage accounts and databases
│   └── monitoring/       # Monitoring and observability
└── providers.tf          # Provider configurations
```

## 🚀 Quick Start

### Prerequisites
- Terraform >= 1.5.0
- Azure CLI >= 2.50.0
- Authenticated Azure session

### Initialize Terraform
```bash
cd environments/dev
terraform init
```

### Plan Infrastructure
```bash
terraform plan -out=tfplan
```

### Apply Changes
```bash
terraform apply tfplan
```

## 📦 Modules

### AI Services Module
Provisions Azure AI services including:
- Azure OpenAI Service
- Azure AI Search
- Cosmos DB with vector search
- GitHub Models integration

### Compute Module
Manages compute resources:
- Azure Kubernetes Service (AKS)
- Azure Functions
- Container Instances

### Networking Module
Sets up networking infrastructure:
- Virtual Networks
- Subnets
- Network Security Groups
- Application Gateway

### Storage Module
Handles data storage:
- Storage Accounts
- Cosmos DB instances
- Azure SQL Database
- Redis Cache

### Monitoring Module
Implements observability:
- Application Insights
- Log Analytics Workspace
- Azure Monitor
- Alerts and Dashboards

## 🔒 Security Considerations

1. **State Management**: Store Terraform state in Azure Storage with encryption
2. **Service Principals**: Use managed identities where possible
3. **Key Vault**: Store secrets in Azure Key Vault
4. **Network Security**: Implement proper NSG rules and private endpoints

## 🏷️ Tagging Strategy

All resources use consistent tagging:
```hcl
tags = {
  Environment = var.environment
  ManagedBy   = "Terraform"
  Project     = "MasteryAIWorkshop"
  Module      = var.module_number
  CostCenter  = var.cost_center
}
```

## 📊 Cost Management

- Use auto-shutdown for development resources
- Implement resource quotas
- Enable cost alerts
- Regular resource cleanup

## 🔄 CI/CD Integration

Terraform is integrated with GitHub Actions:
- Automatic plan on PR
- Apply on merge to main
- Environment-specific workflows
- Drift detection

## 📚 Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Terraform Examples](https://github.com/Azure/terraform)
- [Workshop Infrastructure Guide](../../docs/infrastructure-guide.md)
