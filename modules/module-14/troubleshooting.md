# Module 14: CI/CD Troubleshooting Guide

## 🔧 Common Issues and Solutions

### 🚫 Workflow Not Triggering

#### Symptom
Push to repository but workflow doesn't start.

#### Possible Causes & Solutions

1. **Branch Protection Rules**
   ```bash
   # Check branch protection
   gh api repos/:owner/:repo/branches/main/protection
   ```
   Solution: Ensure Actions are not restricted in branch protection.

2. **Workflow File Location**
   ```
   ✗ .github/workflow/ci.yml     # Wrong
   ✓ .github/workflows/ci.yml    # Correct
   ```

3. **YAML Syntax Error**
   ```bash
   # Validate YAML locally
   yamllint .github/workflows/*.yml
   
   # Or use actionlint
   actionlint .github/workflows/*.yml
   ```

4. **Workflow Disabled**
   Check: Settings → Actions → General → Actions permissions

### 🔑 Authentication Failures

#### Azure Login Failed
```
Error: Login failed with Error: The client '***' with object id '***' does not have authorization
```

**Solution:**
```bash
# Recreate service principal
az ad sp create-for-rbac --name "github-actions" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --json-auth > azure-creds.json

# Update secret
gh secret set AZURE_CREDENTIALS < azure-creds.json
```

#### GitHub Token Permissions
```
Error: Resource not accessible by integration
```

**Solution:**
```yaml
permissions:
  contents: read
  issues: write
  pull-requests: write
  actions: read
  checks: write
```

### 🐳 Docker Build Issues

#### Out of Space
```
Error: no space left on device
```

**Solution:**
```yaml
- name: Free disk space
  run: |
    sudo rm -rf /usr/share/dotnet
    sudo rm -rf /opt/ghc
    sudo rm -rf "/usr/local/share/boost"
    sudo rm -rf "$AGENT_TOOLSDIRECTORY"
    
- name: Check space
  run: df -h
```

#### Build Cache Issues
```yaml
- name: Clear Docker cache
  run: |
    docker system prune -af
    docker builder prune -af
```

### 📦 Artifact Problems

#### Upload Fails
```
Error: Artifact upload failed with error: ENOENT
```

**Solution:**
```yaml
- name: Create artifact directory
  run: mkdir -p artifacts

- name: Check files exist
  run: |
    ls -la artifacts/
    find . -name "*.log" -type f

- name: Upload with error handling
  uses: actions/upload-artifact@v3
  if: always()  # Upload even on failure
  continue-on-error: true
  with:
    name: logs
    path: |
      artifacts/
      **/*.log
    if-no-files-found: warn  # Don't fail if no files
```

### 🧪 Test Failures

#### Flaky Tests
```yaml
- name: Run tests with retry
  uses: nick-fields/retry@v2
  with:
    timeout_minutes: 10
    max_attempts: 3
    command: pytest tests/ -v
    retry_wait_seconds: 30
    retry_on: error
```

#### Test Timeout
```yaml
- name: Run tests with timeout
  timeout-minutes: 30  # Job level timeout
  run: |
    # Test level timeout
    pytest tests/ --timeout=300 --timeout-method=thread
```

### 🚀 Deployment Issues

#### App Service Deployment Fails
```
Error: Deployment Failed with Error: Package deployment using ZIP Deploy failed
```

**Solutions:**
1. **Check package size**
   ```bash
   # Limit must be < 2GB
   du -sh deploy.zip
   ```

2. **Verify startup command**
   ```yaml
   - name: Deploy with explicit startup
     uses: azure/webapps-deploy@v2
     with:
       startup-command: 'gunicorn --bind=0.0.0.0 --timeout 600 app:app'
   ```

3. **Check logs**
   ```bash
   az webapp log tail --name <app-name> --resource-group <rg-name>
   ```

#### Health Check Failures
```yaml
- name: Debug health check
  run: |
    # Verbose curl
    curl -v $APP_URL/health
    
    # Check DNS
    nslookup $(echo $APP_URL | sed 's|https://||' | sed 's|/.*||')
    
    # Test with retry
    for i in {1..10}; do
      if curl -f $APP_URL/health; then
        echo "Health check passed on attempt $i"
        exit 0
      fi
      echo "Attempt $i failed, waiting..."
      sleep 30
    done
```

### 💰 Cost Issues

#### High Actions Usage
```yaml
# Monitor usage
- name: Check rate limit
  run: |
    gh api rate_limit | jq '.resources.actions'
```

**Solutions:**
1. Use concurrency limits
   ```yaml
   concurrency:
     group: ${{ github.workflow }}-${{ github.ref }}
     cancel-in-progress: true
   ```

2. Optimize runner usage
   ```yaml
   timeout-minutes: 30  # Prevent hung jobs
   ```

### 🔍 Debugging Workflows

#### Enable Debug Logging
1. Set repository secret: `ACTIONS_RUNNER_DEBUG: true`
2. Set repository secret: `ACTIONS_STEP_DEBUG: true`

#### Interactive Debugging
```yaml
- name: Debug with tmate
  if: ${{ failure() && github.event_name == 'workflow_dispatch' }}
  uses: mxschmitt/action-tmate@v3
  with:
    limit-access-to-actor: true
```

#### Workflow Logs
```bash
# Download logs via CLI
gh run view <run-id> --log

# Get specific job logs
gh run view <run-id> --log | grep -A10 -B10 "error"
```

### 🔄 Caching Problems

#### Cache Not Working
```yaml
- name: Debug cache
  run: |
    echo "Cache key: ${{ runner.os }}-deps-${{ hashFiles('**/requirements.txt') }}"
    echo "Files being hashed:"
    find . -name "requirements*.txt" -type f -exec ls -la {} \;
```

#### Cache Restoration Fails
```yaml
- name: Cache with fallback
  uses: actions/cache@v3
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
    restore-keys: |
      ${{ runner.os }}-pip-
      ${{ runner.os }}-
```

### 🌐 Network Issues

#### API Rate Limits
```yaml
- name: Handle rate limits
  run: |
    while true; do
      response=$(curl -s -w "\n%{http_code}" $API_URL)
      http_code=$(echo "$response" | tail -n1)
      
      if [ "$http_code" = "429" ]; then
        echo "Rate limited, waiting..."
        sleep 60
      else
        break
      fi
    done
```

#### Proxy Configuration
```yaml
env:
  HTTP_PROXY: ${{ secrets.HTTP_PROXY }}
  HTTPS_PROXY: ${{ secrets.HTTPS_PROXY }}
  NO_PROXY: localhost,127.0.0.1
```

### 🔐 Security Scanning Issues

#### Trivy Failures
```yaml
- name: Run Trivy with error handling
  run: |
    # Download Trivy if scan fails
    if ! command -v trivy &> /dev/null; then
      wget -qO- https://github.com/aquasecurity/trivy/releases/latest/download/trivy_Linux-64bit.tar.gz | tar xz
      sudo mv trivy /usr/local/bin/
    fi
    
    # Scan with retry
    trivy image --timeout 10m --exit-code 0 myimage:latest || true
```

### 📊 Monitoring Integration

#### Metrics Not Sending
```yaml
- name: Debug metrics endpoint
  run: |
    # Test connectivity
    curl -v ${{ secrets.METRICS_ENDPOINT }}/health
    
    # Send test metric
    curl -X POST ${{ secrets.METRICS_ENDPOINT }}/metrics \
      -H "Authorization: Bearer ${{ secrets.METRICS_TOKEN }}" \
      -H "Content-Type: application/json" \
      -d '{"test": "metric"}' \
      -w "\nHTTP Status: %{http_code}\n"
```

## 🆘 Emergency Procedures

### Stuck Workflow
```bash
# Cancel stuck workflow
gh run cancel <run-id>

# Cancel all runs for a workflow
gh run list --workflow=ci.yml --json databaseId -q '.[].databaseId' | \
  xargs -I {} gh run cancel {}
```

### Rollback Failed Deployment
```bash
# Immediate rollback
az webapp deployment slot swap \
  --resource-group <rg> \
  --name <app-name> \
  --slot production \
  --target-slot last-known-good
```

## 📋 Diagnostic Commands

### Check Workflow Status
```bash
# List recent runs
gh run list --limit 10

# View specific run
gh run view <run-id>

# Watch run in real-time
gh run watch <run-id>
```

### Validate Configuration
```bash
# Check secrets
gh secret list

# Verify environment
gh api repos/:owner/:repo/environments

# Check webhook deliveries
gh api repos/:owner/:repo/hooks
```

## 🔗 Useful Resources

- [GitHub Actions Status Page](https://www.githubstatus.com/)
- [Actions Debug Logging](https://docs.github.com/actions/monitoring-and-troubleshooting-workflows/enabling-debug-logging)
- [Azure Service Health](https://status.azure.com/)
- [Community Forum](https://github.community/c/actions/)

---

Remember: Most CI/CD issues are configuration-related. Always check logs, validate syntax, and ensure proper permissions before diving deep into debugging.