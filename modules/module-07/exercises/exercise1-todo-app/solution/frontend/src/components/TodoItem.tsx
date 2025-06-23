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