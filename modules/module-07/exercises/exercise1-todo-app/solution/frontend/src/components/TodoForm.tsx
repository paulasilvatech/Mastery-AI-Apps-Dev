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