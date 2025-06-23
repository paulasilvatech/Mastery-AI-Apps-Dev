#!/bin/bash
# setup-gitops.sh - Complete script to initialize GitOps repository structure

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     GitOps Repository Setup Script       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# Create directory structure
echo -e "${YELLOW}📁 Creating directory structure...${NC}"

directories=(
    ".github/workflows"
    ".github/ISSUE_TEMPLATE"
    ".github/PULL_REQUEST_TEMPLATE"
    "infrastructure/modules/network"
    "infrastructure/modules/compute"
    "infrastructure/modules/data"
    "infrastructure/modules/monitoring"
    "infrastructure/modules/security"
    "infrastructure/environments/dev"
    "infrastructure/environments/staging"
    "infrastructure/environments/prod"
    "policies/azure"
    "policies/cost"
    "policies/security"
    "policies/tests"
    "scripts/validation"
    "scripts/deployment"
    "scripts/monitoring"
    "docs/architecture"
    "docs/runbooks"
    "docs/troubleshooting"
    "tests/unit"
    "tests/integration"
    "tests/e2e"
)

for dir in "${directories[@]}"; do
    mkdir -p "$dir"
    echo -e "${GREEN}✅ Created: $dir${NC}"
done

# Create .gitignore
echo -e "\n${YELLOW}📝 Creating .gitignore...${NC}"
cat > .gitignore << 'EOF'
# Terraform
*.tfstate
*.tfstate.*
*.tfplan
*.tfvars.local
.terraform/
.terraform.lock.hcl
crash.log
crash.*.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
.terraformrc
terraform.rc

# Bicep
*.azrm.json
deploymentOutput.json

# Environment variables
.env
.env.local
.env.*.local
*.env

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.project
.classpath
.settings/

# OS
.DS_Store
Thumbs.db
desktop.ini

# Logs
*.log
logs/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Temporary files
*.tmp
*.temp
tmp/
temp/

# Credentials
*.pem
*.key
*.crt
*.p12
*credentials.json
*secret*

# Python
__pycache__/
*.py[cod]
*$py.class
.Python
venv/
ENV/

# Node
node_modules/
dist/
.npm

# Testing
coverage/
.nyc_output
*.coverage
.coverage.*
.cache
htmlcov/

# Backup files
*.backup
*.bak
*.orig
EOF
echo -e "${GREEN}✅ Created .gitignore${NC}"

# Create README
echo -e "\n${YELLOW}📝 Creating README.md...${NC}"
cat > README.md << 'EOF'
# Infrastructure as Code - GitOps Repository

[![Infrastructure Validation](https://github.com/YOUR_ORG/YOUR_REPO/actions/workflows/validate-infrastructure.yml/badge.svg)](https://github.com/YOUR_ORG/YOUR_REPO/actions/workflows/validate-infrastructure.yml)
[![Security Scan](https://github.com/YOUR_ORG/YOUR_REPO/actions/workflows/security-scan.yml/badge.svg)](https://github.com/YOUR_ORG/YOUR_REPO/actions/workflows/security-scan.yml)

This repository implements GitOps principles for infrastructure management using GitHub Actions, Terraform, and Azure Bicep.

## 🏗️ Repository Structure

```
.
├── .github/                    # GitHub Actions workflows and templates
│   ├── workflows/             # CI/CD pipelines
│   ├── ISSUE_TEMPLATE/        # Issue templates
│   └── PULL_REQUEST_TEMPLATE/ # PR templates
├── infrastructure/
│   ├── modules/               # Reusable infrastructure modules
│   │   ├── network/          # Networking components
│   │   ├── compute/          # Compute resources
│   │   ├── data/             # Data storage and databases
│   │   ├── monitoring/       # Monitoring and logging
│   │   └── security/         # Security components
│   └── environments/          # Environment-specific configurations
│       ├── dev/              # Development environment
│       ├── staging/          # Staging environment
│       └── prod/             # Production environment
├── policies/                  # Policy as Code definitions
│   ├── azure/                # Azure-specific policies
│   ├── cost/                 # Cost management policies
│   ├── security/             # Security policies
│   └── tests/                # Policy tests
├── scripts/                   # Automation scripts
│   ├── validation/           # Validation scripts
│   ├── deployment/           # Deployment scripts
│   └── monitoring/           # Monitoring scripts
├── docs/                      # Documentation
│   ├── architecture/         # Architecture diagrams and docs
│   ├── runbooks/             # Operational runbooks
│   └── troubleshooting/      # Troubleshooting guides
└── tests/                     # Infrastructure tests
    ├── unit/                 # Unit tests
    ├── integration/          # Integration tests
    └── e2e/                  # End-to-end tests
```

## 🔄 GitOps Workflow

1. **Create Feature Branch**: Branch from `main` for your changes
2. **Make Changes**: Modify infrastructure code
3. **Open Pull Request**: Automated validation begins
4. **Review**: Team reviews changes, costs, and security
5. **Merge**: Approved changes trigger deployment
6. **Monitor**: Continuous monitoring and drift detection

## 🚀 Quick Start

### Prerequisites

- Azure CLI installed and configured
- Terraform >= 1.6.0
- GitHub CLI (optional)
- OPA (Open Policy Agent)
- Checkov for security scanning

### Setup

1. Clone this repository
2. Run the setup script:
   ```bash
   ./scripts/setup-gitops.sh
   ```
3. Configure GitHub secrets:
   ```bash
   ./scripts/setup-github-secrets.sh
   ```
4. Initialize Terraform backend:
   ```bash
   ./scripts/setup-backend.sh
   ```

## 📋 Environment Strategy

| Environment | Purpose | Deployment | Approval |
|-------------|---------|------------|----------|
| Dev | Development and testing | Automatic on merge | None |
| Staging | Pre-production validation | Manual trigger | 1 reviewer |
| Production | Live environment | Manual trigger | 2 reviewers |

## 🔐 Security

- All secrets stored in Azure Key Vault
- Managed identities for authentication
- Network security enforced by policy
- Regular security scanning with Checkov
- Compliance validation with OPA

## 📊 Cost Management

- Pre-deployment cost estimation
- Environment-specific budgets
- Cost alerts and monitoring
- Regular cost optimization reviews

## 🧪 Testing

```bash
# Run all tests
make test

# Run specific test suite
make test-unit
make test-integration
make test-policies
```

## 📚 Documentation

- [Architecture Overview](docs/architecture/overview.md)
- [Deployment Guide](docs/runbooks/deployment.md)
- [Troubleshooting Guide](docs/troubleshooting/common-issues.md)
- [Policy Reference](docs/policies/reference.md)

## 🤝 Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
EOF
echo -e "${GREEN}✅ Created README.md${NC}"

# Create PR template
echo -e "\n${YELLOW}📝 Creating PR template...${NC}"
cat > .github/PULL_REQUEST_TEMPLATE/infrastructure.md << 'EOF'
## 📋 Description
<!-- Provide a brief description of the infrastructure changes -->

## 🎯 Type of Change
- [ ] 🆕 New infrastructure
- [ ] 🔄 Update existing infrastructure
- [ ] 🐛 Bug fix
- [ ] ⚙️ Configuration change
- [ ] 📚 Documentation update
- [ ] 🔒 Security improvement

## 🧪 Testing
- [ ] ✅ Validated locally with `terraform plan`
- [ ] 🔒 Security scan passed
- [ ] 💰 Cost estimation reviewed
- [ ] 📋 Policy validation passed
- [ ] 🧪 Unit tests passed
- [ ] 🔄 Integration tests passed

## 📊 Impact Analysis
### Resources Affected
<!-- List the resources that will be created/modified/deleted -->

### Estimated Cost Impact
<!-- Monthly cost change: +$X.XX or -$X.XX -->

### Security Considerations
<!-- Any security implications of these changes -->

## ✅ Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review of code completed
- [ ] Documentation updated
- [ ] No hardcoded secrets or sensitive data
- [ ] Appropriate tags added to resources
- [ ] Changes are backwards compatible
- [ ] Breaking changes are documented

## 🚀 Deployment Plan
### Order of Deployment
1. [ ] Dev environment
2. [ ] Staging environment (requires approval)
3. [ ] Production environment (requires 2 approvals)

### Pre-deployment Steps
<!-- List any manual steps required before deployment -->

### Post-deployment Steps
<!-- List any manual steps required after deployment -->

## 🔄 Rollback Plan
<!-- Describe the rollback procedure if deployment fails -->

### Rollback Steps
1. 
2. 
3. 

### Data Recovery
<!-- If applicable, describe data recovery procedures -->

## 📸 Screenshots/Diagrams
<!-- If applicable, add architecture diagrams or screenshots -->

## 🔗 Related Issues/PRs
<!-- Link related issues or PRs -->
- Closes #
- Related to #

## 📝 Additional Notes
<!-- Any additional context or notes for reviewers -->

---
**Reviewer Checklist:**
- [ ] Changes are appropriate for the target environment
- [ ] Security best practices followed
- [ ] Cost impact is acceptable
- [ ] Documentation is complete and accurate
- [ ] Rollback plan is viable
EOF
echo -e "${GREEN}✅ Created PR template${NC}"

# Create issue templates
echo -e "\n${YELLOW}📝 Creating issue templates...${NC}"

# Bug report template
cat > .github/ISSUE_TEMPLATE/bug_report.md << 'EOF'
---
name: Bug Report
about: Report infrastructure issues or unexpected behavior
title: '[BUG] '
labels: 'bug, triage'
assignees: ''
---

## 🐛 Bug Description
<!-- A clear and concise description of the bug -->

## 🔍 Steps to Reproduce
1. 
2. 
3. 

## 💭 Expected Behavior
<!-- What you expected to happen -->

## 🚨 Actual Behavior
<!-- What actually happened -->

## 🌍 Environment
- [ ] Dev
- [ ] Staging
- [ ] Production

## 📸 Screenshots/Logs
<!-- If applicable, add screenshots or relevant log excerpts -->

## 🔧 Possible Solution
<!-- Optional: Suggest a fix or workaround -->

## 📝 Additional Context
<!-- Add any other context about the problem -->
EOF

# Feature request template
cat > .github/ISSUE_TEMPLATE/feature_request.md << 'EOF'
---
name: Feature Request
about: Suggest new infrastructure features or improvements
title: '[FEATURE] '
labels: 'enhancement'
assignees: ''
---

## 🚀 Feature Description
<!-- A clear description of the feature -->

## 🎯 Use Case
<!-- Describe the problem this feature would solve -->

## 💡 Proposed Solution
<!-- How you envision this feature working -->

## 🔄 Alternatives Considered
<!-- Other solutions you've considered -->

## 📊 Impact
- **Cost Impact**: 
- **Security Impact**: 
- **Performance Impact**: 

## ✅ Success Criteria
<!-- How we'll know this feature is successful -->
- [ ] 
- [ ] 
- [ ] 

## 📝 Additional Context
<!-- Any other context or screenshots -->
EOF
echo -e "${GREEN}✅ Created issue templates${NC}"

# Create pre-commit configuration
echo -e "\n${YELLOW}📝 Creating pre-commit configuration...${NC}"
cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.5
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_docs
      - id: terraform_tflint
        args:
          - --args=--only=terraform_deprecated_interpolation
          - --args=--only=terraform_deprecated_index
          - --args=--only=terraform_unused_declarations
          - --args=--only=terraform_comment_syntax
          - --args=--only=terraform_documented_outputs
          - --args=--only=terraform_documented_variables
          - --args=--only=terraform_typed_variables
          - --args=--only=terraform_module_pinned_source
          - --args=--only=terraform_naming_convention
          - --args=--only=terraform_required_version
          - --args=--only=terraform_required_providers
          - --args=--only=terraform_standard_module_structure
      - id: terraform_checkov
        args:
          - --args=--quiet
          - --args=--skip-check CKV_AZURE_88,CKV_AZURE_71

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: check-yaml
      - id: check-json
      - id: check-merge-conflict
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: detect-private-key
      - id: detect-aws-credentials
        args: [--allow-missing-credentials]
      
  - repo: https://github.com/zricethezav/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks

  - repo: https://github.com/igorshubovych/markdownlint-cli
    rev: v0.37.0
    hooks:
      - id: markdownlint
        args: [--fix]
EOF
echo -e "${GREEN}✅ Created pre-commit configuration${NC}"

# Create Makefile
echo -e "\n${YELLOW}📝 Creating Makefile...${NC}"
cat > Makefile << 'EOF'
.PHONY: help init validate plan apply destroy test clean

# Default target
help:
	@echo "Available targets:"
	@echo "  init      - Initialize Terraform"
	@echo "  validate  - Validate Terraform configuration"
	@echo "  plan      - Create Terraform plan"
	@echo "  apply     - Apply Terraform changes"
	@echo "  destroy   - Destroy infrastructure"
	@echo "  test      - Run all tests"
	@echo "  clean     - Clean temporary files"

# Environment variables
ENV ?= dev
TF_DIR = infrastructure/environments/$(ENV)

# Initialize Terraform
init:
	@echo "Initializing Terraform for $(ENV) environment..."
	@cd $(TF_DIR) && terraform init

# Validate configuration
validate: init
	@echo "Validating Terraform configuration..."
	@cd $(TF_DIR) && terraform validate
	@echo "Running security scan..."
	@checkov -d $(TF_DIR) --quiet
	@echo "Running policy validation..."
	@./scripts/validation/validate-policies.sh $(ENV)

# Create plan
plan: validate
	@echo "Creating Terraform plan for $(ENV) environment..."
	@cd $(TF_DIR) && terraform plan -out=tfplan

# Apply changes
apply: plan
	@echo "Applying Terraform changes to $(ENV) environment..."
	@cd $(TF_DIR) && terraform apply tfplan

# Destroy infrastructure
destroy:
	@echo "WARNING: This will destroy all resources in $(ENV) environment!"
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read confirm
	@cd $(TF_DIR) && terraform destroy -auto-approve

# Run all tests
test: test-unit test-integration test-policies

# Run unit tests
test-unit:
	@echo "Running unit tests..."
	@cd tests/unit && go test -v ./...

# Run integration tests
test-integration:
	@echo "Running integration tests..."
	@cd tests/integration && go test -v ./...

# Run policy tests
test-policies:
	@echo "Running policy tests..."
	@opa test policies/ -v

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@find . -type f -name "*.tfplan" -delete
	@find . -type f -name "*.tfstate.backup" -delete
	@find . -type d -name ".terraform" -exec rm -rf {} +
	@find . -type f -name ".terraform.lock.hcl" -delete
	@echo "Clean complete!"
EOF
echo -e "${GREEN}✅ Created Makefile${NC}"

# Create CONTRIBUTING.md
echo -e "\n${YELLOW}📝 Creating CONTRIBUTING.md...${NC}"
cat > CONTRIBUTING.md << 'EOF'
# Contributing to Infrastructure as Code Repository

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Process](#development-process)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [Documentation](#documentation)

## 📜 Code of Conduct

We are committed to providing a welcoming and inclusive environment. Please read and follow our Code of Conduct.

## 🚀 Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/REPO_NAME.git
   cd REPO_NAME
   ```
3. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/REPO_NAME.git
   ```
4. Install pre-commit hooks:
   ```bash
   pre-commit install
   ```

## 🔄 Development Process

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**:
   - Write clean, readable code
   - Follow existing patterns
   - Add tests for new functionality
   - Update documentation

3. **Commit your changes**:
   ```bash
   git commit -m "feat: add new feature"
   ```
   
   Follow conventional commits:
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation changes
   - `style:` - Code style changes
   - `refactor:` - Code refactoring
   - `test:` - Test changes
   - `chore:` - Maintenance tasks

4. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

## 🔀 Pull Request Process

1. **Before opening a PR**:
   - Ensure all tests pass
   - Run security scans
   - Validate against policies
   - Update documentation

2. **PR Requirements**:
   - Fill out the PR template completely
   - Link related issues
   - Provide clear description
   - Include test results
   - Add cost estimates for infrastructure changes

3. **Review Process**:
   - At least one approval required
   - All CI checks must pass
   - Security scan must pass
   - Cost impact must be reviewed

## 📏 Coding Standards

### Terraform
- Use Terraform 1.6.0 or later
- Follow [Terraform Style Guide](https://www.terraform.io/docs/language/syntax/style.html)
- Use meaningful resource names
- Add descriptions to all variables
- Document all outputs

### File Organization
```
modules/
  └── module_name/
      ├── main.tf          # Primary resources
      ├── variables.tf     # Input variables
      ├── outputs.tf       # Output values
      ├── versions.tf      # Provider requirements
      └── README.md        # Module documentation
```

### Naming Conventions
- Resources: `resource_type_purpose_environment`
- Variables: `snake_case`
- Outputs: `snake_case`
- Files: `hyphen-separated`

## 🧪 Testing Requirements

### Unit Tests
- Test individual modules
- Mock external dependencies
- Achieve >80% coverage

### Integration Tests
- Test module interactions
- Validate in test environment
- Clean up resources after tests

### Policy Tests
- All policies must have tests
- Test both allow and deny cases
- Document expected behavior

## 📚 Documentation

### Required Documentation
- README for each module
- Inline comments for complex logic
- Architecture diagrams for systems
- Runbooks for operations

### Documentation Standards
- Use clear, concise language
- Include examples
- Keep documentation up-to-date
- Use diagrams where helpful

## 🎯 Checklist

Before submitting a PR, ensure:

- [ ] Code follows style guidelines
- [ ] Tests are passing
- [ ] Documentation is updated
- [ ] Security scan passes
- [ ] Policy validation passes
- [ ] Cost impact is documented
- [ ] PR template is completed
- [ ] Related issues are linked

Thank you for contributing!
EOF
echo -e "${GREEN}✅ Created CONTRIBUTING.md${NC}"

# Create example environment configuration
echo -e "\n${YELLOW}📝 Creating example environment configuration...${NC}"
cat > infrastructure/environments/dev/.gitkeep << 'EOF'
# Development environment infrastructure
EOF

# Final summary
echo -e "\n${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Setup Complete! 🎉              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✅ Repository structure created${NC}"
echo -e "${GREEN}✅ Templates and documentation added${NC}"
echo -e "${GREEN}✅ Pre-commit hooks configured${NC}"
echo -e "${GREEN}✅ Makefile created for common tasks${NC}"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo -e "1. Install pre-commit hooks: ${BLUE}pre-commit install${NC}"
echo -e "2. Configure GitHub secrets: ${BLUE}./scripts/setup-github-secrets.sh${NC}"
echo -e "3. Initialize Terraform backend: ${BLUE}./scripts/setup-backend.sh${NC}"
echo -e "4. Create your first infrastructure: ${BLUE}make init ENV=dev${NC}"
echo ""
echo -e "${GREEN}Happy GitOps! 🚀${NC}" 