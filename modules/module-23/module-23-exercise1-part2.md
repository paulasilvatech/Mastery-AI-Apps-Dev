# Exercise 1: File System MCP Server - Part 2

## 🛠️ Continuing Implementation

### Step 5: Implement Tool System

**Copilot Prompt Suggestion:**
```typescript
// Create a tool system that:
// - Defines a base Tool interface
// - Implements tool registration and discovery
// - Validates tool parameters using JSON Schema
// - Handles tool execution with proper error handling
// - Supports async tool operations
// - Provides tool metadata and documentation
```

Create `src/tools/Tool.ts`:
```typescript
import Joi from 'joi';

export interface ToolParameter {
  name: string;
  type: 'string' | 'number' | 'boolean' | 'object' | 'array';
  description: string;
  required?: boolean;
  default?: any;
  schema?: Joi.Schema;
}

export interface ToolDefinition {
  name: string;
  description: string;
  parameters: ToolParameter[];
  returns: {
    type: string;
    description: string;
  };
  examples?: ToolExample[];
}

export interface ToolExample {
  params: any;
  result: any;
  description?: string;
}

export interface ToolContext {
  connectionId: string;
  userId?: string;
  timestamp: Date;
}

export abstract class Tool {
  constructor(public definition: ToolDefinition) {}

  abstract execute(params: any, context: ToolContext): Promise<any>;

  validateParams(params: any): void {
    const schema = this.buildValidationSchema();
    const { error } = schema.validate(params);
    
    if (error) {
      throw new ToolError(
        `Invalid parameters: ${error.message}`,
        'INVALID_PARAMETERS',
        error.details
      );
    }
  }

  private buildValidationSchema(): Joi.Schema {
    const schemaObj: any = {};
    
    for (const param of this.definition.parameters) {
      let paramSchema: Joi.Schema;
      
      switch (param.type) {
        case 'string':
          paramSchema = Joi.string();
          break;
        case 'number':
          paramSchema = Joi.number();
          break;
        case 'boolean':
          paramSchema = Joi.boolean();
          break;
        case 'object':
          paramSchema = Joi.object();
          break;
        case 'array':
          paramSchema = Joi.array();
          break;
        default:
          paramSchema = Joi.any();
      }
      
      if (param.schema) {
        paramSchema = param.schema;
      }
      
      if (param.required) {
        paramSchema = paramSchema.required();
      } else if (param.default !== undefined) {
        paramSchema = paramSchema.default(param.default);
      }
      
      schemaObj[param.name] = paramSchema;
    }
    
    return Joi.object(schemaObj);
  }

  toJSON(): any {
    return {
      name: this.definition.name,
      description: this.definition.description,
      parameters: this.definition.parameters.map(p => ({
        name: p.name,
        type: p.type,
        description: p.description,
        required: p.required || false,
        default: p.default
      })),
      returns: this.definition.returns,
      examples: this.definition.examples
    };
  }
}

export class ToolError extends Error {
  constructor(
    message: string, 
    public code: string, 
    public details?: any
  ) {
    super(message);
    this.name = 'ToolError';
  }
}

export class ToolRegistry {
  private tools: Map<string, Tool> = new Map();

  register(tool: Tool): void {
    if (this.tools.has(tool.definition.name)) {
      throw new Error(`Tool ${tool.definition.name} already registered`);
    }
    
    this.tools.set(tool.definition.name, tool);
  }

  get(name: string): Tool | undefined {
    return this.tools.get(name);
  }

  list(): ToolDefinition[] {
    return Array.from(this.tools.values()).map(tool => tool.definition);
  }

  async execute(
    name: string, 
    params: any, 
    context: ToolContext
  ): Promise<any> {
    const tool = this.tools.get(name);
    
    if (!tool) {
      throw new ToolError(
        `Tool not found: ${name}`,
        'TOOL_NOT_FOUND'
      );
    }
    
    // Validate parameters
    tool.validateParams(params);
    
    // Execute tool
    return tool.execute(params, context);
  }
}
```

### Step 6: Implement File System Tools

**Copilot Prompt Suggestion:**
```typescript
// Create file system tools that:
// - Read files with encoding support
// - Write files with atomic operations
// - List directory contents with filtering
// - Search files by pattern with glob support
// - Get file metadata (size, modified date, etc.)
// All with proper security validation
```

Create `src/tools/ReadFileTool.ts`:
```typescript
import { Tool, ToolDefinition, ToolContext } from './Tool';
import { FileSystemSecurity, SecurityContext } from '../security/FileSystemSecurity';
import fs from 'fs/promises';
import Joi from 'joi';

export class ReadFileTool extends Tool {
  constructor(private security: FileSystemSecurity) {
    super({
      name: 'file.read',
      description: 'Read the contents of a file',
      parameters: [
        {
          name: 'path',
          type: 'string',
          description: 'Path to the file to read',
          required: true,
          schema: Joi.string().min(1).max(1000)
        },
        {
          name: 'encoding',
          type: 'string',
          description: 'File encoding (default: utf8)',
          required: false,
          default: 'utf8',
          schema: Joi.string().valid(
            'utf8', 'utf-8', 'ascii', 'base64', 
            'hex', 'binary', 'latin1'
          )
        }
      ],
      returns: {
        type: 'object',
        description: 'File content and metadata'
      },
      examples: [
        {
          params: { path: 'documents/readme.md' },
          result: { 
            content: '# README\n\nThis is a test file.', 
            encoding: 'utf8',
            size: 24 
          }
        }
      ]
    });
  }

  async execute(params: any, context: ToolContext): Promise<any> {
    const { path: filePath, encoding } = params;
    
    // Create security context
    const securityContext: SecurityContext = {
      connectionId: context.connectionId,
      userId: context.userId,
      operation: 'file.read',
      timestamp: context.timestamp
    };
    
    // Validate access
    const resolvedPath = await this.security.validateReadAccess(
      filePath, 
      securityContext
    );
    
    // Read file
    const content = await fs.readFile(resolvedPath, encoding);
    const stats = await fs.stat(resolvedPath);
    
    return {
      content,
      encoding,
      size: stats.size,
      modified: stats.mtime.toISOString(),
      created: stats.birthtime.toISOString()
    };
  }
}
```

Create `src/tools/WriteFileTool.ts`:
```typescript
import { Tool, ToolDefinition, ToolContext } from './Tool';
import { FileSystemSecurity, SecurityContext } from '../security/FileSystemSecurity';
import fs from 'fs/promises';
import path from 'path';
import { nanoid } from 'nanoid';
import Joi from 'joi';

export class WriteFileTool extends Tool {
  constructor(private security: FileSystemSecurity) {
    super({
      name: 'file.write',
      description: 'Write content to a file',
      parameters: [
        {
          name: 'path',
          type: 'string',
          description: 'Path to the file to write',
          required: true,
          schema: Joi.string().min(1).max(1000)
        },
        {
          name: 'content',
          type: 'string',
          description: 'Content to write to the file',
          required: true,
          schema: Joi.string().max(10 * 1024 * 1024) // 10MB limit
        },
        {
          name: 'encoding',
          type: 'string',
          description: 'File encoding (default: utf8)',
          required: false,
          default: 'utf8',
          schema: Joi.string().valid(
            'utf8', 'utf-8', 'ascii', 'base64', 
            'hex', 'binary', 'latin1'
          )
        },
        {
          name: 'mode',
          type: 'string',
          description: 'Write mode: overwrite or append',
          required: false,
          default: 'overwrite',
          schema: Joi.string().valid('overwrite', 'append')
        },
        {
          name: 'createDirectories',
          type: 'boolean',
          description: 'Create parent directories if they don\'t exist',
          required: false,
          default: false
        }
      ],
      returns: {
        type: 'object',
        description: 'Write operation result'
      }
    });
  }

  async execute(params: any, context: ToolContext): Promise<any> {
    const { 
      path: filePath, 
      content, 
      encoding, 
      mode,
      createDirectories 
    } = params;
    
    // Create security context
    const securityContext: SecurityContext = {
      connectionId: context.connectionId,
      userId: context.userId,
      operation: 'file.write',
      timestamp: context.timestamp
    };
    
    // Validate access
    const resolvedPath = await this.security.validateWriteAccess(
      filePath, 
      content,
      securityContext
    );
    
    // Create directories if requested
    if (createDirectories) {
      const dir = path.dirname(resolvedPath);
      await fs.mkdir(dir, { recursive: true });
    }
    
    // Atomic write operation
    const tempPath = `${resolvedPath}.${nanoid()}.tmp`;
    
    try {
      if (mode === 'append') {
        // Read existing content first
        let existingContent = '';
        try {
          existingContent = await fs.readFile(resolvedPath, encoding);
        } catch (error: any) {
          if (error.code !== 'ENOENT') throw error;
        }
        
        await fs.writeFile(tempPath, existingContent + content, encoding);
      } else {
        await fs.writeFile(tempPath, content, encoding);
      }
      
      // Atomic rename
      await fs.rename(tempPath, resolvedPath);
      
      // Get file stats
      const stats = await fs.stat(resolvedPath);
      
      return {
        path: filePath,
        size: stats.size,
        modified: stats.mtime.toISOString(),
        hash: this.security.generateFileHash(content)
      };
    } catch (error) {
      // Clean up temp file on error
      try {
        await fs.unlink(tempPath);
      } catch {}
      
      throw error;
    }
  }
}
```

Create `src/tools/ListDirectoryTool.ts`:
```typescript
import { Tool, ToolDefinition, ToolContext } from './Tool';
import { FileSystemSecurity, SecurityContext } from '../security/FileSystemSecurity';
import fs from 'fs/promises';
import path from 'path';
import { minimatch } from 'minimatch';
import Joi from 'joi';

export class ListDirectoryTool extends Tool {
  constructor(private security: FileSystemSecurity) {
    super({
      name: 'directory.list',
      description: 'List contents of a directory',
      parameters: [
        {
          name: 'path',
          type: 'string',
          description: 'Path to the directory',
          required: true,
          schema: Joi.string().min(1).max(1000)
        },
        {
          name: 'pattern',
          type: 'string',
          description: 'Glob pattern to filter files',
          required: false,
          default: '*',
          schema: Joi.string().max(100)
        },
        {
          name: 'recursive',
          type: 'boolean',
          description: 'List files recursively',
          required: false,
          default: false
        },
        {
          name: 'includeHidden',
          type: 'boolean',
          description: 'Include hidden files (starting with .)',
          required: false,
          default: false
        },
        {
          name: 'maxDepth',
          type: 'number',
          description: 'Maximum depth for recursive listing',
          required: false,
          default: 3,
          schema: Joi.number().min(1).max(10)
        }
      ],
      returns: {
        type: 'array',
        description: 'Array of file/directory information'
      }
    });
  }

  async execute(params: any, context: ToolContext): Promise<any> {
    const { 
      path: dirPath, 
      pattern, 
      recursive,
      includeHidden,
      maxDepth 
    } = params;
    
    // Create security context
    const securityContext: SecurityContext = {
      connectionId: context.connectionId,
      userId: context.userId,
      operation: 'directory.list',
      timestamp: context.timestamp
    };
    
    // Validate access
    const resolvedPath = await this.security.validateDirectoryAccess(
      dirPath, 
      securityContext
    );
    
    // List directory
    const entries = await this.listDirectory(
      resolvedPath, 
      pattern, 
      recursive, 
      includeHidden,
      maxDepth,
      0
    );
    
    // Make paths relative to the requested directory
    return entries.map(entry => ({
      ...entry,
      path: path.relative(resolvedPath, entry.path).replace(/\\/g, '/')
    }));
  }

  private async listDirectory(
    dirPath: string,
    pattern: string,
    recursive: boolean,
    includeHidden: boolean,
    maxDepth: number,
    currentDepth: number
  ): Promise<any[]> {
    if (currentDepth > maxDepth) {
      return [];
    }
    
    const entries = await fs.readdir(dirPath, { withFileTypes: true });
    const results: any[] = [];
    
    for (const entry of entries) {
      // Skip hidden files if not requested
      if (!includeHidden && entry.name.startsWith('.')) {
        continue;
      }
      
      const fullPath = path.join(dirPath, entry.name);
      
      // Check pattern match
      if (!minimatch(entry.name, pattern)) {
        // For directories, still recurse if recursive is true
        if (recursive && entry.isDirectory()) {
          const subEntries = await this.listDirectory(
            fullPath,
            pattern,
            recursive,
            includeHidden,
            maxDepth,
            currentDepth + 1
          );
          results.push(...subEntries);
        }
        continue;
      }
      
      const stats = await fs.stat(fullPath);
      
      results.push({
        name: entry.name,
        path: fullPath,
        type: entry.isDirectory() ? 'directory' : 'file',
        size: stats.size,
        modified: stats.mtime.toISOString(),
        created: stats.birthtime.toISOString()
      });
      
      // Recurse into directories
      if (recursive && entry.isDirectory()) {
        const subEntries = await this.listDirectory(
          fullPath,
          pattern,
          recursive,
          includeHidden,
          maxDepth,
          currentDepth + 1
        );
        results.push(...subEntries);
      }
    }
    
    return results;
  }
}
```

### Step 7: Integrate Tools with Server

Update `src/server/MCPFileSystemServer.ts` to add tool processing:

```typescript
// Add these imports
import { ToolRegistry, ToolContext, ToolError } from '../tools/Tool';
import { ReadFileTool } from '../tools/ReadFileTool';
import { WriteFileTool } from '../tools/WriteFileTool';
import { ListDirectoryTool } from '../tools/ListDirectoryTool';

// Add to class properties
private toolRegistry: ToolRegistry;
private security: FileSystemSecurity;

// Update constructor
constructor(config: Partial<ServerConfig> = {}) {
  // ... existing code ...
  
  this.toolRegistry = new ToolRegistry();
  this.security = new FileSystemSecurity(
    {
      basePath: this.config.basePath,
      allowedPaths: this.config.allowedPaths,
      maxFileSize: this.config.maxFileSize,
      readOnly: false
    },
    this.logger
  );
}

// Update setupTools method
private setupTools(): void {
  // Register tools
  this.toolRegistry.register(new ReadFileTool(this.security));
  this.toolRegistry.register(new WriteFileTool(this.security));
  this.toolRegistry.register(new ListDirectoryTool(this.security));
  
  this.logger.info('Tools registered', {
    tools: this.toolRegistry.list().map(t => t.name)
  });
}

// Update processRequest method
private async processRequest(message: any): Promise<any> {
  const { method, params } = message;
  
  switch (method) {
    case 'rpc.discover':
      return this.handleDiscover();
      
    case 'tool.list':
      return this.handleListTools();
      
    case 'tool.execute':
      return this.handleExecuteTool(params, message.id);
      
    default:
      throw {
        code: -32601,
        message: 'Method not found',
        data: { method }
      };
  }
}

private handleDiscover(): any {
  return {
    version: '1.0.0',
    capabilities: this.getCapabilities(),
    tools: this.toolRegistry.list().map(t => t.name)
  };
}

private handleListTools(): any {
  return this.toolRegistry.list().map(tool => ({
    name: tool.name,
    description: tool.description,
    parameters: tool.parameters,
    returns: tool.returns,
    examples: tool.examples
  }));
}

private async handleExecuteTool(params: any, requestId: any): Promise<any> {
  if (!params || typeof params.name !== 'string') {
    throw {
      code: -32602,
      message: 'Invalid params',
      data: { message: 'Tool name is required' }
    };
  }
  
  const context: ToolContext = {
    connectionId: this.getConnectionId(requestId),
    timestamp: new Date()
  };
  
  try {
    const result = await this.toolRegistry.execute(
      params.name,
      params.arguments || {},
      context
    );
    
    return {
      toolName: params.name,
      result
    };
  } catch (error: any) {
    if (error instanceof ToolError) {
      throw {
        code: -32602,
        message: error.message,
        data: {
          toolError: error.code,
          details: error.details
        }
      };
    }
    
    throw error;
  }
}

// Update getRegisteredTools method
private getRegisteredTools(): string[] {
  return this.toolRegistry.list().map(t => t.name);
}
```

### Step 8: Create Server Entry Point

Create `src/index.ts`:
```typescript
import { MCPFileSystemServer } from './server/MCPFileSystemServer';
import { config } from './config';

async function main() {
  const server = new MCPFileSystemServer({
    port: config.server.port,
    host: config.server.host,
    basePath: config.fileSystem.basePath,
    allowedPaths: config.fileSystem.allowedPaths,
    maxFileSize: config.fileSystem.maxFileSize,
    enableLogging: config.logging.enabled,
    logLevel: config.logging.level
  });

  // Handle shutdown signals
  process.on('SIGTERM', async () => {
    console.log('SIGTERM received, shutting down gracefully...');
    await server.stop();
    process.exit(0);
  });

  process.on('SIGINT', async () => {
    console.log('SIGINT received, shutting down gracefully...');
    await server.stop();
    process.exit(0);
  });

  // Start server
  try {
    await server.start();
    console.log(`MCP File System Server running on ws://${config.server.host}:${config.server.port}`);
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

main().catch(console.error);
```

### Step 9: Add Package Scripts

Update `package.json`:
```json
{
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "nodemon --exec ts-node src/index.ts",
    "test": "jest",
    "test:watch": "jest --watch",
    "lint": "eslint src/**/*.ts",
    "format": "prettier --write src/**/*.ts"
  }
}
```

## 🏃 Running the Server

1. **Create workspace directory:**
```bash
mkdir -p workspace/documents workspace/projects workspace/config
echo "# Test Document" > workspace/documents/test.md
```

2. **Build and start the server:**
```bash
npm run build
npm start
```

3. **Test with a client:**
```typescript
// test-client.ts
import WebSocket from 'ws';

const ws = new WebSocket('ws://localhost:3000');

ws.on('open', () => {
  console.log('Connected to MCP server');
  
  // Discover capabilities
  ws.send(JSON.stringify({
    jsonrpc: '2.0',
    method: 'rpc.discover',
    id: 1
  }));
  
  // List tools
  ws.send(JSON.stringify({
    jsonrpc: '2.0',
    method: 'tool.list',
    id: 2
  }));
  
  // Read a file
  ws.send(JSON.stringify({
    jsonrpc: '2.0',
    method: 'tool.execute',
    params: {
      name: 'file.read',
      arguments: {
        path: 'documents/test.md'
      }
    },
    id: 3
  }));
});

ws.on('message', (data) => {
  console.log('Received:', JSON.parse(data.toString()));
});

ws.on('error', console.error);
```

## 🎯 Validation

Your MCP File System Server should now:
- ✅ Accept WebSocket connections
- ✅ Handle JSON-RPC 2.0 messages
- ✅ Expose file system tools through MCP
- ✅ Validate all file paths for security
- ✅ Prevent path traversal attacks
- ✅ Log all operations
- ✅ Handle errors gracefully

## 📚 Additional Resources

- [MCP Specification](https://github.com/modelcontextprotocol/specification)
- [JSON-RPC 2.0 Specification](https://www.jsonrpc.org/specification)
- [WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket)

## ⏭️ Next Exercise

Ready for more? Move on to [Exercise 2: Database MCP Gateway](../exercise2-database-gateway/) where you'll create an MCP server for database access!