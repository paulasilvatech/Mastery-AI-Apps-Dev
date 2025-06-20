# Module 07: Additional Resources

## 📚 Learning Resources

### Official Documentation

**Core Technologies**
- [React Documentation](https://react.dev/) - Official React docs with interactive examples
- [FastAPI Documentation](https://fastapi.tiangolo.com/) - Comprehensive FastAPI guide
- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html) - Complete TypeScript reference
- [Tailwind CSS](https://tailwindcss.com/docs) - Utility-first CSS framework docs

**Data & State Management**
- [React Query/TanStack Query](https://tanstack.com/query/latest) - Server state management
- [SQLAlchemy 2.0](https://docs.sqlalchemy.org/en/20/) - Python SQL toolkit
- [Pydantic](https://docs.pydantic.dev/) - Data validation using Python type annotations

**Real-time & Deployment**
- [WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API) - MDN WebSocket guide
- [Docker Documentation](https://docs.docker.com/) - Containerization best practices
- [Kubernetes Documentation](https://kubernetes.io/docs/) - Container orchestration

### Recommended Courses & Tutorials

**Full-Stack Development**
1. [Full Stack Open](https://fullstackopen.com/) - University of Helsinki's comprehensive course
2. [The Odin Project](https://www.theodinproject.com/) - Full-stack JavaScript curriculum
3. [FastAPI Full Course](https://www.youtube.com/watch?v=0sOvCWFmrtA) - FreeCodeCamp tutorial

**Advanced Topics**
1. [Real-time Web Apps with WebSockets](https://www.pluralsight.com/courses/websockets-real-time-web-apps) - Pluralsight course
2. [Microservices with Node JS and React](https://www.udemy.com/course/microservices-with-node-js-and-react/) - Stephen Grider's course
3. [System Design Interview](https://www.educative.io/courses/grokking-the-system-design-interview) - Architecture patterns

### Books

**Web Development**
- "Designing Data-Intensive Applications" by Martin Kleppmann
- "Clean Architecture" by Robert C. Martin
- "Building Microservices" by Sam Newman

**React & TypeScript**
- "Learning React" by Alex Banks & Eve Porcello
- "Programming TypeScript" by Boris Cherny
- "React Design Patterns and Best Practices" by Carlos Santana Roldán

## 🛠️ Useful Tools & Libraries

### Development Tools

**VS Code Extensions**
```json
{
  "recommendations": [
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "bradlc.vscode-tailwindcss",
    "prisma.prisma",
    "ms-python.python",
    "ms-python.vscode-pylance",
    "charliermarsh.ruff",
    "github.copilot",
    "github.copilot-chat"
  ]
}
```

**Chrome Extensions**
- [React Developer Tools](https://chrome.google.com/webstore/detail/react-developer-tools/fmkadmapgofadopljbjfkapdkoienihi)
- [Redux DevTools](https://chrome.google.com/webstore/detail/redux-devtools/lmhkpmbekcpmknklioeibfkpmmfibljd)
- [JSON Viewer](https://chrome.google.com/webstore/detail/json-viewer/gbmdgpbipfallnflgajpaliibnhdgobh)

### Testing Libraries

**Frontend Testing**
```bash
npm install -D vitest @testing-library/react @testing-library/jest-dom
npm install -D @testing-library/user-event msw
```

**Backend Testing**
```bash
pip install pytest pytest-asyncio pytest-cov httpx
pip install faker factory-boy pytest-mock
```

### Performance Monitoring

**Frontend Performance**
```typescript
// React performance profiling
import { Profiler } from 'react';

function onRenderCallback(id, phase, actualDuration) {
  console.log(`${id} (${phase}) took ${actualDuration}ms`);
}

<Profiler id="Dashboard" onRender={onRenderCallback}>
  <Dashboard />
</Profiler>
```

**Backend Performance**
```python
# APM with OpenTelemetry
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

tracer = trace.get_tracer(__name__)

FastAPIInstrumentor.instrument_app(app)

@app.get("/agents")
async def get_agents():
    with tracer.start_as_current_span("get_agents"):
        # Your code here
```

## 💡 Code Snippets & Templates

### Authentication Flow Template

**Frontend Auth Context**
```typescript
// contexts/AuthContext.tsx
import React, { createContext, useContext, useState, useEffect } from 'react';
import { authApi } from '../api/auth';

interface AuthContextType {
  user: User | null;
  login: (credentials: LoginCredentials) => Promise<void>;
  logout: () => void;
  isLoading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Check for stored token on mount
    const token = localStorage.getItem('access_token');
    if (token) {
      authApi.getMe()
        .then(setUser)
        .catch(() => localStorage.removeItem('access_token'))
        .finally(() => setIsLoading(false));
    } else {
      setIsLoading(false);
    }
  }, []);

  const login = async (credentials: LoginCredentials) => {
    const response = await authApi.login(credentials);
    localStorage.setItem('access_token', response.access_token);
    setUser(response.user);
  };

  const logout = () => {
    localStorage.removeItem('access_token');
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, login, logout, isLoading }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};
```

### Reusable API Hook

**Custom Query Hook**
```typescript
// hooks/useApiQuery.ts
import { useQuery, UseQueryOptions } from '@tanstack/react-query';
import { toast } from 'react-hot-toast';

export function useApiQuery<TData = unknown>(
  key: string | string[],
  fetcher: () => Promise<TData>,
  options?: UseQueryOptions<TData>
) {
  return useQuery({
    queryKey: Array.isArray(key) ? key : [key],
    queryFn: fetcher,
    retry: (failureCount, error: any) => {
      if (error.response?.status === 404) return false;
      return failureCount < 3;
    },
    onError: (error: any) => {
      const message = error.response?.data?.detail || 'An error occurred';
      toast.error(message);
    },
    ...options,
  });
}

// Usage
const { data: agents } = useApiQuery(
  ['agents', filters],
  () => agentApi.getAll(filters),
  {
    staleTime: 5 * 60 * 1000, // 5 minutes
    cacheTime: 10 * 60 * 1000, // 10 minutes
  }
);
```

### Error Boundary Component

```typescript
// components/ErrorBoundary.tsx
import React, { Component, ReactNode } from 'react';

interface Props {
  children: ReactNode;
  fallback?: (error: Error, reset: () => void) => ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: any) {
    console.error('Error caught by boundary:', error, errorInfo);
    // Send to error tracking service
  }

  reset = () => {
    this.setState({ hasError: false, error: null });
  };

  render() {
    if (this.state.hasError && this.state.error) {
      if (this.props.fallback) {
        return this.props.fallback(this.state.error, this.reset);
      }

      return (
        <div className="min-h-screen flex items-center justify-center">
          <div className="text-center">
            <h1 className="text-2xl font-bold text-red-600 mb-4">
              Something went wrong
            </h1>
            <p className="text-gray-600 mb-4">
              {this.state.error.message}
            </p>
            <button
              onClick={this.reset}
              className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
            >
              Try again
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}
```

### Database Migration Template

```python
# alembic/versions/001_create_users_table.py
"""Create users table

Revision ID: 001
Revises: 
Create Date: 2024-01-01 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers
revision = '001'
down_revision = None
branch_labels = None
depends_on = None

def upgrade() -> None:
    op.create_table(
        'users',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('username', sa.String(50), nullable=False),
        sa.Column('email', sa.String(100), nullable=False),
        sa.Column('hashed_password', sa.String(), nullable=False),
        sa.Column('is_active', sa.Boolean(), default=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_users_username', 'users', ['username'], unique=True)
    op.create_index('ix_users_email', 'users', ['email'], unique=True)

def downgrade() -> None:
    op.drop_index('ix_users_email', table_name='users')
    op.drop_index('ix_users_username', table_name='users')
    op.drop_table('users')
```

## 🔗 GitHub Repositories

### Example Projects

1. **[Awesome FastAPI](https://github.com/mjhea0/awesome-fastapi)** - Curated list of FastAPI resources
2. **[Bulletproof React](https://github.com/alan2207/bulletproof-react)** - Scalable React architecture
3. **[Real World App](https://github.com/gothinkster/realworld)** - Full-stack example apps

### Starter Templates

1. **Full-Stack Template**
   ```bash
   git clone https://github.com/tiangolo/full-stack-fastapi-postgresql
   ```

2. **React TypeScript Template**
   ```bash
   git clone https://github.com/react-boilerplate/react-boilerplate-cra-template
   ```

3. **Monorepo Template**
   ```bash
   git clone https://github.com/Thinkmill/monorepo-starter
   ```

## 📊 Performance Optimization Resources

### Frontend Optimization

**Bundle Analysis**
```bash
# Install bundle analyzer
npm install -D rollup-plugin-visualizer

# vite.config.ts
import { visualizer } from 'rollup-plugin-visualizer';

export default {
  plugins: [
    visualizer({
      open: true,
      gzipSize: true,
      brotliSize: true,
    })
  ]
}
```

**Lazy Loading Routes**
```typescript
import { lazy, Suspense } from 'react';
import { Routes, Route } from 'react-router-dom';

const Dashboard = lazy(() => import('./pages/Dashboard'));
const AgentDetails = lazy(() => 
  import('./pages/AgentDetails').then(module => ({
    default: module.AgentDetails
  }))
);

function App() {
  return (
    <Suspense fallback={<LoadingSpinner />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/agents/:id" element={<AgentDetails />} />
      </Routes>
    </Suspense>
  );
}
```

### Backend Optimization

**Database Query Optimization**
```python
# Use select_related for foreign keys
agents = Agent.objects.select_related('owner').all()

# Use prefetch_related for many-to-many
posts = Post.objects.prefetch_related('tags', 'comments__author').all()

# Use only() to select specific fields
summaries = Agent.objects.only('id', 'name', 'status').all()

# Use database indexes
class Agent(Base):
    __tablename__ = "agents"
    
    owner_id = Column(Integer, ForeignKey("users.id"), index=True)
    status = Column(Enum(AgentStatus), index=True)
    created_at = Column(DateTime, index=True)
    
    __table_args__ = (
        Index('idx_owner_status', 'owner_id', 'status'),
    )
```

## 🎯 AI Prompt Templates

### Component Generation

```
Create a React component called [ComponentName] that:
- Uses TypeScript with proper type definitions
- Accepts props: [list props with types]
- Implements [describe functionality]
- Uses [UI library] for styling
- Handles these states: [loading, error, success]
- Includes these interactions: [list user interactions]
- Follows accessibility best practices
- Is memoized for performance
- Includes JSDoc documentation
```

### API Endpoint Generation

```
Create a FastAPI endpoint for [resource] that:
- Uses async/await syntax
- Implements [HTTP method] at path [/path]
- Accepts [request body/query params] with Pydantic validation
- Returns [response model] with status code [200/201/etc]
- Includes proper error handling for [list scenarios]
- Uses dependency injection for database session
- Implements [authentication/authorization] requirements
- Includes comprehensive docstring
- Logs important operations
```

### Test Generation

```
Generate comprehensive tests for [component/function] that:
- Uses [testing framework]
- Tests happy path scenarios
- Tests error scenarios
- Tests edge cases
- Mocks external dependencies
- Validates all props/parameters
- Checks accessibility
- Includes performance tests if applicable
- Uses proper setup and teardown
- Follows AAA pattern (Arrange, Act, Assert)
```

## 🚀 Deployment Guides

### Docker Deployment

**Multi-stage Dockerfile**
```dockerfile
# Build stage
FROM node:18-alpine AS frontend-build
WORKDIR /app
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# Python stage
FROM python:3.11-slim
WORKDIR /app
COPY backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/ ./
COPY --from=frontend-build /app/dist ./static
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0"]
```

### Azure Deployment

**GitHub Actions Workflow**
```yaml
name: Deploy to Azure

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Login to Azure
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Build and push Docker image
        uses: azure/docker-login@v1
        with:
          login-server: ${{ secrets.REGISTRY_LOGIN_SERVER }}
          username: ${{ secrets.REGISTRY_USERNAME }}
          password: ${{ secrets.REGISTRY_PASSWORD }}
      
      - run: |
          docker build . -t ${{ secrets.REGISTRY_LOGIN_SERVER }}/app:${{ github.sha }}
          docker push ${{ secrets.REGISTRY_LOGIN_SERVER }}/app:${{ github.sha }}
      
      - name: Deploy to Azure Container Instances
        uses: azure/aci-deploy@v1
        with:
          resource-group: ${{ secrets.RESOURCE_GROUP }}
          dns-name-label: ${{ secrets.RESOURCE_GROUP }}${{ github.run_number }}
          image: ${{ secrets.REGISTRY_LOGIN_SERVER }}/app:${{ github.sha }}
          name: app
          location: 'eastus'
```

## 📝 Final Notes

Remember to:
- Always check official documentation for the latest updates
- Join community forums and Discord servers
- Contribute back to open source projects
- Keep learning and experimenting
- Share your knowledge with others

Happy coding! 🚀