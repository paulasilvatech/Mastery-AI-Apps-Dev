# Troubleshooting Multi-Agent Orchestration

## 🔍 Overview

This guide helps diagnose and resolve common issues in multi-agent orchestration systems. Each issue includes symptoms, root causes, diagnostic steps, and solutions.

## 🚨 Common Issues

### 1. Agents Not Starting

#### Symptoms
```
- Agents show as "offline" in orchestrator
- No heartbeat received from agents
- Task assignment failures
- Empty agent registry
```

#### Diagnostic Steps
```bash
# Check agent logs
docker logs agent-container-name

# Verify agent process
ps aux | grep agent

# Check network connectivity
curl http://localhost:agent-port/health

# Verify Redis connection
redis-cli ping

# Check message bus
rabbitmqctl list_queues
```

#### Common Causes & Solutions

**1. Connection Issues**
```typescript
// Problem: Agent can't connect to Redis
Error: connect ECONNREFUSED 127.0.0.1:6379

// Solution: Check Redis configuration
const redis = new Redis({
  host: process.env.REDIS_HOST || 'localhost',
  port: process.env.REDIS_PORT || 6379,
  retryStrategy: (times) => {
    const delay = Math.min(times * 50, 2000);
    return delay;
  }
});
```

**2. Authentication Failures**
```typescript
// Problem: Invalid agent credentials
Error: Agent authentication failed

// Solution: Verify agent registration
const agent = new Agent({
  id: process.env.AGENT_ID,
  token: process.env.AGENT_TOKEN,
  capabilities: ['research', 'analysis']
});

await orchestrator.registerAgent(agent);
```

**3. Port Conflicts**
```bash
# Problem: Address already in use
Error: listen EADDRINUSE: address already in use :::4000

# Solution: Find and kill process using port
lsof -i :4000
kill -9 <PID>

# Or use different port
AGENT_PORT=4001 npm start
```

### 2. Tasks Stuck in Queue

#### Symptoms
```
- Tasks remain in "pending" state
- Queue depth continuously increasing
- No task completion events
- Agent utilization at 0%
```

#### Diagnostic Steps
```typescript
// Check queue status
const queueStats = await orchestrator.getQueueStats();
console.log('Queue depth:', queueStats.waiting);
console.log('Active tasks:', queueStats.active);
console.log('Failed tasks:', queueStats.failed);

// Inspect stuck tasks
const stuckTasks = await queue.getWaiting();
stuckTasks.forEach(job => {
  console.log('Task:', job.id, 'Data:', job.data);
});
```

#### Solutions

**1. Dead Letter Queue Processing**
```typescript
// Move failed tasks to DLQ
const failed = await queue.getFailed();
for (const job of failed) {
  if (job.attemptsMade >= 3) {
    await deadLetterQueue.add(job.data);
    await job.remove();
  }
}
```

**2. Queue Consumer Not Running**
```typescript
// Ensure queue processor is started
queue.process(async (job) => {
  try {
    return await processTask(job.data);
  } catch (error) {
    console.error('Task processing error:', error);
    throw error; // Let Bull handle retry
  }
});

// Add error handler
queue.on('error', (error) => {
  console.error('Queue error:', error);
});
```

**3. Task Timeout**
```typescript
// Configure appropriate timeouts
queue.process({
  concurrency: 5,
  timeout: 30000 // 30 seconds
}, async (job) => {
  return await processTask(job.data);
});
```

### 3. Agent Communication Failures

#### Symptoms
```
- "No route to agent" errors
- Message timeout errors
- Inconsistent task results
- Missing acknowledgments
```

#### Diagnostic Network Issues
```bash
# Test agent connectivity
curl -X POST http://agent-host:port/health

# Check DNS resolution
nslookup agent-service

# Verify network policies (Kubernetes)
kubectl describe networkpolicy

# Monitor network traffic
tcpdump -i any port 4000
```

#### Solutions

**1. Message Bus Configuration**
```typescript
// Configure robust message bus
const messageBus = new MessageBus({
  redis: {
    host: process.env.REDIS_HOST,
    port: process.env.REDIS_PORT,
    retryStrategy: (times) => Math.min(times * 100, 3000),
    enableOfflineQueue: true,
    maxRetriesPerRequest: 3
  }
});

// Add connection error handling
messageBus.on('error', (error) => {
  console.error('Message bus error:', error);
  // Implement fallback mechanism
});
```

**2. Service Discovery Issues**
```typescript
// Implement service registry
class ServiceRegistry {
  async registerAgent(agent: Agent) {
    await this.redis.setex(
      `agent:${agent.id}`,
      300, // 5 minute TTL
      JSON.stringify({
        id: agent.id,
        host: agent.host,
        port: agent.port,
        capabilities: agent.capabilities
      })
    );
  }
  
  async discoverAgent(capability: string): Promise<Agent[]> {
    const keys = await this.redis.keys('agent:*');
    const agents = [];
    
    for (const key of keys) {
      const data = await this.redis.get(key);
      if (data) {
        const agent = JSON.parse(data);
        if (agent.capabilities.includes(capability)) {
          agents.push(agent);
        }
      }
    }
    
    return agents;
  }
}
```

### 4. State Synchronization Issues

#### Symptoms
```
- Inconsistent workflow state
- Lost task results
- Duplicate task execution
- Race conditions
```

#### Diagnostic Steps
```typescript
// Check state consistency
async function validateWorkflowState(workflowId: string) {
  const orchestratorState = await orchestrator.getWorkflowState(workflowId);
  const storeState = await stateStore.get(workflowId);
  
  if (JSON.stringify(orchestratorState) !== JSON.stringify(storeState)) {
    console.error('State mismatch detected!');
    console.log('Orchestrator:', orchestratorState);
    console.log('Store:', storeState);
  }
}

// Monitor state changes
stateStore.on('change', (key, newValue, oldValue) => {
  console.log(`State change: ${key}`);
  console.log('Old:', oldValue);
  console.log('New:', newValue);
});
```

#### Solutions

**1. Implement Distributed Locking**
```typescript
class DistributedLock {
  async acquire(key: string, ttl: number = 5000): Promise<boolean> {
    const lockKey = `lock:${key}`;
    const lockId = uuidv4();
    
    // Try to acquire lock
    const result = await this.redis.set(
      lockKey,
      lockId,
      'PX', ttl,
      'NX'
    );
    
    if (result === 'OK') {
      return lockId;
    }
    
    return null;
  }
  
  async release(key: string, lockId: string): Promise<void> {
    const lockKey = `lock:${key}`;
    
    // Lua script for atomic check and delete
    const script = `
      if redis.call("get", KEYS[1]) == ARGV[1] then
        return redis.call("del", KEYS[1])
      else
        return 0
      end
    `;
    
    await this.redis.eval(script, 1, lockKey, lockId);
  }
}

// Use lock for state updates
async function updateWorkflowState(workflowId: string, update: any) {
  const lock = await distributedLock.acquire(`workflow:${workflowId}`);
  
  if (!lock) {
    throw new Error('Failed to acquire lock');
  }
  
  try {
    const currentState = await stateStore.get(workflowId);
    const newState = { ...currentState, ...update };
    await stateStore.set(workflowId, newState);
  } finally {
    await distributedLock.release(`workflow:${workflowId}`, lock);
  }
}
```

**2. Implement Optimistic Locking**
```typescript
interface VersionedState {
  data: any;
  version: number;
  lastModified: Date;
}

class OptimisticStateStore {
  async update(key: string, updater: (state: any) => any): Promise<void> {
    let retries = 0;
    const maxRetries = 3;
    
    while (retries < maxRetries) {
      // Get current state with version
      const current = await this.get(key) as VersionedState;
      
      // Apply update
      const updated = {
        data: updater(current.data),
        version: current.version + 1,
        lastModified: new Date()
      };
      
      // Try to save with version check
      const saved = await this.compareAndSet(key, updated, current.version);
      
      if (saved) {
        return;
      }
      
      // Version conflict, retry
      retries++;
      await new Promise(resolve => setTimeout(resolve, 100 * retries));
    }
    
    throw new Error('Failed to update state after retries');
  }
}
```

### 5. Performance Issues

#### Symptoms
```
- High latency in task execution
- CPU/Memory spikes
- Slow workflow completion
- Timeout errors
```

#### Performance Diagnostics
```typescript
// Profile task execution
class PerformanceProfiler {
  async profileTask(taskId: string, executor: () => Promise<any>) {
    const startTime = process.hrtime.bigint();
    const startMemory = process.memoryUsage();
    
    try {
      const result = await executor();
      
      const endTime = process.hrtime.bigint();
      const endMemory = process.memoryUsage();
      
      const profile = {
        taskId,
        duration: Number(endTime - startTime) / 1e6, // ms
        memoryDelta: {
          heapUsed: endMemory.heapUsed - startMemory.heapUsed,
          external: endMemory.external - startMemory.external
        }
      };
      
      // Log slow tasks
      if (profile.duration > 1000) {
        console.warn('Slow task detected:', profile);
      }
      
      return result;
    } catch (error) {
      throw error;
    }
  }
}
```

#### Performance Solutions

**1. Implement Caching**
```typescript
class CachedAgent extends BaseAgent {
  private cache = new LRUCache<string, any>({
    max: 1000,
    ttl: 1000 * 60 * 5 // 5 minutes
  });
  
  async execute(task: Task) {
    const cacheKey = this.getCacheKey(task);
    
    // Check cache
    const cached = this.cache.get(cacheKey);
    if (cached) {
      this.metrics.increment('cache.hits');
      return cached;
    }
    
    // Execute task
    const result = await super.execute(task);
    
    // Cache result
    this.cache.set(cacheKey, result);
    this.metrics.increment('cache.misses');
    
    return result;
  }
}
```

**2. Optimize Task Distribution**
```typescript
class LoadBalancedOrchestrator {
  async assignTask(task: Task): Promise<Agent> {
    // Get agents with required capability
    const agents = await this.getAgentsByCapability(task.type);
    
    // Sort by current load
    const sorted = agents.sort((a, b) => {
      const loadA = a.currentLoad / a.maxLoad;
      const loadB = b.currentLoad / b.maxLoad;
      return loadA - loadB;
    });
    
    // Select least loaded agent
    const selected = sorted[0];
    
    if (!selected || selected.currentLoad >= selected.maxLoad) {
      throw new Error('No available agents');
    }
    
    return selected;
  }
}
```

### 6. Memory Leaks

#### Symptoms
```
- Gradually increasing memory usage
- Out of memory errors
- Performance degradation over time
- Process crashes
```

#### Memory Leak Detection
```typescript
// Monitor memory usage
class MemoryMonitor {
  private baseline?: NodeJS.MemoryUsage;
  private samples: NodeJS.MemoryUsage[] = [];
  
  startMonitoring() {
    this.baseline = process.memoryUsage();
    
    setInterval(() => {
      const usage = process.memoryUsage();
      this.samples.push(usage);
      
      // Keep last 100 samples
      if (this.samples.length > 100) {
        this.samples.shift();
      }
      
      // Check for leak indicators
      if (this.detectLeak()) {
        console.warn('Potential memory leak detected!');
        this.dumpHeapSnapshot();
      }
    }, 60000); // Every minute
  }
  
  detectLeak(): boolean {
    if (this.samples.length < 10) return false;
    
    // Calculate trend
    const recent = this.samples.slice(-10);
    const avgGrowth = recent.reduce((sum, sample, i) => {
      if (i === 0) return 0;
      return sum + (sample.heapUsed - recent[i-1].heapUsed);
    }, 0) / 9;
    
    // Alert if consistent growth
    return avgGrowth > 1024 * 1024; // 1MB per minute
  }
}
```

#### Memory Leak Solutions

**1. Clean Up Event Listeners**
```typescript
class CleanableAgent extends BaseAgent {
  private listeners: Array<{
    emitter: EventEmitter;
    event: string;
    handler: Function;
  }> = [];
  
  on(emitter: EventEmitter, event: string, handler: Function) {
    emitter.on(event, handler);
    this.listeners.push({ emitter, event, handler });
  }
  
  async cleanup() {
    // Remove all listeners
    for (const { emitter, event, handler } of this.listeners) {
      emitter.removeListener(event, handler);
    }
    this.listeners = [];
    
    // Clear other resources
    this.activeTasks.clear();
    this.cache?.clear();
  }
}
```

**2. Limit Queue Size**
```typescript
// Configure queue with limits
const queue = new Bull('tasks', {
  redis: redisConfig,
  defaultJobOptions: {
    removeOnComplete: true,
    removeOnFail: {
      age: 24 * 3600 // 24 hours
    }
  }
});

// Periodically clean old jobs
setInterval(async () => {
  await queue.clean(
    3600 * 1000, // Grace period
    'completed'
  );
  await queue.clean(
    3600 * 1000,
    'failed'
  );
}, 3600 * 1000); // Every hour
```

## 🛠️ Diagnostic Tools

### 1. Health Check Endpoint
```typescript
app.get('/health', async (req, res) => {
  const health = {
    status: 'healthy',
    timestamp: new Date(),
    checks: {}
  };
  
  // Check Redis
  try {
    await redis.ping();
    health.checks.redis = 'ok';
  } catch (error) {
    health.status = 'unhealthy';
    health.checks.redis = 'failed';
  }
  
  // Check message bus
  try {
    const stats = await messageBus.getStats();
    health.checks.messageBus = stats;
  } catch (error) {
    health.status = 'unhealthy';
    health.checks.messageBus = 'failed';
  }
  
  // Check agents
  const agents = await orchestrator.getAgents();
  health.checks.agents = {
    total: agents.length,
    healthy: agents.filter(a => a.status === 'healthy').length
  };
  
  res.status(health.status === 'healthy' ? 200 : 503).json(health);
});
```

### 2. Debug Mode
```typescript
class DebugOrchestrator extends Orchestrator {
  constructor(config: OrchestratorConfig) {
    super({
      ...config,
      debug: process.env.DEBUG === 'true'
    });
    
    if (this.config.debug) {
      this.enableDebugLogging();
      this.enableDebugEndpoints();
    }
  }
  
  private enableDebugLogging() {
    this.on('*', (event, data) => {
      console.debug(`[DEBUG] Event: ${event}`, data);
    });
    
    // Log all state changes
    this.stateStore.on('change', (key, value) => {
      console.debug(`[DEBUG] State change: ${key}`, value);
    });
  }
  
  private enableDebugEndpoints() {
    this.app.get('/debug/state/:id', async (req, res) => {
      const state = await this.getCompleteState(req.params.id);
      res.json(state);
    });
    
    this.app.get('/debug/metrics', async (req, res) => {
      const metrics = await this.collectAllMetrics();
      res.json(metrics);
    });
  }
}
```

### 3. Performance Profiling
```bash
# CPU profiling
node --inspect-brk=0.0.0.0:9229 dist/orchestrator.js

# Memory profiling
node --expose-gc --max-old-space-size=4096 dist/orchestrator.js

# Heap snapshot
kill -USR2 <PID>

# Flame graphs
0x -o dist/orchestrator.js
```

## 📊 Monitoring Queries

### Prometheus Queries
```promql
# Agent availability
(up{job="agents"} == 1) / count(up{job="agents"})

# Task processing rate
rate(agent_tasks_processed_total[5m])

# Queue depth
queue_depth{queue="tasks"}

# Error rate
rate(workflow_errors_total[5m]) / rate(workflow_total[5m])

# P95 latency
histogram_quantile(0.95, rate(task_duration_seconds_bucket[5m]))
```

### Log Queries (Elasticsearch)
```json
// Find failed workflows
{
  "query": {
    "bool": {
      "must": [
        { "match": { "level": "error" }},
        { "match": { "component": "orchestrator" }},
        { "range": { "@timestamp": { "gte": "now-1h" }}}
      ]
    }
  }
}

// Trace specific workflow
{
  "query": {
    "match": { "workflowId": "workflow-123" }
  },
  "sort": [{ "@timestamp": "asc" }]
}
```

## 🚑 Emergency Procedures

### 1. Complete System Failure
```bash
# 1. Check infrastructure
kubectl get pods -n orchestration
kubectl describe pod <failing-pod>

# 2. Check dependencies
redis-cli ping
curl http://rabbitmq:15672/api/overview

# 3. Restart in order
kubectl rollout restart deployment/redis
kubectl rollout restart deployment/rabbitmq
kubectl rollout restart deployment/orchestrator
kubectl rollout restart deployment/agents

# 4. Verify recovery
./scripts/health-check.sh
```

### 2. Data Recovery
```bash
# Backup current state
redis-cli --rdb dump.rdb

# Export critical data
redis-cli --scan --pattern "workflow:*" > workflows.txt
redis-cli --scan --pattern "state:*" > states.txt

# Restore from backup
redis-cli --pipe < backup.txt
```

### 3. Emergency Shutdown
```typescript
class EmergencyShutdown {
  async execute(reason: string) {
    console.error(`EMERGENCY SHUTDOWN: ${reason}`);
    
    // 1. Stop accepting new work
    await this.orchestrator.pause();
    
    // 2. Save current state
    await this.saveEmergencySnapshot();
    
    // 3. Gracefully stop agents
    await this.orchestrator.stopAllAgents(30000); // 30s timeout
    
    // 4. Flush queues to persistent storage
    await this.flushQueues();
    
    // 5. Shutdown
    process.exit(1);
  }
}
```

## 📞 Getting Help

### Collect Diagnostic Information
```bash
# Generate diagnostic bundle
./scripts/collect-diagnostics.sh

# This collects:
# - System information
# - Container logs
# - Configuration files
# - Recent metrics
# - Error logs
# - Heap dumps (if available)
```

### Debug Checklist
- [ ] Check all logs (orchestrator, agents, infrastructure)
- [ ] Verify network connectivity
- [ ] Check resource usage (CPU, memory, disk)
- [ ] Review recent changes
- [ ] Test with minimal configuration
- [ ] Isolate failing component
- [ ] Reproduce in test environment

---

Remember: Most issues are configuration or connectivity related. Always check the basics first!