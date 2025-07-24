---
sidebar_position: 5
title: "Exercise 2: Part 1"
description: "## 🎯 Objective"
---

# Exercício 2: Database MCP Gateway (⭐⭐ Médio - 45 minutos)

## 🎯 Objective
Build an MCP server that provides secure database access to AI agents, implementing connection pooling, query validation, and result streaming for large datasets.

## 🧠 O Que Você Aprenderá
- Database connection management through MCP
- Query validation and SQL injection prevention
- Result streaming for large datasets
- Transaction support in MCP
- Performance optimization techniques

## 📋 Pré-requisitos
- Completard Exercício 1
- PostgreSQL running (via Docker)
- Understanding of SQL basics
- Knowledge of database security

## 📚 Voltarground

A Database MCP Gateway enables AI agents to:
- Execute safe SQL queries
- Manage database transactions
- Stream large result sets
- Access multiple databases
- Monitor query performance

Security features include:
- Query validation and sanitization
- Connection isolation
- Rate limiting per client
- Query timeout enforcement
- Audit logging

## 🏗️ Architecture Visão Geral

```mermaid
graph TB
    subgraph "Database MCP Gateway"
        A[WebSocket Server] --&gt; B[MCP Handler]
        B --&gt; C[Query Validator]
        C --&gt; D[Connection Pool]
        
        D --&gt; E[PostgreSQL]
        D --&gt; F[MySQL]
        D --&gt; G[SQLite]
        
        H[Security Layer] --&gt; C
        I[Cache Layer] --&gt; B
        J[Metrics Collector] --&gt; D
    end
    
    K[AI Agent] &lt;--&gt; A
    
    subgraph "Tools"
        L[query]
        M[execute]
        N[transaction]
        O[schema]
    end
    
    B --&gt; L
    B --&gt; M
    B --&gt; N
    B --&gt; O
    
    style A fill:#4CAF50
    style H fill:#FF9800
    style K fill:#2196F3
```

## 🛠️ Step-by-Step Instructions

### Step 1: Project Setup

**Copilot Prompt Suggestion:**
```typescript
// Create a TypeScript project for a Database MCP Gateway that:
// - Supports multiple database types (PostgreSQL, MySQL, SQLite)
// - Implements connection pooling for performance
// - Has comprehensive query validation
// - Supports streaming for large results
// - Includes transaction management
// - Has proper error handling and logging
```

1. **Create project structure:**
```bash
mkdir mcp-database-gateway
cd mcp-database-gateway
npm init -y
```

2. **Install dependencies:**
```bash
# Core dependencies
npm install @modelcontextprotocol/sdk ws express

# Database drivers
npm install pg mysql2 sqlite3

# Database utilities
npm install knex @databases/pg @databases/mysql

# Additional utilities
npm install dotenv winston joi lodash p-queue

# Development dependencies
npm install --save-dev \
  typescript \
  @types/node \
  @types/ws \
  @types/pg \
  @types/lodash \
  ts-node \
  nodemon \
  jest \
  @types/jest
```

3. **Create directory structure:**
```bash
mkdir -p src/{server,database,tools,security,utils}
mkdir -p tests/{unit,integration}
mkdir -p config
```

### Step 2: Implement Database Connection Manager

**Copilot Prompt Suggestion:**
```typescript
// Create a database connection manager that:
// - Supports connection pooling with configurable limits
// - Handles multiple database types (PostgreSQL, MySQL, SQLite)
// - Implements health checks for connections
// - Provides connection lifecycle management
// - Includes retry logic for failed connections
// - Monitors connection usage and performance
```

Create `src/database/ConnectionManager.ts`:
```typescript
import { Pool as PgPool } from 'pg';
import mysql from 'mysql2/promise';
import sqlite3 from 'sqlite3';
import { open, Database as SqliteDB } from 'sqlite';
import winston from 'winston';
import { EventEmitter } from 'events';

export interface DatabaseConfig {
  type: 'postgresql' | 'mysql' | 'sqlite';
  connectionString?: string;
  host?: string;
  port?: number;
  database?: string;
  user?: string;
  password?: string;
  filename?: string; // For SQLite
  pool?: {
    min?: number;
    max?: number;
    idleTimeoutMillis?: number;
    connectionTimeoutMillis?: number;
  };
}

export interface ConnectionStats {
  total: number;
  idle: number;
  active: number;
  waiting: number;
}

export abstract class DatabaseConnection {
  abstract query<T = any>(sql: string, params?: any[]): Promise<T[]>;
  abstract execute(sql: string, params?: any[]): Promise<any>;
  abstract beginTransaction(): Promise<void>;
  abstract commit(): Promise<void>;
  abstract rollback(): Promise<void>;
  abstract close(): Promise<void>;
  abstract getStats(): ConnectionStats;
}

export class PostgreSQLConnection extends DatabaseConnection {
  private pool: PgPool;
  private client?: any;

  constructor(config: DatabaseConfig) {
    super();
    
    this.pool = new PgPool({
      connectionString: config.connectionString,
      host: config.host,
      port: config.port,
      database: config.database,
      user: config.user,
      password: config.password,
      min: config.pool?.min || 2,
      max: config.pool?.max || 10,
      idleTimeoutMillis: config.pool?.idleTimeoutMillis || 30000,
      connectionTimeoutMillis: config.pool?.connectionTimeoutMillis || 2000
    });
  }

  async query<T = any>(sql: string, params?: any[]): Promise<T[]> {
    const result = await this.pool.query(sql, params);
    return result.rows;
  }

  async execute(sql: string, params?: any[]): Promise<any> {
    const result = await this.pool.query(sql, params);
    return {
      rowCount: result.rowCount,
      rows: result.rows
    };
  }

  async beginTransaction(): Promise<void> {
    this.client = await this.pool.connect();
    await this.client.query('BEGIN');
  }

  async commit(): Promise<void> {
    if (!this.client) throw new Error('No transaction in progress');
    await this.client.query('COMMIT');
    this.client.release();
    this.client = undefined;
  }

  async rollback(): Promise<void> {
    if (!this.client) throw new Error('No transaction in progress');
    await this.client.query('ROLLBACK');
    this.client.release();
    this.client = undefined;
  }

  async close(): Promise<void> {
    await this.pool.end();
  }

  getStats(): ConnectionStats {
    return {
      total: this.pool.totalCount,
      idle: this.pool.idleCount,
      active: this.pool.totalCount - this.pool.idleCount,
      waiting: this.pool.waitingCount
    };
  }
}

export class MySQLConnection extends DatabaseConnection {
  private pool: mysql.Pool;
  private connection?: mysql.PoolConnection;

  constructor(config: DatabaseConfig) {
    super();
    
    this.pool = mysql.createPool({
      host: config.host,
      port: config.port,
      database: config.database,
      user: config.user,
      password: config.password,
      connectionLimit: config.pool?.max || 10,
      waitForConnections: true,
      queueLimit: 0
    });
  }

  async query<T = any>(sql: string, params?: any[]): Promise<T[]> {
    const [rows] = await this.pool.execute(sql, params);
    return rows as T[];
  }

  async execute(sql: string, params?: any[]): Promise<any> {
    const [result] = await this.pool.execute(sql, params);
    return result;
  }

  async beginTransaction(): Promise<void> {
    this.connection = await this.pool.getConnection();
    await this.connection.beginTransaction();
  }

  async commit(): Promise<void> {
    if (!this.connection) throw new Error('No transaction in progress');
    await this.connection.commit();
    this.connection.release();
    this.connection = undefined;
  }

  async rollback(): Promise<void> {
    if (!this.connection) throw new Error('No transaction in progress');
    await this.connection.rollback();
    this.connection.release();
    this.connection = undefined;
  }

  async close(): Promise<void> {
    await this.pool.end();
  }

  getStats(): ConnectionStats {
    // MySQL doesn't expose these stats directly
    return {
      total: (this.pool as any)._allConnections?.length || 0,
      idle: (this.pool as any)._freeConnections?.length || 0,
      active: (this.pool as any)._allConnections?.length - 
              (this.pool as any)._freeConnections?.length || 0,
      waiting: 0
    };
  }
}

export class SQLiteConnection extends DatabaseConnection {
  private db?: SqliteDB;
  private filename: string;

  constructor(config: DatabaseConfig) {
    super();
    this.filename = config.filename || ':memory:';
  }

  private async getDb(): Promise<SqliteDB> {
    if (!this.db) {
      this.db = await open({
        filename: this.filename,
        driver: sqlite3.Database
      });
    }
    return this.db;
  }

  async query<T = any>(sql: string, params?: any[]): Promise<T[]> {
    const db = await this.getDb();
    return db.all(sql, params);
  }

  async execute(sql: string, params?: any[]): Promise<any> {
    const db = await this.getDb();
    return db.run(sql, params);
  }

  async beginTransaction(): Promise<void> {
    const db = await this.getDb();
    await db.exec('BEGIN TRANSACTION');
  }

  async commit(): Promise<void> {
    const db = await this.getDb();
    await db.exec('COMMIT');
  }

  async rollback(): Promise<void> {
    const db = await this.getDb();
    await db.exec('ROLLBACK');
  }

  async close(): Promise<void> {
    if (this.db) {
      await this.db.close();
      this.db = undefined;
    }
  }

  getStats(): ConnectionStats {
    // SQLite doesn't have connection pools
    return {
      total: 1,
      idle: this.db ? 0 : 1,
      active: this.db ? 1 : 0,
      waiting: 0
    };
  }
}

export class ConnectionManager extends EventEmitter {
  private connections: Map<string, DatabaseConnection> = new Map();
  private logger: winston.Logger;

  constructor(logger: winston.Logger) {
    super();
    this.logger = logger;
  }

  async createConnection(
    name: string, 
    config: DatabaseConfig
  ): Promise<DatabaseConnection> {
    if (this.connections.has(name)) {
      throw new Error(`Connection ${name} already exists`);
    }

    let connection: DatabaseConnection;

    switch (config.type) {
      case 'postgresql':
        connection = new PostgreSQLConnection(config);
        break;
      case 'mysql':
        connection = new MySQLConnection(config);
        break;
      case 'sqlite':
        connection = new SQLiteConnection(config);
        break;
      default:
        throw new Error(`Unsupported database type: ${config.type}`);
    }

    // Test connection
    try {
      await connection.query('SELECT 1');
      this.logger.info(`Database connection established: ${name}`);
    } catch (error) {
      this.logger.error(`Failed to establish connection: ${name}`, error);
      throw error;
    }

    this.connections.set(name, connection);
    this.emit('connection-created', { name, type: config.type });

    return connection;
  }

  getConnection(name: string): DatabaseConnection {
    const connection = this.connections.get(name);
    if (!connection) {
      throw new Error(`Connection not found: ${name}`);
    }
    return connection;
  }

  async closeConnection(name: string): Promise<void> {
    const connection = this.connections.get(name);
    if (connection) {
      await connection.close();
      this.connections.delete(name);
      this.emit('connection-closed', { name });
    }
  }

  async closeAll(): Promise<void> {
    const promises = Array.from(this.connections.entries()).map(
      ([name, connection]) =&gt; connection.close()
    );
    await Promise.all(promises);
    this.connections.clear();
  }

  getStats(): { [name: string]: ConnectionStats } {
    const stats: { [name: string]: ConnectionStats } = {};
    
    for (const [name, connection] of this.connections) {
      stats[name] = connection.getStats();
    }
    
    return stats;
  }
}
```

### Step 3: Implement Query Validator

**Copilot Prompt Suggestion:**
```typescript
// Create a SQL query validator that:
// - Detects and prevents SQL injection attempts
// - Validates query syntax for different databases
// - Enforces query complexity limits
// - Checks for dangerous operations (DROP, TRUNCATE, etc.)
// - Implements allowlist/denylist for tables
// - Provides detailed validation error messages
```

Create `src/security/QueryValidator.ts`:
```typescript
import { Parser as SqlParser } from 'node-sql-parser';
import winston from 'winston';

export interface ValidationConfig {
  allowedOperations?: string[];
  deniedOperations?: string[];
  allowedTables?: string[];
  deniedTables?: string[];
  maxQueryLength?: number;
  maxJoinCount?: number;
  maxSubqueryDepth?: number;
  readOnly?: boolean;
}

export interface ValidationResult {
  valid: boolean;
  errors: ValidationError[];
  warnings: string[];
  metadata?: QueryMetadata;
}

export interface ValidationError {
  code: string;
  message: string;
  detail?: any;
}

export interface QueryMetadata {
  operation: string;
  tables: string[];
  columns: string[];
  hasJoins: boolean;
  hasSubqueries: boolean;
  isReadOnly: boolean;
}

export class QueryValidator {
  private parser: SqlParser;
  private config: ValidationConfig;
  private logger: winston.Logger;

  constructor(config: ValidationConfig, logger: winston.Logger) {
    this.parser = new SqlParser();
    this.config = {
      maxQueryLength: 10000,
      maxJoinCount: 5,
      maxSubqueryDepth: 3,
      readOnly: false,
      ...config
    };
    this.logger = logger;
  }

  validate(sql: string, database: string = 'PostgreSQL'): ValidationResult {
    const errors: ValidationError[] = [];
    const warnings: string[] = [];
    let metadata: QueryMetadata | undefined;

    try {
      // Length check
      if (sql.length &gt; this.config.maxQueryLength!) {
        errors.push({
          code: 'QUERY_TOO_LONG',
          message: `Query exceeds maximum length of ${this.config.maxQueryLength} characters`
        });
        return { valid: false, errors, warnings };
      }

      // Parse SQL
      const ast = this.parser.astify(sql, { database: database as any });
      
      if (!ast) {
        errors.push({
          code: 'PARSE_ERROR',
          message: 'Failed to parse SQL query'
        });
        return { valid: false, errors, warnings };
      }

      // Analyze query
      metadata = this.analyzeQuery(ast);

      // Validate operations
      if (this.config.readOnly && !metadata.isReadOnly) {
        errors.push({
          code: 'READ_ONLY_VIOLATION',
          message: 'Only SELECT queries are allowed in read-only mode'
        });
      }

      if (this.config.allowedOperations) {
        if (!this.config.allowedOperations.includes(metadata.operation)) {
          errors.push({
            code: 'OPERATION_NOT_ALLOWED',
            message: `Operation ${metadata.operation} is not allowed`
          });
        }
      }

      if (this.config.deniedOperations) {
        if (this.config.deniedOperations.includes(metadata.operation)) {
          errors.push({
            code: 'OPERATION_DENIED',
            message: `Operation ${metadata.operation} is denied`
          });
        }
      }

      // Validate tables
      for (const table of metadata.tables) {
        if (this.config.allowedTables) {
          if (!this.config.allowedTables.includes(table)) {
            errors.push({
              code: 'TABLE_NOT_ALLOWED',
              message: `Access to table ${table} is not allowed`
            });
          }
        }

        if (this.config.deniedTables) {
          if (this.config.deniedTables.includes(table)) {
            errors.push({
              code: 'TABLE_DENIED',
              message: `Access to table ${table} is denied`
            });
          }
        }
      }

      // Check for dangerous patterns
      const dangerousPatterns = [
        /xp_cmdshell/i,
        /sp_executesql/i,
        /exec\s*\(/i,
        /into\s+outfile/i,
        /load_file/i
      ];

      for (const pattern of dangerousPatterns) {
        if (pattern.test(sql)) {
          errors.push({
            code: 'DANGEROUS_PATTERN',
            message: 'Query contains potentially dangerous pattern',
            detail: pattern.source
          });
        }
      }

      // Validate complexity
      if (metadata.hasJoins) {
        const joinCount = this.countJoins(ast);
        if (joinCount &gt; this.config.maxJoinCount!) {
          errors.push({
            code: 'TOO_MANY_JOINS',
            message: `Query has ${joinCount} joins, maximum allowed is ${this.config.maxJoinCount}`
          });
        }
      }

      if (metadata.hasSubqueries) {
        const subqueryDepth = this.getSubqueryDepth(ast);
        if (subqueryDepth &gt; this.config.maxSubqueryDepth!) {
          errors.push({
            code: 'SUBQUERY_TOO_DEEP',
            message: `Subquery depth ${subqueryDepth} exceeds maximum of ${this.config.maxSubqueryDepth}`
          });
        }
      }

      // Add warnings
      if (metadata.operation === 'DELETE' && !sql.toLowerCase().includes('where')) {
        warnings.push('DELETE without WHERE clause will affect all rows');
      }

      if (metadata.operation === 'UPDATE' && !sql.toLowerCase().includes('where')) {
        warnings.push('UPDATE without WHERE clause will affect all rows');
      }

    } catch (error: any) {
      errors.push({
        code: 'VALIDATION_ERROR',
        message: 'Failed to validate query',
        detail: error.message
      });
    }

    return {
      valid: errors.length === 0,
      errors,
      warnings,
      metadata
    };
  }

  private analyzeQuery(ast: any): QueryMetadata {
    const metadata: QueryMetadata = {
      operation: ast.type?.toUpperCase() || 'UNKNOWN',
      tables: [],
      columns: [],
      hasJoins: false,
      hasSubqueries: false,
      isReadOnly: false
    };

    // Determine if read-only
    metadata.isReadOnly = ['SELECT'].includes(metadata.operation);

    // Extract tables
    this.extractTables(ast, metadata.tables);

    // Extract columns
    this.extractColumns(ast, metadata.columns);

    // Check for joins
    metadata.hasJoins = this.hasJoins(ast);

    // Check for subqueries
    metadata.hasSubqueries = this.hasSubqueries(ast);

    return metadata;
  }

  private extractTables(node: any, tables: string[]): void {
    if (!node) return;

    if (node.table) {
      tables.push(node.table);
    }

    if (node.from) {
      for (const table of Array.isArray(node.from) ? node.from : [node.from]) {
        if (table.table) {
          tables.push(table.table);
        }
      }
    }

    // Recursively check all properties
    for (const key in node) {
      if (typeof node[key] === 'object') {
        this.extractTables(node[key], tables);
      }
    }
  }

  private extractColumns(node: any, columns: string[]): void {
    if (!node) return;

    if (node.column) {
      columns.push(node.column);
    }

    if (node.columns) {
      for (const col of Array.isArray(node.columns) ? node.columns : [node.columns]) {
        if (typeof col === 'string') {
          columns.push(col);
        } else if (col.expr?.column) {
          columns.push(col.expr.column);
        }
      }
    }

    // Recursively check all properties
    for (const key in node) {
      if (typeof node[key] === 'object') {
        this.extractColumns(node[key], columns);
      }
    }
  }

  private hasJoins(node: any): boolean {
    if (!node) return false;

    if (node.join || node.joins) {
      return true;
    }

    for (const key in node) {
      if (typeof node[key] === 'object' && this.hasJoins(node[key])) {
        return true;
      }
    }

    return false;
  }

  private countJoins(node: any): number {
    if (!node) return 0;

    let count = 0;

    if (node.join || node.joins) {
      count += Array.isArray(node.join || node.joins) ? 
        (node.join || node.joins).length : 1;
    }

    for (const key in node) {
      if (typeof node[key] === 'object') {
        count += this.countJoins(node[key]);
      }
    }

    return count;
  }

  private hasSubqueries(node: any): boolean {
    if (!node) return false;

    if (node.type === 'subquery') {
      return true;
    }

    for (const key in node) {
      if (typeof node[key] === 'object' && this.hasSubqueries(node[key])) {
        return true;
      }
    }

    return false;
  }

  private getSubqueryDepth(node: any, depth: number = 0): number {
    if (!node) return depth;

    let maxDepth = depth;

    if (node.type === 'subquery') {
      depth++;
    }

    for (const key in node) {
      if (typeof node[key] === 'object') {
        const subDepth = this.getSubqueryDepth(node[key], depth);
        maxDepth = Math.max(maxDepth, subDepth);
      }
    }

    return maxDepth;
  }
}
```

### Step 4: ambiente Configuration

Create `.env`:
```bash
# Server Configuration
MCP_SERVER_PORT=3001
MCP_SERVER_HOST=localhost

# Database Configurations
# PostgreSQL
PG_HOST=localhost
PG_PORT=5432
PG_DATABASE=mcp_demo
PG_USER=postgres
PG_PASSWORD=password

# MySQL
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DATABASE=mcp_demo
MYSQL_USER=root
MYSQL_PASSWORD=password

# SQLite
SQLITE_FILE=./data/mcp_demo.db

# Security
QUERY_READ_ONLY=false
MAX_QUERY_LENGTH=10000
MAX_RESULTS_PER_QUERY=1000
QUERY_TIMEOUT_MS=30000

# Connection Pool
POOL_MIN=2
POOL_MAX=10
POOL_IDLE_TIMEOUT=30000

# Logging
LOG_LEVEL=info
ENABLE_QUERY_LOGGING=true
```

### Step 5: Create Demo Database Setup

Create `scripts/setup-demo-db.sql`:
```sql
-- Create demo tables for PostgreSQL
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    stock INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    total DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id),
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

-- Insert demo data
INSERT INTO users (username, email) VALUES
    ('alice', 'alice@example.com'),
    ('bob', 'bob@example.com'),
    ('charlie', 'charlie@example.com');

INSERT INTO products (name, price, stock) VALUES
    ('Laptop', 999.99, 15),
    ('Mouse', 29.99, 100),
    ('Keyboard', 79.99, 50),
    ('Monitor', 299.99, 25);

INSERT INTO orders (user_id, total, status) VALUES
    (1, 1079.97, 'completed'),
    (2, 329.98, 'processing'),
    (1, 29.99, 'pending');

INSERT INTO order_items (order_id, product_id, quantity, price) VALUES
    (1, 1, 1, 999.99),
    (1, 3, 1, 79.99),
    (2, 4, 1, 299.99),
    (2, 2, 1, 29.99),
    (3, 2, 1, 29.99);
```

## ⏭️ Próximos Passos

Continuar to [Partee 2](./exercise1-part2) where we'll implement:
- Database query tools
- Result streaming
- Transaction management
- MCP server integration