# Development Environment Configuration

This directory contains Terraform configuration for the development environment.

## Files

- `main.tf` - Main configuration file
- `variables.tf` - Variable definitions
- `terraform.tfvars` - Variable values (DO NOT COMMIT sensitive values)
- `outputs.tf` - Output definitions
- `backend.tf` - State storage configuration

## Usage

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply changes
terraform apply

# Destroy resources (when done)
terraform destroy
```

## State Management

State is stored in Azure Storage:
- Storage Account: `stmasteryaitfstate`
- Container: `tfstate`
- Key: `dev.terraform.tfstate`

## Cost Optimization

Development environment uses:
- Smaller VM sizes
- Basic tier services
- Auto-shutdown policies
- Serverless options where available
