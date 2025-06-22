# MCP Implementation Best Practices

## 🏗️ Architecture Best Practices

### 1. Server Design Principles

#### Single Responsibility
Each MCP server should focus on a specific domain:

```typescript
// ✅ Good: Focused server
class DatabaseMCPServer extends MCPServer {
  constructor() {
    super({
      name: 'database-server',
      version: '1.0.0',
      description: 'Provides database query capabilities'
    });
  }
}

// ❌ Bad: Kitchen sink server
class EverythingServer extends MCPServer {
  // Database, files, API calls, email, etc.
}
```

#### Tool Granularity
Design tools with appropriate granularity:

```typescript
// ✅ Good: Specific, reusable tools
server.registerTool({
  name: 'query_database',
  description: 'Execute a SELECT query',
  parameters: {
    query: { type: 'string', description: 'SQL SELECT query' },
    params: { type: 'array', description: 'Query parameters' }
  }
});

server.registerTool({
  name: 'insert_record',
  description: 'Insert a record into a table',
  parameters: {
    table: { type: 'string', description: 'Table name' },
    data: { type: 'object', description: 'Record data' }
  }
});

// ❌ Bad: Overly generic tool
server.registerTool({
  name: 'database_operation',
  description: 'Perform any database operation',
  parameters: {
    operation: { type: 'string' },
    data: { type: 'any' }
  }
});
```

### 2. Protocol Implementation

#### Message Validation
Always validate incoming messages:

```typescript
import Ajv from 'ajv';

class SecureMCPServer extends MCPServer {
  private ajv = new Ajv();
  
  async handleRequest(request: any): Promise<any> {
    // Validate request structure
    const valid = this.ajv.validate(requestSchema, request);
    if (!valid) {
      throw new MCPError(
        -32600,
        'Invalid Request',
        this.ajv.errors
      );
    }
    
    // Validate method exists
    if (!this.methods.has(request.method)) {
      throw new MCPError(
        -32601,
        'Method not found',
        { method: request.method }
      );
    }
    
    // Validate parameters
    const methodSchema = this.getMethodSchema(request.method);
    if (!this.ajv.validate(methodSchema, request.params)) {
      throw new MCPError(
        -32602,
        'Invalid params',
        this.ajv.errors
      );
    }
    
    return super.handleRequest(request);
  }
}
```

#### Error Handling
Implement comprehensive error handling:

```typescript
class RobustMCPServer extends MCPServer {
  async executeTool(name: string, params: any): Promise<any> {
    try {
      // Pre-execution validation
      this.validateToolAccess(name);
      this.validateToolParams(name, params);
      
      // Execute with timeout
      const result = await this.withTimeout(
        this.tools[name].execute(params),
        30000 // 30 second timeout
      );
      
      // Post-execution validation
      this.validateToolResult(name, result);
      
      return result;
    } catch (error) {
      // Map errors to MCP error codes
      if (error instanceof ValidationError) {
        throw new MCPError(-32602, 'Invalid params', error.details);
      } else if (error instanceof TimeoutError) {
        throw new MCPError(-32003, 'Execution timeout', { tool: name });
      } else if (error instanceof AuthorizationError) {
        throw new MCPError(-32004, 'Unauthorized', { tool: name });
      } else {
        // Log unexpected errors
        this.logger.error('Tool execution failed', { error, tool: name });
        throw new MCPError(-32603, 'Internal error');
      }
    }
  }
  
  private async withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
    const timeout = new Promise<never>((_, reject) => 
      setTimeout(() => reject(new TimeoutError()), ms)
    );
    return Promise.race([promise, timeout]);
  }
}
```

### 3. Security Best Practices

#### Authentication
Implement robust authentication:

```typescript
interface MCPAuthConfig {
  type: 'bearer' | 'mutual-tls' | 'oauth2';
  config: any;
}

class AuthenticatedMCPServer extends MCPServer {
  constructor(private auth: MCPAuthConfig) {
    super();
  }
  
  async handleConnection(socket: WebSocket, request: IncomingMessage) {
    try {
      const credentials = await this.extractCredentials(request);
      const identity = await this.authenticate(credentials);
      
      // Store identity for this connection
      this.connectionIdentities.set(socket, identity);
      
      // Set up authorized message handler
      socket.on('message', (data) => 
        this.handleAuthenticatedMessage(socket, data, identity)
      );
    } catch (error) {
      socket.close(1008, 'Authentication failed');
    }
  }
  
  private async authenticate(credentials: any): Promise<Identity> {
    switch (this.auth.type) {
      case 'bearer':
        return this.verifyBearerToken(credentials.token);
      case 'mutual-tls':
        return this.verifyClientCertificate(credentials.cert);
      case 'oauth2':
        return this.verifyOAuth2Token(credentials.token);
      default:
        throw new Error('Unsupported auth type');
    }
  }
}
```

#### Authorization
Implement fine-grained authorization:

```typescript
interface ToolPermission {
  tool: string;
  allowed: boolean;
  constraints?: any;
}

class AuthorizedMCPServer extends AuthenticatedMCPServer {
  private permissions = new Map<string, ToolPermission[]>();
  
  async executeTool(
    name: string, 
    params: any, 
    identity: Identity
  ): Promise<any> {
    // Check tool permission
    const permission = this.getPermission(identity, name);
    
    if (!permission?.allowed) {
      throw new MCPError(
        -32004, 
        'Unauthorized',
        { tool: name, identity: identity.id }
      );
    }
    
    // Apply constraints
    if (permission.constraints) {
      params = this.applyConstraints(params, permission.constraints);
    }
    
    // Audit log
    await this.auditLog.record({
      timestamp: new Date(),
      identity: identity.id,
      tool: name,
      params: this.sanitizeForLog(params),
      ip: identity.ip
    });
    
    return super.executeTool(name, params);
  }
  
  private applyConstraints(params: any, constraints: any): any {
    // Example: Limit database queries
    if (constraints.maxRows && params.limit) {
      params.limit = Math.min(params.limit, constraints.maxRows);
    }
    
    // Example: Filter allowed tables
    if (constraints.allowedTables && params.table) {
      if (!constraints.allowedTables.includes(params.table)) {
        throw new MCPError(-32004, 'Table access denied');
      }
    }
    
    return params;
  }
}
```

#### Input Sanitization
Always sanitize inputs:

```typescript
class SecureFileMCPServer extends MCPServer {
  private pathTraversalRegex = /\.\.|~|^\//;
  
  async readFile(params: { path: string }): Promise<string> {
    // Sanitize path
    const safePath = this.sanitizePath(params.path);
    
    // Validate path is within allowed directory
    const fullPath = path.join(this.baseDir, safePath);
    const realPath = await fs.realpath(fullPath);
    
    if (!realPath.startsWith(this.baseDir)) {
      throw new MCPError(-32602, 'Invalid path');
    }
    
    // Check file permissions
    await this.checkFilePermissions(realPath, 'read');
    
    // Read with size limit
    const stats = await fs.stat(realPath);
    if (stats.size > this.maxFileSize) {
      throw new MCPError(-32602, 'File too large');
    }
    
    return fs.readFile(realPath, 'utf-8');
  }
  
  private sanitizePath(inputPath: string): string {
    // Remove dangerous characters
    let safe = inputPath.replace(this.pathTraversalRegex, '');
    
    // Normalize slashes
    safe = safe.replace(/\\/g, '/');
    
    // Remove leading/trailing slashes
    safe = safe.replace(/^\/+|\/+$/g, '');
    
    return safe;
  }
}
```

### 4. Performance Optimization

#### Connection Pooling
Reuse connections for better performance:

```typescript
class PooledMCPClient {
  private pools = new Map<string, ConnectionPool>();
  
  async connectToServer(url: string): Promise<MCPConnection> {
    let pool = this.pools.get(url);
    
    if (!pool) {
      pool = new ConnectionPool({
        url,
        minConnections: 2,
        maxConnections: 10,
        idleTimeout: 60000,
        connectionTimeout: 5000
      });
      this.pools.set(url, pool);
    }
    
    return pool.acquire();
  }
  
  async executeToolOnServer(
    serverUrl: string,
    tool: string,
    params: any
  ): Promise<any> {
    const connection = await this.connectToServer(serverUrl);
    
    try {
      return await connection.executeTool(tool, params);
    } finally {
      // Return connection to pool
      connection.release();
    }
  }
}
```

#### Response Caching
Cache responses for idempotent operations:

```typescript
interface CacheConfig {
  ttl: number;
  maxSize: number;
}

class CachedMCPServer extends MCPServer {
  private cache = new LRUCache<string, any>({
    max: 1000,
    ttl: 1000 * 60 * 5 // 5 minutes
  });
  
  async executeTool(name: string, params: any): Promise<any> {
    const tool = this.tools.get(name);
    
    // Only cache safe, idempotent operations
    if (tool.cacheable) {
      const cacheKey = this.getCacheKey(name, params);
      const cached = this.cache.get(cacheKey);
      
      if (cached) {
        this.metrics.increment('cache.hits');
        return cached;
      }
      
      const result = await super.executeTool(name, params);
      this.cache.set(cacheKey, result);
      this.metrics.increment('cache.misses');
      
      return result;
    }
    
    return super.executeTool(name, params);
  }
  
  private getCacheKey(tool: string, params: any): string {
    return `${tool}:${JSON.stringify(params, Object.keys(params).sort())}`;
  }
}
```

#### Streaming Responses
Use streaming for large responses:

```typescript
class StreamingMCPServer extends MCPServer {
  async executeLargeQuery(params: { query: string }): AsyncIterable<any> {
    const results = await this.db.queryStream(params.query);
    
    // Stream results in chunks
    async function* streamResults() {
      const buffer = [];
      
      for await (const row of results) {
        buffer.push(row);
        
        // Send chunk when buffer is full
        if (buffer.length >= 100) {
          yield {
            type: 'chunk',
            data: buffer.splice(0)
          };
        }
      }
      
      // Send remaining items
      if (buffer.length > 0) {
        yield {
          type: 'chunk',
          data: buffer
        };
      }
      
      // Send completion marker
      yield {
        type: 'complete',
        totalRows: results.rowCount
      };
    }
    
    return streamResults();
  }
}
```

### 5. Monitoring and Observability

#### Structured Logging
Use structured logging throughout:

```typescript
import winston from 'winston';

class ObservableMCPServer extends MCPServer {
  private logger = winston.createLogger({
    format: winston.format.json(),
    defaultMeta: { 
      service: 'mcp-server',
      version: this.version 
    },
    transports: [
      new winston.transports.File({ filename: 'mcp-error.log', level: 'error' }),
      new winston.transports.File({ filename: 'mcp-combined.log' })
    ]
  });
  
  async handleRequest(request: MCPRequest): Promise<MCPResponse> {
    const requestId = generateRequestId();
    const startTime = Date.now();
    
    this.logger.info('request_received', {
      requestId,
      method: request.method,
      clientId: request.clientId
    });
    
    try {
      const response = await super.handleRequest(request);
      
      this.logger.info('request_completed', {
        requestId,
        method: request.method,
        duration: Date.now() - startTime,
        success: true
      });
      
      return response;
    } catch (error) {
      this.logger.error('request_failed', {
        requestId,
        method: request.method,
        duration: Date.now() - startTime,
        error: error.message,
        errorCode: error.code
      });
      
      throw error;
    }
  }
}
```

#### Metrics Collection
Implement comprehensive metrics:

```typescript
import { Counter, Histogram, Gauge } from 'prom-client';

class MetricsMCPServer extends MCPServer {
  private metrics = {
    requestsTotal: new Counter({
      name: 'mcp_requests_total',
      help: 'Total number of MCP requests',
      labelNames: ['method', 'status']
    }),
    
    requestDuration: new Histogram({
      name: 'mcp_request_duration_seconds',
      help: 'Request duration in seconds',
      labelNames: ['method'],
      buckets: [0.1, 0.5, 1, 2, 5, 10]
    }),
    
    activeConnections: new Gauge({
      name: 'mcp_active_connections',
      help: 'Number of active connections'
    }),
    
    toolExecutions: new Counter({
      name: 'mcp_tool_executions_total',
      help: 'Total tool executions',
      labelNames: ['tool', 'status']
    })
  };
  
  async executeTool(name: string, params: any): Promise<any> {
    const timer = this.metrics.requestDuration.startTimer({ method: name });
    
    try {
      const result = await super.executeTool(name, params);
      
      this.metrics.toolExecutions.inc({ tool: name, status: 'success' });
      timer();
      
      return result;
    } catch (error) {
      this.metrics.toolExecutions.inc({ tool: name, status: 'error' });
      timer();
      
      throw error;
    }
  }
}
```

### 6. Testing Strategies

#### Unit Testing MCP Servers
```typescript
describe('MCP Server', () => {
  let server: TestMCPServer;
  let client: MockMCPClient;
  
  beforeEach(async () => {
    server = new TestMCPServer();
    await server.start();
    
    client = new MockMCPClient();
    await client.connect(server.url);
  });
  
  afterEach(async () => {
    await client.disconnect();
    await server.stop();
  });
  
  describe('Tool Execution', () => {
    it('should execute tool successfully', async () => {
      const result = await client.executeTool('echo', { message: 'test' });
      expect(result).toEqual({ echo: 'test' });
    });
    
    it('should validate parameters', async () => {
      await expect(
        client.executeTool('echo', { invalid: 'param' })
      ).rejects.toThrow('Invalid params');
    });
    
    it('should enforce rate limits', async () => {
      // Execute multiple requests
      const promises = Array(10).fill(0).map(() => 
        client.executeTool('echo', { message: 'test' })
      );
      
      await expect(Promise.all(promises)).rejects.toThrow('Rate limit exceeded');
    });
  });
});
```

#### Integration Testing
```typescript
describe('MCP Integration', () => {
  let servers: MCPServer[];
  let orchestrator: MCPOrchestrator;
  
  beforeAll(async () => {
    // Start multiple servers
    servers = await Promise.all([
      DatabaseMCPServer.start({ port: 3001 }),
      FileMCPServer.start({ port: 3002 }),
      APIMCPServer.start({ port: 3003 })
    ]);
    
    orchestrator = new MCPOrchestrator();
    await orchestrator.discoverServers();
  });
  
  it('should orchestrate across multiple servers', async () => {
    const workflow = {
      steps: [
        { server: 'database', tool: 'query', params: { sql: 'SELECT * FROM users' } },
        { server: 'file', tool: 'write', params: { path: 'users.json', data: '$1' } },
        { server: 'api', tool: 'notify', params: { message: 'Export complete' } }
      ]
    };
    
    const result = await orchestrator.executeWorkflow(workflow);
    expect(result.success).toBe(true);
  });
});
```

### 7. Production Deployment

#### Health Checks
Implement comprehensive health checks:

```typescript
class HealthyMCPServer extends MCPServer {
  async getHealth(): Promise<HealthStatus> {
    const checks = await Promise.all([
      this.checkDatabase(),
      this.checkFileSystem(),
      this.checkMemory(),
      this.checkDependencies()
    ]);
    
    const status = checks.every(c => c.healthy) ? 'healthy' : 'unhealthy';
    
    return {
      status,
      version: this.version,
      uptime: process.uptime(),
      checks: checks.reduce((acc, check) => {
        acc[check.name] = {
          status: check.healthy ? 'pass' : 'fail',
          message: check.message,
          duration: check.duration
        };
        return acc;
      }, {})
    };
  }
  
  private async checkDatabase(): Promise<HealthCheck> {
    const start = Date.now();
    try {
      await this.db.query('SELECT 1');
      return {
        name: 'database',
        healthy: true,
        duration: Date.now() - start
      };
    } catch (error) {
      return {
        name: 'database',
        healthy: false,
        message: error.message,
        duration: Date.now() - start
      };
    }
  }
}
```

#### Graceful Shutdown
Handle shutdown gracefully:

```typescript
class GracefulMCPServer extends MCPServer {
  private isShuttingDown = false;
  
  async start() {
    await super.start();
    
    // Handle shutdown signals
    process.on('SIGTERM', () => this.shutdown());
    process.on('SIGINT', () => this.shutdown());
  }
  
  async shutdown() {
    if (this.isShuttingDown) return;
    this.isShuttingDown = true;
    
    this.logger.info('Shutdown initiated');
    
    // Stop accepting new connections
    this.server.close();
    
    // Wait for ongoing requests
    await this.waitForRequestsToComplete();
    
    // Close database connections
    await this.db.close();
    
    // Close other resources
    await this.cleanup();
    
    this.logger.info('Shutdown complete');
    process.exit(0);
  }
  
  private async waitForRequestsToComplete(timeout = 30000) {
    const start = Date.now();
    
    while (this.activeRequests.size > 0) {
      if (Date.now() - start > timeout) {
        this.logger.warn('Forcing shutdown with active requests', {
          count: this.activeRequests.size
        });
        break;
      }
      
      await new Promise(resolve => setTimeout(resolve, 100));
    }
  }
}
```

## 📋 MCP Development Checklist

### Server Development
- [ ] Define clear tool boundaries
- [ ] Implement proper error handling
- [ ] Add input validation
- [ ] Include authentication
- [ ] Set up authorization
- [ ] Add rate limiting
- [ ] Implement caching where appropriate
- [ ] Add comprehensive logging
- [ ] Include metrics collection
- [ ] Write unit tests
- [ ] Add integration tests
- [ ] Document all tools
- [ ] Implement health checks
- [ ] Handle graceful shutdown

### Client Development
- [ ] Implement connection pooling
- [ ] Add retry logic
- [ ] Handle connection failures
- [ ] Implement timeout handling
- [ ] Add request caching
- [ ] Include circuit breakers
- [ ] Log all operations
- [ ] Add performance metrics
- [ ] Write tests
- [ ] Document usage

### Security
- [ ] Use TLS for all connections
- [ ] Implement authentication
- [ ] Add authorization checks
- [ ] Validate all inputs
- [ ] Sanitize outputs
- [ ] Add rate limiting
- [ ] Implement audit logging
- [ ] Regular security audits

### Operations
- [ ] Set up monitoring
- [ ] Configure alerting
- [ ] Plan for scaling
- [ ] Document runbooks
- [ ] Test disaster recovery
- [ ] Monitor performance
- [ ] Track usage metrics

## 🚀 Performance Tips

1. **Use Connection Pooling**: Reuse connections instead of creating new ones
2. **Implement Caching**: Cache responses for idempotent operations
3. **Batch Operations**: Group multiple operations when possible
4. **Stream Large Data**: Use streaming for large datasets
5. **Optimize Queries**: Profile and optimize database queries
6. **Use Compression**: Compress large payloads
7. **Implement Pagination**: Don't return unlimited results
8. **Monitor Performance**: Track metrics and optimize bottlenecks

## 🛡️ Security Guidelines

1. **Always Use TLS**: Never send MCP traffic over unencrypted connections
2. **Authenticate Everything**: Every connection must be authenticated
3. **Authorize by Default**: Implement allowlists, not denylists
4. **Validate Inputs**: Never trust client-provided data
5. **Limit Resources**: Set maximum limits on all operations
6. **Audit Everything**: Log all security-relevant events
7. **Regular Updates**: Keep all dependencies updated
8. **Security Testing**: Regular penetration testing

Remember: MCP is powerful but must be implemented securely and efficiently!