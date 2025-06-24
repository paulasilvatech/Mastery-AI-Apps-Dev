# Module 13 - Azure Deployment & GitOps Best Practices Guide

## 🚀 Azure Deployment Strategies

### Deployment Patterns by Exercise

| Pattern | Exercise 1 (Bicep) | Exercise 2 (Terraform) | Exercise 3 (GitOps) |
|---------|-------------------|----------------------|-------------------|
| **Blue-Green** | ✅ Slots in App Service | ✅ Traffic Manager | ✅ Automated switching |
| **Canary** | ✓ Manual weights | ✅ Terraform modules | ✅ Progressive rollout |
| **Rolling** | ✓ Update domains | ✅ Instance refresh | ✅ Automated waves |
| **Immutable** | ✅ New resources | ✅ Replace on change | ✅ GitOps native |

### Complete Azure Deployment Solution

```markdown
# Copilot Agent Prompt:
Create a comprehensive Azure deployment solution using IaC:

1. Hub-Spoke Network Architecture:
   ```bicep
   // hub-network.bicep
   param location string = resourceGroup().location
   param hubVnetPrefix string = '10.0.0.0/16'
   param firewallSubnetPrefix string = '10.0.1.0/24'
   
   resource hubVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
     name: 'vnet-hub'
     location: location
     properties: {
       addressSpace: {
         addressPrefixes: [hubVnetPrefix]
       }
       subnets: [
         {
           name: 'AzureFirewallSubnet'
           properties: {
             addressPrefix: firewallSubnetPrefix
           }
         }
       ]
     }
   }
   
   // Azure Firewall for central security
   resource firewall 'Microsoft.Network/azureFirewalls@2023-05-01' = {
     name: 'fw-central'
     location: location
     properties: {
       sku: {
         tier: 'Premium'
       }
       firewallPolicy: {
         id: firewallPolicy.id
       }
     }
   }
   ```

2. Landing Zone Implementation:
   ```terraform
   # modules/landing-zone/main.tf
   module "naming" {
     source = "./modules/naming"
     prefix = var.prefix
     environment = var.environment
   }
   
   module "networking" {
     source = "./modules/networking"
     
     create_hub = var.is_hub
     address_space = var.address_space
     enable_firewall = var.enable_firewall
     enable_bastion = var.enable_bastion
   }
   
   module "identity" {
     source = "./modules/identity"
     
     create_domain_controllers = var.is_hub
     enable_aad_ds = var.enable_aad_ds
   }
   
   module "management" {
     source = "./modules/management"
     
     log_analytics_workspace_id = var.log_analytics_workspace_id
     enable_update_management = true
     enable_change_tracking = true
   }
   ```

3. Zero-Trust Security Model:
   - Private endpoints for all PaaS services
   - No public IPs except Application Gateway
   - mTLS between all services
   - Managed identities everywhere
   - Key Vault for all secrets
   - Defender for Cloud enabled

4. High Availability Architecture:
   - Multi-region active-passive
   - Availability zones in each region
   - Traffic Manager for global routing
   - Geo-redundant storage
   - Cross-region replication

5. Cost Optimization Features:
   - Auto-shutdown for non-production
   - Spot instances for batch workloads
   - Reserved instances for predictable loads
   - Autoscaling with schedule
   - Cost alerts and budgets
```

## 📋 GitOps Best Practices

### Repository Structure Best Practices

```markdown
# Copilot Agent Prompt:
Design an enterprise GitOps repository structure:

```
infrastructure-gitops/
├── .github/
│   ├── CODEOWNERS
│   ├── workflows/
│   │   ├── _templates/           # Reusable workflow templates
│   │   ├── ci/                   # Continuous Integration
│   │   ├── cd/                   # Continuous Deployment
│   │   ├── security/             # Security workflows
│   │   └── operations/           # Operational workflows
│   └── renovate.json            # Dependency updates
├── environments/
│   ├── bootstrap/               # Initial setup
│   ├── dev/
│   │   ├── kustomization.yaml   # If using Kubernetes
│   │   ├── terraform.tfvars
│   │   └── values.yaml          # Helm values
│   ├── staging/
│   └── prod/
├── infrastructure/
│   ├── aws/                     # Multi-cloud support
│   ├── azure/
│   │   ├── bicep/
│   │   └── terraform/
│   └── gcp/
├── applications/
│   ├── backend/
│   ├── frontend/
│   └── shared/
├── policies/
│   ├── security/
│   ├── compliance/
│   └── cost/
├── scripts/
│   ├── automation/
│   ├── migration/
│   └── utilities/
└── docs/
    ├── architecture/
    ├── runbooks/
    └── disaster-recovery/
```

Key Principles:
1. **Environment Isolation**: Separate folders prevent accidental cross-env changes
2. **Tool Flexibility**: Support multiple IaC tools
3. **Application Coupling**: Keep app config close to infrastructure
4. **Policy Enforcement**: Centralized policy management
5. **Documentation**: Colocated with code
```

### GitOps Workflow Patterns

```yaml
# Advanced GitOps Workflow Example
name: Progressive Infrastructure Deployment

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  TF_VERSION: "1.6.5"
  BICEP_VERSION: "0.24.24"
  
jobs:
  # Smart change detection
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.set-matrix.outputs.matrix }}
    steps:
      - uses: actions/checkout@v4
      - id: set-matrix
        run: |
          # Detect changes and build deployment matrix
          # Include dependency analysis
          
  # Parallel validation
  validate:
    needs: detect-changes
    strategy:
      matrix: ${{ fromJson(needs.detect-changes.outputs.matrix) }}
    runs-on: ubuntu-latest
    steps:
      - name: Validate ${{ matrix.tool }} in ${{ matrix.environment }}
        run: |
          # Tool-specific validation
          
  # Progressive deployment
  deploy:
    needs: validate
    strategy:
      max-parallel: 1  # Ensure sequential deployment
      matrix:
        environment: [dev, staging, prod]
    uses: ./.github/workflows/deploy-environment.yml
    with:
      environment: ${{ matrix.environment }}
    secrets: inherit
```

### Security in GitOps

```markdown
# Copilot Agent Prompt:
Implement comprehensive GitOps security:

1. Secret Management:
   ```yaml
   # Using Azure Key Vault with GitHub Actions
   - name: Get secrets from Key Vault
     uses: Azure/get-keyvault-secrets@v1
     with:
       keyvault: "kv-gitops-prod"
       secrets: |
         terraform-backend-key
         azure-client-secret
         notification-webhook
   ```

2. RBAC Implementation:
   ```hcl
   # terraform/modules/rbac/main.tf
   locals {
     role_assignments = {
       "DevOps Engineers" = {
         role = "Contributor"
         scope = "subscription"
       }
       "Developers" = {
         role = "Reader"
         scope = "resource_group"
       }
       "Security Team" = {
         role = "Security Admin"
         scope = "subscription"
       }
     }
   }
   ```

3. Policy Enforcement:
   ```rego
   # policies/security/gitops.rego
   package gitops.security
   
   # Enforce signed commits
   deny[msg] {
     not input.commit.signature
     msg := "All commits must be signed"
   }
   
   # Require approval for production
   deny[msg] {
     input.environment == "production"
     count(input.approvals) < 2
     msg := "Production requires 2 approvals"
   }
   ```

4. Audit Trail:
   - All changes tracked in Git
   - Deployment history in GitHub
   - Azure Activity Log integration
   - Immutable audit storage
```

## 🏗️ Production-Ready Templates

### Complete Application Stack

```markdown
# Copilot Agent Prompt:
Create production-ready templates for a complete application:

1. Frontend (Static Web App):
   ```bicep
   // frontend.bicep
   param appName string
   param environment string
   param customDomain string = ''
   
   resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = {
     name: 'stapp-${appName}-${environment}'
     location: 'eastus2'
     sku: {
       name: environment == 'prod' ? 'Standard' : 'Free'
     }
     properties: {
       repositoryUrl: 'https://github.com/org/frontend'
       branch: environment
       buildProperties: {
         appLocation: 'src'
         outputLocation: 'dist'
       }
     }
   }
   
   // Custom domain for production
   resource customDomainResource 'Microsoft.Web/staticSites/customDomains@2023-01-01' = if (!empty(customDomain)) {
     parent: staticWebApp
     name: customDomain
   }
   ```

2. Backend API (Container Apps):
   ```terraform
   # backend-api.tf
   resource "azurerm_container_app" "api" {
     name                = "ca-${var.app_name}-${var.environment}"
     resource_group_name = azurerm_resource_group.main.name
     location            = azurerm_resource_group.main.location
     container_app_environment_id = azurerm_container_app_environment.main.id
     
     template {
       container {
         name   = "api"
         image  = "${var.acr_url}/${var.app_name}:${var.image_tag}"
         cpu    = var.cpu
         memory = var.memory
         
         env {
           name  = "DATABASE_URL"
           value = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.main.name};SecretName=database-url)"
         }
       }
       
       min_replicas = var.min_replicas
       max_replicas = var.max_replicas
     }
     
     ingress {
       external_enabled = false
       target_port     = 8080
       traffic_weight {
         percentage = 100
         latest_revision = true
       }
     }
     
     identity {
       type = "SystemAssigned"
     }
   }
   ```

3. Database (Cosmos DB):
   ```bicep
   // database.bicep
   resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' = {
     name: 'cosmos-${appName}-${environment}'
     location: location
     kind: 'GlobalDocumentDB'
     properties: {
       databaseAccountOfferType: 'Standard'
       consistencyPolicy: {
         defaultConsistencyLevel: 'Session'
       }
       locations: [
         {
           locationName: location
           failoverPriority: 0
           isZoneRedundant: environment == 'prod'
         }
       ]
       capabilities: environment == 'prod' ? [] : [
         {
           name: 'EnableServerless'
         }
       ]
     }
   }
   ```

4. Monitoring Stack:
   ```yaml
   # monitoring/kustomization.yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   
   resources:
     - prometheus.yaml
     - grafana.yaml
     - alertmanager.yaml
     - loki.yaml
   
   configMapGenerator:
     - name: prometheus-config
       files:
         - prometheus.yml
     - name: grafana-dashboards
       files:
         - dashboards/*.json
   ```
```

## 🔐 Security Best Practices

### Defense in Depth

```markdown
# Copilot Agent Prompt:
Implement defense-in-depth security for Azure infrastructure:

1. Network Security:
   - Network segmentation with NSGs
   - Azure Firewall with IDPS
   - DDoS Protection Standard
   - Private endpoints for all PaaS
   - No public IPs except load balancers

2. Identity Security:
   - Managed identities everywhere
   - No service principals with keys
   - Conditional access policies
   - MFA for all human access
   - Just-in-time access

3. Data Security:
   - Encryption at rest (CMK)
   - Encryption in transit (TLS 1.3)
   - Data classification
   - Backup encryption
   - Secure key rotation

4. Application Security:
   - WAF on Application Gateway
   - API Management for rate limiting
   - Container image scanning
   - Dependency scanning
   - Secret scanning in CI/CD

5. Operational Security:
   - Security Center/Defender
   - Sentinel for SIEM
   - Audit logging
   - Threat detection
   - Incident response automation
```

## 📊 Cost Optimization Strategies

### FinOps for IaC

```markdown
# Copilot Agent Prompt:
Implement FinOps practices in infrastructure code:

1. Tagging Strategy:
   ```bicep
   var commonTags = {
     Environment: environment
     Application: appName
     CostCenter: costCenter
     Owner: owner
     CreatedBy: 'IaC'
     ManagedBy: 'GitOps'
     Department: department
     Project: projectCode
   }
   ```

2. Auto-shutdown Policies:
   ```terraform
   resource "azurerm_dev_test_global_vm_shutdown_schedule" "shutdown" {
     for_each = var.environment != "prod" ? var.vms : {}
     
     virtual_machine_id = each.value.id
     location          = each.value.location
     enabled           = true
     
     daily_recurrence_time = "1900"
     timezone             = "Pacific Standard Time"
     
     notification_settings {
       enabled = false
     }
   }
   ```

3. Right-sizing Automation:
   ```python
   # scripts/rightsize.py
   def analyze_vm_metrics(vm_id, days=30):
       """Analyze VM metrics and recommend sizing"""
       metrics = get_metrics(vm_id, days)
       
       avg_cpu = metrics['cpu_percent'].mean()
       avg_memory = metrics['memory_percent'].mean()
       
       if avg_cpu < 20 and avg_memory < 30:
           return recommend_smaller_sku(current_sku)
   ```

4. Cost Alerts:
   ```bicep
   resource budgets 'Microsoft.Consumption/budgets@2023-05-01' = [for env in environments: {
     name: 'budget-${env.name}'
     properties: {
       amount: env.monthlyBudget
       timeGrain: 'Monthly'
       notifications: {
         actual_GreaterThan_80_Percent: {
           enabled: true
           operator: 'GreaterThan'
           threshold: 80
           contactEmails: alertEmails
         }
       }
     }
   }]
   ```
```

## 🎯 Performance Optimization

### IaC Performance Tips

1. **Parallel Deployments**: Use `-parallelism=20` in Terraform
2. **Targeted Deployments**: Deploy only changed resources
3. **State Management**: Use partial state files for large infrastructures
4. **Caching**: Cache provider plugins and modules
5. **Conditional Resources**: Use count/for_each efficiently

## 🚀 Next-Level Practices

### Platform Engineering with IaC

```markdown
# Copilot Agent Prompt:
Create a self-service platform using IaC:

1. Developer Portal:
   - Service catalog
   - One-click deployments
   - Environment provisioning
   - Cost visibility

2. Golden Paths:
   - Pre-approved architectures
   - Security baked in
   - Best practices enforced
   - Automated compliance

3. Internal Developer Platform:
   - API for infrastructure
   - CLI tools
   - IDE integrations
   - ChatOps support

4. Governance Automation:
   - Policy enforcement
   - Compliance reporting
   - Cost governance
   - Security posture
```

## 🏁 Conclusion

Module 13 provides a comprehensive foundation for Infrastructure as Code with Azure. By mastering both GitHub Copilot approaches:

- **Code Suggestions**: Deep understanding through incremental learning
- **Agent Mode**: Rapid development of production-ready infrastructure

You're now equipped to:
- Build secure, scalable infrastructure
- Implement GitOps workflows
- Optimize costs automatically
- Maintain compliance continuously
- Deploy with confidence

**Remember**: Infrastructure as Code is a journey, not a destination. Keep iterating, learning, and sharing your knowledge!

**Happy Building! 🏗️**