#!/bin/bash
# Ultimate Mastery Challenge - Quick Start Script

echo "🚀 ULTIMATE MASTERY CHALLENGE - MODULE 30 🚀"
echo "==========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running in correct directory
if [ ! -f "challenge-ready.flag" ]; then
    echo -e "${RED}❌ Error: Not in challenge directory${NC}"
    echo "Please run this script from the module-30 directory"
    exit 1
fi

# Timer function
start_timer() {
    START_TIME=$(date +%s)
    echo -e "${GREEN}⏱️  Challenge Timer Started: $(date)${NC}"
    echo ""
}

# Create project structure
create_project_structure() {
    echo "📁 Creating project structure..."
    
    # Main project directory
    mkdir -p mastery-ed/{services,infrastructure,scripts,docs}
    
    # Service directories
    mkdir -p mastery-ed/services/{gateway,auth,course,ai,analytics}
    mkdir -p mastery-ed/services/agents/{tutor,content,assessment}
    mkdir -p mastery-ed/services/mcp-server
    
    # Infrastructure directories
    mkdir -p mastery-ed/infrastructure/{k8s,bicep,docker}
    mkdir -p mastery-ed/infrastructure/k8s/{deployments,services,configmaps}
    
    # Create initial files
    touch mastery-ed/README.md
    touch mastery-ed/.env.example
    touch mastery-ed/docker-compose.yml
    touch mastery-ed/requirements.txt
    
    echo -e "${GREEN}✅ Project structure created${NC}"
}

# Initialize Git repository
init_git() {
    echo "🔄 Initializing Git repository..."
    cd mastery-ed
    
    git init
    
    # Create .gitignore
    cat > .gitignore << EOF
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
.env

# Node
node_modules/
npm-debug.log*
dist/
.env.local

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Docker
.docker/

# Kubernetes
*.secret.yaml
EOF

    git add .
    git commit -m "Initial commit: Challenge setup"
    
    echo -e "${GREEN}✅ Git repository initialized${NC}"
    cd ..
}

# Create base templates
create_templates() {
    echo "📝 Creating starter templates..."
    
    # FastAPI main template
    cat > mastery-ed/services/gateway/main.py << 'EOF'
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

app = FastAPI(
    title="MasteryEd API Gateway",
    description="AI-Powered E-Learning Platform",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "Welcome to MasteryEd API", "status": "ready"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "api-gateway"}

# TODO: Add route handlers for microservices

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF

    # Docker Compose template
    cat > mastery-ed/docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: mastery
      POSTGRES_PASSWORD: mastery123
      POSTGRES_DB: mastery_ed
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  # TODO: Add service containers

volumes:
  postgres_data:
EOF

    # Requirements template
    cat > mastery-ed/requirements.txt << 'EOF'
# Core
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6

# Database
sqlalchemy==2.0.23
alembic==1.12.1
psycopg2-binary==2.9.9
redis==5.0.1

# AI/ML
openai==1.3.0
langchain==0.0.335
tiktoken==0.5.1

# Testing
pytest==7.4.3
pytest-asyncio==0.21.1
httpx==0.25.2

# Monitoring
opentelemetry-api==1.20.0
opentelemetry-instrumentation-fastapi==0.41b0

# Utils
python-dotenv==1.0.0
pydantic==2.5.0
EOF

    echo -e "${GREEN}✅ Starter templates created${NC}"
}

# Setup checklist
create_checklist() {
    echo "📋 Creating challenge checklist..."
    
    cat > mastery-ed/CHALLENGE_CHECKLIST.md << 'EOF'
# Ultimate Mastery Challenge Checklist

## Hour 1: Foundation (0-60 minutes)
- [ ] Project structure created
- [ ] Git repository initialized
- [ ] Database models defined
- [ ] API endpoints implemented (auth, courses, enrollments)
- [ ] WebSocket support added
- [ ] Basic tests written
- [ ] First commit completed

## Hour 2: Enterprise (60-120 minutes)
- [ ] Microservices separated
- [ ] Security implemented (JWT, RBAC)
- [ ] Azure resources deployed (or local alternative)
- [ ] Monitoring configured
- [ ] API Gateway working
- [ ] Services communicating
- [ ] Second commit completed

## Hour 3: AI & Integration (120-180 minutes)
- [ ] AI agents created
- [ ] MCP server running
- [ ] Agent orchestration working
- [ ] Final integration complete
- [ ] Documentation updated
- [ ] All tests passing
- [ ] Final commit completed

## Submission
- [ ] All code committed
- [ ] README.md complete
- [ ] Architecture documented
- [ ] Demo ready
- [ ] Repository link prepared
EOF

    echo -e "${GREEN}✅ Checklist created${NC}"
}

# Show helpful commands
show_commands() {
    echo ""
    echo "📚 QUICK REFERENCE COMMANDS:"
    echo "============================"
    echo ""
    echo "# Start services:"
    echo "cd mastery-ed && docker-compose up -d"
    echo ""
    echo "# Run API Gateway:"
    echo "cd services/gateway && uvicorn main:app --reload"
    echo ""
    echo "# Database migrations:"
    echo "alembic init alembic"
    echo "alembic revision --autogenerate -m 'Initial'"
    echo "alembic upgrade head"
    echo ""
    echo "# Run tests:"
    echo "pytest -v"
    echo ""
    echo "# Check service health:"
    echo "curl http://localhost:8000/health"
    echo ""
    echo "# Git commands:"
    echo "git add . && git commit -m 'Hour X complete: description'"
    echo ""
}

# Final message
show_final_message() {
    echo ""
    echo "🎯 CHALLENGE READY!"
    echo "=================="
    echo ""
    echo -e "${YELLOW}Remember:${NC}"
    echo "- Read ALL requirements first (10 min)"
    echo "- Commit every 30 minutes"
    echo "- Focus on working features over perfection"
    echo "- Use GitHub Copilot effectively"
    echo "- Document as you go"
    echo ""
    echo -e "${GREEN}Your workspace is ready at: ./mastery-ed${NC}"
    echo ""
    echo "Good luck! You've got this! 🚀"
    echo ""
}

# Main execution
main() {
    clear
    start_timer
    create_project_structure
    init_git
    create_templates
    create_checklist
    show_commands
    show_final_message
    
    # Create completion flag
    touch challenge-started.flag
    
    # Open VS Code if available
    if command -v code &> /dev/null; then
        echo "Opening VS Code..."
        code mastery-ed
    fi
}

# Confirmation prompt
echo -e "${YELLOW}⚠️  This will create a new project structure for the challenge.${NC}"
echo "Are you ready to begin? (yes/no)"
read -r response

if [[ "$response" == "yes" || "$response" == "y" ]]; then
    main
else
    echo "Challenge start cancelled. Run this script when you're ready!"
    exit 0
fi