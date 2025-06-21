# Exercise 3: AI Operations Dashboard (Part 4)

## 📋 Step 4: Frontend Dashboard Implementation (15 minutes)

### 4.1 Create React Application

```bash
# From exercise3-ai-dashboard directory
npm create vite@latest frontend -- --template react-ts
cd frontend

# Install dependencies
npm install

# Core dependencies
npm install axios react-router-dom @tanstack/react-query
npm install react-hook-form @hookform/resolvers zod
npm install recharts react-grid-layout
npm install socket.io-client date-fns
npm install react-hot-toast lucide-react
npm install @headlessui/react clsx

# Development dependencies
npm install -D @types/react @types/react-dom
npm install -D tailwindcss postcss autoprefixer
npm install -D @types/react-grid-layout
```

### 4.2 Configure Tailwind CSS

```bash
npx tailwindcss init -p
```

Update `tailwind.config.js`:

**Copilot Prompt Suggestion:**
```javascript
// Configure Tailwind for dashboard with:
// - Dark mode support
// - Custom colors for metrics (success, warning, error, info)
// - Animation utilities for real-time updates
// - Grid system for dashboard layout
// - Custom shadows for cards
```

**Expected Copilot Output:**
```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#eff6ff',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          900: '#1e3a8a',
        },
        success: {
          50: '#f0fdf4',
          500: '#22c55e',
          700: '#15803d',
        },
        warning: {
          50: '#fefce8',
          500: '#eab308',
          700: '#a16207',
        },
        error: {
          50: '#fef2f2',
          500: '#ef4444',
          700: '#b91c1c',
        },
        dark: {
          800: '#1e293b',
          900: '#0f172a',
        }
      },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'slide-in': 'slideIn 0.3s ease-out',
        'fade-in': 'fadeIn 0.5s ease-in',
      },
      keyframes: {
        slideIn: {
          '0%': { transform: 'translateX(100%)' },
          '100%': { transform: 'translateX(0)' },
        },
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
      },
      gridTemplateColumns: {
        'dashboard': 'repeat(auto-fit, minmax(300px, 1fr))',
      },
      boxShadow: {
        'card': '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06)',
        'card-hover': '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
      },
    },
  },
  plugins: [],
}
```

### 4.3 WebSocket Hook

Create `src/hooks/useWebSocket.ts`:

**Copilot Prompt Suggestion:**
```typescript
// Create WebSocket hook that:
// - Connects with authentication token
// - Handles reconnection automatically
// - Manages subscriptions to agent channels
// - Provides real-time metric updates
// - Handles connection status
// - Implements exponential backoff for reconnection
// Include TypeScript types for all messages
```

**Expected Copilot Output:**
```typescript
import { useEffect, useRef, useState, useCallback } from 'react';
import { toast } from 'react-hot-toast';

interface WebSocketMessage {
  type: string;
  channel?: string;
  data?: any;
  timestamp?: string;
}

interface WebSocketHook {
  isConnected: boolean;
  subscribe: (channel: string) => void;
  unsubscribe: (channel: string) => void;
  lastMessage: WebSocketMessage | null;
  connectionStatus: 'connecting' | 'connected' | 'disconnected' | 'error';
}

export function useWebSocket(token: string | null): WebSocketHook {
  const ws = useRef<WebSocket | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  const [connectionStatus, setConnectionStatus] = useState<WebSocketHook['connectionStatus']>('disconnected');
  const [lastMessage, setLastMessage] = useState<WebSocketMessage | null>(null);
  const reconnectTimeout = useRef<NodeJS.Timeout>();
  const reconnectAttempts = useRef(0);
  const subscriptions = useRef<Set<string>>(new Set());

  const connect = useCallback(() => {
    if (!token || ws.current?.readyState === WebSocket.OPEN) return;

    setConnectionStatus('connecting');
    
    try {
      ws.current = new WebSocket(
        `${import.meta.env.VITE_WS_URL || 'ws://localhost:8000'}/api/ws?token=${token}`
      );

      ws.current.onopen = () => {
        setIsConnected(true);
        setConnectionStatus('connected');
        reconnectAttempts.current = 0;
        
        // Resubscribe to channels
        subscriptions.current.forEach(channel => {
          ws.current?.send(JSON.stringify({
            type: 'subscribe',
            channel
          }));
        });

        toast.success('Connected to real-time updates');
      };

      ws.current.onmessage = (event) => {
        try {
          const message = JSON.parse(event.data) as WebSocketMessage;
          setLastMessage(message);

          // Handle specific message types
          switch (message.type) {
            case 'ping':
              ws.current?.send(JSON.stringify({ type: 'pong' }));
              break;
            case 'error':
              toast.error(message.data?.message || 'WebSocket error');
              break;
          }
        } catch (error) {
          console.error('Failed to parse WebSocket message:', error);
        }
      };

      ws.current.onerror = (error) => {
        console.error('WebSocket error:', error);
        setConnectionStatus('error');
      };

      ws.current.onclose = () => {
        setIsConnected(false);
        setConnectionStatus('disconnected');
        
        // Reconnect with exponential backoff
        if (reconnectAttempts.current < 5) {
          const delay = Math.min(1000 * Math.pow(2, reconnectAttempts.current), 30000);
          reconnectAttempts.current++;
          
          reconnectTimeout.current = setTimeout(() => {
            connect();
          }, delay);
        } else {
          toast.error('Failed to connect to real-time updates');
        }
      };
    } catch (error) {
      console.error('Failed to create WebSocket:', error);
      setConnectionStatus('error');
    }
  }, [token]);

  const disconnect = useCallback(() => {
    if (reconnectTimeout.current) {
      clearTimeout(reconnectTimeout.current);
    }
    
    if (ws.current) {
      ws.current.close();
      ws.current = null;
    }
    
    setIsConnected(false);
    setConnectionStatus('disconnected');
    subscriptions.current.clear();
  }, []);

  const subscribe = useCallback((channel: string) => {
    subscriptions.current.add(channel);
    
    if (ws.current?.readyState === WebSocket.OPEN) {
      ws.current.send(JSON.stringify({
        type: 'subscribe',
        channel
      }));
    }
  }, []);

  const unsubscribe = useCallback((channel: string) => {
    subscriptions.current.delete(channel);
    
    if (ws.current?.readyState === WebSocket.OPEN) {
      ws.current.send(JSON.stringify({
        type: 'unsubscribe',
        channel
      }));
    }
  }, []);

  useEffect(() => {
    if (token) {
      connect();
    } else {
      disconnect();
    }

    return () => {
      disconnect();
    };
  }, [token, connect, disconnect]);

  return {
    isConnected,
    connectionStatus,
    subscribe,
    unsubscribe,
    lastMessage
  };
}
```

### 4.4 Dashboard Layout Component

Create `src/components/Dashboard/DashboardLayout.tsx`:

**Copilot Prompt Suggestion:**
```typescript
// Create dashboard layout component that:
// - Provides responsive grid layout
// - Has dark mode toggle
// - Shows connection status indicator
// - Includes navigation sidebar
// - Displays user info and logout
// - Handles role-based menu items
// Use React Grid Layout for draggable widgets
```

**Expected Copilot Output:**
```typescript
import React, { useState } from 'react';
import { Outlet, Link, useNavigate } from 'react-router-dom';
import { 
  LayoutDashboard, 
  Bot, 
  AlertCircle, 
  Settings, 
  LogOut,
  Moon,
  Sun,
  Wifi,
  WifiOff
} from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';
import { useWebSocket } from '../../hooks/useWebSocket';

export function DashboardLayout() {
  const [darkMode, setDarkMode] = useState(false);
  const { user, logout } = useAuth();
  const { isConnected } = useWebSocket(user?.token || null);
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const toggleDarkMode = () => {
    setDarkMode(!darkMode);
    document.documentElement.classList.toggle('dark');
  };

  const menuItems = [
    { 
      icon: LayoutDashboard, 
      label: 'Overview', 
      path: '/', 
      roles: ['admin', 'developer', 'viewer'] 
    },
    { 
      icon: Bot, 
      label: 'Agents', 
      path: '/agents', 
      roles: ['admin', 'developer', 'viewer'] 
    },
    { 
      icon: AlertCircle, 
      label: 'Alerts', 
      path: '/alerts', 
      roles: ['admin', 'developer', 'viewer'] 
    },
    { 
      icon: Settings, 
      label: 'Settings', 
      path: '/settings', 
      roles: ['admin'] 
    },
  ];

  const filteredMenuItems = menuItems.filter(
    item => item.roles.includes(user?.role || 'viewer')
  );

  return (
    <div className={`min-h-screen ${darkMode ? 'dark' : ''}`}>
      <div className="flex h-screen bg-gray-50 dark:bg-dark-900">
        {/* Sidebar */}
        <div className="w-64 bg-white dark:bg-dark-800 shadow-lg">
          <div className="flex items-center justify-between p-4 border-b dark:border-gray-700">
            <h1 className="text-xl font-bold text-gray-800 dark:text-white">
              AI Dashboard
            </h1>
            <button
              onClick={toggleDarkMode}
              className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
            >
              {darkMode ? 
                <Sun className="w-5 h-5 text-gray-600 dark:text-gray-300" /> : 
                <Moon className="w-5 h-5 text-gray-600" />
              }
            </button>
          </div>

          {/* Navigation */}
          <nav className="mt-6">
            {filteredMenuItems.map((item) => (
              <Link
                key={item.path}
                to={item.path}
                className="flex items-center gap-3 px-4 py-3 text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
              >
                <item.icon className="w-5 h-5" />
                <span>{item.label}</span>
              </Link>
            ))}
          </nav>

          {/* User Info */}
          <div className="absolute bottom-0 left-0 right-0 p-4 border-t dark:border-gray-700">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 bg-primary-500 rounded-full flex items-center justify-center text-white font-semibold">
                  {user?.username?.[0]?.toUpperCase()}
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-700 dark:text-gray-200">
                    {user?.username}
                  </p>
                  <p className="text-xs text-gray-500 dark:text-gray-400">
                    {user?.role}
                  </p>
                </div>
              </div>
              <button
                onClick={handleLogout}
                className="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
              >
                <LogOut className="w-4 h-4" />
              </button>
            </div>

            {/* Connection Status */}
            <div className="flex items-center gap-2 text-xs">
              {isConnected ? (
                <>
                  <Wifi className="w-4 h-4 text-success-500" />
                  <span className="text-success-600 dark:text-success-400">
                    Connected
                  </span>
                </>
              ) : (
                <>
                  <WifiOff className="w-4 h-4 text-error-500" />
                  <span className="text-error-600 dark:text-error-400">
                    Disconnected
                  </span>
                </>
              )}
            </div>
          </div>
        </div>

        {/* Main Content */}
        <div className="flex-1 overflow-auto">
          <Outlet />
        </div>
      </div>
    </div>
  );
}
```

### 4.5 Real-time Metrics Chart

Create `src/components/Charts/MetricsChart.tsx`:

**Copilot Prompt Suggestion:**
```typescript
// Create real-time metrics chart component that:
// - Uses Recharts for line charts
// - Updates smoothly with WebSocket data
// - Shows CPU, memory, requests, errors
// - Has time range selector (5m, 1h, 24h)
// - Displays current value and trend
// - Supports dark mode
// - Shows loading and error states
```

**Expected Copilot Output:**
```typescript
import React, { useState, useEffect } from 'react';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend
} from 'recharts';
import { format } from 'date-fns';
import { TrendingUp, TrendingDown, Minus } from 'lucide-react';
import { useWebSocket } from '../../hooks/useWebSocket';
import { useTheme } from '../../hooks/useTheme';

interface MetricsChartProps {
  agentId: number;
  metricType: 'cpu' | 'memory' | 'requests' | 'errors';
  title: string;
  unit?: string;
  color?: string;
}

interface MetricData {
  timestamp: string;
  value: number;
}

export function MetricsChart({ 
  agentId, 
  metricType, 
  title, 
  unit = '%',
  color = '#3b82f6'
}: MetricsChartProps) {
  const [timeRange, setTimeRange] = useState<'5m' | '1h' | '24h'>('1h');
  const [data, setData] = useState<MetricData[]>([]);
  const [currentValue, setCurrentValue] = useState<number>(0);
  const [trend, setTrend] = useState<'up' | 'down' | 'stable'>('stable');
  const { lastMessage, subscribe, unsubscribe } = useWebSocket();
  const { isDark } = useTheme();

  useEffect(() => {
    const channel = `agent:${agentId}`;
    subscribe(channel);

    return () => {
      unsubscribe(channel);
    };
  }, [agentId, subscribe, unsubscribe]);

  useEffect(() => {
    if (lastMessage?.type === 'metrics' && 
        lastMessage.data?.metric_type === metricType) {
      const newPoint: MetricData = {
        timestamp: lastMessage.timestamp || new Date().toISOString(),
        value: lastMessage.data.value
      };

      setData(prev => {
        const updated = [...prev, newPoint];
        // Keep only data within time range
        const cutoff = new Date();
        if (timeRange === '5m') cutoff.setMinutes(cutoff.getMinutes() - 5);
        else if (timeRange === '1h') cutoff.setHours(cutoff.getHours() - 1);
        else cutoff.setHours(cutoff.getHours() - 24);

        return updated.filter(
          point => new Date(point.timestamp) > cutoff
        );
      });

      setCurrentValue(newPoint.value);

      // Calculate trend
      if (data.length > 10) {
        const recent = data.slice(-10);
        const avgRecent = recent.reduce((sum, d) => sum + d.value, 0) / recent.length;
        const avgPrevious = data.slice(-20, -10).reduce((sum, d) => sum + d.value, 0) / 10;
        
        if (avgRecent > avgPrevious * 1.05) setTrend('up');
        else if (avgRecent < avgPrevious * 0.95) setTrend('down');
        else setTrend('stable');
      }
    }
  }, [lastMessage, metricType, data, timeRange]);

  const formatTimestamp = (timestamp: string) => {
    const date = new Date(timestamp);
    if (timeRange === '5m') return format(date, 'HH:mm:ss');
    if (timeRange === '1h') return format(date, 'HH:mm');
    return format(date, 'MMM dd HH:mm');
  };

  const getTrendIcon = () => {
    switch (trend) {
      case 'up':
        return <TrendingUp className="w-4 h-4 text-error-500" />;
      case 'down':
        return <TrendingDown className="w-4 h-4 text-success-500" />;
      default:
        return <Minus className="w-4 h-4 text-gray-500" />;
    }
  };

  const getValueColor = () => {
    if (metricType === 'cpu' || metricType === 'memory') {
      if (currentValue > 90) return 'text-error-600';
      if (currentValue > 70) return 'text-warning-600';
    }
    if (metricType === 'errors') {
      if (currentValue > 10) return 'text-error-600';
      if (currentValue > 5) return 'text-warning-600';
    }
    return 'text-gray-700 dark:text-gray-200';
  };

  return (
    <div className="bg-white dark:bg-dark-800 rounded-lg shadow-card p-6">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <h3 className="text-lg font-semibold text-gray-800 dark:text-white">
            {title}
          </h3>
          <div className="flex items-center gap-2 mt-1">
            <span className={`text-2xl font-bold ${getValueColor()}`}>
              {currentValue.toFixed(1)}{unit}
            </span>
            {getTrendIcon()}
          </div>
        </div>

        {/* Time Range Selector */}
        <div className="flex gap-1 bg-gray-100 dark:bg-gray-700 rounded-lg p-1">
          {(['5m', '1h', '24h'] as const).map(range => (
            <button
              key={range}
              onClick={() => setTimeRange(range)}
              className={`px-3 py-1 text-sm rounded transition-colors ${
                timeRange === range
                  ? 'bg-white dark:bg-gray-600 text-primary-600 dark:text-primary-400 shadow-sm'
                  : 'text-gray-600 dark:text-gray-300 hover:text-gray-800'
              }`}
            >
              {range}
            </button>
          ))}
        </div>
      </div>

      {/* Chart */}
      <div className="h-48">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={data} margin={{ top: 5, right: 5, left: 5, bottom: 5 }}>
            <CartesianGrid 
              strokeDasharray="3 3" 
              stroke={isDark ? '#374151' : '#e5e7eb'}
            />
            <XAxis 
              dataKey="timestamp"
              tickFormatter={formatTimestamp}
              stroke={isDark ? '#9ca3af' : '#6b7280'}
              fontSize={12}
            />
            <YAxis 
              stroke={isDark ? '#9ca3af' : '#6b7280'}
              fontSize={12}
              domain={[0, 100]}
            />
            <Tooltip
              contentStyle={{
                backgroundColor: isDark ? '#1f2937' : '#ffffff',
                border: `1px solid ${isDark ? '#374151' : '#e5e7eb'}`,
                borderRadius: '6px',
              }}
              labelFormatter={(value) => formatTimestamp(value as string)}
              formatter={(value: number) => [`${value.toFixed(2)}${unit}`, title]}
            />
            <Line
              type="monotone"
              dataKey="value"
              stroke={color}
              strokeWidth={2}
              dot={false}
              animationDuration={300}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
```

### 4.6 Agent Status Card

Create `src/components/Agent/AgentCard.tsx`:

**Copilot Prompt Suggestion:**
```typescript
// Create agent status card component that:
// - Shows agent name, type, and status
// - Displays real-time health indicators
// - Has quick action buttons (start, stop, scale)
// - Shows replica count with adjustment controls
// - Indicates alerts with badge
// - Updates in real-time via WebSocket
// - Has loading states for actions
```

**Expected Copilot Output:**
```typescript
import React, { useState, useEffect } from 'react';
import { 
  Play, 
  Square, 
  AlertTriangle, 
  Settings,
  Plus,
  Minus,
  Activity
} from 'lucide-react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'react-hot-toast';
import { agentApi } from '../../api/agents';
import { useWebSocket } from '../../hooks/useWebSocket';

interface AgentCardProps {
  agent: {
    id: number;
    name: string;
    type: string;
    status: 'running' | 'stopped' | 'error' | 'deploying';
    replica_count: number;
    health?: {
      healthy: boolean;
      metrics?: {
        cpu?: { current: number };
        memory?: { current: number };
      };
    };
  };
  onViewDetails: (id: number) => void;
}

export function AgentCard({ agent, onViewDetails }: AgentCardProps) {
  const [status, setStatus] = useState(agent.status);
  const [replicas, setReplicas] = useState(agent.replica_count);
  const [health, setHealth] = useState(agent.health);
  const { lastMessage, subscribe, unsubscribe } = useWebSocket();
  const queryClient = useQueryClient();

  useEffect(() => {
    const channel = `agent:${agent.id}`;
    subscribe(channel);

    return () => {
      unsubscribe(channel);
    };
  }, [agent.id, subscribe, unsubscribe]);

  useEffect(() => {
    if (lastMessage?.agent_id === agent.id) {
      if (lastMessage.type === 'status') {
        setStatus(lastMessage.data.status);
      } else if (lastMessage.type === 'health') {
        setHealth(lastMessage.data);
      }
    }
  }, [lastMessage, agent.id]);

  const startMutation = useMutation({
    mutationFn: () => agentApi.startAgent(agent.id),
    onSuccess: () => {
      toast.success('Agent started');
      queryClient.invalidateQueries(['agents']);
    },
  });

  const stopMutation = useMutation({
    mutationFn: () => agentApi.stopAgent(agent.id),
    onSuccess: () => {
      toast.success('Agent stopped');
      queryClient.invalidateQueries(['agents']);
    },
  });

  const scaleMutation = useMutation({
    mutationFn: (newReplicas: number) => 
      agentApi.scaleAgent(agent.id, newReplicas),
    onSuccess: () => {
      toast.success('Agent scaled');
      queryClient.invalidateQueries(['agents']);
    },
  });

  const handleScale = (delta: number) => {
    const newReplicas = Math.max(0, Math.min(20, replicas + delta));
    setReplicas(newReplicas);
    scaleMutation.mutate(newReplicas);
  };

  const getStatusColor = () => {
    switch (status) {
      case 'running':
        return 'bg-success-100 text-success-700 dark:bg-success-900 dark:text-success-300';
      case 'stopped':
        return 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300';
      case 'error':
        return 'bg-error-100 text-error-700 dark:bg-error-900 dark:text-error-300';
      case 'deploying':
        return 'bg-warning-100 text-warning-700 dark:bg-warning-900 dark:text-warning-300';
    }
  };

  const isLoading = startMutation.isLoading || 
                   stopMutation.isLoading || 
                   scaleMutation.isLoading;

  return (
    <div className="bg-white dark:bg-dark-800 rounded-lg shadow-card hover:shadow-card-hover transition-shadow p-6">
      {/* Header */}
      <div className="flex items-start justify-between mb-4">
        <div>
          <h3 className="text-lg font-semibold text-gray-800 dark:text-white">
            {agent.name}
          </h3>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            {agent.type}
          </p>
        </div>
        <span className={`px-3 py-1 text-xs font-medium rounded-full ${getStatusColor()}`}>
          {status}
        </span>
      </div>

      {/* Health Metrics */}
      {health?.healthy && health.metrics && (
        <div className="grid grid-cols-2 gap-3 mb-4">
          <div className="bg-gray-50 dark:bg-gray-700 rounded p-3">
            <div className="flex items-center justify-between">
              <span className="text-xs text-gray-600 dark:text-gray-300">CPU</span>
              <Activity className="w-3 h-3 text-gray-400" />
            </div>
            <p className="text-lg font-semibold text-gray-800 dark:text-white mt-1">
              {health.metrics.cpu?.current.toFixed(1)}%
            </p>
          </div>
          <div className="bg-gray-50 dark:bg-gray-700 rounded p-3">
            <div className="flex items-center justify-between">
              <span className="text-xs text-gray-600 dark:text-gray-300">Memory</span>
              <Activity className="w-3 h-3 text-gray-400" />
            </div>
            <p className="text-lg font-semibold text-gray-800 dark:text-white mt-1">
              {health.metrics.memory?.current.toFixed(1)}%
            </p>
          </div>
        </div>
      )}

      {/* Replica Control */}
      <div className="flex items-center justify-between mb-4">
        <span className="text-sm text-gray-600 dark:text-gray-300">Replicas</span>
        <div className="flex items-center gap-2">
          <button
            onClick={() => handleScale(-1)}
            disabled={isLoading || replicas === 0}
            className="p-1 rounded hover:bg-gray-100 dark:hover:bg-gray-700 disabled:opacity-50"
          >
            <Minus className="w-4 h-4" />
          </button>
          <span className="w-8 text-center font-medium">{replicas}</span>
          <button
            onClick={() => handleScale(1)}
            disabled={isLoading || replicas >= 20}
            className="p-1 rounded hover:bg-gray-100 dark:hover:bg-gray-700 disabled:opacity-50"
          >
            <Plus className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Actions */}
      <div className="flex gap-2">
        {status === 'stopped' ? (
          <button
            onClick={() => startMutation.mutate()}
            disabled={isLoading}
            className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50 transition-colors"
          >
            <Play className="w-4 h-4" />
            Start
          </button>
        ) : (
          <button
            onClick={() => stopMutation.mutate()}
            disabled={isLoading || status !== 'running'}
            className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 disabled:opacity-50 transition-colors"
          >
            <Square className="w-4 h-4" />
            Stop
          </button>
        )}
        
        <button
          onClick={() => onViewDetails(agent.id)}
          className="px-4 py-2 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-200 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
        >
          <Settings className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}
```

## 📋 Step 5: Final Integration (10 minutes)

### 5.1 Create Dashboard Overview Page

Create `src/pages/Overview.tsx`:

```typescript
import React from 'react';
import { useQuery } from '@tanstack/react-query';
import GridLayout from 'react-grid-layout';
import { MetricsChart } from '../components/Charts/MetricsChart';
import { AgentCard } from '../components/Agent/AgentCard';
import { AlertsList } from '../components/Alerts/AlertsList';
import { SystemHealth } from '../components/System/SystemHealth';
import { dashboardApi } from '../api/dashboard';
import 'react-grid-layout/css/styles.css';
import 'react-resizable/css/styles.css';

export function Overview() {
  const { data: agents } = useQuery(['agents'], dashboardApi.getAgents);
  const { data: systemHealth } = useQuery(['system-health'], dashboardApi.getSystemHealth);

  const layout = [
    { i: 'system-health', x: 0, y: 0, w: 12, h: 2 },
    { i: 'agents-grid', x: 0, y: 2, w: 8, h: 4 },
    { i: 'alerts', x: 8, y: 2, w: 4, h: 4 },
    { i: 'metrics', x: 0, y: 6, w: 12, h: 3 },
  ];

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold text-gray-800 dark:text-white mb-6">
        AI Operations Dashboard
      </h1>

      <GridLayout
        className="layout"
        layout={layout}
        cols={12}
        rowHeight={100}
        width={1200}
        isDraggable={true}
        isResizable={true}
      >
        <div key="system-health">
          <SystemHealth data={systemHealth} />
        </div>
        
        <div key="agents-grid" className="grid grid-cols-2 gap-4 overflow-auto">
          {agents?.map(agent => (
            <AgentCard 
              key={agent.id} 
              agent={agent} 
              onViewDetails={(id) => console.log('View', id)}
            />
          ))}
        </div>
        
        <div key="alerts">
          <AlertsList />
        </div>
        
        <div key="metrics" className="grid grid-cols-4 gap-4">
          {agents?.slice(0, 4).map(agent => (
            <MetricsChart
              key={agent.id}
              agentId={agent.id}
              metricType="cpu"
              title={`${agent.name} CPU`}
            />
          ))}
        </div>
      </GridLayout>
    </div>
  );
}
```

### 5.2 Run the Complete Application

1. Start all backend services:
   ```bash
   cd backend
   docker-compose up -d
   python -m uvicorn app.main:app --reload
   ```

2. Start the frontend:
   ```bash
   cd frontend
   npm run dev
   ```

3. Access the dashboard at http://localhost:5173

## ✅ Success Criteria

Your AI Operations Dashboard is complete when:
- [ ] Real-time metrics update via WebSocket
- [ ] Agents can be started, stopped, and scaled
- [ ] Charts display historical and live data
- [ ] Alerts appear in real-time
- [ ] Role-based access control works
- [ ] Dashboard layout is customizable
- [ ] Dark mode functions properly
- [ ] All actions provide feedback

## 🚀 Extension Challenges

1. **Add Deployment Pipeline**
   - GitHub integration
   - Automated deployments
   - Rollback functionality

2. **Enhanced Monitoring**
   - Log streaming
   - Distributed tracing
   - Custom metrics

3. **Advanced Features**
   - Auto-scaling policies
   - Cost optimization
   - Performance predictions

## 🎉 Congratulations!

You've built a production-ready AI operations dashboard with:
- Real-time monitoring capabilities
- Complex state management
- WebSocket integration
- Professional UI/UX
- Enterprise-grade architecture

This dashboard demonstrates mastery of:
- Full-stack development
- Real-time systems
- Data visualization
- Cloud-native patterns
- Production deployment

## 📚 Key Takeaways

1. **Real-time Architecture**
   - WebSocket for live updates
   - Event-driven design
   - Efficient data streaming

2. **Production Patterns**
   - Role-based access
   - Comprehensive monitoring
   - Error handling
   - Performance optimization

3. **AI-Assisted Development**
   - Complex component generation
   - Architecture suggestions
   - Integration patterns

### Next Steps
- Deploy to Azure Kubernetes Service
- Add more agent types
- Implement ML-based anomaly detection
- Create mobile dashboard app

You're now ready to build and deploy production AI systems!