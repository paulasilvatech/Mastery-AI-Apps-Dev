# CI/CD Best Practices with GitHub Actions

## 🏆 Production-Ready Patterns

This guide contains battle-tested patterns and best practices for implementing CI/CD pipelines with GitHub Actions in production environments.

## 📋 Pipeline Design Principles

### 1. Fast Feedback Loops
```yaml
# Run quick checks first, expensive operations later
jobs:
  quick-checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Syntax check
        run: |
          find . -name "*.py" -exec python -m py_compile {} \;
      - name: Quick lint
        run: flake8 --select=E9,F63,F7,F82 --show-source
  
  full-tests:
    needs: quick-checks
    # ... comprehensive tests
```

**Why**: Fail fast on obvious errors before running time-consuming tests.

### 2. Parallelization Strategy
```yaml
strategy:
  matrix:
    test-suite: [unit, integration, e2e]
    include:
      - test-suite: unit
        timeout: 10
      - test-suite: integration
        timeout: 20
      - test-suite: e2e
        timeout: 30
```

**Why**: Reduce total pipeline time by running independent tasks in parallel.

### 3. Intelligent Caching
```yaml
- name: Cache dependencies
  uses: actions/cache@v3
  with:
    path: |
      ~/.cache/pip
      ~/.npm
      ~/.m2
    key: ${{ runner.os }}-deps-${{ hashFiles('**/requirements*.txt', '**/package-lock.json', '**/pom.xml') }}
    restore-keys: |
      ${{ runner.os }}-deps-
```

**Why**: Significantly reduce build times by caching dependencies intelligently.

## 🔒 Security Best Practices

### 1. Least Privilege Principle
```yaml
permissions:
  contents: read        # Default to read-only
  issues: write        # Only if needed
  pull-requests: write # Only if needed
```

### 2. Secret Management
```yaml
# Never hardcode secrets
env:
  API_KEY: ${{ secrets.API_KEY }}

# Use environment-specific secrets
- name: Deploy
  env:
    DEPLOY_KEY: ${{ secrets[format('{0}_DEPLOY_KEY', inputs.environment)] }}
```

### 3. Dependency Scanning
```yaml
- name: Security scan
  uses: github/super-linter@v5
  env:
    VALIDATE_ALL_CODEBASE: false
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

- name: Dependency check
  uses: actions/dependency-review-action@v3
```

## 🚀 Deployment Strategies

### 1. Environment Protection
```yaml
environment:
  name: production
  url: ${{ steps.deploy.outputs.url }}
```

Configure in GitHub:
- Required reviewers
- Wait timers
- Deployment branches
- Environment secrets

### 2. Progressive Deployment
```yaml
deploy:
  strategy:
    type: progressive
    stages:
      - percentage: 10
        duration: 5m
      - percentage: 50
        duration: 10m
      - percentage: 100
```

### 3. Automated Rollback
```yaml
- name: Health check
  id: health
  run: |
    for i in {1..10}; do
      if curl -f ${{ steps.deploy.outputs.url }}/health; then
        echo "success=true" >> $GITHUB_OUTPUT
        exit 0
      fi
      sleep 30
    done
    echo "success=false" >> $GITHUB_OUTPUT

- name: Rollback if unhealthy
  if: steps.health.outputs.success != 'true'
  run: |
    echo "Deployment failed health checks, rolling back..."
    # Rollback logic here
```

## 📊 Monitoring and Observability

### 1. Comprehensive Logging
```yaml
- name: Deploy with logging
  run: |
    set -euo pipefail
    deploy_app 2>&1 | tee deploy.log
    
- name: Upload logs
  if: always()
  uses: actions/upload-artifact@v3
  with:
    name: deployment-logs
    path: |
      *.log
      logs/
```

### 2. Metrics Collection
```yaml
- name: Collect metrics
  run: |
    echo "deploy_duration=$(($SECONDS))" >> $GITHUB_ENV
    echo "deploy_time=$(date -u +%s)" >> $GITHUB_ENV
    
- name: Send metrics
  run: |
    curl -X POST ${{ secrets.METRICS_ENDPOINT }} \
      -H "Authorization: Bearer ${{ secrets.METRICS_TOKEN }}" \
      -d "{
        \"metric\": \"deployment.duration\",
        \"value\": ${{ env.deploy_duration }},
        \"tags\": {
          \"environment\": \"${{ inputs.environment }}\",
          \"version\": \"${{ github.sha }}\"
        }
      }"
```

### 3. Structured Job Summaries
```yaml
- name: Create deployment summary
  run: |
    cat >> $GITHUB_STEP_SUMMARY << EOF
    ## Deployment Summary 🚀
    
    | Metric | Value |
    |--------|-------|
    | Environment | ${{ inputs.environment }} |
    | Version | ${{ github.sha }} |
    | Duration | ${{ env.deploy_duration }}s |
    | Status | ${{ job.status }} |
    
    ### Deployed Services
    - API: ${{ steps.deploy.outputs.api_url }}
    - Frontend: ${{ steps.deploy.outputs.frontend_url }}
    
    ### Next Steps
    - [ ] Verify deployment
    - [ ] Run smoke tests
    - [ ] Monitor metrics
    EOF
```

## 🔄 Reusable Workflows

### 1. Composite Actions
```yaml
# .github/actions/deploy-app/action.yml
name: Deploy Application
description: Reusable deployment action

inputs:
  environment:
    required: true
  version:
    required: true

runs:
  using: composite
  steps:
    - name: Deploy
      shell: bash
      run: |
        ${{ github.action_path }}/deploy.sh \
          --env ${{ inputs.environment }} \
          --version ${{ inputs.version }}
```

### 2. Reusable Workflows
```yaml
# .github/workflows/reusable-deploy.yml
on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
    secrets:
      deploy_key:
        required: true
```

## 💰 Cost Optimization

### 1. Smart Runner Selection
```yaml
runs-on: ${{ matrix.os == 'linux' && 'ubuntu-latest' || matrix.os }}
```

### 2. Conditional Job Execution
```yaml
jobs:
  expensive-tests:
    if: |
      github.event_name == 'push' && 
      github.ref == 'refs/heads/main' ||
      contains(github.event.pull_request.labels.*.name, 'run-all-tests')
```

### 3. Artifact Retention
```yaml
- uses: actions/upload-artifact@v3
  with:
    name: test-results
    path: results/
    retention-days: ${{ github.ref == 'refs/heads/main' && 30 || 7 }}
```

## 🤖 AI-Powered Enhancements

### 1. Copilot-Friendly Comments
```yaml
# Copilot: Create a job that runs security scans on the Docker image
# including vulnerability scanning, secret detection, and SBOM generation
# Use Trivy for scanning and upload results as SARIF
```

### 2. Self-Documenting Pipelines
```yaml
- name: Document pipeline
  run: |
    # Generate documentation from workflow file
    yq eval '.jobs | keys' $GITHUB_WORKFLOW > pipeline-stages.txt
    
    # Create visual representation
    echo "graph LR" > pipeline.mmd
    yq eval '.jobs | keys | .[]' $GITHUB_WORKFLOW | while read job; do
      echo "  $job[${job}]" >> pipeline.mmd
    done
```

## 🎯 Testing Strategies

### 1. Test What Matters
```yaml
- name: Critical path tests
  run: |
    # Test only critical user journeys in PR builds
    pytest tests/critical/ -m "critical" --fast
    
- name: Full test suite
  if: github.ref == 'refs/heads/main'
  run: |
    pytest tests/ --cov --cov-report=xml
```

### 2. Smart Test Selection
```yaml
- name: Detect changed files
  id: changes
  uses: dorny/paths-filter@v2
  with:
    filters: |
      backend:
        - 'src/**'
        - 'tests/**'
      frontend:
        - 'web/**'
      docs:
        - '**.md'

- name: Backend tests
  if: steps.changes.outputs.backend == 'true'
  run: pytest tests/backend/
```

## 📈 Performance Optimization

### 1. Build Matrix Optimization
```yaml
strategy:
  fail-fast: true  # Stop all jobs if one fails
  matrix:
    include:
      - os: ubuntu-latest
        arch: x64
        primary: true  # Mark primary build
```

### 2. Conditional Caching
```yaml
- name: Smart cache
  uses: actions/cache@v3
  with:
    path: ~/.cache
    key: cache-${{ runner.os }}-${{ github.run_id }}
    restore-keys: |
      cache-${{ runner.os }}-
    # Only save cache on main branch
    save-on-any-failure: ${{ github.ref == 'refs/heads/main' }}
```

## 🔍 Debugging and Troubleshooting

### 1. Debug Mode
```yaml
- name: Enable debug
  if: runner.debug == '1'
  run: |
    set -x
    echo "::debug::Debug mode enabled"
```

### 2. Conditional SSH Access
```yaml
- name: Setup tmate session
  if: failure() && github.event_name == 'workflow_dispatch'
  uses: mxschmitt/action-tmate@v3
  timeout-minutes: 15
```

## 📝 Documentation Standards

### 1. Inline Documentation
```yaml
# ====================================
# CI/CD Pipeline for Production
# ====================================
# Purpose: Build, test, and deploy application
# Triggers: Push to main, PR, manual
# Environments: dev, staging, prod
# ====================================
```

### 2. Workflow Metadata
```yaml
name: Production Pipeline
run-name: Deploy ${{ github.ref_name }} by @${{ github.actor }}
```

## 🏁 Checklist for Production

- [ ] All secrets are properly managed
- [ ] Appropriate permissions are set
- [ ] Caching is optimized
- [ ] Tests run in parallel where possible
- [ ] Deployments have health checks
- [ ] Rollback procedures are in place
- [ ] Monitoring and alerting configured
- [ ] Documentation is comprehensive
- [ ] Cost optimization measures applied
- [ ] Security scanning integrated

---

Following these best practices will ensure your CI/CD pipelines are reliable, secure, performant, and maintainable in production environments.