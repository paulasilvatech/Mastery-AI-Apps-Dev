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