# Module 07 - Complete Repository Structure

## 📁 Folder Organization

```
module-07-web-applications/
├── README.md                           # Main module documentation
├── .devcontainer/                      # GitHub Codespaces configuration
│   ├── devcontainer.json              # Codespaces settings
│   └── setup.sh                       # Auto-setup script
├── docs/
│   ├── best-practices.md              # Production patterns
│   ├── troubleshooting.md             # Common issues & solutions
│   └── architecture-diagrams.md       # Visual references
├── exercises/
│   ├── exercise-1-todo/
│   │   ├── README.md                  # Exercise instructions
│   │   ├── starter/
│   │   │   ├── frontend/
│   │   │   │   ├── package.json
│   │   │   │   ├── vite.config.js
│   │   │   │   ├── tailwind.config.js
│   │   │   │   ├── postcss.config.js
│   │   │   │   ├── index.html
│   │   │   │   └── src/
│   │   │   │       ├── App.jsx       # Minimal starter
│   │   │   │       ├── App.css
│   │   │   │       └── main.jsx
│   │   │   └── backend/
│   │   │       ├── requirements.txt
│   │   │       └── main.py           # Minimal starter
│   │   └── solution/                  # Complete working solution
│   │       ├── frontend/
│   │       └── backend/
│   ├── exercise-2-notes/
│   │   ├── README.md
│   │   ├── starter/
│   │   │   └── frontend/
│   │   │       ├── package.json
│   │   │       ├── vite.config.js
│   │   │       ├── tailwind.config.js
│   │   │       ├── index.html
│   │   │       └── src/
│   │   │           ├── App.jsx
│   │   │           └── main.jsx
│   │   └── solution/
│   │       └── frontend/
│   └── exercise-3-recipes/
│       ├── README.md
│       ├── starter/
│       │   ├── frontend/
│       │   │   ├── package.json
│       │   │   ├── vite.config.js
│       │   │   ├── tailwind.config.js
│       │   │   ├── index.html
│       │   │   └── src/
│       │   │       ├── App.jsx
│       │   │       └── main.jsx
│       │   └── backend/
│       │       ├── requirements.txt
│       │       ├── .env.example
│       │       └── main.py
│       └── solution/
│           ├── frontend/
│           └── backend/
└── resources/
    ├── copilot-prompts.md             # Best prompts collection
    └── quick-reference.md             # Cheatsheet
```

## 📄 Starter Files Content

### Exercise 1 - Frontend `package.json`
```json
{
  "name": "todo-app-frontend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "axios": "^1.6.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "@vitejs/plugin-react": "^4.0.0",
    "autoprefixer": "^10.4.14",
    "postcss": "^8.4.24",
    "tailwindcss": "^3.3.0",
    "vite": "^4.4.0"
  }
}
```

### Exercise 1 - Backend `requirements.txt`
```
fastapi==0.104.1
uvicorn==0.24.0
sqlalchemy==2.0.23
python-dotenv==1.0.0
```

### Exercise 1 - Minimal Starter `App.jsx`
```javascript
import { useState } from 'react'
import './App.css'

function App() {
  // Copilot Prompt: Create a complete todo app with:
  // - Add todo functionality
  // - List todos with checkboxes
  // - Delete todos
  // - Filter by status (all/active/completed)
  // - Use Tailwind CSS for styling
  // - Connect to backend API at http://localhost:8000
  
  return (
    <div className="min-h-screen bg-gray-100">
      <h1 className="text-3xl font-bold text-center py-8">
        Todo App
      </h1>
      {/* Let Copilot build the rest! */}
    </div>
  )
}

export default App
```

### Exercise 2 - Frontend `package.json`
```json
{
  "name": "smart-notes-frontend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "@uiw/react-md-editor": "^3.23.0",
    "react-icons": "^4.11.0",
    "fuse.js": "^7.0.0",
    "uuid": "^9.0.1",
    "date-fns": "^2.30.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "@vitejs/plugin-react": "^4.0.0",
    "autoprefixer": "^10.4.14",
    "postcss": "^8.4.24",
    "tailwindcss": "^3.3.0",
    "vite": "^4.4.0"
  }
}
```

### Exercise 3 - Backend `requirements.txt`
```
fastapi==0.104.1
uvicorn==0.24.0
openai==1.3.0
python-dotenv==1.0.0
python-multipart==0.0.6
cloudinary==1.36.0
httpx==0.25.2
slowapi==0.1.9
```

### Exercise 3 - `.env.example`
```bash
# OpenAI Configuration
OPENAI_API_KEY=sk-...your-key-here

# Optional: Cloudinary for image uploads
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# Application Settings
DEBUG=True
SECRET_KEY=your-secret-key-here
```

### Universal `vite.config.js`
```javascript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    host: true,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      }
    }
  }
})
```

### Universal `tailwind.config.js`
```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

### Minimal Backend Starter
```python
# main.py - Minimal starter for all exercises
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "API is running!"}

# Copilot will help you build the rest!
```

## 🚀 Quick Start Commands

### For Students:
```bash
# 1. Fork this repository
# 2. Create a Codespace from your fork
# 3. Wait for setup to complete (2-3 minutes)
# 4. Start coding!

# Exercise 1
cd exercises/exercise-1-todo/starter
# Follow README.md

# Exercise 2  
cd exercises/exercise-2-notes/starter
# Follow README.md

# Exercise 3
cd exercises/exercise-3-recipes/starter
# Add your OpenAI API key to backend/.env
# Follow README.md
```

### For Instructors:
```bash
# Clone the repository
git clone <repo-url>

# Test all exercises
./scripts/test-all-exercises.sh

# Create solution branches
git checkout -b solutions
# Add complete solutions
git push origin solutions
```

## 📝 Notes

- All npm dependencies are pre-installed in Codespaces
- Python virtual environments are pre-created
- Ports are automatically forwarded
- GitHub Copilot is pre-activated
- No local setup required!

This structure provides everything needed for a smooth 3-hour workshop experience in GitHub Codespaces.