# Exercise 1: Rapid Todo App (45 minutes)

## 🎯 Overview

Build a functional todo application using GitHub Copilot in Codespaces. Focus on speed and AI-assisted development.

## 🚀 Quick Start

### Step 1: Setup (2 minutes)

```bash
# Open two terminals in VS Code (Terminal → Split Terminal)

# Terminal 1 - Frontend
cd exercises/exercise-1-todo/starter/frontend
npm install  # Should be pre-installed
npm run dev

# Terminal 2 - Backend  
cd exercises/exercise-1-todo/starter/backend
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload
```

### Step 2: Access Your App

- Check the **PORTS** tab in VS Code
- Click the 🌐 icon next to port 5173 (frontend)
- Click the 🌐 icon next to port 8000 (backend)

## 📝 Implementation Guide

### Part 1: Backend API (10 minutes)

Create `main.py` in the backend folder:

```python
# Copilot Prompt: Create a complete FastAPI todo app with:
# - Todo model with id, title, completed (SQLAlchemy)
# - In-memory SQLite database
# - CRUD endpoints: GET /todos, POST /todos, PUT /todos/{id}, DELETE /todos/{id}
# - CORS enabled for port 5173
# - Pydantic models for validation

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
# Let Copilot complete the imports and implementation!
```

**Key Copilot Prompts:**
1. "Create SQLAlchemy model for todos"
2. "Add database session management"
3. "Create all CRUD endpoints with error handling"
4. "Add startup event to create tables"

### Part 2: Frontend React App (15 minutes)

Update `App.jsx` in the frontend folder:

```javascript
// Copilot Prompt: Create a complete todo app with:
// - Modern UI using Tailwind CSS
// - Add todo with input field and button
// - List todos with checkboxes
// - Delete button for each todo
// - Filter buttons: All, Active, Completed
// - Use axios for API calls to http://localhost:8000
// - Loading states and error handling

import { useState, useEffect } from 'react'
import axios from 'axios'
// Let Copilot generate the complete component!
```

**Key Copilot Prompts:**
1. "Create todo item component with checkbox and delete"
2. "Add filter buttons with active state styling"
3. "Implement keyboard shortcuts (Enter to add)"
4. "Add empty state message"

### Part 3: Styling with Tailwind (10 minutes)

```javascript
// Copilot Prompts for better UI:
// "Style the todo app with a gradient background"
// "Add hover effects and transitions to buttons"
// "Create a card layout with shadow for the todo list"
// "Add icons using Unicode symbols (➕ ✓ ✗)"
// "Make it responsive for mobile screens"
```

### Part 4: Integration & Testing (10 minutes)

1. **Test all features:**
   - ✅ Add new todos
   - ✅ Toggle completion
   - ✅ Delete todos
   - ✅ Filter by status
   - ✅ Persistence (refresh page)

2. **Quick Enhancements:**
   ```javascript
   // Copilot: Add these quick features
   // - Todo count summary
   // - Clear completed button
   // - Edit todo on double-click
   // - Local storage backup
   ```

## 🎨 Expected Result

Your todo app should have:
- Clean, modern UI with gradient background
- Smooth animations and transitions
- Full CRUD functionality
- Real-time updates
- Persistent storage

## 💡 Copilot Tips

### Effective Prompts for This Exercise

```javascript
// 1. Component Structure
// Create a TodoItem component that shows a checkbox, 
// todo text (strikethrough when completed), and delete button

// 2. API Integration  
// Add useEffect to fetch todos on mount and update the list

// 3. Error Handling
// Show user-friendly error messages using toast notifications

// 4. Performance
// Memoize the filtered todos to prevent unnecessary recalculations
```

### Common Patterns

```python
# Backend: Generic CRUD pattern
@app.get("/todos")
async def get_todos(db: Session = Depends(get_db)):
    # Copilot will complete based on pattern

# Frontend: State update pattern  
const updateTodo = async (id, updates) => {
    // Copilot understands the pattern
}
```

## 🐛 Quick Fixes

### CORS Issue?
```python
# In main.py, ensure CORS is configured
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Database Not Creating?
```python
# Add this after your models
if __name__ == "__main__":
    Base.metadata.create_all(bind=engine)
```

### Port Already in Use?
```bash
# Find and kill the process
lsof -i :8000  # Find process
kill -9 <PID>  # Kill it
```

## ✅ Completion Checklist

- [ ] Backend API running on port 8000
- [ ] Frontend running on port 5173
- [ ] Can create new todos
- [ ] Can toggle completion status
- [ ] Can delete todos
- [ ] Filters work correctly
- [ ] Data persists on refresh
- [ ] UI is responsive and styled

## 🚀 Bonus Challenges (If Time Permits)

1. **Drag & Drop Reordering**
   ```javascript
   // Copilot: Add drag and drop to reorder todos
   ```

2. **Due Dates**
   ```javascript
   // Copilot: Add due date picker to todos
   ```

3. **Categories**
   ```javascript
   // Copilot: Add category tags with colors
   ```

## 🎉 Completed?

Congratulations! You've built a full-stack todo app in 45 minutes using AI assistance. 

**Next Steps:**
1. Take a 5-minute break
2. Move on to Exercise 2: Smart Notes Platform
3. Remember to commit your code!

```bash
git add .
git commit -m "Complete Exercise 1: Todo App"
```

---

**Pro Tip**: Save your best Copilot prompts for future use. They're reusable patterns!