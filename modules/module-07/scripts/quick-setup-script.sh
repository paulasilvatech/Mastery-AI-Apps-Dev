#!/bin/bash
# Module 07: Quick Setup Script
# Sets up the development environment for all exercises

set -e

echo "🚀 Module 07 Quick Setup"
echo "======================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get the module root directory
MODULE_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

echo ""
echo -e "${BLUE}Setting up Module 07 environment...${NC}"

# Function to setup Python environment
setup_python_env() {
    local dir=$1
    echo -e "${BLUE}Setting up Python environment in $dir${NC}"
    
    cd "$dir"
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        python3 -m venv venv
        echo "✓ Created virtual environment"
    fi
    
    # Activate and install dependencies
    source venv/bin/activate 2>/dev/null || . venv/Scripts/activate 2>/dev/null
    
    if [ -f "requirements.txt" ]; then
        pip install --upgrade pip
        pip install -r requirements.txt
        echo "✓ Installed Python dependencies"
    fi
    
    deactivate
}

# Function to setup Node environment
setup_node_env() {
    local dir=$1
    echo -e "${BLUE}Setting up Node environment in $dir${NC}"
    
    cd "$dir"
    
    # Install dependencies
    if [ -f "package.json" ]; then
        # Use pnpm if available, otherwise npm
        if command -v pnpm &> /dev/null; then
            pnpm install
        else
            npm install
        fi
        echo "✓ Installed Node dependencies"
    fi
}

# 1. Create base requirements file if not exists
echo ""
echo "1. Creating base configuration files..."
cd "$MODULE_ROOT"

if [ ! -f "requirements-base.txt" ]; then
    cat > requirements-base.txt << EOF
# Core dependencies for all exercises
fastapi==0.104.1
uvicorn[standard]==0.24.0
sqlalchemy==2.0.23
pydantic==2.5.0
python-multipart==0.0.6
aiofiles==23.2.1
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
httpx==0.25.2
pytest==7.4.3
pytest-asyncio==0.21.1
EOF
    echo "✓ Created requirements-base.txt"
fi

# 2. Setup Exercise 1: Todo App
echo ""
echo "2. Setting up Exercise 1: Todo App..."
EXERCISE1_DIR="$MODULE_ROOT/exercises/exercise1-todo-app"

if [ -d "$EXERCISE1_DIR" ]; then
    # Backend setup
    if [ -d "$EXERCISE1_DIR/backend" ]; then
        setup_python_env "$EXERCISE1_DIR/backend"
    fi
    
    # Frontend setup
    if [ -d "$EXERCISE1_DIR/frontend" ]; then
        setup_node_env "$EXERCISE1_DIR/frontend"
    fi
else
    echo -e "${YELLOW}⚠ Exercise 1 directory not found${NC}"
fi

# 3. Setup Exercise 2: Blog Platform
echo ""
echo "3. Setting up Exercise 2: Blog Platform..."
EXERCISE2_DIR="$MODULE_ROOT/exercises/exercise2-blog-platform"

if [ -d "$EXERCISE2_DIR" ]; then
    # Check if Docker Compose file exists
    if [ -f "$EXERCISE2_DIR/docker-compose.yml" ]; then
        echo "✓ Docker Compose file found"
        cd "$EXERCISE2_DIR"
        
        # Pull required images
        echo "Pulling Docker images..."
        docker-compose pull
    fi
    
    # Backend setup
    if [ -d "$EXERCISE2_DIR/backend" ]; then
        setup_python_env "$EXERCISE2_DIR/backend"
    fi
    
    # Frontend setup
    if [ -d "$EXERCISE2_DIR/frontend" ]; then
        setup_node_env "$EXERCISE2_DIR/frontend"
    fi
else
    echo -e "${YELLOW}⚠ Exercise 2 directory not found${NC}"
fi

# 4. Setup Exercise 3: AI Dashboard
echo ""
echo "4. Setting up Exercise 3: AI Dashboard..."
EXERCISE3_DIR="$MODULE_ROOT/exercises/exercise3-ai-dashboard"

if [ -d "$EXERCISE3_DIR" ]; then
    # Infrastructure setup
    if [ -f "$EXERCISE3_DIR/docker-compose.yml" ]; then
        echo "✓ Docker Compose file found"
        cd "$EXERCISE3_DIR"
        
        # Create required directories
        mkdir -p data/{postgres,redis,influxdb}
        echo "✓ Created data directories"
        
        # Pull required images
        echo "Pulling Docker images..."
        docker-compose pull
    fi
    
    # Backend setup
    if [ -d "$EXERCISE3_DIR/backend" ]; then
        setup_python_env "$EXERCISE3_DIR/backend"
    fi
    
    # Frontend setup
    if [ -d "$EXERCISE3_DIR/frontend" ]; then
        setup_node_env "$EXERCISE3_DIR/frontend"
    fi
else
    echo -e "${YELLOW}⚠ Exercise 3 directory not found${NC}"
fi

# 5. Create useful aliases
echo ""
echo "5. Creating helpful commands..."

cat > "$MODULE_ROOT/module07-commands.sh" << 'EOF'
#!/bin/bash
# Module 07 Helper Commands

# Quick start commands for each exercise
alias