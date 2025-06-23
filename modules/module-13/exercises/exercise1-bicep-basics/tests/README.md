# Exercise 1: Bicep Basics - Tests

## Overview

This directory contains validation tests for the Bicep templates created in Exercise 1.

## Test Structure

```
tests/
├── validate-bicep.sh     # Bicep validation script
├── test-deployment.sh    # Deployment testing script
├── test-resources.py     # Python tests for deployed resources
└── README.md            # This file
```

## Running Tests

### 1. Bicep Validation

```bash
# Validate Bicep syntax
./validate-bicep.sh

# This script:
# - Checks Bicep file syntax
# - Validates ARM template generation
# - Runs best practice analyzer
```

### 2. Deployment Testing

```bash
# Test deployment (requires Azure subscription)
./test-deployment.sh --resource-group test-rg --environment dev

# This script:
# - Creates a test resource group
# - Deploys the template
# - Validates outputs
# - Cleans up resources
```

### 3. Resource Validation

```bash
# Run Python tests
python test-resources.py --resource-group <your-rg>

# These tests validate:
# - All resources are created
# - Security settings are correct
# - Connectivity works
# - Monitoring is configured
```

## Test Cases

### Bicep Template Tests
- ✅ Valid Bicep syntax
- ✅ All required parameters defined
- ✅ Resources have proper dependencies
- ✅ Outputs are correctly defined
- ✅ No hardcoded values

### Deployment Tests
- ✅ Successful deployment
- ✅ All resources created
- ✅ Correct SKUs applied
- ✅ Tags properly set
- ✅ No deployment errors

### Security Tests
- ✅ HTTPS only enabled
- ✅ Minimum TLS 1.2
- ✅ Managed identity configured
- ✅ SQL firewall rules set
- ✅ No plain text secrets

### Functional Tests
- ✅ Web app accessible
- ✅ Database connection works
- ✅ Storage account accessible
- ✅ Application Insights collecting data

## CI/CD Integration

These tests can be integrated into your CI/CD pipeline:

```yaml
# Example GitHub Actions workflow
name: Validate Bicep

on:
  push:
    paths:
      - 'exercises/exercise1-bicep-basics/**/*.bicep'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Validate Bicep
        run: |
          cd exercises/exercise1-bicep-basics
          ./tests/validate-bicep.sh
```

## Troubleshooting

### Common Issues

1. **Validation Fails**
   - Check Bicep extension is installed
   - Ensure latest Bicep CLI version
   - Review error messages carefully

2. **Deployment Fails**
   - Verify Azure credentials
   - Check resource quotas
   - Ensure unique resource names

3. **Tests Fail**
   - Wait for resources to fully provision
   - Check network connectivity
   - Verify correct resource group

## Contributing

When adding new features to the Bicep template:
1. Add corresponding test cases
2. Update test documentation
3. Ensure all tests pass before submitting