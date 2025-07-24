---
sidebar_position: 5
title: "Exercise 1: Part 1"
description: "## 🎯 Objective"
---

# Ejercicio 1: ReBuscar Assistant System (⭐ Fácil - 30 minutos)

## 🎯 Objective
Build a multi-agent research system where specialized agents collaborate to gather information, analyze data, synthesize findings, and generate comprehensive research reports.

## 🧠 Lo Que Aprenderás
- Agent specialization and role definition
- Inter-agent communication patterns
- Task distribution and coordination
- Result aggregation strategies
- Workflow orchestration basics

## 📋 Prerrequisitos
- Basic understanding of agent architectures
- Familiarity with async programming
- Knowledge of pub/sub patterns
- Understanding of research workflows

## 📚 Atrásground

A Research Assistant System demonstrates how multiple specialized agents can work together more effectively than a single general-purpose agent. The system includes:

- **Research Agent**: Gathers information from various sources
- **Analysis Agent**: Processes and analyzes collected data
- **Synthesis Agent**: Combines findings into coherent insights
- **Writer Agent**: Produces well-structured reports

Each agent has specific capabilities and communicates through a central orchestrator.

## 🏗️ Architecture Resumen

```mermaid
graph TB
    subgraph "Research Assistant System"
        A[Research Orchestrator] --&gt; B[Task Queue]
        
        B --&gt; C[Research Agent]
        B --&gt; D[Analysis Agent]
        B --&gt; E[Synthesis Agent]
        B --&gt; F[Writer Agent]
        
        C --&gt; G[Data Store]
        D --&gt; G
        E --&gt; G
        F --&gt; G
        
        H[Event Bus] --&gt; C
        H --&gt; D
        H --&gt; E
        H --&gt; F
        
        I[State Manager] --&gt; A
        I --&gt; G
    end
    
    J[User Request] --&gt; A
    F --&gt; K[Research Report]
    
    style A fill:#4CAF50
    style B fill:#2196F3
    style G fill:#FF9800
    style I fill:#9C27B0
```

## 🛠️ Step-by-Step Instructions

### Step 1: Project Setup

**Copilot Prompt Suggestion:**
```typescript
// Create a TypeScript project for a multi-agent research system that:
// - Has specialized agents for research, analysis, synthesis, and writing
// - Uses a central orchestrator to coordinate agent activities
// - Implements pub/sub for inter-agent communication
// - Manages shared state across agents
// - Includes task queuing and distribution
// - Has comprehensive error handling and monitoring
```

1. **Initialize the project:**
```bash
mkdir research-assistant-system
cd research-assistant-system
npm init -y
```

2. **Install dependencies:**
```bash
# Core dependencies
npm install \
  eventemitter3 \
  bull \
  ioredis \
  uuid \
  axios \
  cheerio

# AI/LLM dependencies
npm install \
  @azure/openai \
  @anthropic-ai/sdk \
  langchain

# Utility dependencies
npm install \
  winston \
  dotenv \
  joi \
  lodash \
  p-queue

# Development dependencies
npm install --save-dev \
  typescript \
  @types/node \
  @types/bull \
  @types/lodash \
  ts-node \
  nodemon \
  jest \
  @types/jest
```

3. **Create directory structure:**
```bash
mkdir -p src/{agents,orchestrator,communication,state,utils}
mkdir -p tests/{unit,integration}
mkdir -p config
```

### Step 2: Define Agent Base Class

**Copilot Prompt Suggestion:**
```typescript
// Create a base agent class that:
// - Has a unique ID and name
// - Defines agent capabilities and role
// - Implements message handling
// - Supports async task execution
// - Includes health checking
// - Has built-in error handling and retry logic
```

Create `src/agents/BaseAgent.ts`:
```typescript
import { EventEmitter } from 'eventemitter3';
import { v4 as uuidv4 } from 'uuid';
import winston from 'winston';

export interface AgentConfig {
  name: string;
  capabilities: string[];
  maxConcurrentTasks?: number;
  timeout?: number;
  retryAttempts?: number;
}

export interface Task {
  id: string;
  type: string;
  payload: any;
  priority?: number;
  deadline?: Date;
  dependencies?: string[];
}

export interface TaskResult {
  taskId: string;
  agentId: string;
  status: 'success' | 'failure' | 'partial';
  result?: any;
  error?: string;
  executionTime: number;
  timestamp: Date;
}

export abstract class BaseAgent extends EventEmitter {
  public readonly id: string;
  public readonly name: string;
  public readonly capabilities: string[];
  protected config: AgentConfig;
  protected logger: winston.Logger;
  protected activeTasks: Map<string, Task> = new Map();
  protected isRunning: boolean = false;
  protected health: {
    status: 'healthy' | 'degraded' | 'unhealthy';
    lastCheck: Date;
    metrics: {
      tasksCompleted: number;
      tasksFailed: number;
      averageExecutionTime: number;
    };
  };

  constructor(config: AgentConfig) {
    super();
    
    this.id = uuidv4();
    this.name = config.name;
    this.capabilities = config.capabilities;
    this.config = {
      maxConcurrentTasks: 5,
      timeout: 30000,
      retryAttempts: 3,
      ...config
    };
    
    this.logger = this.setupLogger();
    this.health = {
      status: 'healthy',
      lastCheck: new Date(),
      metrics: {
        tasksCompleted: 0,
        tasksFailed: 0,
        averageExecutionTime: 0
      }
    };
    
    this.setupHealthCheck();
  }

  private setupLogger(): winston.Logger {
    return winston.createLogger({
      level: 'info',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
      ),
      defaultMeta: { 
        agentId: this.id, 
        agentName: this.name 
      },
      transports: [
        new winston.transports.Console({
          format: winston.format.simple()
        })
      ]
    });
  }

  private setupHealthCheck(): void {
    setInterval(() =&gt; {
      this.checkHealth();
    }, 30000); // Check every 30 seconds
  }

  private checkHealth(): void {
    const failureRate = this.health.metrics.tasksFailed / 
      (this.health.metrics.tasksCompleted + this.health.metrics.tasksFailed || 1);
    
    if (failureRate &gt; 0.5) {
      this.health.status = 'unhealthy';
    } else if (failureRate &gt; 0.2) {
      this.health.status = 'degraded';
    } else {
      this.health.status = 'healthy';
    }
    
    this.health.lastCheck = new Date();
    
    this.emit('health-update', {
      agentId: this.id,
      health: this.health
    });
  }

  async start(): Promise<void> {
    if (this.isRunning) {
      throw new Error(`Agent ${this.name} is already running`);
    }
    
    this.isRunning = true;
    this.logger.info(`Agent ${this.name} started`);
    
    this.emit('agent-started', {
      agentId: this.id,
      name: this.name,
      capabilities: this.capabilities
    });
  }

  async stop(): Promise<void> {
    this.isRunning = false;
    
    // Wait for active tasks to complete
    const timeout = setTimeout(() =&gt; {
      this.logger.warn('Forcing agent shutdown due to timeout');
    }, 10000);
    
    while (this.activeTasks.size &gt; 0) {
      await new Promise(resolve =&gt; setTimeout(resolve, 100));
    }
    
    clearTimeout(timeout);
    
    this.logger.info(`Agent ${this.name} stopped`);
    this.emit('agent-stopped', { agentId: this.id });
  }

  canHandle(taskType: string): boolean {
    return this.capabilities.includes(taskType) || 
           this.capabilities.includes('*');
  }

  async executeTask(task: Task): Promise<TaskResult> {
    if (!this.isRunning) {
      throw new Error(`Agent ${this.name} is not running`);
    }
    
    if (this.activeTasks.size &gt;= this.config.maxConcurrentTasks!) {
      throw new Error(`Agent ${this.name} at maximum capacity`);
    }
    
    if (!this.canHandle(task.type)) {
      throw new Error(`Agent ${this.name} cannot handle task type: ${task.type}`);
    }
    
    this.activeTasks.set(task.id, task);
    const startTime = Date.now();
    
    this.logger.info(`Executing task ${task.id}`, {
      taskType: task.type,
      priority: task.priority
    });
    
    this.emit('task-started', {
      agentId: this.id,
      taskId: task.id,
      taskType: task.type
    });
    
    try {
      // Execute with timeout
      const result = await this.executeWithTimeout(
        () =&gt; this.execute(task),
        this.config.timeout!
      );
      
      const executionTime = Date.now() - startTime;
      
      // Update metrics
      this.health.metrics.tasksCompleted++;
      this.health.metrics.averageExecutionTime = 
        (this.health.metrics.averageExecutionTime * 
         (this.health.metrics.tasksCompleted - 1) + executionTime) / 
        this.health.metrics.tasksCompleted;
      
      const taskResult: TaskResult = {
        taskId: task.id,
        agentId: this.id,
        status: 'success',
        result,
        executionTime,
        timestamp: new Date()
      };
      
      this.logger.info(`Task ${task.id} completed successfully`, {
        executionTime
      });
      
      this.emit('task-completed', taskResult);
      
      return taskResult;
      
    } catch (error: any) {
      const executionTime = Date.now() - startTime;
      
      // Update failure metrics
      this.health.metrics.tasksFailed++;
      
      const taskResult: TaskResult = {
        taskId: task.id,
        agentId: this.id,
        status: 'failure',
        error: error.message,
        executionTime,
        timestamp: new Date()
      };
      
      this.logger.error(`Task ${task.id} failed`, {
        error: error.message,
        executionTime
      });
      
      this.emit('task-failed', taskResult);
      
      return taskResult;
      
    } finally {
      this.activeTasks.delete(task.id);
    }
  }

  private async executeWithTimeout<T>(
    operation: () =&gt; Promise<T>,
    timeout: number
  ): Promise<T> {
    return Promise.race([
      operation(),
      new Promise<never>((_, reject) =&gt; 
        setTimeout(() =&gt; reject(new Error('Task timeout')), timeout)
      )
    ]);
  }

  protected abstract execute(task: Task): Promise<any>;

  getStatus(): {
    id: string;
    name: string;
    isRunning: boolean;
    activeTasks: number;
    health: typeof this.health;
  } {
    return {
      id: this.id,
      name: this.name,
      isRunning: this.isRunning,
      activeTasks: this.activeTasks.size,
      health: this.health
    };
  }
}
```

### Step 3: Implement ReBuscar Agent

**Copilot Prompt Suggestion:**
```typescript
// Create a research agent that:
// - Searches multiple sources (web, databases, APIs)
// - Validates and filters information
// - Extracts relevant data points
// - Handles rate limiting and retries
// - Caches results for efficiency
// - Provides source attribution
```

Create `src/agents/ResearchAgent.ts`:
```typescript
import { BaseAgent, Task } from './BaseAgent';
import axios from 'axios';
import * as cheerio from 'cheerio';
import { LRUCache } from 'lru-cache';

interface ResearchTask {
  query: string;
  sources?: string[];
  maxResults?: number;
  filters?: {
    dateRange?: { start: Date; end: Date };
    domains?: string[];
    types?: string[];
  };
}

interface ResearchResult {
  sources: Array<{
    title: string;
    url: string;
    snippet: string;
    relevanceScore: number;
    metadata: any;
  }>;
  summary: string;
  keywords: string[];
  timestamp: Date;
}

export class ResearchAgent extends BaseAgent {
  private cache: LRUCache<string, ResearchResult>;
  private rateLimiters: Map<string, { lastCall: number; minInterval: number }>;

  constructor() {
    super({
      name: 'ResearchAgent',
      capabilities: ['research', 'search', 'gather-info']
    });
    
    this.cache = new LRUCache<string, ResearchResult>({
      max: 100,
      ttl: 1000 * 60 * 60 // 1 hour cache
    });
    
    this.rateLimiters = new Map([
      ['web', { lastCall: 0, minInterval: 1000 }],
      ['api', { lastCall: 0, minInterval: 500 }]
    ]);
  }

  protected async execute(task: Task): Promise<ResearchResult> {
    const researchTask = task.payload as ResearchTask;
    
    // Check cache first
    const cacheKey = this.getCacheKey(researchTask);
    const cached = this.cache.get(cacheKey);
    if (cached) {
      this.logger.info('Returning cached research results', {
        taskId: task.id,
        query: researchTask.query
      });
      return cached;
    }
    
    // Perform research
    const sources = await this.gatherSources(researchTask);
    const filtered = await this.filterAndRank(sources, researchTask);
    const summary = await this.generateSummary(filtered);
    const keywords = this.extractKeywords(filtered);
    
    const result: ResearchResult = {
      sources: filtered,
      summary,
      keywords,
      timestamp: new Date()
    };
    
    // Cache result
    this.cache.set(cacheKey, result);
    
    return result;
  }

  private async gatherSources(task: ResearchTask): Promise<any[]> {
    const sources: any[] = [];
    
    // Simulate gathering from multiple sources
    const searchPromises = [
      this.searchWeb(task.query),
      this.searchAcademic(task.query),
      this.searchNews(task.query)
    ];
    
    const results = await Promise.allSettled(searchPromises);
    
    for (const result of results) {
      if (result.status === 'fulfilled') {
        sources.push(...result.value);
      } else {
        this.logger.warn('Source search failed', {
          error: result.reason
        });
      }
    }
    
    return sources;
  }

  private async searchWeb(query: string): Promise<any[]> {
    await this.enforceRateLimit('web');
    
    // Simulate web search (in production, use actual search API)
    return [
      {
        title: `Web result for: ${query}`,
        url: `https://example.com/search?q=${encodeURIComponent(query)}`,
        snippet: `This is a simulated web search result for "${query}"...`,
        source: 'web',
        relevanceScore: 0.85
      }
    ];
  }

  private async searchAcademic(query: string): Promise<any[]> {
    await this.enforceRateLimit('api');
    
    // Simulate academic search
    return [
      {
        title: `Academic paper: ${query}`,
        url: `https://scholar.example.com/paper/${Date.now()}`,
        snippet: `Abstract: Research findings related to "${query}"...`,
        source: 'academic',
        relevanceScore: 0.92
      }
    ];
  }

  private async searchNews(query: string): Promise<any[]> {
    await this.enforceRateLimit('api');
    
    // Simulate news search
    return [
      {
        title: `Latest news on: ${query}`,
        url: `https://news.example.com/article/${Date.now()}`,
        snippet: `Recent developments regarding "${query}"...`,
        source: 'news',
        relevanceScore: 0.78
      }
    ];
  }

  private async filterAndRank(
    sources: any[], 
    task: ResearchTask
  ): Promise<any[]> {
    let filtered = sources;
    
    // Apply filters
    if (task.filters?.types) {
      filtered = filtered.filter(s => 
        task.filters!.types!.includes(s.source)
      );
    }
    
    // Sort by relevance
    filtered.sort((a, b) => b.relevanceScore - a.relevanceScore);
    
    // Limit results
    if (task.maxResults) {
      filtered = filtered.slice(0, task.maxResults);
    }
    
    return filtered;
  }

  private async generateSummary(sources: any[]): Promise<string> {
    // In production, use LLM to generate summary
    const titles = sources.map(s =&gt; s.title).join('; ');
    return `Summary based on ${sources.length} sources: ${titles}`;
  }

  private extractKeywords(sources: any[]): string[] {
    // Simple keyword extraction (use NLP library in production)
    const allText = sources
      .map(s =&gt; `${s.title} ${s.snippet}`)
      .join(' ')
      .toLowerCase();
    
    const words = allText.split(/\s+/);
    const frequency: Record<string, number> = {};
    
    for (const word of words) {
      if (word.length &gt; 4) {
        frequency[word] = (frequency[word] || 0) + 1;
      }
    }
    
    return Object.entries(frequency)
      .sort(([, a], [, b]) =&gt; b - a)
      .slice(0, 10)
      .map(([word]) =&gt; word);
  }

  private getCacheKey(task: ResearchTask): string {
    return JSON.stringify({
      query: task.query,
      sources: task.sources,
      filters: task.filters
    });
  }

  private async enforceRateLimit(source: string): Promise<void> {
    const limiter = this.rateLimiters.get(source);
    if (!limiter) return;
    
    const now = Date.now();
    const timeSinceLastCall = now - limiter.lastCall;
    
    if (timeSinceLastCall &lt; limiter.minInterval) {
      const waitTime = limiter.minInterval - timeSinceLastCall;
      await new Promise(resolve =&gt; setTimeout(resolve, waitTime));
    }
    
    limiter.lastCall = Date.now();
  }
}
```

### Step 4: Create Communication Bus

**Copilot Prompt Suggestion:**
```typescript
// Create an event-driven communication bus that:
// - Enables pub/sub messaging between agents
// - Supports different message types and priorities
// - Implements message routing and filtering
// - Handles message persistence and replay
// - Provides delivery guarantees
// - Includes dead letter queue for failed messages
```

Create `src/communication/MessageBus.ts`:
```typescript
import { EventEmitter } from 'eventemitter3';
import Bull from 'bull';
import Redis from 'ioredis';
import winston from 'winston';

export interface Message {
  id: string;
  type: string;
  from: string;
  to?: string | string[];
  payload: any;
  priority?: number;
  timestamp: Date;
  correlationId?: string;
  replyTo?: string;
}

export interface MessageHandler {
  (message: Message): Promise<void>;
}

export class MessageBus extends EventEmitter {
  private redis: Redis;
  private queues: Map<string, Bull.Queue> = new Map();
  private subscribers: Map<string, Set<MessageHandler>&gt; = new Map();
  private logger: winston.Logger;
  private deadLetterQueue: Bull.Queue;

  constructor(redisUrl: string) {
    super();
    
    this.redis = new Redis(redisUrl);
    this.logger = winston.createLogger({
      level: 'info',
      format: winston.format.json(),
      defaultMeta: { component: 'MessageBus' }
    });
    
    this.deadLetterQueue = new Bull('dead-letter-queue', redisUrl);
    this.setupDeadLetterProcessing();
  }

  private setupDeadLetterProcessing(): void {
    this.deadLetterQueue.process(async (job) =&gt; {
      this.logger.error('Message in dead letter queue', {
        message: job.data,
        failedAttempts: job.attemptsMade
      });
      
      // Could implement alerting or manual intervention here
    });
  }

  async publish(message: Message): Promise<void> {
    this.logger.debug('Publishing message', {
      messageId: message.id,
      type: message.type,
      from: message.from,
      to: message.to
    });
    
    // Direct message to specific agent(s)
    if (message.to) {
      const recipients = Array.isArray(message.to) ? message.to : [message.to];
      
      for (const recipient of recipients) {
        const queue = this.getOrCreateQueue(recipient);
        
        await queue.add(message, {
          priority: message.priority || 0,
          attempts: 3,
          backoff: {
            type: 'exponential',
            delay: 2000
          }
        });
      }
    } else {
      // Broadcast message
      await this.broadcast(message);
    }
    
    this.emit('message-published', message);
  }

  async subscribe(
    agentId: string, 
    topics: string[], 
    handler: MessageHandler
  ): Promise<void> {
    // Subscribe to direct messages
    const queue = this.getOrCreateQueue(agentId);
    
    queue.process(async (job) =&gt; {
      const message = job.data as Message;
      
      try {
        await handler(message);
        this.emit('message-processed', {
          messageId: message.id,
          agentId
        });
      } catch (error) {
        this.logger.error('Message processing failed', {
          messageId: message.id,
          agentId,
          error
        });
        
        throw error; // Let Bull handle retry
      }
    });
    
    // Subscribe to topics
    for (const topic of topics) {
      if (!this.subscribers.has(topic)) {
        this.subscribers.set(topic, new Set());
      }
      
      this.subscribers.get(topic)!.add(handler);
    }
    
    this.logger.info('Agent subscribed', {
      agentId,
      topics
    });
  }

  private async broadcast(message: Message): Promise<void> {
    const topic = message.type;
    const handlers = this.subscribers.get(topic) || new Set();
    
    const promises = Array.from(handlers).map(handler =&gt; 
      this.executeHandler(handler, message)
    );
    
    await Promise.allSettled(promises);
  }

  private async executeHandler(
    handler: MessageHandler, 
    message: Message
  ): Promise<void> {
    try {
      await handler(message);
    } catch (error) {
      this.logger.error('Broadcast handler failed', {
        messageId: message.id,
        error
      });
      
      // Add to dead letter queue
      await this.deadLetterQueue.add({
        message,
        error: error.message,
        timestamp: new Date()
      });
    }
  }

  private getOrCreateQueue(agentId: string): Bull.Queue {
    if (!this.queues.has(agentId)) {
      const queue = new Bull(`agent-${agentId}`, {
        redis: this.redis
      });
      
      // Setup error handling
      queue.on('failed', (job, err) =&gt; {
        this.logger.error('Job failed', {
          agentId,
          messageId: job.data.id,
          error: err.message
        });
        
        if (job.attemptsMade &gt;= 3) {
          this.deadLetterQueue.add(job.data);
        }
      });
      
      this.queues.set(agentId, queue);
    }
    
    return this.queues.get(agentId)!;
  }

  async getQueueStats(agentId: string): Promise<{
    waiting: number;
    active: number;
    completed: number;
    failed: number;
  }> {
    const queue = this.queues.get(agentId);
    if (!queue) {
      return { waiting: 0, active: 0, completed: 0, failed: 0 };
    }
    
    const [waiting, active, completed, failed] = await Promise.all([
      queue.getWaitingCount(),
      queue.getActiveCount(),
      queue.getCompletedCount(),
      queue.getFailedCount()
    ]);
    
    return { waiting, active, completed, failed };
  }

  async shutdown(): Promise<void> {
    for (const queue of this.queues.values()) {
      await queue.close();
    }
    
    await this.deadLetterQueue.close();
    this.redis.disconnect();
    
    this.removeAllListeners();
  }
}
```

## ⏭️ Próximos Pasos

Continuar to [Partee 2](./exercise1-part2) where we'll implement:
- Analysis Agent
- Synthesis Agent
- Writer Agent
- Research Orchestrator
- Completar workflow integration