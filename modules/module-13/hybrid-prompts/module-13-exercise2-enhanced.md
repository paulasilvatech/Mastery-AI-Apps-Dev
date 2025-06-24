# Exercise 2: Multi-Environment Infrastructure with Terraform - Enhanced Guide (60 minutes)

## 🎯 Overview

Build a production-ready multi-environment infrastructure using Terraform with GitHub Copilot's dual capabilities:
- **Code Suggestion Mode**: Learn Terraform patterns incrementally with AI completions
- **Agent Mode**: Generate complete modules and configurations through conversation

## 🤖 Development Approach Strategy

### Code Suggestions Excel At:
- Understanding HCL syntax and patterns
- Building modules step by step
- Learning Terraform functions and expressions
- Debugging configuration issues

### Agent Mode Excels At:
- Complete module generation
- Complex multi-environment setups
- Best practice implementations
- Production-ready configurations

## 📋 Prerequisites & Environment Setup

### Comprehensive Prerequisites Check

```markdown
# Copilot Agent Prompt:
Create a complete environment validator for Terraform multi-environment setup:

Check Requirements:
1. Development Tools:
   - Terraform 1.6+ installed
   - Azure CLI 2.50+ configured
   - VS Code with Terraform extension
   - Git for version control
   - GitHub Copilot enabled
   - tflint for linting
   - terraform-docs for documentation

2. Azure Requirements:
   - Valid subscription with Owner access
   - Service Principal for automation
   - Resource providers registered
   - Terraform state storage account
   - Key Vault for secrets

3. Validation Steps:
   - Test Terraform init/plan/apply
   - Verify Azure permissions
   - Check remote state access
   - Validate module sources
   - Test environment isolation

4. Create Setup Script:
   - Install missing tools
   - Configure Azure backend
   - Set up directory structure
   - Initialize environments
   - Create sample tfvars

Include cost estimation and security checks.
```

**💡 Exploration Tip**: Add Terragrunt support for even more powerful multi-environment management!

## 🚀 Step-by-Step Implementation

### Step 1: Project Structure and Backend Setup (10 minutes)

#### Option A: Code Suggestion Approach

Start with basic structure and build up:

```bash
# Create directory structure
mkdir -p terraform/{modules,environments/{dev,staging,prod}}

# Create backend configuration
# terraform/backend.tf
# Configure Azure Storage backend for state
# Use different state files per environment
# Enable state locking with blob leases
```

```hcl
# terraform/versions.tf
# Define required Terraform version >= 1.6
# Configure required providers:
# - azurerm ~> 3.85
# - random ~> 3.6
# - azuread ~> 2.46
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create a complete Terraform project structure for multi-environment deployment:

Project Architecture:
```
terraform/
├── backend/
│   ├── main.tf              # Backend storage resources
│   ├── outputs.tf           # Backend configuration outputs
│   └── setup.sh            # One-time setup script
├── modules/
│   ├── networking/
│   │   ├── main.tf         # VNet, Subnets, NSGs
│   │   ├── variables.tf    # Module inputs
│   │   ├── outputs.tf      # Module outputs
│   │   └── README.md       # Module documentation
│   ├── compute/
│   │   ├── main.tf         # VMs, Scale Sets, App Services
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   ├── database/
│   │   ├── main.tf         # SQL, Cosmos, Redis
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── examples/
│   ├── security/
│   │   ├── main.tf         # Key Vault, Identities, RBAC
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── monitoring/
│       ├── main.tf         # Log Analytics, App Insights
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── global/             # Shared resources
│   │   ├── main.tf
│   │   └── terraform.tfvars
│   ├── dev/
│   │   ├── main.tf         # Dev environment root
│   │   ├── terraform.tfvars
│   │   ├── backend.conf    # Dev state config
│   │   └── .terraform.lock.hcl
│   ├── staging/
│   │   └── [similar structure]
│   └── prod/
│       ├── main.tf
│       ├── terraform.tfvars
│       ├── backend.conf
│       └── terraform.tfvars.encrypted
├── scripts/
│   ├── deploy.sh           # Deployment automation
│   ├── destroy.sh          # Cleanup script
│   ├── validate.sh         # Pre-deployment checks
│   └── cost-estimate.sh    # Cost analysis
└── .github/
    └── workflows/
        ├── terraform-plan.yml
        ├── terraform-apply.yml
        └── terraform-destroy.yml
```

Backend Configuration Features:
1. State Storage:
   - Azure Storage with versioning
   - Container per environment
   - Encryption at rest
   - Soft delete enabled
   - Access logging

2. State Locking:
   - Blob lease for locking
   - Automatic unlock on failure
   - Lock timeout configuration

3. Backend Security:
   - Service Principal authentication
   - RBAC for state access
   - Network restrictions
   - Audit logging

4. Backup Strategy:
   - Automated state backups
   - Point-in-time recovery
   - Cross-region replication

Generate all files with proper configuration and documentation.
```

**💡 Exploration Tip**: Implement Terraform Cloud for enterprise-grade state management and policy enforcement!

### Step 2: Core Infrastructure Modules (15 minutes)

#### Option A: Code Suggestion Approach

Build modules incrementally:

```hcl
# modules/networking/main.tf
# Create a flexible networking module:
# - VNet with configurable address space
# - Dynamic subnet creation based on input
# - NSG rules using dynamic blocks
# - Private DNS zones
# - NAT Gateway for outbound traffic

# modules/networking/variables.tf
# Define variables for:
# - vnet_address_space (list of strings)
# - subnets (map of objects with name, prefix, delegations)
# - nsg_rules (list of security rule objects)
# - enable_ddos_protection (bool)
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create production-ready Terraform modules for multi-environment infrastructure:

1. Advanced Networking Module:
   ```hcl
   # Features to implement:
   - Hub-spoke topology support
   - Multiple subnet tiers (web, app, data, management)
   - Network security groups with rule priorities
   - Application security groups
   - Route tables with UDRs
   - Private endpoints support
   - Service endpoints
   - VNet peering configuration
   - Azure Firewall integration
   - DDoS protection plans
   - Network Watcher configuration
   - Flow logs to storage
   ```

2. Compute Module with Options:
   ```hcl
   # Support multiple compute types:
   - Azure App Service (with slots)
   - Container Instances
   - Kubernetes Service (AKS)
   - Virtual Machine Scale Sets
   - Azure Functions
   - Container Apps
   
   # Features:
   - Auto-scaling configurations
   - Load balancer integration
   - Availability zones
   - Spot instances for dev
   - Managed identities
   - Custom script extensions
   ```

3. Data Layer Module:
   ```hcl
   # Database options:
   - Azure SQL (single/elastic pool)
   - PostgreSQL Flexible Server
   - Cosmos DB (multiple APIs)
   - Redis Cache
   - Storage Accounts
   
   # Features:
   - Geo-replication
   - Backup policies
   - Firewall rules
   - Private endpoints
   - Encryption keys
   - Performance tiers by environment
   ```

4. Security & Identity Module:
   ```hcl
   # Components:
   - Key Vault with RBAC
   - Managed Identities
   - Service Principals
   - Role Assignments
   - Azure Policy definitions
   - Defender for Cloud
   
   # Advanced features:
   - Certificate management
   - Secret rotation
   - Access policies
   - Audit logging
   - Compliance scanning
   ```

5. Monitoring & Observability:
   ```hcl
   # Complete monitoring stack:
   - Log Analytics Workspace
   - Application Insights
   - Alerts and Action Groups
   - Dashboards
   - Diagnostic Settings
   - Metrics collection
   
   # Integrations:
   - Grafana dashboards
   - PagerDuty alerts
   - Slack notifications
   - Cost alerts
   ```

Make modules environment-agnostic with sensible defaults and comprehensive variables.
```

**💡 Exploration Tip**: Create a private Terraform registry for sharing modules across teams!

### Step 3: Environment-Specific Configurations (10 minutes)

#### Option A: Code Suggestion Approach

```hcl
# environments/dev/main.tf
# Import all required modules
# Configure with dev-appropriate settings:
# - Smaller SKUs
# - Reduced redundancy
# - Shorter retention
# - Basic networking

# environments/dev/terraform.tfvars
# Set all variable values for dev:
# environment = "dev"
# location = "eastus2"
# enable_production_features = false
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create environment-specific Terraform configurations with progressive enhancement:

1. Development Environment (dev/):
   ```hcl
   # main.tf
   module "networking" {
     source = "../../modules/networking"
     
     environment         = "dev"
     vnet_address_space = ["10.0.0.0/16"]
     
     subnets = {
       web = {
         address_prefixes = ["10.0.1.0/24"]
         service_endpoints = ["Microsoft.Storage"]
       }
       app = {
         address_prefixes = ["10.0.2.0/24"]
         delegation = null
       }
     }
     
     # Dev optimizations
     enable_ddos_protection = false
     enable_firewall       = false
     flow_logs_retention   = 7
   }
   
   # terraform.tfvars
   # Cost-optimized settings
   vm_size                = "Standard_B2s"
   sql_edition           = "Basic"
   storage_replication   = "LRS"
   backup_retention_days = 7
   enable_ha            = false
   ```

2. Staging Environment:
   ```hcl
   # Production-like but cost-optimized
   - Full feature parity with prod
   - Smaller instance sizes
   - Single region deployment
   - Reduced retention periods
   - Manual scaling
   ```

3. Production Environment:
   ```hcl
   # Full production features
   module "networking" {
     source = "../../modules/networking"
     
     environment         = "prod"
     vnet_address_space = ["10.100.0.0/16"]
     
     # Production security
     enable_ddos_protection = true
     enable_firewall       = true
     enable_waf           = true
     
     # High availability
     availability_zones = [1, 2, 3]
     
     # Compliance
     enable_flow_logs     = true
     flow_logs_retention  = 90
     enable_network_watcher = true
   }
   ```

4. Global/Shared Resources:
   ```hcl
   # Resources shared across environments
   - DNS zones
   - Container registries
   - Shared Key Vaults
   - Log Analytics workspaces
   - Backup vaults
   ```

5. Variable Patterns:
   ```hcl
   # Common variables across environments
   variable "common_config" {
     type = object({
       company_name = string
       cost_center  = string
       project_code = string
       compliance   = list(string)
     })
   }
   
   # Environment-specific overrides
   variable "env_config" {
     type = map(object({
       instance_size = string
       replica_count = number
       backup_enabled = bool
       monitoring_level = string
     }))
   }
   ```

Include tfvars examples and environment promotion strategy.
```

**💡 Exploration Tip**: Use Terraform workspaces or Terragrunt for even better environment isolation!

### Step 4: State Management and Backend Configuration (10 minutes)

#### Option A: Code Suggestion Approach

```bash
#!/bin/bash
# scripts/init-backend.sh
# Create Azure Storage for Terraform state
# Set up containers for each environment
# Configure access keys securely
# Enable versioning and soft delete

# Create backend config files
# backend/dev.conf
# backend/staging.conf  
# backend/prod.conf
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create a complete Terraform state management solution:

1. Backend Infrastructure (backend/main.tf):
   ```hcl
   # State storage account with:
   - Globally unique naming
   - Geo-redundant storage
   - Versioning enabled
   - Soft delete (90 days)
   - Immutable blobs
   - Private endpoints
   - Customer-managed keys
   
   # Containers per environment
   resource "azurerm_storage_container" "state" {
     for_each = toset(["dev", "staging", "prod", "shared"])
     
     name                  = each.value
     storage_account_name  = azurerm_storage_account.state.name
     container_access_type = "private"
   }
   ```

2. Backend Configuration Scripts:
   ```bash
   #!/bin/bash
   # scripts/setup-backend.sh
   
   # Automated backend setup with:
   - Service principal creation
   - RBAC assignments
   - Backend config generation
   - Secret storage in Key Vault
   - GitHub secrets creation
   - Local config encryption
   ```

3. Environment Backend Configs:
   ```hcl
   # backend/dev.conf
   resource_group_name  = "rg-terraform-state"
   storage_account_name = "tfstate${UNIQUE_ID}"
   container_name       = "dev"
   key                  = "infrastructure.tfstate"
   use_azuread_auth    = true
   ```

4. State Management Tools:
   ```bash
   # State inspection script
   terraform state list
   terraform state show
   terraform state pull > backup.tfstate
   
   # State manipulation (use with caution!)
   terraform state mv
   terraform state rm
   terraform import
   
   # State locking info
   terraform force-unlock
   ```

5. Backup and Recovery:
   ```yaml
   # .github/workflows/backup-state.yml
   name: Backup Terraform State
   on:
     schedule:
       - cron: '0 2 * * *'  # Daily at 2 AM
     workflow_dispatch:
   
   jobs:
     backup:
       runs-on: ubuntu-latest
       strategy:
         matrix:
           environment: [dev, staging, prod]
   ```

6. Migration Strategy:
   ```hcl
   # Migrate from local to remote state
   terraform init -migrate-state
   
   # Migrate between backends
   terraform init -migrate-state \
     -backend-config=backend/new.conf
   ```

Include disaster recovery procedures and state recovery tools.
```

**💡 Exploration Tip**: Implement state file encryption with Azure Key Vault and customer-managed keys!

### Step 5: CI/CD Pipeline Implementation (10 minutes)

#### Option A: Code Suggestion Approach

```yaml
# .github/workflows/terraform.yml
name: Terraform CI/CD

# Trigger on push to main and PRs
# Use matrix strategy for multiple environments
# Steps:
# - Checkout code
# - Setup Terraform
# - Run tflint
# - Terraform fmt check
# - Terraform init with backend
# - Terraform validate
# - Terraform plan
# - Post plan to PR
# - Apply on merge (with approval)
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create comprehensive GitHub Actions workflows for Terraform CI/CD:

1. Pull Request Workflow (.github/workflows/terraform-pr.yml):
   ```yaml
   name: Terraform Pull Request
   
   on:
     pull_request:
       paths:
         - 'terraform/**'
         - '.github/workflows/terraform-*.yml'
   
   env:
     TF_VERSION: "1.6.5"
     TFLINT_VERSION: "0.49.0"
   
   jobs:
     detect-changes:
       runs-on: ubuntu-latest
       outputs:
         environments: ${{ steps.filter.outputs.changes }}
       steps:
         - uses: dorny/paths-filter@v2
           id: filter
           with:
             filters: |
               dev:
                 - 'terraform/environments/dev/**'
                 - 'terraform/modules/**'
               staging:
                 - 'terraform/environments/staging/**'
                 - 'terraform/modules/**'
               prod:
                 - 'terraform/environments/prod/**'
                 - 'terraform/modules/**'
   
     validate:
       needs: detect-changes
       runs-on: ubuntu-latest
       strategy:
         matrix:
           environment: ${{ fromJson(needs.detect-changes.outputs.environments) }}
       
       steps:
         - name: Checkout
           uses: actions/checkout@v4
         
         - name: Setup Terraform
           uses: hashicorp/setup-terraform@v3
           with:
             terraform_version: ${{ env.TF_VERSION }}
         
         - name: Setup TFLint
           uses: terraform-linters/setup-tflint@v4
         
         - name: Azure Login
           uses: azure/login@v1
           with:
             creds: ${{ secrets.AZURE_CREDENTIALS }}
         
         - name: Terraform Format Check
           run: terraform fmt -check -recursive
         
         - name: Terraform Init
           working-directory: terraform/environments/${{ matrix.environment }}
           run: |
             terraform init \
               -backend-config="backend/${{ matrix.environment }}.conf" \
               -backend-config="access_key=${{ secrets.STATE_ACCESS_KEY }}"
         
         - name: Terraform Validate
           working-directory: terraform/environments/${{ matrix.environment }}
           run: terraform validate
         
         - name: TFLint
           working-directory: terraform/environments/${{ matrix.environment }}
           run: tflint --init && tflint
         
         - name: Terraform Plan
           id: plan
           working-directory: terraform/environments/${{ matrix.environment }}
           run: |
             terraform plan -out=tfplan -input=false
             terraform show -no-color tfplan > plan.txt
         
         - name: Post Plan to PR
           uses: actions/github-script@v7
           with:
             script: |
               const plan = require('fs').readFileSync('plan.txt', 'utf8');
               const output = `#### Terraform Plan - ${{ matrix.environment }}
               \`\`\`terraform
               ${plan}
               \`\`\``;
               
               github.rest.issues.createComment({
                 issue_number: context.issue.number,
                 owner: context.repo.owner,
                 repo: context.repo.repo,
                 body: output
               });
   ```

2. Deployment Workflow (.github/workflows/terraform-deploy.yml):
   ```yaml
   name: Terraform Deploy
   
   on:
     push:
       branches: [main]
       paths:
         - 'terraform/**'
     workflow_dispatch:
       inputs:
         environment:
           type: choice
           options: [dev, staging, prod]
           required: true
         action:
           type: choice
           options: [plan, apply, destroy]
           default: plan
   
   jobs:
     deploy:
       runs-on: ubuntu-latest
       environment: ${{ inputs.environment || 'dev' }}
       
       steps:
         - name: Manual Approval for Production
           if: inputs.environment == 'prod' && inputs.action != 'plan'
           uses: trstringer/manual-approval@v1
           with:
             approvers: prod-approvers-team
         
         - name: Cost Estimation
           uses: infracost/actions/setup@v2
           # ... Run Infracost
         
         - name: Security Scanning
           uses: aquasecurity/tfsec-action@v1
         
         - name: Apply Terraform
           if: inputs.action == 'apply'
           run: terraform apply -auto-approve tfplan
   ```

3. Scheduled Validation (.github/workflows/terraform-drift.yml):
   ```yaml
   # Detect drift daily
   name: Terraform Drift Detection
   
   on:
     schedule:
       - cron: '0 6 * * *'
   
   jobs:
     drift-detection:
       # Run plan and alert on changes
   ```

4. Destroy Workflow (with safeguards):
   ```yaml
   # Protected destroy with multiple approvals
   name: Terraform Destroy
   
   on:
     workflow_dispatch:
   
   jobs:
     destroy:
       if: github.actor == 'authorized-user'
       environment: destroy-approval
   ```

Include branch protection rules and environment secrets configuration.
```

**💡 Exploration Tip**: Add Terraform Cloud integration for policy as code and cost estimation!

### Step 6: Testing and Validation (5 minutes)

#### Option A: Code Suggestion Approach

```hcl
# tests/terraform_test.go
// Create Go tests using Terratest
// Test module functionality
// Validate resource creation
// Check outputs
// Verify tagging compliance

# tests/validate.sh
#!/bin/bash
# Run pre-deployment checks:
# - Terraform fmt
# - tflint rules
# - tfsec security scan
# - Cost estimation
# - Policy validation
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create comprehensive testing framework for Terraform infrastructure:

1. Unit Tests with Terratest (tests/unit/):
   ```go
   package test
   
   import (
     "testing"
     "github.com/gruntwork-io/terratest/modules/terraform"
     "github.com/stretchr/testify/assert"
   )
   
   func TestNetworkModule(t *testing.T) {
     terraformOptions := &terraform.Options{
       TerraformDir: "../../modules/networking",
       Vars: map[string]interface{}{
         "environment": "test",
         "vnet_address_space": []string{"10.0.0.0/16"},
       },
     }
     
     defer terraform.Destroy(t, terraformOptions)
     terraform.InitAndApply(t, terraformOptions)
     
     // Validate outputs
     vnetId := terraform.Output(t, terraformOptions, "vnet_id")
     assert.NotEmpty(t, vnetId)
   }
   ```

2. Integration Tests (tests/integration/):
   ```bash
   #!/bin/bash
   # Full environment deployment test
   - Deploy to test subscription
   - Validate all resources
   - Test connectivity
   - Check security rules
   - Verify backups
   - Test disaster recovery
   ```

3. Compliance Tests (tests/compliance/):
   ```python
   # Azure Policy compliance
   import azure.policy
   
   def test_tagging_compliance():
       """Ensure all resources have required tags"""
       required_tags = ["Environment", "CostCenter", "Owner"]
       
   def test_encryption_compliance():
       """Verify encryption at rest"""
       
   def test_network_compliance():
       """Check network isolation"""
   ```

4. Performance Tests:
   ```yaml
   # Load testing infrastructure
   - Deployment time benchmarks
   - Terraform operation performance
   - State operation timing
   - Module execution profiling
   ```

5. Security Scanning:
   ```yaml
   # tfsec custom rules
   custom_rules:
     - id: AZU001
       description: Ensure all storage accounts use private endpoints
       severity: HIGH
       
     - id: AZU002  
       description: Require encryption with customer keys
       severity: MEDIUM
   ```

6. Cost Testing:
   ```bash
   # Infracost integration
   infracost breakdown --path . \
     --format json \
     --out-file infracost.json
   
   # Check against budget
   python check_budget.py infracost.json
   ```

Include contract testing between modules and environments.
```

**💡 Exploration Tip**: Implement chaos engineering tests to validate infrastructure resilience!

## ☁️ Production Deployment Strategy

### Complete Multi-Environment Solution

```markdown
# Copilot Agent Prompt:
Create production-ready deployment strategy for Terraform:

1. Environment Promotion:
   ```mermaid
   graph LR
     Dev --> Staging
     Staging --> UAT
     UAT --> Production
     Production --> DR
   ```

2. Deployment Patterns:
   - Blue-Green deployments
   - Canary releases
   - Rolling updates
   - Immutable infrastructure
   - GitOps with Flux/ArgoCD

3. Operational Excellence:
   - Runbooks for common tasks
   - Automated recovery procedures
   - Performance optimization
   - Cost governance
   - Security automation

4. Disaster Recovery:
   - Multi-region failover
   - Backup automation
   - RTO/RPO targets
   - DR testing procedures
   - Data replication

5. Monitoring and Alerting:
   - Infrastructure dashboards
   - Cost tracking
   - Security monitoring
   - Compliance reporting
   - SLA tracking

Create implementation guides for each pattern.
```

## 🎯 Challenge Extensions

### Enterprise Patterns Implementation

```markdown
# Copilot Agent Prompt for Enterprise Patterns:

Implement these advanced Terraform patterns:

1. Multi-Cloud Architecture:
   - Azure as primary
   - AWS for DR
   - GCP for specific services
   - Consistent networking
   - Unified monitoring

2. Service Mesh Infrastructure:
   - Istio/Linkerd setup
   - mTLS everywhere
   - Traffic management
   - Observability
   - Policy enforcement

3. Platform Engineering:
   - Self-service portal
   - Template catalog
   - Automated provisioning
   - Cost showback
   - Compliance automation

4. FinOps Implementation:
   - Real-time cost tracking
   - Budget enforcement
   - Reserved instance management
   - Spot instance automation
   - Waste identification

Choose one pattern and build it completely!
```

## ✅ Completion Checklist

### Core Requirements
- [ ] Remote state configured
- [ ] Modules created and tested
- [ ] Three environments deployed
- [ ] Variables properly parameterized
- [ ] CI/CD pipeline working
- [ ] Documentation complete

### Advanced Achievements
- [ ] State encryption enabled
- [ ] Compliance tests passing
- [ ] Cost optimization applied
- [ ] Security scanning clean
- [ ] Performance benchmarks met
- [ ] DR procedures tested

### Excellence Indicators
- [ ] Zero-downtime updates
- [ ] Self-healing infrastructure
- [ ] Automated compliance
- [ ] Cost anomaly detection
- [ ] Multi-region ready

## 🎉 Congratulations!

You've mastered multi-environment Terraform using both Copilot approaches:
- **Code Suggestions** for learning HCL patterns and syntax
- **Agent Mode** for complex modules and production configurations

**Reflection Questions:**
1. How did the modular approach improve maintainability?
2. What cost savings did you achieve with environment-specific configurations?
3. Which Terraform patterns will you adopt in your projects?

**Next Steps:**
- Try Exercise 3 for complete GitOps automation
- Explore Terraform Cloud for enterprise features
- Build a module registry for your organization
- Contribute to open source Terraform modules

**Remember**: Infrastructure as Code is about creating reliable, repeatable, and reviewable infrastructure. Make every deployment predictable!