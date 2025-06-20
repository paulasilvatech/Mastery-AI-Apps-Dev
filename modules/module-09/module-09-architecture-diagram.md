# Module 09: Database Architecture Overview

## System Architecture Diagram

```mermaid
graph TB
    subgraph "Application Layer"
        API[FastAPI Application]
        GC[GitHub Copilot]
        WS[WebSocket Server]
    end
    
    subgraph "Data Access Layer"
        ORM[SQLAlchemy ORM]
        QO[Query Optimizer]
        CP[Connection Pool]
        CM[Cache Manager]
    end
    
    subgraph "Caching Layer"
        Redis[(Redis)]
        MC[Memory Cache]
        CDN[CDN Cache]
    end
    
    subgraph "Primary Database"
        PG[(PostgreSQL)]
        PGV[pgvector Extension]
        TS[TimescaleDB]
        FTS[Full-Text Search]
    end
    
    subgraph "Analytics Database"
        Cosmos[(Cosmos DB)]
        VS[Vector Store]
        ES[Event Store]
    end
    
    subgraph "Monitoring"
        PM[Prometheus]
        GF[Grafana]
        AL[Alert Manager]
    end
    
    API --> ORM
    API --> CM
    GC -.-> API
    WS --> CM
    
    ORM --> QO
    QO --> CP
    CP --> PG
    
    CM --> Redis
    CM --> MC
    
    PG --> PGV
    PG --> TS
    PG --> FTS
    
    API --> Cosmos
    Cosmos --> VS
    Cosmos --> ES
    
    PG --> PM
    Redis --> PM
    PM --> GF
    PM --> AL
    
    style API fill:#e1f5fe
    style PG fill:#fff3e0
    style Redis fill:#ffebee
    style Cosmos fill:#f3e5f5
    style GC fill:#e8f5e9
```

## Data Flow Diagram

```mermaid
flowchart LR
    subgraph "Write Path"
        A1[API Request] --> A2[Validation]
        A2 --> A3[Business Logic]
        A3 --> A4[ORM Layer]
        A4 --> A5[PostgreSQL]
        A5 --> A6[Cache Invalidation]
        A6 --> A7[Event Stream]
    end
    
    subgraph "Read Path"
        B1[API Request] --> B2[Cache Check]
        B2 -->|Hit| B3[Return Cached]
        B2 -->|Miss| B4[Query Optimizer]
        B4 --> B5[Database Query]
        B5 --> B6[Transform Data]
        B6 --> B7[Update Cache]
        B7 --> B3
    end
    
    subgraph "Analytics Path"
        C1[Events] --> C2[Stream Processing]
        C2 --> C3[Aggregation]
        C3 --> C4[Cosmos DB]
        C4 --> C5[Vector Search]
        C5 --> C6[ML Models]
        C6 --> C7[Recommendations]
    end
```

## Query Optimization Process

```mermaid
graph TD
    A[Slow Query Detected] --> B{Analyze Execution Plan}
    B -->|Table Scan| C[Add Index]
    B -->|High Cost| D[Rewrite Query]
    B -->|Many Joins| E[Denormalize]
    B -->|Large Dataset| F[Add Pagination]
    
    C --> G[Test Performance]
    D --> G
    E --> G
    F --> G
    
    G -->|Improved| H[Deploy Changes]
    G -->|Not Improved| I[Further Analysis]
    
    I --> J[Check Statistics]
    I --> K[Review Schema]
    I --> L[Consider Caching]
    
    J --> B
    K --> B
    L --> M[Implement Cache]
    
    M --> G
    H --> N[Monitor Results]
    
    style A fill:#ffcdd2
    style H fill:#c8e6c9
    style N fill:#bbdefb
```

## Caching Strategy Diagram

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant Cache
    participant DB
    participant Queue
    
    Note over Client,Queue: Read Operation
    Client->>API: GET /products/123
    API->>Cache: Check Redis
    alt Cache Hit
        Cache-->>API: Return Data
        API-->>Client: 200 OK (from cache)
    else Cache Miss
        API->>DB: SELECT * FROM products
        DB-->>API: Product Data
        API->>Cache: Store in Redis (TTL: 1h)
        API-->>Client: 200 OK (from DB)
    end
    
    Note over Client,Queue: Write Operation
    Client->>API: PUT /products/123
    API->>DB: UPDATE products
    DB-->>API: Success
    API->>Cache: Invalidate product:123
    API->>Queue: Publish update event
    API-->>Client: 200 OK
    
    Note over Queue: Async Processing
    Queue->>Cache: Invalidate related caches
    Queue->>DB: Update materialized views
```

## Database Schema Relationships

```mermaid
erDiagram
    users ||--o{ orders : places
    users ||--o{ addresses : has
    users ||--o{ reviews : writes
    users ||--o{ cart_items : has
    
    products ||--o{ product_variants : has
    products }o--|| categories : belongs_to
    products ||--o{ product_images : has
    products ||--o{ reviews : receives
    
    product_variants ||--|| inventory : tracks
    product_variants ||--o{ cart_items : contains
    product_variants ||--o{ order_items : contains
    
    orders ||--o{ order_items : contains
    orders }o--|| addresses : ships_to
    orders }o--|| addresses : bills_to
    
    categories ||--o{ categories : has_subcategories
    
    reviews }o--|| orders : verified_purchase
    
    inventory ||--o{ stock_movements : logs_changes
```

## Performance Optimization Lifecycle

```mermaid
graph LR
    A[Monitor] --> B[Identify Bottleneck]
    B --> C[Analyze Root Cause]
    C --> D[Design Solution]
    D --> E[Implement Fix]
    E --> F[Test Performance]
    F --> G{Meets SLA?}
    G -->|Yes| H[Deploy]
    G -->|No| C
    H --> I[Document]
    I --> A
    
    style A fill:#e8f5e9
    style H fill:#c8e6c9
    style G fill:#fff9c4
```

## Index Strategy Decision Tree

```mermaid
graph TD
    A[Query Performance Issue] --> B{Query Type?}
    
    B -->|Equality| C[B-Tree Index]
    B -->|Range| D[B-Tree Index]
    B -->|Full-Text| E[GIN Index]
    B -->|Array/JSON| F[GIN Index]
    B -->|Spatial| G[GiST Index]
    
    C --> H{Selectivity?}
    D --> H
    
    H -->|High| I[Single Column Index]
    H -->|Low| J[Composite Index]
    
    I --> K{Frequent Updates?}
    J --> K
    
    K -->|Yes| L[Partial Index]
    K -->|No| M[Standard Index]
    
    E --> N[Configure FTS]
    F --> O[JSONB Operators]
    G --> P[PostGIS Extension]
    
    style A fill:#ffcdd2
    style I fill:#c8e6c9
    style J fill:#c8e6c9
    style L fill:#fff9c4
    style M fill:#bbdefb
```