---
sidebar_position: 4
title: "Exercise 1: Part 2"
description: "## 📝 Part 2: Customization and Advanced Features"
---

# Exercise 1: Build Your First Pipeline (Part 2)

## 📝 Part 2: Customization and Advanced Features

### Step 6: Add Status Badge to README

Let's add a status badge to show the build status:

**README.md:**

**Copilot Prompt Suggestion:**
```markdown
# Create a README with:
# - Project title "CI/CD Workshop Demo"
# - Build status badge for the CI Pipeline
# - Description of the project
# - Installation instructions
# - How to run tests
# - How to contribute
# - License information
```

**Expected Output:**
```markdown
# CI/CD Workshop Demo

[![CI Pipeline](https://github.com/YOUR-USERNAME/cicd-workshop/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR-USERNAME/cicd-workshop/actions/workflows/ci.yml)

## Description

This is a demo Flask application showcasing CI/CD best practices using GitHub Actions. The project demonstrates automated testing, linting, security scanning, and artifact generation.

## Features

- 🚀 Automated CI/CD pipeline with GitHub Actions
- 🧪 Comprehensive test coverage
- 🔒 Security scanning with Bandit
- 📊 Code quality checks with flake8 and black
- 📦 Automated artifact generation

## Installation

```bash
# Clone the repository
git clone https://github.com/YOUR-USERNAME/cicd-workshop.git
cd cicd-workshop

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements-dev.txt
```

## Running the Application

```bash
python src/app.py
```

The application will be available at `http://localhost:5000`

## Running Tests

```bash
# Run all tests with coverage
pytest tests/ -v --cov=src

# Run specific test file
pytest tests/test_app.py -v

# Generate HTML coverage report
pytest tests/ --cov=src --cov-report=html
```

## Code Quality

```bash
# Run linting
flake8 src tests

# Check code formatting
black --check src tests

# Format code
black src tests

# Security scan
bandit -r src/
```

## CI/CD Pipeline

Our GitHub Actions workflow automatically:
1. Runs code quality checks (flake8, black, mypy)
2. Executes all tests with coverage reporting
3. Performs security scanning
4. Builds and packages the application
5. Uploads artifacts for deployment

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
```

### Step 7: Create a .gitignore File

**.gitignore:**
```
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
.venv
*.egg-info/
dist/
build/

# Testing
.coverage
.pytest_cache/
htmlcov/
.tox/
*.cover
.hypothesis/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Security
*.key
*.pem
.env

# CI/CD
*.log
bandit-report.json
```

### Step 8: Add Matrix Strategy for Multiple Python Versions

Let's enhance our workflow to test against multiple Python versions:

**Update .github/workflows/ci.yml:**

**Copilot Prompt Suggestion:**
```yaml
# Modify the test job to:
# - Use a matrix strategy for Python 3.9, 3.10, and 3.11
# - Display the Python version in the job name
# - Continue on error for non-required versions
# - Make 3.11 required and others optional
```

**Expected Update for test job:**
```yaml
  test:
    name: Run Tests (Python ${{ matrix.python-version }})
    runs-on: ubuntu-latest
    needs: lint
    strategy:
      matrix:
        python-version: ['3.9', '3.10', '3.11']
        include:
          - python-version: '3.11'
            required: true
          - python-version: '3.10'
            required: false
          - python-version: '3.9'
            required: false
      fail-fast: false
    continue-on-error: ${{ matrix.required == false }}
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}
    
    # ... rest of the steps remain the same
```

### Step 9: Add Workflow Dispatch for Manual Runs

Add the ability to manually trigger the workflow:

**Update the `on:` section in .github/workflows/ci.yml:**
```yaml
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:
    inputs:
      debug_enabled:
        description: 'Enable debug logging'
        required: false
        default: 'false'
        type: boolean
      skip_tests:
        description: 'Skip test execution'
        required: false
        default: 'false'
        type: boolean
```

### Step 10: Implement Conditional Steps

Add conditional execution based on inputs:

```yaml
    - name: Run tests with coverage
      if: ${{ github.event.inputs.skip_tests != 'true' }}
      run: |
        if [[ "${{ github.event.inputs.debug_enabled }}" == "true" ]]; then
          pytest tests/ -v -s --cov=src --cov-report=xml --cov-report=html --cov-report=term
        else
          pytest tests/ -v --cov=src --cov-report=xml --cov-report=html --cov-report=term
        fi
```

## 🧪 Testing Your Pipeline

### Local Testing with act

Before pushing to GitHub, test your workflow locally:

```bash
# Install act (GitHub Actions local runner)
# macOS
brew install act

# Windows
choco install act-cli

# Linux
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run the workflow locally
act push
```

### Pushing to GitHub

```bash
# Initialize git and push
git add .
git commit -m "Initial CI/CD pipeline setup"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/cicd-workshop.git
git push -u origin main
```

## 🎯 Validation Checklist

Your pipeline is complete when:

- [ ] Workflow runs automatically on push to main
- [ ] All jobs pass successfully (green checkmarks)
- [ ] Status badge appears in README
- [ ] Coverage report is generated and uploaded
- [ ] Security scan completes without critical issues
- [ ] Build artifacts are created and available
- [ ] Job summaries provide useful information
- [ ] Manual dispatch works with parameters

## 🚀 Bonus Challenges

1. **Add Docker Build**: Create a Dockerfile and add a job to build and push to a registry
2. **Implement Caching**: Add caching for Docker layers
3. **Add Release Creation**: Automatically create GitHub releases on tags
4. **Slack Notifications**: Send build status to Slack
5. **Performance Metrics**: Add timing information to job summaries

## 📊 Understanding the Results

### Reading Workflow Runs
- Click on the Actions tab in your repository
- Each run shows status for all jobs
- Click on a run to see detailed logs
- Download artifacts from the run summary

### Interpreting Coverage Reports
- Open the uploaded HTML coverage report
- Green lines are covered by tests
- Red lines need test coverage
- Aim for Greater than 80% coverage

## 🎓 Key Takeaways

1. **Workflow Structure**: YAML syntax and job organization
2. **Job Dependencies**: Using `needs` for sequential execution
3. **Caching**: Speed up builds with dependency caching
4. **Artifacts**: Share data between jobs and workflows
5. **Matrix Builds**: Test across multiple environments
6. **Conditional Logic**: Dynamic workflow behavior

## 🆘 Common Issues and Solutions

### Workflow Not Triggering
- Check branch protection rules
- Verify Actions are enabled in repository settings
- Ensure YAML syntax is valid

### Permission Errors
```yaml
permissions:
  contents: read
  checks: write
  pull-requests: write
```

### Python Import Errors
- Ensure `__init__.py` files exist
- Check PYTHONPATH in workflow
- Verify package structure

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Workflow Syntax Reference](https://docs.github.com/actions/reference/workflow-syntax-for-github-actions)
- [GitHub Actions Marketplace](https://github.com/marketplace/actions)
- [Best Practices Guide](https://docs.github.com/actions/guides/building-and-testing-python)

---

**Congratulations!** 🎉 You've successfully created your first CI/CD pipeline. This forms the foundation for the more advanced exercises in this module.

**Next Step**: Proceed to Exercise 2 - Multi-Environment Deployment