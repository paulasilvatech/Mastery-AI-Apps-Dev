#!/bin/bash

# ========================================================================
# Mastery AI Apps and Development Workshop - Prerequisites Validator
# ========================================================================
# This script validates all prerequisites for the workshop
# ========================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Requirements
MIN_PYTHON_VERSION="3.11"
MIN_NODE_VERSION="18"
MIN_DOTNET_VERSION="8"
MIN_DOCKER_VERSION="24"
MIN_GIT_VERSION="2.38"
MIN_RAM_GB=16
MIN_DISK_GB=100

# Functions
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_test() {
    printf "%-50s" "$1"
}

pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED++))
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARNINGS++))
}

check_command() {
    local cmd=$1
    print_test "Checking $cmd..."
    
    if command -v $cmd &> /dev/null; then
        pass "Found"
        return 0
    else
        fail "Not found"
        return 1
    fi
}

check_version() {
    local name=$1
    local current=$2
    local required=$3
    local compare_type=${4:-"ge"} # ge = greater or equal, eq = equal
    
    print_test "Checking $name version..."
    
    if [[ -z "$current" ]]; then
        fail "Could not determine version"
        return 1
    fi
    
    # Extract major.minor for comparison
    current_major=$(echo $current | cut -d. -f1)
    current_minor=$(echo $current | cut -d. -f2)
    required_major=$(echo $required | cut -d. -f1)
    required_minor=$(echo $required | cut -d. -f2)
    
    current_num=$((current_major * 100 + current_minor))
    required_num=$((required_major * 100 + required_minor))
    
    case $compare_type in
        "ge")
            if [[ $current_num -ge $required_num ]]; then
                pass "$current (>= $required)"
                return 0
            else
                fail "$current (requires >= $required)"
                return 1
            fi
            ;;
        "eq")
            if [[ "$current" == "$required" ]]; then
                pass "$current"
                return 0
            else
                fail "$current (requires $required)"
                return 1
            fi
            ;;
    esac
}

check_os() {
    print_header "Operating System"
    print_test "Checking OS..."
    
    case "$OSTYPE" in
        linux-gnu*)
            pass "Linux"
            check_linux_distro
            ;;
        darwin*)
            pass "macOS"
            check_macos_version
            ;;
        msys*|cygwin*)
            pass "Windows (WSL/Git Bash)"
            warn "Native Windows detected. WSL2 is recommended for best compatibility"
            ;;
        *)
            fail "Unknown OS: $OSTYPE"
            ;;
    esac
}

check_linux_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        print_test "Linux distribution..."
        pass "$NAME $VERSION"
    fi
}

check_macos_version() {
    print_test "macOS version..."
    version=$(sw_vers -productVersion)
    major=$(echo $version | cut -d. -f1)
    
    if [[ $major -ge 12 ]]; then
        pass "$version"
    else
        fail "$version (requires macOS 12 Monterey or later)"
    fi
}

check_hardware() {
    print_header "Hardware Requirements"
    
    # CPU cores
    print_test "CPU cores..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        cores=$(sysctl -n hw.logicalcpu)
    else
        cores=$(nproc)
    fi
    
    if [[ $cores -ge 4 ]]; then
        pass "$cores cores"
    else
        fail "$cores cores (minimum 4 required)"
    fi
    
    # RAM
    print_test "RAM..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ram_bytes=$(sysctl -n hw.memsize)
        ram_gb=$((ram_bytes / 1024 / 1024 / 1024))
    else
        ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        ram_gb=$((ram_kb / 1024 / 1024))
    fi
    
    if [[ $ram_gb -ge $MIN_RAM_GB ]]; then
        pass "${ram_gb}GB"
    else
        warn "${ram_gb}GB (recommended ${MIN_RAM_GB}GB minimum)"
    fi
    
    # Disk space
    print_test "Available disk space..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        disk_gb=$(df -g . | awk 'NR==2 {print $4}')
    else
        disk_gb=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    fi
    
    if [[ $disk_gb -ge $MIN_DISK_GB ]]; then
        pass "${disk_gb}GB available"
    else
        fail "${disk_gb}GB available (minimum ${MIN_DISK_GB}GB required)"
    fi
}

check_git() {
    print_header "Git"
    
    if check_command git; then
        version=$(git --version | awk '{print $3}')
        check_version "Git" "$version" "$MIN_GIT_VERSION"
        
        # Check git config
        print_test "Git user configuration..."
        if [[ -n $(git config --global user.name) ]] && [[ -n $(git config --global user.email) ]]; then
            pass "Configured"
        else
            warn "Not configured (run git config --global user.name/email)"
        fi
    fi
}

check_python() {
    print_header "Python"
    
    # Try different Python commands
    for cmd in python3 python; do
        if command -v $cmd &> /dev/null; then
            version=$($cmd --version 2>&1 | awk '{print $2}')
            if check_version "Python" "$version" "$MIN_PYTHON_VERSION"; then
                # Check pip
                print_test "Checking pip..."
                if $cmd -m pip --version &> /dev/null; then
                    pass "Available"
                else
                    fail "Not available"
                fi
                
                # Check venv
                print_test "Checking venv module..."
                if $cmd -m venv --help &> /dev/null; then
                    pass "Available"
                else
                    fail "Not available"
                fi
                
                return 0
            fi
        fi
    done
    
    fail "Python $MIN_PYTHON_VERSION+ not found"
}

check_node() {
    print_header "Node.js"
    
    if check_command node; then
        version=$(node --version | sed 's/v//')
        check_version "Node.js" "$version" "$MIN_NODE_VERSION"
        
        # Check npm
        print_test "Checking npm..."
        if command -v npm &> /dev/null; then
            npm_version=$(npm --version)
            pass "v$npm_version"
        else
            fail "Not found"
        fi
    fi
}

check_dotnet() {
    print_header ".NET SDK"
    
    if check_command dotnet; then
        # Get the latest SDK version
        version=$(dotnet --list-sdks | tail -1 | awk '{print $1}' | cut -d. -f1)
        
        print_test "Checking .NET SDK version..."
        if [[ $version -ge $MIN_DOTNET_VERSION ]]; then
            pass "SDK $version.x"
        else
            fail "SDK $version.x (requires $MIN_DOTNET_VERSION.x)"
        fi
        
        # Check workloads
        print_test "Checking .NET workloads..."
        if dotnet workload list &> /dev/null; then
            pass "Available"
        else
            warn "Could not check workloads"
        fi
    fi
}

check_docker() {
    print_header "Docker"
    
    if check_command docker; then
        version=$(docker --version | awk '{print $3}' | sed 's/,//')
        check_version "Docker" "$version" "$MIN_DOCKER_VERSION"
        
        # Check if Docker daemon is running
        print_test "Docker daemon status..."
        if docker info &> /dev/null; then
            pass "Running"
            
            # Check Docker Compose
            print_test "Docker Compose..."
            if docker compose version &> /dev/null; then
                pass "Available"
            else
                warn "Not available (docker compose)"
            fi
        else
            fail "Not running (start Docker Desktop)"
        fi
    fi
}

check_azure_cli() {
    print_header "Azure CLI"
    
    if check_command az; then
        version=$(az --version | grep "azure-cli" | awk '{print $2}')
        pass "v$version"
        
        # Check if logged in
        print_test "Azure authentication..."
        if az account show &> /dev/null; then
            subscription=$(az account show --query name -o tsv)
            pass "Logged in ($subscription)"
        else
            warn "Not logged in (run 'az login')"
        fi
    else
        warn "Not installed (optional but recommended)"
    fi
}

check_github_cli() {
    print_header "GitHub CLI"
    
    if check_command gh; then
        version=$(gh --version | grep "gh version" | awk '{print $3}')
        pass "v$version"
        
        # Check authentication
        print_test "GitHub authentication..."
        if gh auth status &> /dev/null; then
            pass "Authenticated"
            
            # Check Copilot
            print_test "GitHub Copilot status..."
            if gh copilot status &> /dev/null; then
                pass "Active"
            else
                warn "Not active (subscription required)"
            fi
        else
            warn "Not authenticated (run 'gh auth login')"
        fi
    else
        warn "Not installed (optional but recommended)"
    fi
}

check_vscode() {
    print_header "VS Code"
    
    if check_command code; then
        version=$(code --version | head -1)
        pass "v$version"
        
        # Check extensions
        print_test "GitHub Copilot extension..."
        if code --list-extensions | grep -q "GitHub.copilot"; then
            pass "Installed"
        else
            warn "Not installed"
        fi
        
        print_test "Python extension..."
        if code --list-extensions | grep -q "ms-python.python"; then
            pass "Installed"
        else
            warn "Not installed"
        fi
    else
        warn "Not found in PATH (install from https://code.visualstudio.com)"
    fi
}

check_network() {
    print_header "Network Connectivity"
    
    # Check internet connection
    print_test "Internet connection..."
    if ping -c 1 github.com &> /dev/null; then
        pass "Connected"
    else
        fail "No internet connection"
    fi
    
    # Check GitHub access
    print_test "GitHub access..."
    if curl -s https://api.github.com &> /dev/null; then
        pass "Accessible"
    else
        fail "Cannot reach GitHub"
    fi
    
    # Check Azure endpoints
    print_test "Azure endpoints..."
    if curl -s https://management.azure.com &> /dev/null; then
        pass "Accessible"
    else
        warn "Cannot reach Azure (may need authentication)"
    fi
}

check_workshop_structure() {
    print_header "Workshop Structure"
    
    # Check if we're in the right directory
    print_test "Workshop repository..."
    if [[ -f "README.md" ]] && [[ -d "modules" ]]; then
        pass "Found"
        
        # Count modules
        print_test "Module directories..."
        module_count=$(ls -d modules/module-* 2>/dev/null | wc -l)
        if [[ $module_count -eq 30 ]]; then
            pass "All 30 modules present"
        else
            warn "Found $module_count/30 modules"
        fi
    else
        fail "Not in workshop root directory"
    fi
}

generate_report() {
    print_header "Validation Summary"
    
    echo -e "\n${GREEN}Passed:${NC} $PASSED"
    echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
    echo -e "${RED}Failed:${NC} $FAILED"
    
    if [[ $FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}✓ All critical requirements met!${NC}"
        echo -e "You're ready to start the workshop! 🚀"
        
        if [[ $WARNINGS -gt 0 ]]; then
            echo -e "\n${YELLOW}Note: You have some warnings. The workshop will work, but addressing these will improve your experience.${NC}"
        fi
        
        exit 0
    else
        echo -e "\n${RED}✗ Some critical requirements are not met.${NC}"
        echo -e "Please run ${YELLOW}./scripts/setup-workshop.sh${NC} to install missing components."
        exit 1
    fi
}

main() {
    clear
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║   Mastery AI Apps and Development Workshop                  ║"
    echo "║              Prerequisites Validator                         ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Run all checks
    check_os
    check_hardware
    check_git
    check_python
    check_node
    check_dotnet
    check_docker
    check_azure_cli
    check_github_cli
    check_vscode
    check_network
    check_workshop_structure
    
    # Generate report
    generate_report
}

# Run main function
main
