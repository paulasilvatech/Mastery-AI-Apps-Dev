# Exercise 3: Complete GitOps Pipeline - Enhanced Guide (90 minutes)

## 🎯 Overview

Build a production-grade GitOps pipeline using GitHub Copilot's dual capabilities:
- **Code Suggestion Mode**: Learn GitOps patterns and workflow automation step by step
- **Agent Mode**: Generate complete CI/CD pipelines and policy frameworks

## 🤖 Development Approach Strategy

### Code Suggestions Excel At:
- Understanding YAML workflow syntax
- Building pipeline steps incrementally
- Learning GitHub Actions patterns
- Debugging workflow issues

### Agent Mode Excels At:
- Complete pipeline generation
- Complex multi-stage workflows
- Policy as Code frameworks
- Production-ready automation

## 📋 Prerequisites & Environment Setup

### Comprehensive Prerequisites Check

```markdown
# Copilot Agent Prompt:
Create a complete GitOps prerequisites validator:

Requirements to Check:
1. Repository Setup:
   - GitHub repository with Actions enabled
   - Branch protection rules configured
   - Required secrets set up
   - Webhook permissions
   - CODEOWNERS file

2. Azure Configuration:
   - Service Principal with correct permissions
   - State storage account accessible
   - Key Vault for secrets
   - Policy definitions deployed
   - Cost management APIs enabled

3. Tools and CLIs:
   - GitHub CLI installed
   - Azure CLI configured
   - Terraform/Bicep validated
   - OPA (Open Policy Agent)
   - Infracost CLI
   - Checkov/tfsec

4. Validation Steps:
   - Test GitHub Actions locally (act)
   - Verify Azure permissions
   - Check policy engine
   - Validate cost APIs
   - Test notification channels

5. Create Setup Script:
   - Configure all prerequisites
   - Set up branch policies
   - Create environments
   - Configure approvals
   - Initialize monitoring

Include security scanning and compliance checks.
```

**💡 Exploration Tip**: Add GitLab CI/CD or Azure DevOps pipelines for multi-platform GitOps!

## 🚀 Step-by-Step Implementation

### Step 1: Repository Structure and GitOps Foundation (15 minutes)

#### Option A: Code Suggestion Approach

Build your GitOps structure incrementally:

```bash
#!/bin/bash
# setup-gitops.sh
# Create a GitOps repository structure with:
# - Environment-based directories
# - Shared components
# - Policy definitions
# - Workflow templates
# - Documentation

# Create directory structure
# Add CODEOWNERS file
# Set up branch protection
# Configure environments
```

```yaml
# .github/CODEOWNERS
# Define ownership for infrastructure code
# Require reviews from platform team
# Set environment-specific owners
# Protect critical paths
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create a complete GitOps repository structure with enterprise patterns:

Repository Architecture:
```
gitops-infrastructure/
├── .github/
│   ├── workflows/
│   │   ├── 00-detect-changes.yml      # Intelligent change detection
│   │   ├── 01-validate-pr.yml         # PR validation pipeline
│   │   ├── 02-plan-infrastructure.yml # Generate plans
│   │   ├── 03-security-scan.yml       # Security checks
│   │   ├── 04-policy-check.yml        # Policy validation
│   │   ├── 05-cost-estimate.yml       # Cost analysis
│   │   ├── 06-deploy-dev.yml          # Dev deployment
│   │   ├── 07-deploy-staging.yml      # Staging deployment
│   │   ├── 08-deploy-prod.yml         # Production deployment
│   │   ├── 09-drift-detection.yml     # Scheduled drift check
│   │   ├── 10-rollback.yml            # Emergency rollback
│   │   └── 11-destroy.yml             # Teardown workflow
│   ├── actions/                        # Reusable actions
│   │   ├── terraform-setup/
│   │   ├── policy-engine/
│   │   └── notification/
│   ├── PULL_REQUEST_TEMPLATE/
│   │   ├── infrastructure.md
│   │   ├── hotfix.md
│   │   └── documentation.md
│   └── ISSUE_TEMPLATE/
│       ├── bug-report.md
│       ├── feature-request.md
│       └── incident.md
├── infrastructure/
│   ├── core/                          # Shared infrastructure
│   │   ├── networking/
│   │   ├── identity/
│   │   ├── monitoring/
│   │   └── security/
│   ├── applications/                  # Application-specific
│   │   ├── app1/
│   │   └── app2/
│   └── environments/
│       ├── dev/
│       │   ├── main.tf
│       │   ├── terraform.tfvars
│       │   └── backend.conf
│       ├── staging/
│       └── prod/
├── policies/
│   ├── security/                      # Security policies
│   │   ├── encryption.rego
│   │   ├── networking.rego
│   │   └── identity.rego
│   ├── cost/                          # Cost policies
│   │   ├── limits.rego
│   │   └── tagging.rego
│   └── compliance/                    # Compliance policies
│       ├── cis.rego
│       └── pci.rego
├── scripts/
│   ├── setup/                         # Setup scripts
│   ├── validation/                    # Validation tools
│   ├── deployment/                    # Deployment helpers
│   └── emergency/                     # Break-glass procedures
├── docs/
│   ├── architecture/                  # Architecture decisions
│   ├── runbooks/                      # Operational guides
│   ├── disaster-recovery/             # DR procedures
│   └── onboarding/                    # Team onboarding
├── tests/
│   ├── unit/                          # Unit tests
│   ├── integration/                   # Integration tests
│   ├── smoke/                         # Smoke tests
│   └── compliance/                    # Compliance tests
├── monitoring/
│   ├── dashboards/                    # Dashboard definitions
│   ├── alerts/                        # Alert rules
│   └── slos/                          # SLO definitions
├── CODEOWNERS                         # Ownership mapping
├── SECURITY.md                        # Security policies
└── .gitops/
    ├── config.yaml                    # GitOps configuration
    ├── environments.yaml              # Environment definitions
    └── promotion.yaml                 # Promotion rules
```

Features to Implement:
1. Smart Change Detection:
   - Detect which components changed
   - Map changes to environments
   - Skip unchanged resources
   - Optimize pipeline runs

2. Environment Configuration:
   - GitHub Environments with protection rules
   - Required reviewers by environment
   - Deployment windows
   - Secret management
   - Automated rollback triggers

3. Branch Protection:
   - Require PR reviews (2+ for prod)
   - Dismiss stale reviews
   - Require up-to-date branches
   - Include administrators
   - Require conversation resolution

4. CODEOWNERS Mapping:
   ```
   # Global owners
   * @platform-team
   
   # Environment-specific
   /infrastructure/environments/prod/ @senior-engineers @security-team
   /infrastructure/environments/staging/ @dev-team @platform-team
   
   # Policy owners
   /policies/ @security-team @compliance-team
   
   # Critical components
   /infrastructure/core/networking/ @network-team
   /infrastructure/core/security/ @security-team
   ```

5. GitOps Configuration:
   ```yaml
   # .gitops/config.yaml
   version: 1.0
   
   settings:
     auto_merge: false
     require_approval: true
     enable_drift_detection: true
     enable_cost_tracking: true
     
   notifications:
     slack:
       webhook: ${SLACK_WEBHOOK}
       channels:
         - name: infrastructure-alerts
           events: [deployment, failure, drift]
         - name: cost-alerts
           events: [cost_threshold]
     
   integrations:
     terraform_cloud:
       organization: company-name
       workspaces:
         prefix: gitops-
     
     azure_devops:
       organization: company-name
       project: infrastructure
   ```

Generate all files with proper documentation and examples.
```

**💡 Exploration Tip**: Implement Flux or ArgoCD for Kubernetes GitOps integration!

### Step 2: CI Pipeline - Validation and Security (20 minutes)

#### Option A: Code Suggestion Approach

Build validation workflows step by step:

```yaml
# .github/workflows/validate-pr.yml
name: Validate Pull Request

# Trigger on PR against main or release branches
# Also trigger on specific paths
# Use concurrency to cancel outdated runs

jobs:
  # Job 1: Detect what changed
  # Use git diff to find modified files
  # Output matrix of affected environments
  
  # Job 2: Lint and format
  # Check Terraform fmt
  # Validate Bicep syntax
  # YAML linting
  
  # Job 3: Security scanning
  # Run Checkov
  # Run tfsec
  # Upload SARIF results
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create comprehensive CI pipeline workflows for infrastructure validation:

1. Intelligent Change Detection (.github/workflows/00-detect-changes.yml):
   ```yaml
   name: Detect Changes
   
   on:
     workflow_call:
       outputs:
         environments:
           description: 'Affected environments'
           value: ${{ jobs.detect.outputs.environments }}
         modules:
           description: 'Changed modules'
           value: ${{ jobs.detect.outputs.modules }}
         has_infrastructure_changes:
           value: ${{ jobs.detect.outputs.has_infrastructure_changes }}
         has_policy_changes:
           value: ${{ jobs.detect.outputs.has_policy_changes }}
   
   jobs:
     detect:
       runs-on: ubuntu-latest
       outputs:
         environments: ${{ steps.changes.outputs.environments }}
         modules: ${{ steps.changes.outputs.modules }}
         
       steps:
         - name: Checkout
           uses: actions/checkout@v4
           with:
             fetch-depth: 0
         
         - name: Analyze changes
           id: changes
           run: |
             # Complex change detection logic
             # Map file changes to environments
             # Detect transitive dependencies
             # Output JSON matrix for downstream jobs
   ```

2. Security Scanning Workflow (.github/workflows/03-security-scan.yml):
   ```yaml
   name: Security Scanning
   
   on:
     workflow_call:
       inputs:
         scan_severity:
           type: string
           default: 'CRITICAL,HIGH'
   
   jobs:
     checkov:
       runs-on: ubuntu-latest
       steps:
         - name: Run Checkov with custom policies
           uses: bridgecrewio/checkov-action@v12
           with:
             config_file: .checkov.yaml
             output_format: cli,sarif,json
             download_external_modules: true
             
     tfsec:
       runs-on: ubuntu-latest
       steps:
         - name: Run tfsec with custom checks
           uses: aquasecurity/tfsec-action@v1
           with:
             config_file: .tfsec/config.yml
             
     terrascan:
       runs-on: ubuntu-latest
       steps:
         - name: Run Terrascan
           uses: accurics/terrascan-action@v1
           
     secrets-scan:
       runs-on: ubuntu-latest
       steps:
         - name: Scan for secrets
           uses: trufflesecurity/trufflehog@v3
           
     dependency-check:
       runs-on: ubuntu-latest
       steps:
         - name: Check dependencies
           run: |
             # Check for outdated providers
             # Scan for vulnerable modules
             # Validate module sources
   
     consolidate:
       needs: [checkov, tfsec, terrascan, secrets-scan, dependency-check]
       runs-on: ubuntu-latest
       steps:
         - name: Merge security reports
         - name: Generate summary
         - name: Post to PR
   ```

3. Policy Validation (.github/workflows/04-policy-check.yml):
   ```yaml
   name: Policy as Code Validation
   
   jobs:
     opa-validation:
       strategy:
         matrix:
           environment: ${{ fromJson(inputs.environments) }}
       
       steps:
         - name: Setup OPA
         - name: Generate Terraform plan
         - name: Convert plan to JSON
         - name: Run OPA evaluation
           run: |
             opa eval -d policies/ \
               -i tfplan.json \
               "data.terraform.deny[x]"
         
         - name: Sentinel policies (if using Terraform Cloud)
         - name: Azure Policy dry-run
         - name: AWS Config rules validation
   ```

4. Advanced Cost Estimation (.github/workflows/05-cost-estimate.yml):
   ```yaml
   name: Cost Analysis
   
   jobs:
     infracost:
       steps:
         - name: Run Infracost
           run: |
             infracost breakdown \
               --path . \
               --usage-file infracost-usage.yml \
               --sync-usage-file \
               --show-skipped
         
         - name: Compare with baseline
         - name: Check budget limits
         - name: Generate cost report
         - name: Post to PR with graphs
   ```

5. Comprehensive Validation (.github/workflows/01-validate-pr.yml):
   ```yaml
   name: PR Validation Pipeline
   
   on:
     pull_request:
       types: [opened, synchronize, reopened]
   
   jobs:
     detect-changes:
       uses: ./.github/workflows/00-detect-changes.yml
     
     lint-and-format:
       needs: detect-changes
       if: needs.detect-changes.outputs.has_infrastructure_changes == 'true'
       # Terraform fmt, tflint, yamllint, markdownlint
     
     security-scan:
       needs: detect-changes
       if: needs.detect-changes.outputs.has_infrastructure_changes == 'true'
       uses: ./.github/workflows/03-security-scan.yml
     
     policy-check:
       needs: [detect-changes, lint-and-format]
       uses: ./.github/workflows/04-policy-check.yml
     
     cost-estimate:
       needs: [detect-changes, policy-check]
       uses: ./.github/workflows/05-cost-estimate.yml
     
     integration-tests:
       needs: [security-scan, policy-check]
       # Deploy to ephemeral environment
       # Run integration tests
       # Destroy ephemeral environment
     
     summary:
       needs: [lint-and-format, security-scan, policy-check, cost-estimate]
       if: always()
       runs-on: ubuntu-latest
       steps:
         - name: Generate PR report
         - name: Update PR status
         - name: Add labels
   ```

Include reusable workflows and composite actions for common tasks.
```

**💡 Exploration Tip**: Add SAST/DAST scanning for application code deployed by infrastructure!

### Step 3: CD Pipeline - Progressive Deployment (20 minutes)

#### Option A: Code Suggestion Approach

Create deployment workflows incrementally:

```yaml
# .github/workflows/deploy-dev.yml
name: Deploy to Development

# Trigger on push to main
# Only for infrastructure changes
# Use environment protection

jobs:
  deploy:
    environment: development
    # Configure Azure credentials
    # Run Terraform init with backend
    # Generate plan
    # Apply with auto-approve
    # Run smoke tests
    # Send notifications
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create production-grade CD pipelines with progressive deployment:

1. Development Deployment (.github/workflows/06-deploy-dev.yml):
   ```yaml
   name: Deploy to Development
   
   on:
     push:
       branches: [main]
       paths:
         - 'infrastructure/**'
     workflow_dispatch:
       inputs:
         force_deploy:
           type: boolean
           description: 'Force deployment even without changes'
   
   concurrency:
     group: deploy-dev
     cancel-in-progress: false
   
   jobs:
     pre-deployment:
       runs-on: ubuntu-latest
       steps:
         - name: Check deployment window
         - name: Verify prerequisites
         - name: Create deployment record
     
     deploy-infrastructure:
       needs: pre-deployment
       runs-on: ubuntu-latest
       environment:
         name: development
         url: ${{ steps.deploy.outputs.environment_url }}
       
       steps:
         - name: Download plan artifact
         - name: Setup deployment tools
         - name: Azure Login with OIDC
           uses: azure/login@v1
           with:
             client-id: ${{ secrets.AZURE_CLIENT_ID }}
             tenant-id: ${{ secrets.AZURE_TENANT_ID }}
             subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
         
         - name: Deploy with Terraform
           id: deploy
           run: |
             terraform apply -auto-approve tfplan
             echo "environment_url=$(terraform output -raw app_url)" >> $GITHUB_OUTPUT
         
         - name: Tag deployment
           run: |
             git tag -a "dev-$(date +%Y%m%d-%H%M%S)" -m "Dev deployment"
             git push origin --tags
     
     post-deployment:
       needs: deploy-infrastructure
       runs-on: ubuntu-latest
       steps:
         - name: Run smoke tests
         - name: Update inventory
         - name: Send notifications
         - name: Update documentation
   ```

2. Staging Deployment with Approvals (.github/workflows/07-deploy-staging.yml):
   ```yaml
   name: Deploy to Staging
   
   on:
     workflow_dispatch:
     schedule:
       - cron: '0 2 * * 1-5'  # 2 AM weekdays
   
   jobs:
     pre-checks:
       runs-on: ubuntu-latest
       outputs:
         can_deploy: ${{ steps.checks.outputs.result }}
       steps:
         - name: Check dev stability
         - name: Verify test results
         - name: Check deployment window
     
     plan:
       needs: pre-checks
       if: needs.pre-checks.outputs.can_deploy == 'true'
       # Generate plan for review
     
     approval:
       needs: plan
       runs-on: ubuntu-latest
       environment: staging-approval
       steps:
         - name: Request approval
           uses: trstringer/manual-approval@v1
     
     deploy:
       needs: approval
       uses: ./.github/workflows/deploy-infrastructure.yml
       with:
         environment: staging
         run_integration_tests: true
     
     integration-tests:
       needs: deploy
       # Comprehensive test suite
   ```

3. Production Deployment with Advanced Controls (.github/workflows/08-deploy-prod.yml):
   ```yaml
   name: Deploy to Production
   
   on:
     workflow_dispatch:
       inputs:
         deployment_type:
           type: choice
           options: [standard, emergency, rollback]
         change_ticket:
           type: string
           required: true
   
   jobs:
     validate-deployment:
       runs-on: ubuntu-latest
       steps:
         - name: Validate change ticket
         - name: Check staging validation
         - name: Verify approval chain
         - name: Check deployment window
         - name: Validate rollback plan
     
     canary-deployment:
       needs: validate-deployment
       if: inputs.deployment_type == 'standard'
       strategy:
         max-parallel: 1
         matrix:
           region: [eastus, westus, europe]
       
       steps:
         - name: Deploy to canary (10%)
         - name: Monitor metrics
         - name: Automated validation
         - name: Manual checkpoint
         - name: Progressive rollout (25%, 50%, 100%)
     
     production-deployment:
       needs: canary-deployment
       environment:
         name: production
         url: ${{ steps.deploy.outputs.environment_url }}
       
       steps:
         - name: Blue-green deployment
         - name: Health checks
         - name: Smoke tests
         - name: Performance validation
         - name: Security scan
     
     post-deployment:
       needs: production-deployment
       steps:
         - name: Update change ticket
         - name: Send notifications
         - name: Update status page
         - name: Trigger monitoring
         - name: Update documentation
   ```

4. Rollback Workflow (.github/workflows/10-rollback.yml):
   ```yaml
   name: Emergency Rollback
   
   on:
     workflow_dispatch:
       inputs:
         environment:
           type: choice
           options: [dev, staging, prod]
           required: true
         rollback_to:
           type: string
           description: 'Git tag or commit SHA'
           required: true
         reason:
           type: string
           required: true
   
   jobs:
     rollback:
       runs-on: ubuntu-latest
       environment: ${{ inputs.environment }}-emergency
       steps:
         - name: Validate rollback target
         - name: Create incident
         - name: Execute rollback
         - name: Verify rollback
         - name: Update incident
   ```

5. Drift Detection (.github/workflows/09-drift-detection.yml):
   ```yaml
   name: Drift Detection
   
   on:
     schedule:
       - cron: '0 * * * *'  # Hourly
     workflow_dispatch:
   
   jobs:
     detect-drift:
       strategy:
         matrix:
           environment: [dev, staging, prod]
       
       steps:
         - name: Run Terraform plan
         - name: Check for drift
         - name: Generate drift report
         - name: Create issue if drift detected
         - name: Send alerts
   ```

Include deployment strategies, health checks, and automated rollback triggers.
```

**💡 Exploration Tip**: Implement feature flags for infrastructure to enable gradual rollouts!

### Step 4: Policy as Code Framework (15 minutes)

#### Option A: Code Suggestion Approach

Build policies incrementally:

```rego
# policies/security/encryption.rego
package terraform.security.encryption

# Deny storage accounts without encryption
# Check minimum TLS version
# Ensure encryption at rest
# Validate key management

# policies/cost/limits.rego
package terraform.cost.limits

# Set cost limits per environment
# Check resource SKUs
# Validate auto-shutdown policies
# Enforce tagging for cost allocation
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create comprehensive Policy as Code framework:

1. Security Policies (policies/security/):
   ```rego
   # comprehensive-security.rego
   package terraform.security
   
   import future.keywords.contains
   import future.keywords.if
   
   # Encryption Requirements
   deny[msg] {
       resource := input.resource_changes[_]
       resource.type == "azurerm_storage_account"
       not resource.change.after.enable_https_traffic_only
       msg := sprintf("Storage account '%s' must enforce HTTPS", [resource.address])
   }
   
   deny[msg] {
       resource := input.resource_changes[_]
       resource.type == "azurerm_sql_database"
       not resource.change.after.transparent_data_encryption.state == "Enabled"
       msg := sprintf("SQL Database '%s' must have TDE enabled", [resource.address])
   }
   
   # Network Security
   deny[msg] {
       resource := input.resource_changes[_]
       resource.type == "azurerm_network_security_rule"
       resource.change.after.direction == "Inbound"
       resource.change.after.access == "Allow"
       resource.change.after.source_address_prefix == "*"
       resource.change.after.destination_port_range == "*"
       msg := sprintf("NSG rule '%s' is too permissive", [resource.address])
   }
   
   # Identity and Access
   deny[msg] {
       resource := input.resource_changes[_]
       resource.type == "azurerm_key_vault"
       not resource.change.after.enable_rbac_authorization
       msg := sprintf("Key Vault '%s' must use RBAC", [resource.address])
   }
   
   # Compliance Checks
   required_providers := {
       "azurerm": "~> 3.0",
       "random": "~> 3.0"
   }
   
   deny[msg] {
       provider := input.configuration.provider_config[name]
       required_version := required_providers[name]
       not semver.match(required_version, provider.version_constraint)
       msg := sprintf("Provider '%s' version must match %s", [name, required_version])
   }
   ```

2. Cost Policies (policies/cost/):
   ```rego
   # cost-control.rego
   package terraform.cost
   
   # Environment cost limits (monthly USD)
   cost_limits := {
       "dev": 1000,
       "staging": 5000,
       "prod": 20000
   }
   
   # SKU restrictions by environment
   allowed_skus := {
       "dev": {
           "azurerm_app_service_plan": ["B1", "B2", "B3"],
           "azurerm_sql_database": ["Basic", "S0"],
           "azurerm_virtual_machine": ["Standard_B2s", "Standard_B2ms"]
       },
       "staging": {
           "azurerm_app_service_plan": ["S1", "S2", "S3", "P1v2"],
           "azurerm_sql_database": ["S0", "S1", "S2", "S3"],
           "azurerm_virtual_machine": ["Standard_D2s_v3", "Standard_D4s_v3"]
       },
       "prod": {
           "azurerm_app_service_plan": ["P1v2", "P2v2", "P3v2", "P1v3", "P2v3"],
           "azurerm_sql_database": ["S3", "S4", "S6", "S7", "P1", "P2"],
           "azurerm_virtual_machine": ["Standard_D4s_v3", "Standard_D8s_v3", "Standard_E4s_v3"]
       }
   }
   
   deny[msg] {
       resource := input.resource_changes[_]
       env := resource.change.after.tags.Environment
       allowed := allowed_skus[env][resource.type]
       sku := resource.change.after.sku[0].name
       not sku in allowed
       msg := sprintf("SKU '%s' not allowed for %s in %s environment", [sku, resource.type, env])
   }
   
   # Auto-shutdown for non-production
   deny[msg] {
       resource := input.resource_changes[_]
       resource.type == "azurerm_virtual_machine"
       env := resource.change.after.tags.Environment
       env != "prod"
       not resource.change.after.auto_shutdown_enabled
       msg := sprintf("VM '%s' in %s must have auto-shutdown enabled", [resource.address, env])
   }
   ```

3. Compliance Policies (policies/compliance/):
   ```rego
   # compliance-framework.rego
   package terraform.compliance
   
   # CIS Azure Foundations Benchmark
   cis_checks := {
       "1.1": "Ensure that multi-factor authentication is enabled for all privileged users",
       "3.1": "Ensure that 'Secure transfer required' is set to 'Enabled'",
       "4.1": "Ensure that 'Auditing' is set to 'On'",
       "5.1": "Ensure that Network Security Group Flow Logs are enabled",
       "6.1": "Ensure that RDP access is restricted from the internet",
       "7.1": "Ensure Virtual Machines are utilizing Managed Disks",
       "8.1": "Ensure that the expiry date is set on all keys",
       "9.1": "Ensure App Service is using the latest version of TLS"
   }
   
   # Tag compliance
   required_tags := {
       "Environment": "^(dev|staging|prod)$",
       "CostCenter": "^[0-9]{6}$",
       "Owner": "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$",
       "DataClassification": "^(Public|Internal|Confidential|Restricted)$",
       "BusinessUnit": "^(Engineering|Sales|Marketing|Operations|Finance)$"
   }
   
   deny[msg] {
       resource := input.resource_changes[_]
       required_tag := required_tags[tag_name]
       tag_value := resource.change.after.tags[tag_name]
       not regex.match(required_tag, tag_value)
       msg := sprintf("Resource '%s' tag '%s' value '%s' doesn't match pattern '%s'", 
                      [resource.address, tag_name, tag_value, required_tag])
   }
   ```

4. Custom Organization Policies:
   ```rego
   # organization-specific.rego
   package terraform.organization
   
   # Naming conventions
   naming_patterns := {
       "azurerm_resource_group": "^rg-[a-z0-9-]+$",
       "azurerm_virtual_network": "^vnet-[a-z0-9-]+$",
       "azurerm_subnet": "^snet-[a-z0-9-]+$",
       "azurerm_storage_account": "^st[a-z0-9]{3,24}$",
       "azurerm_key_vault": "^kv-[a-z0-9-]{1,21}$"
   }
   
   # Region restrictions
   allowed_regions := {
       "dev": ["eastus", "eastus2", "westus2"],
       "staging": ["eastus", "eastus2"],
       "prod": ["eastus", "westeurope"]  # Multi-region for prod
   }
   
   # Backup requirements
   backup_required_resources := [
       "azurerm_sql_database",
       "azurerm_postgresql_server",
       "azurerm_mysql_server",
       "azurerm_storage_account"
   ]
   ```

5. Policy Testing Framework:
   ```yaml
   # .github/workflows/test-policies.yml
   name: Test Policy Framework
   
   on:
     pull_request:
       paths:
         - 'policies/**'
   
   jobs:
     test-policies:
       runs-on: ubuntu-latest
       steps:
         - name: Test with sample plans
         - name: Validate policy syntax
         - name: Check policy coverage
         - name: Performance testing
   ```

Include policy documentation, examples, and integration guides.
```

**💡 Exploration Tip**: Integrate with cloud-native policy engines like Azure Policy or AWS Config!

### Step 5: Monitoring and Observability (10 minutes)

#### Option A: Code Suggestion Approach

```yaml
# monitoring/dashboards/gitops-dashboard.json
# Create Grafana dashboard for:
# - Deployment frequency
# - Lead time for changes
# - Mean time to recovery
# - Change failure rate
# - Cost trends
# - Security posture

# monitoring/alerts/critical-alerts.yaml
# Define alerts for:
# - Deployment failures
# - Cost overruns
# - Security violations
# - Drift detection
# - SLA breaches
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create comprehensive monitoring solution for GitOps:

1. Metrics Collection:
   ```yaml
   # monitoring/metrics/deployment-metrics.yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: deployment-metrics
   data:
     metrics.yaml: |
       metrics:
         - name: deployment_duration_seconds
           help: Time taken for deployment
           type: histogram
           labels: [environment, status, component]
         
         - name: deployment_frequency
           help: Number of deployments
           type: counter
           labels: [environment, trigger]
         
         - name: infrastructure_drift_detected
           help: Drift detection results
           type: gauge
           labels: [environment, resource_type]
         
         - name: policy_violations_total
           help: Policy check failures
           type: counter
           labels: [environment, policy_type, severity]
         
         - name: infrastructure_cost_dollars
           help: Current infrastructure cost
           type: gauge
           labels: [environment, service, resource_type]
   ```

2. Grafana Dashboards:
   ```json
   {
     "dashboard": {
       "title": "GitOps Infrastructure Overview",
       "panels": [
         {
           "title": "Deployment Frequency",
           "targets": [{
             "expr": "rate(deployment_frequency[5m])"
           }]
         },
         {
           "title": "Deployment Success Rate",
           "targets": [{
             "expr": "sum(rate(deployment_frequency{status='success'}[5m])) / sum(rate(deployment_frequency[5m])) * 100"
           }]
         },
         {
           "title": "Mean Time to Recovery",
           "targets": [{
             "expr": "avg(deployment_duration_seconds{status='rollback'})"
           }]
         },
         {
           "title": "Cost by Environment",
           "targets": [{
             "expr": "sum(infrastructure_cost_dollars) by (environment)"
           }]
         },
         {
           "title": "Active Security Violations",
           "targets": [{
             "expr": "sum(policy_violations_total{severity='critical'}) by (environment)"
           }]
         }
       ]
     }
   }
   ```

3. AlertManager Configuration:
   ```yaml
   # monitoring/alerts/alertmanager.yaml
   global:
     resolve_timeout: 5m
     slack_api_url: '${SLACK_WEBHOOK}'
   
   route:
     group_by: ['alertname', 'environment']
     group_wait: 10s
     group_interval: 10s
     repeat_interval: 12h
     receiver: 'default'
     routes:
       - match:
           severity: critical
           environment: prod
         receiver: 'pagerduty-critical'
         continue: true
       
       - match:
           alertname: DeploymentFailed
         receiver: 'deployment-team'
       
       - match:
           alertname: CostOverrun
         receiver: 'finance-team'
       
       - match:
           alertname: SecurityViolation
         receiver: 'security-team'
   
   receivers:
     - name: 'default'
       slack_configs:
         - channel: '#infrastructure-alerts'
           title: 'Infrastructure Alert'
           text: '{{ .GroupLabels.alertname }} in {{ .GroupLabels.environment }}'
     
     - name: 'pagerduty-critical'
       pagerduty_configs:
         - service_key: '${PAGERDUTY_KEY}'
           severity: 'critical'
   ```

4. SLO Definitions:
   ```yaml
   # monitoring/slos/infrastructure-slos.yaml
   slos:
     - name: deployment_success_rate
       description: "95% of deployments should succeed"
       objective: 95
       window: 30d
       indicator:
         ratio:
           success:
             metric: deployment_frequency{status="success"}
           total:
             metric: deployment_frequency
     
     - name: deployment_speed
       description: "90% of deployments complete within 15 minutes"
       objective: 90
       window: 7d
       indicator:
         latency:
           success:
             metric: deployment_duration_seconds
             threshold: 900  # 15 minutes
     
     - name: infrastructure_availability
       description: "99.9% uptime for production infrastructure"
       objective: 99.9
       window: 30d
       indicator:
         ratio:
           success:
             metric: up{environment="prod"}
           total:
             metric: up
   ```

5. Automated Reporting:
   ```python
   # scripts/generate-report.py
   #!/usr/bin/env python3
   """Generate weekly GitOps metrics report"""
   
   import prometheus_client
   import matplotlib.pyplot as plt
   from datetime import datetime, timedelta
   import smtplib
   from email.mime.multipart import MIMEMultipart
   from email.mime.text import MIMEText
   
   def generate_report():
       # Query Prometheus for metrics
       # Generate charts
       # Create HTML report
       # Send via email
       pass
   ```

Include runbooks for incident response and troubleshooting guides.
```

**💡 Exploration Tip**: Implement AIOps for predictive failure detection and automated remediation!

### Step 6: Testing and Validation (10 minutes)

#### Option A: Code Suggestion Approach

```python
# tests/integration/test_deployment.py
import pytest
import subprocess
import json

# Test that deployment succeeds
# Validate all resources created
# Check resource configurations
# Verify connectivity
# Test rollback procedures

# tests/compliance/test_policies.py
# Test OPA policies with sample plans
# Validate policy coverage
# Check for false positives
# Performance benchmarks
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create comprehensive testing framework for GitOps:

1. Unit Tests for Workflows:
   ```yaml
   # tests/workflows/test_workflows.py
   import pytest
   import yaml
   from github import Github
   
   class TestGitHubWorkflows:
       def test_workflow_syntax(self):
           """Validate all workflow files have correct syntax"""
           
       def test_required_secrets(self):
           """Ensure all required secrets are referenced"""
           
       def test_job_dependencies(self):
           """Validate job dependency chains"""
           
       def test_environment_protection(self):
           """Verify environment protection rules"""
   ```

2. Infrastructure Tests:
   ```go
   // tests/infrastructure/main_test.go
   package test
   
   import (
       "testing"
       "github.com/gruntwork-io/terratest/modules/terraform"
       "github.com/gruntwork-io/terratest/modules/azure"
   )
   
   func TestCompleteDeployment(t *testing.T) {
       t.Parallel()
       
       terraformOptions := &terraform.Options{
           TerraformDir: "../../infrastructure/environments/test",
       }
       
       defer terraform.Destroy(t, terraformOptions)
       
       terraform.InitAndApply(t, terraformOptions)
       
       // Validate outputs
       resourceGroup := terraform.Output(t, terraformOptions, "resource_group_name")
       assert.NotEmpty(t, resourceGroup)
       
       // Test actual resources
       azure.ResourceGroupExists(t, resourceGroup, "")
   }
   ```

3. Policy Tests:
   ```bash
   #!/bin/bash
   # tests/policies/test_policies.sh
   
   # Test security policies
   opa test policies/security/ -v
   
   # Test with sample violations
   for violation in tests/policies/violations/*.json; do
       echo "Testing violation: $violation"
       opa eval -d policies/ -i "$violation" "data.terraform.deny[x]"
   done
   
   # Test with compliant samples
   for compliant in tests/policies/compliant/*.json; do
       echo "Testing compliant: $compliant"
       result=$(opa eval -d policies/ -i "$compliant" "data.terraform.deny[x]")
       if [ "$result" != "[]" ]; then
           echo "False positive detected!"
           exit 1
       fi
   done
   ```

4. End-to-End Tests:
   ```python
   # tests/e2e/test_gitops_flow.py
   import pytest
   import git
   import time
   from github import Github
   
   class TestGitOpsFlow:
       def test_complete_deployment_flow(self):
           """Test entire GitOps flow from PR to production"""
           
           # Create feature branch
           repo = git.Repo('.')
           feature_branch = repo.create_head('test/e2e-deployment')
           
           # Make infrastructure change
           # Create PR
           # Wait for checks
           # Approve PR
           # Merge PR
           # Verify dev deployment
           # Promote to staging
           # Verify staging
           # Promote to production
           # Verify production
           
       def test_rollback_flow(self):
           """Test emergency rollback procedures"""
           
       def test_drift_detection(self):
           """Test drift detection and remediation"""
   ```

5. Chaos Engineering:
   ```yaml
   # tests/chaos/experiments.yaml
   version: 1.0.0
   title: GitOps Chaos Experiments
   description: Test GitOps resilience
   
   steady-state-hypothesis:
     title: System is healthy
     probes:
       - type: probe
         name: deployments-succeeding
         provider:
           type: prometheus
           query: rate(deployment_frequency{status="success"}[5m]) > 0.95
   
   method:
     - type: action
       name: inject-terraform-failure
       provider:
         type: process
         path: ./inject_failure.sh
         arguments: ["terraform", "random"]
     
     - type: action
       name: corrupt-state-file
       provider:
         type: python
         module: chaos_terraform
         func: corrupt_state
   
   rollbacks:
     - type: action
       name: restore-state
       provider:
         type: process
         path: ./restore_state.sh
   ```

Include contract testing, performance benchmarks, and security penetration tests.
```

**💡 Exploration Tip**: Implement property-based testing for infrastructure code!

## ☁️ Production GitOps Implementation

### Enterprise GitOps Architecture

```markdown
# Copilot Agent Prompt:
Create enterprise-ready GitOps implementation:

1. Multi-Cluster GitOps:
   ```yaml
   # Fleet management for multiple clusters/environments
   apiVersion: fleet.cattle.io/v1alpha1
   kind: GitRepo
   metadata:
     name: infrastructure-fleet
   spec:
     repo: https://github.com/company/infrastructure
     branch: main
     paths:
       - infrastructure/environments/dev
       - infrastructure/environments/staging
       - infrastructure/environments/prod
     targets:
       - name: dev-cluster
         clusterSelector:
           matchLabels:
             environment: dev
       - name: staging-cluster
         clusterSelector:
           matchLabels:
             environment: staging
       - name: prod-clusters
         clusterSelector:
           matchLabels:
             environment: prod
   ```

2. Progressive Delivery:
   - Canary deployments with Flagger
   - Blue-green with Traffic Manager
   - Feature flags with LaunchDarkly
   - A/B testing infrastructure

3. Compliance Automation:
   - Automated compliance reporting
   - Audit trail generation
   - Evidence collection
   - Regulatory mappings

4. Disaster Recovery:
   - Automated backup procedures
   - Cross-region replication
   - Failover automation
   - Recovery time objectives

5. FinOps Integration:
   - Real-time cost tracking
   - Budget enforcement
   - Chargeback/showback
   - Optimization recommendations

Create implementation guide with examples.
```

## 🎯 Challenge Extensions

### Advanced GitOps Patterns

```markdown
# Copilot Agent Prompt for Advanced Patterns:

Implement these enterprise GitOps patterns:

1. GitOps for Hybrid Cloud:
   - Azure primary, AWS secondary
   - On-premises integration
   - Edge deployments
   - Consistent tooling

2. Policy-Driven Automation:
   - Self-healing infrastructure
   - Automated compliance fixes
   - Security remediation
   - Cost optimization bots

3. AI-Powered GitOps:
   - Predictive scaling
   - Anomaly detection
   - Intelligent rollbacks
   - Configuration optimization

4. Platform Engineering:
   - Self-service portal
   - Golden paths
   - Developer experience
   - Internal developer platform

Choose one pattern and implement completely!
```

## ✅ Completion Checklist

### Core Requirements
- [ ] Repository structure created
- [ ] CI workflows validated
- [ ] CD pipelines deployed
- [ ] Policies enforced
- [ ] Monitoring active
- [ ] Documentation complete

### Advanced Achievements
- [ ] Multi-environment working
- [ ] Security scanning clean
- [ ] Cost tracking enabled
- [ ] Drift detection active
- [ ] Rollback tested
- [ ] Compliance automated

### Excellence Indicators
- [ ] Self-healing enabled
- [ ] Zero-downtime deployments
- [ ] Predictive monitoring
- [ ] Full observability
- [ ] Platform engineering ready

## 🎉 Congratulations!

You've mastered GitOps with both Copilot approaches:
- **Code Suggestions** for understanding GitOps patterns and workflows
- **Agent Mode** for complex pipeline generation and automation

**Reflection Questions:**
1. How has GitOps improved your deployment reliability?
2. What time savings have you achieved through automation?
3. Which GitOps patterns will transform your organization?

**Next Steps:**
- Implement GitOps for your production workloads
- Explore advanced patterns like progressive delivery
- Build a platform engineering team
- Share your GitOps journey with the community

**Remember**: GitOps is not just about automation—it's about creating a culture of transparency, reliability, and continuous improvement. Every commit is a deployment!