#!/bin/bash

# Module 01 Setup Script
# This script sets up the environment for Module 01

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Functions
log() {
    echo -e "${GREEN}[SETUP]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check Python version
check_python() {
    log "Checking Python installation..."
    
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
    else
        error "Python is not installed. Please install Python 3.11 or higher."
    fi
    
    # Check version
    PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | awk '{print $2}')
    MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
    MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
    
    if [ "$MAJOR" -lt 3 ] || ([ "$MAJOR" -eq 3 ] && [ "$MINOR" -lt 11 ]); then
        error "Python 3.11 or higher is required. Found: $PYTHON_VERSION"
    fi
    
    log "Python $PYTHON_VERSION found ✓"
}

# Check Git
check_git() {
    log "Checking Git installation..."
    
    if ! command -v git &> /dev/null; then
        error "Git is not installed. Please install Git."
    fi
    
    GIT_VERSION=$(git --version | awk '{print $3}')
    log "Git $GIT_VERSION found ✓"
}

# Check VS Code
check_vscode() {
    log "Checking VS Code installation..."
    
    if ! command -v code &> /dev/null; then
        warning "VS Code CLI not found. Make sure VS Code is installed and 'code' command is available."
        warning "You can add it from VS Code: Shell Command: Install 'code' command in PATH"
    else
        log "VS Code found ✓"
    fi
}

# Create directory structure
create_structure() {
    log "Creating module directory structure..."
    
    # Create main directories
    mkdir -p exercises/{exercise1-easy,exercise2-medium,exercise3-hard}
    mkdir -p project
    mkdir -p resources
    
    # Exercise 1 structure
    mkdir -p exercises/exercise1-easy/{instructions,starter,solution,tests,resources}
    
    # Exercise 2 structure
    mkdir -p exercises/exercise2-medium/{instructions,starter,solution,tests}
    mkdir -p exercises/exercise2-medium/starter/task_manager
    
    # Exercise 3 structure
    mkdir -p exercises/exercise3-hard/{instructions,starter,solution}
    mkdir -p exercises/exercise3-hard/starter/{backend,frontend,docker}
    mkdir -p exercises/exercise3-hard/starter/backend/app/{api,core,db,models}
    
    log "Directory structure created ✓"
}

# Create virtual environment
setup_venv() {
    log "Setting up Python virtual environment..."
    
    # Create venv
    $PYTHON_CMD -m venv venv
    
    # Activate venv
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        source venv/Scripts/activate
    else
        source venv/bin/activate
    fi
    
    log "Virtual environment created ✓"
}

# Install dependencies
install_dependencies() {
    log "Installing Python dependencies..."
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Core dependencies
    pip install pytest pytest-cov
    pip install black flake8 mypy
    pip install click rich
    pip install requests
    
    # Exercise 2 dependencies
    pip install python-dateutil
    
    # Exercise 3 dependencies
    pip install fastapi uvicorn[standard]
    pip install sqlalchemy aiosqlite asyncpg
    pip install python-jose[cryptography] passlib[bcrypt]
    pip install python-multipart email-validator
    pip install httpx pytest-asyncio
    
    log "Dependencies installed ✓"
}

# Create starter files
create_starter_files() {
    log "Creating starter files..."
    
    # Exercise 1 starter file
    cat > exercises/exercise1-easy/starter/utils.py << 'EOF'
"""
Utility Functions Library
A collection of helpful functions for common programming tasks.
"""

# Your code will go here
EOF

    # Exercise 1 test starter
    cat > exercises/exercise1-easy/starter/test_utils.py << 'EOF'
import pytest
# Import your functions here

# Write your tests here
EOF

    # Exercise 2 starter files
    cat > exercises/exercise2-medium/starter/task_manager/__init__.py << 'EOF'
"""Task Manager Package"""
__version__ = "1.0.0"
EOF

    # Create requirements.txt
    cat > requirements.txt << 'EOF'
# Core
pytest>=7.4.0
black>=23.11.0
flake8>=6.1.0
mypy>=1.7.1

# Exercise 1
click>=8.1.0
rich>=13.7.0
requests>=2.31.0

# Exercise 2
python-dateutil>=2.8.2

# Exercise 3
fastapi>=0.104.1
uvicorn[standard]>=0.24.0
sqlalchemy>=2.0.23
aiosqlite>=0.19.0
asyncpg>=0.29.0
python-jose[cryptography]>=3.3.0
passlib[bcrypt]>=1.7.4
python-multipart>=0.0.6
email-validator>=2.1.0
httpx>=0.25.1
pytest-asyncio>=0.21.1
EOF

    log "Starter files created ✓"
}

# Create validation script
create_validation_script() {
    log "Creating module validation script..."
    
    cat > validate_module.py << 'EOF'
#!/usr/bin/env python3
"""Module 01 Validation Script"""

import subprocess
import sys
from pathlib import Path

def check_structure():
    """Check if all required directories exist."""
    required_dirs = [
        "exercises/exercise1-easy",
        "exercises/exercise2-medium", 
        "exercises/exercise3-hard",
        "project",
        "resources"
    ]
    
    print("Checking directory structure...")
    all_exist = True
    
    for dir_path in required_dirs:
        if Path(dir_path).exists():
            print(f"✓ {dir_path}")
        else:
            print(f"✗ {dir_path} missing")
            all_exist = False
    
    return all_exist

def check_dependencies():
    """Check if required packages are installed."""
    required_packages = [
        "pytest",
        "click",
        "fastapi",
        "sqlalchemy"
    ]
    
    print("\nChecking Python packages...")
    all_installed = True
    
    for package in required_packages:
        try:
            __import__(package)
            print(f"✓ {package}")
        except ImportError:
            print(f"✗ {package} not installed")
            all_installed = False
    
    return all_installed

def main():
    """Run all validation checks."""
    print("Module 01 Environment Validation")
    print("=" * 40)
    
    structure_ok = check_structure()
    deps_ok = check_dependencies()
    
    print("\n" + "=" * 40)
    
    if structure_ok and deps_ok:
        print("✅ Module 01 environment is ready!")
        return 0
    else:
        print("❌ Some requirements are missing.")
        print("Run ./setup-module.sh to fix issues.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
EOF

    chmod +x validate_module.py
    log "Validation script created ✓"
}

# Create helpful scripts
create_helper_scripts() {
    log "Creating helper scripts..."
    
    # Create run script for Exercise 1
    cat > exercises/exercise1-easy/run.sh << 'EOF'
#!/bin/bash
echo "Running Exercise 1 tests..."
cd starter
python -m pytest test_utils.py -v
EOF
    chmod +x exercises/exercise1-easy/run.sh
    
    # Create run script for Exercise 2
    cat > exercises/exercise2-medium/run.sh << 'EOF'
#!/bin/bash
echo "Task Manager CLI"
cd starter
python task.py --help
EOF
    chmod +x exercises/exercise2-medium/run.sh
    
    log "Helper scripts created ✓"
}

# Main setup flow
main() {
    echo "🚀 Module 01 Environment Setup"
    echo "=============================="
    
    # Run checks
    check_python
    check_git
    check_vscode
    
    # Create environment
    create_structure
    setup_venv
    install_dependencies
    
    # Create files
    create_starter_files
    create_validation_script
    create_helper_scripts
    
    echo ""
    echo "✅ Module 01 setup complete!"
    echo ""
    echo "Next steps:"
    echo "1. Activate the virtual environment:"
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        echo "   source venv/Scripts/activate"
    else
        echo "   source venv/bin/activate"
    fi
    echo "2. Verify setup: python validate_module.py"
    echo "3. Open VS Code: code ."
    echo "4. Start with Exercise 1!"
}

# Run main function
main