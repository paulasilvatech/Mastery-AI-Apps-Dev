# Module 22: Infrastructure & Design Patterns

## 🐳 infrastructure/docker/

### Dockerfile.agent
```dockerfile
# Multi-stage build for production-ready agent container
FROM python:3.11-slim as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /build

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Production stage
FROM python:3.11-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 agent

# Copy Python packages from builder
COPY --from=builder /root/.local /home/agent/.local

# Set up app directory
WORKDIR /app

# Copy application code
COPY --chown=agent:agent src/ ./src/
COPY --chown=agent:agent templates/ ./templates/
COPY --chown=agent:agent resources/ ./resources/

# Set environment variables
ENV PYTHONPATH=/app
ENV PATH=/home/agent/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1

# Switch to non-root user
USER agent

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Default command
CMD ["python", "-m", "src.agents.server"]

# Expose port
EXPOSE 8080
```

### docker-compose.yml
```yaml
version: '3.8'

services:
  # Agent API Service
  agent-api:
    build:
      context: .
      dockerfile: infrastructure/docker/Dockerfile.agent
    container_name: agent-api
    environment:
      - REDIS_URL=redis://redis:6379
      - DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD:-agentpass}@postgres:5432/agents
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - LOG_LEVEL=${LOG_LEVEL:-INFO}
      - ENVIRONMENT=development
    ports:
      - "8080:8080"
    volumes:
      - ./src:/app/src:ro
      - ./templates:/app/templates:ro
      - agent-data:/app/data
    depends_on:
      redis:
        condition: service_healthy
      postgres:
        condition: service_healthy
    networks:
      - agent-network
    restart: unless-stopped

  # Redis for state management
  redis:
    image: redis:7-alpine
    container_name: redis-agents
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD:-agentpass}
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - agent-network
    restart: unless-stopped

  # PostgreSQL for persistent storage
  postgres:
    image: postgres:16-alpine
    container_name: postgres-agents
    environment:
      - POSTGRES_DB=agents
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-agentpass}
      - PGDATA=/var/lib/postgresql/data/pgdata
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./infrastructure/docker/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d agents"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - agent-network
    restart: unless-stopped

  # Prometheus for metrics
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus-agents
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
      - '--web.enable-lifecycle'
    ports:
      - "9090:9090"
    volumes:
      - ./infrastructure/docker/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    networks:
      - agent-network
    restart: unless-stopped

  # Grafana for visualization
  grafana:
    image: grafana/grafana:latest
    container_name: grafana-agents
    environment:
      - GF_SECURITY_ADMIN_USER=${GRAFANA_USER:-admin}
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD:-admin}
      - GF_USERS_ALLOW_SIGN_UP=false
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana
      - ./resources/monitoring-dashboards:/etc/grafana/provisioning/dashboards:ro
      - ./infrastructure/docker/grafana-datasources.yml:/etc/grafana/provisioning/datasources/datasources.yml:ro
    depends_on:
      - prometheus
    networks:
      - agent-network
    restart: unless-stopped

  # Jaeger for tracing
  jaeger:
    image: jaegertracing/all-in-one:latest
    container_name: jaeger-agents
    environment:
      - COLLECTOR_ZIPKIN_HOST_PORT=9411
    ports:
      - "5775:5775/udp"
      - "6831:6831/udp"
      - "6832:6832/udp"
      - "5778:5778"
      - "16686:16686"  # UI
      - "14268:14268"
      - "14250:14250"
      - "9411:9411"
    networks:
      - agent-network
    restart: unless-stopped

networks:
  agent-network:
    driver: bridge

volumes:
  agent-data:
  redis-data:
  postgres-data:
  prometheus-data:
  grafana-data:
```

### init.sql
```sql
-- Initialize database for agents
CREATE SCHEMA IF NOT EXISTS agents;

-- Agent metadata table
CREATE TABLE IF NOT EXISTS agents.agent_metadata (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    version VARCHAR(50) NOT NULL,
    description TEXT,
    config JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Agent state table
CREATE TABLE IF NOT EXISTS agents.agent_state (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID NOT NULL REFERENCES agents.agent_metadata(id),
    state_data JSONB NOT NULL,
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(agent_id, version)
);

-- Tool registry
CREATE TABLE IF NOT EXISTS agents.tool_registry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    specification JSONB NOT NULL,
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Memory storage
CREATE TABLE IF NOT EXISTS agents.memory_store (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID NOT NULL REFERENCES agents.agent_metadata(id),
    memory_type VARCHAR(50) NOT NULL,
    content JSONB NOT NULL,
    embedding vector(768),
    importance FLOAT DEFAULT 0.5,
    access_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes
CREATE INDEX idx_agent_state_agent_id ON agents.agent_state(agent_id);
CREATE INDEX idx_memory_store_agent_id ON agents.memory_store(agent_id);
CREATE INDEX idx_memory_store_type ON agents.memory_store(memory_type);
CREATE INDEX idx_memory_store_embedding ON agents.memory_store USING ivfflat (embedding vector_cosine_ops);

-- Enable Row Level Security
ALTER TABLE agents.agent_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE agents.agent_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE agents.memory_store ENABLE ROW LEVEL SECURITY;

-- Create update trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_agent_metadata_updated_at
    BEFORE UPDATE ON agents.agent_metadata
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_tool_registry_updated_at
    BEFORE UPDATE ON agents.tool_registry
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
```

## ☸️ infrastructure/kubernetes/

### agent-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: agent-api
  namespace: agents
  labels:
    app: agent-api
    version: v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: agent-api
  template:
    metadata:
      labels:
        app: agent-api
        version: v1
    spec:
      serviceAccountName: agent-api
      containers:
      - name: agent-api
        image: your-registry/agent-api:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
          name: http
          protocol: TCP
        env:
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: agent-secrets
              key: redis-url
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: agent-secrets
              key: database-url
        - name: OPENAI_API_KEY
          valueFrom:
            secretKeyRef:
              name: agent-secrets
              key: openai-api-key
        - name: LOG_LEVEL
          value: "INFO"
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "2000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        volumeMounts:
        - name: config
          mountPath: /app/config
          readOnly: true
      volumes:
      - name: config
        configMap:
          name: agent-config
---
apiVersion: v1
kind: Service
metadata:
  name: agent-api
  namespace: agents
  labels:
    app: agent-api
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: agent-api
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: agent-api-hpa
  namespace: agents
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: agent-api
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
```

### agent-service.yaml
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: agent-api
  namespace: agents
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: agent-api
  namespace: agents
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: agent-api
  namespace: agents
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: agent-api
subjects:
- kind: ServiceAccount
  name: agent-api
  namespace: agents
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: agent-config
  namespace: agents
data:
  config.yaml: |
    agent:
      name: production-agent
      version: 1.0.0
      timeout: 300
      max_retries: 3
    
    monitoring:
      prometheus:
        enabled: true
        port: 9090
      jaeger:
        enabled: true
        endpoint: http://jaeger-collector:14268/api/traces
    
    features:
      memory_system: true
      tool_registry: true
      state_management: true
---
apiVersion: v1
kind: Secret
metadata:
  name: agent-secrets
  namespace: agents
type: Opaque
stringData:
  redis-url: "redis://redis-master:6379"
  database-url: "postgresql://postgres:password@postgres:5432/agents"
  openai-api-key: "your-openai-api-key"
```

## 🎨 resources/design-patterns/

### state-management.md
```markdown
# State Management Patterns for Agents

## Overview

State management is crucial for building robust, scalable agents. This guide covers proven patterns for managing agent state effectively.

## Core Patterns

### 1. Immutable State Pattern

**When to use**: When you need predictable state updates and easy debugging.

```python
from dataclasses import dataclass, replace
from typing import List, Optional
import copy

@dataclass(frozen=True)
class AgentState:
    """Immutable state container"""
    conversation_id: str
    messages: tuple
    context: dict
    
    def add_message(self, message: str) -> 'AgentState':
        """Return new state with added message"""
        return replace(
            self,
            messages=self.messages + (message,)
        )
    
    def update_context(self, key: str, value: any) -> 'AgentState':
        """Return new state with updated context"""
        new_context = copy.deepcopy(self.context)
        new_context[key] = value
        return replace(self, context=new_context)
```

**Benefits**:
- No accidental mutations
- Easy to track state changes
- Time-travel debugging possible
- Thread-safe by default

### 2. Event Sourcing Pattern

**When to use**: When you need audit trails and state reconstruction.

```python
from enum import Enum
from dataclasses import dataclass
from typing import List, Any
from datetime import datetime

class EventType(Enum):
    STATE_INITIALIZED = "state_initialized"
    MESSAGE_RECEIVED = "message_received"
    CONTEXT_UPDATED = "context_updated"
    ERROR_OCCURRED = "error_occurred"

@dataclass
class StateEvent:
    event_type: EventType
    timestamp: datetime
    data: dict
    agent_id: str
    
class EventSourcedState:
    def __init__(self, agent_id: str):
        self.agent_id = agent_id
        self.events: List[StateEvent] = []
        self._current_state = {}
        
    def apply_event(self, event: StateEvent) -> None:
        """Apply event to update state"""
        self.events.append(event)
        
        # Update state based on event type
        if event.event_type == EventType.MESSAGE_RECEIVED:
            messages = self._current_state.get('messages', [])
            messages.append(event.data['message'])
            self._current_state['messages'] = messages
            
        elif event.event_type == EventType.CONTEXT_UPDATED:
            context = self._current_state.get('context', {})
            context.update(event.data['context'])
            self._current_state['context'] = context
    
    def get_state_at(self, timestamp: datetime) -> dict:
        """Reconstruct state at specific time"""
        state = {}
        for event in self.events:
            if event.timestamp <= timestamp:
                # Apply event logic
                pass
        return state
```

**Benefits**:
- Complete audit trail
- State reconstruction at any point
- Easy debugging and replay
- Supports undo/redo

### 3. Redux-Style State Management

**When to use**: When you have complex state with many updates.

```python
from typing import Dict, Any, Callable
from enum import Enum
import copy

class ActionType(Enum):
    ADD_MESSAGE = "ADD_MESSAGE"
    UPDATE_CONTEXT = "UPDATE_CONTEXT"
    SET_ERROR = "SET_ERROR"
    CLEAR_ERROR = "CLEAR_ERROR"

class StateStore:
    def __init__(self, initial_state: dict, reducer: Callable):
        self._state = initial_state
        self._reducer = reducer
        self._listeners = []
        
    def dispatch(self, action: dict) -> None:
        """Dispatch action to update state"""
        old_state = copy.deepcopy(self._state)
        self._state = self._reducer(self._state, action)
        
        # Notify listeners if state changed
        if self._state != old_state:
            for listener in self._listeners:
                listener(self._state, old_state)
    
    def get_state(self) -> dict:
        """Get current state"""
        return copy.deepcopy(self._state)
    
    def subscribe(self, listener: Callable) -> Callable:
        """Subscribe to state changes"""
        self._listeners.append(listener)
        
        # Return unsubscribe function
        def unsubscribe():
            self._listeners.remove(listener)
        return unsubscribe

# Example reducer
def agent_reducer(state: dict, action: dict) -> dict:
    """Pure function to update state based on action"""
    action_type = ActionType(action['type'])
    
    if action_type == ActionType.ADD_MESSAGE:
        messages = state.get('messages', []).copy()
        messages.append(action['payload'])
        return {**state, 'messages': messages}
        
    elif action_type == ActionType.UPDATE_CONTEXT:
        context = state.get('context', {}).copy()
        context.update(action['payload'])
        return {**state, 'context': context}
        
    elif action_type == ActionType.SET_ERROR:
        return {**state, 'error': action['payload'], 'has_error': True}
        
    elif action_type == ActionType.CLEAR_ERROR:
        return {**state, 'error': None, 'has_error': False}
        
    return state
```

**Benefits**:
- Predictable state updates
- Easy testing (pure functions)
- Time-travel debugging
- Middleware support

### 4. Finite State Machine Pattern

**When to use**: When agent has clear states and transitions.

```python
from enum import Enum
from typing import Dict, Set, Optional, Callable

class AgentState(Enum):
    IDLE = "idle"
    LISTENING = "listening"
    PROCESSING = "processing"
    RESPONDING = "responding"
    ERROR = "error"

class StateMachine:
    def __init__(self):
        self.state = AgentState.IDLE
        self.transitions: Dict[AgentState, Set[AgentState]] = {
            AgentState.IDLE: {AgentState.LISTENING, AgentState.ERROR},
            AgentState.LISTENING: {AgentState.PROCESSING, AgentState.IDLE, AgentState.ERROR},
            AgentState.PROCESSING: {AgentState.RESPONDING, AgentState.ERROR},
            AgentState.RESPONDING: {AgentState.IDLE, AgentState.LISTENING, AgentState.ERROR},
            AgentState.ERROR: {AgentState.IDLE}
        }
        
        # State entry/exit handlers
        self.on_enter: Dict[AgentState, Callable] = {}
        self.on_exit: Dict[AgentState, Callable] = {}
        
    def can_transition_to(self, new_state: AgentState) -> bool:
        """Check if transition is valid"""
        return new_state in self.transitions.get(self.state, set())
    
    def transition_to(self, new_state: AgentState) -> bool:
        """Attempt state transition"""
        if not self.can_transition_to(new_state):
            return False
            
        # Call exit handler for current state
        if self.state in self.on_exit:
            self.on_exit[self.state]()
            
        old_state = self.state
        self.state = new_state
        
        # Call entry handler for new state
        if new_state in self.on_enter:
            self.on_enter[new_state]()
            
        return True
```

**Benefits**:
- Clear state boundaries
- Prevents invalid states
- Easy to visualize
- Built-in validation

## Advanced Patterns

### 1. CQRS (Command Query Responsibility Segregation)

Separate read and write models for complex state:

```python
class AgentCQRS:
    def __init__(self):
        self.write_model = {}  # Optimized for writes
        self.read_models = {}  # Multiple read models
        
    def execute_command(self, command: dict) -> None:
        """Handle state-changing commands"""
        # Update write model
        # Trigger read model updates
        pass
        
    def execute_query(self, query: dict) -> Any:
        """Handle read-only queries"""
        # Use appropriate read model
        pass
```

### 2. Snapshot Pattern

Periodic state snapshots for performance:

```python
class SnapshotState:
    def __init__(self):
        self.events = []
        self.snapshots = {}
        self.snapshot_interval = 100
        
    def save_snapshot(self) -> None:
        """Save current state snapshot"""
        if len(self.events) % self.snapshot_interval == 0:
            snapshot_id = len(self.events)
            self.snapshots[snapshot_id] = self.compute_current_state()
    
    def load_state(self) -> dict:
        """Load state from nearest snapshot"""
        # Find nearest snapshot
        # Apply events since snapshot
        pass
```

## Best Practices

1. **Keep State Minimal**: Only store what's necessary
2. **Use Immutability**: Prefer immutable data structures
3. **Version Your State**: Include version field for migrations
4. **Validate State**: Always validate before updates
5. **Handle Persistence**: Plan for state persistence early
6. **Monitor State Size**: Track state growth over time
7. **Design for Recovery**: Handle partial state loss
8. **Test State Transitions**: Comprehensive state testing

## Common Pitfalls

1. **Mutable Shared State**: Leads to race conditions
2. **Unbounded State Growth**: Memory leaks
3. **Complex State Shapes**: Hard to maintain
4. **Missing Validation**: Corrupted state
5. **No Migration Strategy**: Breaking changes

## Implementation Checklist

- [ ] Choose appropriate pattern for use case
- [ ] Define clear state schema
- [ ] Implement state validation
- [ ] Add persistence layer
- [ ] Create migration strategy
- [ ] Add monitoring/metrics
- [ ] Write comprehensive tests
- [ ] Document state transitions
- [ ] Plan for failure recovery
- [ ] Consider performance implications
```

### memory-architectures.md
```markdown
# Memory Architecture Patterns for AI Agents

## Overview

Memory systems are critical for creating intelligent agents that can learn, adapt, and maintain context. This guide covers proven memory architecture patterns.

## Memory Types

### 1. Working Memory (Short-term)
- **Purpose**: Current context and immediate tasks
- **Capacity**: Limited (5-10 items)
- **Duration**: Current session/conversation
- **Implementation**: In-memory cache, circular buffer

### 2. Episodic Memory (Experiences)
- **Purpose**: Specific events and interactions
- **Capacity**: Moderate (1000s of episodes)
- **Duration**: Days to months
- **Implementation**: Time-indexed database

### 3. Semantic Memory (Knowledge)
- **Purpose**: Facts, concepts, relationships
- **Capacity**: Large (unlimited)
- **Duration**: Permanent
- **Implementation**: Vector database, knowledge graph

### 4. Procedural Memory (Skills)
- **Purpose**: How to perform tasks
- **Capacity**: Moderate
- **Duration**: Permanent
- **Implementation**: Rule engine, decision trees

## Architecture Patterns

### 1. Hierarchical Memory Architecture

```python
from abc import ABC, abstractmethod
from typing import Any, List, Optional
import numpy as np

class MemoryLayer(ABC):
    @abstractmethod
    def store(self, key: str, value: Any, importance: float) -> None:
        pass
    
    @abstractmethod
    def retrieve(self, query: str, limit: int) -> List[Any]:
        pass
    
    @abstractmethod
    def forget(self, threshold: float) -> int:
        pass

class HierarchicalMemory:
    def __init__(self):
        self.sensory = SensoryMemory(duration_ms=500)
        self.working = WorkingMemory(capacity=7)
        self.short_term = ShortTermMemory(capacity=100)
        self.long_term = LongTermMemory()
        
    def process_input(self, input_data: Any) -> None:
        """Process input through memory hierarchy"""
        # Sensory buffer
        self.sensory.buffer(input_data)
        
        # Attention mechanism filters to working memory
        if self.is_important(input_data):
            self.working.add(input_data)
            
            # Consolidate to short-term
            if self.working.is_full():
                item = self.working.get_least_active()
                self.short_term.store(item)
                
            # Long-term storage for important items
            if self.calculate_importance(input_data) > 0.8:
                self.long_term.store(input_data)
```

### 2. Associative Memory Network

```python
class AssociativeMemory:
    def __init__(self, dimension: int = 512):
        self.dimension = dimension
        self.memories = {}
        self.associations = defaultdict(set)
        
    def store(self, key: str, content: Any, associations: List[str] = None):
        """Store with associations"""
        # Create embedding
        embedding = self.encode(content)
        
        self.memories[key] = {
            'content': content,
            'embedding': embedding,
            'associations': associations or []
        }
        
        # Build association network
        if associations:
            for assoc in associations:
                self.associations[key].add(assoc)
                self.associations[assoc].add(key)
    
    def recall_by_association(self, key: str, depth: int = 2) -> List[Any]:
        """Recall memories by association"""
        visited = set()
        to_visit = [(key, 0)]
        related = []
        
        while to_visit:
            current, current_depth = to_visit.pop(0)
            
            if current in visited or current_depth > depth:
                continue
                
            visited.add(current)
            
            if current in self.memories:
                related.append(self.memories[current])
                
            # Add associations
            for assoc in self.associations.get(current, []):
                if assoc not in visited:
                    to_visit.append((assoc, current_depth + 1))
                    
        return related
```

### 3. Attention-Based Memory

```python
class AttentionMemory:
    def __init__(self, capacity: int, attention_heads: int = 8):
        self.capacity = capacity
        self.attention_heads = attention_heads
        self.memory_bank = []
        self.attention_weights = {}
        
    def attend(self, query: np.ndarray) -> List[Tuple[Any, float]]:
        """Retrieve memories using attention mechanism"""
        if not self.memory_bank:
            return []
            
        # Multi-head attention
        attention_scores = []
        
        for head in range(self.attention_heads):
            # Project query for this head
            q_proj = self.project_query(query, head)
            
            # Calculate attention scores
            scores = []
            for mem in self.memory_bank:
                k_proj = self.project_key(mem['embedding'], head)
                score = np.dot(q_proj, k_proj) / np.sqrt(len(q_proj))
                scores.append(score)
                
            attention_scores.append(scores)
        
        # Combine heads
        final_scores = np.mean(attention_scores, axis=0)
        
        # Apply softmax
        weights = self.softmax(final_scores)
        
        # Return weighted memories
        results = []
        for i, weight in enumerate(weights):
            if weight > 0.01:  # Threshold
                results.append((self.memory_bank[i], weight))
                
        return sorted(results, key=lambda x: x[1], reverse=True)
```

### 4. Temporal Memory System

```python
from datetime import datetime, timedelta

class TemporalMemory:
    def __init__(self):
        self.timeline = []
        self.temporal_index = defaultdict(list)
        
    def store(self, content: Any, timestamp: datetime = None):
        """Store with temporal information"""
        if timestamp is None:
            timestamp = datetime.now()
            
        memory = {
            'id': str(uuid.uuid4()),
            'content': content,
            'timestamp': timestamp,
            'access_count': 0,
            'last_accessed': timestamp
        }
        
        # Add to timeline
        self.timeline.append(memory)
        self.timeline.sort(key=lambda x: x['timestamp'])
        
        # Index by time buckets
        bucket = timestamp.date()
        self.temporal_index[bucket].append(memory)
        
    def recall_period(self, start: datetime, end: datetime) -> List[Any]:
        """Recall memories from time period"""
        memories = []
        
        for memory in self.timeline:
            if start <= memory['timestamp'] <= end:
                memory['access_count'] += 1
                memory['last_accessed'] = datetime.now()
                memories.append(memory)
                
        return memories
    
    def get_temporal_context(self, timestamp: datetime, 
                           window: timedelta) -> List[Any]:
        """Get memories around a timestamp"""
        start = timestamp - window
        end = timestamp + window
        return self.recall_period(start, end)
```

## Memory Optimization Strategies

### 1. Compression and Summarization

```python
class CompressedMemory:
    def __init__(self, compression_ratio: float = 0.1):
        self.compression_ratio = compression_ratio
        self.compressed_store = {}
        
    def compress(self, memories: List[Any]) -> Any:
        """Compress multiple memories into summary"""
        # Extract key information
        # Generate summary
        # Store both compressed and references
        pass
```

### 2. Importance-Based Retention

```python
class ImportanceMemory:
    def __init__(self):
        self.importance_threshold = 0.5
        
    def calculate_importance(self, memory: dict) -> float:
        """Calculate memory importance score"""
        factors = {
            'recency': self.recency_score(memory),
            'frequency': self.frequency_score(memory),
            'emotional': self.emotional_score(memory),
            'utility': self.utility_score(memory)
        }
        
        weights = {
            'recency': 0.2,
            'frequency': 0.3,
            'emotional': 0.2,
            'utility': 0.3
        }
        
        return sum(factors[k] * weights[k] for k in factors)
```

### 3. Memory Consolidation

```python
class ConsolidationEngine:
    def consolidate(self, short_term: List[Any], 
                   long_term: Any) -> None:
        """Consolidate short-term to long-term memory"""
        # Group similar memories
        # Extract patterns
        # Create semantic connections
        # Update knowledge graph
        pass
```

## Implementation Best Practices

1. **Capacity Management**
   - Set hard limits for each memory type
   - Implement eviction policies
   - Monitor memory usage

2. **Indexing Strategy**
   - Use multiple indices (temporal, semantic, importance)
   - Optimize for common query patterns
   - Consider distributed indexing

3. **Persistence**
   - Separate volatile and persistent memory
   - Implement checkpointing
   - Handle recovery gracefully

4. **Performance**
   - Use caching for frequent queries
   - Implement lazy loading
   - Consider memory mapping for large datasets

5. **Privacy and Security**
   - Encrypt sensitive memories
   - Implement access controls
   - Allow selective forgetting

## Common Patterns

### 1. Memory Pools
```python
class MemoryPool:
    def __init__(self, pool_size: int):
        self.pools = {
            'facts': MemorySubPool(pool_size // 3),
            'experiences': MemorySubPool(pool_size // 3),
            'skills': MemorySubPool(pool_size // 3)
        }
```

### 2. Memory Chains
```python
class MemoryChain:
    def __init__(self):
        self.chains = defaultdict(list)
        
    def link_memories(self, memory_ids: List[str]):
        """Create causal chain of memories"""
        for i in range(len(memory_ids) - 1):
            self.chains[memory_ids[i]].append(memory_ids[i + 1])
```

### 3. Contextual Memory
```python
class ContextualMemory:
    def store_with_context(self, content: Any, context: dict):
        """Store memory with rich context"""
        memory = {
            'content': content,
            'context': {
                'location': context.get('location'),
                'participants': context.get('participants'),
                'mood': context.get('mood'),
                'task': context.get('task')
            }
        }
```

## Pitfalls to Avoid

1. **Memory Leaks**: Unbounded growth without cleanup
2. **Over-indexing**: Too many indices slow updates
3. **Poor Eviction**: Losing important memories
4. **No Backup**: Single point of failure
5. **Slow Retrieval**: Not optimizing for query patterns

## Future Considerations

1. **Neuromorphic Memory**: Brain-inspired architectures
2. **Quantum Memory**: Quantum state storage
3. **Distributed Memory**: Multi-agent shared memory
4. **Adaptive Memory**: Self-organizing structures
5. **Emotional Memory**: Affect-based storage and retrieval
```

### tool-integration.md
```markdown
# Tool Integration Patterns for AI Agents

## Overview

Effective tool integration is essential for creating capable AI agents. This guide covers patterns for integrating, managing, and orchestrating tools.

## Core Concepts

### Tool Definition
A tool is any external capability an agent can use:
- APIs and web services
- Database operations
- File system access
- Computational functions
- External programs
- Other agents

### Tool Properties
- **Name**: Unique identifier
- **Description**: What the tool does
- **Parameters**: Input specification
- **Returns**: Output specification
- **Constraints**: Usage limits, requirements
- **Cost**: Computational or monetary

## Integration Patterns

### 1. Registry Pattern

```python
from typing import Dict, List, Any, Protocol
from dataclasses import dataclass
import inspect

class Tool(Protocol):
    """Tool protocol"""
    name: str
    description: str
    
    async def execute(self, **kwargs) -> Any:
        ...

@dataclass
class ToolSpec:
    name: str
    description: str
    parameters: Dict[str, Any]
    returns: Dict[str, Any]
    examples: List[Dict[str, Any]]
    
class ToolRegistry:
    def __init__(self):
        self._tools: Dict[str, Tool] = {}
        self._specs: Dict[str, ToolSpec] = {}
        self._middleware: List[Callable] = []
        
    def register(self, tool: Tool, spec: ToolSpec = None):
        """Register a tool with optional specification"""
        self._tools[tool.name] = tool
        
        if spec is None:
            # Auto-generate spec from tool
            spec = self._generate_spec(tool)
            
        self._specs[tool.name] = spec
        
    def _generate_spec(self, tool: Tool) -> ToolSpec:
        """Auto-generate specification from tool"""
        sig = inspect.signature(tool.execute)
        parameters = {}
        
        for name, param in sig.parameters.items():
            if name == 'self' or name == 'kwargs':
                continue
                
            param_info = {
                'type': param.annotation.__name__ if param.annotation != param.empty else 'Any',
                'required': param.default == param.empty,
                'default': param.default if param.default != param.empty else None
            }
            parameters[name] = param_info
            
        return ToolSpec(
            name=tool.name,
            description=tool.description or tool.__doc__ or "",
            parameters=parameters,
            returns={'type': 'Any'},
            examples=[]
        )
    
    async def execute(self, tool_name: str, **kwargs) -> Any:
        """Execute tool with middleware"""
        if tool_name not in self._tools:
            raise ValueError(f"Tool '{tool_name}' not found")
            
        tool = self._tools[tool_name]
        
        # Apply middleware
        for middleware in self._middleware:
            kwargs = await middleware(tool_name, kwargs)
            
        # Execute tool
        result = await tool.execute(**kwargs)
        
        # Apply post-middleware
        for middleware in reversed(self._middleware):
            if hasattr(middleware, 'post_execute'):
                result = await middleware.post_execute(tool_name, result)
                
        return result
```

### 2. Adapter Pattern

```python
from abc import ABC, abstractmethod

class ToolAdapter(ABC):
    """Base adapter for external tools"""
    
    @abstractmethod
    async def execute(self, **kwargs) -> Any:
        pass
    
class RESTAPIAdapter(ToolAdapter):
    """Adapter for REST APIs"""
    
    def __init__(self, base_url: str, headers: Dict[str, str] = None):
        self.base_url = base_url
        self.headers = headers or {}
        self.session = aiohttp.ClientSession()
        
    async def execute(self, method: str, endpoint: str, **kwargs) -> Any:
        url = f"{self.base_url}/{endpoint}"
        
        async with self.session.request(
            method=method,
            url=url,
            headers=self.headers,
            **kwargs
        ) as response:
            response.raise_for_status()
            return await response.json()
    
    async def close(self):
        await self.session.close()

class DatabaseAdapter(ToolAdapter):
    """Adapter for database operations"""
    
    def __init__(self, connection_string: str):
        self.connection_string = connection_string
        self.pool = None
        
    async def initialize(self):
        self.pool = await asyncpg.create_pool(self.connection_string)
        
    async def execute(self, query: str, params: List[Any] = None) -> Any:
        async with self.pool.acquire() as conn:
            if params:
                return await conn.fetch(query, *params)
            return await conn.fetch(query)

class CommandLineAdapter(ToolAdapter):
    """Adapter for command-line tools"""
    
    def __init__(self, command: str):
        self.command = command
        
    async def execute(self, args: List[str] = None, **kwargs) -> Any:
        cmd = [self.command]
        if args:
            cmd.extend(args)
            
        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            **kwargs
        )
        
        stdout, stderr = await proc.communicate()
        
        if proc.returncode != 0:
            raise RuntimeError(f"Command failed: {stderr.decode()}")
            
        return stdout.decode()
```

### 3. Chain of Responsibility Pattern

```python
class ToolHandler(ABC):
    """Abstract handler in chain"""
    
    def __init__(self):
        self._next_handler: Optional[ToolHandler] = None
        
    def set_next(self, handler: 'ToolHandler') -> 'ToolHandler':
        self._next_handler = handler
        return handler
        
    @abstractmethod
    async def handle(self, request: Dict[str, Any]) -> Any:
        if self._next_handler:
            return await self._next_handler.handle(request)
        return None

class ValidationHandler(ToolHandler):
    """Validate tool requests"""
    
    async def handle(self, request: Dict[str, Any]) -> Any:
        tool_name = request.get('tool')
        params = request.get('params', {})
        
        # Validate required fields
        if not tool_name:
            raise ValueError("Tool name required")
            
        # Validate parameters
        spec = self.get_tool_spec(tool_name)
        for param, info in spec.parameters.items():
            if info['required'] and param not in params:
                raise ValueError(f"Required parameter '{param}' missing")
                
        return await super().handle(request)

class RateLimitHandler(ToolHandler):
    """Rate limit tool usage"""
    
    def __init__(self, limits: Dict[str, int]):
        super().__init__()
        self.limits = limits
        self.usage = defaultdict(list)
        
    async def handle(self, request: Dict[str, Any]) -> Any:
        tool_name = request['tool']
        
        if tool_name in self.limits:
            # Check rate limit
            now = time.time()
            self.usage[tool_name] = [
                t for t in self.usage[tool_name] 
                if now - t < 60  # 1-minute window
            ]
            
            if len(self.usage[tool_name]) >= self.limits[tool_name]:
                raise RuntimeError(f"Rate limit exceeded for {tool_name}")
                
            self.usage[tool_name].append(now)
            
        return await super().handle(request)

class ExecutionHandler(ToolHandler):
    """Execute the actual tool"""
    
    def __init__(self, registry: ToolRegistry):
        super().__init__()
        self.registry = registry
        
    async def handle(self, request: Dict[str, Any]) -> Any:
        tool_name = request['tool']
        params = request.get('params', {})
        
        return await self.registry.execute(tool_name, **params)
```

### 4. Strategy Pattern for Tool Selection

```python
from abc import ABC, abstractmethod

class ToolSelectionStrategy(ABC):
    """Base strategy for tool selection"""
    
    @abstractmethod
    def select_tool(self, task: str, available_tools: List[ToolSpec]) -> Optional[str]:
        pass

class KeywordStrategy(ToolSelectionStrategy):
    """Select tool based on keyword matching"""
    
    def select_tool(self, task: str, available_tools: List[ToolSpec]) -> Optional[str]:
        task_lower = task.lower()
        best_match = None
        best_score = 0
        
        for tool in available_tools:
            # Simple scoring based on word overlap
            tool_words = set(tool.description.lower().split())
            task_words = set(task_lower.split())
            
            common = tool_words.intersection(task_words)
            score = len(common) / max(len(task_words), 1)
            
            if score > best_score:
                best_score = score
                best_match = tool.name
                
        return best_match if best_score > 0.3 else None

class SemanticStrategy(ToolSelectionStrategy):
    """Select tool using semantic similarity"""
    
    def __init__(self, embedding_model):
        self.embedding_model = embedding_model
        self.tool_embeddings = {}
        
    def index_tools(self, tools: List[ToolSpec]):
        """Pre-compute tool embeddings"""
        for tool in tools:
            embedding = self.embedding_model.encode(tool.description)
            self.tool_embeddings[tool.name] = embedding
            
    def select_tool(self, task: str, available_tools: List[ToolSpec]) -> Optional[str]:
        task_embedding = self.embedding_model.encode(task)
        
        best_match = None
        best_similarity = 0
        
        for tool in available_tools:
            if tool.name in self.tool_embeddings:
                similarity = cosine_similarity(
                    task_embedding, 
                    self.tool_embeddings[tool.name]
                )
                
                if similarity > best_similarity:
                    best_similarity = similarity
                    best_match = tool.name
                    
        return best_match if best_similarity > 0.7 else None

class MLStrategy(ToolSelectionStrategy):
    """Select tool using trained ML model"""
    
    def __init__(self, model_path: str):
        self.model = self.load_model(model_path)
        
    def select_tool(self, task: str, available_tools: List[ToolSpec]) -> Optional[str]:
        # Prepare features
        features = self.extract_features(task, available_tools)
        
        # Predict best tool
        predictions = self.model.predict(features)
        best_idx = np.argmax(predictions)
        
        if predictions[best_idx] > 0.5:
            return available_tools[best_idx].name
            
        return None
```

### 5. Composite Tool Pattern

```python
class CompositeTool(Tool):
    """Tool composed of multiple sub-tools"""
    
    def __init__(self, name: str, description: str):
        self.name = name
        self.description = description
        self.sub_tools: List[Tool] = []
        self.workflow = []
        
    def add_tool(self, tool: Tool):
        """Add sub-tool to composite"""
        self.sub_tools.append(tool)
        
    def define_workflow(self, workflow: List[Dict[str, Any]]):
        """Define execution workflow"""
        self.workflow = workflow
        
    async def execute(self, **kwargs) -> Any:
        """Execute composite tool workflow"""
        context = kwargs.copy()
        results = {}
        
        for step in self.workflow:
            tool_name = step['tool']
            params = step.get('params', {})
            
            # Resolve parameters from context
            resolved_params = {}
            for key, value in params.items():
                if isinstance(value, str) and value.startswith('$'):
                    # Reference to previous result
                    ref = value[1:]
                    if '.' in ref:
                        obj, attr = ref.split('.', 1)
                        resolved_params[key] = results[obj].get(attr)
                    else:
                        resolved_params[key] = results.get(ref)
                else:
                    resolved_params[key] = value
                    
            # Execute sub-tool
            tool = next(t for t in self.sub_tools if t.name == tool_name)
            result = await tool.execute(**resolved_params)
            
            # Store result
            results[step.get('output', tool_name)] = result
            
        return results

# Example usage
research_tool = CompositeTool(
    name="research_assistant",
    description="Research a topic comprehensively"
)

research_tool.add_tool(WebSearchTool())
research_tool.add_tool(SummarizerTool())
research_tool.add_tool(ReportGeneratorTool())

research_tool.define_workflow([
    {
        'tool': 'web_search',
        'params': {'query': '$query', 'max_results': 10},
        'output': 'search_results'
    },
    {
        'tool': 'summarizer',
        'params': {'texts': '$search_results.snippets'},
        'output': 'summaries'
    },
    {
        'tool': 'report_generator',
        'params': {
            'title': '$query',
            'sections': '$summaries',
            'format': 'markdown'
        },
        'output': 'report'
    }
])
```

## Tool Orchestration Patterns

### 1. Pipeline Pattern
```python
class ToolPipeline:
    def __init__(self):
        self.stages = []
        
    def add_stage(self, tool: Tool, transform: Callable = None):
        self.stages.append((tool, transform))
        
    async def execute(self, initial_input: Any) -> Any:
        result = initial_input
        
        for tool, transform in self.stages:
            result = await tool.execute(input=result)
            if transform:
                result = transform(result)
                
        return result
```

### 2. Parallel Execution Pattern
```python
class ParallelToolExecutor:
    async def execute_parallel(self, tool_calls: List[Tuple[Tool, Dict]]) -> List[Any]:
        tasks = [
            tool.execute(**params) 
            for tool, params in tool_calls
        ]
        
        return await asyncio.gather(*tasks, return_exceptions=True)
```

### 3. Conditional Execution Pattern
```python
class ConditionalToolExecutor:
    def __init__(self):
        self.conditions = []
        
    def add_condition(self, condition: Callable, tool: Tool):
        self.conditions.append((condition, tool))
        
    async def execute(self, context: Dict[str, Any]) -> Any:
        for condition, tool in self.conditions:
            if condition(context):
                return await tool.execute(**context)
                
        raise ValueError("No condition matched")
```

## Best Practices

1. **Tool Discovery**
   - Implement tool search/discovery
   - Provide clear descriptions
   - Include usage examples

2. **Error Handling**
   - Graceful degradation
   - Fallback tools
   - Clear error messages

3. **Security**
   - Input validation
   - Sandboxing dangerous tools
   - Authentication/authorization

4. **Performance**
   - Tool response caching
   - Parallel execution where possible
   - Timeout handling

5. **Monitoring**
   - Track tool usage
   - Monitor performance
   - Log failures

## Common Pitfalls

1. **Over-tooling**: Too many similar tools
2. **Poor Abstraction**: Tools too specific or too general
3. **No Versioning**: Breaking changes without version management
4. **Tight Coupling**: Tools dependent on each other
5. **No Documentation**: Unclear tool capabilities

## Future Patterns

1. **Self-Discovering Tools**: Tools that adapt their capabilities
2. **Collaborative Tools**: Tools that work together automatically
3. **Learning Tools**: Tools that improve with usage
4. **Meta-Tools**: Tools that create other tools
5. **Quantum Tools**: Leveraging quantum computing capabilities
```