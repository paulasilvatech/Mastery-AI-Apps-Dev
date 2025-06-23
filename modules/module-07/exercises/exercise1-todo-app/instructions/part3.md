# Exercise 1: AI-Powered Todo Application (Part 3)

## 📋 Step 3: Complete the Application (10 minutes)

### 3.1 Create Main App Component

Update `src/App.tsx`:

**Copilot Prompt Suggestion:**
```typescript
// Create the main App component that:
// - Uses React Query for data fetching and caching
// - Displays TodoForm at the top
// - Shows loading state while fetching todos
// - Filters todos by completed status with tabs
// - Lists todos using TodoItem component
// - Handles all CRUD operations with optimistic updates
// - Shows empty state when no todos
// - Uses responsive layout with Tailwind
```

**Expected Copilot Output:**
```typescript
import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { TodoForm } from './components/TodoForm';
import { TodoItem } from './components/TodoItem';
import { todoApi, Todo, CreateTodoDto, UpdateTodoDto } from './api/todoApi';

type FilterType = 'all' | 'active' | 'completed';

function App() {
  const [filter, setFilter] = useState<FilterType>('all');
  const queryClient = useQueryClient();

  // Fetch todos
  const { data, isLoading, error } = useQuery({
    queryKey: ['todos', filter],
    queryFn: () => {
      if (filter === 'all') return todoApi.getTodos();
      return todoApi.getTodos(filter === 'completed');
    },
  });

  // Create todo mutation
  const createMutation = useMutation({
    mutationFn: (newTodo: CreateTodoDto) => todoApi.createTodo(newTodo),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['todos'] });
    },
  });

  // Update todo mutation
  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: number; data: UpdateTodoDto }) => 
      todoApi.updateTodo(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['todos'] });
    },
  });

  // Delete todo mutation
  const deleteMutation = useMutation({
    mutationFn: (id: number) => todoApi.deleteTodo(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['todos'] });
    },
  });

  const handleCreateTodo = async (data: CreateTodoDto) => {
    await createMutation.mutateAsync(data);
  };

  const handleUpdateTodo = async (id: number, data: UpdateTodoDto) => {
    await updateMutation.mutateAsync({ id, data });
  };

  const handleDeleteTodo = async (id: number) => {
    await deleteMutation.mutateAsync(id);
  };

  const todos = data?.todos || [];
  const activeTodoCount = todos.filter(todo => !todo.completed).length;
  const completedTodoCount = todos.filter(todo => todo.completed).length;

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto px-4 py-8">
        {/* Header */}
        <header className="text-center mb-8">
          <h1 className="text-4xl font-bold text-gray-800 mb-2">
            ✨ AI-Powered Todo App
          </h1>
          <p className="text-gray-600">
            Built with React, FastAPI, and GitHub Copilot
          </p>
        </header>

        {/* Todo Form */}
        <TodoForm onSubmit={handleCreateTodo} />

        {/* Filter Tabs */}
        <div className="bg-white rounded-lg shadow-sm mb-6">
          <div className="flex border-b">
            <button
              onClick={() => setFilter('all')}
              className={`flex-1 px-4 py-3 text-sm font-medium transition-colors
                ${filter === 'all' 
                  ? 'text-primary-600 border-b-2 border-primary-600' 
                  : 'text-gray-500 hover:text-gray-700'}`}
            >
              All ({todos.length})
            </button>
            <button
              onClick={() => setFilter('active')}
              className={`flex-1 px-4 py-3 text-sm font-medium transition-colors
                ${filter === 'active' 
                  ? 'text-primary-600 border-b-2 border-primary-600' 
                  : 'text-gray-500 hover:text-gray-700'}`}
            >
              Active ({activeTodoCount})
            </button>
            <button
              onClick={() => setFilter('completed')}
              className={`flex-1 px-4 py-3 text-sm font-medium transition-colors
                ${filter === 'completed' 
                  ? 'text-primary-600 border-b-2 border-primary-600' 
                  : 'text-gray-500 hover:text-gray-700'}`}
            >
              Completed ({completedTodoCount})
            </button>
          </div>
        </div>

        {/* Todo List */}
        <div className="space-y-3">
          {isLoading && (
            <div className="text-center py-8">
              <div className="inline-block animate-spin text-4xl">⟳</div>
              <p className="text-gray-600 mt-2">Loading todos...</p>
            </div>
          )}

          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-md">
              Error loading todos. Please try again.
            </div>
          )}

          {!isLoading && !error && todos.length === 0 && (
            <div className="text-center py-12 bg-white rounded-lg">
              <div className="text-6xl mb-4">
                {filter === 'completed' ? '🎉' : '📝'}
              </div>
              <p className="text-gray-600">
                {filter === 'completed' 
                  ? 'No completed todos yet. Keep going!' 
                  : 'No todos yet. Create your first one above!'}
              </p>
            </div>
          )}

          {todos.map((todo) => (
            <TodoItem
              key={todo.id}
              todo={todo}
              onUpdate={handleUpdateTodo}
              onDelete={handleDeleteTodo}
            />
          ))}
        </div>

        {/* Footer Stats */}
        {todos.length > 0 && (
          <div className="mt-8 text-center text-sm text-gray-600">
            <p>
              {activeTodoCount} active, {completedTodoCount} completed, {todos.length} total
            </p>
          </div>
        )}
      </div>
    </div>
  );
}

export default App;
```

### 3.2 Setup React Query

Update `src/main.tsx`:

**Copilot Prompt Suggestion:**
```typescript
// Setup React Query provider with:
// - Default stale time of 5 minutes
// - Retry 3 times on failure
// - Show React Query devtools in development
```

**Expected Copilot Output:**
```typescript
import React from 'react'
import ReactDOM from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import App from './App.tsx'
import './index.css'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // 5 minutes
      retry: 3,
      retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000),
    },
  },
})

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <App />
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  </React.StrictMode>,
)
```

### 3.3 Install React Query DevTools

```bash
npm install -D @tanstack/react-query-devtools
```

## 📋 Step 4: Run and Test (5 minutes)

### 4.1 Start Both Servers

Terminal 1 - Backend:
```bash
cd backend
source venv/bin/activate  # Windows: .\venv\Scripts\activate
python run.py
```

Terminal 2 - Frontend:
```bash
cd frontend
npm run dev
```

### 4.2 Test All Features

1. **Create Todo**
   - Type a title and optional description
   - Click "Add Todo"
   - Verify it appears in the list

2. **AI Suggestions**
   - Click "AI Suggest" button
   - Verify it fills the title field

3. **Toggle Complete**
   - Click checkbox on a todo
   - Verify it moves to completed tab

4. **Edit Todo**
   - Click edit icon
   - Modify title/description
   - Save changes

5. **Delete Todo**
   - Click delete icon
   - Confirm deletion
   - Verify it's removed

6. **Filter Todos**
   - Switch between All/Active/Completed tabs
   - Verify counts are correct

### 4.3 Responsive Design Test

- Resize browser window
- Check mobile view (< 640px)
- Verify all features work on mobile

## 🎯 Success Criteria

Your todo application is complete when:
- [ ] All CRUD operations work correctly
- [ ] AI suggestions populate the title field
- [ ] Filters show correct todos and counts
- [ ] UI is responsive on all screen sizes
- [ ] No console errors in browser
- [ ] Loading states display properly
- [ ] Error states handle API failures

## 🚀 Extension Challenges

If you finish early, try these enhancements:

1. **Add Priority Levels**
   ```typescript
   // Add priority field to Todo model
   // Color-code todos by priority
   // Sort by priority
   ```

2. **Implement Search**
   ```typescript
   // Add search input to filter todos
   // Search in both title and description
   // Highlight matching text
   ```

3. **Add Due Dates**
   ```typescript
   // Add due_date field to backend
   // Show calendar picker in form
   // Highlight overdue todos
   ```

4. **Bulk Operations**
   ```typescript
   // Select multiple todos
   // Bulk complete/delete
   // Select all checkbox
   ```

## 📚 Key Takeaways

In this exercise, you learned to:
1. **Use Copilot for Full-Stack Development**
   - Generated backend models and API endpoints
   - Created React components with TypeScript
   - Implemented state management patterns

2. **Build Modern Web Applications**
   - RESTful API design
   - React with TypeScript
   - Tailwind CSS for styling
   - React Query for data fetching

3. **Apply Best Practices**
   - Proper error handling
   - Loading states
   - Type safety throughout
   - Responsive design

## 🎉 Congratulations!

You've successfully built your first AI-powered full-stack application! This foundation will serve you well in the upcoming exercises where we'll build more complex applications.

### Next Steps
- Review the solution code in `solution/` directory
- Compare your implementation with best practices
- Proceed to [Exercise 2: Blog Platform](modules/module-07/exercises/exercise2-blog-platform/README.md)

## 🆘 Troubleshooting

If you encounter issues:

**Frontend won't start:**
```bash
rm -rf node_modules package-lock.json
npm install
npm run dev
```

**CORS errors:**
- Ensure backend CORS allows `http://localhost:5173`
- Check backend is running on port 8000

**Database errors:**
- Delete `todos.db` and restart backend
- Check SQLite is installed

**TypeScript errors:**
- Run `npm run type-check`
- Ensure all imports have proper types

For more help, see the module troubleshooting guide or post in discussions.
