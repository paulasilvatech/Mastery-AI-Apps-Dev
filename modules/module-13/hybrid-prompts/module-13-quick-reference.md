# Module 13 - Quick Reference Guide: Code Suggestions vs Agent Mode

## 🚀 At a Glance Comparison

| Task | Code Suggestions | Agent Mode |
|------|-----------------|------------|
| **Create Bicep template** | `// Create App Service with database` | "Create complete Bicep template for web app with SQL database, monitoring, and security" |
| **Add Terraform module** | `# Module for Azure networking with 3 subnets` | "Create Terraform network module with hub-spoke topology, NSGs, and private endpoints" |
| **Fix deployment error** | `// Fix invalid resource property` | "Debug this Bicep error: [paste error]" |
| **Create GitOps workflow** | `# GitHub Action to deploy on push to main` | "Create complete CI/CD pipeline with validation, security scanning, and progressive deployment" |

## 📝 Exercise 1: Bicep Basics - Quick Commands

### Code Suggestions Approach

```bicep
// Create resource group tags for cost tracking
// Add parameter for environment with allowed values
// Create App Service Plan with conditional SKU based on environment
// Add Application Insights with connection to App Service
// Create Storage Account with private endpoint
// Add outputs for connection strings
```

### Agent Mode Approach

```markdown
Create a Bicep template with:
- Parameterized environment (dev/staging/prod)
- App Service with environment-based sizing
- SQL Database with transparent encryption
- Storage Account with private endpoints
- Application Insights for monitoring
- Key Vault for secrets
- Proper RBAC assignments
- Cost-optimized SKUs per environment
Include outputs for all connection strings and endpoints.
```

## 🌍 Exercise 2: Terraform Multi-Environment - Quick Commands

### Code Suggestions Approach

```hcl
# Create reusable module for web application
# Include variables for environment-specific configs
# Add App Service with staging slot for production
# Configure auto-scaling based on environment
# Create backend configuration for remote state
# Add lifecycle rules to prevent accidental deletion
```

### Agent Mode Approach

```markdown
Create Terraform configuration for multi-environment setup:

1. Module structure with:
   - Networking module (VNet, Subnets, NSGs)
   - Compute module (App Service, Functions)
   - Data module (SQL, Cosmos, Storage)
   - Monitoring module (Log Analytics, App Insights)

2. Environment configurations:
   - Dev: Minimal resources, no HA
   - Staging: Production-like, smaller scale
   - Prod: HA, auto-scaling, geo-redundancy

3. Features:
   - Remote state with locking
   - Variable validation
   - Outputs for cross-module references
   - Provider version constraints

Include tfvars files for each environment.
```

## 🔄 Exercise 3: GitOps Pipeline - Quick Commands

### Code Suggestions Approach

```yaml
# Create workflow triggered on PR to main
# Add job to validate Terraform syntax
# Run security scanning with Checkov
# Generate cost estimate with Infracost
# Post results as PR comment
# Deploy to dev on merge to main
# Add manual approval for production
```

### Agent Mode Approach

```markdown
Create complete GitOps pipeline with:

1. PR Validation:
   - Lint (Terraform fmt, tflint)
   - Security scan (Checkov, tfsec)
   - Policy validation (OPA)
   - Cost estimation
   - Post summary to PR

2. Deployment Pipeline:
   - Deploy to dev automatically
   - Integration tests in dev
   - Promote to staging with approval
   - Canary deployment to production
   - Automated rollback on failure

3. Monitoring:
   - Drift detection (hourly)
   - Cost tracking
   - Security compliance
   - Performance metrics

Include reusable workflows and proper secret management.
```

## 🛠️ Common Patterns

### Resource Naming

**Code Suggestions:**
```bicep
// Create variable for resource names using naming convention
// Format: {resource-type}-{app-name}-{environment}-{region}
```

**Agent Mode:**
```markdown
Generate Azure naming convention variables following CAF standards for all resource types
```

### Tagging Strategy

**Code Suggestions:**
```hcl
# Create common tags including environment, cost center, owner
locals {
  common_tags = {
    # Let Copilot complete
  }
}
```

**Agent Mode:**
```markdown
Create comprehensive tagging strategy with:
- Mandatory tags (Environment, Owner, CostCenter)
- Optional tags (Project, DataClassification)
- Tag inheritance patterns
- Policy enforcement
```

### Error Handling

**Code Suggestions:**
```yaml
# Add error handling with retry logic
# Include fallback for failed deployments
# Send notifications on failure
```

**Agent Mode:**
```markdown
Implement comprehensive error handling:
- Retry transient failures (3x with exponential backoff)
- Capture detailed logs
- Send alerts to Slack/Teams
- Automatic rollback triggers
- Post-mortem report generation
```

## 💡 Pro Tips for Each Approach

### Code Suggestions Tips
1. **Be Specific**: `// Create Azure SQL with geo-replication` > `// Create database`
2. **Incremental**: Build one resource at a time
3. **Context**: Keep related code nearby for better suggestions
4. **Examples**: Provide one example, Copilot learns the pattern

### Agent Mode Tips
1. **Structure**: Use numbered lists and clear sections
2. **Constraints**: Specify limits (budget, regions, SKUs)
3. **Examples**: "Like X but with Y modifications"
4. **Iterations**: Start broad, then refine with follow-ups

## 🔍 Debugging Quick Reference

### When Code Suggestions Fail
```bicep
// If suggestions aren't appearing:
// 1. Check file extension (.bicep, .tf, .yml)
// 2. Ensure Copilot is enabled for file type
// 3. Try simpler comment first
// 4. Provide more context above
```

### When Agent Mode Struggles
```markdown
If responses are too generic:
1. Add specific requirements
2. Include current code context
3. Ask for step-by-step explanation
4. Request specific file structures
```

## 📊 Decision Matrix

| Use Code Suggestions When... | Use Agent Mode When... |
|------------------------------|------------------------|
| Learning new syntax | Need complete solution |
| Making small changes | Starting from scratch |
| Understanding line-by-line | Want best practices included |
| Debugging specific issues | Need multiple files |
| Want control over each line | Want rapid prototyping |

## 🎯 Quick Wins

### Instant Bicep Resources
```bicep
// Storage account with all security features
// Key Vault with RBAC and soft delete
// App Service with managed identity
// SQL Database with AAD auth only
```

### Instant Terraform Modules
```hcl
# Azure VM with managed disk and backup
# AKS cluster with monitoring enabled
# API Management with custom domain
# Cosmos DB with multi-region writes
```

### Instant GitHub Actions
```yaml
# Matrix build for multiple environments
# Parallel deployment with dependencies
# Automated rollback on metric threshold
# Cost approval workflow
```

## 🚨 Emergency Commands

### Quick Cleanup
```bash
# Delete all Module 13 resources
az group list --tag Module=13 -o tsv | xargs -I {} az group delete -n {} --yes

# Force unlock Terraform state
terraform force-unlock <LOCK_ID>

# Cancel all GitHub Actions runs
gh run list --limit 20 | grep "in_progress" | awk '{print $1}' | xargs -I {} gh run cancel {}
```

### Quick Validation
```bash
# Validate all Bicep files
find . -name "*.bicep" -exec bicep build {} \;

# Validate all Terraform files
terraform fmt -check -recursive && terraform validate

# Test GitHub Actions locally
act -n  # Dry run
```

## 📚 Essential Links

- **Bicep Playground**: https://aka.ms/bicepdemo
- **Terraform Registry**: https://registry.terraform.io/providers/hashicorp/azurerm/latest
- **GitHub Actions Marketplace**: https://github.com/marketplace?type=actions
- **Azure Pricing Calculator**: https://azure.microsoft.com/pricing/calculator/

---

**Remember**: This is a quick reference. For detailed explanations, see the full exercise guides. Good luck! 🚀