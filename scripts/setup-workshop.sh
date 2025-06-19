#!/bin/bash

# Setup Workshop Script
set -e

echo "🚀 Setting up AI Code Development Workshop..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check command existence
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is not installed"
        return 1
    fi
}

# Function to check version
check_version() {
    local cmd=$1
    local version_flag=$2
    local required=$3
    
    if command -v $cmd &> /dev/null; then
        version=$($cmd $version_flag 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
        echo -e "${GREEN}✓${NC} $cmd version: $version (required: $required+)"
    fi
}

echo -e "\n${YELLOW}Checking prerequisites...${NC}"

# Check required tools
check_command git
check_version git --version 2.34

check_command node
check_version node --version 18

check_command python3
check_version python3 --version 3.9

check_command docker
check_command code || check_command cursor

echo -e "\n${YELLOW}Setting up project structure...${NC}"

# Create necessary directories if they don't exist
directories=(
    "scripts"
    "infrastructure/bicep/modules"
    "infrastructure/bicep/parameters"
    "infrastructure/terraform"
    "infrastructure/github-actions"
    "docs"
    "modules"
)

for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo -e "${GREEN}✓${NC} Created directory: $dir"
    fi
done

echo -e "\n${YELLOW}Installing dependencies...${NC}"

# Check for package.json and install npm dependencies
if [ -f "package.json" ]; then
    npm install
    echo -e "${GREEN}✓${NC} NPM dependencies installed"
fi

# Check for requirements.txt and install Python dependencies
if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt
    echo -e "${GREEN}✓${NC} Python dependencies installed"
fi

echo -e "\n${YELLOW}Setting up Git hooks...${NC}"

# Make scripts executable
chmod +x scripts/*.sh
echo -e "${GREEN}✓${NC} Scripts are now executable"

# Create git hooks directory if it doesn't exist
mkdir -p .git/hooks

# Create pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit hook for AI-assisted development

# Run linting
if command -v eslint &> /dev/null; then
    eslint . --ext .js,.jsx,.ts,.tsx
fi

# Run Python linting
if command -v pylint &> /dev/null; then
    pylint **/*.py
fi

# Check for sensitive data
if command -v gitleaks &> /dev/null; then
    gitleaks detect --source . -v
fi
EOF

chmod +x .git/hooks/pre-commit
echo -e "${GREEN}✓${NC} Git hooks configured"

echo -e "\n${YELLOW}Configuring AI tools...${NC}"

# Check for VS Code
if command -v code &> /dev/null; then
    echo -e "${GREEN}✓${NC} VS Code detected"
    # Install recommended extensions
    extensions=(
        "GitHub.copilot"
        "GitHub.copilot-chat"
        "ms-azuretools.vscode-docker"
        "ms-python.python"
        "dbaeumer.vscode-eslint"
        "esbenp.prettier-vscode"
    )
    
    for ext in "${extensions[@]}"; do
        code --install-extension $ext 2>/dev/null || true
    done
fi

# Check for Cursor
if command -v cursor &> /dev/null; then
    echo -e "${GREEN}✓${NC} Cursor IDE detected"
fi

echo -e "\n${YELLOW}Setting up module structure...${NC}"

# Create README for each module if it doesn't exist
for i in {01..30}; do
    module_dir="modules/Module-$i"
    if [ -d "$module_dir" ] && [ ! -f "$module_dir/README.md" ]; then
        echo "# Module $i" > "$module_dir/README.md"
        echo -e "${GREEN}✓${NC} Created README for Module-$i"
    fi
done

echo -e "\n${YELLOW}Final setup steps...${NC}"

# Create .env.example if it doesn't exist
if [ ! -f ".env.example" ]; then
    cat > .env.example << EOF
# AI Configuration
OPENAI_API_KEY=your_openai_key_here
ANTHROPIC_API_KEY=your_anthropic_key_here
GITHUB_TOKEN=your_github_token_here

# Azure Configuration
AZURE_SUBSCRIPTION_ID=your_subscription_id
AZURE_RESOURCE_GROUP=ai-workshop-rg
AZURE_LOCATION=eastus

# Workshop Settings
WORKSHOP_ENVIRONMENT=development
EOF
    echo -e "${GREEN}✓${NC} Created .env.example"
fi

echo -e "\n${GREEN}✅ Workshop setup complete!${NC}"
echo -e "\nNext steps:"
echo "1. Copy .env.example to .env and add your API keys"
echo "2. Run ./scripts/validate-prerequisites.sh to verify setup"
echo "3. Start with Module-01 in the modules directory"
echo -e "\nHappy coding! 🎉" 