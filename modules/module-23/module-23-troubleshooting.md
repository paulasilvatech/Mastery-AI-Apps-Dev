# 🔧 Module 23: MCP Troubleshooting Guide

## Common Issues and Solutions

### 🚫 Connection Issues

#### Problem: WebSocket connection fails immediately
```
Error: WebSocket connection to 'ws://localhost:3000' failed: Connection refused
```

**Solutions:**

1. **Check if server is running**
```bash
# Check if port is listening
lsof -i :3000  # macOS/Linux
netstat -an | findstr :3000  # Windows

# If not running, start the server
npm run start-server
# or
node dist/server.js
```

2. **Verify server configuration**
```typescript
// Check server startup code
const server = new MCPServer({
  host: 'localhost', // Make sure this matches client
  port: 3000,        // Make sure port matches
  path: '/mcp'       // WebSocket path
});

await server.start();
console.log(`Server listening on ws://localhost:3000/mcp`);
```

3. **Check firewall settings**
```bash
# macOS
sudo pfctl -s rules | grep 3000

# Linux
sudo iptables -L -n | grep 3000

# Windows
netsh advfirewall firewall show rule name=all | findstr 3000
```

#### Problem: TLS/SSL connection errors
```
Error: unable to verify the first certificate
```

**Solutions:**

1. **For development, allow self-signed certificates**
```typescript
// Client configuration
const client = new MCPClient({
  url: 'wss://localhost:3000',
  tls: {
    rejectUnauthorized: false // ONLY for development
  }
});
```

2. **For production, use proper certificates**
```typescript
// Server configuration
const server = new MCPServer({
  tls: {
    cert: fs.readFileSync('server.crt'),
    key: fs.readFileSync('server.key'),
    ca: fs.readFileSync('ca.crt') // If using custom CA
  }
});
```

3. **Debug certificate issues**
```bash
# Check certificate validity
openssl x509 -in server.crt -text -noout

# Test TLS connection
openssl s_client -connect localhost:3000
```

#### Problem: Authentication failures
```
Error: Authentication failed: Invalid token
```

**Solutions:**

1. **Verify token format**
```typescript
// Correct Bearer token format
const client = new MCPClient({
  auth: {
    type: 'bearer',
    token: 'Bearer YOUR_TOKEN_HERE' // Include 'Bearer' prefix
  }
});
```

2. **Check token expiration**
```typescript
// Decode JWT to check expiration
import jwt from 'jsonwebtoken';

const decoded = jwt.decode(token);
console.log('Token expires:', new Date(decoded.exp * 1000));

// Implement token refresh
async function getValidToken() {
  if (isTokenExpired(currentToken)) {
    currentToken = await refreshToken();
  }
  return currentToken;
}
```

3. **Debug authentication flow**
```typescript
// Add authentication debugging
class DebugMCPClient extends MCPClient {
  async connect() {
    console.log('Attempting authentication...');
    console.log('Auth type:', this.config.auth.type);
    console.log('Auth header:', this.getAuthHeader());
    
    try {
      await super.connect();
      console.log('Authentication successful');
    } catch (error) {
      console.error('Authentication failed:', error);
      throw error;
    }
  }
}
```

### 🔴 Protocol Errors

#### Problem: Invalid JSON-RPC request
```
Error: Parse error: Invalid JSON was received by the server
```

**Solutions:**

1. **Validate JSON structure**
```typescript
// Ensure proper JSON-RPC 2.0 format
const request = {
  jsonrpc: "2.0",  // Required
  method: "tool.execute",
  params: {
    name: "query_database",
    arguments: { query: "SELECT * FROM users" }
  },
  id: 1  // Required for requests expecting response
};

// Validate before sending
try {
  JSON.parse(JSON.stringify(request));
} catch (error) {
  console.error('Invalid JSON:', error);
}
```

2. **Check for special characters**
```typescript
// Escape special characters in strings
function sanitizeForJSON(str: string): string {
  return str
    .replace(/\\/g, '\\\\')
    .replace(/"/g, '\\"')
    .replace(/\n/g, '\\n')
    .replace(/\r/g, '\\r')
    .replace(/\t/g, '\\t');
}
```

3. **Use a JSON-RPC library**
```typescript
import { JSONRPCClient } from 'json-rpc-2.0';

const client = new JSONRPCClient((request) => {
  // Automatically handles proper formatting
  return fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(request)
  }).then(response => response.json());
});
```

#### Problem: Method not found
```
Error: Method not found: tool.unknown
```

**Solutions:**

1. **List available methods**
```typescript
// Add discovery endpoint
class DiscoverableMCPServer extends MCPServer {
  constructor() {
    super();
    
    // Register discovery method
    this.registerMethod('rpc.discover', async () => {
      return {
        methods: Array.from(this.methods.keys()),
        tools: Array.from(this.tools.keys()),
        version: this.version
      };
    });
  }
}

// Client discovery
const discovery = await client.request('rpc.discover');
console.log('Available methods:', discovery.methods);
console.log('Available tools:', discovery.tools);
```

2. **Check method registration**
```typescript
// Verify method is registered
server.registerMethod('tool.execute', async (params) => {
  // Implementation
});

// Debug registered methods
console.log('Registered methods:', server.getRegisteredMethods());
```

3. **Handle method aliases**
```typescript
// Support multiple method names
class FlexibleMCPServer extends MCPServer {
  registerMethod(name: string | string[], handler: Function) {
    const names = Array.isArray(name) ? name : [name];
    
    for (const n of names) {
      super.registerMethod(n, handler);
    }
  }
}

// Register with aliases
server.registerMethod(
  ['tool.execute', 'tools/execute', 'execute_tool'],
  toolExecuteHandler
);
```

### 🛠️ Tool Execution Issues

#### Problem: Tool execution timeout
```
Error: Tool execution timed out after 30000ms
```

**Solutions:**

1. **Increase timeout for long-running operations**
```typescript
// Configure per-tool timeouts
const tools = {
  quick_query: {
    handler: quickQueryHandler,
    timeout: 5000 // 5 seconds
  },
  complex_analysis: {
    handler: complexAnalysisHandler,
    timeout: 300000 // 5 minutes
  }
};

// Client-side timeout configuration
const result = await client.executeTool('complex_analysis', params, {
  timeout: 300000 // Match server timeout
});
```

2. **Implement progress reporting**
```typescript
// Stream progress updates
class ProgressMCPServer extends MCPServer {
  async executeLongTool(params: any, context: MCPContext) {
    const progressId = generateId();
    
    // Start async execution
    this.executeAsync(async () => {
      for (let i = 0; i <= 100; i += 10) {
        await this.sendProgress(context.connectionId, {
          id: progressId,
          progress: i,
          message: `Processing... ${i}%`
        });
        
        await someWork();
      }
    });
    
    // Return immediately with progress ID
    return { progressId, status: 'started' };
  }
}
```

3. **Use chunked responses**
```typescript
// Break large operations into chunks
async function* executeInChunks(params: any) {
  const totalItems = await getTotalCount(params);
  const chunkSize = 1000;
  
  for (let offset = 0; offset < totalItems; offset += chunkSize) {
    const chunk = await processChunk(params, offset, chunkSize);
    
    yield {
      type: 'chunk',
      offset,
      data: chunk,
      progress: (offset + chunkSize) / totalItems
    };
  }
  
  yield { type: 'complete', totalProcessed: totalItems };
}
```

#### Problem: Tool parameter validation errors
```
Error: Invalid params: Missing required parameter 'query'
```

**Solutions:**

1. **Provide clear parameter schemas**
```typescript
// Define detailed schemas
const toolSchema = {
  name: 'query_database',
  description: 'Execute a database query',
  parameters: {
    type: 'object',
    properties: {
      query: {
        type: 'string',
        description: 'SQL query to execute',
        minLength: 1,
        pattern: '^SELECT .+' // Only allow SELECT queries
      },
      params: {
        type: 'array',
        description: 'Query parameters',
        items: { type: ['string', 'number', 'boolean', 'null'] }
      },
      timeout: {
        type: 'number',
        description: 'Query timeout in milliseconds',
        minimum: 1000,
        maximum: 60000,
        default: 30000
      }
    },
    required: ['query']
  }
};
```

2. **Implement helpful error messages**
```typescript
class HelpfulMCPServer extends MCPServer {
  validateParams(schema: any, params: any): ValidationResult {
    const result = super.validateParams(schema, params);
    
    if (!result.valid) {
      // Enhance error messages
      const enhanced = result.errors.map(error => {
        if (error.keyword === 'required') {
          const missing = error.params.missingProperty;
          const param = schema.properties[missing];
          
          return {
            ...error,
            message: `Missing required parameter '${missing}': ${param.description}`,
            suggestion: `Add '${missing}' to your request parameters`
          };
        }
        
        return error;
      });
      
      result.errors = enhanced;
    }
    
    return result;
  }
}
```

3. **Generate example requests**
```typescript
// Auto-generate examples from schema
function generateExample(schema: any): any {
  const example: any = {};
  
  for (const [key, prop] of Object.entries(schema.properties)) {
    if (schema.required?.includes(key)) {
      example[key] = generateExampleValue(prop);
    }
  }
  
  return example;
}

// Include in error response
throw new MCPError(-32602, 'Invalid params', {
  errors: validationErrors,
  example: generateExample(toolSchema.parameters)
});
```

### 📊 Performance Issues

#### Problem: Slow response times
```
Warning: Request took 5234ms to complete
```

**Solutions:**

1. **Profile server performance**
```typescript
class ProfiledMCPServer extends MCPServer {
  async handleRequest(request: any): Promise<any> {
    const profiler = new Profiler(request.id);
    
    profiler.mark('request_start');
    
    // Validate
    profiler.mark('validation_start');
    const validation = await this.validate(request);
    profiler.mark('validation_end');
    
    // Execute
    profiler.mark('execution_start');
    const result = await this.execute(request);
    profiler.mark('execution_end');
    
    // Log performance metrics
    const metrics = profiler.getMetrics();
    if (metrics.total > 1000) {
      this.logger.warn('Slow request', {
        requestId: request.id,
        metrics
      });
    }
    
    return result;
  }
}
```

2. **Optimize database queries**
```typescript
// Use connection pooling
const pool = new Pool({
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000
});

// Prepare statements
const preparedQueries = new Map();

async function executeQuery(sql: string, params: any[]) {
  let prepared = preparedQueries.get(sql);
  
  if (!prepared) {
    prepared = await pool.prepare(sql);
    preparedQueries.set(sql, prepared);
  }
  
  return prepared.execute(params);
}
```

3. **Implement caching**
```typescript
// Cache with TTL
const cache = new NodeCache({ 
  stdTTL: 600, // 10 minutes
  checkperiod: 60 // Check every minute
});

async function cachedExecute(tool: string, params: any) {
  const key = `${tool}:${JSON.stringify(params)}`;
  
  // Check cache
  const cached = cache.get(key);
  if (cached) {
    return cached;
  }
  
  // Execute and cache
  const result = await execute(tool, params);
  cache.set(key, result);
  
  return result;
}
```

#### Problem: Memory leaks
```
Error: JavaScript heap out of memory
```

**Solutions:**

1. **Monitor memory usage**
```typescript
// Track memory usage
class MemoryAwareMCPServer extends MCPServer {
  private memoryMonitor = setInterval(() => {
    const usage = process.memoryUsage();
    
    this.metrics.gauge('memory.rss', usage.rss);
    this.metrics.gauge('memory.heap_used', usage.heapUsed);
    this.metrics.gauge('memory.heap_total', usage.heapTotal);
    
    // Alert on high memory
    if (usage.heapUsed / usage.heapTotal > 0.9) {
      this.logger.warn('High memory usage', {
        heapUsed: usage.heapUsed,
        heapTotal: usage.heapTotal
      });
    }
  }, 10000);
}
```

2. **Clean up resources**
```typescript
// Ensure cleanup
class ResourceManagedServer extends MCPServer {
  private resources = new Set<IDisposable>();
  
  registerResource(resource: IDisposable) {
    this.resources.add(resource);
  }
  
  async shutdown() {
    // Clean up all resources
    for (const resource of this.resources) {
      try {
        await resource.dispose();
      } catch (error) {
        this.logger.error('Resource cleanup failed', { error });
      }
    }
    
    this.resources.clear();
    await super.shutdown();
  }
}
```

3. **Limit concurrent operations**
```typescript
// Use semaphore to limit concurrency
class ConcurrencyLimitedServer extends MCPServer {
  private semaphore = new Semaphore(10); // Max 10 concurrent
  
  async executeTool(name: string, params: any): Promise<any> {
    await this.semaphore.acquire();
    
    try {
      return await super.executeTool(name, params);
    } finally {
      this.semaphore.release();
    }
  }
}
```

### 🔐 Security Issues

#### Problem: CORS errors in browser
```
Error: CORS policy: No 'Access-Control-Allow-Origin' header
```

**Solutions:**

1. **Configure CORS properly**
```typescript
// For HTTP transport
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true,
  methods: ['POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// For WebSocket
const wss = new WebSocket.Server({
  verifyClient: (info) => {
    const origin = info.origin;
    const allowed = getAllowedOrigins();
    
    return allowed.includes(origin) || allowed.includes('*');
  }
});
```

2. **Use proxy for development**
```json
// package.json
{
  "proxy": "http://localhost:3000"
}

// Or webpack config
module.exports = {
  devServer: {
    proxy: {
      '/mcp': {
        target: 'ws://localhost:3000',
        ws: true,
        changeOrigin: true
      }
    }
  }
};
```

### 🐛 Debugging Tools

#### MCP Protocol Inspector
```typescript
// Log all MCP messages
class DebugMCPServer extends MCPServer {
  async handleMessage(message: string) {
    console.log('Received:', JSON.stringify(JSON.parse(message), null, 2));
    
    const response = await super.handleMessage(message);
    
    console.log('Sending:', JSON.stringify(JSON.parse(response), null, 2));
    
    return response;
  }
}
```

#### Connection Tester
```bash
#!/bin/bash
# test-mcp-connection.sh

echo "Testing MCP connection..."

# Test basic connectivity
curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "rpc.discover",
    "id": 1
  }'

# Test WebSocket
wscat -c ws://localhost:3000/mcp \
  -x '{"jsonrpc":"2.0","method":"rpc.discover","id":1}'
```

#### Performance Profiler
```typescript
// Profile tool execution
async function profileToolExecution(client: MCPClient, tool: string, params: any) {
  const iterations = 100;
  const times: number[] = [];
  
  console.log(`Profiling ${tool}...`);
  
  for (let i = 0; i < iterations; i++) {
    const start = performance.now();
    await client.executeTool(tool, params);
    const end = performance.now();
    
    times.push(end - start);
  }
  
  // Calculate statistics
  const avg = times.reduce((a, b) => a + b) / times.length;
  const min = Math.min(...times);
  const max = Math.max(...times);
  const p95 = times.sort((a, b) => a - b)[Math.floor(iterations * 0.95)];
  
  console.log(`
    Average: ${avg.toFixed(2)}ms
    Min: ${min.toFixed(2)}ms
    Max: ${max.toFixed(2)}ms
    P95: ${p95.toFixed(2)}ms
  `);
}
```

## 🔍 Diagnostic Commands

### Check MCP Server Status
```bash
# Check if server is responding
curl -s http://localhost:3000/health | jq .

# Check WebSocket endpoint
websocat -1 ws://localhost:3000/mcp <<< '{"jsonrpc":"2.0","method":"ping","id":1}'

# Monitor server logs
tail -f mcp-server.log | jq .
```

### Debug Client Connection
```typescript
// Enable debug logging
const client = new MCPClient({
  url: 'ws://localhost:3000',
  debug: true,
  logger: {
    debug: console.log,
    info: console.info,
    warn: console.warn,
    error: console.error
  }
});
```

### Monitor Performance
```bash
# Watch server metrics
watch -n 1 'curl -s http://localhost:3000/metrics | grep mcp_'

# Profile specific tool
time curl -X POST http://localhost:3000/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tool.execute","params":{"name":"test"},"id":1}'
```

## 📞 Getting Help

If issues persist:

1. **Enable verbose logging**
```typescript
process.env.DEBUG = 'mcp:*';
process.env.LOG_LEVEL = 'debug';
```

2. **Collect diagnostic information**
```bash
# System info
node -v
npm ls @modelcontextprotocol/sdk

# Network info
netstat -tulpn | grep node
```

3. **Create minimal reproduction**
```typescript
// minimal-repro.js
const { MCPServer } = require('@modelcontextprotocol/sdk');

const server = new MCPServer();
server.registerTool('test', async () => 'works');

server.start()
  .then(() => console.log('Server started'))
  .catch(console.error);
```

4. **Check official resources**
- [MCP GitHub Issues](https://github.com/modelcontextprotocol/specification/issues)
- [MCP Discussions](https://github.com/modelcontextprotocol/specification/discussions)
- Module 23 Discord Channel

Remember: Most MCP issues are related to connection setup, authentication, or message formatting. Start debugging there!