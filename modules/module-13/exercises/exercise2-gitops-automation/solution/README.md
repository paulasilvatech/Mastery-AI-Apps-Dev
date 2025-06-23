# Exercise 2: GitOps Automation - Complete Solution

This is the complete solution for Exercise 2 of Module 13, demonstrating multi-environment infrastructure management with Terraform and GitOps.

## 📁 Project Structure

```
solution/
├── environments/          # Environment-specific configurations
│   ├── dev/              # Development environment
│   ├── staging/          # Staging environment
│   └── prod/            # Production environment
├── modules/              # Reusable Terraform modules
│   ├── network/         # VNet, subnets, NSGs
│   ├── webapp/          # App Service and related resources
│   └── database/        # Azure SQL Database
├── .github/              # GitHub Actions workflows
│   └── workflows/       # CI/CD pipelines
├── scripts/              # Helper scripts
│   ├── setup-backend.sh # Backend configuration
│   └── destroy.sh       # Cleanup script
├── main.tf              # Main Terraform configuration
├── variables.tf         # Variable definitions
├── outputs.tf           # Output definitions
└── README.md            # This file
```

## 🏗️ Architecture

The solution implements a three-tier architecture with:
- **Network Layer**: VNet with separate subnets for each tier
- **Application Layer**: App Service with staging slots
- **Data Layer**: Azure SQL Database with geo-replication for production

## 🚀 Quick Start

### 1. Setup Backend

```bash
# Configure Terraform backend
./scripts/setup-backend.sh

# Export backend configuration
export $(cat backend-config.txt | xargs)
```

### 2. Initialize Terraform

```bash
# Initialize with backend config
terraform init \
  -backend-config="resource_group_name=$BACKEND_RG" \
  -backend-config="storage_account_name=$BACKEND_SA" \
  -backend-config="container_name=$BACKEND_CONTAINER" \
  -backend-config="key=${ENVIRONMENT}.terraform.tfstate"
```

### 3. Deploy Infrastructure

```bash
# Deploy to dev environment
terraform plan -var-file=environments/dev/terraform.tfvars -out=dev.plan
terraform apply dev.plan

# Deploy to staging
terraform plan -var-file=environments/staging/terraform.tfvars -out=staging.plan
terraform apply staging.plan

# Deploy to production
terraform plan -var-file=environments/prod/terraform.tfvars -out=prod.plan
terraform apply prod.plan
```

## 📋 Environment Configurations

### Development
- Single instance App Service (F1 tier)
- Basic SQL Database
- No high availability
- Minimal monitoring

### Staging
- Standard App Service (S1 tier)
- Standard SQL Database
- Application Insights enabled
- Similar to production but smaller

### Production
- Premium App Service (P1v2 tier)
- Premium SQL Database with geo-replication
- Full monitoring and alerting
- Auto-scaling enabled
- Staging slots for blue-green deployments

## 🔒 Security Features

- Managed identities for all services
- Key Vault for secret management
- Network security groups with least privilege
- HTTPS only for all web apps
- SQL firewall rules restricting access

## 📊 Monitoring

- Application Insights for all environments
- Log Analytics workspace
- Azure Monitor alerts
- Custom dashboards per environment

## 🔄 CI/CD Pipeline

The GitHub Actions workflow:
1. Validates Terraform configuration
2. Runs security scanning
3. Creates plan for review
4. Applies changes after approval
5. Runs smoke tests
6. Notifies team of deployment status

## 📝 Best Practices Implemented

1. **State Management**: Remote state with locking
2. **Module Design**: Reusable, parameterized modules
3. **Environment Isolation**: Separate state files per environment
4. **Security**: Secrets in Key Vault, managed identities
5. **Tagging**: Consistent tagging strategy
6. **Naming**: Following Azure naming conventions
7. **Documentation**: Inline comments and README files

## 🧪 Testing

Run the included tests:
```bash
# Validate configurations
terraform validate

# Format check
terraform fmt -check -recursive

# Run integration tests
cd tests
go test -v ./...
```

## 🧹 Cleanup

To destroy resources:
```bash
# Destroy specific environment
terraform destroy -var-file=environments/dev/terraform.tfvars

# Or use the cleanup script
./scripts/destroy.sh dev
```

## 📚 Further Reading

- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [Azure Terraform Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [GitOps with Terraform](https://www.hashicorp.com/blog/gitops-for-terraform) 