# Module 23 Resources

## 📁 resources/mcp-templates/

### mcp-server-template.ts
```typescript
/**
 * MCP Server Template
 * Use this as a starting point for creating new MCP servers
 */

import { 
  MCPServer, 
  MCPServerOptions,
  Tool,
  Resource,
  MCPError 
} from '@modelcontextprotocol/sdk';
import WebSocket from 'ws';
import { createServer } from 'http';
import express from 'express';
import winston from 'winston';

interface ServerConfig extends MCPServerOptions {
  port: number;
  host: string;
  name: string;
  version: string;
  description: string;
}

export class CustomMCPServer {
  private config: ServerConfig;
  private app: express.Application;
  private server: any;
  private wss: WebSocket.Server;
  private logger: winston.Logger;
  private tools: Map<string, Tool> = new Map();
  private resources: Map<string, Resource> = new Map();

  constructor(config: ServerConfig) {
    this.config = config;
    this.logger = this.setupLogger();
    this.app = express();
    this.server = createServer(this.app);
    this.wss = new WebSocket.Server({ server: this.server });
    
    this.setupServer();
    this.registerTools();
    this.registerResources();
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

  private setupServer(): void {
    // Health check
    this.app.get('/health', (req, res) => {
      res.json({ status: 'healthy', version: this.config.version });
    });

    // WebSocket handling
    this.wss.on('connection', (ws, request) => {
      this.logger.info('New connection', {
        ip: request.socket.remoteAddress
      });

      ws.on('message', async (data) => {
        try {
          const message = JSON.parse(data.toString());
          const response = await this.handleRequest(message);
          ws.send(JSON.stringify(response));
        } catch (error: any) {
          ws.send(JSON.stringify({
            jsonrpc: '2.0',
            error: {
              code: -32700,
              message: 'Parse error'
            }
          }));
        }
      });

      ws.on('close', () => {
        this.logger.info('Connection closed');
      });
    });
  }

  private async handleRequest(request: any): Promise<any> {
    // Validate JSON-RPC
    if (request.jsonrpc !== '2.0') {
      return {
        jsonrpc: '2.0',
        id: request.id,
        error: {
          code: -32600,
          message: 'Invalid Request'
        }
      };
    }

    try {
      const result = await this.processMethod(request.method, request.params);
      
      return {
        jsonrpc: '2.0',
        id: request.id,
        result
      };
    } catch (error: any) {
      return {
        jsonrpc: '2.0',
        id: request.id,
        error: {
          code: error.code || -32603,
          message: error.message || 'Internal error',
          data: error.data
        }
      };
    }
  }

  private async processMethod(method: string, params: any): Promise<any> {
    switch (method) {
      case 'initialize':
        return this.handleInitialize(params);
      
      case 'tools/list':
        return this.handleListTools();
      
      case 'tools/execute':
        return this.handleExecuteTool(params);
      
      case 'resources/list':
        return this.handleListResources();
      
      case 'resources/get':
        return this.handleGetResource(params);
      
      default:
        throw new MCPError(-32601, 'Method not found');
    }
  }

  private handleInitialize(params: any): any {
    return {
      protocolVersion: '1.0',
      serverInfo: {
        name: this.config.name,
        version: this.config.version,
        description: this.config.description
      },
      capabilities: {
        tools: true,
        resources: true,
        streaming: false
      }
    };
  }

  private handleListTools(): any {
    return Array.from(this.tools.values()).map(tool => ({
      name: tool.name,
      description: tool.description,
      inputSchema: tool.inputSchema
    }));
  }

  private async handleExecuteTool(params: any): Promise<any> {
    const tool = this.tools.get(params.name);
    
    if (!tool) {
      throw new MCPError(-32602, 'Tool not found');
    }
    
    return await tool.execute(params.arguments);
  }

  private handleListResources(): any {
    return Array.from(this.resources.values()).map(resource => ({
      id: resource.id,
      name: resource.name,
      description: resource.description,
      mimeType: resource.mimeType
    }));
  }

  private async handleGetResource(params: any): Promise<any> {
    const resource = this.resources.get(params.id);
    
    if (!resource) {
      throw new MCPError(-32602, 'Resource not found');
    }
    
    return await resource.getData();
  }

  private registerTools(): void {
    // Register your tools here
    // Example:
    // this.tools.set('example_tool', new ExampleTool());
  }

  private registerResources(): void {
    // Register your resources here
    // Example:
    // this.resources.set('example_resource', new ExampleResource());
  }

  async start(): Promise<void> {
    return new Promise((resolve) => {
      this.server.listen(this.config.port, this.config.host, () => {
        this.logger.info(`MCP Server started on ${this.config.host}:${this.config.port}`);
        resolve();
      });
    });
  }

  async stop(): Promise<void> {
    this.wss.close();
    return new Promise((resolve) => {
      this.server.close(() => {
        this.logger.info('MCP Server stopped');
        resolve();
      });
    });
  }
}

// Example usage
async function main() {
  const server = new CustomMCPServer({
    port: 3000,
    host: 'localhost',
    name: 'custom-mcp-server',
    version: '1.0.0',
    description: 'Custom MCP Server'
  });

  await server.start();
}

if (require.main === module) {
  main().catch(console.error);
}
```

### mcp-client-template.ts
```typescript
/**
 * MCP Client Template
 * Use this as a starting point for creating MCP clients
 */

import WebSocket from 'ws';
import { EventEmitter } from 'events';

interface ClientConfig {
  url: string;
  timeout?: number;
  reconnect?: boolean;
  reconnectInterval?: number;
  maxReconnectAttempts?: number;
}

interface MCPRequest {
  jsonrpc: '2.0';
  method: string;
  params?: any;
  id: string | number;
}

interface MCPResponse {
  jsonrpc: '2.0';
  id: string | number;
  result?: any;
  error?: {
    code: number;
    message: string;
    data?: any;
  };
}

export class MCPClient extends EventEmitter {
  private config: ClientConfig;
  private ws?: WebSocket;
  private requestId = 0;
  private pendingRequests = new Map<string | number, {
    resolve: (value: any) => void;
    reject: (error: any) => void;
    timeout: NodeJS.Timeout;
  }>();
  private reconnectAttempts = 0;
  private isConnected = false;

  constructor(config: ClientConfig) {
    super();
    this.config = {
      timeout: 30000,
      reconnect: true,
      reconnectInterval: 5000,
      maxReconnectAttempts: 5,
      ...config
    };
  }

  async connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      this.ws = new WebSocket(this.config.url);

      this.ws.on('open', () => {
        this.isConnected = true;
        this.reconnectAttempts = 0;
        this.emit('connected');
        resolve();
      });

      this.ws.on('message', (data) => {
        try {
          const response: MCPResponse = JSON.parse(data.toString());
          this.handleResponse(response);
        } catch (error) {
          this.emit('error', new Error('Invalid response format'));
        }
      });

      this.ws.on('close', () => {
        this.isConnected = false;
        this.emit('disconnected');
        this.handleDisconnect();
      });

      this.ws.on('error', (error) => {
        this.emit('error', error);
        if (!this.isConnected) {
          reject(error);
        }
      });
    });
  }

  async disconnect(): Promise<void> {
    if (this.ws) {
      this.config.reconnect = false;
      this.ws.close();
      this.ws = undefined;
    }
  }

  async request(method: string, params?: any): Promise<any> {
    if (!this.isConnected || !this.ws) {
      throw new Error('Not connected to MCP server');
    }

    const id = ++this.requestId;
    const request: MCPRequest = {
      jsonrpc: '2.0',
      method,
      params,
      id
    };

    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        this.pendingRequests.delete(id);
        reject(new Error(`Request timeout: ${method}`));
      }, this.config.timeout!);

      this.pendingRequests.set(id, { resolve, reject, timeout });
      
      this.ws!.send(JSON.stringify(request), (error) => {
        if (error) {
          clearTimeout(timeout);
          this.pendingRequests.delete(id);
          reject(error);
        }
      });
    });
  }

  async initialize(clientInfo?: any): Promise<any> {
    return this.request('initialize', {
      clientInfo: clientInfo || {
        name: 'mcp-client',
        version: '1.0.0'
      }
    });
  }

  async listTools(): Promise<any[]> {
    return this.request('tools/list');
  }

  async executeTool(name: string, args: any): Promise<any> {
    return this.request('tools/execute', {
      name,
      arguments: args
    });
  }

  async listResources(): Promise<any[]> {
    return this.request('resources/list');
  }

  async getResource(id: string): Promise<any> {
    return this.request('resources/get', { id });
  }

  private handleResponse(response: MCPResponse): void {
    const pending = this.pendingRequests.get(response.id);
    
    if (!pending) {
      this.emit('error', new Error(`No pending request for id: ${response.id}`));
      return;
    }

    clearTimeout(pending.timeout);
    this.pendingRequests.delete(response.id);

    if (response.error) {
      pending.reject(new Error(`${response.error.message} (${response.error.code})`));
    } else {
      pending.resolve(response.result);
    }
  }

  private handleDisconnect(): void {
    // Clear all pending requests
    for (const [id, pending] of this.pendingRequests) {
      clearTimeout(pending.timeout);
      pending.reject(new Error('Connection lost'));
    }
    this.pendingRequests.clear();

    // Attempt reconnection
    if (this.config.reconnect && 
        this.reconnectAttempts < this.config.maxReconnectAttempts!) {
      this.reconnectAttempts++;
      
      setTimeout(() => {
        this.emit('reconnecting', this.reconnectAttempts);
        this.connect().catch(() => {
          // Reconnection failed, will retry
        });
      }, this.config.reconnectInterval);
    }
  }
}

// Example usage
async function main() {
  const client = new MCPClient({
    url: 'ws://localhost:3000'
  });

  client.on('connected', () => {
    console.log('Connected to MCP server');
  });

  client.on('disconnected', () => {
    console.log('Disconnected from MCP server');
  });

  client.on('error', (error) => {
    console.error('Client error:', error);
  });

  try {
    await client.connect();
    
    // Initialize session
    const initResult = await client.initialize();
    console.log('Initialized:', initResult);
    
    // List available tools
    const tools = await client.listTools();
    console.log('Available tools:', tools);
    
    // Execute a tool
    const result = await client.executeTool('example_tool', {
      param1: 'value1'
    });
    console.log('Tool result:', result);
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.disconnect();
  }
}

if (require.main === module) {
  main().catch(console.error);
}
```

## 📋 resources/protocol-specs/

### mcp-message-format.md
```markdown
# MCP Message Format Specification

## Overview

MCP uses JSON-RPC 2.0 as its message format. All messages are JSON objects with specific structure.

## Request Format

```json
{
  "jsonrpc": "2.0",
  "method": "method_name",
  "params": {
    // Method-specific parameters
  },
  "id": 1
}
```

### Fields:
- `jsonrpc`: MUST be exactly "2.0"
- `method`: String containing the method name
- `params`: Object containing method parameters (optional)
- `id`: Unique identifier for the request (string or number)

## Response Format

### Success Response
```json
{
  "jsonrpc": "2.0",
  "result": {
    // Method-specific result
  },
  "id": 1
}
```

### Error Response
```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32601,
    "message": "Method not found",
    "data": {
      // Additional error information
    }
  },
  "id": 1
}
```

## Standard Error Codes

| Code | Message | Description |
|------|---------|-------------|
| -32700 | Parse error | Invalid JSON |
| -32600 | Invalid Request | Not a valid Request object |
| -32601 | Method not found | Method does not exist |
| -32602 | Invalid params | Invalid method parameters |
| -32603 | Internal error | Internal JSON-RPC error |

## MCP-Specific Methods

### Initialize
```json
{
  "jsonrpc": "2.0",
  "method": "initialize",
  "params": {
    "clientInfo": {
      "name": "client-name",
      "version": "1.0.0"
    }
  },
  "id": 1
}
```

### List Tools
```json
{
  "jsonrpc": "2.0",
  "method": "tools/list",
  "id": 2
}
```

### Execute Tool
```json
{
  "jsonrpc": "2.0",
  "method": "tools/execute",
  "params": {
    "name": "tool_name",
    "arguments": {
      // Tool-specific arguments
    }
  },
  "id": 3
}
```

### List Resources
```json
{
  "jsonrpc": "2.0",
  "method": "resources/list",
  "id": 4
}
```

### Get Resource
```json
{
  "jsonrpc": "2.0",
  "method": "resources/get",
  "params": {
    "id": "resource_id"
  },
  "id": 5
}
```

## Notifications

Notifications are requests without an `id` field. No response is expected.

```json
{
  "jsonrpc": "2.0",
  "method": "notification_method",
  "params": {
    // Notification data
  }
}
```

## Batch Requests

Multiple requests can be sent as an array:

```json
[
  {"jsonrpc": "2.0", "method": "tools/list", "id": 1},
  {"jsonrpc": "2.0", "method": "resources/list", "id": 2}
]
```

The response will be an array of responses in any order.
```

### mcp-tool-schema.json
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "MCP Tool Definition",
  "type": "object",
  "required": ["name", "description", "inputSchema"],
  "properties": {
    "name": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_.-]+$",
      "minLength": 1,
      "maxLength": 100,
      "description": "Unique identifier for the tool"
    },
    "description": {
      "type": "string",
      "minLength": 1,
      "maxLength": 1000,
      "description": "Human-readable description of what the tool does"
    },
    "inputSchema": {
      "$ref": "http://json-schema.org/draft-07/schema#",
      "description": "JSON Schema defining the tool's input parameters"
    },
    "outputSchema": {
      "$ref": "http://json-schema.org/draft-07/schema#",
      "description": "JSON Schema defining the tool's output format"
    },
    "examples": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["input", "output"],
        "properties": {
          "description": {
            "type": "string"
          },
          "input": {
            "type": "object"
          },
          "output": {}
        }
      }
    },
    "errors": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["code", "message"],
        "properties": {
          "code": {
            "type": "string"
          },
          "message": {
            "type": "string"
          }
        }
      }
    }
  }
}
```

## 🧪 resources/testing-tools/

### mcp-test-client.ts
```typescript
#!/usr/bin/env node
/**
 * MCP Test Client
 * Command-line tool for testing MCP servers
 */

import { MCPClient } from '../mcp-templates/mcp-client-template';
import readline from 'readline';
import { program } from 'commander';
import chalk from 'chalk';

program
  .version('1.0.0')
  .description('MCP Server Test Client')
  .option('-u, --url <url>', 'MCP server URL', 'ws://localhost:3000')
  .option('-v, --verbose', 'Enable verbose logging')
  .parse(process.argv);

const options = program.opts();

class MCPTestClient {
  private client: MCPClient;
  private rl: readline.Interface;

  constructor(url: string) {
    this.client = new MCPClient({ url });
    this.rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
      prompt: chalk.blue('mcp> ')
    });

    this.setupEventHandlers();
  }

  private setupEventHandlers(): void {
    this.client.on('connected', () => {
      console.log(chalk.green('✓ Connected to MCP server'));
      this.showCommands();
      this.rl.prompt();
    });

    this.client.on('disconnected', () => {
      console.log(chalk.red('✗ Disconnected from server'));
    });

    this.client.on('error', (error) => {
      console.error(chalk.red('Error:'), error.message);
    });

    if (options.verbose) {
      this.client.on('reconnecting', (attempt) => {
        console.log(chalk.yellow(`Reconnecting... (attempt ${attempt})`));
      });
    }
  }

  private showCommands(): void {
    console.log(chalk.cyan('\nAvailable commands:'));
    console.log('  init          - Initialize session');
    console.log('  tools         - List available tools');
    console.log('  tool <name>   - Execute a tool');
    console.log('  resources     - List available resources');
    console.log('  get <id>      - Get a resource');
    console.log('  help          - Show this help');
    console.log('  exit          - Exit the client\n');
  }

  async start(): Promise<void> {
    try {
      console.log(chalk.cyan(`Connecting to ${options.url}...`));
      await this.client.connect();

      this.rl.on('line', async (line) => {
        const [command, ...args] = line.trim().split(' ');

        try {
          switch (command) {
            case 'init':
              await this.handleInit();
              break;

            case 'tools':
              await this.handleListTools();
              break;

            case 'tool':
              await this.handleExecuteTool(args[0]);
              break;

            case 'resources':
              await this.handleListResources();
              break;

            case 'get':
              await this.handleGetResource(args[0]);
              break;

            case 'help':
              this.showCommands();
              break;

            case 'exit':
            case 'quit':
              await this.client.disconnect();
              process.exit(0);

            default:
              if (command) {
                console.log(chalk.red(`Unknown command: ${command}`));
              }
          }
        } catch (error: any) {
          console.error(chalk.red('Error:'), error.message);
        }

        this.rl.prompt();
      });

    } catch (error) {
      console.error(chalk.red('Failed to connect:'), error);
      process.exit(1);
    }
  }

  private async handleInit(): Promise<void> {
    const result = await this.client.initialize({
      name: 'mcp-test-client',
      version: '1.0.0'
    });
    
    console.log(chalk.green('Initialized:'));
    console.log(JSON.stringify(result, null, 2));
  }

  private async handleListTools(): Promise<void> {
    const tools = await this.client.listTools();
    
    if (tools.length === 0) {
      console.log(chalk.yellow('No tools available'));
      return;
    }

    console.log(chalk.green(`\nAvailable tools (${tools.length}):`));
    for (const tool of tools) {
      console.log(chalk.cyan(`\n${tool.name}`));
      console.log(`  ${tool.description}`);
      
      if (options.verbose && tool.inputSchema) {
        console.log(chalk.gray('  Parameters:'));
        console.log(chalk.gray(JSON.stringify(tool.inputSchema, null, 4)
          .split('\n')
          .map(line => '    ' + line)
          .join('\n')));
      }
    }
  }

  private async handleExecuteTool(toolName: string): Promise<void> {
    if (!toolName) {
      console.log(chalk.red('Usage: tool <name>'));
      return;
    }

    // Get tool parameters from user
    const params: any = {};
    
    console.log(chalk.cyan(`Enter parameters for ${toolName} (JSON format):`));
    
    const input = await new Promise<string>((resolve) => {
      this.rl.question('> ', resolve);
    });

    try {
      const args = input ? JSON.parse(input) : {};
      const result = await this.client.executeTool(toolName, args);
      
      console.log(chalk.green('\nResult:'));
      console.log(JSON.stringify(result, null, 2));
    } catch (error: any) {
      if (error.message.includes('JSON')) {
        console.error(chalk.red('Invalid JSON format'));
      } else {
        throw error;
      }
    }
  }

  private async handleListResources(): Promise<void> {
    const resources = await this.client.listResources();
    
    if (resources.length === 0) {
      console.log(chalk.yellow('No resources available'));
      return;
    }

    console.log(chalk.green(`\nAvailable resources (${resources.length}):`));
    for (const resource of resources) {
      console.log(chalk.cyan(`\n${resource.id}`));
      console.log(`  Name: ${resource.name}`);
      console.log(`  Type: ${resource.mimeType}`);
      console.log(`  ${resource.description}`);
    }
  }

  private async handleGetResource(resourceId: string): Promise<void> {
    if (!resourceId) {
      console.log(chalk.red('Usage: get <resource-id>'));
      return;
    }

    const resource = await this.client.getResource(resourceId);
    
    console.log(chalk.green('\nResource content:'));
    console.log(JSON.stringify(resource, null, 2));
  }
}

// Start the client
const client = new MCPTestClient(options.url);
client.start().catch(console.error);
```

### mcp-load-test.ts
```typescript
/**
 * MCP Load Testing Tool
 * Tests server performance under load
 */

import { MCPClient } from '../mcp-templates/mcp-client-template';
import { performance } from 'perf_hooks';

interface LoadTestConfig {
  url: string;
  clients: number;
  requestsPerClient: number;
  tool: string;
  toolArgs: any;
}

class MCPLoadTester {
  private config: LoadTestConfig;
  private results: any[] = [];

  constructor(config: LoadTestConfig) {
    this.config = config;
  }

  async run(): Promise<void> {
    console.log('Starting load test...');
    console.log(`Clients: ${this.config.clients}`);
    console.log(`Requests per client: ${this.config.requestsPerClient}`);
    console.log(`Total requests: ${this.config.clients * this.config.requestsPerClient}`);
    
    const startTime = performance.now();
    
    // Create and run clients in parallel
    const clientPromises = [];
    
    for (let i = 0; i < this.config.clients; i++) {
      clientPromises.push(this.runClient(i));
    }
    
    await Promise.all(clientPromises);
    
    const endTime = performance.now();
    const totalTime = endTime - startTime;
    
    this.printResults(totalTime);
  }

  private async runClient(clientId: number): Promise<void> {
    const client = new MCPClient({ 
      url: this.config.url,
      reconnect: false 
    });
    
    try {
      await client.connect();
      await client.initialize();
      
      for (let i = 0; i < this.config.requestsPerClient; i++) {
        const start = performance.now();
        
        try {
          await client.executeTool(this.config.tool, this.config.toolArgs);
          const duration = performance.now() - start;
          
          this.results.push({
            clientId,
            requestId: i,
            success: true,
            duration
          });
        } catch (error) {
          const duration = performance.now() - start;
          
          this.results.push({
            clientId,
            requestId: i,
            success: false,
            duration,
            error: error.message
          });
        }
      }
    } finally {
      await client.disconnect();
    }
  }

  private printResults(totalTime: number): void {
    const successful = this.results.filter(r => r.success).length;
    const failed = this.results.filter(r => !r.success).length;
    const durations = this.results.map(r => r.duration);
    
    const avg = durations.reduce((a, b) => a + b, 0) / durations.length;
    const sorted = durations.sort((a, b) => a - b);
    const p50 = sorted[Math.floor(sorted.length * 0.5)];
    const p95 = sorted[Math.floor(sorted.length * 0.95)];
    const p99 = sorted[Math.floor(sorted.length * 0.99)];
    
    console.log('\n=== Load Test Results ===');
    console.log(`Total time: ${(totalTime / 1000).toFixed(2)}s`);
    console.log(`Successful requests: ${successful}`);
    console.log(`Failed requests: ${failed}`);
    console.log(`Requests/second: ${(this.results.length / (totalTime / 1000)).toFixed(2)}`);
    console.log('\nLatency (ms):');
    console.log(`  Average: ${avg.toFixed(2)}`);
    console.log(`  P50: ${p50.toFixed(2)}`);
    console.log(`  P95: ${p95.toFixed(2)}`);
    console.log(`  P99: ${p99.toFixed(2)}`);
    
    if (failed > 0) {
      console.log('\nErrors:');
      const errors = this.results
        .filter(r => !r.success)
        .reduce((acc, r) => {
          acc[r.error] = (acc[r.error] || 0) + 1;
          return acc;
        }, {} as any);
      
      for (const [error, count] of Object.entries(errors)) {
        console.log(`  ${error}: ${count}`);
      }
    }
  }
}

// CLI usage
if (require.main === module) {
  const config: LoadTestConfig = {
    url: process.env.MCP_URL || 'ws://localhost:3000',
    clients: parseInt(process.env.CLIENTS || '10'),
    requestsPerClient: parseInt(process.env.REQUESTS || '100'),
    tool: process.env.TOOL || 'echo',
    toolArgs: JSON.parse(process.env.TOOL_ARGS || '{}')
  };
  
  const tester = new MCPLoadTester(config);
  tester.run().catch(console.error);
}
```

## 🔒 resources/security-configs/

### mcp-security-best-practices.md
```markdown
# MCP Security Best Practices

## Authentication

### 1. Bearer Token Authentication
```typescript
// Server implementation
class AuthenticatedMCPServer {
  private validateToken(token: string): boolean {
    // Implement JWT validation
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      return decoded.exp > Date.now() / 1000;
    } catch {
      return false;
    }
  }

  handleConnection(ws: WebSocket, request: IncomingMessage) {
    const auth = request.headers.authorization;
    
    if (!auth || !auth.startsWith('Bearer ')) {
      ws.close(1008, 'Unauthorized');
      return;
    }
    
    const token = auth.substring(7);
    
    if (!this.validateToken(token)) {
      ws.close(1008, 'Invalid token');
      return;
    }
    
    // Continue with authenticated connection
  }
}
```

### 2. Mutual TLS (mTLS)
```typescript
// Server configuration
const server = https.createServer({
  cert: fs.readFileSync('server-cert.pem'),
  key: fs.readFileSync('server-key.pem'),
  ca: fs.readFileSync('ca-cert.pem'),
  requestCert: true,
  rejectUnauthorized: true
});
```

## Authorization

### 1. Tool-Level Permissions
```typescript
interface Permission {
  tool: string;
  actions: string[];
  constraints?: any;
}

class AuthorizationService {
  private permissions: Map<string, Permission[]> = new Map();
  
  canExecuteTool(userId: string, tool: string): boolean {
    const userPerms = this.permissions.get(userId) || [];
    return userPerms.some(p => p.tool === tool || p.tool === '*');
  }
  
  applyConstraints(userId: string, tool: string, params: any): any {
    const perm = this.permissions.get(userId)?.find(p => p.tool === tool);
    
    if (perm?.constraints) {
      // Apply constraints to parameters
      if (perm.constraints.maxRows && params.limit) {
        params.limit = Math.min(params.limit, perm.constraints.maxRows);
      }
    }
    
    return params;
  }
}
```

### 2. Resource-Based Access Control
```typescript
interface ResourceACL {
  resourceId: string;
  permissions: {
    [userId: string]: string[]; // ['read', 'write', 'delete']
  };
}

class ResourceAuthorizationService {
  private acls: Map<string, ResourceACL> = new Map();
  
  canAccessResource(
    userId: string, 
    resourceId: string, 
    action: string
  ): boolean {
    const acl = this.acls.get(resourceId);
    
    if (!acl) {
      return false; // Deny by default
    }
    
    const userPerms = acl.permissions[userId] || [];
    return userPerms.includes(action) || userPerms.includes('*');
  }
}
```

## Input Validation

### 1. Schema Validation
```typescript
import Ajv from 'ajv';

const ajv = new Ajv();

const toolSchema = {
  type: 'object',
  properties: {
    name: { type: 'string', pattern: '^[a-zA-Z0-9_-]+$' },
    arguments: { type: 'object' }
  },
  required: ['name', 'arguments'],
  additionalProperties: false
};

function validateToolRequest(data: any): boolean {
  const validate = ajv.compile(toolSchema);
  return validate(data);
}
```

### 2. Sanitization
```typescript
function sanitizePath(input: string): string {
  // Remove dangerous characters
  return input
    .replace(/\.\./g, '')  // No parent directory
    .replace(/[<>:"|?*]/g, '')  // No special chars
    .replace(/\\/g, '/')  // Normalize slashes
    .replace(/\/+/g, '/');  // No double slashes
}

function sanitizeSQL(input: string): string {
  // Basic SQL injection prevention
  return input
    .replace(/'/g, "''")  // Escape quotes
    .replace(/;/g, '')  // No statement separation
    .replace(/--/g, '');  // No comments
}
```

## Rate Limiting

```typescript
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per window
  message: 'Too many requests'
});

// Per-tool rate limiting
class ToolRateLimiter {
  private limits = new Map<string, number>();
  private usage = new Map<string, Map<string, number[]>>();
  
  constructor() {
    // Configure limits per tool
    this.limits.set('expensive_operation', 10); // 10 per minute
    this.limits.set('default', 100); // 100 per minute
  }
  
  checkLimit(userId: string, tool: string): boolean {
    const limit = this.limits.get(tool) || this.limits.get('default')!;
    const now = Date.now();
    const windowStart = now - 60000; // 1 minute window
    
    if (!this.usage.has(userId)) {
      this.usage.set(userId, new Map());
    }
    
    const userUsage = this.usage.get(userId)!;
    const toolUsage = userUsage.get(tool) || [];
    
    // Remove old entries
    const recentUsage = toolUsage.filter(t => t > windowStart);
    
    if (recentUsage.length >= limit) {
      return false; // Rate limit exceeded
    }
    
    // Record usage
    recentUsage.push(now);
    userUsage.set(tool, recentUsage);
    
    return true;
  }
}
```

## Secure Communication

### 1. TLS Configuration
```typescript
const tlsOptions = {
  cert: fs.readFileSync('server.crt'),
  key: fs.readFileSync('server.key'),
  // Security hardening
  secureProtocol: 'TLSv1_2_method',
  ciphers: [
    'ECDHE-RSA-AES128-GCM-SHA256',
    'ECDHE-RSA-AES256-GCM-SHA384',
    'ECDHE-RSA-AES128-SHA256',
    'ECDHE-RSA-AES256-SHA384'
  ].join(':'),
  honorCipherOrder: true
};
```

### 2. Message Encryption
```typescript
import crypto from 'crypto';

class EncryptedMCPTransport {
  private algorithm = 'aes-256-gcm';
  private key: Buffer;
  
  constructor(secretKey: string) {
    this.key = crypto.scryptSync(secretKey, 'salt', 32);
  }
  
  encrypt(message: string): { encrypted: string; iv: string; tag: string } {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv(this.algorithm, this.key, iv);
    
    let encrypted = cipher.update(message, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    const tag = cipher.getAuthTag();
    
    return {
      encrypted,
      iv: iv.toString('hex'),
      tag: tag.toString('hex')
    };
  }
  
  decrypt(encrypted: string, iv: string, tag: string): string {
    const decipher = crypto.createDecipheriv(
      this.algorithm, 
      this.key, 
      Buffer.from(iv, 'hex')
    );
    
    decipher.setAuthTag(Buffer.from(tag, 'hex'));
    
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    
    return decrypted;
  }
}
```

## Audit Logging

```typescript
interface AuditLog {
  timestamp: Date;
  userId: string;
  clientId: string;
  action: string;
  resource?: string;
  tool?: string;
  parameters?: any;
  result: 'success' | 'failure';
  error?: string;
  ip: string;
  userAgent?: string;
}

class AuditLogger {
  async log(entry: AuditLog): Promise<void> {
    // Sanitize sensitive data
    const sanitized = {
      ...entry,
      parameters: this.sanitizeParams(entry.parameters)
    };
    
    // Log to persistent storage
    await this.writeToDatabase(sanitized);
    
    // Alert on suspicious activity
    if (this.isSuspicious(entry)) {
      await this.sendAlert(entry);
    }
  }
  
  private sanitizeParams(params: any): any {
    // Remove sensitive fields
    const sanitized = { ...params };
    delete sanitized.password;
    delete sanitized.token;
    delete sanitized.apiKey;
    
    return sanitized;
  }
  
  private isSuspicious(entry: AuditLog): boolean {
    // Check for suspicious patterns
    return (
      entry.result === 'failure' ||
      entry.action.includes('delete') ||
      entry.parameters?.path?.includes('..') ||
      entry.error?.includes('injection')
    );
  }
}
```

## Security Checklist

- [ ] Enable TLS for all connections
- [ ] Implement authentication (Bearer token, mTLS, or OAuth2)
- [ ] Add authorization checks for all tools and resources
- [ ] Validate all input parameters
- [ ] Sanitize file paths and SQL queries
- [ ] Implement rate limiting
- [ ] Add request size limits
- [ ] Enable audit logging
- [ ] Regularly update dependencies
- [ ] Conduct security audits
- [ ] Implement error handling that doesn't leak information
- [ ] Use secure random generators for IDs and tokens
- [ ] Set appropriate CORS policies
- [ ] Implement request timeouts
- [ ] Monitor for anomalous behavior
```

## 📚 Additional Scripts

### scripts/generate-certs.sh
```bash
#!/bin/bash
# Generate self-signed certificates for development

# Create directory for certificates
mkdir -p certs

# Generate CA private key
openssl genrsa -out certs/ca-key.pem 4096

# Generate CA certificate
openssl req -new -x509 -days 365 -key certs/ca-key.pem -out certs/ca-cert.pem \
  -subj "/C=US/ST=State/L=City/O=MCP Development/CN=MCP CA"

# Generate server private key
openssl genrsa -out certs/server-key.pem 4096

# Generate server certificate request
openssl req -new -key certs/server-key.pem -out certs/server-csr.pem \
  -subj "/C=US/ST=State/L=City/O=MCP Development/CN=localhost"

# Sign server certificate
openssl x509 -req -days 365 -in certs/server-csr.pem \
  -CA certs/ca-cert.pem -CAkey certs/ca-key.pem \
  -CAcreateserial -out certs/server-cert.pem

# Generate client private key
openssl genrsa -out certs/client-key.pem 4096

# Generate client certificate request
openssl req -new -key certs/client-key.pem -out certs/client-csr.pem \
  -subj "/C=US/ST=State/L=City/O=MCP Development/CN=MCP Client"

# Sign client certificate
openssl x509 -req -days 365 -in certs/client-csr.pem \
  -CA certs/ca-cert.pem -CAkey certs/ca-key.pem \
  -CAcreateserial -out certs/client-cert.pem

# Clean up
rm certs/*-csr.pem
rm certs/ca-cert.srl

echo "Certificates generated in ./certs/"
echo "  CA Certificate: certs/ca-cert.pem"
echo "  Server Certificate: certs/server-cert.pem"
echo "  Server Key: certs/server-key.pem"
echo "  Client Certificate: certs/client-cert.pem"
echo "  Client Key: certs/client-key.pem"
```

These resources provide comprehensive templates, specifications, and tools for working with MCP in Module 23!