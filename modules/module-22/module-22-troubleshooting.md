# 🔧 Module 22: Custom Agents Troubleshooting Guide

## Common Issues and Solutions

### 🚫 Agent State Management Issues

#### Problem: Agent loses state between requests
```python
# Symptom: Agent doesn't remember previous interactions
agent = CustomAgent()
agent.process("My name is John")
response = agent.process("What is my name?")  # Returns "I don't know"
```

**Solutions:**

1. **Ensure State Persistence**
```python
class StatefulAgent:
    def __init__(self):
        self.state_manager = PersistentStateManager()
        self.conversation_state = self.state_manager.load_state()
    
    def process(self, input_text: str) -> str:
        # Update state
        self.conversation_state.add_message(input_text)
        
        # Process with state context
        response = self._generate_response(self.conversation_state)
        
        # Persist state
        self.state_manager.save_state(self.conversation_state)
        
        return response
```

2. **Use Session Management**
```python
from functools import lru_cache

class SessionAwareAgent:
    def __init__(self):
        self.sessions = {}
    
    def process(self, input_text: str, session_id: str) -> str:
        # Get or create session
        if session_id not in self.sessions:
            self.sessions[session_id] = AgentSession()
        
        session = self.sessions[session_id]
        return session.process(input_text)
    
    @lru_cache(maxsize=100)
    def get_session(self, session_id: str) -> AgentSession:
        return self.sessions.get(session_id, AgentSession())
```

#### Problem: State corruption during concurrent access
```python
# Multiple threads accessing agent state simultaneously
# Results in race conditions and corrupted state
```

**Solutions:**

1. **Thread-Safe State Management**
```python
import threading
from contextlib import contextmanager

class ThreadSafeAgent:
    def __init__(self):
        self._state_lock = threading.RLock()
        self._state = {}
    
    @contextmanager
    def state_transaction(self):
        """Context manager for atomic state updates"""
        self._state_lock.acquire()
        try:
            # Make a copy for rollback
            backup = self._state.copy()
            yield self._state
            # Transaction successful
        except Exception:
            # Rollback on error
            self._state = backup
            raise
        finally:
            self._state_lock.release()
    
    def update_state(self, key: str, value: Any):
        with self.state_transaction() as state:
            state[key] = value
```

2. **Use Immutable State**
```python
from dataclasses import dataclass, replace

@dataclass(frozen=True)
class ImmutableAgentState:
    messages: tuple = ()
    context: dict = None
    
    def add_message(self, message: str) -> 'ImmutableAgentState':
        return replace(
            self,
            messages=self.messages + (message,)
        )
```

### 🔴 Memory System Issues

#### Problem: Memory leak - agent memory grows unbounded
```python
# Agent memory usage keeps increasing
# Eventually causes OutOfMemoryError
```

**Solutions:**

1. **Implement Memory Limits**
```python
from collections import OrderedDict
import sys

class BoundedMemory:
    def __init__(self, max_items: int = 1000, max_size_mb: int = 100):
        self.max_items = max_items
        self.max_size_bytes = max_size_mb * 1024 * 1024
        self.memory = OrderedDict()
    
    def store(self, key: str, value: Any):
        # Check size limit
        size = sys.getsizeof(value)
        total_size = sum(sys.getsizeof(v) for v in self.memory.values())
        
        # Evict if necessary
        while (len(self.memory) >= self.max_items or 
               total_size + size > self.max_size_bytes):
            if not self.memory:
                raise MemoryError("Single item exceeds memory limit")
            
            # Remove oldest item (LRU)
            self.memory.popitem(last=False)
            total_size = sum(sys.getsizeof(v) for v in self.memory.values())
        
        self.memory[key] = value
```

2. **Implement Memory Cleanup**
```python
import weakref
import gc

class ManagedMemoryAgent:
    def __init__(self):
        self.memory = {}
        self.weak_refs = weakref.WeakValueDictionary()
        
        # Schedule periodic cleanup
        self._cleanup_timer = threading.Timer(300, self._cleanup_memory)
        self._cleanup_timer.start()
    
    def _cleanup_memory(self):
        """Periodic memory cleanup"""
        # Remove expired items
        now = time.time()
        expired_keys = [
            k for k, v in self.memory.items()
            if hasattr(v, 'expires_at') and v.expires_at < now
        ]
        
        for key in expired_keys:
            del self.memory[key]
        
        # Force garbage collection
        gc.collect()
        
        # Reschedule
        self._cleanup_timer = threading.Timer(300, self._cleanup_memory)
        self._cleanup_timer.start()
```

#### Problem: Slow memory retrieval
```python
# Memory searches take too long
# Agent response time degrades with memory size
```

**Solutions:**

1. **Use Indexed Memory**
```python
import faiss
import numpy as np

class IndexedVectorMemory:
    def __init__(self, dimension: int = 768):
        self.dimension = dimension
        self.index = faiss.IndexFlatL2(dimension)
        self.memories = []
        self.metadata = []
    
    def store(self, vector: np.ndarray, data: Any, metadata: Dict = None):
        """Store with vector index"""
        self.index.add(vector.reshape(1, -1))
        self.memories.append(data)
        self.metadata.append(metadata or {})
    
    def search(self, query_vector: np.ndarray, k: int = 5) -> List[Any]:
        """Fast vector similarity search"""
        distances, indices = self.index.search(
            query_vector.reshape(1, -1), k
        )
        
        return [
            {
                'data': self.memories[idx],
                'metadata': self.metadata[idx],
                'distance': dist
            }
            for idx, dist in zip(indices[0], distances[0])
            if idx < len(self.memories)
        ]
```

2. **Implement Caching Layer**
```python
from functools import lru_cache
import hashlib

class CachedMemory:
    def __init__(self, backend_memory):
        self.backend = backend_memory
        self.cache = {}
        self.cache_stats = {'hits': 0, 'misses': 0}
    
    @lru_cache(maxsize=128)
    def _search_cached(self, query_hash: str, limit: int):
        """Cached search by query hash"""
        return self.backend.search(query_hash, limit)
    
    def search(self, query: str, limit: int = 10) -> List[Any]:
        # Generate cache key
        query_hash = hashlib.md5(query.encode()).hexdigest()
        
        # Try cache first
        cached_result = self.cache.get((query_hash, limit))
        if cached_result is not None:
            self.cache_stats['hits'] += 1
            return cached_result
        
        # Cache miss - search backend
        self.cache_stats['misses'] += 1
        result = self.backend.search(query, limit)
        
        # Cache result
        self.cache[(query_hash, limit)] = result
        
        return result
```

### 🔗 Tool Integration Issues

#### Problem: Tool execution hangs or times out
```python
# Tool calls never return or take too long
# Agent becomes unresponsive
```

**Solutions:**

1. **Implement Timeouts**
```python
import asyncio
from concurrent.futures import ThreadPoolExecutor, TimeoutError

class TimeoutToolExecutor:
    def __init__(self, timeout: int = 30):
        self.timeout = timeout
        self.executor = ThreadPoolExecutor(max_workers=5)
    
    def execute_tool(self, tool: Tool, **kwargs) -> Any:
        """Execute tool with timeout"""
        future = self.executor.submit(tool.execute, **kwargs)
        
        try:
            result = future.result(timeout=self.timeout)
            return result
        except TimeoutError:
            # Cancel the operation
            future.cancel()
            raise TimeoutError(f"Tool {tool.name} timed out after {self.timeout}s")
        except Exception as e:
            raise RuntimeError(f"Tool {tool.name} failed: {e}")
    
    async def execute_tool_async(self, tool: Tool, **kwargs) -> Any:
        """Async tool execution with timeout"""
        try:
            return await asyncio.wait_for(
                tool.execute_async(**kwargs),
                timeout=self.timeout
            )
        except asyncio.TimeoutError:
            raise TimeoutError(f"Tool {tool.name} timed out")
```

2. **Implement Circuit Breakers**
```python
from datetime import datetime, timedelta

class ToolCircuitBreaker:
    def __init__(self, failure_threshold: int = 5, timeout: int = 60):
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.failures = defaultdict(list)
        self.circuit_open = defaultdict(bool)
        self.circuit_open_until = {}
    
    def is_open(self, tool_name: str) -> bool:
        """Check if circuit is open for tool"""
        if tool_name in self.circuit_open_until:
            if datetime.now() < self.circuit_open_until[tool_name]:
                return True
            else:
                # Reset circuit
                self.circuit_open[tool_name] = False
                del self.circuit_open_until[tool_name]
                self.failures[tool_name].clear()
        
        return self.circuit_open[tool_name]
    
    def record_success(self, tool_name: str):
        """Record successful execution"""
        self.failures[tool_name].clear()
        self.circuit_open[tool_name] = False
    
    def record_failure(self, tool_name: str):
        """Record failure and check if circuit should open"""
        now = datetime.now()
        self.failures[tool_name].append(now)
        
        # Remove old failures
        cutoff = now - timedelta(seconds=self.timeout)
        self.failures[tool_name] = [
            f for f in self.failures[tool_name] if f > cutoff
        ]
        
        # Check if circuit should open
        if len(self.failures[tool_name]) >= self.failure_threshold:
            self.circuit_open[tool_name] = True
            self.circuit_open_until[tool_name] = now + timedelta(seconds=self.timeout)
```

#### Problem: Tool dependency conflicts
```python
# Different tools require conflicting dependencies
# ImportError or version conflicts
```

**Solutions:**

1. **Isolate Tool Environments**
```python
import subprocess
import json

class IsolatedToolExecutor:
    """Execute tools in isolated environments"""
    
    def __init__(self):
        self.tool_environments = {
            'python_tool': 'conda activate tool_env_1',
            'node_tool': 'nvm use 16',
            'ruby_tool': 'rvm use 3.0'
        }
    
    def execute_isolated(self, tool_name: str, script: str, args: Dict) -> Any:
        """Execute tool in isolated environment"""
        # Create temporary script
        script_file = f"/tmp/{tool_name}_{uuid.uuid4()}.py"
        
        with open(script_file, 'w') as f:
            f.write(f"""
import json
import sys

# Tool execution
result = {script}

# Output result as JSON
print(json.dumps(result))
""")
        
        # Get environment activation
        env_cmd = self.tool_environments.get(tool_name, '')
        
        # Execute in subprocess with environment
        cmd = f"{env_cmd} && python {script_file} '{json.dumps(args)}'"
        
        try:
            result = subprocess.run(
                cmd,
                shell=True,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode != 0:
                raise RuntimeError(f"Tool failed: {result.stderr}")
            
            return json.loads(result.stdout)
            
        finally:
            # Cleanup
            os.remove(script_file)
```

### 🧠 Agent Decision Making Issues

#### Problem: Agent gets stuck in decision loops
```python
# Agent keeps reconsidering the same options
# Never reaches a conclusion
```

**Solutions:**

1. **Implement Decision Timeouts**
```python
class DecisionMaker:
    def __init__(self, max_iterations: int = 10):
        self.max_iterations = max_iterations
    
    def make_decision(self, options: List[Any], context: Dict) -> Any:
        """Make decision with iteration limit"""
        best_option = None
        best_score = float('-inf')
        
        for iteration in range(self.max_iterations):
            # Evaluate options
            scores = {}
            for option in options:
                score = self.evaluate_option(option, context)
                scores[option] = score
                
                if score > best_score:
                    best_score = score
                    best_option = option
            
            # Check for convergence
            if self.has_converged(scores, iteration):
                break
            
            # Update context for next iteration
            context = self.update_context(context, scores)
        
        return best_option
    
    def has_converged(self, scores: Dict, iteration: int) -> bool:
        """Check if decision has converged"""
        if iteration == 0:
            return False
        
        # Check if scores are stable
        score_variance = np.var(list(scores.values()))
        return score_variance < 0.01
```

2. **Use Decision Trees**
```python
class DecisionTreeAgent:
    def __init__(self):
        self.decision_tree = self._build_decision_tree()
    
    def _build_decision_tree(self):
        """Build decision tree structure"""
        return {
            'root': {
                'condition': lambda ctx: ctx.get('urgency', 'low'),
                'high': {
                    'action': 'immediate_response',
                    'params': {'priority': 1}
                },
                'medium': {
                    'condition': lambda ctx: ctx.get('complexity', 'low'),
                    'high': {
                        'action': 'delegate_to_expert',
                        'params': {'expert_type': 'senior'}
                    },
                    'low': {
                        'action': 'standard_response',
                        'params': {'template': 'quick'}
                    }
                },
                'low': {
                    'action': 'queue_for_later',
                    'params': {'queue': 'low_priority'}
                }
            }
        }
    
    def decide(self, context: Dict) -> Dict[str, Any]:
        """Make decision using tree"""
        node = self.decision_tree['root']
        
        while 'condition' in node:
            condition_result = str(node['condition'](context))
            node = node.get(condition_result, node.get('default', {}))
        
        return {
            'action': node.get('action', 'default_action'),
            'params': node.get('params', {})
        }
```

### 🔌 Async/Concurrent Processing Issues

#### Problem: Deadlocks in async agent operations
```python
# Agent hangs when processing multiple async operations
# Tasks wait for each other indefinitely
```

**Solutions:**

1. **Implement Deadlock Detection**
```python
import asyncio
from asyncio import Task
from typing import Set

class DeadlockDetector:
    def __init__(self):
        self.active_tasks: Set[Task] = set()
        self.task_dependencies: Dict[Task, Set[Task]] = {}
    
    async def execute_with_detection(self, coro, dependencies: Set[Task] = None):
        """Execute coroutine with deadlock detection"""
        task = asyncio.create_task(coro)
        self.active_tasks.add(task)
        
        if dependencies:
            self.task_dependencies[task] = dependencies
        
        try:
            # Check for cycles
            if self._has_cycle(task):
                raise RuntimeError("Deadlock detected!")
            
            result = await task
            return result
            
        finally:
            self.active_tasks.discard(task)
            self.task_dependencies.pop(task, None)
    
    def _has_cycle(self, start_task: Task) -> bool:
        """Detect cycles in task dependencies"""
        visited = set()
        rec_stack = set()
        
        def visit(task):
            if task in rec_stack:
                return True
            if task in visited:
                return False
            
            visited.add(task)
            rec_stack.add(task)
            
            for dep in self.task_dependencies.get(task, []):
                if visit(dep):
                    return True
            
            rec_stack.remove(task)
            return False
        
        return visit(start_task)
```

2. **Use Async Context Managers**
```python
class AsyncResourceManager:
    def __init__(self):
        self.resources = {}
        self.locks = defaultdict(asyncio.Lock)
    
    async def acquire_resources(self, resource_ids: List[str]):
        """Acquire multiple resources in consistent order"""
        # Sort to prevent deadlock
        sorted_ids = sorted(resource_ids)
        
        acquired = []
        try:
            for resource_id in sorted_ids:
                async with self.locks[resource_id]:
                    resource = await self._load_resource(resource_id)
                    self.resources[resource_id] = resource
                    acquired.append(resource_id)
            
            return [self.resources[rid] for rid in resource_ids]
            
        except Exception:
            # Release acquired resources
            for resource_id in acquired:
                await self._release_resource(resource_id)
            raise
```

## 🔍 Debugging Techniques

### 1. Agent State Inspection
```python
class DebuggableAgent:
    def __init__(self):
        self.debug_mode = False
        self.state_history = []
        self.decision_log = []
    
    def enable_debug(self):
        """Enable debug mode"""
        self.debug_mode = True
        
    def _debug_snapshot(self):
        """Take snapshot of current state"""
        if self.debug_mode:
            snapshot = {
                'timestamp': datetime.now(),
                'state': copy.deepcopy(self.__dict__),
                'stack_trace': traceback.format_stack()
            }
            self.state_history.append(snapshot)
    
    def get_debug_info(self) -> Dict[str, Any]:
        """Get comprehensive debug information"""
        return {
            'current_state': self.__dict__,
            'state_history': self.state_history[-10:],  # Last 10 states
            'decision_log': self.decision_log[-20:],    # Last 20 decisions
            'metrics': self._calculate_metrics()
        }
```

### 2. Performance Profiling
```python
import cProfile
import pstats
from io import StringIO

class ProfilableAgent:
    def __init__(self):
        self.profiler = cProfile.Profile()
        self.profiling = False
    
    def start_profiling(self):
        """Start performance profiling"""
        self.profiling = True
        self.profiler.enable()
    
    def stop_profiling(self) -> str:
        """Stop profiling and return report"""
        self.profiler.disable()
        self.profiling = False
        
        # Generate report
        stream = StringIO()
        stats = pstats.Stats(self.profiler, stream=stream)
        stats.sort_stats('cumulative')
        stats.print_stats(20)  # Top 20 functions
        
        return stream.getvalue()
    
    def process_with_profiling(self, input_data: str) -> str:
        """Process with optional profiling"""
        if self.profiling:
            self.profiler.enable()
        
        try:
            result = self._process_internal(input_data)
            return result
        finally:
            if self.profiling:
                self.profiler.disable()
```

### 3. Trace Logging
```python
import functools
import structlog

def trace_method(func):
    """Decorator for tracing method calls"""
    @functools.wraps(func)
    def wrapper(self, *args, **kwargs):
        logger = structlog.get_logger()
        
        # Log entry
        logger.debug(
            "method_entry",
            class_name=self.__class__.__name__,
            method_name=func.__name__,
            args=args,
            kwargs=kwargs
        )
        
        start_time = time.time()
        
        try:
            result = func(self, *args, **kwargs)
            
            # Log successful exit
            logger.debug(
                "method_exit",
                class_name=self.__class__.__name__,
                method_name=func.__name__,
                duration=time.time() - start_time,
                result_type=type(result).__name__
            )
            
            return result
            
        except Exception as e:
            # Log error
            logger.error(
                "method_error",
                class_name=self.__class__.__name__,
                method_name=func.__name__,
                error_type=type(e).__name__,
                error_message=str(e),
                duration=time.time() - start_time
            )
            raise

class TracedAgent:
    @trace_method
    def process(self, input_data: str) -> str:
        # All method calls are automatically traced
        return self._internal_process(input_data)
```

## 🛠️ Diagnostic Tools

### Agent Health Check Script
```python
#!/usr/bin/env python3
"""
Agent health check diagnostic tool
"""

import asyncio
import psutil
import time
from typing import Dict, Any

class AgentDiagnostics:
    def __init__(self, agent):
        self.agent = agent
    
    async def run_diagnostics(self) -> Dict[str, Any]:
        """Run comprehensive diagnostics"""
        results = {
            'timestamp': datetime.now().isoformat(),
            'agent_name': getattr(self.agent, 'name', 'Unknown'),
            'checks': {}
        }
        
        # Memory check
        results['checks']['memory'] = self._check_memory()
        
        # State check
        results['checks']['state'] = self._check_state()
        
        # Tool availability
        results['checks']['tools'] = await self._check_tools()
        
        # Response time
        results['checks']['response_time'] = await self._check_response_time()
        
        # Error rate
        results['checks']['error_rate'] = self._check_error_rate()
        
        return results
    
    def _check_memory(self) -> Dict[str, Any]:
        """Check memory usage"""
        process = psutil.Process()
        memory_info = process.memory_info()
        
        return {
            'status': 'healthy' if memory_info.rss < 1e9 else 'warning',
            'rss_mb': memory_info.rss / 1024 / 1024,
            'vms_mb': memory_info.vms / 1024 / 1024,
            'percent': process.memory_percent()
        }
    
    def _check_state(self) -> Dict[str, Any]:
        """Check agent state consistency"""
        try:
            state = self.agent.get_state()
            return {
                'status': 'healthy',
                'state_size': len(str(state)),
                'state_type': type(state).__name__
            }
        except Exception as e:
            return {
                'status': 'error',
                'error': str(e)
            }
    
    async def _check_tools(self) -> Dict[str, Any]:
        """Check tool availability"""
        if not hasattr(self.agent, 'tools'):
            return {'status': 'not_applicable'}
        
        available = 0
        total = 0
        failed = []
        
        for tool_name in self.agent.tools.list_tools():
            total += 1
            try:
                # Test tool
                await self.agent.tools.test_tool(tool_name)
                available += 1
            except Exception as e:
                failed.append({
                    'tool': tool_name,
                    'error': str(e)
                })
        
        return {
            'status': 'healthy' if available == total else 'degraded',
            'available': available,
            'total': total,
            'failed': failed
        }
    
    async def _check_response_time(self) -> Dict[str, Any]:
        """Check agent response time"""
        test_inputs = [
            "Hello",
            "What is 2+2?",
            "Explain quantum computing"
        ]
        
        response_times = []
        
        for test_input in test_inputs:
            start = time.time()
            try:
                await asyncio.wait_for(
                    self.agent.process(test_input),
                    timeout=10
                )
                response_times.append(time.time() - start)
            except asyncio.TimeoutError:
                response_times.append(10.0)
        
        avg_time = sum(response_times) / len(response_times)
        
        return {
            'status': 'healthy' if avg_time < 2 else 'slow',
            'average_ms': avg_time * 1000,
            'max_ms': max(response_times) * 1000,
            'min_ms': min(response_times) * 1000
        }

# Usage
async def main():
    agent = YourCustomAgent()
    diagnostics = AgentDiagnostics(agent)
    
    results = await diagnostics.run_diagnostics()
    
    print(json.dumps(results, indent=2))
    
    # Generate report
    if any(check['status'] != 'healthy' for check in results['checks'].values()):
        print("\n⚠️ Issues detected! See details above.")
    else:
        print("\n✅ All checks passed!")

if __name__ == "__main__":
    asyncio.run(main())
```

## 🔧 Quick Fixes

### Memory Issues
```bash
# Clear agent memory
python -c "agent.memory.clear(); agent.save_state()"

# Garbage collect
python -c "import gc; gc.collect()"

# Check memory usage
ps aux | grep python | grep agent
```

### State Issues
```bash
# Reset agent state
python -c "agent.reset_state(); agent.initialize()"

# Export state for inspection
python -c "import json; print(json.dumps(agent.get_state(), indent=2))"
```

### Performance Issues
```bash
# Profile agent
python -m cProfile -s cumulative agent_script.py > profile.txt

# Monitor in real-time
htop -p $(pgrep -f agent)
```

## 📞 Getting Help

If issues persist:

1. **Enable Debug Logging**
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

2. **Collect Diagnostics**
```bash
python diagnostic_script.py > diagnostics.txt
```

3. **Create Minimal Reproduction**
```python
# minimal_repro.py
agent = CustomAgent()
# Minimal code that shows the problem
```

4. **Check Community Resources**
- GitHub Issues for known problems
- Stack Overflow for common patterns
- Discord/Slack for real-time help

Remember: Most agent issues come from state management, memory leaks, or tool integration problems. Start debugging there!