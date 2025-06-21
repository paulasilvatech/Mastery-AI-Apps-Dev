# Infrastructure as Code

This directory contains all Infrastructure as Code (IaC) templates and configurations for the Mastery AI Code Development Workshop.

## Structure

```
infrastructure/
├── bicep/                # Azure Bicep templates
│   ├── main.bicep       # Main template
│   ├── modules/         # Reusable Bicep modules
│   └── parameters/      # Environment-specific parameters
├── terraform/           # Terraform configurations
│   ├── modules/        # Reusable Terraform modules
│   └── environments/   # Environment configurations
├── github-actions/     # Reusable GitHub Actions workflows
└── arm-templates/      # Legacy ARM templates
```

## Usage

### Bicep
```bash
# Deploy using Bicep
az deployment group create \
  --resource-group mastery-ai-workshop \
  --template-file bicep/main.bicep \
  --parameters @bicep/parameters/dev.json
```

### Terraform
```bash
# Deploy using Terraform
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

## Best Practices

1. **Version Control**: All infrastructure changes must be versioned
2. **Environment Separation**: Use parameter files for different environments
3. **Module Reusability**: Create reusable modules for common patterns
4. **Security**: Never commit secrets or credentials
5. **Documentation**: Document all modules and their parameters

## Module-Specific Infrastructure

Each workshop module may have specific infrastructure requirements:
- Modules 1-10: Basic compute and storage
- Modules 11-20: Advanced cloud services
- Modules 21-25: AI services and agent infrastructure
- Modules 26-30: Enterprise patterns

Refer to each module's documentation for specific infrastructure needs.
