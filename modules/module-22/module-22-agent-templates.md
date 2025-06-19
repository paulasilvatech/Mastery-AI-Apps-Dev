# Agent Template Library

## 📚 resources/agent-templates/

### base_agent.py
```python
"""Base agent template with core functionality"""

from abc import ABC, abstractmethod
from typing import Any, Dict, List, Optional
from dataclasses import dataclass, field
from datetime import datetime
import logging
import asyncio
from enum import Enum

class AgentStatus(Enum):
    """Agent operational status"""
    IDLE = "idle"
    PROCESSING = "processing"
    ERROR = "error"
    SHUTDOWN = "shutdown"

@dataclass
class AgentConfig:
    """Base configuration for agents"""
    name: str
    version: str = "1.0.0"
    timeout: int = 300  # seconds
    max_retries: int = 3
    log_level: str = "INFO"
    metadata: Dict[str, Any] = field(default_factory=dict)

class BaseAgent(ABC):
    """Abstract base class for all custom agents"""
    
    def __init__(self, config: AgentConfig):
        self.config = config
        self.status = AgentStatus.IDLE
        self.logger = self._setup_logger()
        self._start_time = datetime.now()
        self._request_count = 0
        self._error_count = 0
        
    def _setup_logger(self) -> logging.Logger:
        """Configure agent-specific logger"""
        logger = logging.getLogger(f"agent.{self.config.name}")
        logger.setLevel(self.config.log_level)
        
        if not logger.handlers:
            handler = logging.StreamHandler()
            formatter = logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            )
            handler.setFormatter(formatter)
            logger.addHandler(handler)
            
        return logger
    
    @abstractmethod
    async def process(self, input_data: Any) -> Any:
        """Main processing method to be implemented by subclasses"""
        pass
    
    @abstractmethod
    async def initialize(self) -> None:
        """Initialize agent resources"""
        pass
    
    @abstractmethod
    async def shutdown(self) -> None:
        """Clean up agent resources"""
        pass
    
    async def __aenter__(self):
        """Async context manager entry"""
        await self.initialize()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit"""
        await self.shutdown()
    
    async def execute(self, input_data: Any) -> Any:
        """Execute with error handling and retries"""
        self._request_count += 1
        self.status = AgentStatus.PROCESSING
        
        for attempt in range(self.config.max_retries):
            try:
                self.logger.info(f"Processing request {self._request_count} (attempt {attempt + 1})")
                result = await asyncio.wait_for(
                    self.process(input_data),
                    timeout=self.config.timeout
                )
                self.status = AgentStatus.IDLE
                return result
                
            except asyncio.TimeoutError:
                self.logger.error(f"Timeout on attempt {attempt + 1}")
                self._error_count += 1
                if attempt == self.config.max_retries - 1:
                    self.status = AgentStatus.ERROR
                    raise
                    
            except Exception as e:
                self.logger.error(f"Error on attempt {attempt + 1}: {e}")
                self._error_count += 1
                if attempt == self.config.max_retries - 1:
                    self.status = AgentStatus.ERROR
                    raise
                    
            await asyncio.sleep(2 ** attempt)  # Exponential backoff
    
    def get_metrics(self) -> Dict[str, Any]:
        """Get agent performance metrics"""
        uptime = (datetime.now() - self._start_time).total_seconds()
        
        return {
            "name": self.config.name,
            "version": self.config.version,
            "status": self.status.value,
            "uptime_seconds": uptime,
            "request_count": self._request_count,
            "error_count": self._error_count,
            "error_rate": self._error_count / max(1, self._request_count),
            "avg_request_time": uptime / max(1, self._request_count)
        }

# Example implementation
class ExampleAgent(BaseAgent):
    """Example agent implementation"""
    
    async def initialize(self) -> None:
        """Initialize resources"""
        self.logger.info(f"Initializing {self.config.name}")
        # Setup connections, load models, etc.
        
    async def process(self, input_data: str) -> str:
        """Process input data"""
        # Implement your processing logic
        return f"Processed: {input_data}"
    
    async def shutdown(self) -> None:
        """Clean up resources"""
        self.logger.info(f"Shutting down {self.config.name}")
        # Close connections, save state, etc.

# Usage example
async def main():
    config = AgentConfig(name="example_agent", version="1.0.0")
    
    async with ExampleAgent(config) as agent:
        result = await agent.execute("Hello, World!")
        print(result)
        print(agent.get_metrics())

if __name__ == "__main__":
    asyncio.run(main())
```

### stateful_agent.py
```python
"""Stateful agent template with persistent state management"""

from typing import Any, Dict, Optional, TypeVar, Generic
from dataclasses import dataclass
import pickle
import json
from pathlib import Path
import aiofiles
from base_agent import BaseAgent, AgentConfig

T = TypeVar('T')

@dataclass
class StatefulAgentConfig(AgentConfig):
    """Configuration for stateful agents"""
    state_path: Path = Path("agent_state")
    checkpoint_interval: int = 100  # requests
    state_backend: str = "file"  # file, redis, database

class AgentState(Generic[T]):
    """Generic state container"""
    
    def __init__(self, initial_state: Optional[T] = None):
        self._state: Optional[T] = initial_state
        self._version: int = 0
        self._checkpoints: List[Tuple[int, T]] = []
        
    def get(self) -> Optional[T]:
        """Get current state"""
        return self._state
    
    def set(self, new_state: T) -> None:
        """Set new state"""
        self._state = new_state
        self._version += 1
    
    def checkpoint(self) -> None:
        """Create a checkpoint"""
        if self._state is not None:
            self._checkpoints.append((self._version, self._state))
            # Keep only last 10 checkpoints
            self._checkpoints = self._checkpoints[-10:]
    
    def rollback(self, version: Optional[int] = None) -> bool:
        """Rollback to a previous version"""
        if not self._checkpoints:
            return False
            
        if version is None:
            # Rollback to last checkpoint
            self._version, self._state = self._checkpoints[-1]
        else:
            # Find specific version
            for v, state in self._checkpoints:
                if v == version:
                    self._version, self._state = v, state
                    return True
            return False
            
        return True

class StatefulAgent(BaseAgent):
    """Base class for agents with persistent state"""
    
    def __init__(self, config: StatefulAgentConfig):
        super().__init__(config)
        self.config: StatefulAgentConfig = config
        self.state: AgentState[Dict[str, Any]] = AgentState(initial_state={})
        self._operation_count = 0
        
    async def initialize(self) -> None:
        """Initialize and load state"""
        await super().initialize()
        await self._load_state()
        
    async def shutdown(self) -> None:
        """Save state and shutdown"""
        await self._save_state()
        await super().shutdown()
    
    async def _load_state(self) -> None:
        """Load state from storage"""
        state_file = self.config.state_path / f"{self.config.name}_state.json"
        
        if state_file.exists():
            try:
                async with aiofiles.open(state_file, 'r') as f:
                    data = json.loads(await f.read())
                    self.state.set(data)
                    self.logger.info(f"Loaded state from {state_file}")
            except Exception as e:
                self.logger.error(f"Failed to load state: {e}")
    
    async def _save_state(self) -> None:
        """Save state to storage"""
        self.config.state_path.mkdir(parents=True, exist_ok=True)
        state_file = self.config.state_path / f"{self.config.name}_state.json"
        
        try:
            current_state = self.state.get()
            if current_state:
                async with aiofiles.open(state_file, 'w') as f:
                    await f.write(json.dumps(current_state, indent=2))
                self.logger.info(f"Saved state to {state_file}")
        except Exception as e:
            self.logger.error(f"Failed to save state: {e}")
    
    async def process(self, input_data: Any) -> Any:
        """Process with state management"""
        self._operation_count += 1
        
        # Auto-checkpoint
        if self._operation_count % self.config.checkpoint_interval == 0:
            self.state.checkpoint()
            await self._save_state()
        
        # Implement in subclass
        return await self._process_with_state(input_data)
    
    async def _process_with_state(self, input_data: Any) -> Any:
        """Override this method in subclasses"""
        raise NotImplementedError

# Example: Conversation agent with state
class ConversationAgent(StatefulAgent):
    """Agent that maintains conversation history"""
    
    async def initialize(self) -> None:
        await super().initialize()
        
        # Initialize state structure
        current_state = self.state.get() or {}
        if 'conversations' not in current_state:
            current_state['conversations'] = {}
        if 'total_messages' not in current_state:
            current_state['total_messages'] = 0
        self.state.set(current_state)
    
    async def _process_with_state(self, input_data: Dict[str, str]) -> str:
        """Process message with conversation history"""
        user_id = input_data.get('user_id', 'default')
        message = input_data.get('message', '')
        
        # Get current state
        current_state = self.state.get()
        
        # Update conversation history
        if user_id not in current_state['conversations']:
            current_state['conversations'][user_id] = []
        
        current_state['conversations'][user_id].append({
            'timestamp': datetime.now().isoformat(),
            'message': message
        })
        
        current_state['total_messages'] += 1
        
        # Update state
        self.state.set(current_state)
        
        # Generate response based on history
        history = current_state['conversations'][user_id]
        response = f"You've sent {len(history)} messages. Last: {message}"
        
        return response
```

### memory_agent.py
```python
"""Agent template with advanced memory systems"""

from typing import Any, Dict, List, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime, timedelta
from collections import deque
import numpy as np
from abc import abstractmethod
import hashlib
import json

from base_agent import BaseAgent, AgentConfig

@dataclass
class MemoryConfig:
    """Configuration for memory systems"""
    short_term_capacity: int = 100
    long_term_capacity: int = 10000
    embedding_dim: int = 768
    similarity_threshold: float = 0.8
    memory_decay_days: int = 30

class MemoryType:
    """Types of memory"""
    EPISODIC = "episodic"  # Specific experiences
    SEMANTIC = "semantic"  # General knowledge
    PROCEDURAL = "procedural"  # How to do things
    WORKING = "working"  # Current context

@dataclass
class Memory:
    """Individual memory entry"""
    id: str
    type: str
    content: Any
    embedding: Optional[np.ndarray]
    timestamp: datetime
    access_count: int = 0
    importance: float = 0.5
    metadata: Dict[str, Any] = None
    
    def decay_score(self, current_time: datetime, decay_days: int) -> float:
        """Calculate memory decay based on time"""
        age_days = (current_time - self.timestamp).days
        decay_factor = max(0, 1 - (age_days / decay_days))
        return self.importance * decay_factor

class MemoryAgent(BaseAgent):
    """Agent with sophisticated memory capabilities"""
    
    def __init__(self, config: AgentConfig, memory_config: MemoryConfig):
        super().__init__(config)
        self.memory_config = memory_config
        
        # Different memory stores
        self.working_memory = deque(maxlen=10)
        self.short_term_memory = deque(maxlen=memory_config.short_term_capacity)
        self.long_term_memory: Dict[str, Memory] = {}
        
        # Memory indices for fast retrieval
        self.semantic_index: Dict[str, List[str]] = {}
        self.episodic_timeline: List[Tuple[datetime, str]] = []
        
    async def initialize(self) -> None:
        """Initialize memory systems"""
        await super().initialize()
        self.logger.info("Initializing memory systems")
        
    def store_memory(self, content: Any, memory_type: str, 
                    importance: float = 0.5, metadata: Dict[str, Any] = None) -> str:
        """Store a new memory"""
        # Generate unique ID
        memory_id = self._generate_memory_id(content)
        
        # Create embedding (simplified - use real embedding model)
        embedding = self._create_embedding(content)
        
        # Create memory object
        memory = Memory(
            id=memory_id,
            type=memory_type,
            content=content,
            embedding=embedding,
            timestamp=datetime.now(),
            importance=importance,
            metadata=metadata or {}
        )
        
        # Store in appropriate memory system
        if memory_type == MemoryType.WORKING:
            self.working_memory.append(memory)
        else:
            self.short_term_memory.append(memory)
            
            # Promote important memories to long-term
            if importance > 0.7:
                self._promote_to_long_term(memory)
        
        # Update indices
        self._update_indices(memory)
        
        self.logger.debug(f"Stored memory {memory_id} of type {memory_type}")
        return memory_id
    
    def recall_memory(self, query: Any, memory_type: Optional[str] = None, 
                     top_k: int = 5) -> List[Memory]:
        """Recall memories based on query"""
        query_embedding = self._create_embedding(query)
        
        # Search in different memory stores
        candidates = []
        
        # Working memory (always check)
        candidates.extend(self.working_memory)
        
        # Short-term memory
        candidates.extend(self.short_term_memory)
        
        # Long-term memory (filtered by type if specified)
        if memory_type:
            candidates.extend([m for m in self.long_term_memory.values() 
                             if m.type == memory_type])
        else:
            candidates.extend(self.long_term_memory.values())
        
        # Score and rank memories
        scored_memories = []
        current_time = datetime.now()
        
        for memory in candidates:
            if memory.embedding is not None:
                similarity = self._cosine_similarity(query_embedding, memory.embedding)
                decay_score = memory.decay_score(current_time, self.memory_config.memory_decay_days)
                total_score = similarity * decay_score
                
                if total_score > self.memory_config.similarity_threshold:
                    scored_memories.append((total_score, memory))
        
        # Sort by score and return top k
        scored_memories.sort(key=lambda x: x[0], reverse=True)
        
        # Update access counts
        results = []
        for score, memory in scored_memories[:top_k]:
            memory.access_count += 1
            results.append(memory)
            
        return results
    
    def consolidate_memories(self) -> None:
        """Consolidate short-term memories into long-term"""
        current_time = datetime.now()
        memories_to_consolidate = []
        
        # Find important or frequently accessed memories
        for memory in self.short_term_memory:
            if (memory.importance > 0.6 or 
                memory.access_count > 3 or
                (current_time - memory.timestamp).seconds > 3600):  # 1 hour old
                memories_to_consolidate.append(memory)
        
        # Move to long-term memory
        for memory in memories_to_consolidate:
            self._promote_to_long_term(memory)
            self.short_term_memory.remove(memory)
    
    def forget_memories(self, threshold_days: int = 90) -> int:
        """Remove old, unimportant memories"""
        current_time = datetime.now()
        memories_to_forget = []
        
        for memory_id, memory in self.long_term_memory.items():
            age_days = (current_time - memory.timestamp).days
            
            # Forget old, unimportant, rarely accessed memories
            if (age_days > threshold_days and 
                memory.importance < 0.3 and 
                memory.access_count < 2):
                memories_to_forget.append(memory_id)
        
        # Remove memories
        for memory_id in memories_to_forget:
            del self.long_term_memory[memory_id]
            self._remove_from_indices(memory_id)
        
        self.logger.info(f"Forgot {len(memories_to_forget)} memories")
        return len(memories_to_forget)
    
    async def process(self, input_data: Any) -> Any:
        """Process with memory augmentation"""
        # Store input as working memory
        self.store_memory(
            content=input_data,
            memory_type=MemoryType.WORKING,
            importance=0.8
        )
        
        # Recall relevant memories
        relevant_memories = self.recall_memory(input_data, top_k=10)
        
        # Process with memory context
        result = await self._process_with_memory(input_data, relevant_memories)
        
        # Store the interaction as episodic memory
        self.store_memory(
            content={
                'input': input_data,
                'output': result,
                'context': [m.id for m in relevant_memories]
            },
            memory_type=MemoryType.EPISODIC,
            importance=0.6
        )
        
        # Periodic consolidation
        if len(self.short_term_memory) > self.memory_config.short_term_capacity * 0.8:
            self.consolidate_memories()
        
        return result
    
    @abstractmethod
    async def _process_with_memory(self, input_data: Any, 
                                  relevant_memories: List[Memory]) -> Any:
        """Process input with memory context - implement in subclass"""
        pass
    
    def _generate_memory_id(self, content: Any) -> str:
        """Generate unique ID for memory"""
        content_str = json.dumps(content, sort_keys=True)
        timestamp = datetime.now().isoformat()
        return hashlib.md5(f"{content_str}{timestamp}".encode()).hexdigest()[:16]
    
    def _create_embedding(self, content: Any) -> np.ndarray:
        """Create embedding for content (placeholder - use real model)"""
        # This is a simplified example - use real embedding model
        content_str = str(content)
        # Simple hash-based embedding
        hash_value = int(hashlib.md5(content_str.encode()).hexdigest(), 16)
        np.random.seed(hash_value % 2**32)
        return np.random.randn(self.memory_config.embedding_dim)
    
    def _cosine_similarity(self, a: np.ndarray, b: np.ndarray) -> float:
        """Calculate cosine similarity between embeddings"""
        return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))
    
    def _promote_to_long_term(self, memory: Memory) -> None:
        """Promote memory to long-term storage"""
        self.long_term_memory[memory.id] = memory
        
        # Manage capacity
        if len(self.long_term_memory) > self.memory_config.long_term_capacity:
            # Remove least important old memory
            sorted_memories = sorted(
                self.long_term_memory.values(),
                key=lambda m: m.importance * m.access_count
            )
            to_remove = sorted_memories[0]
            del self.long_term_memory[to_remove.id]
            self._remove_from_indices(to_remove.id)
    
    def _update_indices(self, memory: Memory) -> None:
        """Update memory indices"""
        # Semantic index (by type)
        if memory.type not in self.semantic_index:
            self.semantic_index[memory.type] = []
        self.semantic_index[memory.type].append(memory.id)
        
        # Episodic timeline
        if memory.type == MemoryType.EPISODIC:
            self.episodic_timeline.append((memory.timestamp, memory.id))
            self.episodic_timeline.sort(key=lambda x: x[0])
    
    def _remove_from_indices(self, memory_id: str) -> None:
        """Remove memory from indices"""
        # Remove from semantic index
        for memories in self.semantic_index.values():
            if memory_id in memories:
                memories.remove(memory_id)
        
        # Remove from timeline
        self.episodic_timeline = [(t, mid) for t, mid in self.episodic_timeline 
                                  if mid != memory_id]

# Example implementation
class KnowledgeAgent(MemoryAgent):
    """Agent that builds and uses knowledge over time"""
    
    async def _process_with_memory(self, input_data: str, 
                                  relevant_memories: List[Memory]) -> str:
        """Process query using accumulated knowledge"""
        # Build context from memories
        context_parts = []
        
        for memory in relevant_memories:
            if memory.type == MemoryType.SEMANTIC:
                context_parts.append(f"Known fact: {memory.content}")
            elif memory.type == MemoryType.EPISODIC:
                context_parts.append(f"Previous interaction: {memory.content}")
        
        # Generate response based on context
        if context_parts:
            context = "\n".join(context_parts[:5])  # Limit context size
            response = f"Based on my memory:\n{context}\n\nRegarding '{input_data}': [Generated response]"
        else:
            response = f"This is new information about '{input_data}'. I'll remember this."
            
            # Store as semantic knowledge
            self.store_memory(
                content=input_data,
                memory_type=MemoryType.SEMANTIC,
                importance=0.7
            )
        
        return response
```

### tool_agent.py
```python
"""Agent template with advanced tool integration"""

from typing import Any, Dict, List, Optional, Callable, TypeVar, Protocol
from dataclasses import dataclass, field
from abc import abstractmethod
import inspect
import asyncio
from concurrent.futures import ThreadPoolExecutor
import json

from base_agent import BaseAgent, AgentConfig

T = TypeVar('T')

class Tool(Protocol):
    """Protocol for agent tools"""
    name: str
    description: str
    
    async def execute(self, **kwargs) -> Any:
        """Execute the tool"""
        ...

@dataclass
class ToolSpec:
    """Tool specification"""
    name: str
    description: str
    parameters: Dict[str, Dict[str, Any]]  # param_name -> {type, description, required}
    returns: Dict[str, Any]  # {type, description}
    async_tool: bool = True
    requires_confirmation: bool = False
    max_retries: int = 3
    timeout: int = 30

@dataclass
class ToolResult:
    """Result from tool execution"""
    tool_name: str
    success: bool
    result: Any
    error: Optional[str] = None
    execution_time: float = 0.0
    metadata: Dict[str, Any] = field(default_factory=dict)

class ToolAgent(BaseAgent):
    """Agent with sophisticated tool management"""
    
    def __init__(self, config: AgentConfig):
        super().__init__(config)
        self.tools: Dict[str, Tool] = {}
        self.tool_specs: Dict[str, ToolSpec] = {}
        self.tool_history: List[ToolResult] = []
        self.executor = ThreadPoolExecutor(max_workers=5)
        
    async def initialize(self) -> None:
        """Initialize agent and tools"""
        await super().initialize()
        await self._initialize_tools()
        
    async def shutdown(self) -> None:
        """Shutdown agent and cleanup"""
        self.executor.shutdown(wait=True)
        await super().shutdown()
    
    @abstractmethod
    async def _initialize_tools(self) -> None:
        """Initialize available tools - implement in subclass"""
        pass
    
    def register_tool(self, tool: Tool, spec: ToolSpec) -> None:
        """Register a new tool"""
        self.tools[spec.name] = tool
        self.tool_specs[spec.name] = spec
        self.logger.info(f"Registered tool: {spec.name}")
    
    async def call_tool(self, tool_name: str, **kwargs) -> ToolResult:
        """Call a registered tool with error handling"""
        if tool_name not in self.tools:
            return ToolResult(
                tool_name=tool_name,
                success=False,
                result=None,
                error=f"Tool '{tool_name}' not found"
            )
        
        tool = self.tools[tool_name]
        spec = self.tool_specs[tool_name]
        
        # Validate parameters
        validation_error = self._validate_parameters(spec, kwargs)
        if validation_error:
            return ToolResult(
                tool_name=tool_name,
                success=False,
                result=None,
                error=validation_error
            )
        
        # Execute tool with retries
        start_time = asyncio.get_event_loop().time()
        
        for attempt in range(spec.max_retries):
            try:
                # Confirm if required
                if spec.requires_confirmation:
                    if not await self._confirm_tool_execution(tool_name, kwargs):
                        return ToolResult(
                            tool_name=tool_name,
                            success=False,
                            result=None,
                            error="User cancelled tool execution"
                        )
                
                # Execute tool
                if spec.async_tool:
                    result = await asyncio.wait_for(
                        tool.execute(**kwargs),
                        timeout=spec.timeout
                    )
                else:
                    # Run sync tool in thread pool
                    result = await asyncio.get_event_loop().run_in_executor(
                        self.executor,
                        tool.execute,
                        **kwargs
                    )
                
                # Success
                tool_result = ToolResult(
                    tool_name=tool_name,
                    success=True,
                    result=result,
                    execution_time=asyncio.get_event_loop().time() - start_time
                )
                
                self.tool_history.append(tool_result)
                return tool_result
                
            except asyncio.TimeoutError:
                error = f"Tool '{tool_name}' timed out after {spec.timeout}s"
                self.logger.error(error)
                
                if attempt == spec.max_retries - 1:
                    tool_result = ToolResult(
                        tool_name=tool_name,
                        success=False,
                        result=None,
                        error=error,
                        execution_time=asyncio.get_event_loop().time() - start_time
                    )
                    self.tool_history.append(tool_result)
                    return tool_result
                    
            except Exception as e:
                error = f"Tool '{tool_name}' error: {str(e)}"
                self.logger.error(error)
                
                if attempt == spec.max_retries - 1:
                    tool_result = ToolResult(
                        tool_name=tool_name,
                        success=False,
                        result=None,
                        error=error,
                        execution_time=asyncio.get_event_loop().time() - start_time
                    )
                    self.tool_history.append(tool_result)
                    return tool_result
            
            # Wait before retry
            await asyncio.sleep(2 ** attempt)
    
    async def call_tools_parallel(self, tool_calls: List[Tuple[str, Dict[str, Any]]]) -> List[ToolResult]:
        """Execute multiple tools in parallel"""
        tasks = []
        
        for tool_name, kwargs in tool_calls:
            task = self.call_tool(tool_name, **kwargs)
            tasks.append(task)
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Handle any exceptions
        processed_results = []
        for i, result in enumerate(results):
            if isinstance(result, Exception):
                tool_name = tool_calls[i][0]
                processed_results.append(ToolResult(
                    tool_name=tool_name,
                    success=False,
                    result=None,
                    error=str(result)
                ))
            else:
                processed_results.append(result)
        
        return processed_results
    
    def select_tool(self, task_description: str) -> Optional[str]:
        """Select the best tool for a task (simple implementation)"""
        # This is a simplified version - use LLM or better matching
        task_lower = task_description.lower()
        
        best_match = None
        best_score = 0
        
        for tool_name, spec in self.tool_specs.items():
            # Simple keyword matching
            description_lower = spec.description.lower()
            
            # Count matching words
            task_words = set(task_lower.split())
            desc_words = set(description_lower.split())
            
            common_words = task_words.intersection(desc_words)
            score = len(common_words) / max(len(task_words), 1)
            
            if score > best_score:
                best_score = score
                best_match = tool_name
        
        return best_match if best_score > 0.3 else None
    
    def get_tool_description(self, tool_name: str) -> Optional[str]:
        """Get human-readable tool description"""
        if tool_name not in self.tool_specs:
            return None
        
        spec = self.tool_specs[tool_name]
        
        # Build parameter description
        param_desc = []
        for param_name, param_info in spec.parameters.items():
            required = param_info.get('required', False)
            param_type = param_info.get('type', 'any')
            description = param_info.get('description', '')
            
            param_str = f"  - {param_name} ({param_type})"
            if required:
                param_str += " [REQUIRED]"
            if description:
                param_str += f": {description}"
            
            param_desc.append(param_str)
        
        # Build full description
        desc_parts = [
            f"Tool: {spec.name}",
            f"Description: {spec.description}",
            "Parameters:"
        ]
        desc_parts.extend(param_desc)
        
        if spec.returns:
            return_type = spec.returns.get('type', 'any')
            return_desc = spec.returns.get('description', '')
            desc_parts.append(f"Returns: {return_type} - {return_desc}")
        
        return "\n".join(desc_parts)
    
    def _validate_parameters(self, spec: ToolSpec, kwargs: Dict[str, Any]) -> Optional[str]:
        """Validate tool parameters"""
        # Check required parameters
        for param_name, param_info in spec.parameters.items():
            if param_info.get('required', False) and param_name not in kwargs:
                return f"Missing required parameter: {param_name}"
        
        # Check parameter types (simplified)
        for param_name, value in kwargs.items():
            if param_name not in spec.parameters:
                continue  # Allow extra parameters
            
            expected_type = spec.parameters[param_name].get('type')
            if expected_type and not self._check_type(value, expected_type):
                return f"Invalid type for {param_name}: expected {expected_type}, got {type(value).__name__}"
        
        return None
    
    def _check_type(self, value: Any, expected_type: str) -> bool:
        """Simple type checking"""
        type_map = {
            'str': str,
            'int': int,
            'float': float,
            'bool': bool,
            'list': list,
            'dict': dict
        }
        
        if expected_type in type_map:
            return isinstance(value, type_map[expected_type])
        
        return True  # Unknown type, allow it
    
    async def _confirm_tool_execution(self, tool_name: str, kwargs: Dict[str, Any]) -> bool:
        """Confirm tool execution (override in subclass for real confirmation)"""
        self.logger.info(f"Tool execution confirmation required: {tool_name} with {kwargs}")
        return True  # Auto-confirm in base implementation
    
    def get_tool_statistics(self) -> Dict[str, Any]:
        """Get statistics about tool usage"""
        stats = {
            'total_tools': len(self.tools),
            'total_calls': len(self.tool_history),
            'success_rate': 0.0,
            'average_execution_time': 0.0,
            'tool_usage': {}
        }
        
        if self.tool_history:
            successful_calls = sum(1 for r in self.tool_history if r.success)
            stats['success_rate'] = successful_calls / len(self.tool_history)
            
            total_time = sum(r.execution_time for r in self.tool_history)
            stats['average_execution_time'] = total_time / len(self.tool_history)
            
            # Per-tool statistics
            for result in self.tool_history:
                if result.tool_name not in stats['tool_usage']:
                    stats['tool_usage'][result.tool_name] = {
                        'calls': 0,
                        'successes': 0,
                        'failures': 0,
                        'total_time': 0.0
                    }
                
                tool_stats = stats['tool_usage'][result.tool_name]
                tool_stats['calls'] += 1
                if result.success:
                    tool_stats['successes'] += 1
                else:
                    tool_stats['failures'] += 1
                tool_stats['total_time'] += result.execution_time
        
        return stats

# Example tools
class CalculatorTool:
    """Simple calculator tool"""
    name = "calculator"
    description = "Performs basic mathematical calculations"
    
    async def execute(self, expression: str) -> float:
        """Evaluate mathematical expression"""
        # In production, use a safe expression evaluator
        try:
            result = eval(expression, {"__builtins__": {}}, {})
            return float(result)
        except Exception as e:
            raise ValueError(f"Invalid expression: {e}")

class WebSearchTool:
    """Web search tool (mock)"""
    name = "web_search"
    description = "Searches the web for information"
    
    async def execute(self, query: str, max_results: int = 5) -> List[Dict[str, str]]:
        """Search the web (mock implementation)"""
        # Mock results
        await asyncio.sleep(0.5)  # Simulate network delay
        
        results = []
        for i in range(max_results):
            results.append({
                "title": f"Result {i+1} for '{query}'",
                "url": f"https://example.com/result{i+1}",
                "snippet": f"This is a snippet for result {i+1} about {query}..."
            })
        
        return results

# Example implementation
class AssistantAgent(ToolAgent):
    """Assistant agent with multiple tools"""
    
    async def _initialize_tools(self) -> None:
        """Initialize available tools"""
        # Register calculator
        calc_spec = ToolSpec(
            name="calculator",
            description="Performs basic mathematical calculations",
            parameters={
                "expression": {
                    "type": "str",
                    "description": "Mathematical expression to evaluate",
                    "required": True
                }
            },
            returns={
                "type": "float",
                "description": "Result of the calculation"
            }
        )
        self.register_tool(CalculatorTool(), calc_spec)
        
        # Register web search
        search_spec = ToolSpec(
            name="web_search",
            description="Searches the web for information",
            parameters={
                "query": {
                    "type": "str",
                    "description": "Search query",
                    "required": True
                },
                "max_results": {
                    "type": "int",
                    "description": "Maximum number of results",
                    "required": False
                }
            },
            returns={
                "type": "list",
                "description": "List of search results"
            }
        )
        self.register_tool(WebSearchTool(), search_spec)
    
    async def process(self, input_data: str) -> str:
        """Process user input and use tools as needed"""
        # Simple intent detection
        if "calculate" in input_data.lower() or "math" in input_data.lower():
            # Extract expression (simplified)
            expression = input_data.split("calculate")[-1].strip()
            
            result = await self.call_tool("calculator", expression=expression)
            
            if result.success:
                return f"The result is: {result.result}"
            else:
                return f"Calculation error: {result.error}"
        
        elif "search" in input_data.lower():
            # Extract query
            query = input_data.split("search for")[-1].strip()
            
            result = await self.call_tool("web_search", query=query, max_results=3)
            
            if result.success:
                response_parts = ["Here are the search results:"]
                for i, item in enumerate(result.result, 1):
                    response_parts.append(f"{i}. {item['title']}")
                    response_parts.append(f"   {item['snippet']}")
                
                return "\n".join(response_parts)
            else:
                return f"Search error: {result.error}"
        
        else:
            # Try to select appropriate tool
            selected_tool = self.select_tool(input_data)
            
            if selected_tool:
                return f"I think you want to use the {selected_tool} tool. {self.get_tool_description(selected_tool)}"
            else:
                return "I'm not sure which tool to use for this request. Available tools: " + ", ".join(self.tools.keys())

# Usage example
async def main():
    config = AgentConfig(name="assistant", version="1.0.0")
    
    async with AssistantAgent(config) as agent:
        # Test calculator
        result1 = await agent.execute("Calculate 42 * 17 + 3")
        print(f"Math result: {result1}")
        
        # Test search
        result2 = await agent.execute("Search for Python async programming")
        print(f"\nSearch result: {result2}")
        
        # Show statistics
        stats = agent.get_tool_statistics()
        print(f"\nTool statistics: {json.dumps(stats, indent=2)}")

if __name__ == "__main__":
    asyncio.run(main())
```