# Exercise 3: Complete GitOps Pipeline (Part 2)

## 📝 Part 3: Deployment Workflows

### Step 4: Create Deployment Workflow

Create the main deployment workflow that triggers on merge to main:

**💡 Copilot Prompt Suggestion:**
```yaml
# Create a GitHub Actions workflow that:
# - Triggers when PR is merged to main
# - Deploys to dev automatically
# - Requires approval for staging
# - Requires multiple approvals for prod
# - Includes smoke tests after each deployment
# - Supports automatic rollback on failure
# Path: .github/workflows/deploy-infrastructure.yml
```

**Expected Copilot Output:**
```yaml
# .github/workflows/deploy-infrastructure.yml
name: Deploy Infrastructure

on:
  push:
    branches: [main]
    paths:
      - 'infrastructure/**'
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        type: choice
        options:
          - dev
          - staging
          - prod

jobs:
  prepare:
    runs-on: ubuntu-latest
    outputs:
      environments: ${{ steps.determine.outputs.environments }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 2
      
      - name: Determine deployment targets
        id: determine
        run: |
          if [ "${{ github.event_name }}" == "workflow_dispatch" ]; then
            echo "environments=[\"${{ github.event.inputs.environment }}\"]" >> $GITHUB_OUTPUT
          else
            # Auto-deploy to dev on merge
            echo "environments=[\"dev\"]" >> $GITHUB_OUTPUT
          fi

  deploy:
    needs: prepare
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: ${{ fromJson(needs.prepare.outputs.environments) }}
    environment:
      name: ${{ matrix.environment }}
      url: ${{ steps.deploy.outputs.app_url }}
    concurrency:
      group: deploy-${{ matrix.environment }}
      cancel-in-progress: false
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: '1.6.0'
      
      - name: Create deployment artifact
        run: |
          TIMESTAMP=$(date +%Y%m%d%H%M%S)
          echo "DEPLOYMENT_ID=${TIMESTAMP}-${{ github.sha:0:7 }}" >> $GITHUB_ENV
          
          # Save current state for rollback
          mkdir -p artifacts/deployments/${{ env.DEPLOYMENT_ID }}
          cp -r infrastructure/environments/${{ matrix.environment }}/* artifacts/deployments/${{ env.DEPLOYMENT_ID }}/
      
      - name: Deploy Infrastructure
        id: deploy
        working-directory: infrastructure/environments/${{ matrix.environment }}
        run: |
          # Initialize with remote backend
          terraform init \
            -backend-config="resource_group_name=${{ secrets.TF_STATE_RG }}" \
            -backend-config="storage_account_name=${{ secrets.TF_STATE_SA }}" \
            -backend-config="container_name=tfstate" \
            -backend-config="key=${{ matrix.environment }}/terraform.tfstate"
          
          # Apply with auto-approve
          terraform apply -auto-approve -input=false
          
          # Capture outputs
          APP_URL=$(terraform output -raw web_app_url)
          echo "app_url=$APP_URL" >> $GITHUB_OUTPUT
          
          # Tag deployment
          echo "${{ env.DEPLOYMENT_ID }}" > .last_successful_deployment
      
      - name: Run Smoke Tests
        id: smoke-tests
        run: |
          APP_URL="${{ steps.deploy.outputs.app_url }}"
          
          echo "🧪 Running smoke tests for $APP_URL"
          
          # Wait for app to be ready
          for i in {1..30}; do
            if curl -s -o /dev/null -w "%{http_code}" "$APP_URL/health" | grep -q "200"; then
              echo "✅ Health check passed"
              break
            fi
            echo "Waiting for app to be ready... ($i/30)"
            sleep 10
          done
          
          # Run basic tests
          ./scripts/smoke-tests.sh "${{ matrix.environment }}" "$APP_URL"
      
      - name: Rollback on Failure
        if: failure() && steps.deploy.outcome == 'failure'
        run: |
          echo "❌ Deployment failed, initiating rollback..."
          
          # Trigger rollback workflow
          gh workflow run rollback-infrastructure.yml \
            -f environment=${{ matrix.environment }} \
            -f deployment_id=${{ env.DEPLOYMENT_ID }}
      
      - name: Update Deployment Status
        if: always()
        uses: actions/github-script@v7
        with:
          script: |
            const status = '${{ job.status }}' === 'success' ? 'success' : 'failure';
            
            await github.rest.repos.createDeploymentStatus({
              owner: context.repo.owner,
              repo: context.repo.repo,
              deployment_id: context.payload.deployment.id,
              state: status,
              environment_url: '${{ steps.deploy.outputs.app_url }}',
              description: `Deployment ${status} for ${{ matrix.environment }}`
            });

  promote-to-staging:
    needs: deploy
    if: success() && contains(needs.prepare.outputs.environments, 'dev')
    runs-on: ubuntu-latest
    steps:
      - name: Create staging promotion PR
        uses: actions/github-script@v7
        with:
          script: |
            const { data: pr } = await github.rest.pulls.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: '🚀 Promote to Staging',
              body: `## Promotion Request
              
              Promoting successful dev deployment to staging.
              
              **Deployment ID**: ${{ env.DEPLOYMENT_ID }}
              **Commit**: ${{ github.sha }}
              
              ### Checklist
              - [ ] Dev smoke tests passed
              - [ ] No critical issues in dev
              - [ ] Staging environment ready
              
              /deploy staging`,
              head: context.ref,
              base: 'staging-promote'
            });
            
            console.log(`Created PR #${pr.number}`);
```

### Step 5: Create Drift Detection Workflow

Implement continuous drift detection:

**💡 Copilot Prompt Suggestion:**
```yaml
# Create a scheduled workflow that:
# - Runs every hour
# - Checks for drift in all environments
# - Creates issues for detected drift
# - Optionally auto-remediates minor drift
# - Sends alerts to teams channel
# Path: .github/workflows/drift-detection.yml
```

**Expected Copilot Output:**
```yaml
# .github/workflows/drift-detection.yml
name: Infrastructure Drift Detection

on:
  schedule:
    - cron: '0 * * * *'  # Every hour
  workflow_dispatch:
    inputs:
      environment:
        description: 'Specific environment to check'
        required: false
        type: choice
        options:
          - all
          - dev
          - staging
          - prod

jobs:
  detect-drift:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: ${{ fromJson(github.event_name == 'workflow_dispatch' && github.event.inputs.environment != 'all' ? format('["{0}"]', github.event.inputs.environment) : '["dev", "staging", "prod"]') }}
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: '1.6.0'
      
      - name: Check for Drift
        id: drift-check
        working-directory: infrastructure/environments/${{ matrix.environment }}
        run: |
          # Initialize Terraform
          terraform init \
            -backend-config="resource_group_name=${{ secrets.TF_STATE_RG }}" \
            -backend-config="storage_account_name=${{ secrets.TF_STATE_SA }}" \
            -backend-config="container_name=tfstate" \
            -backend-config="key=${{ matrix.environment }}/terraform.tfstate"
          
          # Create detailed plan
          terraform plan -detailed-exitcode -out=tfplan > plan_output.txt 2>&1 || EXIT_CODE=$?
          
          if [ "${EXIT_CODE}" == "2" ]; then
            echo "drift_detected=true" >> $GITHUB_OUTPUT
            echo "❌ Drift detected in ${{ matrix.environment }} environment"
            
            # Generate drift report
            terraform show -no-color tfplan > drift_report.txt
            
            # Extract drift summary
            RESOURCES_TO_ADD=$(grep -c "will be created" drift_report.txt || true)
            RESOURCES_TO_CHANGE=$(grep -c "will be updated" drift_report.txt || true)
            RESOURCES_TO_DELETE=$(grep -c "will be destroyed" drift_report.txt || true)
            
            echo "drift_summary=Add: $RESOURCES_TO_ADD, Change: $RESOURCES_TO_CHANGE, Delete: $RESOURCES_TO_DELETE" >> $GITHUB_OUTPUT
          else
            echo "drift_detected=false" >> $GITHUB_OUTPUT
            echo "✅ No drift detected in ${{ matrix.environment }} environment"
          fi
      
      - name: Create Drift Issue
        if: steps.drift-check.outputs.drift_detected == 'true'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const driftReport = fs.readFileSync('infrastructure/environments/${{ matrix.environment }}/drift_report.txt', 'utf8');
            
            // Check if issue already exists
            const { data: issues } = await github.rest.issues.listForRepo({
              owner: context.repo.owner,
              repo: context.repo.repo,
              labels: ['drift', '${{ matrix.environment }}'],
              state: 'open'
            });
            
            const issueBody = `## 🚨 Infrastructure Drift Detected
            
            **Environment**: ${{ matrix.environment }}
            **Detection Time**: ${new Date().toISOString()}
            **Summary**: ${{ steps.drift-check.outputs.drift_summary }}
            
            ### Drift Details
            
            <details>
            <summary>Click to expand full drift report</summary>
            
            \`\`\`
            ${driftReport.substring(0, 60000)}  // GitHub issue body limit
            \`\`\`
            
            </details>
            
            ### Actions Required
            
            1. Review the drift report
            2. Determine if changes were authorized
            3. Either:
               - Apply the changes through GitOps
               - Revert unauthorized changes
               - Update Terraform state if changes are acceptable
            
            ### Auto-Remediation
            
            To auto-remediate this drift, comment:
            - \`/remediate\` - Apply Terraform to fix drift
            - \`/ignore\` - Close issue without action
            `;
            
            if (issues.length === 0) {
              await github.rest.issues.create({
                owner: context.repo.owner,
                repo: context.repo.repo,
                title: `[Drift] Infrastructure drift in ${{ matrix.environment }}`,
                body: issueBody,
                labels: ['drift', '${{ matrix.environment }}', 'infrastructure']
              });
            } else {
              // Update existing issue
              await github.rest.issues.update({
                owner: context.repo.owner,
                repo: context.repo.repo,
                issue_number: issues[0].number,
                body: issueBody
              });
            }
      
      - name: Send Alert
        if: steps.drift-check.outputs.drift_detected == 'true'
        run: |
          # Send to Teams/Slack webhook
          curl -X POST ${{ secrets.TEAMS_WEBHOOK }} \
            -H "Content-Type: application/json" \
            -d '{
              "title": "Infrastructure Drift Detected",
              "text": "Drift detected in ${{ matrix.environment }} environment",
              "sections": [{
                "facts": [
                  {"name": "Environment", "value": "${{ matrix.environment }}"},
                  {"name": "Summary", "value": "${{ steps.drift-check.outputs.drift_summary }}"},
                  {"name": "Action", "value": "[View Details](${{ github.server_url }}/${{ github.repository }}/issues)"}
                ]
              }]
            }'
```

### Step 6: Create Rollback Workflow

Implement automated rollback capability:

**💡 Copilot Prompt Suggestion:**
```yaml
# Create a rollback workflow that:
# - Can be triggered manually or automatically
# - Rolls back to previous known good state
# - Validates rollback success
# - Updates deployment records
# Path: .github/workflows/rollback-infrastructure.yml
```

**Expected Copilot Output:**
```yaml
# .github/workflows/rollback-infrastructure.yml
name: Rollback Infrastructure

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to rollback'
        required: true
        type: choice
        options:
          - dev
          - staging
          - prod
      deployment_id:
        description: 'Deployment ID to rollback to (optional)'
        required: false
      reason:
        description: 'Reason for rollback'
        required: true

jobs:
  rollback:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment }}-rollback
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: '1.6.0'
      
      - name: Determine Rollback Target
        id: target
        run: |
          if [ -n "${{ github.event.inputs.deployment_id }}" ]; then
            echo "deployment_id=${{ github.event.inputs.deployment_id }}" >> $GITHUB_OUTPUT
          else
            # Find last successful deployment
            LAST_DEPLOYMENT=$(cat infrastructure/environments/${{ github.event.inputs.environment }}/.last_successful_deployment || echo "")
            if [ -z "$LAST_DEPLOYMENT" ]; then
              echo "❌ No previous successful deployment found"
              exit 1
            fi
            echo "deployment_id=$LAST_DEPLOYMENT" >> $GITHUB_OUTPUT
          fi
      
      - name: Restore Previous State
        run: |
          # Create backup of current state
          BACKUP_ID="backup-$(date +%Y%m%d%H%M%S)"
          mkdir -p artifacts/backups/$BACKUP_ID
          cp -r infrastructure/environments/${{ github.event.inputs.environment }}/* artifacts/backups/$BACKUP_ID/
          
          # Restore from deployment artifact
          if [ -d "artifacts/deployments/${{ steps.target.outputs.deployment_id }}" ]; then
            cp -r artifacts/deployments/${{ steps.target.outputs.deployment_id }}/* infrastructure/environments/${{ github.event.inputs.environment }}/
          else
            echo "❌ Deployment artifact not found, using git history"
            git checkout ${{ steps.target.outputs.deployment_id }} -- infrastructure/environments/${{ github.event.inputs.environment }}/
          fi
      
      - name: Execute Rollback
        working-directory: infrastructure/environments/${{ github.event.inputs.environment }}
        run: |
          # Initialize Terraform
          terraform init \
            -backend-config="resource_group_name=${{ secrets.TF_STATE_RG }}" \
            -backend-config="storage_account_name=${{ secrets.TF_STATE_SA }}" \
            -backend-config="container_name=tfstate" \
            -backend-config="key=${{ github.event.inputs.environment }}/terraform.tfstate"
          
          # Apply rollback
          terraform apply -auto-approve -input=false
      
      - name: Validate Rollback
        run: |
          # Run smoke tests
          ./scripts/smoke-tests.sh ${{ github.event.inputs.environment }}
      
      - name: Update Records
        uses: actions/github-script@v7
        with:
          script: |
            // Create rollback record
            await github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: `[Rollback] ${{ github.event.inputs.environment }} rolled back`,
              body: `## Rollback Executed
              
              **Environment**: ${{ github.event.inputs.environment }}
              **Rolled back to**: ${{ steps.target.outputs.deployment_id }}
              **Reason**: ${{ github.event.inputs.reason }}
              **Executed by**: @${{ github.actor }}
              **Time**: ${new Date().toISOString()}
              
              ### Next Steps
              1. Investigate the issue that caused the rollback
              2. Fix the problem in a new PR
              3. Re-deploy through normal GitOps flow
              `,
              labels: ['rollback', '${{ github.event.inputs.environment }}']
            });
```

## 📝 Part 4: Integration and Testing

### Step 7: Create Integration Tests

Build comprehensive tests for the GitOps pipeline:

**💡 Copilot Prompt Suggestion:**
```python
# Create a test suite that:
# - Validates all GitHub Actions workflows
# - Tests policy enforcement
# - Simulates deployment scenarios
# - Validates rollback procedures
# - Checks monitoring and alerting
# Path: tests/integration/test_gitops_pipeline.py
```

**Expected Copilot Output:**
```python
#!/usr/bin/env python3
# tests/integration/test_gitops_pipeline.py

import os
import yaml
import json
import subprocess
import pytest
from pathlib import Path
import tempfile
import shutil

class TestGitOpsPipeline:
    """Integration tests for GitOps pipeline"""
    
    @pytest.fixture
    def temp_repo(self):
        """Create a temporary repository for testing"""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Copy repository structure
            repo_root = Path(__file__).parent.parent.parent
            shutil.copytree(repo_root, tmpdir, dirs_exist_ok=True)
            yield tmpdir
    
    def test_workflow_syntax(self):
        """Validate all workflow files have correct syntax"""
        workflows_dir = Path(".github/workflows")
        
        for workflow_file in workflows_dir.glob("*.yml"):
            with open(workflow_file, 'r') as f:
                try:
                    yaml.safe_load(f)
                    print(f"✅ {workflow_file.name} - Valid YAML")
                except yaml.YAMLError as e:
                    pytest.fail(f"Invalid YAML in {workflow_file.name}: {e}")
    
    def test_terraform_modules(self):
        """Validate all Terraform modules"""
        modules_dir = Path("infrastructure/modules")
        
        for module_dir in modules_dir.iterdir():
            if module_dir.is_dir():
                # Check for required files
                assert (module_dir / "main.tf").exists(), f"Missing main.tf in {module_dir.name}"
                assert (module_dir / "variables.tf").exists() or \
                       any(module_dir.glob("*.tf")), f"Missing variables in {module_dir.name}"
                
                # Validate Terraform syntax
                result = subprocess.run(
                    ["terraform", "fmt", "-check"],
                    cwd=module_dir,
                    capture_output=True
                )
                assert result.returncode == 0, f"Terraform format issues in {module_dir.name}"
    
    def test_policy_validation(self):
        """Test OPA policies with sample plans"""
        policies_dir = Path("policies/azure")
        test_plans_dir = Path("tests/fixtures/terraform_plans")
        
        for policy_file in policies_dir.glob("*.rego"):
            # Test with valid plan
            valid_plan = test_plans_dir / "valid_plan.json"
            result = subprocess.run(
                ["opa", "eval", "-d", str(policy_file), "-i", str(valid_plan),
                 "data.azure.resources.deny[x]"],
                capture_output=True,
                text=True
            )
            
            # Valid plan should have no denials
            assert "[]" in result.stdout, f"Policy {policy_file.name} incorrectly denied valid plan"
            
            # Test with invalid plan
            invalid_plan = test_plans_dir / "invalid_plan.json"
            result = subprocess.run(
                ["opa", "eval", "-d", str(policy_file), "-i", str(invalid_plan),
                 "data.azure.resources.deny[x]"],
                capture_output=True,
                text=True
            )
            
            # Invalid plan should have denials
            assert "[]" not in result.stdout, f"Policy {policy_file.name} failed to catch violations"
    
    def test_deployment_scripts(self):
        """Test deployment automation scripts"""
        scripts_dir = Path("scripts/deployment")
        
        for script in scripts_dir.glob("*.sh"):
            # Check script has executable permissions
            assert os.access(script, os.X_OK), f"{script.name} is not executable"
            
            # Validate bash syntax
            result = subprocess.run(
                ["bash", "-n", str(script)],
                capture_output=True
            )
            assert result.returncode == 0, f"Syntax error in {script.name}"
    
    @pytest.mark.integration
    def test_end_to_end_deployment(self, temp_repo):
        """Simulate end-to-end deployment flow"""
        os.chdir(temp_repo)
        
        # Create a feature branch
        subprocess.run(["git", "checkout", "-b", "test-deployment"], check=True)
        
        # Modify infrastructure
        test_tf_content = '''
        resource "azurerm_resource_group" "test" {
          name     = "rg-test-gitops"
          location = "eastus2"
          tags = {
            Environment = "test"
            ManagedBy   = "Terraform"
            CostCenter  = "Testing"
            Owner       = "DevOps"
            Module      = "Module-13"
          }
        }
        '''
        
        with open("infrastructure/environments/dev/test.tf", "w") as f:
            f.write(test_tf_content)
        
        # Commit changes
        subprocess.run(["git", "add", "."], check=True)
        subprocess.run(["git", "commit", "-m", "test: Add test resource"], check=True)
        
        # Validate the change would pass checks
        # This simulates what would happen in CI
        
        # 1. Terraform format
        result = subprocess.run(
            ["terraform", "fmt", "-check"],
            cwd="infrastructure/environments/dev",
            capture_output=True
        )
        assert result.returncode == 0, "Terraform format check failed"
        
        # 2. Terraform validate
        subprocess.run(
            ["terraform", "init", "-backend=false"],
            cwd="infrastructure/environments/dev",
            check=True
        )
        result = subprocess.run(
            ["terraform", "validate"],
            cwd="infrastructure/environments/dev",
            capture_output=True
        )
        assert result.returncode == 0, "Terraform validation failed"
        
        print("✅ End-to-end deployment test passed")
    
    def test_rollback_capability(self):
        """Test rollback procedures work correctly"""
        # Create a mock deployment history
        deployments_dir = Path("artifacts/deployments")
        deployments_dir.mkdir(parents=True, exist_ok=True)
        
        # Create fake deployment
        deployment_id = "20240115120000-abc1234"
        deployment_dir = deployments_dir / deployment_id
        deployment_dir.mkdir(parents=True, exist_ok=True)
        
        # Save deployment marker
        with open("infrastructure/environments/dev/.last_successful_deployment", "w") as f:
            f.write(deployment_id)
        
        # Verify rollback target can be determined
        with open("infrastructure/environments/dev/.last_successful_deployment", "r") as f:
            last_deployment = f.read().strip()
        
        assert last_deployment == deployment_id, "Failed to track deployment"
        assert deployment_dir.exists(), "Deployment artifact not created"
        
        print("✅ Rollback capability test passed")

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
```

## 🧪 Validation and Testing

### Step 8: Run Complete Pipeline Test

Test the entire GitOps pipeline:

```bash
# 1. Initialize the repository
./setup-gitops-repo.sh

# 2. Configure GitHub secrets
gh secret set AZURE_CREDENTIALS < azure-creds.json
gh secret set TF_STATE_RG --body "rg-terraform-state"
gh secret set TF_STATE_SA --body "tfstate12345"
gh secret set INFRACOST_API_KEY --body "your-api-key"
gh secret set TEAMS_WEBHOOK --body "your-webhook-url"

# 3. Create and push a test branch
git checkout -b test/gitops-pipeline
git add .
git commit -m "feat: Complete GitOps pipeline"
git push origin test/gitops-pipeline

# 4. Create PR and observe checks
gh pr create --title "Implement GitOps Pipeline" \
  --body "Testing complete GitOps implementation" \
  --base main

# 5. Monitor the PR checks
gh pr checks --watch
```

### Step 9: Set Up Monitoring Dashboard

Create a monitoring dashboard for the GitOps pipeline:

**💡 Copilot Prompt Suggestion:**
```python
# Create a script that:
# - Generates a dashboard for GitOps metrics
# - Shows deployment frequency
# - Tracks failure rates
# - Monitors drift detection results
# - Displays cost trends
# Path: scripts/create-gitops-dashboard.py
```

**Expected Monitoring Script:**
```python
#!/usr/bin/env python3
# scripts/create-gitops-dashboard.py

import json
from datetime import datetime, timedelta
from azure.monitor.query import LogsQueryClient
from azure.identity import DefaultAzureCredential
from azure.mgmt.dashboard import DashboardManagementClient

def create_gitops_dashboard(subscription_id, resource_group, workspace_id):
    """Create a comprehensive GitOps monitoring dashboard"""
    
    credential = DefaultAzureCredential()
    
    dashboard_config = {
        "lenses": {
            "0": {
                "order": 0,
                "parts": {
                    # Deployment frequency
                    "0": {
                        "position": {"x": 0, "y": 0, "colSpan": 6, "rowSpan": 4},
                        "metadata": {
                            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
                            "settings": {
                                "title": "Deployment Frequency",
                                "queryText": """
                                GitHubActions_CL
                                | where action_s == "deployment_complete"
                                | summarize Count=count() by bin(TimeGenerated, 1d), environment_s
                                | render timechart
                                """
                            }
                        }
                    },
                    # Success rate
                    "1": {
                        "position": {"x": 6, "y": 0, "colSpan": 6, "rowSpan": 4},
                        "metadata": {
                            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
                            "settings": {
                                "title": "Deployment Success Rate",
                                "queryText": """
                                GitHubActions_CL
                                | where action_s == "deployment_complete"
                                | summarize 
                                    Success=countif(status_s=="success"),
                                    Failed=countif(status_s=="failed")
                                  by environment_s
                                | extend SuccessRate = Success * 100.0 / (Success + Failed)
                                | render barchart
                                """
                            }
                        }
                    },
                    # Drift detection
                    "2": {
                        "position": {"x": 0, "y": 4, "colSpan": 6, "rowSpan": 4},
                        "metadata": {
                            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
                            "settings": {
                                "title": "Infrastructure Drift",
                                "queryText": """
                                DriftDetection_CL
                                | where drift_detected_b == true
                                | summarize Count=count() by bin(TimeGenerated, 1h), environment_s
                                | render timechart
                                """
                            }
                        }
                    },
                    # Cost trends
                    "3": {
                        "position": {"x": 6, "y": 4, "colSpan": 6, "rowSpan": 4},
                        "metadata": {
                            "type": "Extension/HubsExtension/PartType/MonitorChartPart",
                            "settings": {
                                "title": "Infrastructure Costs",
                                "queryText": """
                                CostEstimates_CL
                                | summarize 
                                    EstimatedCost=avg(estimated_cost_d)
                                  by bin(TimeGenerated, 1d), environment_s
                                | render linechart
                                """
                            }
                        }
                    }
                }
            }
        }
    }
    
    # Create dashboard
    dashboard_client = DashboardManagementClient(credential, subscription_id)
    
    dashboard = dashboard_client.dashboards.create_or_update(
        resource_group_name=resource_group,
        dashboard_name="gitops-monitoring",
        dashboard={
            "location": "global",
            "properties": dashboard_config,
            "tags": {
                "Purpose": "GitOps Monitoring",
                "Module": "Module-13"
            }
        }
    )
    
    print(f"✅ Dashboard created: {dashboard.id}")
    return dashboard

if __name__ == "__main__":
    # Configuration
    SUBSCRIPTION_ID = os.environ.get("AZURE_SUBSCRIPTION_ID")
    RESOURCE_GROUP = "rg-monitoring"
    WORKSPACE_ID = os.environ.get("LOG_ANALYTICS_WORKSPACE_ID")
    
    create_gitops_dashboard(SUBSCRIPTION_ID, RESOURCE_GROUP, WORKSPACE_ID)
```

## 🎯 Exercise Completion

Congratulations! You've successfully implemented:
- ✅ Complete GitOps repository structure
- ✅ Automated validation and security scanning
- ✅ Multi-environment deployment pipeline
- ✅ Drift detection and alerting
- ✅ Automated rollback capabilities
- ✅ Comprehensive monitoring

## 🔍 Key Takeaways

1. **GitOps Principles**: Everything through Git, nothing manual
2. **Policy as Code**: Enforce standards automatically
3. **Security First**: Scan and validate before deployment
4. **Observability**: Monitor everything continuously
5. **Automation**: Reduce human error through automation

## 🚀 Production Readiness Checklist

- [ ] All workflows tested and validated
- [ ] Security scanning configured
- [ ] Cost controls implemented
- [ ] Monitoring dashboards created
- [ ] Rollback procedures tested
- [ ] Documentation complete
- [ ] Team trained on procedures

## 📚 Additional Resources

- [GitOps Principles](https://www.gitops.tech/)
- [GitHub Actions Best Practices](https://docs.github.com/en/actions/guides)
- [OPA Documentation](https://www.openpolicyagent.org/docs/latest/)
- [Azure Monitor Documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/)

## 🎉 Module Completion

You've mastered Infrastructure as Code with GitOps! This advanced knowledge prepares you for:
- Managing enterprise-scale infrastructure
- Implementing compliance automation
- Building self-healing systems
- Leading DevOps transformations

**Next Module**: [Module 14: CI/CD with GitHub Actions](../../module-14-cicd-github-actions/)

---

*Remember: The best infrastructure is invisible, automated, and self-healing. You've just built the foundation for that!*