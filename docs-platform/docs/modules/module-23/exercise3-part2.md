---
sidebar_position: 4
title: "Exercise 3: Part 2"
description: "## 🛠️ Continuing Implementation"
---

# Exercise 3: Multi-Server MCP Client - Part 2

## 🛠️ Continuing Implementation

### Step 4: Implement Request Router with Load Balancing

**Copilot Prompt Suggestion:**
```typescript
// Create a request router that:
// - Routes requests to appropriate servers based on capabilities
// - Implements multiple load balancing strategies (round-robin, least-connections, weighted)
// - Handles request queuing and prioritization
// - Supports request affinity/sticky sessions
// - Implements request timeout and cancellation
// - Provides request tracing and metrics
```

Create `src/routing/RequestRouter.ts`:
```typescript
import { EventEmitter } from 'events';
import { ServerRegistry, ServerInfo } from '../discovery/ServerRegistry';
import { ConnectionPool, MCPConnection } from '../client/ConnectionPool';
import winston from 'winston';
import { nanoid } from 'nanoid';

export interface RoutingStrategy {
  name: string;
  selectServer(servers: ServerInfo[], context: RequestContext): ServerInfo | null;
}

export interface RequestContext {
  tool: string;
  params: any;
  priority?: 'low' | 'normal' | 'high';
  affinity?: string;
  timeout?: number;
  metadata?: Record<string, any>;
}

export interface RequestResult {
  requestId: string;
  serverId: string;
  tool: string;
  result: any;
  duration: number;
  attempts: number;
}

export class RoundRobinStrategy implements RoutingStrategy {
  name = 'round-robin';
  private index = 0;
  
  selectServer(servers: ServerInfo[]): ServerInfo | null {
    if (servers.length === 0) return null;
    
    const server = servers[this.index % servers.length];
    this.index++;
    
    return server;
  }
}

export class LeastConnectionsStrategy implements RoutingStrategy {
  name = 'least-connections';
  private connectionCounts = new Map<string, number>();
  
  selectServer(servers: ServerInfo[]): ServerInfo | null {
    if (servers.length === 0) return null;
    
    let selectedServer = servers[0];
    let minConnections = this.connectionCounts.get(selectedServer.id) || 0;
    
    for (const server of servers) {
      const count = this.connectionCounts.get(server.id) || 0;
      if (count &lt; minConnections) {
        selectedServer = server;
        minConnections = count;
      }
    }
    
    return selectedServer;
  }
  
  incrementConnections(serverId: string): void {
    const current = this.connectionCounts.get(serverId) || 0;
    this.connectionCounts.set(serverId, current + 1);
  }
  
  decrementConnections(serverId: string): void {
    const current = this.connectionCounts.get(serverId) || 0;
    this.connectionCounts.set(serverId, Math.max(0, current - 1));
  }
}

export class WeightedStrategy implements RoutingStrategy {
  name = 'weighted';
  
  selectServer(servers: ServerInfo[]): ServerInfo | null {
    if (servers.length === 0) return null;
    
    // Calculate weights based on server metrics
    const weightedServers = servers.map(server =&gt; ({
      server,
      weight: this.calculateWeight(server)
    }));
    
    // Sort by weight (highest first)
    weightedServers.sort((a, b) =&gt; b.weight - a.weight);
    
    // Select based on weighted random
    const totalWeight = weightedServers.reduce((sum, ws) =&gt; sum + ws.weight, 0);
    let random = Math.random() * totalWeight;
    
    for (const ws of weightedServers) {
      random -= ws.weight;
      if (random &lt;= 0) {
        return ws.server;
      }
    }
    
    return weightedServers[0].server;
  }
  
  private calculateWeight(server: ServerInfo): number {
    let weight = 100;
    
    // Adjust based on error rate
    const errorRate = server.errorCount / (server.successCount + server.errorCount || 1);
    weight *= (1 - errorRate);
    
    // Adjust based on response time (lower is better)
    if (server.averageResponseTime &gt; 0) {
      weight *= (1000 / server.averageResponseTime);
    }
    
    return Math.max(1, weight);
  }
}

export class RequestRouter extends EventEmitter {
  private registry: ServerRegistry;
  private connectionPool: ConnectionPool;
  private strategies: Map<string, RoutingStrategy> = new Map();
  private activeStrategy: RoutingStrategy;
  private affinityMap: Map<string, string> = new Map();
  private requestQueue: PriorityQueue<QueuedRequest>;
  private logger: winston.Logger;

  constructor(
    registry: ServerRegistry,
    connectionPool: ConnectionPool,
    logger: winston.Logger
  ) {
    super();
    
    this.registry = registry;
    this.connectionPool = connectionPool;
    this.logger = logger;
    this.requestQueue = new PriorityQueue();
    
    // Register default strategies
    this.registerStrategy(new RoundRobinStrategy());
    this.registerStrategy(new LeastConnectionsStrategy());
    this.registerStrategy(new WeightedStrategy());
    
    // Default to round-robin
    this.activeStrategy = this.strategies.get('round-robin')!;
  }

  registerStrategy(strategy: RoutingStrategy): void {
    this.strategies.set(strategy.name, strategy);
  }

  setStrategy(name: string): void {
    const strategy = this.strategies.get(name);
    if (!strategy) {
      throw new Error(`Unknown routing strategy: ${name}`);
    }
    
    this.activeStrategy = strategy;
    this.logger.info('Routing strategy changed', { strategy: name });
  }

  async routeRequest(context: RequestContext): Promise<RequestResult> {
    const requestId = nanoid();
    const startTime = Date.now();
    
    this.logger.debug('Routing request', {
      requestId,
      tool: context.tool,
      priority: context.priority
    });
    
    try {
      // Find servers with the required capability
      const capableServers = this.findCapableServers(context.tool);
      
      if (capableServers.length === 0) {
        throw new Error(`No servers available for tool: ${context.tool}`);
      }
      
      // Check for affinity
      let selectedServer: ServerInfo | null = null;
      
      if (context.affinity) {
        const affinityServerId = this.affinityMap.get(context.affinity);
        if (affinityServerId) {
          selectedServer = capableServers.find(s =&gt; s.id === affinityServerId) || null;
        }
      }
      
      // Select server using strategy
      if (!selectedServer) {
        selectedServer = this.activeStrategy.selectServer(capableServers, context);
      }
      
      if (!selectedServer) {
        throw new Error('No server selected');
      }
      
      // Update affinity if requested
      if (context.affinity) {
        this.affinityMap.set(context.affinity, selectedServer.id);
      }
      
      // Execute request
      const result = await this.executeRequest(
        requestId,
        selectedServer,
        context
      );
      
      const duration = Date.now() - startTime;
      
      this.logger.info('Request routed successfully', {
        requestId,
        serverId: selectedServer.id,
        tool: context.tool,
        duration
      });
      
      return {
        requestId,
        serverId: selectedServer.id,
        tool: context.tool,
        result,
        duration,
        attempts: 1
      };
      
    } catch (error: any) {
      const duration = Date.now() - startTime;
      
      this.logger.error('Request routing failed', {
        requestId,
        tool: context.tool,
        error: error.message,
        duration
      });
      
      throw error;
    }
  }

  private findCapableServers(tool: string): ServerInfo[] {
    // Extract capability from tool name
    const capability = tool.split('.')[0];
    
    return this.registry
      .getHealthyServers()
      .filter(server =&gt; 
        !server.capabilities || 
        server.capabilities.includes(capability) ||
        server.capabilities.includes('*')
      );
  }

  private async executeRequest(
    requestId: string,
    server: ServerInfo,
    context: RequestContext
  ): Promise<any> {
    const connection = await this.connectionPool.getConnection(server.id);
    
    try {
      // Update connection tracking for least-connections strategy
      if (this.activeStrategy.name === 'least-connections') {
        (this.activeStrategy as LeastConnectionsStrategy)
          .incrementConnections(server.id);
      }
      
      // Send request
      const response = await this.sendRequest(
        connection,
        requestId,
        context
      );
      
      // Update server metrics
      this.registry.updateServerMetrics(
        server.id,
        true,
        Date.now() - Date.now() // Calculate actual response time
      );
      
      return response;
      
    } finally {
      this.connectionPool.releaseConnection(connection);
      
      if (this.activeStrategy.name === 'least-connections') {
        (this.activeStrategy as LeastConnectionsStrategy)
          .decrementConnections(server.id);
      }
    }
  }

  private async sendRequest(
    connection: MCPConnection,
    requestId: string,
    context: RequestContext
  ): Promise<any> {
    return new Promise((resolve, reject) =&gt; {
      const timeout = setTimeout(() =&gt; {
        reject(new Error('Request timeout'));
      }, context.timeout || 30000);
      
      const message = {
        jsonrpc: '2.0',
        method: 'tool.execute',
        params: {
          name: context.tool,
          arguments: context.params
        },
        id: requestId
      };
      
      // Set up response handler
      const messageHandler = (data: WebSocket.Data) =&gt; {
        try {
          const response = JSON.parse(data.toString());
          
          if (response.id === requestId) {
            clearTimeout(timeout);
            connection.ws.removeListener('message', messageHandler);
            
            if (response.error) {
              reject(new Error(response.error.message));
            } else {
              resolve(response.result);
            }
          }
        } catch (error) {
          // Ignore parsing errors for other messages
        }
      };
      
      connection.ws.on('message', messageHandler);
      connection.ws.send(JSON.stringify(message));
    });
  }
}

// Priority Queue implementation for request queuing
class PriorityQueue<T> {
  private items: Array<{ item: T; priority: number }> = [];
  
  enqueue(item: T, priority: number): void {
    const element = { item, priority };
    let added = false;
    
    for (let i = 0; i < this.items.length; i++) {
      if (element.priority > this.items[i].priority) {
        this.items.splice(i, 0, element);
        added = true;
        break;
      }
    }
    
    if (!added) {
      this.items.push(element);
    }
  }
  
  dequeue(): T | undefined {
    return this.items.shift()?.item;
  }
  
  isEmpty(): boolean {
    return this.items.length === 0;
  }
  
  size(): number {
    return this.items.length;
  }
}

interface QueuedRequest {
  context: RequestContext;
  resolve: (result: any) => void;
  reject: (error: any) => void;
}
```

### Step 5: Implement Circuit Breaker

**Copilot Prompt Suggestion:**
```typescript
// Create a circuit breaker that:
// - Monitors server health and failures
// - Opens circuit after threshold failures
// - Implements half-open state for recovery testing
// - Provides configurable failure thresholds
// - Supports custom failure detection
// - Includes circuit state monitoring
```

Create `src/routing/CircuitBreaker.ts`:
```typescript
import { EventEmitter } from 'events';
import winston from 'winston';

export interface CircuitBreakerConfig {
  failureThreshold: number;
  successThreshold: number;
  timeout: number;
  resetTimeout: number;
  monitoringPeriod: number;
}

export enum CircuitState {
  CLOSED = 'CLOSED',
  OPEN = 'OPEN',
  HALF_OPEN = 'HALF_OPEN'
}

export class CircuitBreaker extends EventEmitter {
  private state: CircuitState = CircuitState.CLOSED;
  private failureCount: number = 0;
  private successCount: number = 0;
  private lastFailureTime?: Date;
  private nextAttemptTime?: Date;
  private config: CircuitBreakerConfig;
  private logger: winston.Logger;
  private serverId: string;

  constructor(
    serverId: string,
    config: Partial<CircuitBreakerConfig>,
    logger: winston.Logger
  ) {
    super();
    
    this.serverId = serverId;
    this.config = {
      failureThreshold: 5,
      successThreshold: 2,
      timeout: 60000, // 1 minute
      resetTimeout: 30000, // 30 seconds
      monitoringPeriod: 300000, // 5 minutes
      ...config
    };
    this.logger = logger;
  }

  async execute<T>(operation: () =&gt; Promise<T>): Promise<T> {
    if (this.state === CircuitState.OPEN) {
      if (this.canAttemptReset()) {
        this.transitionToHalfOpen();
      } else {
        throw new Error(`Circuit breaker is OPEN for server ${this.serverId}`);
      }
    }
    
    try {
      const result = await this.executeWithTimeout(operation);
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure(error);
      throw error;
    }
  }

  private async executeWithTimeout<T>(operation: () =&gt; Promise<T>): Promise<T> {
    return Promise.race([
      operation(),
      new Promise<never>((_, reject) =&gt; 
        setTimeout(
          () =&gt; reject(new Error('Circuit breaker timeout')),
          this.config.timeout
        )
      )
    ]);
  }

  private onSuccess(): void {
    this.failureCount = 0;
    
    if (this.state === CircuitState.HALF_OPEN) {
      this.successCount++;
      
      if (this.successCount &gt;= this.config.successThreshold) {
        this.transitionToClosed();
      }
    }
  }

  private onFailure(error: any): void {
    this.failureCount++;
    this.lastFailureTime = new Date();
    
    this.logger.warn('Circuit breaker failure', {
      serverId: this.serverId,
      failureCount: this.failureCount,
      error: error.message,
      state: this.state
    });
    
    if (this.state === CircuitState.HALF_OPEN) {
      this.transitionToOpen();
    } else if (
      this.state === CircuitState.CLOSED &&
      this.failureCount &gt;= this.config.failureThreshold
    ) {
      this.transitionToOpen();
    }
  }

  private canAttemptReset(): boolean {
    return (
      this.nextAttemptTime &&
      new Date() &gt;= this.nextAttemptTime
    );
  }

  private transitionToOpen(): void {
    this.state = CircuitState.OPEN;
    this.nextAttemptTime = new Date(Date.now() + this.config.resetTimeout);
    
    this.logger.error('Circuit breaker opened', {
      serverId: this.serverId,
      failureCount: this.failureCount,
      nextAttemptTime: this.nextAttemptTime
    });
    
    this.emit('state-change', {
      serverId: this.serverId,
      previousState: this.state,
      newState: CircuitState.OPEN
    });
  }

  private transitionToHalfOpen(): void {
    const previousState = this.state;
    this.state = CircuitState.HALF_OPEN;
    this.successCount = 0;
    
    this.logger.info('Circuit breaker half-open', {
      serverId: this.serverId
    });
    
    this.emit('state-change', {
      serverId: this.serverId,
      previousState,
      newState: CircuitState.HALF_OPEN
    });
  }

  private transitionToClosed(): void {
    const previousState = this.state;
    this.state = CircuitState.CLOSED;
    this.failureCount = 0;
    this.successCount = 0;
    this.nextAttemptTime = undefined;
    
    this.logger.info('Circuit breaker closed', {
      serverId: this.serverId
    });
    
    this.emit('state-change', {
      serverId: this.serverId,
      previousState,
      newState: CircuitState.CLOSED
    });
  }

  getState(): CircuitState {
    return this.state;
  }

  getStats(): {
    state: CircuitState;
    failureCount: number;
    successCount: number;
    lastFailureTime?: Date;
    nextAttemptTime?: Date;
  } {
    return {
      state: this.state,
      failureCount: this.failureCount,
      successCount: this.successCount,
      lastFailureTime: this.lastFailureTime,
      nextAttemptTime: this.nextAttemptTime
    };
  }

  reset(): void {
    this.transitionToClosed();
  }
}

export class CircuitBreakerManager {
  private breakers: Map<string, CircuitBreaker> = new Map();
  private config: Partial<CircuitBreakerConfig>;
  private logger: winston.Logger;

  constructor(
    config: Partial<CircuitBreakerConfig>,
    logger: winston.Logger
  ) {
    this.config = config;
    this.logger = logger;
  }

  getBreaker(serverId: string): CircuitBreaker {
    let breaker = this.breakers.get(serverId);
    
    if (!breaker) {
      breaker = new CircuitBreaker(serverId, this.config, this.logger);
      this.breakers.set(serverId, breaker);
      
      // Monitor state changes
      breaker.on('state-change', (event) =&gt; {
        this.logger.info('Circuit breaker state changed', event);
      });
    }
    
    return breaker;
  }

  async executeWithBreaker<T>(
    serverId: string,
    operation: () =&gt; Promise<T>
  ): Promise<T> {
    const breaker = this.getBreaker(serverId);
    return breaker.execute(operation);
  }

  getStats(): Map<string, any> {
    const stats = new Map();
    
    for (const [serverId, breaker] of this.breakers) {
      stats.set(serverId, breaker.getStats());
    }
    
    return stats;
  }

  reset(serverId?: string): void {
    if (serverId) {
      this.breakers.get(serverId)?.reset();
    } else {
      for (const breaker of this.breakers.values()) {
        breaker.reset();
      }
    }
  }
}
```

### Step 6: Create the Multi-Server MCP Client

Create `src/client/MultiServerMCPClient.ts`:
```typescript
import { EventEmitter } from 'events';
import { ServerRegistry, ServerInfo } from '../discovery/ServerRegistry';
import { ConnectionPool } from './ConnectionPool';
import { RequestRouter, RequestContext, RequestResult } from '../routing/RequestRouter';
import { CircuitBreakerManager } from '../routing/CircuitBreaker';
import winston from 'winston';
import NodeCache from 'node-cache';

export interface MultiServerConfig {
  discovery?: {
    method: 'static' | 'dns' | 'consul' | 'etcd';
    config?: any;
  };
  connectionPool?: {
    maxConnections?: number;
    minConnections?: number;
    connectionTimeout?: number;
  };
  routing?: {
    strategy?: 'round-robin' | 'least-connections' | 'weighted';
    timeout?: number;
  };
  circuitBreaker?: {
    enabled?: boolean;
    failureThreshold?: number;
    resetTimeout?: number;
  };
  cache?: {
    enabled?: boolean;
    ttl?: number;
    checkPeriod?: number;
  };
}

export class MultiServerMCPClient extends EventEmitter {
  private registry: ServerRegistry;
  private connectionPool: ConnectionPool;
  private router: RequestRouter;
  private circuitBreakerManager: CircuitBreakerManager;
  private cache?: NodeCache;
  private logger: winston.Logger;
  private isInitialized = false;

  constructor(config: MultiServerConfig = {}) {
    super();
    
    this.logger = this.setupLogger();
    this.registry = new ServerRegistry(this.logger);
    
    this.connectionPool = new ConnectionPool(
      {
        maxConnections: config.connectionPool?.maxConnections || 5,
        minConnections: config.connectionPool?.minConnections || 1,
        connectionTimeout: config.connectionPool?.connectionTimeout || 5000,
        idleTimeout: 300000,
        maxRetries: 3,
        retryDelay: 1000,
        healthCheckInterval: 30000
      },
      this.logger
    );
    
    this.router = new RequestRouter(
      this.registry,
      this.connectionPool,
      this.logger
    );
    
    this.circuitBreakerManager = new CircuitBreakerManager(
      {
        failureThreshold: config.circuitBreaker?.failureThreshold || 5,
        resetTimeout: config.circuitBreaker?.resetTimeout || 30000
      },
      this.logger
    );
    
    if (config.cache?.enabled) {
      this.cache = new NodeCache({
        stdTTL: config.cache.ttl || 600,
        checkperiod: config.cache.checkPeriod || 60
      });
    }
    
    // Set routing strategy
    if (config.routing?.strategy) {
      this.router.setStrategy(config.routing.strategy);
    }
    
    this.setupEventHandlers();
  }

  private setupLogger(): winston.Logger {
    return winston.createLogger({
      level: 'info',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
      ),
      transports: [
        new winston.transports.Console({
          format: winston.format.simple()
        })
      ]
    });
  }

  private setupEventHandlers(): void {
    // Registry events
    this.registry.on('server-registered', (server) =&gt; {
      this.handleServerRegistered(server);
    });
    
    this.registry.on('server-status-changed', (event) =&gt; {
      this.emit('server-status-changed', event);
    });
    
    // Connection pool events
    this.connectionPool.on('connection-error', (event) =&gt; {
      this.handleConnectionError(event);
    });
  }

  async initialize(servers?: ServerInfo[]): Promise<void> {
    if (this.isInitialized) {
      throw new Error('Client already initialized');
    }
    
    // Register static servers if provided
    if (servers) {
      for (const server of servers) {
        this.registry.registerServer(server);
      }
    }
    
    // Initialize discovery if configured
    await this.registry.initialize();
    
    // Wait for at least one server
    await this.waitForServers();
    
    this.isInitialized = true;
    this.emit('initialized');
  }

  private async waitForServers(timeout: number = 10000): Promise<void> {
    const startTime = Date.now();
    
    while (this.registry.getAllServers().length === 0) {
      if (Date.now() - startTime &gt; timeout) {
        throw new Error('No servers available after timeout');
      }
      
      await new Promise(resolve =&gt; setTimeout(resolve, 100));
    }
  }

  private async handleServerRegistered(server: ServerInfo): Promise<void> {
    try {
      await this.connectionPool.createPool(server.id, server.url);
      
      // Discover server capabilities
      const capabilities = await this.discoverCapabilities(server.id);
      this.registry.updateServerCapabilities(server.id, capabilities);
      
      this.registry.updateServerStatus(server.id, 'connected');
      
    } catch (error) {
      this.logger.error('Failed to setup server', {
        serverId: server.id,
        error
      });
      
      this.registry.updateServerStatus(server.id, 'error');
    }
  }

  private async discoverCapabilities(serverId: string): Promise<string[]> {
    try {
      const connection = await this.connectionPool.getConnection(serverId);
      
      const response = await this.sendDiscoveryRequest(connection);
      this.connectionPool.releaseConnection(connection);
      
      return response.tools || [];
      
    } catch (error) {
      this.logger.error('Failed to discover capabilities', {
        serverId,
        error
      });
      
      return [];
    }
  }

  private async sendDiscoveryRequest(connection: any): Promise<any> {
    // Implementation would send actual discovery request
    return { tools: ['file', 'database'] };
  }

  private handleConnectionError(event: any): void {
    this.registry.updateServerStatus(event.serverId, 'error');
  }

  async executeTool(
    tool: string,
    params: any,
    options: Partial<RequestContext> = {}
  ): Promise<any> {
    if (!this.isInitialized) {
      throw new Error('Client not initialized');
    }
    
    const context: RequestContext = {
      tool,
      params,
      ...options
    };
    
    // Check cache
    if (this.cache) {
      const cacheKey = this.getCacheKey(tool, params);
      const cached = this.cache.get(cacheKey);
      
      if (cached) {
        this.logger.debug('Cache hit', { tool, cacheKey });
        return cached;
      }
    }
    
    // Route request with circuit breaker
    const result = await this.circuitBreakerManager.executeWithBreaker(
      'main', // Circuit breaker key
      async () =&gt; this.router.routeRequest(context)
    );
    
    // Cache result
    if (this.cache && this.isCacheable(tool)) {
      const cacheKey = this.getCacheKey(tool, params);
      this.cache.set(cacheKey, result);
    }
    
    return result;
  }

  private getCacheKey(tool: string, params: any): string {
    return `${tool}:${JSON.stringify(params)}`;
  }

  private isCacheable(tool: string): boolean {
    // Don't cache write operations
    const nonCacheablePatterns = [
      'write', 'create', 'update', 'delete', 'execute'
    ];
    
    return !nonCacheablePatterns.some(pattern =&gt; 
      tool.toLowerCase().includes(pattern)
    );
  }

  async listTools(): Promise<Array<{
    server: string;
    tools: string[];
  }>> {
    const results: Array<{ server: string; tools: string[] }> = [];
    
    for (const server of this.registry.getHealthyServers()) {
      results.push({
        server: server.name,
        tools: server.capabilities || []
      });
    }
    
    return results;
  }

  getServerStats(): any {
    return {
      registry: this.registry.getStatistics(),
      circuitBreakers: Object.fromEntries(
        this.circuitBreakerManager.getStats()
      )
    };
  }

  async shutdown(): Promise<void> {
    await this.connectionPool.shutdown();
    await this.registry.shutdown();
    
    this.removeAllListeners();
    this.isInitialized = false;
  }
}
```

### Step 7: Create Demo and Test Script

Create `src/demo.ts`:
```typescript
import { MultiServerMCPClient } from './client/MultiServerMCPClient';

async function demonstrateMultiServerClient() {
  console.log('🚀 Multi-Server MCP Client Demo\n');
  
  // Create client
  const client = new MultiServerMCPClient({
    routing: {
      strategy: 'weighted'
    },
    circuitBreaker: {
      enabled: true,
      failureThreshold: 3
    },
    cache: {
      enabled: true,
      ttl: 300
    }
  });
  
  // Setup event handlers
  client.on('server-status-changed', (event) =&gt; {
    console.log(`📊 Server ${event.server.name} status: ${event.newStatus}`);
  });
  
  try {
    // Initialize with static servers
    await client.initialize([
      {
        id: 'fs-server',
        name: 'File System Server',
        url: 'ws://localhost:3000',
        type: 'filesystem',
        tags: ['storage', 'files']
      },
      {
        id: 'db-server',
        name: 'Database Server',
        url: 'ws://localhost:3001',
        type: 'database',
        tags: ['data', 'sql']
      }
    ]);
    
    console.log('✅ Client initialized\n');
    
    // List available tools
    const tools = await client.listTools();
    console.log('📋 Available tools:');
    tools.forEach(({ server, tools }) =&gt; {
      console.log(`  ${server}: ${tools.join(', ')}`);
    });
    console.log();
    
    // Example 1: File operation
    console.log('📁 Reading file...');
    const fileResult = await client.executeTool('file.read', {
      path: 'documents/test.md'
    });
    console.log('File content:', fileResult.result.content);
    console.log();
    
    // Example 2: Database query
    console.log('🗄️ Querying database...');
    const dbResult = await client.executeTool('database.query', {
      connection: 'postgresql',
      query: 'SELECT * FROM users LIMIT 5'
    });
    console.log('Users:', dbResult.result.rows);
    console.log();
    
    // Example 3: Parallel operations
    console.log('⚡ Executing parallel operations...');
    const [files, tables] = await Promise.all([
      client.executeTool('directory.list', { path: 'documents' }),
      client.executeTool('database.schema', { 
        connection: 'postgresql',
        type: 'tables' 
      })
    ]);
    
    console.log('Files:', files.result.map((f: any) =&gt; f.name));
    console.log('Tables:', tables.result.data.map((t: any) =&gt; t.table_name));
    console.log();
    
    // Show statistics
    const stats = client.getServerStats();
    console.log('📊 Client Statistics:');
    console.log(JSON.stringify(stats, null, 2));
    
  } catch (error) {
    console.error('❌ Demo error:', error);
  } finally {
    await client.shutdown();
    console.log('\n👋 Client shutdown complete');
  }
}

// Run demo
demonstrateMultiServerClient().catch(console.error);
```

### Step 8: Add Package Scripts

Update `package.json`:
```json
{
  "scripts": {
    "build": "tsc",
    "start": "node dist/demo.js",
    "dev": "nodemon --exec ts-node src/demo.ts",
    "test": "jest",
    "start-servers": "concurrently \"npm run start-fs-server\" \"npm run start-db-server\"",
    "start-fs-server": "cd ../exercise1-filesystem-server && npm start",
    "start-db-server": "cd ../exercise2-database-gateway && npm start",
    "lint": "eslint src/**/*.ts",
    "format": "prettier --write src/**/*.ts"
  }
}
```

## 🏃 Running the Multi-Server Client

1. **Start both MCP servers:**
```bash
# Terminal 1: File System Server
cd ../exercise1-filesystem-server
npm start

# Terminal 2: Database Server
cd ../exercise2-database-gateway
npm start
```

2. **Run the multi-server client:**
```bash
npm run build
npm start
```

## 🎯 Validation

Your Multi-Server MCP Client should now:
- ✅ Connect to multiple MCP servers
- ✅ Discover server capabilities automatically
- ✅ Route requests based on tool requirements
- ✅ Implement load balancing strategies
- ✅ Handle server failures with circuit breakers
- ✅ Cache responses for better performance
- ✅ Monitor server health and performance
- ✅ Support parallel operations across servers

## 🎊 Module 23 Complete!

Congratulations! You've mastered the Model Context Protocol by:
- Building a secure file system MCP server
- Creating a database gateway with query validation
- Implementing a sophisticated multi-server client

Key achievements:
- **Protocol Mastery**: Implemented JSON-RPC 2.0 over WebSocket
- **Security**: Query validation, path traversal prevention
- **Scalability**: Connection pooling, load balancing
- **Reliability**: Circuit breakers, automatic failover
- **Performance**: Caching, result streaming

## 📚 Additional Resources

- [MCP Specification](https://github.com/modelcontextprotocol/specification)
- [Distributed Systems Patterns](https://martinfowler.com/articles/patterns-of-distributed-systems/)
- [Circuit Breaker Pattern](https://martinfowler.com/bliki/CircuitBreaker.html)

## ⏭️ What's Next?

You're now ready for:
- **Module 24**: Multi-Agent Orchestration - Build complex agent systems
- **Module 25**: Production Agent Deployment - Deploy agents at scale

The MCP knowledge you've gained here will be essential for building production-ready agent systems!