import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { TodoForm } from './components/TodoForm';
import { TodoItem } from './components/TodoItem';
import { todoApi, CreateTodoDto, UpdateTodoDto } from './api/todoApi';

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