# Exercise 1: Deploy Azure Resources with Bicep - Enhanced Guide (45 minutes)

## 🎯 Overview

Build a web application infrastructure using Azure Bicep with two powerful GitHub Copilot approaches:
- **Code Suggestion Mode**: Learn Bicep syntax incrementally with inline AI assistance
- **Agent Mode**: Generate complete infrastructure templates through conversational AI

## 🤖 Understanding the Two Approaches

### Code Suggestion Mode
- **What it is**: GitHub Copilot suggests infrastructure code as you type based on comments
- **Best for**: Learning Bicep syntax, understanding resource relationships, incremental building
- **How it works**: Write a comment describing the resource, press Tab to accept suggestions

### Agent Mode (Copilot Chat)
- **What it is**: Conversational AI that generates complete Bicep templates and modules
- **Best for**: Complex infrastructure, multi-resource deployments, production patterns
- **How it works**: Describe your infrastructure needs, get comprehensive solutions

## 📋 Prerequisites Check

### Using Agent Mode for Setup Verification

```markdown
# Copilot Agent Prompt:
Create a comprehensive script that checks all prerequisites for Module 13 Exercise 1:

1. System Requirements:
   - Azure CLI 2.50+ installed and configured
   - Bicep CLI installed (or Azure CLI with Bicep)
   - VS Code with Bicep extension
   - Git for version control
   - GitHub Copilot enabled

2. Azure Requirements:
   - Valid Azure subscription
   - Contributor access to create resources
   - Resource providers registered:
     * Microsoft.Web
     * Microsoft.Storage
     * Microsoft.Insights
     * Microsoft.KeyVault

3. Validation Steps:
   - Check Azure login status
   - Verify subscription access
   - Test Bicep installation
   - Validate VS Code extensions
   - Check available regions

4. Create Setup Script:
   - Cross-platform (Bash/PowerShell)
   - Colored output for status
   - Install missing components
   - Set up resource group
   - Configure defaults

Include error handling and remediation steps.
```

**💡 Exploration Tip**: Extend the script to include cost estimation for the resources you'll deploy!

## 🚀 Step-by-Step Implementation

### Step 1: Project Setup and Basic Template (10 minutes)

#### Option A: Code Suggestion Approach

Create your Bicep file and build incrementally:

```bicep
// main.bicep
// Create a parameter for environment with allowed values
// dev, staging, prod with dev as default

// Create a parameter for application name
// Minimum 3 characters, maximum 24 characters

// Create variables for resource names following Azure naming conventions
// Use environment and appName in the naming pattern
```

Let Copilot complete each section as you type comments.

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create a complete Azure Bicep template for a web application infrastructure:

Infrastructure Requirements:
1. Resources to Deploy:
   - App Service Plan (Linux)
     * B1 tier for dev/staging
     * P1v3 for production
     * Auto-scaling for production only
   - Web App (Python 3.11)
     * HTTPS only
     * Managed identity enabled
     * Staging slot for production
   - Storage Account
     * Standard_LRS for dev
     * Standard_GRS for production
     * Private endpoints in production
   - Application Insights
     * Full telemetry
     * 30-day retention for dev
     * 90-day retention for production
   - Key Vault
     * Store connection strings
     * Managed identity access
     * Soft delete enabled

2. Parameters:
   - environment (dev/staging/prod)
   - appName (base name for resources)
   - location (default to resource group location)
   - tags (for cost tracking)

3. Best Practices:
   - Use variables for resource names
   - Follow Azure naming conventions
   - Implement conditional deployment
   - Add resource dependencies
   - Include diagnostic settings
   - Use secure outputs

4. Advanced Features:
   - Deployment slots for zero-downtime
   - Auto-scaling rules
   - Network security
   - Backup configuration
   - Custom domain support

Generate a production-ready template with comments explaining each section.
```

**💡 Exploration Tip**: Add Azure Front Door for global load balancing and CDN capabilities!

### Step 2: Enhanced Resource Configuration (10 minutes)

#### Option A: Code Suggestion Approach

Enhance your resources with advanced features:

```bicep
// Add auto-scaling settings for production environment
// Scale between 2-10 instances based on CPU usage
// Scale up when CPU > 70% for 5 minutes
// Scale down when CPU < 30% for 5 minutes

// Add diagnostic settings to send logs to Log Analytics
// Include AppServiceHTTPLogs, AppServiceConsoleLogs
// Send all metrics to workspace

// Configure backup for production web apps
// Daily backups retained for 30 days
// Include database in backup
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Enhance the Bicep template with enterprise-grade features:

1. Security Enhancements:
   - Private endpoints for all resources
   - Network security groups with rules
   - Azure Firewall integration
   - DDoS protection for production
   - Web Application Firewall (WAF)
   - SSL/TLS certificate management

2. Monitoring and Observability:
   - Log Analytics Workspace
   - Diagnostic settings for all resources
   - Custom metrics and alerts
   - Application Performance Monitoring
   - Cost tracking with tags
   - Azure Dashboard definition

3. High Availability:
   - Multi-region deployment support
   - Traffic Manager for global routing
   - Availability zones for production
   - Geo-redundant storage
   - Database failover groups
   - Backup and disaster recovery

4. DevOps Integration:
   - Deployment slots (staging, production)
   - Blue-green deployment support
   - GitHub Actions integration
   - Container registry for Docker
   - Kubernetes service (optional)

5. Compliance and Governance:
   - Azure Policy assignments
   - Resource locks for production
   - Audit logging
   - Data encryption at rest
   - Managed identities everywhere
   - RBAC assignments

Create modules for reusability and include parameter files for each environment.
```

**💡 Exploration Tip**: Implement Azure API Management for a complete API gateway solution!

### Step 3: Modular Bicep Architecture (10 minutes)

#### Option A: Code Suggestion Approach

Create modular Bicep files:

```bicep
// modules/storage.bicep
// Create a module for storage account with:
// - Parameters for name, location, sku, kind
// - Blob services configuration
// - Container definitions
// - Lifecycle management rules
// - Outputs for connection string and endpoints

// modules/monitoring.bicep
// Create a module for monitoring resources:
// - Application Insights
// - Log Analytics Workspace
// - Diagnostic settings template
// - Alert rules
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create a modular Bicep architecture for the infrastructure:

1. Module Structure:
   ```
   infrastructure/
   ├── main.bicep              # Orchestrator
   ├── modules/
   │   ├── compute.bicep       # App Service resources
   │   ├── storage.bicep       # Storage accounts
   │   ├── networking.bicep    # VNet, NSG, Private endpoints
   │   ├── monitoring.bicep    # Insights, Log Analytics
   │   ├── security.bicep      # Key Vault, Managed identities
   │   └── database.bicep      # Optional database resources
   ├── parameters/
   │   ├── dev.bicepparam      # Dev environment
   │   ├── staging.bicepparam  # Staging environment
   │   └── prod.bicepparam     # Production environment
   └── scripts/
       ├── deploy.ps1          # PowerShell deployment
       └── deploy.sh           # Bash deployment
   ```

2. Module Requirements:
   - Each module should be self-contained
   - Use interfaces for module contracts
   - Implement proper parameter validation
   - Include comprehensive outputs
   - Add module documentation
   - Support conditional deployment

3. Cross-Module Integration:
   - Shared variables module
   - Common tagging strategy
   - Naming convention module
   - Network integration patterns
   - Security baseline module

4. Deployment Patterns:
   - Sequential deployment order
   - Dependency management
   - Rollback capabilities
   - Smoke test integration
   - Post-deployment validation

Generate all modules with proper documentation and examples.
```

**💡 Exploration Tip**: Create a Bicep registry for sharing modules across teams!

### Step 4: Parameter Files and Environments (5 minutes)

#### Option A: Code Suggestion Approach

```json
// parameters/dev.bicepparam
// Create a Bicep parameter file for dev environment
// Use the new .bicepparam format
// Include all required parameters with dev-specific values

// parameters/prod.bicepparam  
// Create production parameter file with:
// - Production SKUs
// - High availability settings
// - Enhanced security configurations
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create comprehensive parameter files for multi-environment deployment:

1. Development Environment (dev.bicepparam):
   ```bicep
   using './main.bicep'
   
   param environment = 'dev'
   param appName = 'workshop13'
   param location = 'eastus2'
   
   // Cost-optimized settings
   param appServicePlanSku = {
     name: 'B1'
     tier: 'Basic'
   }
   
   param storageAccountSku = 'Standard_LRS'
   param enableHighAvailability = false
   param enablePrivateEndpoints = false
   param retentionDays = 30
   ```

2. Staging Environment:
   - Similar to production but with lower SKUs
   - Full feature parity for testing
   - Shorter retention periods
   - Limited scaling

3. Production Environment:
   - Premium SKUs for performance
   - High availability enabled
   - Private endpoints for security
   - Extended retention (90+ days)
   - Auto-scaling configured
   - Geo-redundancy enabled

4. Feature Flags:
   - enableMonitoring
   - enableBackup
   - enableSecurityCenter
   - enableNetworkIsolation
   - enableDisasterRecovery

5. Secret Management:
   - Reference Key Vault for sensitive values
   - Use managed identities
   - Avoid hardcoded secrets
   - Environment-specific vaults

Create parameter files that support gradual feature rollout and A/B testing.
```

**💡 Exploration Tip**: Implement parameter validation using Bicep's new validation features!

### Step 5: Deployment Automation (10 minutes)

#### Option A: Code Suggestion Approach

Create deployment scripts:

```bash
#!/bin/bash
# deploy.sh - Deploy Bicep infrastructure

# Set error handling and variables
# Check prerequisites (az cli, bicep, etc.)
# Validate template syntax
# Run what-if to preview changes
# Deploy with confirmation
# Capture outputs
# Run post-deployment tests
```

```yaml
# .github/workflows/deploy-infra.yml
# Create GitHub Actions workflow that:
# - Triggers on push to main
# - Validates Bicep templates
# - Runs security scanning
# - Deploys to dev first
# - Requires approval for production
# - Runs smoke tests
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create a complete deployment automation solution:

1. PowerShell Deployment Script (deploy.ps1):
   - Parameter validation
   - Environment detection
   - Prerequisite checking
   - Cost estimation before deployment
   - What-if analysis
   - Parallel deployment where possible
   - Rollback on failure
   - Output capture and formatting
   - Integration with Azure DevOps/GitHub

2. Bash Deployment Script (deploy.sh):
   - Cross-platform compatibility
   - Colored output for better UX
   - Progress indicators
   - Error handling with retry logic
   - Logging to file
   - Slack/Teams notifications
   - Performance metrics

3. GitHub Actions Workflow:
   ```yaml
   name: Deploy Infrastructure
   
   on:
     push:
       branches: [main]
       paths:
         - 'infrastructure/**'
     pull_request:
       branches: [main]
     workflow_dispatch:
       inputs:
         environment:
           type: choice
           options: [dev, staging, prod]
   ```

4. Deployment Features:
   - Matrix strategy for multiple environments
   - Bicep linting and formatting
   - Security scanning (Checkov, tfsec)
   - Cost estimation with Infracost
   - Dependency caching
   - Artifact management
   - Environment protection rules
   - Manual approval gates
   - Automated rollback
   - Deployment history tracking

5. Post-Deployment:
   - Smoke tests with Azure CLI
   - Health check endpoints
   - Performance baselines
   - Security validation
   - Cost alerts setup
   - Documentation generation

Include reusable workflows and composite actions.
```

**💡 Exploration Tip**: Add Terraform Cloud or Azure DevOps for enterprise-grade state management!

### Step 6: Testing and Validation (5 minutes)

#### Option A: Code Suggestion Approach

```python
# test_deployment.py
# Create a Python script that:
# - Uses Azure SDK to verify resources
# - Checks resource properties match expectations
# - Validates network connectivity
# - Tests application endpoints
# - Verifies security settings
# - Generates test report
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create a comprehensive testing framework for Bicep deployments:

1. Unit Tests for Bicep (using Pester):
   ```powershell
   Describe 'Bicep Template Tests' {
     It 'Should have required parameters' {
       # Test parameter definitions
     }
     
     It 'Should follow naming conventions' {
       # Test resource names
     }
     
     It 'Should have proper tags' {
       # Test tagging strategy
     }
   }
   ```

2. Integration Tests (Python/Azure SDK):
   - Resource existence validation
   - Configuration verification
   - Network connectivity tests
   - Security posture validation
   - Performance benchmarks
   - Cost tracking validation

3. End-to-End Tests:
   - Application deployment
   - User journey testing
   - Load testing setup
   - Chaos engineering
   - Disaster recovery drills

4. Compliance Tests:
   - Azure Policy compliance
   - Security Center recommendations
   - CIS benchmark validation
   - Data residency verification
   - Encryption validation

5. Continuous Testing:
   - Scheduled test runs
   - Drift detection
   - Configuration compliance
   - Performance regression
   - Security scanning
   - Cost anomaly detection

Generate a complete testing strategy with example implementations.
```

**💡 Exploration Tip**: Integrate with Azure Chaos Studio for resilience testing!

## ☁️ Advanced Azure Deployment

### Complete Infrastructure as Code Solution

```markdown
# Copilot Agent Prompt:
Create an enterprise-ready Bicep deployment solution:

1. Advanced Bicep Features:
   - User-defined types
   - Compile-time imports
   - Lambda functions
   - Deployment stacks
   - Template specs
   - Bicep registry

2. GitOps Implementation:
   - Flux or ArgoCD integration
   - Git as source of truth
   - Automated synchronization
   - Drift detection and remediation
   - Multi-cluster support

3. Cost Optimization:
   - Azure Advisor integration
   - Cost alerts and budgets
   - Reserved instance automation
   - Spot instance usage
   - Auto-shutdown schedules
   - Resource tagging for chargeback

4. Security Hardening:
   - Azure Policy as Code
   - Defender for Cloud integration
   - Network isolation by default
   - Encryption everywhere
   - Privileged access management
   - Compliance automation

5. Multi-Region Strategy:
   - Global resource deployment
   - Data sovereignty compliance
   - Disaster recovery automation
   - Traffic management
   - Geo-redundancy patterns

Create a reference architecture with all components.
```

## 🎯 Challenge Extensions

### Advanced Infrastructure Patterns

```markdown
# Copilot Agent Prompt for Advanced Patterns:

Implement these enterprise patterns:

1. Hub-Spoke Network Topology:
   - Central hub VNet with shared services
   - Spoke VNets for workloads
   - Azure Firewall in hub
   - ExpressRoute/VPN gateway
   - Network virtual appliances

2. Landing Zone Architecture:
   - Management groups hierarchy
   - Policy inheritance
   - Centralized logging
   - Identity and access management
   - Cost management structure

3. Zero Trust Security:
   - Private endpoints everywhere
   - No public IPs
   - Application Gateway with WAF
   - Conditional access policies
   - Privileged identity management

4. Event-Driven Infrastructure:
   - Event Grid for notifications
   - Logic Apps for automation
   - Function Apps for processing
   - Service Bus for messaging
   - Event Hubs for streaming

Choose one pattern and implement it completely!
```

## ✅ Completion Checklist

### Core Requirements
- [ ] Bicep template validates successfully
- [ ] Resources deployed to Azure
- [ ] Parameter files for multiple environments
- [ ] Modular architecture implemented
- [ ] Outputs captured correctly
- [ ] Tags applied consistently

### Advanced Achievements
- [ ] Auto-scaling configured
- [ ] Monitoring and alerts set up
- [ ] Security best practices applied
- [ ] Cost optimization implemented
- [ ] CI/CD pipeline working
- [ ] Tests passing

### Excellence Indicators
- [ ] Zero-downtime deployment
- [ ] Multi-region support
- [ ] Compliance automation
- [ ] Self-healing infrastructure
- [ ] Cost anomaly detection

## 🎉 Congratulations!

You've mastered Infrastructure as Code with Bicep using both Copilot approaches:
- **Code Suggestions** for learning and incremental development
- **Agent Mode** for rapid, production-ready infrastructure

**Reflection Questions:**
1. Which approach helped you understand Bicep concepts better?
2. How much time did AI assistance save?
3. What patterns will you reuse in real projects?

**Next Steps:**
- Try Exercise 2 with Terraform for multi-cloud
- Experiment with Bicep deployment stacks
- Create your own Bicep module library
- Share your templates with the community

**Remember**: Great infrastructure is invisible when working but visible when needed. Build infrastructure that scales, secures, and serves!