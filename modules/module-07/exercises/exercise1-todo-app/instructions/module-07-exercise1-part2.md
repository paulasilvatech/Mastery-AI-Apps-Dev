# Exercise 1: AI-Powered Todo Application (Part 2)

## 📋 Step 2: Frontend Setup (15 minutes)

### 2.1 Create React Application

Open a new terminal in the `exercise1-todo-app` directory:

```bash
# Create Vite React app with TypeScript
npm create vite@latest frontend -- --template react-ts

# Navigate to frontend directory
cd frontend

# Install dependencies
npm install

# Install additional packages
npm install axios react-query @tanstack/react-query
npm install -D @types/react @types/react-dom
```

### 2.2 Install and Configure Tailwind CSS

**Copilot Prompt Suggestion:**
```bash
# Install and configure Tailwind CSS for Vite React project
# Include all necessary dependencies and configuration files
```

Expected commands:
```bash
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

Update `tailwind.config.js`:

**Copilot Prompt Suggestion:**
```javascript
// Configure Tailwind for React with:
// - Content paths for jsx/tsx files
// - Custom colors for primary brand
// - Responsive breakpoints
// - Dark mode support
```

**Expected Copilot Output:**
```javascript
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
```

Update `src/index.css`:
```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

### 2.3 Create API Client

Create `src/api/todoApi.ts`:

**Copilot Prompt Suggestion:**
```typescript
// Create a TypeScript API client for todo operations:
// - Define Todo interface matching backend schema
// - Create axios instance with base URL http://localhost:8000
// - Implement CRUD functions: getTodos, createTodo, updateTodo, deleteTodo
// - Add getSuggestion function
// - Include proper error handling and type safety
```

**Expected Copilot Output:**
```typescript
import axios from 'axios';

const API_BASE_URL = 'http://localhost:8000';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export interface Todo {
  id: number;
  title: string;
  description?: string;
  completed: boolean;
  created_at: string;
  updated_at: string;
}

export interface CreateTodoDto {
  title: string;
  description?: string;
}

export interface UpdateTodoDto {
  title?: string;
  description?: string;
  completed?: boolean;
}

export interface TodoListResponse {
  todos: Todo[];
  total: number;
}

export const todoApi = {
  async getTodos(completed?: boolean): Promise<TodoListResponse> {
    const params = completed !== undefined ? { completed } : {};
    const response = await api.get<TodoListResponse>('/todos', { params });
    return response.data;
  },

  async createTodo(data: CreateTodoDto): Promise<Todo> {
    const response = await api.post<Todo>('/todos', data);
    return response.data;
  },

  async updateTodo(id: number, data: UpdateTodoDto): Promise<Todo> {
    const response = await api.put<Todo>(`/todos/${id}`, data);
    return response.data;
  },

  async deleteTodo(id: number): Promise<void> {
    await api.delete(`/todos/${id}`);
  },

  async getSuggestion(): Promise<string> {
    const response = await api.get<{ suggestion: string }>('/todos/suggest/next');
    return response.data.suggestion;
  },
};
```

### 2.4 Create Todo Components

Create `src/components/TodoItem.tsx`:

**Copilot Prompt Suggestion:**
```typescript
// Create a TodoItem component that:
// - Displays todo title, description, and checkbox
// - Shows created date in relative format
// - Has edit and delete buttons
// - Toggles completed state on checkbox change
// - Uses Tailwind classes for styling
// - Handles loading states during updates
// Props: todo, onUpdate, onDelete
```

**Expected Copilot Output:**
```typescript
import React, { useState } from 'react';
import { Todo, UpdateTodoDto } from '../api/todoApi';

interface TodoItemProps {
  todo: Todo;
  onUpdate: (id: number, data: UpdateTodoDto) => Promise<void>;
  onDelete: (id: number) => Promise<void>;
}

export const TodoItem: React.FC<TodoItemProps> = ({ todo, onUpdate, onDelete }) => {
  const [isLoading, setIsLoading] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [editTitle, setEditTitle] = useState(todo.title);
  const [editDescription, setEditDescription] = useState(todo.description || '');

  const handleToggleComplete = async () => {
    setIsLoading(true);
    try {
      await onUpdate(todo.id, { completed: !todo.completed });
    } catch (error) {
      console.error('Failed to update todo:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSaveEdit = async () => {
    setIsLoading(true);
    try {
      await onUpdate(todo.id, { 
        title: editTitle, 
        description: editDescription 
      });
      setIsEditing(false);
    } catch (error) {
      console.error('Failed to update todo:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleDelete = async () => {
    if (window.confirm('Are you sure you want to delete this todo?')) {
      setIsLoading(true);
      try {
        await onDelete(todo.id);
      } catch (error) {
        console.error('Failed to delete todo:', error);
      } finally {
        setIsLoading(false);
      }
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffInHours = (now.getTime() - date.getTime()) / (1000 * 60 * 60);
    
    if (diffInHours < 1) return 'Just now';
    if (diffInHours < 24) return `${Math.floor(diffInHours)} hours ago`;
    if (diffInHours < 168) return `${Math.floor(diffInHours / 24)} days ago`;
    return date.toLocaleDateString();
  };

  if (isEditing) {
    return (
      <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
        <input
          type="text"
          value={editTitle}
          onChange={(e) => setEditTitle(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-md mb-2"
          placeholder="Todo title"
        />
        <textarea
          value={editDescription}
          onChange={(e) => setEditDescription(e.target.value)}
          className="w-full px-3 py-2 border border-gray-300 rounded-md mb-2"
          placeholder="Description (optional)"
          rows={2}
        />
        <div className="flex gap-2">
          <button
            onClick={handleSaveEdit}
            disabled={isLoading || !editTitle.trim()}
            className="px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 disabled:opacity-50"
          >
            Save
          </button>
          <button
            onClick={() => {
              setIsEditing(false);
              setEditTitle(todo.title);
              setEditDescription(todo.description || '');
            }}
            className="px-4 py-2 bg-gray-300 text-gray-700 rounded-md hover:bg-gray-400"
          >
            Cancel
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className={`bg-white p-4 rounded-lg shadow-sm border border-gray-200 
      ${todo.completed ? 'opacity-75' : ''} ${isLoading ? 'animate-pulse' : ''}`}>
      <div className="flex items-start gap-3">
        <input
          type="checkbox"
          checked={todo.completed}
          onChange={handleToggleComplete}
          disabled={isLoading}
          className="mt-1 w-5 h-5 text-primary-600 rounded focus:ring-primary-500"
        />
        <div className="flex-1">
          <h3 className={`text-lg font-medium ${todo.completed ? 'line-through text-gray-500' : ''}`}>
            {todo.title}
          </h3>
          {todo.description && (
            <p className="text-gray-600 mt-1">{todo.description}</p>
          )}
          <p className="text-sm text-gray-400 mt-2">
            Created {formatDate(todo.created_at)}
          </p>
        </div>
        <div className="flex gap-2">
          <button
            onClick={() => setIsEditing(true)}
            disabled={isLoading}
            className="text-gray-600 hover:text-primary-600 transition-colors"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} 
                d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
            </svg>
          </button>
          <button
            onClick={handleDelete}
            disabled={isLoading}
            className="text-gray-600 hover:text-red-600 transition-colors"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} 
                d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
            </svg>
          </button>
        </div>
      </div>
    </div>
  );
};
```

### 2.5 Create TodoForm Component

Create `src/components/TodoForm.tsx`:

**Copilot Prompt Suggestion:**
```typescript
// Create a TodoForm component that:
// - Has input for title (required) and description (optional)
// - Shows AI suggestion button that fills the title
// - Validates input before submission
// - Clears form after successful submission
// - Shows loading state during submission
// - Uses modern Tailwind styling
// Props: onSubmit callback
```

**Expected Copilot Output:**
```typescript
import React, { useState } from 'react';
import { CreateTodoDto } from '../api/todoApi';
import { todoApi } from '../api/todoApi';

interface TodoFormProps {
  onSubmit: (data: CreateTodoDto) => Promise<void>;
}

export const TodoForm: React.FC<TodoFormProps> = ({ onSubmit }) => {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isLoadingSuggestion, setIsLoadingSuggestion] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!title.trim()) {
      alert('Please enter a title');
      return;
    }

    setIsLoading(true);
    try {
      await onSubmit({ 
        title: title.trim(), 
        description: description.trim() || undefined 
      });
      
      // Clear form on success
      setTitle('');
      setDescription('');
    } catch (error) {
      console.error('Failed to create todo:', error);
      alert('Failed to create todo. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleGetSuggestion = async () => {
    setIsLoadingSuggestion(true);
    try {
      const suggestion = await todoApi.getSuggestion();
      setTitle(suggestion);
    } catch (error) {
      console.error('Failed to get suggestion:', error);
      alert('Failed to get suggestion. Please try again.');
    } finally {
      setIsLoadingSuggestion(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="bg-white p-6 rounded-lg shadow-md mb-6">
      <h2 className="text-xl font-semibold mb-4">Add New Todo</h2>
      
      <div className="mb-4">
        <label htmlFor="title" className="block text-sm font-medium text-gray-700 mb-1">
          Title *
        </label>
        <div className="flex gap-2">
          <input
            id="title"
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="What needs to be done?"
            className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500"
            disabled={isLoading}
            maxLength={200}
          />
          <button
            type="button"
            onClick={handleGetSuggestion}
            disabled={isLoading || isLoadingSuggestion}
            className="px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200 
              disabled:opacity-50 flex items-center gap-2 whitespace-nowrap"
          >
            {isLoadingSuggestion ? (
              <span className="inline-block animate-spin">⟳</span>
            ) : (
              <span>✨</span>
            )}
            AI Suggest
          </button>
        </div>
      </div>

      <div className="mb-4">
        <label htmlFor="description" className="block text-sm font-medium text-gray-700 mb-1">
          Description (optional)
        </label>
        <textarea
          id="description"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="Add more details..."
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500"
          disabled={isLoading}
          rows={3}
          maxLength={1000}
        />
      </div>

      <button
        type="submit"
        disabled={isLoading || !title.trim()}
        className="w-full px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 
          disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center gap-2"
      >
        {isLoading ? (
          <>
            <span className="inline-block animate-spin">⟳</span>
            Creating...
          </>
        ) : (
          <>
            <span>➕</span>
            Add Todo
          </>
        )}
      </button>
    </form>
  );
};
```

## ✅ Checkpoint 2

Before proceeding to the main app component, verify:
- [ ] All components are created without TypeScript errors
- [ ] Tailwind CSS is properly configured
- [ ] API client matches backend endpoints
- [ ] Components use proper TypeScript types
- [ ] No import errors in VS Code