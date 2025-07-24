---
sidebar_position: 2
title: "Exercise 1: Part 1"
description: "## 🎯 Objective"
---

# Ejercicio 1: File System MCP Server (⭐ Fácil - 30 minutos)

## 🎯 Objective
Build an MCP server that safely exposes file system operations to AI agents, implementing proper security, validation, and the complete MCP protocol specification.

## 🧠 Lo Que Aprenderás
- MCP server architecture and setup
- JSON-RPC 2.0 protocol implementation
- Tool registration and parameter validation
- Security measures for file system access
- Error handling and logging

## 📋 Prerrequisitos
- Basic understanding of file system operations
- Familiarity with TypeScript/JavaScript
- Knowledge of async/await patterns
- Understanding of JSON-RPC basics

## 📚 Atrásground

An MCP File System Server enables AI agents to:
- Read files within allowed directories
- Write files with proper permissions
- List directory contents
- Buscar for files by pattern
- Get file metadata

All while maintaining security through:
- Path traversal prevention
- Access control lists
- Operation limits
- Audit logging

## 🏗️ Architecture Resumen

```mermaid
graph TB
    subgraph "MCP File System Server"
        A[WebSocket Server] --&gt; B[JSON-RPC Handler]
        B --&gt; C[Request Validator]
        C --&gt; D[Tool Registry]
        
        D --&gt; E[Read File Tool]
        D --&gt; F[Write File Tool]
        D --&gt; G[List Directory Tool]
        D --&gt; H[Search Files Tool]
        
        I[Security Layer] --&gt; E
        I --&gt; F
        I --&gt; G
        I --&gt; H
        
        J[File System] --&gt; E
        J --&gt; F
        J --&gt; G
        J --&gt; H
    end
    
    K[MCP Client/Agent] &lt;--&gt; A
    
    style A fill:#4CAF50
    style I fill:#FF9800
    style K fill:#2196F3
```

## 🛠️ Step-by-Step Instructions

### Step 1: Project Setup

**Copilot Prompt Suggestion:**
```typescript
// Create a TypeScript project structure for an MCP server that:
// - Uses @modelcontextprotocol/sdk for the server
// - Implements WebSocket transport
// - Has proper TypeScript configuration
// - Includes testing setup with Jest
// - Has ESLint and Prettier configured
```

1. **Initialize the project:**
```bash
mkdir mcp-filesystem-server
cd mcp-filesystem-server
npm init -y
```

2. **Install dependencies:**
```bash
# Core MCP dependencies
npm install @modelcontextprotocol/sdk ws express

# Development dependencies
npm install --save-dev \
  typescript \
  @types/node \
  @types/ws \
  @types/express \
  ts-node \
  nodemon \
  jest \
  @types/jest \
  ts-jest \
  eslint \
  @typescript-eslint/parser \
  @typescript-eslint/eslint-plugin \
  prettier

# Additional utilities
npm install \
  dotenv \
  winston \
  joi \
  nanoid \
  glob
```

3. **Create TypeScript configuration (`tsconfig.json`):**
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
```

4. **Create project structure:**
```bash
mkdir -p src/{server,tools,security,utils}
mkdir -p tests/{unit,integration}
mkdir -p config
mkdir -p logs
```

### Step 2: Implement the MCP Server Core

**Copilot Prompt Suggestion:**
```typescript
// Create an MCP server class that:
// - Extends the base MCP server from the SDK
// - Implements WebSocket transport
// - Handles JSON-RPC 2.0 messages
// - Has proper error handling and logging
// - Supports graceful shutdown
// Include comprehensive logging with Winston
```

Create `src/server/MCPFileSystemServer.ts`:
```typescript
import { MCPServer, MCPServerOptions } from '@modelcontextprotocol/sdk';
import WebSocket from 'ws';
import { createServer, Server as HTTPServer } from 'http';
import express, { Application } from 'express';
import winston from 'winston';
import { nanoid } from 'nanoid';
import path from 'path';
import { EventEmitter } from 'events';

interface ServerConfig {
  port: number;
  host: string;
  basePath: string;
  allowedPaths: string[];
  maxFileSize: number;
  enableLogging: boolean;
  logLevel: string;
}

export class MCPFileSystemServer extends EventEmitter {
  private config: ServerConfig;
  private app: Application;
  private httpServer: HTTPServer;
  private wss: WebSocket.Server;
  private logger: winston.Logger;
  private connections: Map<string, WebSocket> = new Map();
  private isShuttingDown = false;

  constructor(config: Partial<ServerConfig> = {}) {
    super();
    
    this.config = {
      port: config.port || 3000,
      host: config.host || 'localhost',
      basePath: config.basePath || process.cwd(),
      allowedPaths: config.allowedPaths || ['.'],
      maxFileSize: config.maxFileSize || 10 * 1024 * 1024, // 10MB
      enableLogging: config.enableLogging !== false,
      logLevel: config.logLevel || 'info'
    };

    this.logger = this.setupLogger();
    this.app = express();
    this.httpServer = createServer(this.app);
    this.wss = new WebSocket.Server({ server: this.httpServer });
    
    this.setupMiddleware();
    this.setupWebSocket();
    this.setupTools();
  }

  private setupLogger(): winston.Logger {
    return winston.createLogger({
      level: this.config.logLevel,
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
      ),
      transports: [
        new winston.transports.File({ 
          filename: 'logs/error.log', 
          level: 'error' 
        }),
        new winston.transports.File({ 
          filename: 'logs/combined.log' 
        })
      ]
    });

    if (this.config.enableLogging && process.env.NODE_ENV !== 'production') {
      this.logger.add(new winston.transports.Console({
        format: winston.format.combine(
          winston.format.colorize(),
          winston.format.simple()
        )
      }));
    }
  }

  private setupMiddleware(): void {
    // Health check endpoint
    this.app.get('/health', (req, res) =&gt; {
      res.json({
        status: 'healthy',
        uptime: process.uptime(),
        connections: this.connections.size,
        timestamp: new Date().toISOString()
      });
    });

    // Metrics endpoint
    this.app.get('/metrics', (req, res) =&gt; {
      res.json(this.getMetrics());
    });
  }

  private setupWebSocket(): void {
    this.wss.on('connection', (ws: WebSocket, request) =&gt; {
      const connectionId = nanoid();
      this.connections.set(connectionId, ws);
      
      this.logger.info('New connection', {
        connectionId,
        remoteAddress: request.socket.remoteAddress
      });

      ws.on('message', async (data: WebSocket.Data) =&gt; {
        try {
          const message = JSON.parse(data.toString());
          await this.handleMessage(connectionId, message, ws);
        } catch (error) {
          this.sendError(ws, null, -32700, 'Parse error');
        }
      });

      ws.on('close', () =&gt; {
        this.connections.delete(connectionId);
        this.logger.info('Connection closed', { connectionId });
      });

      ws.on('error', (error) =&gt; {
        this.logger.error('WebSocket error', { connectionId, error });
      });

      // Send welcome message
      this.sendResponse(ws, null, {
        version: '1.0.0',
        capabilities: this.getCapabilities()
      });
    });
  }

  private async handleMessage(
    connectionId: string, 
    message: any, 
    ws: WebSocket
  ): Promise<void> {
    this.logger.debug('Received message', { connectionId, message });

    // Validate JSON-RPC structure
    if (!this.isValidJsonRpc(message)) {
      this.sendError(ws, message.id || null, -32600, 'Invalid Request');
      return;
    }

    try {
      const result = await this.processRequest(message);
      this.sendResponse(ws, message.id, result);
    } catch (error: any) {
      this.logger.error('Request processing error', { error, message });
      
      if (error.code && error.message) {
        this.sendError(ws, message.id, error.code, error.message, error.data);
      } else {
        this.sendError(ws, message.id, -32603, 'Internal error');
      }
    }
  }

  private isValidJsonRpc(message: any): boolean {
    return (
      message &&
      message.jsonrpc === '2.0' &&
      typeof message.method === 'string' &&
      (message.id === undefined || 
       typeof message.id === 'string' || 
       typeof message.id === 'number')
    );
  }

  private sendResponse(ws: WebSocket, id: any, result: any): void {
    const response = {
      jsonrpc: '2.0',
      id,
      result
    };
    
    ws.send(JSON.stringify(response));
  }

  private sendError(
    ws: WebSocket, 
    id: any, 
    code: number, 
    message: string, 
    data?: any
  ): void {
    const error = {
      jsonrpc: '2.0',
      id,
      error: {
        code,
        message,
        data
      }
    };
    
    ws.send(JSON.stringify(error));
  }

  private getCapabilities(): string[] {
    return [
      'file.read',
      'file.write',
      'directory.list',
      'file.search',
      'file.metadata'
    ];
  }

  private getMetrics(): any {
    return {
      connections: this.connections.size,
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      tools: this.getRegisteredTools()
    };
  }

  private getRegisteredTools(): string[] {
    // Will be implemented when we add tools
    return [];
  }

  async start(): Promise<void> {
    return new Promise((resolve) =&gt; {
      this.httpServer.listen(this.config.port, this.config.host, () =&gt; {
        this.logger.info('MCP File System Server started', {
          host: this.config.host,
          port: this.config.port,
          basePath: this.config.basePath
        });
        
        this.emit('ready');
        resolve();
      });
    });
  }

  async stop(): Promise<void> {
    if (this.isShuttingDown) return;
    this.isShuttingDown = true;

    this.logger.info('Shutting down server...');

    // Close all WebSocket connections
    for (const [id, ws] of this.connections) {
      ws.close(1001, 'Server shutting down');
    }

    // Close WebSocket server
    await new Promise<void>((resolve) =&gt; {
      this.wss.close(() =&gt; resolve());
    });

    // Close HTTP server
    await new Promise<void>((resolve) =&gt; {
      this.httpServer.close(() =&gt; resolve());
    });

    this.logger.info('Server shut down complete');
    this.emit('shutdown');
  }

  private setupTools(): void {
    // Tool setup will be implemented in the next step
  }

  private async processRequest(message: any): Promise<any> {
    // Request processing will be implemented with tools
    throw new Error('Method not implemented');
  }
}
```

### Step 3: Implement Security Layer

**Copilot Prompt Suggestion:**
```typescript
// Create a security module that:
// - Prevents path traversal attacks
// - Validates file paths against allowed directories
// - Implements access control for read/write operations
// - Sanitizes file names and paths
// - Enforces file size limits
// - Provides audit logging for all operations
```

Create `src/security/FileSystemSecurity.ts`:
```typescript
import path from 'path';
import fs from 'fs/promises';
import { createHash } from 'crypto';
import winston from 'winston';

export interface SecurityConfig {
  basePath: string;
  allowedPaths: string[];
  maxFileSize: number;
  allowedExtensions?: string[];
  deniedExtensions?: string[];
  readOnly?: boolean;
}

export interface SecurityContext {
  userId?: string;
  connectionId: string;
  operation: string;
  timestamp: Date;
}

export class FileSystemSecurity {
  private config: SecurityConfig;
  private logger: winston.Logger;
  private accessLog: Map<string, AccessRecord[]> = new Map();

  constructor(config: SecurityConfig, logger: winston.Logger) {
    this.config = {
      ...config,
      basePath: path.resolve(config.basePath),
      allowedPaths: config.allowedPaths.map(p => path.resolve(config.basePath, p))
    };
    this.logger = logger;
  }

  async validateReadAccess(
    filePath: string, 
    context: SecurityContext
  ): Promise<string> {
    const resolvedPath = await this.validatePath(filePath);
    
    // Check if file exists
    try {
      const stats = await fs.stat(resolvedPath);
      
      if (!stats.isFile()) {
        throw new SecurityError('Not a file', 'INVALID_FILE_TYPE');
      }
      
      // Check file size for read
      if (stats.size &gt; this.config.maxFileSize) {
        throw new SecurityError(
          `File too large: ${stats.size} bytes`, 
          'FILE_TOO_LARGE'
        );
      }
    } catch (error: any) {
      if (error.code === 'ENOENT') {
        throw new SecurityError('File not found', 'FILE_NOT_FOUND');
      }
      throw error;
    }
    
    // Log access
    this.logAccess(context, 'read', resolvedPath, true);
    
    return resolvedPath;
  }

  async validateWriteAccess(
    filePath: string, 
    content: string | Buffer,
    context: SecurityContext
  ): Promise<string> {
    if (this.config.readOnly) {
      throw new SecurityError('Write operations are disabled', 'READ_ONLY');
    }
    
    const resolvedPath = await this.validatePath(filePath);
    
    // Check content size
    const size = Buffer.isBuffer(content) ? content.length : Buffer.byteLength(content);
    if (size &gt; this.config.maxFileSize) {
      throw new SecurityError(
        `Content too large: ${size} bytes`,
        'CONTENT_TOO_LARGE'
      );
    }
    
    // Check if directory exists
    const dir = path.dirname(resolvedPath);
    try {
      await fs.access(dir, fs.constants.W_OK);
    } catch {
      throw new SecurityError('Directory not writable', 'DIRECTORY_NOT_WRITABLE');
    }
    
    // Log access
    this.logAccess(context, 'write', resolvedPath, true);
    
    return resolvedPath;
  }

  async validateDirectoryAccess(
    dirPath: string,
    context: SecurityContext
  ): Promise<string> {
    const resolvedPath = await this.validatePath(dirPath);
    
    // Check if directory exists
    try {
      const stats = await fs.stat(resolvedPath);
      
      if (!stats.isDirectory()) {
        throw new SecurityError('Not a directory', 'INVALID_DIRECTORY');
      }
    } catch (error: any) {
      if (error.code === 'ENOENT') {
        throw new SecurityError('Directory not found', 'DIRECTORY_NOT_FOUND');
      }
      throw error;
    }
    
    // Log access
    this.logAccess(context, 'list', resolvedPath, true);
    
    return resolvedPath;
  }

  private async validatePath(inputPath: string): Promise<string> {
    // Normalize and resolve path
    const normalizedPath = path.normalize(inputPath);
    const resolvedPath = path.resolve(this.config.basePath, normalizedPath);
    
    // Get real path to handle symlinks
    let realPath: string;
    try {
      realPath = await fs.realpath(resolvedPath);
    } catch (error: any) {
      if (error.code === 'ENOENT') {
        // For new files, check parent directory
        const parentDir = path.dirname(resolvedPath);
        const realParent = await fs.realpath(parentDir).catch(() =&gt; parentDir);
        realPath = path.join(realParent, path.basename(resolvedPath));
      } else {
        throw error;
      }
    }
    
    // Check if path is within allowed directories
    const isAllowed = this.config.allowedPaths.some(allowed =&gt; 
      realPath.startsWith(allowed) || realPath === allowed
    );
    
    if (!isAllowed) {
      throw new SecurityError(
        'Access denied: Path outside allowed directories',
        'PATH_TRAVERSAL'
      );
    }
    
    // Check file extension
    const ext = path.extname(realPath).toLowerCase();
    
    if (this.config.deniedExtensions?.includes(ext)) {
      throw new SecurityError(
        `File type not allowed: ${ext}`,
        'DENIED_EXTENSION'
      );
    }
    
    if (this.config.allowedExtensions && 
        !this.config.allowedExtensions.includes(ext)) {
      throw new SecurityError(
        `File type not allowed: ${ext}`,
        'INVALID_EXTENSION'
      );
    }
    
    return realPath;
  }

  private logAccess(
    context: SecurityContext,
    operation: string,
    path: string,
    success: boolean
  ): void {
    const record: AccessRecord = {
      ...context,
      operation,
      path,
      success,
      timestamp: new Date()
    };
    
    // Store in memory (could be persisted)
    const key = context.connectionId;
    if (!this.accessLog.has(key)) {
      this.accessLog.set(key, []);
    }
    this.accessLog.get(key)!.push(record);
    
    // Log to file
    this.logger.info('File access', record);
  }

  getAccessLog(connectionId?: string): AccessRecord[] {
    if (connectionId) {
      return this.accessLog.get(connectionId) || [];
    }
    
    // Return all logs
    const allLogs: AccessRecord[] = [];
    for (const logs of this.accessLog.values()) {
      allLogs.push(...logs);
    }
    return allLogs;
  }

  generateFileHash(content: string | Buffer): string {
    const hash = createHash('sha256');
    hash.update(content);
    return hash.digest('hex');
  }
}

export class SecurityError extends Error {
  constructor(message: string, public code: string) {
    super(message);
    this.name = 'SecurityError';
  }
}

interface AccessRecord extends SecurityContext {
  operation: string;
  path: string;
  success: boolean;
}
```

### Step 4: Create ambiente Configuration

Create `.env`:
```bash
# Server Configuration
MCP_SERVER_PORT=3000
MCP_SERVER_HOST=localhost

# File System Configuration
FS_BASE_PATH=./workspace
FS_ALLOWED_PATHS=documents,projects,config
FS_MAX_FILE_SIZE=10485760
FS_READ_ONLY=false

# Security
FS_ALLOWED_EXTENSIONS=.txt,.md,.json,.yaml,.yml,.xml,.csv
FS_DENIED_EXTENSIONS=.exe,.sh,.bat,.cmd,.ps1

# Logging
LOG_LEVEL=info
ENABLE_LOGGING=true
```

Create `src/config/index.ts`:
```typescript
import dotenv from 'dotenv';
import path from 'path';

dotenv.config();

export const config = {
  server: {
    port: parseInt(process.env.MCP_SERVER_PORT || '3000'),
    host: process.env.MCP_SERVER_HOST || 'localhost'
  },
  fileSystem: {
    basePath: path.resolve(process.env.FS_BASE_PATH || './workspace'),
    allowedPaths: (process.env.FS_ALLOWED_PATHS || '.').split(',').map(p =&gt; p.trim()),
    maxFileSize: parseInt(process.env.FS_MAX_FILE_SIZE || '10485760'),
    readOnly: process.env.FS_READ_ONLY === 'true',
    allowedExtensions: process.env.FS_ALLOWED_EXTENSIONS?.split(',').map(e =&gt; e.trim()),
    deniedExtensions: process.env.FS_DENIED_EXTENSIONS?.split(',').map(e =&gt; e.trim())
  },
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    enabled: process.env.ENABLE_LOGGING !== 'false'
  }
};
```

## 🧪 Testing

Create `tests/unit/security.test.ts`:
```typescript
import { FileSystemSecurity, SecurityError } from '../../src/security/FileSystemSecurity';
import winston from 'winston';
import path from 'path';

describe('FileSystemSecurity', () =&gt; {
  let security: FileSystemSecurity;
  let mockLogger: winston.Logger;

  beforeEach(() =&gt; {
    mockLogger = winston.createLogger({ silent: true });
    
    security = new FileSystemSecurity({
      basePath: '/workspace',
      allowedPaths: ['/workspace/allowed'],
      maxFileSize: 1024 * 1024,
      allowedExtensions: ['.txt', '.md'],
      readOnly: false
    }, mockLogger);
  });

  describe('Path Validation', () =&gt; {
    it('should prevent path traversal attacks', async () =&gt; {
      const maliciousPaths = [
        '../../../etc/passwd',
        '..\\..\\..\\windows\\system32',
        'allowed/../../secret',
        'allowed/./../../secret'
      ];

      for (const malPath of maliciousPaths) {
        await expect(
          security.validateReadAccess(malPath, {
            connectionId: 'test',
            operation: 'read',
            timestamp: new Date()
          })
        ).rejects.toThrow(SecurityError);
      }
    });

    it('should allow valid paths within allowed directories', async () =&gt; {
      // Mock fs operations for testing
      // In real tests, use a test filesystem or mock fs module
    });
  });
});
```

## ⏭️ Próximos Pasos

Continuar to [Partee 2](./exercise1-part2) where we'll implement:
- Tool registration system
- File system operation tools
- Request processing
- Integration with the MCP protocol