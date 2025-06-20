# Module 14: Validation Tests

These scripts validate that exercises have been completed correctly.

## 📁 Test Structure

```
tests/
├── validate_exercise1.py
├── validate_exercise2.py
├── validate_exercise3.py
└── run_all_validations.sh
```

## 🧪 Validation Scripts

### validate_exercise1.py
```python
#!/usr/bin/env python3
"""
Validation script for Exercise 1: Build Your First Pipeline
"""

import os
import sys
import yaml
import subprocess
from pathlib import Path
from typing import Dict, List, Tuple


class Exercise1Validator:
    def __init__(self, project_path: str = "."):
        self.project_path = Path(project_path)
        self.errors: List[str] = []
        self.warnings: List[str] = []
        
    def validate(self) -> bool:
        """Run all validations."""
        print("🔍 Validating Exercise 1: Build Your First Pipeline\n")
        
        checks = [
            self.check_file_structure,
            self.check_workflow_file,
            self.check_application_code,
            self.check_tests,
            self.check_documentation,
            self.check_workflow_execution
        ]
        
        for check in checks:
            check()
            
        return self.print_results()
    
    def check_file_structure(self):
        """Verify required files exist."""
        print("📁 Checking file structure...")
        
        required_files = [
            ".github/workflows/ci.yml",
            "src/__init__.py",
            "src/app.py",
            "tests/__init__.py",
            "tests/test_app.py",
            "requirements.txt",
            "requirements-dev.txt",
            "README.md",
            ".gitignore"
        ]
        
        for file in required_files:
            path = self.project_path / file
            if not path.exists():
                self.errors.append(f"Missing required file: {file}")
            else:
                print(f"  ✅ Found {file}")
    
    def check_workflow_file(self):
        """Validate GitHub Actions workflow."""
        print("\n📄 Checking workflow configuration...")
        
        workflow_path = self.project_path / ".github/workflows/ci.yml"
        if not workflow_path.exists():
            self.errors.append("Workflow file not found")
            return
            
        try:
            with open(workflow_path) as f:
                workflow = yaml.safe_load(f)
                
            # Check triggers
            if 'on' not in workflow:
                self.errors.append("Workflow missing 'on' triggers")
            else:
                triggers = workflow['on']
                if 'push' not in triggers:
                    self.warnings.append("Workflow should trigger on push")
                if 'pull_request' not in triggers:
                    self.warnings.append("Workflow should trigger on pull_request")
                    
            # Check jobs
            if 'jobs' not in workflow:
                self.errors.append("Workflow missing jobs")
            else:
                jobs = workflow['jobs']
                required_jobs = ['lint', 'test', 'security', 'build']
                
                for job in required_jobs:
                    if job not in jobs:
                        self.errors.append(f"Missing required job: {job}")
                    else:
                        print(f"  ✅ Found job: {job}")
                        
                # Check job dependencies
                if 'test' in jobs and 'needs' in jobs['test']:
                    if 'lint' not in jobs['test']['needs']:
                        self.warnings.append("Test job should depend on lint job")
                        
        except Exception as e:
            self.errors.append(f"Error parsing workflow: {e}")
    
    def check_application_code(self):
        """Validate Flask application."""
        print("\n🐍 Checking application code...")
        
        app_path = self.project_path / "src/app.py"
        if not app_path.exists():
            self.errors.append("Application file not found")
            return
            
        with open(app_path) as f:
            content = f.read()
            
        # Check for required endpoints
        endpoints = [
            ("@app.route('/')", "Welcome endpoint"),
            ("@app.route('/health')", "Health check endpoint"),
            ("@app.route('/api/data')", "API data endpoint"),
            ("@app.errorhandler(404)", "404 error handler"),
            ("@app.errorhandler(500)", "500 error handler")
        ]
        
        for pattern, desc in endpoints:
            if pattern not in content:
                self.errors.append(f"Missing {desc}")
            else:
                print(f"  ✅ Found {desc}")
                
        # Check for logging
        if "import logging" not in content:
            self.warnings.append("Consider adding logging to application")
            
        # Check for environment variables
        if "os.environ.get" not in content:
            self.warnings.append("Application should read configuration from environment")
    
    def check_tests(self):
        """Validate test implementation."""
        print("\n🧪 Checking tests...")
        
        test_path = self.project_path / "tests/test_app.py"
        if not test_path.exists():
            self.errors.append("Test file not found")
            return
            
        # Run tests
        try:
            result = subprocess.run(
                ["pytest", str(test_path), "-v"],
                capture_output=True,
                text=True
            )
            
            if result.returncode != 0:
                self.errors.append("Tests are failing")
                print(f"  ❌ Tests failed:\n{result.stdout}")
            else:
                print("  ✅ All tests passing")
                
                # Check test coverage
                coverage_result = subprocess.run(
                    ["pytest", str(test_path), "--cov=src", "--cov-report=term"],
                    capture_output=True,
                    text=True
                )
                
                if "100%" in coverage_result.stdout:
                    print("  ✅ 100% test coverage")
                else:
                    self.warnings.append("Test coverage is less than 100%")
                    
        except Exception as e:
            self.errors.append(f"Error running tests: {e}")
    
    def check_documentation(self):
        """Validate README and documentation."""
        print("\n📚 Checking documentation...")
        
        readme_path = self.project_path / "README.md"
        if not readme_path.exists():
            self.errors.append("README.md not found")
            return
            
        with open(readme_path) as f:
            content = f.read()
            
        # Check for required sections
        sections = [
            ("# ", "Title"),
            ("## Description", "Description section"),
            ("## Installation", "Installation section"),
            ("[![", "Status badge")
        ]
        
        for pattern, desc in sections:
            if pattern not in content:
                self.warnings.append(f"README missing {desc}")
            else:
                print(f"  ✅ Found {desc}")
    
    def check_workflow_execution(self):
        """Check if workflow would execute successfully."""
        print("\n🚀 Checking workflow execution...")
        
        # Validate YAML syntax
        workflow_path = self.project_path / ".github/workflows/ci.yml"
        try:
            result = subprocess.run(
                ["yamllint", str(workflow_path)],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                print("  ✅ Workflow YAML is valid")
            else:
                self.warnings.append("Workflow has YAML issues")
                
        except:
            # yamllint might not be installed
            pass
            
        # Check if all required secrets would be available
        workflow_content = workflow_path.read_text()
        if "${{ secrets." in workflow_content:
            print("  ⚠️  Workflow uses secrets - ensure they are configured")
    
    def print_results(self) -> bool:
        """Print validation results."""
        print("\n" + "="*50)
        print("VALIDATION RESULTS")
        print("="*50)
        
        if not self.errors and not self.warnings:
            print("\n✅ All validations passed! Exercise 1 is complete.")
            return True
            
        if self.errors:
            print(f"\n❌ Found {len(self.errors)} errors:")
            for error in self.errors:
                print(f"  - {error}")
                
        if self.warnings:
            print(f"\n⚠️  Found {len(self.warnings)} warnings:")
            for warning in self.warnings:
                print(f"  - {warning}")
                
        print("\n📝 Please fix the errors and review the warnings.")
        return len(self.errors) == 0


def main():
    validator = Exercise1Validator()
    success = validator.validate()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
```

### validate_exercise2.py
```python
#!/usr/bin/env python3
"""
Validation script for Exercise 2: Multi-Environment Deployment
"""

import os
import sys
import json
import yaml
from pathlib import Path
from typing import Dict, List


class Exercise2Validator:
    def __init__(self, project_path: str = "."):
        self.project_path = Path(project_path)
        self.errors: List[str] = []
        self.warnings: List[str] = []
        
    def validate(self) -> bool:
        """Run all validations."""
        print("🔍 Validating Exercise 2: Multi-Environment Deployment\n")
        
        checks = [
            self.check_infrastructure_files,
            self.check_deployment_workflow,
            self.check_environment_configs,
            self.check_deployment_strategies,
            self.check_monitoring_setup
        ]
        
        for check in checks:
            check()
            
        return self.print_results()
    
    def check_infrastructure_files(self):
        """Check Bicep/Terraform files."""
        print("🏗️ Checking infrastructure files...")
        
        # Check for Bicep files
        bicep_files = [
            "infrastructure/main.bicep",
            "infrastructure/parameters.dev.json",
            "infrastructure/parameters.staging.json",
            "infrastructure/parameters.prod.json"
        ]
        
        for file in bicep_files:
            path = self.project_path / file
            if path.exists():
                print(f"  ✅ Found {file}")
            else:
                self.errors.append(f"Missing infrastructure file: {file}")
    
    def check_deployment_workflow(self):
        """Validate deployment workflow."""
        print("\n🚀 Checking deployment workflow...")
        
        workflow_path = self.project_path / ".github/workflows/deploy.yml"
        if not workflow_path.exists():
            self.errors.append("Deployment workflow not found")
            return
            
        try:
            with open(workflow_path) as f:
                workflow = yaml.safe_load(f)
                
            # Check for environment-specific jobs
            jobs = workflow.get('jobs', {})
            
            required_jobs = [
                'prepare-deployment',
                'deploy-infrastructure',
                'deploy-application',
                'smoke-tests'
            ]
            
            for job in required_jobs:
                if job not in jobs:
                    self.errors.append(f"Missing deployment job: {job}")
                else:
                    print(f"  ✅ Found job: {job}")
                    
            # Check for environment usage
            for job_name, job_config in jobs.items():
                if 'environment' in job_config:
                    print(f"  ✅ Job '{job_name}' uses environment")
                    
        except Exception as e:
            self.errors.append(f"Error parsing deployment workflow: {e}")
    
    def check_environment_configs(self):
        """Check environment-specific configurations."""
        print("\n🔧 Checking environment configurations...")
        
        environments = ['dev', 'staging', 'prod']
        
        for env in environments:
            param_file = self.project_path / f"infrastructure/parameters.{env}.json"
            if param_file.exists():
                try:
                    with open(param_file) as f:
                        params = json.load(f)
                        
                    if 'parameters' in params:
                        if 'environmentName' in params['parameters']:
                            print(f"  ✅ Valid configuration for {env}")
                        else:
                            self.warnings.append(f"{env} missing environmentName parameter")
                            
                except Exception as e:
                    self.errors.append(f"Error parsing {env} parameters: {e}")
    
    def check_deployment_strategies(self):
        """Check for different deployment strategies."""
        print("\n📊 Checking deployment strategies...")
        
        deploy_workflow = self.project_path / ".github/workflows/deploy.yml"
        if deploy_workflow.exists():
            content = deploy_workflow.read_text()
            
            strategies = [
                ("blue-green", "Blue-green deployment"),
                ("canary", "Canary deployment"),
                ("slot", "Deployment slots")
            ]
            
            for pattern, desc in strategies:
                if pattern in content.lower():
                    print(f"  ✅ Found {desc}")
                else:
                    self.warnings.append(f"Consider implementing {desc}")
    
    def check_monitoring_setup(self):
        """Check monitoring and alerting setup."""
        print("\n📈 Checking monitoring setup...")
        
        # Check for monitoring in Bicep
        bicep_file = self.project_path / "infrastructure/main.bicep"
        if bicep_file.exists():
            content = bicep_file.read_text()
            
            if "Microsoft.Insights/components" in content:
                print("  ✅ Application Insights configured")
            else:
                self.warnings.append("Consider adding Application Insights")
                
            if "Microsoft.KeyVault/vaults" in content:
                print("  ✅ Key Vault configured")
            else:
                self.warnings.append("Consider adding Key Vault for secrets")
    
    def print_results(self) -> bool:
        """Print validation results."""
        print("\n" + "="*50)
        print("VALIDATION RESULTS")
        print("="*50)
        
        if not self.errors and not self.warnings:
            print("\n✅ All validations passed! Exercise 2 is complete.")
            return True
            
        if self.errors:
            print(f"\n❌ Found {len(self.errors)} errors:")
            for error in self.errors:
                print(f"  - {error}")
                
        if self.warnings:
            print(f"\n⚠️  Found {len(self.warnings)} warnings:")
            for warning in self.warnings:
                print(f"  - {warning}")
                
        return len(self.errors) == 0


def main():
    validator = Exercise2Validator()
    success = validator.validate()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
```

### run_all_validations.sh
```bash
#!/bin/bash
# Run all validation tests for Module 14

echo "🚀 Running Module 14 Validation Suite"
echo "===================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track overall success
ALL_PASSED=true

# Function to run a validation
run_validation() {
    local exercise=$1
    local script=$2
    
    echo -e "\n${YELLOW}Validating Exercise ${exercise}${NC}"
    echo "------------------------------------"
    
    if python3 "${script}"; then
        echo -e "${GREEN}✅ Exercise ${exercise} validation passed${NC}"
    else
        echo -e "${RED}❌ Exercise ${exercise} validation failed${NC}"
        ALL_PASSED=false
    fi
}

# Check Python is available
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 is required${NC}"
    exit 1
fi

# Install required packages
echo "📦 Installing validation dependencies..."
pip install -q pyyaml pytest pytest-cov yamllint

# Run validations
run_validation "1" "tests/validate_exercise1.py"
run_validation "2" "tests/validate_exercise2.py"
run_validation "3" "tests/validate_exercise3.py"

# Summary
echo -e "\n${YELLOW}===================================="
echo "VALIDATION SUMMARY"
echo -e "====================================${NC}"

if [ "$ALL_PASSED" = true ]; then
    echo -e "${GREEN}✅ All exercises passed validation!${NC}"
    echo "🎉 Congratulations! You've completed Module 14."
    exit 0
else
    echo -e "${RED}❌ Some exercises need more work.${NC}"
    echo "Please review the errors above and try again."
    exit 1
fi
```

### validate_exercise3.py
```python
#!/usr/bin/env python3
"""
Validation script for Exercise 3: Enterprise Pipeline with AI
"""

import os
import sys
import yaml
from pathlib import Path
from typing import List


class Exercise3Validator:
    def __init__(self, project_path: str = "."):
        self.project_path = Path(project_path)
        self.errors: List[str] = []
        self.warnings: List[str] = []
        
    def validate(self) -> bool:
        """Run all validations."""
        print("🔍 Validating Exercise 3: Enterprise Pipeline with AI\n")
        
        checks = [
            self.check_ai_actions,
            self.check_enterprise_workflow,
            self.check_ai_integration,
            self.check_monitoring_automation,
            self.check_cost_optimization
        ]
        
        for check in checks:
            check()
            
        return self.print_results()
    
    def check_ai_actions(self):
        """Check custom AI actions."""
        print("🤖 Checking AI-powered actions...")
        
        ai_actions = [
            ".github/actions/ai-code-analysis/action.yml",
            ".github/actions/deployment-strategy/action.yml"
        ]
        
        for action in ai_actions:
            path = self.project_path / action
            if path.exists():
                print(f"  ✅ Found {action}")
                
                # Validate action structure
                try:
                    with open(path) as f:
                        action_def = yaml.safe_load(f)
                        
                    if 'inputs' in action_def and 'outputs' in action_def:
                        print(f"    ✓ Valid action structure")
                    else:
                        self.warnings.append(f"{action} missing inputs or outputs")
                        
                except Exception as e:
                    self.errors.append(f"Error parsing {action}: {e}")
            else:
                self.errors.append(f"Missing AI action: {action}")
    
    def check_enterprise_workflow(self):
        """Check enterprise pipeline workflow."""
        print("\n🏢 Checking enterprise workflow...")
        
        workflow_path = self.project_path / ".github/workflows/enterprise-pipeline.yml"
        if not workflow_path.exists():
            self.errors.append("Enterprise pipeline workflow not found")
            return
            
        try:
            with open(workflow_path) as f:
                workflow = yaml.safe_load(f)
                
            jobs = workflow.get('jobs', {})
            
            ai_jobs = [
                'ai-analysis',
                'ai-test-generation',
                'intelligent-build',
                'deployment-strategy',
                'ai-monitoring'
            ]
            
            for job in ai_jobs:
                if job in jobs:
                    print(f"  ✅ Found AI job: {job}")
                else:
                    self.errors.append(f"Missing AI job: {job}")
                    
        except Exception as e:
            self.errors.append(f"Error parsing enterprise workflow: {e}")
    
    def check_ai_integration(self):
        """Check AI service integrations."""
        print("\n🔗 Checking AI integrations...")
        
        workflow_files = list((self.project_path / ".github/workflows").glob("*.yml"))
        
        ai_integrations = {
            "OPENAI_API_KEY": "OpenAI integration",
            "openai": "OpenAI SDK usage",
            "ai-analyze": "AI analysis implementation",
            "ai-monitor": "AI monitoring"
        }
        
        for workflow_file in workflow_files:
            content = workflow_file.read_text()
            
            for pattern, desc in ai_integrations.items():
                if pattern in content:
                    print(f"  ✅ Found {desc}")
    
    def check_monitoring_automation(self):
        """Check automated monitoring and response."""
        print("\n📊 Checking monitoring automation...")
        
        # Look for monitoring scripts or configurations
        monitoring_indicators = [
            "ai_monitor.py",
            "anomaly",
            "predict",
            "self-healing"
        ]
        
        found_monitoring = False
        
        for root, dirs, files in os.walk(self.project_path):
            for file in files:
                if file.endswith('.yml') or file.endswith('.py'):
                    file_path = Path(root) / file
                    content = file_path.read_text()
                    
                    for indicator in monitoring_indicators:
                        if indicator in content.lower():
                            found_monitoring = True
                            break
                            
        if found_monitoring:
            print("  ✅ Found monitoring automation")
        else:
            self.warnings.append("Consider adding automated monitoring")
    
    def check_cost_optimization(self):
        """Check cost optimization features."""
        print("\n💰 Checking cost optimization...")
        
        cost_indicators = [
            "cost",
            "optimization",
            "resource",
            "scaling"
        ]
        
        found_cost_opt = False
        
        workflow_files = list((self.project_path / ".github/workflows").glob("*.yml"))
        
        for workflow_file in workflow_files:
            content = workflow_file.read_text().lower()
            
            for indicator in cost_indicators:
                if indicator in content:
                    found_cost_opt = True
                    break
                    
        if found_cost_opt:
            print("  ✅ Found cost optimization features")
        else:
            self.warnings.append("Consider adding cost optimization")
    
    def print_results(self) -> bool:
        """Print validation results."""
        print("\n" + "="*50)
        print("VALIDATION RESULTS")
        print("="*50)
        
        if not self.errors and not self.warnings:
            print("\n✅ All validations passed! Exercise 3 is complete.")
            print("🏆 Outstanding work on the enterprise AI pipeline!")
            return True
            
        if self.errors:
            print(f"\n❌ Found {len(self.errors)} errors:")
            for error in self.errors:
                print(f"  - {error}")
                
        if self.warnings:
            print(f"\n⚠️  Found {len(self.warnings)} warnings:")
            for warning in self.warnings:
                print(f"  - {warning}")
                
        return len(self.errors) == 0


def main():
    validator = Exercise3Validator()
    success = validator.validate()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
```

## 🚀 Using the Validation Tests

### For Students

Run validation after completing each exercise:

```bash
# Validate Exercise 1
python tests/validate_exercise1.py

# Validate Exercise 2
python tests/validate_exercise2.py

# Validate Exercise 3
python tests/validate_exercise3.py

# Or run all validations
./tests/run_all_validations.sh
```

### For Instructors

Use these scripts to:
1. Automatically grade submissions
2. Provide consistent feedback
3. Track progress across students
4. Identify common issues

### Integration with CI/CD

Add validation to your workflow:

```yaml
- name: Validate exercises
  run: |
    chmod +x tests/run_all_validations.sh
    ./tests/run_all_validations.sh
```

## 📊 Grading Rubric

| Component | Exercise 1 | Exercise 2 | Exercise 3 |
|-----------|------------|------------|------------|
| File Structure | 10% | 10% | 10% |
| Workflow Implementation | 30% | 25% | 20% |
| Code Quality | 20% | 20% | 20% |
| Testing | 20% | 15% | 15% |
| Advanced Features | 10% | 20% | 25% |
| Documentation | 10% | 10% | 10% |

## 🎯 Success Metrics

- **Exercise 1**: Basic CI/CD pipeline working
- **Exercise 2**: Multi-environment deployment functional
- **Exercise 3**: AI integration demonstrable