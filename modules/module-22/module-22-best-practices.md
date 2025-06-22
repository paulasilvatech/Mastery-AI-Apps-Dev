# Custom Agent Development Best Practices

## 🏗️ Agent Architecture Patterns

### 1. Domain-Driven Agent Design
Structure agents around business domains:

```python
# ✅ Good: Domain-focused agents
class OrderFulfillmentAgent:
    """Agent specialized in order fulfillment domain"""
    def __init__(self, inventory_service, shipping_service):
        self.inventory = inventory_service
        self.shipping = shipping_service
        self.domain_rules = OrderFulfillmentRules()
    
    def process_order(self, order: Order) -> FulfillmentResult:
        # Domain-specific logic
        pass

# ❌ Bad: Generic, unfocused agent
class GeneralAgent:
    def do_everything(self, task_type, data):
        if task_type == "order":
            # Order logic
        elif task_type == "inventory":
            # Inventory logic
        # Too many responsibilities
```

### 2. State Management Patterns

#### Immutable State Pattern
```python
from dataclasses import dataclass, replace
from typing import List, Optional

@dataclass(frozen=True)
class AgentState:
    """Immutable agent state"""
    conversation_id: str
    messages: tuple
    context: dict
    timestamp: datetime
    
    def add_message(self, message: Message) -> 'AgentState':
        """Return new state with added message"""
        return replace(
            self,
            messages=self.messages + (message,),
            timestamp=datetime.now()
        )

class ImmutableStateAgent:
    def __init__(self):
        self.state_history: List[AgentState] = []
        self.current_state: Optional[AgentState] = None
    
    def process(self, input_data: str) -> str:
        # Create new state, never modify existing
        new_state = self.current_state.add_message(
            Message(role="user", content=input_data)
        )
        self.state_history.append(new_state)
        self.current_state = new_state
        
        return self._generate_response(new_state)
```

#### Event Sourcing Pattern
```python
from enum import Enum
from dataclasses import dataclass
from typing import List, Any

class EventType(Enum):
    AGENT_STARTED = "agent_started"
    INPUT_RECEIVED = "input_received"
    TOOL_CALLED = "tool_called"
    RESPONSE_GENERATED = "response_generated"
    ERROR_OCCURRED = "error_occurred"

@dataclass
class Event:
    event_type: EventType
    timestamp: datetime
    data: Dict[str, Any]
    metadata: Dict[str, Any] = field(default_factory=dict)

class EventSourcedAgent:
    def __init__(self):
        self.events: List[Event] = []
        self.snapshots: Dict[int, Any] = {}
        
    def apply_event(self, event: Event):
        """Apply event and update state"""
        self.events.append(event)
        
        # Update internal state based on event
        if event.event_type == EventType.INPUT_RECEIVED:
            self._handle_input(event.data)
        elif event.event_type == EventType.TOOL_CALLED:
            self._handle_tool_call(event.data)
    
    def replay_events(self, from_index: int = 0) -> Any:
        """Rebuild state by replaying events"""
        # Start from snapshot if available
        snapshot_index = max(
            (i for i in self.snapshots.keys() if i <= from_index),
            default=0
        )
        
        state = self.snapshots.get(snapshot_index, self._initial_state())
        
        # Replay events from snapshot
        for event in self.events[snapshot_index:]:
            state = self._apply_event_to_state(state, event)
            
        return state
```

### 3. Memory Architecture Patterns

#### Hierarchical Memory System
```python
from abc import ABC, abstractmethod
import time

class MemoryLayer(ABC):
    @abstractmethod
    def store(self, key: str, value: Any, metadata: Dict = None):
        pass
    
    @abstractmethod
    def retrieve(self, key: str) -> Optional[Any]:
        pass
    
    @abstractmethod
    def search(self, query: str, limit: int = 10) -> List[Any]:
        pass

class WorkingMemory(MemoryLayer):
    """Short-term, fast access memory"""
    def __init__(self, capacity: int = 100):
        self.capacity = capacity
        self.memory = OrderedDict()
        
    def store(self, key: str, value: Any, metadata: Dict = None):
        if len(self.memory) >= self.capacity:
            # Remove oldest item
            self.memory.popitem(last=False)
        
        self.memory[key] = {
            'value': value,
            'metadata': metadata or {},
            'timestamp': time.time(),
            'access_count': 0
        }
    
    def retrieve(self, key: str) -> Optional[Any]:
        if key in self.memory:
            self.memory[key]['access_count'] += 1
            # Move to end (most recently used)
            self.memory.move_to_end(key)
            return self.memory[key]['value']
        return None

class LongTermMemory(MemoryLayer):
    """Persistent, slower access memory"""
    def __init__(self, storage_path: Path):
        self.storage_path = storage_path
        self.index = self._load_index()
        
    def store(self, key: str, value: Any, metadata: Dict = None):
        # Store with compression and indexing
        compressed = self._compress(value)
        file_path = self.storage_path / f"{key}.pkl"
        
        with open(file_path, 'wb') as f:
            pickle.dump(compressed, f)
            
        # Update index
        self.index[key] = {
            'path': str(file_path),
            'metadata': metadata,
            'size': len(compressed),
            'timestamp': time.time()
        }
        self._save_index()

class EpisodicMemory(MemoryLayer):
    """Memory for specific experiences/episodes"""
    def __init__(self, embedding_model):
        self.episodes = []
        self.embeddings = []
        self.embedding_model = embedding_model
        
    def store(self, key: str, value: Any, metadata: Dict = None):
        episode = {
            'id': key,
            'content': value,
            'metadata': metadata or {},
            'timestamp': time.time()
        }
        
        # Generate embedding for semantic search
        embedding = self.embedding_model.encode(str(value))
        
        self.episodes.append(episode)
        self.embeddings.append(embedding)
    
    def search(self, query: str, limit: int = 10) -> List[Any]:
        # Semantic search using embeddings
        query_embedding = self.embedding_model.encode(query)
        
        similarities = [
            cosine_similarity(query_embedding, emb) 
            for emb in self.embeddings
        ]
        
        # Get top k most similar
        top_indices = sorted(
            range(len(similarities)), 
            key=lambda i: similarities[i], 
            reverse=True
        )[:limit]
        
        return [self.episodes[i] for i in top_indices]

class HierarchicalMemoryAgent:
    def __init__(self):
        self.working_memory = WorkingMemory()
        self.long_term_memory = LongTermMemory(Path("memory_store"))
        self.episodic_memory = EpisodicMemory(load_embedding_model())
        
    def remember(self, key: str, value: Any, importance: float = 0.5):
        """Store in appropriate memory layer based on importance"""
        # Always in working memory
        self.working_memory.store(key, value)
        
        # Important items go to long-term
        if importance > 0.7:
            self.long_term_memory.store(key, value)
            
        # Experiences go to episodic
        if isinstance(value, Experience):
            self.episodic_memory.store(key, value)
    
    def recall(self, key: str) -> Optional[Any]:
        """Retrieve from memory hierarchy"""
        # Check working memory first
        value = self.working_memory.retrieve(key)
        if value:
            return value
            
        # Check long-term
        value = self.long_term_memory.retrieve(key)
        if value:
            # Promote to working memory
            self.working_memory.store(key, value)
            return value
            
        # Search episodic
        results = self.episodic_memory.search(key, limit=1)
        if results:
            return results[0]['content']
            
        return None
```

### 4. Tool Integration Patterns

#### Tool Registry Pattern
```python
from typing import Protocol, Callable, Dict, Any
import inspect

class Tool(Protocol):
    """Protocol for agent tools"""
    name: str
    description: str
    parameters: Dict[str, Any]
    
    def execute(self, **kwargs) -> Any:
        ...

class ToolRegistry:
    """Central registry for agent tools"""
    def __init__(self):
        self._tools: Dict[str, Tool] = {}
        self._validators: Dict[str, Callable] = {}
        self._middlewares: List[Callable] = []
        
    def register(self, tool: Tool, validator: Optional[Callable] = None):
        """Register a tool with optional validator"""
        self._tools[tool.name] = tool
        
        if validator:
            self._validators[tool.name] = validator
        else:
            # Auto-generate validator from parameters
            self._validators[tool.name] = self._create_validator(tool)
    
    def execute(self, tool_name: str, **kwargs) -> Any:
        """Execute tool with validation and middleware"""
        if tool_name not in self._tools:
            raise ValueError(f"Unknown tool: {tool_name}")
            
        tool = self._tools[tool_name]
        
        # Validate parameters
        validator = self._validators[tool_name]
        if not validator(**kwargs):
            raise ValueError(f"Invalid parameters for tool {tool_name}")
        
        # Apply middleware
        for middleware in self._middlewares:
            kwargs = middleware(tool_name, kwargs)
        
        # Execute tool
        try:
            result = tool.execute(**kwargs)
            
            # Post-execution middleware
            for middleware in reversed(self._middlewares):
                if hasattr(middleware, 'post_execute'):
                    result = middleware.post_execute(tool_name, result)
                    
            return result
            
        except Exception as e:
            # Error handling
            self._handle_tool_error(tool_name, e)
            raise
    
    def add_middleware(self, middleware: Callable):
        """Add middleware for all tool executions"""
        self._middlewares.append(middleware)
    
    def _create_validator(self, tool: Tool) -> Callable:
        """Auto-generate parameter validator"""
        def validator(**kwargs):
            # Check required parameters
            for param, spec in tool.parameters.items():
                if spec.get('required', False) and param not in kwargs:
                    return False
                    
                # Type checking
                if param in kwargs and 'type' in spec:
                    expected_type = spec['type']
                    if not isinstance(kwargs[param], expected_type):
                        return False
                        
            return True
            
        return validator

# Example tool implementation
@dataclass
class DatabaseQueryTool:
    name: str = "database_query"
    description: str = "Query database with SQL"
    parameters: Dict[str, Any] = field(default_factory=lambda: {
        'query': {'type': str, 'required': True},
        'database': {'type': str, 'required': False, 'default': 'main'}
    })
    
    def __init__(self, connection_pool):
        self.connection_pool = connection_pool
        
    def execute(self, query: str, database: str = 'main') -> List[Dict]:
        with self.connection_pool.get_connection(database) as conn:
            return conn.execute(query).fetchall()

# Usage
registry = ToolRegistry()
registry.register(DatabaseQueryTool(connection_pool))

# Add logging middleware
def logging_middleware(tool_name: str, params: Dict) -> Dict:
    logger.info(f"Executing tool {tool_name} with params: {params}")
    return params

registry.add_middleware(logging_middleware)
```

### 5. Error Handling and Resilience

#### Circuit Breaker Pattern
```python
from enum import Enum
import time
from threading import Lock

class CircuitState(Enum):
    CLOSED = "closed"  # Normal operation
    OPEN = "open"      # Failing, reject calls
    HALF_OPEN = "half_open"  # Testing recovery

class CircuitBreaker:
    def __init__(
        self,
        failure_threshold: int = 5,
        recovery_timeout: int = 60,
        expected_exception: type = Exception
    ):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.expected_exception = expected_exception
        
        self.failure_count = 0
        self.last_failure_time = None
        self.state = CircuitState.CLOSED
        self._lock = Lock()
        
    def __call__(self, func):
        def wrapper(*args, **kwargs):
            return self._call(func, *args, **kwargs)
        return wrapper
        
    def _call(self, func, *args, **kwargs):
        with self._lock:
            if self.state == CircuitState.OPEN:
                if self._should_attempt_reset():
                    self.state = CircuitState.HALF_OPEN
                else:
                    raise Exception("Circuit breaker is OPEN")
            
        try:
            result = func(*args, **kwargs)
            self._on_success()
            return result
            
        except self.expected_exception as e:
            self._on_failure()
            raise
            
    def _should_attempt_reset(self) -> bool:
        return (
            self.last_failure_time and
            time.time() - self.last_failure_time >= self.recovery_timeout
        )
    
    def _on_success(self):
        with self._lock:
            self.failure_count = 0
            self.state = CircuitState.CLOSED
            
    def _on_failure(self):
        with self._lock:
            self.failure_count += 1
            self.last_failure_time = time.time()
            
            if self.failure_count >= self.failure_threshold:
                self.state = CircuitState.OPEN

class ResilientAgent:
    def __init__(self):
        self.circuit_breakers = {}
        
    @CircuitBreaker(failure_threshold=3, recovery_timeout=30)
    def call_external_api(self, endpoint: str, data: Dict) -> Any:
        """Call external API with circuit breaker protection"""
        response = requests.post(endpoint, json=data)
        response.raise_for_status()
        return response.json()
    
    def process_with_fallback(self, input_data: str) -> str:
        """Process with fallback strategies"""
        strategies = [
            self._primary_processing,
            self._secondary_processing,
            self._fallback_processing
        ]
        
        for strategy in strategies:
            try:
                return strategy(input_data)
            except Exception as e:
                logger.warning(f"Strategy {strategy.__name__} failed: {e}")
                continue
                
        # All strategies failed
        return self._default_response(input_data)
```

### 6. Performance Optimization

#### Caching Strategies
```python
from functools import lru_cache, wraps
import hashlib
import asyncio

class SmartCache:
    """Intelligent caching with TTL and size limits"""
    def __init__(self, max_size: int = 1000, ttl: int = 3600):
        self.max_size = max_size
        self.ttl = ttl
        self.cache = OrderedDict()
        self.stats = {'hits': 0, 'misses': 0}
        
    def key_generator(self, func_name: str, args, kwargs) -> str:
        """Generate cache key from function call"""
        key_data = {
            'func': func_name,
            'args': args,
            'kwargs': sorted(kwargs.items())
        }
        key_str = json.dumps(key_data, sort_keys=True)
        return hashlib.md5(key_str.encode()).hexdigest()
    
    def cached(self, func):
        """Decorator for caching function results"""
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Generate cache key
            key = self.key_generator(func.__name__, args, kwargs)
            
            # Check cache
            if key in self.cache:
                entry = self.cache[key]
                if time.time() - entry['timestamp'] < self.ttl:
                    self.stats['hits'] += 1
                    # Move to end (LRU)
                    self.cache.move_to_end(key)
                    return entry['value']
                else:
                    # Expired
                    del self.cache[key]
            
            # Cache miss
            self.stats['misses'] += 1
            
            # Compute result
            result = func(*args, **kwargs)
            
            # Store in cache
            self._store(key, result)
            
            return result
            
        # Add cache control methods
        wrapper.invalidate = lambda: self.cache.clear()
        wrapper.stats = lambda: self.stats.copy()
        
        return wrapper
    
    def _store(self, key: str, value: Any):
        """Store value in cache with LRU eviction"""
        if len(self.cache) >= self.max_size:
            # Remove oldest
            self.cache.popitem(last=False)
            
        self.cache[key] = {
            'value': value,
            'timestamp': time.time()
        }

# Async caching
class AsyncCache:
    def __init__(self):
        self.cache = {}
        self.locks = defaultdict(asyncio.Lock)
        
    def async_cached(self, func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            key = self._make_key(func, args, kwargs)
            
            # Check cache first
            if key in self.cache:
                return self.cache[key]
            
            # Use lock to prevent multiple concurrent calculations
            async with self.locks[key]:
                # Double-check after acquiring lock
                if key in self.cache:
                    return self.cache[key]
                
                # Calculate and cache
                result = await func(*args, **kwargs)
                self.cache[key] = result
                
                return result
                
        return wrapper
```

### 7. Monitoring and Observability

#### Comprehensive Agent Metrics
```python
from prometheus_client import Counter, Histogram, Gauge, Info
import structlog

class ObservableAgent:
    """Agent with built-in observability"""
    
    # Define metrics
    request_count = Counter(
        'agent_requests_total',
        'Total number of requests processed',
        ['agent_name', 'operation', 'status']
    )
    
    request_duration = Histogram(
        'agent_request_duration_seconds',
        'Request duration in seconds',
        ['agent_name', 'operation']
    )
    
    active_requests = Gauge(
        'agent_active_requests',
        'Number of active requests',
        ['agent_name']
    )
    
    memory_usage = Gauge(
        'agent_memory_usage_bytes',
        'Current memory usage in bytes',
        ['agent_name', 'memory_type']
    )
    
    agent_info = Info(
        'agent_info',
        'Agent metadata'
    )
    
    def __init__(self, name: str, version: str):
        self.name = name
        self.logger = structlog.get_logger().bind(
            agent_name=name,
            agent_version=version
        )
        
        # Set agent info
        self.agent_info.info({
            'name': name,
            'version': version,
            'started_at': datetime.now().isoformat()
        })
        
    def process_request(self, request: Request) -> Response:
        """Process request with full observability"""
        # Track active requests
        self.active_requests.labels(agent_name=self.name).inc()
        
        # Start timer
        start_time = time.time()
        
        # Structured logging
        self.logger.info(
            "request_started",
            request_id=request.id,
            operation=request.operation,
            input_size=len(str(request.data))
        )
        
        try:
            # Process request
            response = self._process(request)
            
            # Record success metrics
            self.request_count.labels(
                agent_name=self.name,
                operation=request.operation,
                status='success'
            ).inc()
            
            self.logger.info(
                "request_completed",
                request_id=request.id,
                duration=time.time() - start_time,
                output_size=len(str(response))
            )
            
            return response
            
        except Exception as e:
            # Record failure metrics
            self.request_count.labels(
                agent_name=self.name,
                operation=request.operation,
                status='error'
            ).inc()
            
            self.logger.error(
                "request_failed",
                request_id=request.id,
                error_type=type(e).__name__,
                error_message=str(e),
                duration=time.time() - start_time
            )
            
            raise
            
        finally:
            # Update metrics
            duration = time.time() - start_time
            self.request_duration.labels(
                agent_name=self.name,
                operation=request.operation
            ).observe(duration)
            
            self.active_requests.labels(agent_name=self.name).dec()
            
            # Update memory metrics
            self._update_memory_metrics()
    
    def _update_memory_metrics(self):
        """Update memory usage metrics"""
        import psutil
        process = psutil.Process()
        
        memory_info = process.memory_info()
        self.memory_usage.labels(
            agent_name=self.name,
            memory_type='rss'
        ).set(memory_info.rss)
        
        self.memory_usage.labels(
            agent_name=self.name,
            memory_type='vms'
        ).set(memory_info.vms)
```

## 🔐 Security Best Practices

### 1. Input Validation and Sanitization
```python
from typing import TypeVar, Type
import re
import bleach

T = TypeVar('T')

class SecureAgent:
    """Agent with security-first design"""
    
    def __init__(self):
        self.validators = {
            'email': self._validate_email,
            'url': self._validate_url,
            'sql': self._validate_sql,
            'command': self._validate_command
        }
        
        # Define allowed patterns
        self.allowed_commands = {'list', 'get', 'search'}
        self.sql_blacklist = {
            'drop', 'delete', 'truncate', 'exec', 
            'execute', 'xp_', 'sp_'
        }
    
    def process_input(self, input_type: str, value: str) -> str:
        """Process input with validation"""
        if input_type not in self.validators:
            raise ValueError(f"Unknown input type: {input_type}")
            
        validator = self.validators[input_type]
        if not validator(value):
            raise ValueError(f"Invalid {input_type}: {value}")
            
        # Sanitize
        sanitized = self._sanitize_input(value, input_type)
        
        return sanitized
    
    def _validate_email(self, email: str) -> bool:
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return bool(re.match(pattern, email))
    
    def _validate_url(self, url: str) -> bool:
        pattern = r'^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$'
        return bool(re.match(pattern, url))
    
    def _validate_sql(self, query: str) -> bool:
        # Check for dangerous keywords
        query_lower = query.lower()
        for keyword in self.sql_blacklist:
            if keyword in query_lower:
                return False
        return True
    
    def _validate_command(self, command: str) -> bool:
        # Only allow whitelisted commands
        cmd_parts = command.split()
        if not cmd_parts:
            return False
            
        return cmd_parts[0] in self.allowed_commands
    
    def _sanitize_input(self, value: str, input_type: str) -> str:
        """Sanitize input based on type"""
        if input_type == 'sql':
            # Escape SQL special characters
            return value.replace("'", "''").replace(";", "")
        
        elif input_type == 'html':
            # Clean HTML
            return bleach.clean(value)
        
        else:
            # General sanitization
            return re.sub(r'[^\w\s-]', '', value)
```

### 2. Secure Tool Execution
```python
import subprocess
import shlex
from pathlib import Path

class SecureToolExecutor:
    """Secure execution of external tools"""
    
    def __init__(self):
        self.allowed_tools = {
            'grep': '/usr/bin/grep',
            'awk': '/usr/bin/awk',
            'sed': '/usr/bin/sed'
        }
        
        self.timeout = 30  # seconds
        self.max_output_size = 1024 * 1024  # 1MB
        
    def execute_tool(self, tool: str, args: List[str]) -> str:
        """Securely execute external tool"""
        # Validate tool
        if tool not in self.allowed_tools:
            raise ValueError(f"Tool not allowed: {tool}")
            
        tool_path = self.allowed_tools[tool]
        
        # Validate tool exists and is executable
        if not Path(tool_path).is_file():
            raise ValueError(f"Tool not found: {tool_path}")
            
        # Sanitize arguments
        safe_args = [shlex.quote(arg) for arg in args]
        
        # Build command
        cmd = [tool_path] + safe_args
        
        try:
            # Execute with restrictions
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=self.timeout,
                check=True,
                # Security restrictions
                preexec_fn=self._drop_privileges,
                env={'PATH': '/usr/bin:/bin'},  # Minimal PATH
                cwd='/tmp'  # Restricted working directory
            )
            
            # Check output size
            if len(result.stdout) > self.max_output_size:
                raise ValueError("Output too large")
                
            return result.stdout
            
        except subprocess.TimeoutExpired:
            raise TimeoutError(f"Tool execution timed out after {self.timeout}s")
        except subprocess.CalledProcessError as e:
            raise RuntimeError(f"Tool execution failed: {e}")
    
    def _drop_privileges(self):
        """Drop privileges for subprocess"""
        import os
        import pwd
        
        # Get nobody user
        nobody = pwd.getpwnam('nobody')
        
        # Drop privileges
        os.setgroups([])
        os.setgid(nobody.pw_gid)
        os.setuid(nobody.pw_uid)
```

## 🧪 Testing Strategies

### 1. Agent Testing Framework
```python
import pytest
from unittest.mock import Mock, patch, AsyncMock
import asyncio

class AgentTestFramework:
    """Comprehensive testing framework for agents"""
    
    @pytest.fixture
    def mock_agent_dependencies(self):
        """Mock all agent dependencies"""
        return {
            'memory': Mock(spec=MemorySystem),
            'tools': Mock(spec=ToolRegistry),
            'state_manager': Mock(spec=StateManager),
            'logger': Mock(spec=Logger)
        }
    
    @pytest.fixture
    def agent_under_test(self, mock_agent_dependencies):
        """Create agent with mocked dependencies"""
        return CustomAgent(**mock_agent_dependencies)
    
    def test_agent_initialization(self, agent_under_test):
        """Test agent initializes correctly"""
        assert agent_under_test.state == AgentState.IDLE
        assert agent_under_test.memory is not None
        assert len(agent_under_test.tools) > 0
    
    @pytest.mark.asyncio
    async def test_async_processing(self, agent_under_test):
        """Test async agent processing"""
        # Mock async tool
        async_tool = AsyncMock(return_value="tool_result")
        agent_under_test.tools.register("async_tool", async_tool)
        
        # Process request
        result = await agent_under_test.process_async("test input")
        
        # Verify
        assert result is not None
        async_tool.assert_called_once()
    
    def test_error_handling(self, agent_under_test):
        """Test agent handles errors gracefully"""
        # Mock tool that raises exception
        failing_tool = Mock(side_effect=Exception("Tool failed"))
        agent_under_test.tools.register("failing_tool", failing_tool)
        
        # Should not raise
        result = agent_under_test.process_with_fallback(
            "use failing_tool"
        )
        
        # Should use fallback
        assert "fallback" in result.lower()
    
    @pytest.mark.parametrize("input_data,expected_state", [
        ("start task", AgentState.PROCESSING),
        ("pause", AgentState.PAUSED),
        ("resume", AgentState.PROCESSING),
        ("stop", AgentState.IDLE)
    ])
    def test_state_transitions(self, agent_under_test, input_data, expected_state):
        """Test agent state transitions"""
        agent_under_test.process_command(input_data)
        assert agent_under_test.state == expected_state

# Property-based testing
from hypothesis import given, strategies as st

class PropertyBasedAgentTests:
    @given(st.text())
    def test_agent_never_crashes(self, input_text):
        """Agent should handle any text input without crashing"""
        agent = RobustAgent()
        
        # Should not raise any exception
        result = agent.process(input_text)
        
        # Should always return a response
        assert result is not None
        assert isinstance(result, str)
    
    @given(st.lists(st.text(), min_size=1, max_size=100))
    def test_agent_memory_consistency(self, items):
        """Agent memory should maintain consistency"""
        agent = MemoryAgent()
        
        # Store all items
        for i, item in enumerate(items):
            agent.remember(f"key_{i}", item)
        
        # Retrieve and verify
        for i, item in enumerate(items):
            retrieved = agent.recall(f"key_{i}")
            assert retrieved == item
```

### 2. Integration Testing
```python
class AgentIntegrationTests:
    """Integration tests for agent systems"""
    
    def test_multi_agent_collaboration(self):
        """Test multiple agents working together"""
        # Create agent ecosystem
        data_agent = DataAnalysisAgent()
        decision_agent = DecisionMakingAgent()
        execution_agent = ExecutionAgent()
        
        # Create orchestrator
        orchestrator = AgentOrchestrator([
            data_agent,
            decision_agent,
            execution_agent
        ])
        
        # Test workflow
        task = ComplexTask(
            objective="Analyze sales data and optimize pricing",
            data_source="sales_db",
            constraints={"max_price_increase": 0.1}
        )
        
        result = orchestrator.execute_workflow(task)
        
        # Verify collaboration
        assert result.status == "completed"
        assert data_agent.call_count > 0
        assert decision_agent.call_count > 0
        assert execution_agent.call_count > 0
    
    def test_agent_persistence(self):
        """Test agent state persistence and recovery"""
        # Create agent with state
        agent = PersistentAgent("test_agent")
        agent.process("learn about user preferences")
        agent.process("user likes python")
        
        original_state = agent.get_state()
        
        # Simulate restart
        new_agent = PersistentAgent("test_agent")
        new_agent.load_state()
        
        # Verify state restored
        assert new_agent.get_state() == original_state
        
        # Verify knowledge retained
        response = new_agent.process("what does the user like?")
        assert "python" in response.lower()
```

## 📊 Production Deployment

### 1. Agent Deployment Architecture
```python
# docker-compose.yml for agent deployment
"""
version: '3.8'

services:
  agent-api:
    build: .
    environment:
      - AGENT_MODE=production
      - REDIS_URL=redis://redis:6379
      - DATABASE_URL=postgresql://postgres:password@db:5432/agents
    ports:
      - "8080:8080"
    depends_on:
      - redis
      - db
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
  
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    
  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=agents
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    
  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana

volumes:
  redis_data:
  postgres_data:
  prometheus_data:
  grafana_data:
"""
```

### 2. Agent Scaling Strategies
```python
class ScalableAgentPool:
    """Pool of agents for horizontal scaling"""
    
    def __init__(self, min_agents: int = 1, max_agents: int = 10):
        self.min_agents = min_agents
        self.max_agents = max_agents
        self.agents = []
        self.load_balancer = LoadBalancer()
        
        # Initialize minimum agents
        for _ in range(min_agents):
            self._create_agent()
    
    def _create_agent(self):
        """Create and register new agent"""
        agent = CustomAgent(f"agent_{len(self.agents)}")
        self.agents.append(agent)
        self.load_balancer.register(agent)
        
    def process_request(self, request: Request) -> Response:
        """Process request with load balancing"""
        # Get available agent
        agent = self.load_balancer.get_next_agent()
        
        # Check if scaling needed
        if self._should_scale_up():
            self._scale_up()
        elif self._should_scale_down():
            self._scale_down()
        
        # Process request
        return agent.process(request)
    
    def _should_scale_up(self) -> bool:
        """Check if should add more agents"""
        avg_load = self.load_balancer.get_average_load()
        return (
            avg_load > 0.8 and 
            len(self.agents) < self.max_agents
        )
    
    def _should_scale_down(self) -> bool:
        """Check if should remove agents"""
        avg_load = self.load_balancer.get_average_load()
        return (
            avg_load < 0.2 and 
            len(self.agents) > self.min_agents
        )
```

## 🎯 Checklist for Production-Ready Agents

### Development Phase
- [ ] Domain-driven design implemented
- [ ] State management pattern chosen and implemented
- [ ] Memory architecture designed for scale
- [ ] Tool registry with validation
- [ ] Comprehensive error handling
- [ ] Security measures implemented
- [ ] Monitoring and metrics added
- [ ] Logging strategy defined

### Testing Phase
- [ ] Unit tests > 80% coverage
- [ ] Integration tests written
- [ ] Property-based tests added
- [ ] Performance tests completed
- [ ] Security testing performed
- [ ] Chaos testing conducted

### Deployment Phase
- [ ] Containerization complete
- [ ] Scaling strategy implemented
- [ ] Monitoring dashboards created
- [ ] Alerting rules configured
- [ ] Backup and recovery tested
- [ ] Documentation complete
- [ ] Runbook created

### Operations Phase
- [ ] SLIs and SLOs defined
- [ ] On-call procedures documented
- [ ] Incident response plan created
- [ ] Regular security audits scheduled
- [ ] Performance optimization ongoing
- [ ] Cost optimization reviewed

Remember: Building custom agents is an iterative process. Start simple, measure everything, and continuously improve based on real-world usage!