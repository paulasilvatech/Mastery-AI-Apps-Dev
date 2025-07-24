---
sidebar_position: 6
title: "Exercise 2: Part 2"
description: "## 📝 Part 2: Application Deployment and Testing"
---

# Ejercicio 2: Multi-ambiente despliegue (Partee 2)

## 📝 Partee 2: Application despliegue and Testing

### Step 4: Continuar the despliegue Workflow

Let's add the application despliegue job to our workflow:

**.github/workflows/deploy.yml (continued):**

```yaml
  deploy-application:
    name: Deploy Application - ${{ needs.prepare-deployment.outputs.environment }}
    runs-on: ubuntu-latest
    needs: [prepare-deployment, deploy-infrastructure]
    environment: 
      name: ${{ needs.prepare-deployment.outputs.environment }}
      url: ${{ needs.deploy-infrastructure.outputs.appServiceUrl }}
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}
    
    - name: Create deployment package
      run: |
        python -m venv antenv
        source antenv/bin/activate
        pip install -r requirements.txt
        
        # Create startup script
        cat &gt; startup.sh &lt;&lt; 'EOF'
        #!/bin/bash
        gunicorn --bind=0.0.0.0:8000 --workers=4 --timeout=600 src.app:app
        EOF
        chmod +x startup.sh
        
        # Package application
        zip -r deploy.zip . -x "*.git*" -x "tests/*" -x "*.md" -x ".github/*"
    
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Deploy to Azure App Service
      if: needs.prepare-deployment.outputs.environment != 'prod'
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ needs.deploy-infrastructure.outputs.appServiceName }}
        package: deploy.zip
        startup-command: 'startup.sh'
    
    - name: Deploy to Staging Slot (Production)
      if: needs.prepare-deployment.outputs.environment == 'prod'
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ needs.deploy-infrastructure.outputs.appServiceName }}
        slot-name: staging
        package: deploy.zip
        startup-command: 'startup.sh'
    
    - name: Set application settings
      run: |
        az webapp config appsettings set \
          --resource-group "rg-workshop-${{ needs.prepare-deployment.outputs.environment }}" \
          --name ${{ needs.deploy-infrastructure.outputs.appServiceName }} \
          --settings \
            VERSION="${{ needs.prepare-deployment.outputs.version }}" \
            ENVIRONMENT="${{ needs.prepare-deployment.outputs.environment }}" \
            BUILD_NUMBER="${{ github.run_number }}" \
            COMMIT_SHA="${{ github.sha }}"
    
    - name: Warm up application
      run: |
        echo "Warming up application..."
        for i in {\`1..5\`}; do
          curl -s -o /dev/null -w "%{http_code}" ${{ needs.deploy-infrastructure.outputs.appServiceUrl }}/health || true
          sleep 5
        done

  smoke-tests:
    name: Smoke Tests - ${{ needs.prepare-deployment.outputs.environment }}
    runs-on: ubuntu-latest
    needs: [prepare-deployment, deploy-infrastructure, deploy-application]
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}
    
    - name: Install test dependencies
      run: |
        pip install requests pytest
    
    - name: Run smoke tests
      env:
        APP_URL: ${{ needs.deploy-infrastructure.outputs.appServiceUrl }}
      run: |
        # Create smoke test script
        cat &gt; test_smoke.py &lt;&lt; 'EOF'
        import requests
        import pytest
        import os
        import time

        APP_URL = os.environ.get('APP_URL', 'http://localhost:5000')

        def test_health_endpoint():
            """Test that health endpoint returns 200."""
            response = requests.get(f"{APP_URL}/health", timeout=30)
            assert response.status_code == 200
            data = response.json()
            assert data['status'] == 'healthy'

        def test_main_page():
            """Test that main page is accessible."""
            response = requests.get(APP_URL, timeout=30)
            assert response.status_code == 200
            assert 'Welcome to CI/CD Workshop!' in response.text

        def test_api_endpoint():
            """Test that API endpoint returns expected data."""
            response = requests.get(f"{APP_URL}/api/data", timeout=30)
            assert response.status_code == 200
            data = response.json()
            assert 'message' in data
            assert 'version' in data

        def test_404_handling():
            """Test that 404 errors are handled properly."""
            response = requests.get(f"{APP_URL}/nonexistent", timeout=30)
            assert response.status_code == 404

        def test_response_time():
            """Test that response time is acceptable."""
            start_time = time.time()
            response = requests.get(f"{APP_URL}/health", timeout=30)
            end_time = time.time()
            response_time = end_time - start_time
            assert response_time &lt; 2.0, f"Response time {response_time}s exceeds 2s threshold"
        EOF
        
        # Run smoke tests
        pytest test_smoke.py -v --tb=short
    
    - name: Update test summary
      if: always()
      run: |
        echo "## Smoke Test Results 🔥" &gt;&gt; $GITHUB_STEP_SUMMARY
        echo "- **Environment:** ${{ needs.prepare-deployment.outputs.environment }}" &gt;&gt; $GITHUB_STEP_SUMMARY
        echo "- **URL:** ${{ needs.deploy-infrastructure.outputs.appServiceUrl }}" &gt;&gt; $GITHUB_STEP_SUMMARY
        echo "- **Status:** ${{ job.status }}" &gt;&gt; $GITHUB_STEP_SUMMARY

  blue-green-swap:
    name: Blue-Green Deployment Swap
    runs-on: ubuntu-latest
    needs: [prepare-deployment, deploy-infrastructure, deploy-application, smoke-tests]
    if: needs.prepare-deployment.outputs.environment == 'prod'
    environment:
      name: production-swap
    
    steps:
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Swap deployment slots
      run: |
        echo "Swapping staging slot to production..."
        az webapp deployment slot swap \
          --resource-group "rg-workshop-prod" \
          --name ${{ needs.deploy-infrastructure.outputs.appServiceName }} \
          --slot staging \
          --target-slot production
    
    - name: Verify production deployment
      run: |
        sleep 30  # Wait for swap to complete
        response=$(curl -s -o /dev/null -w "%{http_code}" ${{ needs.deploy-infrastructure.outputs.appServiceUrl }}/health)
        if [[ $response -ne 200 ]]; then
          echo "❌ Production health check failed!"
          exit 1
        else
          echo "✅ Production deployment successful!"
        fi
    
    - name: Update deployment summary
      run: |
        echo "## Production Deployment Complete! 🎉" &gt;&gt; $GITHUB_STEP_SUMMARY
        echo "- **Version:** ${{ needs.prepare-deployment.outputs.version }}" &gt;&gt; $GITHUB_STEP_SUMMARY
        echo "- **Strategy:** Blue-Green Swap" &gt;&gt; $GITHUB_STEP_SUMMARY
        echo "- **URL:** ${{ needs.deploy-infrastructure.outputs.appServiceUrl }}" &gt;&gt; $GITHUB_STEP_SUMMARY
```

### Step 5: Create ambiente Configuration

Create GitHub Environments with protection rules:

**Instructions for GitHub UI:**
1. Go to Configuraciones → Environments
2. Create three ambientes: `dev`, `staging`, `prod`
3. For `staging`:
   - Add required reviewers (1 reviewer)
   - Set despliegue branches to `main`
4. For `prod`:
   - Add required reviewers (2 reviewers)
   - Set wait timer (5 minutos)
   - Add despliegue branches rule: `main`
5. For `producción-swap`:
   - Add required reviewers (1 reviewer)
   - Enable "Prevent self-review"

### Step 6: Add RollAtrás Workflow

Create a rollback mechanism:

**.github/workflows/rollback.yml:**

**Copilot Prompt Suggestion:**
```yaml
# Create a rollback workflow that:
# - Can be manually triggered
# - Lists recent deployments
# - Allows selection of version to rollback to
# - Only works for staging and production
# - Swaps slots back for production
# - Runs health checks after rollback
# - Notifies team of rollback
```

**Expected Output:**
```yaml
name: Rollback Deployment

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to rollback'
        required: true
        type: choice
        options:
          - staging
          - prod
      reason:
        description: 'Reason for rollback'
        required: true
        type: string

jobs:
  rollback:
    name: Rollback ${{ github.event.inputs.environment }}
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment }}-rollback
    
    steps:
    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Get deployment history
      id: history
      run: |
        # Get last 5 deployments
        deployments=$(az webapp deployment list \
          --resource-group "rg-workshop-${{ github.event.inputs.environment }}" \
          --name "workshop-app-${{ github.event.inputs.environment }}" \
          --query "[0:5].{id:id, timestamp:timestamp, author:author}" \
          --output json)
        
        echo "Recent deployments:"
        echo "$deployments" | jq .
    
    - name: Perform rollback
      run: |
        if [[ "${{ github.event.inputs.environment }}" == "prod" ]]; then
          # For production, swap slots back
          echo "Rolling back production by swapping slots..."
          az webapp deployment slot swap \
            --resource-group "rg-workshop-prod" \
            --name "workshop-app-prod" \
            --slot production \
            --target-slot staging
        else
          # For staging, redeploy previous version
          echo "Rolling back to previous deployment..."
          # In real scenario, you would redeploy from previous artifact
        fi
    
    - name: Verify rollback
      run: |
        APP_URL="https://workshop-app-${{ github.event.inputs.environment }}.azurewebsites.net"
        response=$(curl -s -o /dev/null -w "%{http_code}" $APP_URL/health)
        if [[ $response -eq 200 ]]; then
          echo "✅ Rollback successful!"
        else
          echo "❌ Rollback verification failed!"
          exit 1
        fi
    
    - name: Create rollback summary
      run: |
        echo "## Rollback Summary 🔄" &gt;&gt; $GITHUB_STEP_SUMMARY
        echo "- **Environment:** ${{ github.event.inputs.environment }}" &gt;&gt; $GITHUB_STEP_SUMMARY
        echo "- **Reason:** ${{ github.event.inputs.reason }}" &gt;&gt; $GITHUB_STEP_SUMMARY
        echo "- **Initiated by:** ${{ github.actor }}" &gt;&gt; $GITHUB_STEP_SUMMARY
        echo "- **Timestamp:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")" &gt;&gt; $GITHUB_STEP_SUMMARY
```

### Step 7: Add Monitoring and Alerts

Create Application Insights alerts:

**monitoring/alerts.bicep:**
```bicep
param appInsightsId string
param actionGroupId string
param environment string

// Response time alert
resource responseTimeAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'response-time-alert-${environment}'
  location: 'global'
  properties: {
    severity: 2
    enabled: true
    scopes: [appInsightsId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'ResponseTime'
          metricName: 'requests/duration'
          operator: 'GreaterThan'
          threshold: environment == 'prod' ? 1000 : 2000
          timeAggregation: 'Average'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
  }
}

// Failure rate alert
resource failureRateAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'failure-rate-alert-${environment}'
  location: 'global'
  properties: {
    severity: 1
    enabled: true
    scopes: [appInsightsId]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'FailureRate'
          metricName: 'requests/failed'
          operator: 'GreaterThan'
          threshold: 5
          timeAggregation: 'Percentage'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
  }
}
```

## 🧪 Testing Your Multi-ambiente Pipeline

### Step 1: Deploy to desarrollo
```bash
# Push to develop branch
git checkout -b develop
git push origin develop
```

### Step 2: Deploy to Staging
```bash
# Create PR to main
git checkout -b feature/test-deployment
git push origin feature/test-deployment
# Create and merge PR
```

### Step 3: Deploy to producción
- Wait for staging despliegue
- Approve producción despliegue in GitHub
- Monitor blue-green swap

## 🎯 Validation Verificarlist

- [ ] Infrastructure deploys successfully to all ambientes
- [ ] Application deploys with correct configurations
- [ ] Smoke tests pass in all ambientes
- [ ] Blue-green despliegue works for producción
- [ ] Rollback mechanism functions correctly
- [ ] Monitoring alerts are configurado
- [ ] Approval gates work as expected
- [ ] Environment URLs are accessible

## 🚀 Bonus Challenges

1. **Add Database Migrations**: Implement automatic database schema updates
2. **Implement Canary Deployment**: Deploy to percentage of traffic
3. **Add Performance Tests**: Run load tests before producción
4. **Create Deployment Panel**: Build custom dashboard for despliegues
5. **Add ChatOps**: Deploy via Slack commands

## 📊 Key Takeaways

1. **Environment Management**: Separate configurations and secrets
2. **Deployment Strategies**: Blue-green vs canary vs rolling
3. **Protection Rules**: Approval gates and branch restrictions
4. **Rollback Plans**: Always have a way back
5. **Monitoring**: Know when things go wrong
6. **Automation**: Reduce manual intervention

---

**Great job!** 🎉 You've implemented a production-ready multi-environment deployment pipeline. 

**Next Step**: Proceed to Exercise 3 - Enterprise Pipeline with AI