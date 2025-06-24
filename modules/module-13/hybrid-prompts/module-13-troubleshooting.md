# Module 13 - Comprehensive Troubleshooting Guide

## 🔧 Overview

This guide helps you resolve common issues encountered in Module 13 exercises, covering both GitHub Copilot approaches and infrastructure deployment challenges.

## 🤖 GitHub Copilot Issues

### Code Suggestions Not Appearing

#### Symptoms
- No inline suggestions when typing
- Tab key doesn't complete code
- Ghost text not showing

#### Solutions

```markdown
# Copilot Agent Prompt:
Help me troubleshoot GitHub Copilot code suggestions:

1. Check Copilot status in VS Code
2. Verify subscription is active
3. Test with a simple Python function
4. Check network connectivity
5. Review VS Code settings

Provide diagnostic commands and fixes.
```

**Manual Steps:**
1. Check status bar: Look for Copilot icon
2. Run command: `GitHub Copilot: Status`
3. Verify settings:
   ```json
   {
     "github.copilot.enable": {
       "*": true,
       "yaml": true,
       "markdown": true,
       "terraform": true
     }
   }
   ```
4. Restart VS Code
5. Sign out and back into GitHub

### Agent Mode (Chat) Not Responding

#### Symptoms
- Chat window opens but no responses
- "Thinking" indicator stuck
- Error messages in chat

#### Solutions
1. **Check Extension Version**
   ```bash
   code --list-extensions --show-versions | grep copilot
   # Should show latest versions
   ```

2. **Clear Chat Context**
   - Click "New Chat" button
   - Start with simpler prompt
   - Avoid very long prompts initially

3. **Network Issues**
   - Check proxy settings
   - Verify firewall allows GitHub
   - Test with mobile hotspot

## 🔵 Bicep Deployment Issues (Exercise 1)

### "Invalid Template" Errors

#### Symptom
```
Error: Code=InvalidTemplate; Message=Deployment template validation failed
```

#### Solutions

**Using Code Suggestions:**
```bicep
// Add this comment above problematic resource:
// Fix validation error for resource type and API version
// Ensure all required properties are included
// Check parent-child relationships
```

**Using Agent Mode:**
```markdown
# Copilot Agent Prompt:
I'm getting "InvalidTemplate" error with this Bicep code:
[paste your code]

Please:
1. Identify the validation issue
2. Fix the template syntax
3. Ensure API versions are current
4. Add any missing required properties
```

### Resource Already Exists

#### Symptom
```
Error: Code=Conflict; Message=The resource already exists
```

#### Solution Script
```bash
#!/bin/bash
# cleanup-resources.sh

RESOURCE_GROUP="rg-workshop-module13"

echo "🧹 Cleaning up existing resources..."

# List all resources
az resource list --resource-group $RESOURCE_GROUP --output table

# Delete specific resource types
az resource delete \
  --resource-group $RESOURCE_GROUP \
  --name "problematic-resource-name" \
  --resource-type "Microsoft.Web/sites" \
  --confirm

# Or delete entire resource group (careful!)
# az group delete --name $RESOURCE_GROUP --yes --no-wait
```

### Bicep CLI Issues

#### Symptom
```
bicep: command not found
```

#### Platform-Specific Fixes

**Windows PowerShell:**
```powershell
# Install using Azure CLI
az bicep install

# Or direct download
Invoke-WebRequest -Uri https://github.com/Azure/bicep/releases/latest/download/bicep-win-x64.exe -OutFile bicep.exe
Move-Item bicep.exe "$env:USERPROFILE\.azure\bin\bicep.exe"
```

**macOS:**
```bash
# Using Homebrew
brew tap azure/bicep
brew install bicep

# Or using Azure CLI
az bicep install
```

**Linux:**
```bash
# Download and install
curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
chmod +x ./bicep
sudo mv ./bicep /usr/local/bin/bicep
```

## 🟢 Terraform Issues (Exercise 2)

### State Lock Errors

#### Symptom
```
Error: Error acquiring the state lock
Error message: state blob is already locked
```

#### Solutions

1. **Force Unlock (Careful!)**
   ```bash
   terraform force-unlock <LOCK_ID>
   ```

2. **Check for Running Operations**
   ```bash
   # List running operations
   ps aux | grep terraform
   
   # Kill stuck process
   kill -9 <PID>
   ```

3. **Break Lease in Azure**
   ```bash
   # Get storage account details
   STORAGE_ACCOUNT=$(terraform output -raw storage_account_name)
   
   # Break lease
   az storage blob lease break \
     --container-name tfstate \
     --name terraform.tfstate \
     --account-name $STORAGE_ACCOUNT
   ```

### Provider Authentication Failures

#### Symptom
```
Error: building AzureRM Client: obtain subscription() from Azure CLI
```

#### Solutions

**Using Code Suggestions:**
```hcl
# Add provider configuration with authentication
# Use Azure CLI authentication
# Or use Service Principal with environment variables
provider "azurerm" {
  features {}
  # Let Copilot suggest authentication method
}
```

**Using Agent Mode:**
```markdown
# Copilot Agent Prompt:
Create Terraform Azure provider configuration that:
1. Supports multiple authentication methods
2. Works with GitHub Actions
3. Handles different environments
4. Includes proper error handling
```

### Module Download Failures

#### Symptom
```
Error: Failed to download module
```

#### Solutions
```bash
# Clear module cache
rm -rf .terraform/modules

# Re-initialize with upgrade
terraform init -upgrade

# Use specific module versions
module "network" {
  source  = "Azure/network/azurerm"
  version = "5.3.0"  # Pin version
}
```

## 🟡 GitOps Pipeline Issues (Exercise 3)

### GitHub Actions Workflow Failures

#### Symptom
```
Error: Process completed with exit code 1
```

#### Debugging Steps

1. **Enable Debug Logging**
   ```yaml
   env:
     ACTIONS_STEP_DEBUG: true
     ACTIONS_RUNNER_DEBUG: true
   ```

2. **Add Diagnostic Steps**
   ```yaml
   - name: Debug Information
     run: |
       echo "Event: ${{ github.event_name }}"
       echo "Ref: ${{ github.ref }}"
       echo "SHA: ${{ github.sha }}"
       env | sort
   ```

3. **Test Locally with Act**
   ```bash
   # Install act
   brew install act  # or appropriate for your OS
   
   # Run workflow locally
   act -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest
   ```

### Secret Not Found Errors

#### Symptom
```
Error: Input required and not supplied: creds
```

#### Solutions

1. **Verify Secrets Exist**
   ```bash
   gh secret list
   ```

2. **Re-create Secrets**
   ```bash
   # Create service principal
   az ad sp create-for-rbac --name "GitHub-Actions" \
     --role contributor \
     --scopes /subscriptions/$SUBSCRIPTION_ID \
     --sdk-auth > azure-creds.json
   
   # Set secret
   gh secret set AZURE_CREDENTIALS < azure-creds.json
   
   # Clean up
   rm azure-creds.json
   ```

3. **Check Environment Secrets**
   ```bash
   # List environments
   gh api repos/:owner/:repo/environments
   
   # Check specific environment
   gh api repos/:owner/:repo/environments/production/secrets
   ```

### Policy Validation Failures

#### Symptom
```
Error: OPA policy check failed
```

#### Debugging OPA Policies

1. **Test Policies Locally**
   ```bash
   # Test with sample input
   opa eval -d policies/ -i test-input.json "data.terraform.deny"
   
   # Run policy tests
   opa test policies/ -v
   ```

2. **Add Debug Output**
   ```rego
   # Add debug prints in policy
   deny[msg] {
     print("Checking resource:", input.resource_changes[_])
     # ... rest of policy
   }
   ```

3. **Validate Policy Syntax**
   ```bash
   # Format check
   opa fmt --list policies/
   
   # Syntax check
   opa parse policies/**/*.rego
   ```

## 🔴 Azure Deployment Issues

### Quota Exceeded Errors

#### Symptom
```
Error: Code=QuotaExceeded; Message=Operation could not be completed as it results in exceeding approved quota
```

#### Solutions

1. **Check Current Usage**
   ```bash
   # Check VM quota
   az vm list-usage --location eastus2 --output table
   
   # Check all quotas
   az quota list --scope /subscriptions/$SUBSCRIPTION_ID
   ```

2. **Request Quota Increase**
   ```bash
   # Via Azure CLI
   az quota create --resource-type Microsoft.Compute/virtualMachines \
     --limit 50 \
     --location eastus2
   ```

3. **Use Different Regions**
   ```hcl
   variable "fallback_locations" {
     default = ["eastus2", "westus2", "centralus"]
   }
   ```

### Network Security Group Rules Not Working

#### Symptom
- Cannot access deployed resources
- Connection timeouts

#### Diagnostic Steps

```markdown
# Copilot Agent Prompt:
Create a comprehensive network troubleshooting script that:
1. Lists all NSG rules
2. Checks effective security rules
3. Tests connectivity
4. Validates route tables
5. Checks for overlapping rules
```

**Manual Testing:**
```bash
# Check NSG rules
az network nsg rule list --nsg-name <NSG_NAME> -g <RG> --output table

# Check effective rules
az network nic list-effective-nsg \
  --name <NIC_NAME> \
  --resource-group <RG>

# Test connectivity
az network watcher test-connectivity \
  --source-resource <SOURCE_VM_ID> \
  --dest-address <TARGET_IP> \
  --dest-port <PORT>
```

## 🛠️ General Troubleshooting Techniques

### Enable Verbose Logging

**Terraform:**
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log
terraform apply
```

**Bicep:**
```bash
az deployment group create \
  --debug \
  --verbose \
  --resource-group $RG \
  --template-file main.bicep
```

**GitHub Actions:**
```yaml
- name: Deploy with debugging
  env:
    DEBUG: '*'
    ACTIONS_STEP_DEBUG: true
  run: |
    set -x  # Shell debugging
    your-deployment-command
```

### Resource Cleanup Script

```bash
#!/bin/bash
# emergency-cleanup.sh

echo "⚠️  Emergency Cleanup Script"
echo "This will delete all Module 13 resources!"
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
    # Delete all resource groups with module-13 tag
    az group list --tag Module=13 --query "[].name" -o tsv | while read rg; do
        echo "Deleting resource group: $rg"
        az group delete --name "$rg" --yes --no-wait
    done
    
    # Clean Terraform state
    rm -rf .terraform terraform.tfstate*
    
    # Clean local files
    rm -rf .bicep .terraform.lock.hcl
    
    echo "✅ Cleanup complete"
else
    echo "❌ Cleanup cancelled"
fi
```

## 📊 Performance Optimization

### Slow Deployments

```markdown
# Copilot Agent Prompt:
My infrastructure deployments are taking too long. Create optimizations for:

1. Terraform deployments taking 30+ minutes
2. Bicep deployments with many resources
3. GitHub Actions running slowly
4. Parallel resource creation

Include before/after metrics and monitoring.
```

### Memory Issues

**VS Code Performance:**
```json
// settings.json
{
  "files.watcherExclude": {
    "**/.terraform/**": true,
    "**/node_modules/**": true
  },
  "search.exclude": {
    "**/.terraform": true,
    "**/tfplan": true
  }
}
```

## 🆘 Getting Additional Help

### Resources
1. **Module Discussions**: GitHub Discussions for peer help
2. **Office Hours**: Weekly instructor sessions
3. **Slack Channel**: #module-13-help
4. **Documentation**: Official Azure/Terraform/GitHub docs

### Diagnostic Information to Collect

When asking for help, include:
```bash
# System info
uname -a  # or systeminfo on Windows
code --version
az --version
terraform --version
bicep --version

# Error context
echo $?  # Last command exit code
env | grep -E "(AZURE|TF_|GITHUB)" | sort

# Log files
tail -n 50 terraform.log
cat .github/workflows/run-*.log
```

## ✅ Prevention Tips

1. **Always validate before deploying**
2. **Use consistent naming conventions**
3. **Pin versions for reproducibility**
4. **Test in dev environment first**
5. **Keep backups of working configurations**
6. **Document your changes**
7. **Use version control effectively**

---

**Still stuck?** Don't hesitate to ask for help in the workshop discussions. Include error messages, what you've tried, and diagnostic information for faster resolution!