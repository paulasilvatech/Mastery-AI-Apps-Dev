# Exercise 1: Rapid Todo App - Enhanced Guide (45 minutes)

## 🎯 Overview

Build a functional todo application using two approaches with GitHub Copilot:
- **Code Suggestion Mode**: Use inline comments to generate code
- **Agent Mode**: Use comprehensive prompts for complete implementations

## 🤖 Understanding the Two Approaches

### Code Suggestion Mode
- **What it is**: GitHub Copilot suggests code as you type based on comments and context
- **Best for**: Line-by-line development, learning syntax, incremental building
- **How it works**: Write a comment, press Tab to accept suggestions

### Agent Mode (Copilot Chat)
- **What it is**: Conversational AI that generates complete code blocks and files
- **Best for**: Rapid prototyping, complex implementations, architectural decisions
- **How it works**: Write detailed prompts in chat, get comprehensive solutions

## 📋 Prerequisites Check

### Using Agent Mode for Setup Verification

```markdown
# Copilot Agent Prompt:
Create a comprehensive script that checks all prerequisites for Module 07 Exercise 1:

1. System Requirements:
   - Python 3.11+ with pip
   - Node.js 18+ with npm
   - Git installed and configured
   - Azure CLI (for deployment)
   - VS Code with GitHub Copilot

2. Required Accounts:
   - GitHub account with Copilot enabled
   - Azure subscription (free tier works)
   - Verify Copilot is working

3. Port Availability:
   - Check ports 8000 and 5173 are free

4. Create Setup Script:
   - Cross-platform (Windows/Mac/Linux)
   - Colored output for status
   - Install missing dependencies
   - Setup virtual environment
   - Configure Azure CLI

Include error handling and helpful messages for each check.
```

## 🚀 Step-by-Step Implementation

### Step 1: Project Setup (5 minutes)

#### Option A: Code Suggestion Approach
```bash
# In your terminal, create the project structure
mkdir -p todo-app/{backend,frontend}
cd todo-app

# Backend setup - let Copilot help with each file
cd backend
# Create a comment in terminal or new file:
# Create requirements.txt for FastAPI todo app with SQLAlchemy
```

#### Option B: Agent Mode Approach
```markdown
# Copilot Agent Prompt:
Create a complete project structure for a todo app:

Project Requirements:
- Root folder: todo-app
- Backend: FastAPI with SQLAlchemy, SQLite, CORS support
- Frontend: React with Vite, Tailwind CSS, Axios
- Create all necessary files:
  - backend/requirements.txt (fastapi, uvicorn, sqlalchemy, pydantic)
  - backend/main.py (starter template)
  - frontend/package.json (with all dependencies)
  - frontend/vite.config.js (with proxy configuration)
  - frontend/tailwind.config.js
  - .gitignore for both Python and Node.js

Include setup commands for both environments.
```

**💡 Exploration Tip**: Try adding Docker support to your project structure! Modify the prompt to include Dockerfile and docker-compose.yml.

### Step 2: Backend API Implementation (10 minutes)

#### Option A: Code Suggestion Approach

Create `backend/main.py` and build incrementally:

```python
# Create a FastAPI app for todo management
# Import necessary modules: FastAPI, SQLAlchemy, Pydantic
from fastapi import FastAPI, HTTPException, Depends
# Let Copilot suggest the imports...

# Create database models for todos
# Todo should have: id, title, completed status
```

Build step by step:
1. Write a comment for each component
2. Accept Copilot suggestions
3. Refine as needed

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create a complete FastAPI backend for a todo app in main.py:

Technical Requirements:
1. Database:
   - Use SQLAlchemy with SQLite
   - Todo model: id (int), title (str), completed (bool), created_at (datetime)
   - In-memory database for development

2. API Endpoints:
   - GET /todos - List all todos with optional filtering
   - POST /todos - Create new todo with validation
   - PUT /todos/{id} - Update todo (title or completed)
   - DELETE /todos/{id} - Soft delete with is_deleted flag
   - GET /todos/stats - Return statistics

3. Features:
   - CORS enabled for localhost:5173
   - Request validation with Pydantic
   - Proper error handling with status codes
   - Logging for all operations
   - Auto-create tables on startup

4. Bonus Features:
   - Add pagination (limit/offset)
   - Add sorting (by date, title)
   - Add search functionality
   - Add bulk operations endpoint

Make it production-ready with proper structure and error handling.
```

**💡 Exploration Tip**: Add user authentication! Extend the prompt to include JWT tokens and user-specific todos.

### Step 3: Frontend React Implementation (15 minutes)

#### Option A: Code Suggestion Approach

Create `frontend/src/App.jsx`:

```javascript
// Create a todo app component with:
// - State for todos, new todo input, and filter
// - useEffect to fetch todos on mount
// - Functions to add, toggle, and delete todos
// - Responsive UI with Tailwind CSS

import { useState, useEffect } from 'react'
// Let Copilot complete the imports...

function App() {
  // State management for todos
  const [todos, setTodos] = useState([])
  // Let Copilot suggest more state...
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create a complete React todo app with modern UI/UX:

Component Structure:
1. Main App Component:
   - State management with useState and useReducer
   - API integration with custom hooks
   - Error boundary for graceful failures

2. Sub-components to create:
   - TodoList: Virtual scrolling for performance
   - TodoItem: Editable inline with double-click
   - TodoFilters: All/Active/Completed + custom filters
   - TodoStats: Visual statistics with charts
   - SearchBar: Real-time search with debouncing

3. Features:
   - Drag-and-drop to reorder todos
   - Bulk actions (select multiple)
   - Undo/Redo functionality
   - Offline support with service worker
   - Export/Import todos (JSON/CSV)
   - Dark/Light theme toggle
   - Keyboard shortcuts (?, N, /, ESC)
   - Toast notifications for actions

4. UI/UX with Tailwind:
   - Gradient backgrounds with animations
   - Smooth transitions (framer-motion)
   - Loading skeletons
   - Empty states with illustrations
   - Mobile-first responsive design
   - Accessibility (ARIA labels, keyboard nav)

5. Performance:
   - Memoization with useMemo/useCallback
   - Code splitting
   - Lazy loading
   - Optimistic updates

Include TypeScript types if you want to make it more robust!
```

**💡 Exploration Tip**: Add a Pomodoro timer to your todos! Each todo could have an estimated time and track actual time spent.

### Step 4: Enhanced Features (10 minutes)

#### Option A: Code Suggestion Approach

Add features incrementally:

```javascript
// Add local storage persistence
// Save todos to localStorage on every change
useEffect(() => {
  // Let Copilot complete this...
}, [todos])

// Add keyboard shortcuts
// Press 'n' to create new todo, '/' to search
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Enhance the todo app with advanced features:

1. Smart Features:
   - AI-powered todo suggestions based on patterns
   - Natural language processing ("Buy milk tomorrow" → sets due date)
   - Smart categorization (auto-detect projects)
   - Priority detection from keywords

2. Collaboration:
   - Share todo lists via unique URL
   - Real-time sync with WebSockets
   - Comments on todos
   - Activity history

3. Integrations:
   - Calendar sync (Google/Outlook)
   - Email todos to a special address
   - Slack/Discord notifications
   - GitHub Issues integration

4. Analytics:
   - Productivity dashboard
   - Completion trends
   - Time tracking
   - Weekly/Monthly reports

5. Mobile Features:
   - PWA with offline support
   - Push notifications
   - Voice input
   - Widget for home screen

Implement at least 3 of these features with full functionality.
```

**💡 Exploration Tip**: Create a browser extension that adds todos from any webpage!

### Step 5: Testing & Validation (5 minutes)

#### Option A: Code Suggestion Approach

Create test files:

```python
# backend/test_api.py
# Create pytest tests for all todo endpoints
# Test CRUD operations, error cases, validation
```

#### Option B: Agent Mode Approach

```markdown
# Copilot Agent Prompt:
Create comprehensive testing for the todo app:

1. Backend Tests (pytest):
   - Unit tests for all endpoints
   - Integration tests with test database
   - Performance tests (load testing)
   - Security tests (SQL injection, XSS)

2. Frontend Tests (Jest + React Testing Library):
   - Component unit tests
   - Integration tests
   - E2E tests with Cypress
   - Visual regression tests

3. CI/CD Pipeline (GitHub Actions):
   - Run tests on every push
   - Code coverage reports
   - Automated deployment to staging
   - Performance monitoring

Create all test files and GitHub Actions workflow.
```

## ☁️ Azure Deployment

### Step 6: Azure Infrastructure with Bicep (10 minutes)

#### Agent Mode Approach for Azure Deployment

```markdown
# Copilot Agent Prompt:
Create complete Azure deployment for the todo app:

1. Bicep Template (infrastructure/main.bicep):
   Infrastructure needed:
   - Azure Container Registry
   - Azure Container Instances or App Service
   - Azure SQL Database (or Cosmos DB)
   - Application Insights
   - Key Vault for secrets
   - CDN for frontend
   - API Management (optional)

2. Parameters file (infrastructure/parameters.json):
   - Environment-specific settings
   - Resource naming conventions
   - SKU configurations
   - Region settings

3. GitHub Actions Workflow (.github/workflows/deploy.yml):
   - Build and test
   - Create Docker images
   - Push to ACR
   - Deploy infrastructure with Bicep
   - Deploy applications
   - Run smoke tests

4. Supporting Scripts:
   - setup-azure.sh: Create resource group, service principal
   - deploy.sh: One-click deployment
   - teardown.sh: Clean up resources

5. Security Best Practices:
   - Managed identities
   - Private endpoints
   - Network security groups
   - Azure Policy compliance

Include cost optimization and monitoring setup.
```

### Local Bicep Template Creation

Create `infrastructure/main.bicep`:

```bicep
// Copilot Agent Prompt:
// Create a complete Bicep template for todo app with:
// - App Service Plan (Linux, B1 tier for dev)
// - Web App for backend with Python runtime
// - Static Web App for frontend
// - Application Insights
// - Key Vault for secrets
// Include parameters for environment and regions
```

**💡 Exploration Tip**: Add Azure Cognitive Services to analyze todo patterns and provide insights!

## 🎯 Challenge Extensions

### Advanced Prompts for Exploration

```markdown
# Copilot Agent Prompt for Advanced Features:

Transform the simple todo app into a comprehensive productivity suite:

1. AI Integration:
   - Use Azure OpenAI to generate task breakdowns
   - Sentiment analysis on task descriptions
   - Smart scheduling based on calendar
   - Predictive completion times

2. Voice and Vision:
   - Voice commands with Azure Speech
   - OCR to create todos from photos
   - Gesture controls for mobile

3. Enterprise Features:
   - Multi-tenant architecture
   - RBAC with Azure AD
   - Audit logging
   - Compliance reporting

4. Performance at Scale:
   - Redis caching
   - Database sharding
   - CDN integration
   - Load balancing

Choose one area and implement it fully!
```

## ✅ Completion Checklist

### Core Requirements
- [ ] Backend API running and responding
- [ ] Frontend connecting to backend
- [ ] CRUD operations working
- [ ] Data persistence implemented
- [ ] Error handling in place
- [ ] Responsive design complete

### Bonus Achievements
- [ ] Added custom features beyond base requirements
- [ ] Implemented testing
- [ ] Deployed to Azure
- [ ] Created documentation
- [ ] Added accessibility features

## 🎉 Congratulations!

You've learned two powerful ways to use GitHub Copilot:
1. **Code Suggestions** for learning and incremental development
2. **Agent Mode** for rapid prototyping and complex features

**Next Steps:**
- Try rebuilding with the approach you didn't use
- Add your own creative features
- Share your unique implementation
- Prepare for Exercise 2!

**Remember**: The goal is not just to complete the exercise, but to explore and learn. Every prompt you write teaches Copilot to better understand your needs!