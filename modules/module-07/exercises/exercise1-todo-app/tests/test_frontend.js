/**
 * Frontend Tests for Todo Application
 * Using Jest and React Testing Library
 */

import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import App from '../starter/frontend/src/App';
import TodoList from '../starter/frontend/src/components/TodoList';
import TodoForm from '../starter/frontend/src/components/TodoForm';

// Mock fetch API
global.fetch = jest.fn();

describe('Todo Application Frontend', () => {
  beforeEach(() => {
    fetch.mockClear();
  });

  describe('App Component', () => {
    test('renders without crashing', () => {
      fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ todos: [], total: 0 }),
      });

      render(<App />);
      expect(screen.getByText(/AI-Powered Todo/i)).toBeInTheDocument();
    });

    test('loads todos on mount', async () => {
      const mockTodos = [
        {
          id: 1,
          title: 'Test Todo 1',
          description: 'Description 1',
          completed: false,
          created_at: '2024-01-01T00:00:00',
          updated_at: '2024-01-01T00:00:00',
        },
        {
          id: 2,
          title: 'Test Todo 2',
          description: 'Description 2',
          completed: true,
          created_at: '2024-01-01T00:00:00',
          updated_at: '2024-01-01T00:00:00',
        },
      ];

      fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ todos: mockTodos, total: 2 }),
      });

      render(<App />);

      await waitFor(() => {
        expect(screen.getByText('Test Todo 1')).toBeInTheDocument();
        expect(screen.getByText('Test Todo 2')).toBeInTheDocument();
      });
    });
  });

  describe('TodoForm Component', () => {
    test('renders form inputs', () => {
      const mockOnSubmit = jest.fn();
      render(<TodoForm onSubmit={mockOnSubmit} />);

      expect(screen.getByPlaceholderText(/Enter todo title/i)).toBeInTheDocument();
      expect(screen.getByPlaceholderText(/Enter description/i)).toBeInTheDocument();
      expect(screen.getByText(/Add Todo/i)).toBeInTheDocument();
    });

    test('calls onSubmit with form data', async () => {
      const mockOnSubmit = jest.fn();
      render(<TodoForm onSubmit={mockOnSubmit} />);

      const titleInput = screen.getByPlaceholderText(/Enter todo title/i);
      const descriptionInput = screen.getByPlaceholderText(/Enter description/i);
      const submitButton = screen.getByText(/Add Todo/i);

      fireEvent.change(titleInput, { target: { value: 'New Todo' } });
      fireEvent.change(descriptionInput, { target: { value: 'New Description' } });
      fireEvent.click(submitButton);

      await waitFor(() => {
        expect(mockOnSubmit).toHaveBeenCalledWith({
          title: 'New Todo',
          description: 'New Description',
        });
      });
    });

    test('validates required title field', () => {
      const mockOnSubmit = jest.fn();
      render(<TodoForm onSubmit={mockOnSubmit} />);

      const submitButton = screen.getByText(/Add Todo/i);
      fireEvent.click(submitButton);

      expect(mockOnSubmit).not.toHaveBeenCalled();
    });

    test('shows AI suggestion button', () => {
      const mockOnSubmit = jest.fn();
      render(<TodoForm onSubmit={mockOnSubmit} />);

      expect(screen.getByText(/Get AI Suggestion/i)).toBeInTheDocument();
    });
  });

  describe('TodoList Component', () => {
    const mockTodos = [
      {
        id: 1,
        title: 'Test Todo',
        description: 'Test Description',
        completed: false,
        created_at: '2024-01-01T00:00:00',
        updated_at: '2024-01-01T00:00:00',
      },
    ];

    test('renders todo items', () => {
      render(
        <TodoList
          todos={mockTodos}
          onToggle={jest.fn()}
          onDelete={jest.fn()}
        />
      );

      expect(screen.getByText('Test Todo')).toBeInTheDocument();
      expect(screen.getByText('Test Description')).toBeInTheDocument();
    });

    test('calls onToggle when checkbox clicked', () => {
      const mockOnToggle = jest.fn();
      render(
        <TodoList
          todos={mockTodos}
          onToggle={mockOnToggle}
          onDelete={jest.fn()}
        />
      );

      const checkbox = screen.getByRole('checkbox');
      fireEvent.click(checkbox);

      expect(mockOnToggle).toHaveBeenCalledWith(1);
    });

    test('calls onDelete when delete button clicked', () => {
      const mockOnDelete = jest.fn();
      render(
        <TodoList
          todos={mockTodos}
          onToggle={jest.fn()}
          onDelete={mockOnDelete}
        />
      );

      const deleteButton = screen.getByText(/Delete/i);
      fireEvent.click(deleteButton);

      expect(mockOnDelete).toHaveBeenCalledWith(1);
    });

    test('shows empty state when no todos', () => {
      render(
        <TodoList
          todos={[]}
          onToggle={jest.fn()}
          onDelete={jest.fn()}
        />
      );

      expect(screen.getByText(/No todos yet/i)).toBeInTheDocument();
    });

    test('applies completed styling', () => {
      const completedTodos = [
        { ...mockTodos[0], completed: true },
      ];

      render(
        <TodoList
          todos={completedTodos}
          onToggle={jest.fn()}
          onDelete={jest.fn()}
        />
      );

      const todoTitle = screen.getByText('Test Todo');
      expect(todoTitle).toHaveClass('line-through');
    });
  });

  describe('Integration Tests', () => {
    test('creates a new todo', async () => {
      fetch
        .mockResolvedValueOnce({
          ok: true,
          json: async () => ({ todos: [], total: 0 }),
        })
        .mockResolvedValueOnce({
          ok: true,
          json: async () => ({
            id: 1,
            title: 'New Todo',
            description: 'New Description',
            completed: false,
            created_at: '2024-01-01T00:00:00',
            updated_at: '2024-01-01T00:00:00',
          }),
        })
        .mockResolvedValueOnce({
          ok: true,
          json: async () => ({
            todos: [{
              id: 1,
              title: 'New Todo',
              description: 'New Description',
              completed: false,
              created_at: '2024-01-01T00:00:00',
              updated_at: '2024-01-01T00:00:00',
            }],
            total: 1,
          }),
        });

      render(<App />);

      const titleInput = screen.getByPlaceholderText(/Enter todo title/i);
      const submitButton = screen.getByText(/Add Todo/i);

      fireEvent.change(titleInput, { target: { value: 'New Todo' } });
      fireEvent.click(submitButton);

      await waitFor(() => {
        expect(screen.getByText('New Todo')).toBeInTheDocument();
      });
    });

    test('toggles todo completion', async () => {
      const mockTodo = {
        id: 1,
        title: 'Toggle Me',
        completed: false,
        created_at: '2024-01-01T00:00:00',
        updated_at: '2024-01-01T00:00:00',
      };

      fetch
        .mockResolvedValueOnce({
          ok: true,
          json: async () => ({ todos: [mockTodo], total: 1 }),
        })
        .mockResolvedValueOnce({
          ok: true,
          json: async () => ({ ...mockTodo, completed: true }),
        })
        .mockResolvedValueOnce({
          ok: true,
          json: async () => ({
            todos: [{ ...mockTodo, completed: true }],
            total: 1,
          }),
        });

      render(<App />);

      await waitFor(() => {
        expect(screen.getByText('Toggle Me')).toBeInTheDocument();
      });

      const checkbox = screen.getByRole('checkbox');
      fireEvent.click(checkbox);

      await waitFor(() => {
        expect(checkbox).toBeChecked();
      });
    });
  });
});