#!/bin/bash

# Exercise 1: Todo App Setup Script
# This script sets up the development environment for the AI-powered todo application

set -e  # Exit on error

echo "🚀 Setting up Exercise 1: AI-Powered Todo Application"
echo "=================================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check prerequisites
echo -e "\n📋 Checking prerequisites..."

if ! command_exists python3; then
    print_error "Python 3 is not installed. Please install Python 3.11 or higher."
    exit 1
else
    print_status "Python 3 found: $(python3 --version)"
fi

if ! command_exists node; then
    print_error "Node.js is not installed. Please install Node.js 18 or higher."
    exit 1
else
    print_status "Node.js found: $(node --version)"
fi

if ! command_exists npm; then
    print_error "npm is not installed. Please install npm."
    exit 1
else
    print_status "npm found: $(npm --version)"
fi

# Create project structure
echo -e "\n📁 Creating project structure..."

# Create directories
mkdir -p backend/{app,tests}
mkdir -p frontend
mkdir -p tests/{backend,frontend}

print_status "Project structure created"

# Setup Backend
echo -e "\n🔧 Setting up Backend..."

cd backend

# Create virtual environment
if [ ! -d "venv" ]; then
    python3 -m venv venv
    print_status "Virtual environment created"
else
    print_warning "Virtual environment already exists"
fi

# Activate virtual environment
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    source venv/Scripts/activate
else
    source venv/bin/activate
fi

# Create requirements.txt
cat > requirements.txt << EOL
fastapi==0.104.1
uvicorn[standard]==0.24.0
sqlalchemy==2.0.23
pydantic==2.5.0
python-multipart==0.0.6
aiofiles==23.2.1
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
pytest==7.4.3
httpx==0.25.2
EOL

# Install dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt
print_status "Backend dependencies installed"

# Create __init__.py files
touch app/__init__.py
touch tests/__init__.py

# Go back to exercise root
cd ..

# Setup Frontend
echo -e "\n🎨 Setting up Frontend..."

# Create Vite React app if frontend directory is empty
if [ -z "$(ls -A frontend)" ]; then
    npm create vite@latest frontend -- --template react-ts -y
    print_status "React TypeScript app created"
else
    print_warning "Frontend directory not empty, skipping Vite setup"
fi

cd frontend

# Install dependencies
echo "Installing frontend dependencies..."
npm install

# Install additional packages
npm install axios @tanstack/react-query
npm install -D @types/react @types/react-dom @tanstack/react-query-devtools

# Install and configure Tailwind CSS
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p

print_status "Frontend dependencies installed"

# Create API directory
mkdir -p src/api
mkdir -p src/components

# Update Tailwind config
cat > tailwind.config.js << 'EOL'
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#eff6ff',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
        }
      },
      animation: {
        'fade-in': 'fadeIn 0.3s ease-in-out',
        'slide-up': 'slideUp 0.3s ease-out',
      }
    },
  },
  plugins: [],
}
EOL

# Update index.css
cat > src/index.css << EOL
@tailwind base;
@tailwind components;
@tailwind utilities;
EOL

print_status "Tailwind CSS configured"

# Go back to exercise root
cd ..

# Create test structure
echo -e "\n🧪 Setting up test structure..."

# Backend tests
cat > tests/backend/test_todos.py << 'EOL'
import pytest
from fastapi.testclient import TestClient
from backend.app.main import app

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Todo API is running!"}

def test_create_todo():
    response = client.post(
        "/todos",
        json={"title": "Test Todo", "description": "Test Description"}
    )
    assert response.status_code == 201
    assert response.json()["title"] == "Test Todo"
EOL

# Frontend test placeholder
cat > tests/frontend/README.md << EOL
# Frontend Tests

Frontend tests will be added as you build components.
Use React Testing Library and Jest for testing.
EOL

print_status "Test structure created"

# Create run scripts
echo -e "\n📝 Creating utility scripts..."

# Backend run script
cat > run-backend.sh << 'EOL'
#!/bin/bash
cd backend
source venv/bin/activate || source venv/Scripts/activate
python run.py
EOL

# Frontend run script
cat > run-frontend.sh << 'EOL'
#!/bin/bash
cd frontend
npm run dev
EOL

# Test script
cat > run-tests.sh << 'EOL'
#!/bin/bash
echo "Running backend tests..."
cd backend
source venv/bin/activate || source venv/Scripts/activate
pytest ../tests/backend -v

echo -e "\nRunning frontend tests..."
cd ../frontend
npm test -- --run
EOL

# Make scripts executable
chmod +x run-backend.sh run-frontend.sh run-tests.sh

print_status "Utility scripts created"

# Create starter files
echo -e "\n📄 Creating starter files..."

# Backend starter files
mkdir -p starter/backend/app
cat > starter/backend/app/models.py << 'EOL'
# TODO: Create SQLAlchemy models for todo application
# Hint: Use the Copilot prompt from the instructions
EOL

cat > starter/backend/app/schemas.py << 'EOL'
# TODO: Create Pydantic schemas for todo operations
# Hint: Use the Copilot prompt from the instructions
EOL

cat > starter/backend/app/main.py << 'EOL'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Todo API", version="1.0.0")

# TODO: Configure CORS middleware
# TODO: Add todo endpoints

@app.get("/")
def read_root():
    return {"message": "Todo API is running!"}
EOL

# Frontend starter files
mkdir -p starter/frontend/src/{api,components}
cat > starter/frontend/src/api/todoApi.ts << 'EOL'
// TODO: Create TypeScript API client for todo operations
// Hint: Use the Copilot prompt from the instructions
EOL

print_status "Starter files created"

# Final summary
echo -e "\n✅ Setup Complete!"
echo "=================="
echo -e "${GREEN}All dependencies installed and project structure created.${NC}"
echo -e "\nNext steps:"
echo "1. Open the project in VS Code: code ."
echo "2. Start the backend: ./run-backend.sh"
echo "3. Start the frontend: ./run-frontend.sh"
echo "4. Follow the instructions in the exercise guide"
echo -e "\n${YELLOW}Happy coding! 🚀${NC}"
