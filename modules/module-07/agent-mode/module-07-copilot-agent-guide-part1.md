# Module 07 - Complete GitHub Copilot Agent Guide
## Part 1: Repository Setup & Exercise 1 (Todo App)

### 🎯 Learning Objectives

In this comprehensive guide, you'll learn:
- How to use GitHub Copilot Agent Mode effectively with @workspace
- Why we structure prompts in specific ways
- Best practices for AI-assisted development
- How to create production-ready full-stack applications

### 🤖 Understanding GitHub Copilot Agent Mode

**What is Agent Mode?**
- A conversational interface where you describe what you want in natural language
- Different from code completion (inline suggestions)
- Generates complete files, structures, and implementations
- Uses @workspace to understand your entire project context

**Why use Agent Mode for learning?**
- See complete implementations with explanations
- Understand architectural decisions
- Learn best practices through generated code
- Get comprehensive solutions quickly

---

## 📚 Module 07 Overview: Web Application Development

In this module, you'll build three progressive web applications:
1. **Exercise 1**: Todo App (React + FastAPI)
2. **Exercise 2**: Smart Notes Platform (React + Local Storage)
3. **Exercise 3**: AI Recipe Assistant (React + FastAPI + OpenAI)

Let's start with setting up your development environment and Exercise 1.

---

## 🚀 Initial Setup: Creating Your Development Environment

### Step 1: Repository Creation

**💡 Educational Note**: We start by creating a new repository for each exercise. This helps you understand the complete project lifecycle and gives you full ownership of your code.

#### Copilot Agent Prompt:
```markdown
@workspace Create a new GitHub repository setup guide for a todo application exercise. Include:

1. Step-by-step instructions for creating a new GitHub repository named "todo-app-fullstack"
2. Essential files: README.md with project description, .gitignore for Python and Node.js, LICENSE (MIT)
3. Initial commit message best practices
4. Branch protection recommendations for main branch
5. Repository settings for a learning project

Explain why each step is important for professional development practices.
```

#### Expected Output:
```markdown
# Creating Your Todo App Repository

## Step 1: Create New Repository on GitHub
1. Go to https://github.com/new
2. Repository name: `todo-app-fullstack`
3. Description: "Full-stack todo application with React and FastAPI - Module 07 Exercise 1"
4. Set to **Private** initially (you can make it public later)
5. Initialize with:
   - ✅ Add a README file
   - ✅ Add .gitignore (select "Node")
   - ✅ Choose a license (MIT recommended for learning projects)

## Step 2: Clone Your Repository
```bash
# Using HTTPS (recommended for beginners)
git clone https://github.com/YOUR_USERNAME/todo-app-fullstack.git
cd todo-app-fullstack

# Or using SSH (if configured)
git clone git@github.com:YOUR_USERNAME/todo-app-fullstack.git
cd todo-app-fullstack
```

## Why These Steps Matter:
- **Private initially**: Practice in a safe environment without public exposure
- **README**: Documents your project from day one
- **.gitignore**: Prevents committing unnecessary files (node_modules, __pycache__, etc.)
- **License**: Establishes how others can use your code
- **Descriptive naming**: Makes your portfolio professional

## Initial Commit Best Practices:
```bash
git add .
git commit -m "Initial commit: Setup todo-app-fullstack repository with basic structure"
```

Good commit messages:
- Start with a verb (Add, Update, Fix, Remove)
- Be specific about what changed
- Keep under 72 characters
- Use present tense
```

### Step 2: Project Structure Setup

**💡 Educational Note**: A well-organized project structure is crucial for maintainability. We'll create a monorepo structure that separates frontend and backend concerns while keeping them in the same repository.

#### Copilot Agent Prompt:
```markdown
@workspace Create the complete project structure for a full-stack todo application. I need:

1. A monorepo structure with separate frontend (React with Vite) and backend (FastAPI) directories
2. Configuration files for both environments
3. Shared directory for common types/interfaces
4. Docker setup for local development
5. VS Code workspace configuration for better development experience
6. Detailed explanation of why we organize projects this way

Include all necessary configuration files with comments explaining their purpose.
```

#### Expected Output:
```
todo-app-fullstack/
├── frontend/                    # React application
│   ├── src/
│   │   ├── components/         # Reusable UI components
│   │   ├── pages/             # Page components
│   │   ├── services/          # API communication
│   │   ├── hooks/             # Custom React hooks
│   │   ├── utils/             # Helper functions
│   │   ├── App.jsx            # Main app component
│   │   ├── main.jsx           # Entry point
│   │   └── index.css          # Global styles
│   ├── public/                # Static assets
│   ├── index.html             # HTML template
│   ├── package.json           # Frontend dependencies
│   ├── vite.config.js         # Vite configuration
│   ├── .env.example           # Environment variables template
│   └── .gitignore            # Frontend-specific ignores
│
├── backend/                   # FastAPI application
│   ├── app/
│   │   ├── api/              # API routes
│   │   │   └── v1/           # API versioning
│   │   ├── core/             # Core functionality
│   │   ├── models/           # Database models
│   │   ├── schemas/          # Pydantic schemas
│   │   ├── services/         # Business logic
│   │   ├── db/               # Database configuration
│   │   └── main.py           # FastAPI app entry
│   ├── tests/                # Backend tests
│   ├── requirements.txt      # Python dependencies
│   ├── .env.example          # Environment template
│   └── .gitignore           # Backend-specific ignores
│
├── shared/                   # Shared types/interfaces
│   └── types.ts             # TypeScript interfaces
│
├── .vscode/                 # VS Code configuration
│   ├── settings.json        # Workspace settings
│   ├── extensions.json      # Recommended extensions
│   └── launch.json          # Debug configurations
│
├── docker-compose.yml       # Local development setup
├── .gitignore              # Root level ignores
├── README.md               # Project documentation
└── todo-app.code-workspace # VS Code workspace file
```

**Why This Structure?**
1. **Separation of Concerns**: Frontend and backend are clearly separated
2. **Monorepo Benefits**: Single repository, easier to manage related code
3. **Shared Resources**: Common types prevent duplication
4. **Development Tools**: VS Code and Docker configs improve DX
5. **Scalability**: Easy to add more services or migrate to microservices

### Step 3: Initialize the Workspace

#### Copilot Agent Prompt:
```markdown
@workspace Create all the initial configuration files for our todo-app-fullstack project:

1. VS Code workspace file (todo-app.code-workspace) with multi-root setup
2. VS Code settings.json with formatting, linting, and Copilot configurations
3. Recommended extensions.json for the team
4. Root .gitignore combining Python and Node.js patterns
5. docker-compose.yml for local development with hot-reload

Explain the benefits of each configuration and how it improves the development workflow.
```

#### Expected Output:

**todo-app.code-workspace:**
```json
{
  "folders": [
    {
      "name": "Frontend",
      "path": "./frontend"
    },
    {
      "name": "Backend", 
      "path": "./backend"
    },
    {
      "name": "Root",
      "path": "."
    }
  ],
  "settings": {
    "files.exclude": {
      "**/node_modules": true,
      "**/__pycache__": true,
      "**/.pytest_cache": true
    },
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.fixAll.eslint": true
    },
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "python.formatting.provider": "black",
    "[python]": {
      "editor.defaultFormatter": "ms-python.black-formatter"
    },
    "[javascript]": {
      "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[javascriptreact]": {
      "editor.defaultFormatter": "esbenp.prettier-vscode"
    }
  },
  "extensions": {
    "recommendations": [
      "github.copilot",
      "github.copilot-chat",
      "ms-python.python",
      "ms-python.vscode-pylance",
      "dbaeumer.vscode-eslint",
      "esbenp.prettier-vscode",
      "ms-vscode.vscode-typescript-next"
    ]
  }
}
```

**Why Workspace Files?**
- **Multi-root**: Work on frontend/backend simultaneously
- **Shared Settings**: Consistent formatting across team
- **Focused Views**: Reduce cognitive load
- **Better Search**: Scoped to relevant folders

**.vscode/extensions.json:**
```json
{
  "recommendations": [
    // AI Assistance
    "github.copilot",
    "github.copilot-chat",
    
    // Python Development
    "ms-python.python",
    "ms-python.vscode-pylance",
    "ms-python.black-formatter",
    
    // JavaScript/React
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "dsznajder.es7-react-js-snippets",
    
    // Utilities
    "christian-kohler.path-intellisense",
    "formulahendry.auto-rename-tag",
    "aaron-bond.better-comments",
    "yzhang.markdown-all-in-one",
    
    // Docker
    "ms-azuretools.vscode-docker",
    
    // Git
    "eamodio.gitlens"
  ]
}
```

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  # Backend Service
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.dev
    container_name: todo-backend
    ports:
      - "8000:8000"
    volumes:
      - ./backend:/app
    environment:
      - DATABASE_URL=sqlite:///./todos.db
      - PYTHONUNBUFFERED=1
    command: uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

  # Frontend Service  
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.dev
    container_name: todo-frontend
    ports:
      - "5173:5173"
    volumes:
      - ./frontend:/app
      - /app/node_modules
    environment:
      - VITE_API_URL=http://localhost:8000
    depends_on:
      - backend
    command: npm run dev -- --host

  # Database (optional, for production-like setup)
  db:
    image: postgres:15-alpine
    container_name: todo-db
    environment:
      - POSTGRES_USER=todouser
      - POSTGRES_PASSWORD=todopass
      - POSTGRES_DB=tododb
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  postgres_data:
```

---

## 🛠️ Exercise 1: Todo Application Setup

### Step 4: Backend Setup (FastAPI)

**💡 Educational Note**: We start with the backend because it defines our data structure and API contracts. This API-first approach helps us design better frontends.

#### Copilot Agent Prompt:
```markdown
@workspace Set up the complete FastAPI backend structure for our todo application. Create:

1. FastAPI project initialization with proper project structure
2. SQLAlchemy models for todos with proper relationships
3. Pydantic schemas for request/response validation
4. CRUD operations with async support
5. API routes with RESTful conventions
6. Database setup with migrations using Alembic
7. CORS configuration for frontend communication
8. Environment variable management
9. Comprehensive error handling
10. API documentation setup

Explain each component's purpose and FastAPI best practices. Include all necessary files with detailed comments.
```

#### Expected Output Structure:
```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI application entry point
│   ├── api/
│   │   ├── __init__.py
│   │   └── v1/
│   │       ├── __init__.py
│   │       ├── api.py          # API router aggregation
│   │       └── endpoints/
│   │           ├── __init__.py
│   │           └── todos.py    # Todo endpoints
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py          # Settings management
│   │   └── security.py        # Security utilities
│   ├── models/
│   │   ├── __init__.py
│   │   └── todo.py            # SQLAlchemy models
│   ├── schemas/
│   │   ├── __init__.py
│   │   └── todo.py            # Pydantic schemas
│   ├── crud/
│   │   ├── __init__.py
│   │   └── todo.py            # CRUD operations
│   └── db/
│       ├── __init__.py
│       ├── base.py            # Database base configuration
│       └── session.py         # Database session management
├── alembic/                   # Database migrations
├── tests/
├── requirements.txt
├── .env.example
└── Dockerfile.dev
```

**backend/app/main.py:**
```python
"""
Main FastAPI application entry point.

This file configures the FastAPI application with:
- CORS middleware for frontend communication
- API route registration
- Database initialization
- Global exception handlers
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.api.v1.api import api_router
from app.core.config import settings
from app.db.base import Base
from app.db.session import engine

# Create database tables on startup
@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Manage application lifecycle.
    Creates database tables on startup.
    """
    # Startup
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    # Shutdown (cleanup if needed)

# Initialize FastAPI app
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routes
app.include_router(api_router, prefix=settings.API_V1_STR)

# Root endpoint
@app.get("/")
async def root():
    """
    Root endpoint returning API information.
    Useful for health checks.
    """
    return {
        "message": "Todo API",
        "version": settings.VERSION,
        "docs": f"{settings.API_V1_STR}/docs"
    }
```

**Why This Structure?**
1. **Lifespan Management**: Proper startup/shutdown handling
2. **CORS Configuration**: Enables frontend communication
3. **API Versioning**: Future-proof API design
4. **Settings Management**: Centralized configuration
5. **Async Support**: Better performance with async/await

### Step 5: Frontend Setup (React + Vite)

#### Copilot Agent Prompt:
```markdown
@workspace Create the complete React frontend setup for our todo application using Vite. Include:

1. Vite project initialization with React and TypeScript
2. Tailwind CSS configuration for styling
3. Axios setup for API communication
4. Component structure following atomic design principles
5. Custom hooks for state management
6. Context API for global state
7. Error boundary implementation
8. Loading states and skeletons
9. Responsive design setup
10. Development proxy configuration

Explain why we choose each technology and how they work together. Create all necessary configuration files with educational comments.
```

#### Expected Output:

**💡 Educational Note**: Vite is chosen over Create React App for its speed and modern development experience. It provides faster hot module replacement (HMR) and better build optimization.

**frontend/package.json:**
```json
{
  "name": "todo-app-frontend",
  "private": true,
  "version": "0.0.1",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext js,jsx --report-unused-disable-directives --max-warnings 0",
    "format": "prettier --write \"src/**/*.{js,jsx,json,css,md}\""
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "axios": "^1.6.0",
    "react-hot-toast": "^2.4.1",
    "clsx": "^2.0.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.43",
    "@types/react-dom": "^18.2.17",
    "@vitejs/plugin-react": "^4.2.1",
    "autoprefixer": "^10.4.16",
    "eslint": "^8.55.0",
    "eslint-plugin-react": "^7.33.2",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-react-refresh": "^0.4.5",
    "postcss": "^8.4.32",
    "prettier": "^3.1.1",
    "tailwindcss": "^3.3.0",
    "vite": "^5.0.8"
  }
}
```

**frontend/vite.config.js:**
```javascript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    // Enable HMR
    host: true,
    port: 5173,
    // Proxy API requests to backend
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
        secure: false,
      }
    }
  },
  // Build optimizations
  build: {
    // Reduce bundle size
    rollupOptions: {
      output: {
        manualChunks: {
          'react-vendor': ['react', 'react-dom'],
        }
      }
    }
  }
})
```

**Why These Configurations?**
- **Proxy Setup**: Avoids CORS issues during development
- **Manual Chunks**: Better caching in production
- **Host: true**: Allows external device access
- **HMR**: Instant feedback during development

### Step 6: Implementing Core Features

#### Copilot Agent Prompt for Backend API:
```markdown
@workspace Implement the complete Todo API with the following features:

1. Todo model with: id, title, description, completed, priority, due_date, created_at, updated_at
2. CRUD endpoints: GET /todos (with pagination), POST /todos, PUT /todos/{id}, DELETE /todos/{id}
3. Filtering: by status (completed/active), priority, due date
4. Sorting: by created date, due date, priority
5. Bulk operations: complete all, delete completed
6. Input validation with meaningful error messages
7. Async database operations with SQLAlchemy
8. Proper HTTP status codes and error handling

Include educational comments explaining REST principles, async patterns, and why each design decision was made.
```

#### Expected Backend Implementation:

**backend/app/models/todo.py:**
```python
"""
Todo model definition using SQLAlchemy ORM.

Educational Notes:
- We use SQLAlchemy's declarative style for cleaner code
- UUID primary keys prevent enumeration attacks
- Timestamps help with debugging and features like sorting
- Indexes improve query performance
"""

from sqlalchemy import Column, String, Boolean, DateTime, Integer, Index
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
import uuid

from app.db.base_class import Base

class Todo(Base):
    """
    Todo model representing a task in our application.
    
    Attributes:
        id: Unique identifier (UUID for security)
        title: Main task description (required)
        description: Detailed task information (optional)
        completed: Task completion status
        priority: 1-5 scale (1=lowest, 5=highest)
        due_date: Optional deadline
        created_at: Timestamp for sorting/filtering
        updated_at: Track last modification
    """
    __tablename__ = "todos"
    
    # Primary key using UUID to prevent ID enumeration
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Core fields
    title = Column(String(200), nullable=False, index=True)
    description = Column(String(1000), nullable=True)
    completed = Column(Boolean, default=False, nullable=False, index=True)
    
    # Priority: 1 (low) to 5 (high)
    priority = Column(Integer, default=3, nullable=False)
    
    # Optional due date for deadlines
    due_date = Column(DateTime, nullable=True)
    
    # Timestamps for auditing and sorting
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Composite index for common query patterns
    __table_args__ = (
        Index('idx_completed_priority', 'completed', 'priority'),
        Index('idx_due_date', 'due_date'),
    )
    
    def __repr__(self):
        """String representation for debugging."""
        return f"<Todo {self.title} - {'✓' if self.completed else '○'}>"
```

#### Copilot Agent Prompt for Frontend Components:
```markdown
@workspace Create the React component structure for our Todo application:

1. TodoList component with virtualization for performance
2. TodoItem with inline editing capabilities  
3. TodoForm with validation and error handling
4. TodoFilters for status, priority, and date filtering
5. TodoStats showing completion progress
6. Custom useTodos hook for state management
7. API service layer with proper error handling
8. Loading states with skeleton components
9. Empty states with helpful messages
10. Keyboard shortcuts for power users

Explain React best practices, performance optimizations, and accessibility considerations in comments.
```

### Step 7: Running the Application

#### Copilot Agent Prompt:
```markdown
@workspace Create comprehensive setup and run instructions for our todo application covering:

1. Environment setup for Windows (CMD/PowerShell), macOS/Linux (bash), and GitHub Codespaces
2. Installing dependencies for both frontend and backend
3. Database initialization and migration
4. Running services individually or with Docker Compose
5. Verifying everything works with test requests
6. Common troubleshooting steps
7. Development workflow tips

Format as a step-by-step guide with platform-specific commands clearly marked.
```

#### Expected Output:

**Running Your Todo Application - Complete Guide**

**Option 1: Using GitHub Codespaces (Recommended for Beginners)**
```bash
# 1. Open repository in Codespaces
# Click "Code" > "Codespaces" > "Create codespace on main"

# 2. Terminal will open automatically
# Split terminal for frontend and backend

# Terminal 1 - Backend
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload

# Terminal 2 - Frontend  
cd frontend
npm install
npm run dev

# 3. Codespaces will automatically forward ports
# Click on the URLs in the terminal to open the app
```

**Option 2: Local Development (VS Code)**

**Windows (PowerShell):**
```powershell
# Clone and enter directory
git clone https://github.com/YOUR_USERNAME/todo-app-fullstack.git
cd todo-app-fullstack

# Backend setup
cd backend
python -m venv venv
.\venv\Scripts\Activate
pip install -r requirements.txt
uvicorn app.main:app --reload

# New terminal for frontend
cd frontend
npm install
npm run dev
```

**macOS/Linux (bash):**
```bash
# Clone and enter directory
git clone https://github.com/YOUR_USERNAME/todo-app-fullstack.git
cd todo-app-fullstack

# Backend setup
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload

# New terminal for frontend
cd frontend
npm install
npm run dev
```

**Option 3: Using Docker Compose (All Platforms):**
```bash
# From root directory
docker-compose up

# Or run in background
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

**Verification Steps:**
1. Backend API: http://localhost:8000/docs
2. Frontend App: http://localhost:5173
3. Test API: 
   ```bash
   curl http://localhost:8000/api/v1/todos
   ```

---

## 🚀 Challenge: GitOps Deployment to Azure

### Final Challenge Prompt:

#### Copilot Agent Prompt:
```markdown
@workspace Create a complete GitOps setup for deploying our todo application to Azure:

1. GitHub Actions workflow for CI/CD
2. Infrastructure as Code using Bicep or Terraform
3. Separate workflows for development and production
4. Secret management with GitHub Secrets
5. Automated testing before deployment
6. Blue-green deployment strategy
7. Rollback capabilities
8. Monitoring and alerting setup
9. Cost optimization strategies
10. Security best practices

Explain each component and why it's important for production deployments. Include all configuration files and scripts.
```

**💡 Educational Note**: This challenge combines everything you've learned and introduces DevOps practices. GitOps means using Git as the single source of truth for infrastructure and deployments.

---

## 📚 Key Takeaways

1. **Start with Structure**: A well-organized project is easier to maintain
2. **API-First Design**: Define your data and endpoints before the UI
3. **Use Modern Tools**: Vite, FastAPI, and Docker improve developer experience
4. **Think in Components**: Break complex UIs into manageable pieces
5. **Embrace AI Assistance**: Copilot helps you learn and code faster
6. **Practice DevOps Early**: Understanding deployment makes you a complete developer

## 🎯 Next Steps

You've completed Exercise 1! You now have:
- A working full-stack todo application
- Understanding of modern web development practices
- Experience with AI-assisted development
- Foundation for more complex projects

Continue to Exercise 2: Smart Notes Platform, where you'll learn about local storage, advanced React patterns, and offline-first development!

---

**Remember**: The best way to learn is by doing. Experiment with the code, break things, and fix them. Every error is a learning opportunity!