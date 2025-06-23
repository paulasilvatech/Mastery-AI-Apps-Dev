# Module 13: Infrastructure as Code - Troubleshooting Guide

## 🔍 Overview

This guide helps you resolve common issues when working with Infrastructure as Code using Terraform, Bicep, and GitOps. Each issue includes symptoms, root causes, and step-by-step solutions.

## 🚨 Common Issues

### 1. Terraform State Lock Issues

#### Symptoms
```
Error: Error acquiring the state lock
Error message: state blob is already locked
Lock Info:
  ID:        xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  Path:      terraform.tfstate
  Operation: OperationTypeApply
  Who:       user@machine
  Version:   1.6.0
  Created:   2024-01-15 10:30:45
```

#### Solutions

**Option 1: Wait for lock to release**
```bash
# Locks typically timeout after 15 minutes
# Check who has the lock and coordinate
```

**Option 2: Force unlock (use with caution)**
```bash
# Get the lock ID from the error message
terraform force-unlock xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# Verify no one else is running terraform
terraform plan  # Should work now
```

**Option 3: Fix Azure Storage lock**
```bash
# Check blob lease status
az storage blob show \
  --account-name $STORAGE_ACCOUNT \
  --container-name tfstate \
  --name terraform.tfstate \
  --query "properties.lease"

# Break the lease if stuck
az storage blob lease break \
  --account-name $STORAGE_ACCOUNT \
  --container-name tfstate \
  --blob-name terraform.tfstate
```

### 2. Bicep Deployment Failures

#### Error: "The subscription is not registered to use namespace"

**Solution:**
```bash
# Register the required provider
az provider register --namespace Microsoft.Web
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Sql

# Check registration status
az provider show --namespace Microsoft.Web --query registrationState
```

#### Error: "Code: InvalidTemplateDeployment"

**Debug steps:**
```bash
# Validate the template
az deployment group validate \
  --resource-group $RG \
  --template-file main.bicep \
  --parameters @parameters.json

# Get detailed error
az deployment group create \
  --resource-group $RG \
  --template-file main.bicep \
  --parameters @parameters.json \
  --debug

# Check deployment operations
az deployment operation group list \
  --resource-group $RG \
  --name deployment-name
```

### 3. GitHub Actions Workflow Failures

#### Error: "Resource not accessible by integration"

**Solution:**
```yaml
# Ensure proper permissions in workflow
permissions:
  contents: read
  pull-requests: write
  issues: write
  actions: read
```

#### Error: "Azure credentials are not set"

**Fix:**
```bash
# Create service principal
az ad sp create-for-rbac \
  --name "GitHub-Actions" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --sdk-auth > azure-creds.json

# Set GitHub secret
gh secret set AZURE_CREDENTIALS < azure-creds.json

# Verify in workflow
- uses: azure/login@v1
  with:
    creds: ${{ secrets.AZURE_CREDENTIALS }}
```

### 4. Terraform Provider Issues

#### Error: "Failed to query available provider packages"

**Solutions:**
```bash
# Clear provider cache
rm -rf .terraform/providers

# Use mirror if having connectivity issues
terraform init -plugin-dir=/usr/local/share/terraform/plugins

# Or specify provider explicitly
cat > .terraformrc << EOF
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.company.com/"
  }
}
EOF
```

#### Error: "Invalid provider configuration"

**Debug:**
```hcl
# Enable provider debugging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log

# Check provider version constraints
terraform version
terraform providers

# Update provider version
terraform init -upgrade
```

### 5. State File Corruption

#### Symptoms
- "Error loading state: state data in S3 does not have the expected content"
- Terraform shows all resources need to be created

#### Recovery Steps

**1. Backup current state**
```bash
# Download corrupted state
az storage blob download \
  --account-name $STORAGE_ACCOUNT \
  --container-name tfstate \
  --name terraform.tfstate \
  --file terraform.tfstate.corrupted
```

**2. Restore from backup**
```bash
# List available backups
az storage blob list \
  --account-name $STORAGE_ACCOUNT \
  --container-name tfstate-backups \
  --query "[].name" \
  --output table

# Restore specific backup
az storage blob copy start \
  --source-container tfstate-backups \
  --source-blob terraform.tfstate.20240115-120000 \
  --destination-container tfstate \
  --destination-blob terraform.tfstate
```

**3. Rebuild state if no backup**
```bash
# Import existing resources
terraform import azurerm_resource_group.main /subscriptions/$SUB/resourceGroups/rg-name
terraform import azurerm_storage_account.main /subscriptions/$SUB/resourceGroups/rg-name/providers/Microsoft.Storage/storageAccounts/stname

# Verify state
terraform plan  # Should show no changes
```

### 6. Cost Estimation Failures

#### Infracost Issues

**Setup:**
```bash
# Install Infracost
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh

# Configure API key
infracost configure set api_key $INFRACOST_API_KEY

# Test
infracost breakdown --path .
```

**Common fixes:**
```yaml
# Fix GitHub Action
- name: Setup Infracost
  uses: infracost/actions/setup@v2
  with:
    api-key: ${{ secrets.INFRACOST_API_KEY }}
    version: latest  # Or specific version

# Debug mode
- name: Run Infracost
  run: |
    infracost breakdown \
      --path . \
      --log-level debug \
      --no-cache
```

### 7. Policy Validation Errors

#### OPA Policy Failures

**Debug OPA policies:**
```bash
# Test policy with example input
opa eval -d policies/ -i input.json "data.azure.resources.deny"

# Run with coverage
opa test policies/ --coverage

# Debug with print statements
cat > debug.rego << 'EOF'
package debug

deny[msg] {
  print("Input:", input)
  # Your policy logic
}
EOF
```

**Fix common issues:**
```rego
# Handle missing fields
deny[msg] {
  # Safe navigation
  tags := object.get(input.resource_changes[_].change.after, "tags", {})
  required_tags := {"Environment", "Owner"}
  missing := required_tags - {k | tags[k]}
  count(missing) > 0
  msg := sprintf("Missing tags: %v", [missing])
}
```

### 8. Network Connectivity Issues

#### Private Endpoint Problems

**Diagnosis:**
```bash
# Test DNS resolution
nslookup storageaccount.blob.core.windows.net

# Check private DNS zone
az network private-dns zone show \
  --resource-group $RG \
  --name privatelink.blob.core.windows.net

# Verify DNS records
az network private-dns record-set a list \
  --resource-group $RG \
  --zone-name privatelink.blob.core.windows.net
```

**Fix:**
```bicep
// Ensure proper DNS configuration
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
}

resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: 'link-to-vnet'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}
```

### 9. Module Dependency Issues

#### Terraform Module Problems

**Error: "Module not found"**
```bash
# Update modules
terraform get -update

# Clear module cache
rm -rf .terraform/modules
terraform init

# Use specific version
module "network" {
  source  = "Azure/network/azurerm"
  version = "3.5.0"  # Pin version
}
```

**Circular dependencies:**
```hcl
# Avoid by using data sources
data "azurerm_subnet" "existing" {
  name                 = "subnet-name"
  virtual_network_name = "vnet-name"
  resource_group_name  = "rg-name"
}

# Instead of direct module references
resource "azurerm_network_interface" "main" {
  ip_configuration {
    subnet_id = data.azurerm_subnet.existing.id  # Not module.network.subnet_id
  }
}
```

### 10. Performance Issues

#### Slow Terraform Operations

**Optimize:**
```bash
# Parallelize operations
export TF_CLI_ARGS_apply="-parallelism=20"

# Target specific resources
terraform apply -target=module.network

# Refresh only changed resources
terraform apply -refresh=false

# Use refresh-only when needed
terraform apply -refresh-only
```

**Large state files:**
```hcl
# Split into multiple state files
cd environments/prod/network
terraform init

cd ../compute  
terraform init  # Separate state

# Or use workspaces
terraform workspace new prod
terraform workspace select prod
```

## 🛠️ Diagnostic Scripts

### Health Check Script
```bash
#!/bin/bash
# diagnose.sh - Comprehensive IaC health check

echo "🔍 Running IaC Diagnostics..."

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI not found"
else
    echo "✅ Azure CLI: $(az version --query '"azure-cli"' -o tsv)"
fi

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found"
else
    echo "✅ Terraform: $(terraform version -json | jq -r .terraform_version)"
fi

# Check connectivity
if az account show &> /dev/null; then
    echo "✅ Azure connected: $(az account show --query name -o tsv)"
else
    echo "❌ Not logged into Azure"
fi

# Check state backend
if [ -f backend-config.txt ]; then
    source backend-config.txt
    if az storage blob exists \
        --account-name $storage_account_name \
        --container-name $container_name \
        --name terraform.tfstate &> /dev/null; then
        echo "✅ State file accessible"
    else
        echo "❌ State file not accessible"
    fi
fi
```

### State Recovery Script
```bash
#!/bin/bash
# recover-state.sh - Recover from state issues

STORAGE_ACCOUNT="$1"
CONTAINER="tfstate"
BACKUP_DIR="state-recovery-$(date +%Y%m%d-%H%M%S)"

mkdir -p $BACKUP_DIR

echo "🔄 Downloading current state..."
az storage blob download \
  --account-name $STORAGE_ACCOUNT \
  --container-name $CONTAINER \
  --name terraform.tfstate \
  --file $BACKUP_DIR/current.tfstate

echo "📋 Analyzing state..."
terraform show -json $BACKUP_DIR/current.tfstate > $BACKUP_DIR/state.json

echo "🔍 Resources in state:"
jq -r '.values.root_module.resources[].address' $BACKUP_DIR/state.json

echo "💾 Backup created in $BACKUP_DIR"
```

## 📞 Getting Help

### 1. Enable Debug Logging
```bash
# Terraform debugging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log

# Azure CLI debugging  
export AZURE_CLI_DEBUG=1
az ... --debug

# GitHub Actions debugging
# Add to workflow:
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

### 2. Community Resources
- [Terraform Community Forums](https://discuss.hashicorp.com/c/terraform-core)
- [Azure Bicep GitHub Issues](https://github.com/Azure/bicep/issues)
- [GitHub Actions Community](https://github.community/c/code-to-cloud/github-actions)

### 3. Workshop Support
- Check module [FAQ](./FAQ.md)
- Review [Best Practices](./best-practices.md)
- Post in [GitHub Discussions](https://github.com/workshop/discussions)

## 🔄 Prevention Tips

1. **Always Plan Before Apply**
   ```bash
   terraform plan -out=tfplan
   terraform show tfplan  # Review
   terraform apply tfplan
   ```

2. **Use PR Reviews**
   - Never apply directly to production
   - Require approval for main branch

3. **Regular Backups**
   - Automate state backups
   - Test restore procedures

4. **Monitor Everything**
   - Set up alerts for failures
   - Track deployment metrics

---

*Remember: Most IaC issues are preventable with good practices. When in doubt, plan first!*
