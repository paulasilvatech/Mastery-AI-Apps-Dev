# Module 07: Quick Start Guide

## 🚀 5-Minute Setup

Get your environment ready for web application development with AI in just 5 minutes!

### 1️⃣ Prerequisites Check (1 minute)

Run this command to verify everything is installed:
```bash
# Check all requirements
curl -fsSL https://raw.githubusercontent.com/your-org/mastery-ai-workshop/main/modules/module-07/scripts/check-prerequisites.sh | bash
```

Or manually verify:
```bash
# Check versions
node --version          # Should be >= 18.0.0
python --version        # Should be >= 3.11.0
docker --version        # Should be >= 24.0.0
code --version          # VS Code should be latest

# Check Copilot
code --list-extensions | grep github.copilot
```

### 2️⃣ Quick Environment Setup (2 minutes)

```bash
# Clone the module
git clone https://github.com/your-org/mastery-ai-workshop.git
cd mastery-ai-workshop/modules/module-07-web-applications

# Run automated setup
./scripts/quick-setup.sh

# Or manual setup:
# Backend
cd backend
python -m venv venv
source venv/bin/activate  # Windows: .\venv\Scripts\activate
pip install -r requirements-base.txt

# Frontend
cd ../frontend
npm install -g pnpm
pnpm install
```

### 3️⃣ Start Your First App (2 minutes)

```bash
# Quick Todo App
cd exercises/exercise1-todo-app

# Start backend (Terminal 1)
cd backend && python run.py

# Start frontend (Terminal 2)
cd frontend && npm run dev

# Open http://localhost:5173
```

## 🎯 Exercise Quick Starts

### Exercise 1: Todo App (30 minutes)
```bash
cd exercises/exercise1-todo-app
./start.sh  # Starts both frontend and backend
# Follow the step-by-step guide in instructions/README.md
```

### Exercise 2: Blog Platform (45 minutes)
```bash
cd exercises/exercise2-blog-platform
docker-compose up -d  # Start PostgreSQL
./start.sh
# Follow instructions/README.md
```

### Exercise 3: AI Dashboard (60 minutes)
```bash
cd exercises/exercise3-ai-dashboard
./setup-infrastructure.sh  # Sets up all services
./start.sh
# Follow instructions/README.md
```

## 💡 Pro Tips

1. **Use Copilot Chat for Help**
   ```
   # In VS Code, press Cmd/Ctrl + I
   "Help me create a React component for [specific feature]"
   ```

2. **Quick Component Generation**
   ```typescript
   // Type this comment and press Tab
   // Create a TodoItem component with edit and delete functionality
   ```

3. **API Endpoint Generation**
   ```python
   # Type this comment and press Tab
   # Create CRUD endpoints for blog posts with authentication
   ```

## 🆘 Quick Troubleshooting

### Port Already in Use
```bash
# Kill process on port 8000 (backend)
lsof -ti:8000 | xargs kill -9

# Kill process on port 5173 (frontend)
lsof -ti:5173 | xargs kill -9
```

### Copilot Not Working
1. Check subscription: `gh copilot status`
2. Restart VS Code
3. Re-authenticate: `gh auth refresh`

### Database Issues
```bash
# Reset SQLite database
rm backend/todos.db

# Reset PostgreSQL
docker-compose down -v
docker-compose up -d
```

## 📚 Next Steps

1. Read the [conceptual overview](./README.md)
2. Complete exercises in order
3. Check [best practices](./best-practices.md)
4. Deploy your apps using the [deployment guide](./deployment-guide.md)

**Ready? Let's build amazing web apps with AI! 🚀**