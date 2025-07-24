---
sidebar_position: 3
title: "Exercise 2: Part 2"
description: "## 🛠️ Continuing Implementation"
---

# Exercise 2: Database MCP Gateway - Part 2

## 🛠️ Continuing Implementation

### Step 6: Implement Database Query Tools

**Copilot Prompt Suggestion:**
```typescript
// Create database tools that:
// - Execute SELECT queries with parameterization
// - Support INSERT, UPDATE, DELETE operations
// - Handle transactions with BEGIN, COMMIT, ROLLBACK
// - Stream large result sets efficiently
// - Provide schema introspection capabilities
// - Include query performance metrics
```

Create `src/tools/QueryTool.ts`:
```typescript
import { Tool, ToolDefinition, ToolContext } from '../../../exercise1-filesystem-server/src/tools/Tool';
import { ConnectionManager } from '../database/ConnectionManager';
import { QueryValidator, ValidationConfig } from '../security/QueryValidator';
import winston from 'winston';
import Joi from 'joi';
import { Transform } from 'stream';

export class QueryTool extends Tool {
  constructor(
    private connectionManager: ConnectionManager,
    private validator: QueryValidator,
    private logger: winston.Logger
  ) {
    super({
      name: 'database.query',
      description: 'Execute a SELECT query on the database',
      parameters: [
        {
          name: 'connection',
          type: 'string',
          description: 'Name of the database connection to use',
          required: true,
          schema: Joi.string().min(1).max(50)
        },
        {
          name: 'query',
          type: 'string',
          description: 'SQL SELECT query to execute',
          required: true,
          schema: Joi.string().min(1).max(10000)
        },
        {
          name: 'params',
          type: 'array',
          description: 'Query parameters for prepared statement',
          required: false,
          default: [],
          schema: Joi.array().items(
            Joi.alternatives().try(
              Joi.string(),
              Joi.number(),
              Joi.boolean(),
              Joi.date(),
              Joi.allow(null)
            )
          )
        },
        {
          name: 'limit',
          type: 'number',
          description: 'Maximum number of rows to return',
          required: false,
          default: 1000,
          schema: Joi.number().min(1).max(10000)
        },
        {
          name: 'stream',
          type: 'boolean',
          description: 'Whether to stream results',
          required: false,
          default: false
        },
        {
          name: 'timeout',
          type: 'number',
          description: 'Query timeout in milliseconds',
          required: false,
          default: 30000,
          schema: Joi.number().min(1000).max(300000)
        }
      ],
      returns: {
        type: 'object',
        description: 'Query results with metadata'
      }
    });
  }

  async execute(params: any, context: ToolContext): Promise<any> {
    const { connection: connName, query, params: queryParams, limit, stream, timeout } = params;
    
    const startTime = Date.now();
    
    try {
      // Get connection
      const connection = this.connectionManager.getConnection(connName);
      
      // Validate query
      const validation = this.validator.validate(query);
      if (!validation.valid) {
        throw new Error(`Query validation failed: ${validation.errors.map(e =&gt; e.message).join(', ')}`);
      }
      
      // Ensure it's a SELECT query
      if (validation.metadata?.operation !== 'SELECT') {
        throw new Error('Only SELECT queries are allowed with database.query tool');
      }
      
      // Apply limit to query if not already present
      let finalQuery = query;
      if (!query.toLowerCase().includes('limit') && limit) {
        finalQuery = `${query} LIMIT ${limit}`;
      }
      
      // Log query execution
      this.logger.info('Executing query', {
        connectionId: context.connectionId,
        connection: connName,
        operation: 'SELECT',
        tables: validation.metadata?.tables,
        hasParams: queryParams.length &gt; 0
      });
      
      // Execute query with timeout
      const queryPromise = connection.query(finalQuery, queryParams);
      const timeoutPromise = new Promise((_, reject) =&gt; 
        setTimeout(() =&gt; reject(new Error('Query timeout')), timeout)
      );
      
      const rows = await Promise.race([queryPromise, timeoutPromise]) as any[];
      
      const duration = Date.now() - startTime;
      
      // Log performance
      this.logger.info('Query completed', {
        connectionId: context.connectionId,
        duration,
        rowCount: rows.length
      });
      
      return {
        rows,
        rowCount: rows.length,
        metadata: {
          query: finalQuery,
          duration,
          connection: connName,
          tables: validation.metadata?.tables,
          warnings: validation.warnings
        }
      };
      
    } catch (error: any) {
      const duration = Date.now() - startTime;
      
      this.logger.error('Query failed', {
        connectionId: context.connectionId,
        error: error.message,
        duration
      });
      
      throw error;
    }
  }
}
```

Create `src/tools/ExecuteTool.ts`:
```typescript
export class ExecuteTool extends Tool {
  constructor(
    private connectionManager: ConnectionManager,
    private validator: QueryValidator,
    private logger: winston.Logger
  ) {
    super({
      name: 'database.execute',
      description: 'Execute INSERT, UPDATE, or DELETE operations',
      parameters: [
        {
          name: 'connection',
          type: 'string',
          description: 'Name of the database connection to use',
          required: true
        },
        {
          name: 'query',
          type: 'string',
          description: 'SQL statement to execute',
          required: true
        },
        {
          name: 'params',
          type: 'array',
          description: 'Query parameters',
          required: false,
          default: []
        }
      ],
      returns: {
        type: 'object',
        description: 'Execution result with affected rows'
      }
    });
  }

  async execute(params: any, context: ToolContext): Promise<any> {
    const { connection: connName, query, params: queryParams } = params;
    
    // Get connection
    const connection = this.connectionManager.getConnection(connName);
    
    // Validate query
    const validation = this.validator.validate(query);
    if (!validation.valid) {
      throw new Error(`Query validation failed: ${validation.errors.map(e =&gt; e.message).join(', ')}`);
    }
    
    // Ensure it's not a SELECT query
    if (validation.metadata?.operation === 'SELECT') {
      throw new Error('Use database.query tool for SELECT queries');
    }
    
    // Log execution
    this.logger.info('Executing statement', {
      connectionId: context.connectionId,
      connection: connName,
      operation: validation.metadata?.operation,
      tables: validation.metadata?.tables
    });
    
    // Execute statement
    const result = await connection.execute(query, queryParams);
    
    return {
      rowCount: result.rowCount || result.affectedRows || 0,
      metadata: {
        operation: validation.metadata?.operation,
        tables: validation.metadata?.tables,
        warnings: validation.warnings
      }
    };
  }
}
```

Create `src/tools/TransactionTool.ts`:
```typescript
export class TransactionTool extends Tool {
  private activeTransactions = new Map<string, {
    connection: string;
    startTime: number;
  }>();
  
  constructor(
    private connectionManager: ConnectionManager,
    private logger: winston.Logger
  ) {
    super({
      name: 'database.transaction',
      description: 'Manage database transactions',
      parameters: [
        {
          name: 'connection',
          type: 'string',
          description: 'Name of the database connection',
          required: true
        },
        {
          name: 'action',
          type: 'string',
          description: 'Transaction action: begin, commit, or rollback',
          required: true,
          schema: Joi.string().valid('begin', 'commit', 'rollback')
        }
      ],
      returns: {
        type: 'object',
        description: 'Transaction result'
      }
    });
  }

  async execute(params: any, context: ToolContext): Promise<any> {
    const { connection: connName, action } = params;
    const connection = this.connectionManager.getConnection(connName);
    const transactionKey = `${context.connectionId}:${connName}`;
    
    switch (action) {
      case 'begin':
        if (this.activeTransactions.has(transactionKey)) {
          throw new Error('Transaction already in progress');
        }
        
        await connection.beginTransaction();
        this.activeTransactions.set(transactionKey, {
          connection: connName,
          startTime: Date.now()
        });
        
        this.logger.info('Transaction started', {
          connectionId: context.connectionId,
          connection: connName
        });
        
        return { status: 'begun', connection: connName };
        
      case 'commit':
        if (!this.activeTransactions.has(transactionKey)) {
          throw new Error('No active transaction');
        }
        
        await connection.commit();
        const commitTx = this.activeTransactions.get(transactionKey)!;
        const duration = Date.now() - commitTx.startTime;
        this.activeTransactions.delete(transactionKey);
        
        this.logger.info('Transaction committed', {
          connectionId: context.connectionId,
          connection: connName,
          duration
        });
        
        return { status: 'committed', duration };
        
      case 'rollback':
        if (!this.activeTransactions.has(transactionKey)) {
          throw new Error('No active transaction');
        }
        
        await connection.rollback();
        const rollbackTx = this.activeTransactions.get(transactionKey)!;
        const rollbackDuration = Date.now() - rollbackTx.startTime;
        this.activeTransactions.delete(transactionKey);
        
        this.logger.info('Transaction rolled back', {
          connectionId: context.connectionId,
          connection: connName,
          duration: rollbackDuration
        });
        
        return { status: 'rolled_back', duration: rollbackDuration };
        
      default:
        throw new Error(`Invalid action: ${action}`);
    }
  }
}
```

Create `src/tools/SchemaTool.ts`:
```typescript
export class SchemaTool extends Tool {
  constructor(
    private connectionManager: ConnectionManager,
    private logger: winston.Logger
  ) {
    super({
      name: 'database.schema',
      description: 'Get database schema information',
      parameters: [
        {
          name: 'connection',
          type: 'string',
          description: 'Name of the database connection',
          required: true
        },
        {
          name: 'type',
          type: 'string',
          description: 'Type of schema info: tables, columns, indexes',
          required: true,
          schema: Joi.string().valid('tables', 'columns', 'indexes')
        },
        {
          name: 'table',
          type: 'string',
          description: 'Table name (required for columns and indexes)',
          required: false
        }
      ],
      returns: {
        type: 'array',
        description: 'Schema information'
      }
    });
  }

  async execute(params: any, context: ToolContext): Promise<any> {
    const { connection: connName, type, table } = params;
    const connection = this.connectionManager.getConnection(connName);
    
    let query: string;
    let queryParams: any[] = [];
    
    // Build appropriate query based on database type and request
    const dbType = this.getConnectionType(connName);
    
    switch (type) {
      case 'tables':
        query = this.getTablesQuery(dbType);
        break;
        
      case 'columns':
        if (!table) {
          throw new Error('Table name required for columns query');
        }
        query = this.getColumnsQuery(dbType);
        queryParams = [table];
        break;
        
      case 'indexes':
        if (!table) {
          throw new Error('Table name required for indexes query');
        }
        query = this.getIndexesQuery(dbType);
        queryParams = [table];
        break;
        
      default:
        throw new Error(`Invalid schema type: ${type}`);
    }
    
    const results = await connection.query(query, queryParams);
    
    return {
      type,
      table,
      data: results
    };
  }
  
  private getConnectionType(connName: string): string {
    // Implementation would check connection config
    return 'postgresql'; // Default for demo
  }
  
  private getTablesQuery(dbType: string): string {
    switch (dbType) {
      case 'postgresql':
        return `
          SELECT 
            table_name,
            table_type
          FROM information_schema.tables 
          WHERE table_schema = 'public'
          ORDER BY table_name
        `;
        
      case 'mysql':
        return `
          SELECT 
            TABLE_NAME as table_name,
            TABLE_TYPE as table_type
          FROM information_schema.TABLES 
          WHERE TABLE_SCHEMA = DATABASE()
          ORDER BY TABLE_NAME
        `;
        
      case 'sqlite':
        return `
          SELECT 
            name as table_name,
            type as table_type
          FROM sqlite_master 
          WHERE type = 'table'
          ORDER BY name
        `;
        
      default:
        throw new Error(`Unsupported database type: ${dbType}`);
    }
  }
  
  private getColumnsQuery(dbType: string): string {
    switch (dbType) {
      case 'postgresql':
        return `
          SELECT 
            column_name,
            data_type,
            is_nullable,
            column_default
          FROM information_schema.columns 
          WHERE table_schema = 'public' 
            AND table_name = $1
          ORDER BY ordinal_position
        `;
        
      case 'mysql':
        return `
          SELECT 
            COLUMN_NAME as column_name,
            DATA_TYPE as data_type,
            IS_NULLABLE as is_nullable,
            COLUMN_DEFAULT as column_default
          FROM information_schema.COLUMNS 
          WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = ?
          ORDER BY ORDINAL_POSITION
        `;
        
      default:
        throw new Error(`Unsupported database type for columns: ${dbType}`);
    }
  }
  
  private getIndexesQuery(dbType: string): string {
    switch (dbType) {
      case 'postgresql':
        return `
          SELECT 
            indexname as index_name,
            indexdef as index_definition
          FROM pg_indexes 
          WHERE schemaname = 'public' 
            AND tablename = $1
        `;
        
      case 'mysql':
        return `
          SHOW INDEX FROM ?
        `;
        
      default:
        throw new Error(`Unsupported database type for indexes: ${dbType}`);
    }
  }
}
```

### Step 7: Create the MCP Database Server

Create `src/server/MCPDatabaseServer.ts`:
```typescript
import { MCPServer } from '../../../exercise1-filesystem-server/src/server/MCPFileSystemServer';
import { ConnectionManager } from '../database/ConnectionManager';
import { QueryValidator, ValidationConfig } from '../security/QueryValidator';
import { ToolRegistry } from '../../../exercise1-filesystem-server/src/tools/Tool';
import { QueryTool } from '../tools/QueryTool';
import { ExecuteTool } from '../tools/ExecuteTool';
import { TransactionTool } from '../tools/TransactionTool';
import { SchemaTool } from '../tools/SchemaTool';
import winston from 'winston';
import { config } from '../config';

export class MCPDatabaseServer extends MCPServer {
  private connectionManager: ConnectionManager;
  private queryValidator: QueryValidator;
  private toolRegistry: ToolRegistry;
  
  constructor() {
    super({
      port: config.server.port,
      host: config.server.host
    });
    
    this.connectionManager = new ConnectionManager(this.logger);
    this.queryValidator = new QueryValidator(config.validation, this.logger);
    this.toolRegistry = new ToolRegistry();
    
    this.setupConnections();
    this.setupTools();
  }
  
  private async setupConnections(): Promise<void> {
    // Setup PostgreSQL connection
    if (config.databases.postgresql.enabled) {
      await this.connectionManager.createConnection('postgresql', {
        type: 'postgresql',
        host: config.databases.postgresql.host,
        port: config.databases.postgresql.port,
        database: config.databases.postgresql.database,
        user: config.databases.postgresql.user,
        password: config.databases.postgresql.password,
        pool: config.pool
      });
    }
    
    // Setup MySQL connection
    if (config.databases.mysql.enabled) {
      await this.connectionManager.createConnection('mysql', {
        type: 'mysql',
        host: config.databases.mysql.host,
        port: config.databases.mysql.port,
        database: config.databases.mysql.database,
        user: config.databases.mysql.user,
        password: config.databases.mysql.password,
        pool: config.pool
      });
    }
    
    // Setup SQLite connection
    if (config.databases.sqlite.enabled) {
      await this.connectionManager.createConnection('sqlite', {
        type: 'sqlite',
        filename: config.databases.sqlite.filename
      });
    }
  }
  
  private setupTools(): void {
    // Register database tools
    this.toolRegistry.register(new QueryTool(
      this.connectionManager,
      this.queryValidator,
      this.logger
    ));
    
    this.toolRegistry.register(new ExecuteTool(
      this.connectionManager,
      this.queryValidator,
      this.logger
    ));
    
    this.toolRegistry.register(new TransactionTool(
      this.connectionManager,
      this.logger
    ));
    
    this.toolRegistry.register(new SchemaTool(
      this.connectionManager,
      this.logger
    ));
    
    this.logger.info('Database tools registered', {
      tools: this.toolRegistry.list().map(t =&gt; t.name)
    });
  }
  
  async shutdown(): Promise<void> {
    await this.connectionManager.closeAll();
    await super.stop();
  }
}
```

### Step 8: Create Server Entry Point

Create `src/index.ts`:
```typescript
import { MCPDatabaseServer } from './server/MCPDatabaseServer';

async function main() {
  const server = new MCPDatabaseServer();
  
  // Handle shutdown signals
  process.on('SIGTERM', async () =&gt; {
    console.log('SIGTERM received, shutting down gracefully...');
    await server.shutdown();
    process.exit(0);
  });
  
  process.on('SIGINT', async () =&gt; {
    console.log('SIGINT received, shutting down gracefully...');
    await server.shutdown();
    process.exit(0);
  });
  
  // Start server
  try {
    await server.start();
    console.log('MCP Database Gateway running');
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

main().catch(console.error);
```

### Step 9: Create Configuration Module

Create `src/config/index.ts`:
```typescript
import dotenv from 'dotenv';

dotenv.config();

export const config = {
  server: {
    port: parseInt(process.env.MCP_SERVER_PORT || '3001'),
    host: process.env.MCP_SERVER_HOST || 'localhost'
  },
  
  databases: {
    postgresql: {
      enabled: process.env.PG_HOST ? true : false,
      host: process.env.PG_HOST || 'localhost',
      port: parseInt(process.env.PG_PORT || '5432'),
      database: process.env.PG_DATABASE || 'mcp_demo',
      user: process.env.PG_USER || 'postgres',
      password: process.env.PG_PASSWORD || 'password'
    },
    
    mysql: {
      enabled: process.env.MYSQL_HOST ? true : false,
      host: process.env.MYSQL_HOST || 'localhost',
      port: parseInt(process.env.MYSQL_PORT || '3306'),
      database: process.env.MYSQL_DATABASE || 'mcp_demo',
      user: process.env.MYSQL_USER || 'root',
      password: process.env.MYSQL_PASSWORD || 'password'
    },
    
    sqlite: {
      enabled: process.env.SQLITE_FILE ? true : false,
      filename: process.env.SQLITE_FILE || ':memory:'
    }
  },
  
  pool: {
    min: parseInt(process.env.POOL_MIN || '2'),
    max: parseInt(process.env.POOL_MAX || '10'),
    idleTimeoutMillis: parseInt(process.env.POOL_IDLE_TIMEOUT || '30000')
  },
  
  validation: {
    readOnly: process.env.QUERY_READ_ONLY === 'true',
    maxQueryLength: parseInt(process.env.MAX_QUERY_LENGTH || '10000'),
    allowedOperations: process.env.ALLOWED_OPERATIONS?.split(','),
    deniedOperations: process.env.DENIED_OPERATIONS?.split(','),
    allowedTables: process.env.ALLOWED_TABLES?.split(','),
    deniedTables: process.env.DENIED_TABLES?.split(',')
  },
  
  security: {
    maxResultsPerQuery: parseInt(process.env.MAX_RESULTS_PER_QUERY || '1000'),
    queryTimeout: parseInt(process.env.QUERY_TIMEOUT_MS || '30000')
  },
  
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    enableQueryLogging: process.env.ENABLE_QUERY_LOGGING === 'true'
  }
};
```

### Step 10: Add Package Scripts

Update `package.json`:
```json
{
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "nodemon --exec ts-node src/index.ts",
    "test": "jest",
    "setup-db": "psql -U postgres -d mcp_demo -f scripts/setup-demo-db.sql",
    "lint": "eslint src/**/*.ts",
    "format": "prettier --write src/**/*.ts"
  }
}
```

## 🏃 Running the Database Gateway

1. **Setup database:**
```bash
# Create database
createdb -U postgres mcp_demo

# Run setup script
npm run setup-db
```

2. **Start the server:**
```bash
npm run build
npm start
```

3. **Test with MCP client:**
```typescript
// test-database-client.ts
import { MCPClient } from '@modelcontextprotocol/client';

const client = new MCPClient({
  url: 'ws://localhost:3001'
});

async function testDatabaseGateway() {
  await client.connect();
  
  // List available tools
  const tools = await client.listTools();
  console.log('Available tools:', tools);
  
  // Query users
  const users = await client.executeTool('database.query', {
    connection: 'postgresql',
    query: 'SELECT * FROM users WHERE created_at &gt; $1',
    params: [new Date('2024-01-01')]
  });
  console.log('Users:', users);
  
  // Get schema info
  const tables = await client.executeTool('database.schema', {
    connection: 'postgresql',
    type: 'tables'
  });
  console.log('Tables:', tables);
  
  // Transaction example
  await client.executeTool('database.transaction', {
    connection: 'postgresql',
    action: 'begin'
  });
  
  try {
    await client.executeTool('database.execute', {
      connection: 'postgresql',
      query: 'INSERT INTO users (username, email) VALUES ($1, $2)',
      params: ['david', 'david@example.com']
    });
    
    await client.executeTool('database.transaction', {
      connection: 'postgresql',
      action: 'commit'
    });
  } catch (error) {
    await client.executeTool('database.transaction', {
      connection: 'postgresql',
      action: 'rollback'
    });
    throw error;
  }
}

testDatabaseGateway().catch(console.error);
```

## 🎯 Validation

Your Database MCP Gateway should now:
- ✅ Connect to multiple database types
- ✅ Execute queries with parameter binding
- ✅ Validate queries for security
- ✅ Support transactions
- ✅ Stream large result sets
- ✅ Provide schema introspection
- ✅ Handle errors gracefully
- ✅ Log all operations

## 📚 Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [SQL Injection Prevention](https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html)

## ⏭️ Next Exercise

Ready for the final challenge? Move on to [Exercise 3: Multi-Server MCP Client](/docs/modules/module-23/exercise3-overview) where you'll build an intelligent agent that uses multiple MCP servers!