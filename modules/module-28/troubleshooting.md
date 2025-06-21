# Agentic DevOps Troubleshooting Guide

## 🔍 Overview

This comprehensive guide helps diagnose and resolve common issues in Agentic DevOps implementations. Each issue includes symptoms, root causes, diagnostic steps, and proven solutions.

## 📋 Quick Diagnostics

### System Health Check Script
```bash
#!/bin/bash
# Agentic DevOps System Health Check

echo "🔍 Running Agentic DevOps Diagnostics..."

# Check core services
echo -e "\n🤖 Agent Status:"
curl -s http://localhost:8000/health || echo "❌ Agent API not responding"

# Check Kubernetes
echo -e "\n☸️ Kubernetes Status:"
kubectl get nodes || echo "❌ Kubernetes not accessible"
kubectl get pods -n agentic-devops || echo "❌ No agents running"

# Check monitoring
echo -e "\n📊 Monitoring Stack:"
curl -s http://localhost:9090/-/healthy || echo "❌ Prometheus not healthy"
curl -s http://localhost:3000/api/health || echo "❌ Grafana not accessible"

# Check message broker
echo -e "\n📬 Message Broker:"
nc -zv localhost 4222 || echo "❌ NATS not accessible"

# Check AI services
echo -e "\n🧠 AI Services:"
python3 -c "import openai; print('✅ OpenAI module loaded')" || echo "❌ OpenAI not available"

echo -e "\n✅ Diagnostics complete!"
```

## 🚨 Common Issues and Solutions

### 1. Agent Communication Failures

#### Issue: Agents Not Communicating
**Symptoms:**
- Agents running but not processing tasks
- No events being published/consumed
- Timeout errors in logs

**Diagnosis:**
```python
# Test agent communication
import asyncio
from nats.aio.client import Client as NATS

async def test_nats_connection():
    nc = NATS()
    
    try:
        await nc.connect("nats://localhost:4222")
        print("✅ Connected to NATS")
        
        # Test pub/sub
        async def message_handler(msg):
            print(f"Received: {msg.data.decode()}")
        
        await nc.subscribe("test.subject", cb=message_handler)
        await nc.publish("test.subject", b"Test message")
        await nc.flush()
        
        await asyncio.sleep(1)
        await nc.close()
        
    except Exception as e:
        print(f"❌ NATS connection failed: {e}")

asyncio.run(test_nats_connection())
```

**Solution:**
```bash
# Fix NATS connection issues
# 1. Check NATS is running
docker ps | grep nats || docker run -d -p 4222:4222 -p 8222:8222 nats:latest

# 2. Check firewall rules
sudo ufw allow 4222/tcp

# 3. Restart agents with correct config
export AGENT_BROKER_URL=nats://localhost:4222
python agents/orchestrator/main.py
```

#### Issue: Message Serialization Errors
**Symptoms:**
```
Error: Failed to deserialize message: invalid JSON
```

**Solution:**
```python
# Fix serialization issues
import json
from typing import Any, Dict
import structlog

logger = structlog.get_logger()

class RobustMessageHandler:
    """Handle message serialization robustly"""
    
    @staticmethod
    def serialize_message(data: Dict[str, Any]) -> bytes:
        """Safely serialize messages"""
        try:
            # Handle non-serializable objects
            def default_handler(obj):
                if hasattr(obj, 'isoformat'):
                    return obj.isoformat()
                elif hasattr(obj, '__dict__'):
                    return obj.__dict__
                else:
                    return str(obj)
            
            json_str = json.dumps(data, default=default_handler)
            return json_str.encode('utf-8')
            
        except Exception as e:
            logger.error(f"Serialization failed: {e}")
            # Fallback to string representation
            return str(data).encode('utf-8')
    
    @staticmethod
    def deserialize_message(data: bytes) -> Dict[str, Any]:
        """Safely deserialize messages"""
        try:
            return json.loads(data.decode('utf-8'))
        except json.JSONDecodeError:
            # Try to extract any valid JSON
            try:
                text = data.decode('utf-8', errors='ignore')
                # Find JSON-like content
                import re
                json_match = re.search(r'\{.*\}', text, re.DOTALL)
                if json_match:
                    return json.loads(json_match.group())
            except:
                pass
            
            # Return as string if all else fails
            return {'raw_data': data.decode('utf-8', errors='ignore')}
```

### 2. Kubernetes Deployment Issues

#### Issue: Agent Pods Crashing
**Symptoms:**
- CrashLoopBackOff status
- Pods restarting frequently
- OOMKilled errors

**Diagnosis:**
```bash
# Check pod status
kubectl get pods -n agentic-devops

# Check pod logs
kubectl logs -n agentic-devops <pod-name> --previous

# Describe pod for events
kubectl describe pod -n agentic-devops <pod-name>

# Check resource usage
kubectl top pods -n agentic-devops
```

**Solution:**
```yaml
# Fix resource limits - agent-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: devops-agent
  namespace: agentic-devops
spec:
  replicas: 3
  selector:
    matchLabels:
      app: devops-agent
  template:
    metadata:
      labels:
        app: devops-agent
    spec:
      containers:
      - name: agent
        image: devops-agent:latest
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "2000m"
        env:
        - name: PYTHONUNBUFFERED
          value: "1"
        - name: AGENT_LOG_LEVEL
          value: "INFO"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: config
          mountPath: /app/config
          readOnly: true
      volumes:
      - name: config
        configMap:
          name: agent-config
```

#### Issue: Service Discovery Not Working
**Symptoms:**
- Agents can't find each other
- DNS resolution failures
- Connection refused errors

**Solution:**
```yaml
# Fix service discovery - agent-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: agent-orchestrator
  namespace: agentic-devops
  labels:
    app: agent-orchestrator
spec:
  selector:
    app: agent-orchestrator
  ports:
  - name: http
    port: 8000
    targetPort: 8000
  - name: grpc
    port: 50051
    targetPort: 50051
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: agent-orchestrator-headless
  namespace: agentic-devops
spec:
  selector:
    app: agent-orchestrator
  clusterIP: None
  ports:
  - name: http
    port: 8000
    targetPort: 8000
```

### 3. AI Model Integration Issues

#### Issue: OpenAI API Rate Limits
**Symptoms:**
```
openai.error.RateLimitError: Rate limit reached
```

**Solution:**
```python
# Implement rate limiting and retry logic
import asyncio
from typing import Optional, Dict, Any
import openai
from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type,
    before_sleep_log
)
import logging

logger = logging.getLogger(__name__)

class RateLimitedOpenAI:
    """OpenAI client with rate limiting"""
    
    def __init__(self, api_key: str, max_rpm: int = 60):
        self.api_key = api_key
        self.max_rpm = max_rpm
        self.semaphore = asyncio.Semaphore(max_rpm // 60)  # Requests per second
        openai.api_key = api_key
    
    @retry(
        stop=stop_after_attempt(5),
        wait=wait_exponential(multiplier=1, min=4, max=60),
        retry=retry_if_exception_type(openai.error.RateLimitError),
        before_sleep=before_sleep_log(logger, logging.WARNING)
    )
    async def complete(self, 
                      prompt: str, 
                      model: str = "gpt-4",
                      **kwargs) -> Dict[str, Any]:
        """Call OpenAI with rate limiting and retry"""
        
        async with self.semaphore:
            try:
                response = await asyncio.to_thread(
                    openai.ChatCompletion.create,
                    model=model,
                    messages=[{"role": "user", "content": prompt}],
                    **kwargs
                )
                return response
                
            except openai.error.RateLimitError as e:
                logger.warning(f"Rate limit hit: {e}")
                raise
            except openai.error.APIError as e:
                logger.error(f"OpenAI API error: {e}")
                # Use fallback model or cache
                return self.get_cached_response(prompt)
```

#### Issue: Model Response Parsing Errors
**Symptoms:**
- JSON parsing failures from AI responses
- Unexpected response formats
- Missing expected fields

**Solution:**
```python
# Robust AI response parsing
import json
from typing import Dict, Any, Optional
from pydantic import BaseModel, ValidationError

class AIResponseParser:
    """Parse AI responses robustly"""
    
    @staticmethod
    def parse_json_response(response_text: str) -> Optional[Dict[str, Any]]:
        """Extract JSON from AI response"""
        
        # Try direct parsing
        try:
            return json.loads(response_text)
        except json.JSONDecodeError:
            pass
        
        # Try to find JSON in text
        import re
        json_patterns = [
            r'```json\s*(.*?)\s*```',  # Markdown code block
            r'```\s*(.*?)\s*```',       # Generic code block
            r'\{.*\}',                  # Raw JSON object
            r'\[.*\]'                   # Raw JSON array
        ]
        
        for pattern in json_patterns:
            matches = re.findall(pattern, response_text, re.DOTALL)
            for match in matches:
                try:
                    return json.loads(match)
                except:
                    continue
        
        # Try to fix common issues
        cleaned = response_text.strip()
        
        # Remove trailing commas
        cleaned = re.sub(r',(\s*[}\]])', r'\1', cleaned)
        
        # Add quotes to unquoted keys
        cleaned = re.sub(r'(\w+):', r'"\1":', cleaned)
        
        try:
            return json.loads(cleaned)
        except:
            return None
    
    @staticmethod
    def validate_response(data: Dict[str, Any], schema: BaseModel) -> Optional[BaseModel]:
        """Validate response against schema"""
        try:
            return schema(**data)
        except ValidationError as e:
            logger.error(f"Validation error: {e}")
            
            # Try to fix common issues
            fixed_data = {}
            for field in schema.__fields__:
                if field in data:
                    fixed_data[field] = data[field]
                else:
                    # Use default if available
                    field_info = schema.__fields__[field]
                    if field_info.default is not None:
                        fixed_data[field] = field_info.default
            
            try:
                return schema(**fixed_data)
            except:
                return None
```

### 4. Pipeline Execution Failures

#### Issue: Pipeline Steps Timing Out
**Symptoms:**
- Steps hanging indefinitely
- Timeout errors in CI/CD
- Incomplete deployments

**Solution:**
```python
# Implement timeout handling
import asyncio
from typing import Optional, Callable, Any
from datetime import datetime, timedelta

class TimeoutHandler:
    """Handle timeouts gracefully"""
    
    async def execute_with_timeout(self,
                                  func: Callable,
                                  timeout_seconds: int,
                                  cleanup_func: Optional[Callable] = None) -> Any:
        """Execute function with timeout"""
        
        try:
            # Create task
            task = asyncio.create_task(func())
            
            # Wait with timeout
            result = await asyncio.wait_for(task, timeout=timeout_seconds)
            return result
            
        except asyncio.TimeoutError:
            logger.error(f"Task timed out after {timeout_seconds}s")
            
            # Cancel the task
            task.cancel()
            
            # Run cleanup if provided
            if cleanup_func:
                try:
                    await cleanup_func()
                except Exception as e:
                    logger.error(f"Cleanup failed: {e}")
            
            raise
        except Exception as e:
            logger.error(f"Task failed: {e}")
            raise

# Usage in pipeline
class PipelineExecutor:
    def __init__(self):
        self.timeout_handler = TimeoutHandler()
    
    async def execute_step(self, step: PipelineStep) -> StepResult:
        """Execute pipeline step with timeout"""
        
        # Define cleanup function
        async def cleanup():
            # Kill any running processes
            if hasattr(step, 'process') and step.process:
                step.process.terminate()
            
            # Clean up temporary resources
            if hasattr(step, 'temp_resources'):
                for resource in step.temp_resources:
                    await resource.cleanup()
        
        try:
            result = await self.timeout_handler.execute_with_timeout(
                step.execute,
                timeout_seconds=step.timeout or 600,  # Default 10 minutes
                cleanup_func=cleanup
            )
            return result
            
        except asyncio.TimeoutError:
            return StepResult(
                status='timeout',
                error=f"Step {step.name} timed out"
            )
```

### 5. Security Scanning Issues

#### Issue: False Positives in Security Scans
**Symptoms:**
- Too many security alerts
- Known safe patterns flagged
- Alert fatigue

**Solution:**
```python
# Implement intelligent filtering
class SecurityScanFilter:
    """Filter security scan results intelligently"""
    
    def __init__(self):
        self.false_positive_patterns = self.load_patterns()
        self.ml_filter = self.load_ml_model()
    
    async def filter_results(self, scan_results: List[SecurityFinding]) -> List[SecurityFinding]:
        """Filter out false positives"""
        
        filtered = []
        
        for finding in scan_results:
            # Check against known false positives
            if self.is_known_false_positive(finding):
                logger.info(f"Filtered known false positive: {finding.id}")
                continue
            
            # Use ML to classify
            confidence = await self.ml_filter.classify(finding)
            if confidence < 0.3:  # Low confidence it's real
                logger.info(f"ML filtered: {finding.id} (confidence: {confidence})")
                continue
            
            # Check context
            if await self.check_context(finding):
                filtered.append(finding)
        
        return filtered
    
    def is_known_false_positive(self, finding: SecurityFinding) -> bool:
        """Check against known patterns"""
        
        for pattern in self.false_positive_patterns:
            if pattern.matches(finding):
                return True
        
        return False
    
    async def check_context(self, finding: SecurityFinding) -> bool:
        """Check finding in context"""
        
        # Example: Check if vulnerability is in test code
        if finding.file_path and 'test' in finding.file_path:
            if finding.severity < 'HIGH':
                return False  # Ignore medium/low in tests
        
        # Check if already mitigated
        mitigations = await self.get_mitigations(finding.cve_id)
        if mitigations:
            return False
        
        return True
```

### 6. Agent Performance Issues

#### Issue: Slow Agent Response Times
**Symptoms:**
- High latency in agent responses
- Tasks queuing up
- Memory usage growing

**Diagnosis:**
```python
# Performance profiling
import cProfile
import pstats
import tracemalloc
from datetime import datetime

class PerformanceProfiler:
    """Profile agent performance"""
    
    def __init__(self):
        self.profiles = {}
        tracemalloc.start()
    
    def profile_function(self, func_name: str):
        """Decorator to profile functions"""
        def decorator(func):
            async def wrapper(*args, **kwargs):
                # CPU profiling
                profiler = cProfile.Profile()
                profiler.enable()
                
                # Memory snapshot before
                snapshot1 = tracemalloc.take_snapshot()
                
                start_time = datetime.now()
                try:
                    result = await func(*args, **kwargs)
                    return result
                finally:
                    # Stop profiling
                    profiler.disable()
                    
                    # Memory snapshot after
                    snapshot2 = tracemalloc.take_snapshot()
                    
                    # Calculate metrics
                    execution_time = (datetime.now() - start_time).total_seconds()
                    
                    # Store results
                    self.profiles[func_name] = {
                        'execution_time': execution_time,
                        'cpu_stats': pstats.Stats(profiler),
                        'memory_diff': snapshot2.compare_to(snapshot1, 'lineno')
                    }
                    
                    # Log if slow
                    if execution_time > 1.0:
                        logger.warning(f"{func_name} took {execution_time}s")
                        self.print_top_cpu_consumers(func_name)
            
            return wrapper
        return decorator
    
    def print_top_cpu_consumers(self, func_name: str, limit: int = 10):
        """Print top CPU consuming functions"""
        if func_name in self.profiles:
            stats = self.profiles[func_name]['cpu_stats']
            stats.sort_stats('cumulative')
            stats.print_stats(limit)
```

**Solution:**
```python
# Optimize agent performance
class OptimizedAgent(BaseAgent):
    """Performance-optimized agent"""
    
    def __init__(self):
        super().__init__()
        
        # Use connection pooling
        self.db_pool = asyncpg.create_pool(
            dsn=os.getenv('DATABASE_URL'),
            min_size=10,
            max_size=20
        )
        
        # Cache frequently accessed data
        self.cache = TTLCache(maxsize=1000, ttl=300)  # 5 min TTL
        
        # Batch operations
        self.batch_queue = []
        self.batch_size = 100
        self.batch_interval = 5.0  # seconds
        
        # Start batch processor
        asyncio.create_task(self.batch_processor())
    
    async def get_data(self, key: str) -> Any:
        """Get data with caching"""
        
        # Check cache first
        if key in self.cache:
            return self.cache[key]
        
        # Get from database
        async with self.db_pool.acquire() as conn:
            result = await conn.fetchone(
                "SELECT data FROM cache WHERE key = $1",
                key
            )
        
        if result:
            self.cache[key] = result['data']
            return result['data']
        
        return None
    
    async def process_event(self, event: Event):
        """Process events in batches"""
        
        # Add to batch queue
        self.batch_queue.append(event)
        
        # Process immediately if batch is full
        if len(self.batch_queue) >= self.batch_size:
            await self.process_batch()
    
    async def batch_processor(self):
        """Background batch processor"""
        
        while True:
            await asyncio.sleep(self.batch_interval)
            
            if self.batch_queue:
                await self.process_batch()
    
    async def process_batch(self):
        """Process batched events"""
        
        if not self.batch_queue:
            return
        
        # Get current batch
        batch = self.batch_queue[:self.batch_size]
        self.batch_queue = self.batch_queue[self.batch_size:]
        
        # Process in parallel
        tasks = [self.process_single_event(event) for event in batch]
        await asyncio.gather(*tasks, return_exceptions=True)
```

### 7. Multi-Agent Coordination Issues

#### Issue: Agent Deadlocks
**Symptoms:**
- Agents waiting for each other
- No progress in workflows
- Circular dependencies

**Solution:**
```python
# Implement deadlock detection and resolution
class DeadlockDetector:
    """Detect and resolve agent deadlocks"""
    
    def __init__(self):
        self.agent_states = {}
        self.wait_graph = {}  # agent -> waiting_for_agent
        
    async def update_agent_state(self, agent_id: str, state: Dict[str, Any]):
        """Update agent state and check for deadlocks"""
        
        self.agent_states[agent_id] = state
        
        # Update wait graph
        if state.get('waiting_for'):
            self.wait_graph[agent_id] = state['waiting_for']
        else:
            self.wait_graph.pop(agent_id, None)
        
        # Check for cycles (deadlocks)
        if cycle := self.detect_cycle():
            await self.resolve_deadlock(cycle)
    
    def detect_cycle(self) -> Optional[List[str]]:
        """Detect cycles in wait graph"""
        
        visited = set()
        rec_stack = set()
        
        def has_cycle_util(node, path):
            visited.add(node)
            rec_stack.add(node)
            path.append(node)
            
            if node in self.wait_graph:
                neighbor = self.wait_graph[node]
                if neighbor not in visited:
                    if has_cycle_util(neighbor, path):
                        return True
                elif neighbor in rec_stack:
                    # Found cycle
                    cycle_start = path.index(neighbor)
                    return path[cycle_start:]
            
            path.pop()
            rec_stack.remove(node)
            return False
        
        for node in self.wait_graph:
            if node not in visited:
                path = []
                cycle = has_cycle_util(node, path)
                if cycle:
                    return cycle
        
        return None
    
    async def resolve_deadlock(self, cycle: List[str]):
        """Resolve detected deadlock"""
        
        logger.warning(f"Deadlock detected: {' -> '.join(cycle)}")
        
        # Choose victim (agent with least work done)
        victim = min(cycle, key=lambda a: self.agent_states[a].get('work_done', 0))
        
        # Send abort signal to victim
        await self.send_abort_signal(victim)
        
        # Clear its dependencies
        self.wait_graph.pop(victim, None)
        
        logger.info(f"Resolved deadlock by aborting {victim}")
```

## 🛠️ Diagnostic Tools

### Agent Health Monitor
```python
#!/usr/bin/env python3
"""Monitor agent health and performance"""

import asyncio
import aiohttp
from datetime import datetime
from rich.console import Console
from rich.table import Table
from rich.live import Live

console = Console()

class AgentMonitor:
    def __init__(self, agent_endpoints: List[str]):
        self.endpoints = agent_endpoints
        self.session = None
    
    async def __aenter__(self):
        self.session = aiohttp.ClientSession()
        return self
    
    async def __aexit__(self, *args):
        await self.session.close()
    
    async def check_agent_health(self, endpoint: str) -> Dict[str, Any]:
        """Check health of single agent"""
        try:
            async with self.session.get(f"{endpoint}/health", timeout=5) as resp:
                if resp.status == 200:
                    data = await resp.json()
                    return {
                        'status': 'healthy',
                        'response_time': resp.headers.get('X-Response-Time', 'N/A'),
                        **data
                    }
                else:
                    return {'status': 'unhealthy', 'error': f'HTTP {resp.status}'}
        except asyncio.TimeoutError:
            return {'status': 'timeout', 'error': 'Request timed out'}
        except Exception as e:
            return {'status': 'error', 'error': str(e)}
    
    async def monitor_agents(self):
        """Monitor all agents continuously"""
        
        with Live(console=console, refresh_per_second=1) as live:
            while True:
                table = Table(title=f"Agent Health Monitor - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
                table.add_column("Agent", style="cyan")
                table.add_column("Status", style="green")
                table.add_column("Response Time", style="yellow")
                table.add_column("Tasks Processed", style="blue")
                table.add_column("Errors", style="red")
                table.add_column("Memory", style="magenta")
                
                # Check all agents
                tasks = [self.check_agent_health(ep) for ep in self.endpoints]
                results = await asyncio.gather(*tasks)
                
                for endpoint, result in zip(self.endpoints, results):
                    agent_name = endpoint.split('/')[-1]
                    
                    status_style = "green" if result['status'] == 'healthy' else "red"
                    
                    table.add_row(
                        agent_name,
                        f"[{status_style}]{result['status']}[/{status_style}]",
                        result.get('response_time', 'N/A'),
                        str(result.get('tasks_processed', 0)),
                        str(result.get('error_count', 0)),
                        result.get('memory_usage', 'N/A')
                    )
                
                live.update(table)
                await asyncio.sleep(5)

# Usage
async def main():
    endpoints = [
        "http://localhost:8001",  # CI Agent
        "http://localhost:8002",  # Security Agent
        "http://localhost:8003",  # Infra Agent
        "http://localhost:8004",  # Monitoring Agent
    ]
    
    async with AgentMonitor(endpoints) as monitor:
        await monitor.monitor_agents()

if __name__ == "__main__":
    asyncio.run(main())
```

### Log Aggregation and Analysis
```python
class LogAnalyzer:
    """Analyze aggregated logs for issues"""
    
    def __init__(self, log_sources: List[str]):
        self.log_sources = log_sources
        self.error_patterns = [
            (r'ERROR.*timeout', 'timeout_errors'),
            (r'ERROR.*connection refused', 'connection_errors'),
            (r'ERROR.*out of memory', 'memory_errors'),
            (r'CRITICAL', 'critical_errors'),
            (r'Rate limit', 'rate_limit_errors')
        ]
    
    async def analyze_recent_logs(self, minutes: int = 5) -> Dict[str, Any]:
        """Analyze recent logs for patterns"""
        
        analysis = {
            'total_errors': 0,
            'error_types': {},
            'error_timeline': [],
            'top_errors': []
        }
        
        # Collect logs from all sources
        all_logs = []
        for source in self.log_sources:
            logs = await self.fetch_logs(source, minutes)
            all_logs.extend(logs)
        
        # Analyze patterns
        for log in all_logs:
            for pattern, error_type in self.error_patterns:
                if re.search(pattern, log['message']):
                    analysis['error_types'][error_type] = analysis['error_types'].get(error_type, 0) + 1
                    analysis['total_errors'] += 1
                    
                    analysis['error_timeline'].append({
                        'timestamp': log['timestamp'],
                        'type': error_type,
                        'message': log['message'][:100]
                    })
        
        # Find top errors
        if analysis['error_types']:
            analysis['top_errors'] = sorted(
                analysis['error_types'].items(),
                key=lambda x: x[1],
                reverse=True
            )[:5]
        
        return analysis
```

## 📊 Performance Monitoring

### Real-time Metrics Dashboard
```python
# Create Grafana dashboard configuration
dashboard_config = {
    "dashboard": {
        "title": "Agentic DevOps Monitoring",
        "panels": [
            {
                "title": "Agent Task Processing Rate",
                "targets": [{
                    "expr": "rate(agent_tasks_processed_total[5m])",
                    "legendFormat": "{{agent_name}}"
                }],
                "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
            },
            {
                "title": "Agent Error Rate",
                "targets": [{
                    "expr": "rate(agent_errors_total[5m])",
                    "legendFormat": "{{agent_name}}"
                }],
                "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
            },
            {
                "title": "Pipeline Success Rate",
                "targets": [{
                    "expr": "rate(pipeline_success_total[1h]) / rate(pipeline_total[1h])",
                    "legendFormat": "Success Rate"
                }],
                "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8}
            },
            {
                "title": "Security Scan Findings",
                "targets": [{
                    "expr": "security_findings_total",
                    "legendFormat": "{{severity}}"
                }],
                "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8}
            }
        ]
    }
}
```

## 🆘 Emergency Procedures

### 1. Complete System Recovery
```bash
#!/bin/bash
# Emergency recovery script

echo "🚨 EMERGENCY RECOVERY PROCEDURE"
echo "This will restart all agents and clear queues"
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Recovery cancelled"
    exit 1
fi

# 1. Stop all agents
kubectl delete pods -n agentic-devops --all

# 2. Clear message queues
docker exec nats nats-streaming-server -sl -sc

# 3. Reset Redis state
redis-cli FLUSHDB

# 4. Restart infrastructure
kubectl apply -f infrastructure/kubernetes/

# 5. Wait for pods to be ready
kubectl wait --for=condition=ready pod -n agentic-devops --all --timeout=300s

# 6. Run health checks
./scripts/health-check.sh

echo "✅ Recovery complete"
```

### 2. Agent Debug Mode
```python
# Enable debug mode for specific agent
class DebugAgent(BaseAgent):
    """Agent with debug capabilities"""
    
    def __init__(self, debug_mode: bool = False):
        super().__init__()
        self.debug_mode = debug_mode
        
        if debug_mode:
            # Enable detailed logging
            logging.getLogger().setLevel(logging.DEBUG)
            
            # Enable profiling
            self.profiler = cProfile.Profile()
            self.profiler.enable()
            
            # Enable trace collection
            self.trace_collector = TraceCollector()
    
    async def execute_task(self, task: Task):
        """Execute with debug instrumentation"""
        
        if self.debug_mode:
            # Log task details
            logger.debug(f"Task received: {json.dumps(task.to_dict(), indent=2)}")
            
            # Create trace
            trace_id = self.trace_collector.start_trace(task.id)
            
            try:
                # Execute with timing
                start = time.time()
                result = await super().execute_task(task)
                duration = time.time() - start
                
                # Log result
                logger.debug(f"Task completed in {duration}s: {result}")
                
                # Save trace
                self.trace_collector.end_trace(trace_id, result)
                
                return result
                
            except Exception as e:
                # Log full stack trace
                logger.exception(f"Task failed: {task.id}")
                self.trace_collector.error_trace(trace_id, e)
                raise
        else:
            return await super().execute_task(task)
```

## ✅ Troubleshooting Checklist

When issues occur:

- [ ] Check all service health endpoints
- [ ] Verify network connectivity between services
- [ ] Check resource utilization (CPU, memory, disk)
- [ ] Review recent configuration changes
- [ ] Analyze error logs for patterns
- [ ] Verify API keys and credentials
- [ ] Check rate limits and quotas
- [ ] Test with minimal example
- [ ] Enable debug mode if needed
- [ ] Document issue and resolution

## 📚 Additional Resources

### Useful Commands
```bash
# View all agent logs
kubectl logs -n agentic-devops -l app=agent --tail=100 -f

# Check resource usage
kubectl top pods -n agentic-devops

# Port forward for debugging
kubectl port-forward -n agentic-devops svc/agent-orchestrator 8000:8000

# Execute commands in pod
kubectl exec -it -n agentic-devops <pod-name> -- /bin/bash

# View agent configuration
kubectl get configmap -n agentic-devops agent-config -o yaml
```

### Debug Environment Variables
```bash
# Enable verbose logging
export AGENT_LOG_LEVEL=DEBUG
export PYTHONDEBUG=1

# Enable profiling
export AGENT_ENABLE_PROFILING=true
export AGENT_PROFILE_OUTPUT=/tmp/agent_profile

# Disable SSL verification (dev only)
export PYTHONHTTPSVERIFY=0
```

---

**Remember**: When troubleshooting Agentic DevOps, always check the basics first - connectivity, resources, and logs. Most issues stem from configuration or resource constraints rather than code bugs.