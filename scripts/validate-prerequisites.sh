#!/bin/bash

# Mastery AI Code Development Workshop - Prerequisites Validation Script
# This script validates that all prerequisites are met for the workshop

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REQUIRED_TOOLS=("git" "node" "python3" "docker" "az" "code")
REQUIRED_PYTHON_PACKAGES=("requests" "azure-identity" "azure-keyvault" "fastapi" "pytest")
REQUIRED_NODE_PACKAGES=("typescript" "express")
REQUIRED_VSCODE_EXTENSIONS=("github.copilot" "ms-python.python" "ms-azuretools.vscode-azurefunctions")

# Status tracking
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Functions for colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    WARNING_CHECKS=$((WARNING_CHECKS + 1))
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
}

increment_total() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get version
get_version() {
    local cmd=$1
    case $cmd in
        "git")
            git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
            ;;
        "node")
            node --version | sed 's/v//' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
            ;;
        "python3")
            python3 --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
            ;;
        "docker")
            docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
            ;;
        "az")
            az version --output tsv 2>/dev/null | grep azure-cli | cut -f2 || echo "unknown"
            ;;
        "code")
            code --version 2>/dev/null | head -1 || echo "unknown"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Function to compare versions (returns 0 if version1 >= version2)
version_compare() {
    local version1=$1
    local version2=$2
    
    # Convert versions to comparable format
    v1=$(echo "$version1" | tr '.' ' ' | awk '{printf "%03d%03d%03d", $1, $2, $3}' 2>/dev/null || echo "000000000")
    v2=$(echo "$version2" | tr '.' ' ' | awk '{printf "%03d%03d%03d", $1, $2, $3}' 2>/dev/null || echo "000000000")
    
    [ "$v1" -ge "$v2" ]
}

# Check system requirements
check_system_requirements() {
    print_status "Checking system requirements..."
    
    # Check OS
    increment_total
    case "$(uname -s)" in
        Linux*)
            print_success "Operating System: Linux (Supported)"
            ;;
        Darwin*)
            print_success "Operating System: macOS (Supported)"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            print_success "Operating System: Windows (Supported)"
            ;;
        *)
            print_warning "Operating System: Unknown (May have compatibility issues)"
            ;;
    esac
    
    # Check RAM (Linux/macOS only)
    increment_total
    if command_exists "free"; then
        # Linux
        local ram_mb=$(free -m | awk 'NR==2{printf "%.0f", $2}')
        if [ "$ram_mb" -ge 16384 ]; then
            print_success "RAM: ${ram_mb}MB (Sufficient)"
        elif [ "$ram_mb" -ge 8192 ]; then
            print_warning "RAM: ${ram_mb}MB (Minimum, 16GB recommended)"
        else
            print_error "RAM: ${ram_mb}MB (Insufficient, 16GB required)"
        fi
    elif command_exists "system_profiler"; then
        # macOS
        local ram_gb=$(system_profiler SPHardwareDataType | grep "Memory:" | awk '{print $2}')
        if [ "$ram_gb" -ge 16 ]; then
            print_success "RAM: ${ram_gb}GB (Sufficient)"
        elif [ "$ram_gb" -ge 8 ]; then
            print_warning "RAM: ${ram_gb}GB (Minimum, 16GB recommended)"
        else
            print_error "RAM: ${ram_gb}GB (Insufficient, 16GB required)"
        fi
    else
        print_warning "RAM: Cannot detect (Please ensure you have at least 16GB)"
    fi
    
    # Check disk space
    increment_total
    local available_gb=$(df . | awk 'NR==2 {printf "%.0f", $4/1048576}')
    if [ "$available_gb" -ge 100 ]; then
        print_success "Disk Space: ${available_gb}GB available (Sufficient)"
    elif [ "$available_gb" -ge 50 ]; then
        print_warning "Disk Space: ${available_gb}GB available (Minimum, 100GB recommended)"
    else
        print_error "Disk Space: ${available_gb}GB available (Insufficient, 100GB required)"
    fi
}

# Check required tools
check_required_tools() {
    print_status "Checking required tools..."
    
    local requirements=(
        "git:2.38.0"
        "node:18.0.0"
        "python3:3.11.0"
        "docker:24.0.0"
        "az:2.50.0"
        "code:1.80.0"
    )
    
    for requirement in "${requirements[@]}"; do
        local tool=$(echo "$requirement" | cut -d':' -f1)
        local min_version=$(echo "$requirement" | cut -d':' -f2)
        
        increment_total
        if command_exists "$tool"; then
            local current_version=$(get_version "$tool")
            if [ "$current_version" = "unknown" ]; then
                print_warning "$tool is installed but version cannot be determined"
            elif version_compare "$current_version" "$min_version"; then
                print_success "$tool $current_version (>= $min_version required)"
            else
                print_error "$tool $current_version (< $min_version required)"
            fi
        else
            print_error "$tool is not installed"
        fi
    done
}

# Check Python environment
check_python_environment() {
    print_status "Checking Python environment..."
    
    # Check Python virtual environment
    increment_total
    if [ -d "venv" ]; then
        print_success "Python virtual environment exists"
        
        # Check if can activate
        increment_total
        if source venv/bin/activate 2>/dev/null; then
            print_success "Virtual environment can be activated"
            
            # Check pip
            increment_total
            if command_exists "pip"; then
                local pip_version=$(pip --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
                print_success "pip $pip_version is available"
            else
                print_error "pip is not available in virtual environment"
            fi
            
            # Check required packages
            for package in "${REQUIRED_PYTHON_PACKAGES[@]}"; do
                increment_total
                if pip show "$package" >/dev/null 2>&1; then
                    local pkg_version=$(pip show "$package" | grep Version | cut -d' ' -f2)
                    print_success "Python package: $package $pkg_version"
                else
                    print_warning "Python package: $package (not installed)"
                fi
            done
            
            deactivate 2>/dev/null || true
        else
            print_error "Cannot activate virtual environment"
        fi
    else
        print_warning "Python virtual environment not found (run setup-workshop.sh)"
    fi
}

# Check Node.js environment
check_nodejs_environment() {
    print_status "Checking Node.js environment..."
    
    # Check package.json
    increment_total
    if [ -f "package.json" ]; then
        print_success "package.json exists"
        
        # Check node_modules
        increment_total
        if [ -d "node_modules" ]; then
            print_success "node_modules directory exists"
            
            # Check required packages
            for package in "${REQUIRED_NODE_PACKAGES[@]}"; do
                increment_total
                if [ -d "node_modules/$package" ] || npm list "$package" >/dev/null 2>&1; then
                    print_success "Node.js package: $package"
                else
                    print_warning "Node.js package: $package (not installed)"
                fi
            done
        else
            print_warning "node_modules not found (run npm install)"
        fi
    else
        print_warning "package.json not found (run setup-workshop.sh)"
    fi
}

# Check Docker environment
check_docker_environment() {
    print_status "Checking Docker environment..."
    
    # Check if Docker is running
    increment_total
    if docker info >/dev/null 2>&1; then
        print_success "Docker daemon is running"
        
        # Check Docker version
        increment_total
        local docker_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if version_compare "$docker_version" "24.0.0"; then
            print_success "Docker version $docker_version is sufficient"
        else
            print_warning "Docker version $docker_version (24.0.0+ recommended)"
        fi
        
        # Check basic functionality
        increment_total
        if docker run --rm hello-world >/dev/null 2>&1; then
            print_success "Docker can run containers"
        else
            print_error "Docker cannot run containers"
        fi
        
        # Check available images
        increment_total
        local common_images=("python:3.11-slim" "node:18-alpine")
        local images_found=0
        for image in "${common_images[@]}"; do
            if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "$image"; then
                images_found=$((images_found + 1))
            fi
        done
        
        if [ $images_found -gt 0 ]; then
            print_success "Docker has $images_found common workshop images"
        else
            print_warning "No common workshop images found (will be downloaded as needed)"
        fi
    else
        print_error "Docker daemon is not running"
    fi
}

# Check VS Code and extensions
check_vscode_environment() {
    print_status "Checking VS Code environment..."
    
    # Check if VS Code is installed
    increment_total
    if command_exists "code"; then
        print_success "VS Code is installed"
        
        # Check extensions
        for extension in "${REQUIRED_VSCODE_EXTENSIONS[@]}"; do
            increment_total
            if code --list-extensions | grep -q "$extension"; then
                print_success "VS Code extension: $extension"
            else
                print_warning "VS Code extension: $extension (not installed)"
            fi
        done
        
        # Check workspace settings
        increment_total
        if [ -f ".vscode/settings.json" ]; then
            print_success "VS Code workspace settings exist"
        else
            print_warning "VS Code workspace settings not found"
        fi
        
    else
        print_error "VS Code is not installed or not in PATH"
    fi
}

# Check Azure environment
check_azure_environment() {
    print_status "Checking Azure environment..."
    
    # Check Azure CLI authentication
    increment_total
    if az account show >/dev/null 2>&1; then
        local subscription=$(az account show --query name -o tsv)
        print_success "Authenticated with Azure subscription: $subscription"
        
        # Check required providers
        local providers=("Microsoft.CognitiveServices" "Microsoft.Web" "Microsoft.ContainerService" "Microsoft.Storage")
        for provider in "${providers[@]}"; do
            increment_total
            local state=$(az provider show --namespace "$provider" --query registrationState -o tsv 2>/dev/null || echo "Unknown")
            if [ "$state" = "Registered" ]; then
                print_success "Azure provider: $provider (Registered)"
            else
                print_warning "Azure provider: $provider ($state)"
            fi
        done
        
    else
        print_error "Not authenticated with Azure CLI"
    fi
}

# Check GitHub environment
check_github_environment() {
    print_status "Checking GitHub environment..."
    
    # Check GitHub CLI
    increment_total
    if command_exists "gh"; then
        if gh auth status >/dev/null 2>&1; then
            local user=$(gh api user --jq .login 2>/dev/null || echo "unknown")
            print_success "Authenticated with GitHub as: $user"
            
            # Check Copilot subscription
            increment_total
            if gh copilot status >/dev/null 2>&1; then
                print_success "GitHub Copilot is available"
            else
                print_warning "GitHub Copilot status unclear or not available"
            fi
        else
            print_warning "GitHub CLI is installed but not authenticated"
        fi
    else
        print_warning "GitHub CLI not installed (optional)"
    fi
    
    # Check git configuration
    increment_total
    if git config user.name >/dev/null && git config user.email >/dev/null; then
        local name=$(git config user.name)
        local email=$(git config user.email)
        print_success "Git configured: $name <$email>"
    else
        print_error "Git user name/email not configured"
    fi
}

# Check network connectivity
check_network_connectivity() {
    print_status "Checking network connectivity..."
    
    local endpoints=(
        "github.com:443"
        "api.github.com:443"
        "management.azure.com:443"
        "pypi.org:443"
        "registry.npmjs.org:443"
        "hub.docker.com:443"
    )
    
    for endpoint in "${endpoints[@]}"; do
        increment_total
        local host=$(echo "$endpoint" | cut -d':' -f1)
        local port=$(echo "$endpoint" | cut -d':' -f2)
        
        if command_exists "nc"; then
            if nc -z "$host" "$port" >/dev/null 2>&1; then
                print_success "Network: $host:$port (accessible)"
            else
                print_error "Network: $host:$port (not accessible)"
            fi
        elif command_exists "telnet"; then
            if timeout 5 telnet "$host" "$port" >/dev/null 2>&1; then
                print_success "Network: $host:$port (accessible)"
            else
                print_error "Network: $host:$port (not accessible)"
            fi
        else
            print_warning "Network: Cannot test $host:$port (no nc/telnet)"
        fi
    done
}

# Generate report
generate_report() {
    echo
    print_status "Validation Summary:"
    echo "===================="
    echo "Total Checks: $TOTAL_CHECKS"
    echo "Passed: $PASSED_CHECKS"
    echo "Warnings: $WARNING_CHECKS" 
    echo "Failed: $FAILED_CHECKS"
    echo
    
    local success_rate=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    
    if [ $FAILED_CHECKS -eq 0 ]; then
        if [ $WARNING_CHECKS -eq 0 ]; then
            print_success "All validations passed! You're ready for the workshop! 🎉"
        else
            print_warning "Validations passed with $WARNING_CHECKS warning(s). You can proceed but consider addressing warnings."
        fi
        return 0
    else
        print_error "Validation failed with $FAILED_CHECKS error(s). Please address these issues before starting the workshop."
        echo
        print_status "Common solutions:"
        echo "• Run: ./scripts/setup-workshop.sh"
        echo "• Check: TROUBLESHOOTING.md"
        echo "• Install missing tools from PREREQUISITES.md"
        return 1
    fi
}

# Main execution
main() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║         🔍 Workshop Prerequisites Validation 🔍                  ║
║                                                                  ║
║   Checking if your system is ready for the AI Workshop          ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    check_system_requirements
    check_required_tools
    check_python_environment
    check_nodejs_environment
    check_docker_environment
    check_vscode_environment
    check_azure_environment
    check_github_environment
    check_network_connectivity
    
    generate_report
}

# Run main function
main "$@"
