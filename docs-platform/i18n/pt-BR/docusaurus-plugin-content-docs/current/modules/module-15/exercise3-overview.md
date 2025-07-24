---
sidebar_position: 3
title: "Exercise 3: Overview"
description: "## 🎯 Exercise Overview"
---

# Exercício 3: produção Performance Optimization (⭐⭐⭐ Mastery)

## 🎯 Visão Geral do Exercício

**Duração**: 60-90 minutos  
**Difficulty**: ⭐⭐⭐ (Difícil)  
**Success Rate**: 60%

In this mastery-level exercise, you'll optimize a simulated e-commerce platform to handle Black Friday-scale traffic. You'll implement advanced caching strategies, database optimization, sharding, and real-time performance monitoring using GitHub Copilot's assistance.

## 🎓 Objetivos de Aprendizagem

Ao completar este exercício, você irá:
- Optimize database queries with read replicas and sharding
- Implement advanced caching patterns (cache warming, tagging, invalidation)
- Design for 100x traffic spikes
- Build real-time performance monitoring
- Apply chaos engineering principles
- Master produção debugging techniques

## 📋 Pré-requisitos

- ✅ Completard Exercícios 1 & 2
- ✅ Understanding of database optimization
- ✅ Knowledge of distributed systems
- ✅ Experience with performance profiling

## 🏗️ What You'll Build

A highly optimized e-commerce system:

```mermaid
graph TB
    Users[100K Concurrent Users] --&gt; CDN[CDN Layer]
    CDN --&gt; WAF[Web Application Firewall]
    WAF --&gt; LB[Load Balancer]
    
    LB --&gt; API1[API Server 1]
    LB --&gt; API2[API Server 2]
    LB --&gt; API3[API Server 3]
    LB --&gt; APIN[API Server N]
    
    API1 --&gt; Cache{Distributed Cache}
    Cache --&gt; L1[L1: Local Cache]
    Cache --&gt; L2[L2: Redis Cluster]
    Cache --&gt; L3[L3: CDN Cache]
    
    API1 --&gt; Queue[Message Queue]
    Queue --&gt; Workers[Background Workers]
    
    API1 --&gt; Master[(Write DB Master)]
    API1 --&gt; Read1[(Read Replica 1)]
    API1 --&gt; Read2[(Read Replica 2)]
    API1 --&gt; ReadN[(Read Replica N)]
    
    Master --&gt; Shard1[Shard 1: Users A-F]
    Master --&gt; Shard2[Shard 2: Users G-M]
    Master --&gt; Shard3[Shard 3: Users N-S]
    Master --&gt; Shard4[Shard 4: Users T-Z]
    
    Workers --&gt; Analytics[Analytics DB]
    API1 --&gt; Monitor[Real-time Monitoring]
    
    style Users fill:#f96,stroke:#333,stroke-width:4px
    style Cache fill:#9f9,stroke:#333,stroke-width:2px
    style Monitor fill:#69f,stroke:#333,stroke-width:2px
```

## 🚀 Partee 1: System Architecture

### Step 1: Project Structure

```
exercise3-mastery/
├── api/
│   ├── __init__.py
│   ├── app.py
│   ├── models.py
│   ├── routers/
│   │   ├── products.py
│   │   ├── orders.py
│   │   ├── users.py
│   │   └── cart.py
│   └── dependencies.py
├── core/
│   ├── cache/
│   │   ├── distributed_cache.py
│   │   ├── cache_warmer.py
│   │   └── invalidation.py
│   ├── database/
│   │   ├── connection_pool.py
│   │   ├── read_replica_router.py
│   │   └── sharding.py
│   ├── monitoring/
│   │   ├── metrics_collector.py
│   │   ├── performance_profiler.py
│   │   └── alerts.py
│   └── optimization/
│       ├── query_optimizer.py
│       ├── batch_processor.py
│       └── resource_manager.py
├── background/
│   ├── workers.py
│   └── tasks.py
├── chaos/
│   ├── fault_injection.py
│   └── load_simulator.py
├── tests/
│   ├── test_performance.py
│   ├── test_scalability.py
│   └── benchmark.py
└── infrastructure/
    ├── docker-compose.yml
    ├── nginx.conf
    └── redis-cluster.conf
```

### Step 2: Define Data Models

Create `api/models.py`:

**🤖 Copilot Prompt Suggestion #1:**
```python
# Create optimized e-commerce data models with:
# - Denormalized fields for read performance
# - Proper indexing hints
# - Sharding keys
# - Audit fields
# - JSON fields for flexible attributes
# Models: User, Product, Order, OrderItem, Cart, CartItem, Inventory
# Include relationships and performance annotations
```

### Step 3: Implement Database Optimization

Create `core/database/read_replica_router.py`:

**🤖 Copilot Prompt Suggestion #2:**
```python
# Create a database router that:
# - Routes read queries to read replicas
# - Ensures writes go to master
# - Implements smart replica selection based on load
# - Handles replica lag detection
# - Supports sticky sessions for consistency
# - Monitors query performance
# Include connection pooling and circuit breaking
```

### Step 4: Avançado Caching System

Create `core/cache/distributed_cache.py`:

**🤖 Copilot Prompt Suggestion #3:**
```python
# Build a distributed caching system with:
# - Three-tier caching (local, Redis cluster, CDN)
# - Tag-based invalidation
# - Partial cache updates
# - Cache stampede prevention
# - Automatic cache warming
# - Compression for large objects
# - Cache analytics and hit rate optimization
# Support both sync and async operations
```

### Step 5: Implement SDifíciling Strategy

Create `core/database/sharding.py`:

```python
import hashlib
from typing import Any, Dict, List, Optional
from dataclasses import dataclass
import asyncpg
from contextlib import asynccontextmanager

@dataclass
class ShardConfig:
    shard_id: str
    connection_string: str
    key_range: tuple  # (start, end)
    weight: int = 1
    
class ShardRouter:
    """
    Routes database queries to appropriate shards based on sharding key.
    """
    
    def __init__(self, shard_configs: List[ShardConfig]):
        self.shard_configs = shard_configs
        self.connections = {}
        self._build_routing_table()
    
    def _build_routing_table(self):
        """Build consistent hashing ring for shard routing."""
        self.hash_ring = {}
        for config in self.shard_configs:
            for i in range(config.weight * 150):  # Virtual nodes
                hash_key = hashlib.md5(
                    f"{config.shard_id}:{i}".encode()
                ).hexdigest()
                self.hash_ring[hash_key] = config
        
        self.sorted_keys = sorted(self.hash_ring.keys())
    
    def get_shard(self, sharding_key: str) -&gt; ShardConfig:
        """Determine which shard to use for given key."""
        if not sharding_key:
            raise ValueError("Sharding key required")
        
        key_hash = hashlib.md5(sharding_key.encode()).hexdigest()
        
        # Find the first node with hash &gt;= key_hash
        for node_hash in self.sorted_keys:
            if node_hash &gt;= key_hash:
                return self.hash_ring[node_hash]
        
        # Wrap around to first node
        return self.hash_ring[self.sorted_keys[0]]
    
    @asynccontextmanager
    async def get_connection(self, sharding_key: str):
        """Get connection to appropriate shard."""
        shard = self.get_shard(sharding_key)
        
        if shard.shard_id not in self.connections:
            self.connections[shard.shard_id] = await asyncpg.connect(
                shard.connection_string
            )
        
        yield self.connections[shard.shard_id]
    
    async def execute_on_all_shards(self, query: str, *args):
        """Execute query on all shards (for aggregations)."""
        results = []
        
        for config in self.shard_configs:
            if config.shard_id not in self.connections:
                self.connections[config.shard_id] = await asyncpg.connect(
                    config.connection_string
                )
            
            conn = self.connections[config.shard_id]
            result = await conn.fetch(query, *args)
            results.extend(result)
        
        return results

# Example usage
shard_configs = [
    ShardConfig("shard1", "postgresql://localhost/ecommerce_shard1", ("a", "f")),
    ShardConfig("shard2", "postgresql://localhost/ecommerce_shard2", ("g", "m")),
    ShardConfig("shard3", "postgresql://localhost/ecommerce_shard3", ("n", "s")),
    ShardConfig("shard4", "postgresql://localhost/ecommerce_shard4", ("t", "z")),
]

router = ShardRouter(shard_configs)
```

### Step 6: High-Performance API Endpoints

Create `api/routers/products.py`:

**🤖 Copilot Prompt Suggestion #4:**
```python
# Create optimized product endpoints that:
# - Use cursor-based pagination for large datasets
# - Implement field projection to reduce payload
# - Batch multiple operations
# - Cache popular queries aggressively
# - Pre-compute faceted search results
# - Support partial updates
# - Include ETag for client caching
# Handle 10K requests/second
```

### Step 7: Real-time Monitoring

Create `core/monitoring/performance_profiler.py`:

**🤖 Copilot Prompt Suggestion #5:**
```python
# Build a real-time performance profiler that:
# - Tracks p50, p95, p99 latencies
# - Monitors database query performance
# - Profiles memory usage and GC
# - Detects performance anomalies
# - Sends alerts for degradation
# - Visualizes bottlenecks
# - Suggests optimizations using AI
# Minimal overhead (Less than 1% CPU)
```

## 🚀 Partee 2: Avançado Optimizations

### Step 8: Query Optimization

Create `core/optimization/query_optimizer.py`:

```python
import asyncio
from typing import List, Dict, Any, Optional
from dataclasses import dataclass
import asyncpg
import logging
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

@dataclass
class QueryPlan:
    query: str
    execution_time: float
    row_count: int
    plan_details: Dict[str, Any]
    suggestions: List[str]

class QueryOptimizer:
    """
    Analyzes and optimizes database queries for performance.
    """
    
    def __init__(self, connection_pool):
        self.pool = connection_pool
        self.query_cache = {}
        self.slow_query_threshold = 100  # ms
        
    async def analyze_query(self, query: str) → QueryPlan:
        """Analyze query performance and suggest optimizations."""
        async with self.pool.acquire() as conn:
            # Get query execution plan
            explain_query = f"EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) {query}"
            plan_result = await conn.fetchval(explain_query)
            
            plan_data = plan_result[0]
            execution_time = plan_data['Execution Time']
            
            # Analyze plan for issues
            suggestions = self._analyze_plan(plan_data)
            
            return QueryPlan(
                query=query,
                execution_time=execution_time,
                row_count=plan_data.get('Actual Rows', 0),
                plan_details=plan_data,
                suggestions=suggestions
            )
    
    def _analyze_plan(self, plan: Dict[str, Any]) → List[str]:
        """Analyze execution plan and provide optimization suggestions."""
        suggestions = []
        
        # Check for sequential scans on large tables
        if self._has_sequential_scan(plan):
            suggestions.append("Consider adding an index to avoid sequential scan")
        
        # Check for missing indexes
        if self._has_missing_index(plan):
            suggestions.append("Missing index detected - create suggested index")
        
        # Check for expensive sorts
        if self._has_expensive_sort(plan):
            suggestions.append("Expensive sort operation - consider adding sorted index")
        
        # Check for N+1 queries
        if self._has_nested_loop_issue(plan):
            suggestions.append("Potential N+1 query pattern - use JOIN or batch fetch")
        
        return suggestions
    
    def _has_sequential_scan(self, plan: Dict[str, Any]) → bool:
        """Check if plan contains sequential scan on large table."""
        if plan.get('Node Type') == 'Seq Scan':
            rows = plan.get('Plan Rows', 0)
            return rows > 10000
        
        # Recursively check child plans
        for child in plan.get('Plans', []):
            if self._has_sequential_scan(child):
                return True
        
        return False
    
    async def optimize_query(self, query: str) → str:
        """Automatically optimize query based on analysis."""
        plan = await self.analyze_query(query)
        
        if plan.execution_time > self.slow_query_threshold:
            logger.warning(f"Slow query detected: {plan.execution_time}ms")
            
            # Apply automatic optimizations
            optimized_query = query
            
            # Add LIMIT if missing for large result sets
            if plan.row_count > 1000 and 'LIMIT' not in query.upper():
                optimized_query += ' LIMIT 1000'
            
            # Suggest query rewrite
            if 'JOIN' in query and plan.row_count > 10000:
                logger.info("Consider using subquery or CTE for better performance")
            
            return optimized_query
        
        return query
    
    async def create_missing_indexes(self, table_stats: Dict[str, Any]):
        """Create indexes based on query patterns."""
        async with self.pool.acquire() as conn:
            # Analyze most frequent WHERE clauses
            frequent_filters = await self._get_frequent_filters(conn, table_stats)
            
            for table, columns in frequent_filters.items():
                for column in columns:
                    index_name = f"idx_{table}_{column}"
                    create_index = f"""
                        CREATE INDEX CONCURRENTLY IF NOT EXISTS {index_name}
                        ON {table} ({column})
                    """
                    try:
                        await conn.execute(create_index)
                        logger.info(f"Created index: {index_name}")
                    except Exception as e:
                        logger.error(f"Failed to create index: {e}")
```

### Step 9: Cache Warming Strategy

Create `core/cache/cache_warmer.py`:

**🤖 Copilot Prompt Suggestion #6:**
```python
# Implement intelligent cache warming that:
# - Predicts popular items using ML
# - Pre-loads cache before traffic spikes
# - Uses historical access patterns
# - Implements gradual warming to avoid thundering herd
# - Prioritizes based on business value
# - Monitors warming effectiveness
# - Adjusts strategy based on hit rates
```

### Step 10: Performance Testing

Create `tests/benchmark.py`:

```python
import asyncio
import time
import random
import statistics
from typing import List, Dict, Any
import httpx
import matplotlib.pyplot as plt
from concurrent.futures import ThreadPoolExecutor
import numpy as np

class PerformanceBenchmark:
    """
    Comprehensive performance testing for the e-commerce platform.
    """
    
    def __init__(self, base_url: str, num_users: int = 1000):
        self.base_url = base_url
        self.num_users = num_users
        self.results = {
            "response_times": [],
            "error_count": 0,
            "success_count": 0,
            "throughput": []
        }
    
    async def simulate_user_journey(self, user_id: int):
        """Simulate realistic user behavior."""
        async with httpx.AsyncClient() as client:
            try:
                # Browse products
                start = time.time()
                resp = await client.get(f"{self.base_url}/products?limit=20")
                browse_time = time.time() - start
                
                if resp.status_code != 200:
                    self.results["error_count"] += 1
                    return
                
                products = resp.json()
                
                # View product details
                for _ in range(random.randint(3, 8)):
                    product = random.choice(products)
                    await client.get(f"{self.base_url}/products/{product['id']}")
                
                # Add to cart
                cart_items = random.randint(1, 5)
                for _ in range(cart_items):
                    product = random.choice(products)
                    await client.post(
                        f"{self.base_url}/cart/add",
                        json={{{{"product_id": product['id'], "quantity": random.randint(1, 3)}}}}
                    )
                
                # Checkout
                start = time.time()
                checkout_resp = await client.post(f"{self.base_url}/orders/checkout")
                checkout_time = time.time() - start
                
                self.results["response_times"].append({
                    "browse": browse_time,
                    "checkout": checkout_time
                })
                self.results["success_count"] += 1
                
            except Exception as e:
                self.results["error_count"] += 1
                print(f"User {user_id} error: {e}")
    
    async def run_load_test(self, duration_seconds: int = 300):
        """Run sustained load test."""
        print(f"Starting load test with {self.num_users} concurrent users...")
        
        start_time = time.time()
        tasks = []
        
        while time.time() - start_time < duration_seconds:
            # Ramp up users gradually
            current_users = min(
                self.num_users,
                int((time.time() - start_time) / duration_seconds * self.num_users * 2)
            )
            
            # Create new user sessions
            new_tasks = [
                self.simulate_user_journey(i)
                for i in range(current_users - len(tasks))
            ]
            tasks.extend(new_tasks)
            
            # Calculate throughput
            elapsed = time.time() - start_time
            if elapsed > 0:
                throughput = self.results["success_count"] / elapsed
                self.results["throughput"].append(throughput)
            
            await asyncio.sleep(1)
        
        # Wait for remaining tasks
        await asyncio.gather(*tasks)
        
        return self.generate_report()
    
    def generate_report(self) → Dict[str, Any]:
        """Generate performance test report."""
        browse_times = [r["browse"] for r in self.results["response_times"]]
        checkout_times = [r["checkout"] for r in self.results["response_times"]]
        
        report = {
            "summary": {
                "total_requests": self.results["success_count"] + self.results["error_count"],
                "success_rate": self.results["success_count"] / (self.results["success_count"] + self.results["error_count"]),
                "avg_throughput": statistics.mean(self.results["throughput"]) if self.results["throughput"] else 0
            },
            "response_times": {
                "browse": {
                    "avg": statistics.mean(browse_times) if browse_times else 0,
                    "p50": statistics.median(browse_times) if browse_times else 0,
                    "p95": np.percentile(browse_times, 95) if browse_times else 0,
                    "p99": np.percentile(browse_times, 99) if browse_times else 0
                },
                "checkout": {
                    "avg": statistics.mean(checkout_times) if checkout_times else 0,
                    "p50": statistics.median(checkout_times) if checkout_times else 0,
                    "p95": np.percentile(checkout_times, 95) if checkout_times else 0,
                    "p99": np.percentile(checkout_times, 99) if checkout_times else 0
                }
            }
        }
        
        self.plot_results()
        return report
    
    def plot_results(self):
        """Visualize performance test results."""
        fig, axes = plt.subplots(2, 2, figsize=(12, 10))
        
        # Response time distribution
        browse_times = [r["browse"] * 1000 for r in self.results["response_times"]]  # Convert to ms
        axes[0, 0].hist(browse_times, bins=50, alpha=0.7)
        axes[0, 0].set_title('Browse Response Time Distribution')
        axes[0, 0].set_xlabel('Response Time (ms)')
        axes[0, 0].set_ylabel('Frequency')
        
        # Throughput over time
        axes[0, 1].plot(self.results["throughput"])
        axes[0, 1].set_title('Throughput Over Time')
        axes[0, 1].set_xlabel('Time (seconds)')
        axes[0, 1].set_ylabel('Requests/second')
        
        # Error rate
        time_windows = range(0, len(self.results["response_times"]), 100)
        error_rates = []
        for i in time_windows:
            window = self.results["response_times"][i:i+100]
            # Calculate error rate for this window
            error_rates.append(0)  # Placeholder
        
        axes[1, 0].plot(time_windows, error_rates)
        axes[1, 0].set_title('Error Rate Over Time')
        axes[1, 0].set_xlabel('Request Count')
        axes[1, 0].set_ylabel('Error Rate (%)')
        
        # Percentiles
        percentiles = [50, 75, 90, 95, 99]
        browse_percentiles = [np.percentile(browse_times, p) for p in percentiles]
        axes[1, 1].bar(percentiles, browse_percentiles)
        axes[1, 1].set_title('Response Time Percentiles')
        axes[1, 1].set_xlabel('Percentile')
        axes[1, 1].set_ylabel('Response Time (ms)')
        
        plt.tight_layout()
        plt.savefig('performance_results.png')
        print("Performance graphs saved to performance_results.png")

# Run the benchmark
async def main():
    benchmark = PerformanceBenchmark("http://localhost:8000", num_users=1000)
    report = await benchmark.run_load_test(duration_seconds=300)
    
    print("\n=== Performance Test Report ===")
    print(f"Total Requests: {report['summary']['total_requests']}")
    print(f"Success Rate: {report['summary']['success_rate']:.2%}")
    print(f"Average Throughput: {report['summary']['avg_throughput']:.2f} req/s")
    print(f"\nBrowse Response Times:")
    print(f"  Average: {report['response_times']['browse']['avg']*1000:.2f}ms")
    print(f"  P95: {report['response_times']['browse']['p95']*1000:.2f}ms")
    print(f"  P99: {report['response_times']['browse']['p99']*1000:.2f}ms")

if __name__ == "__main__":
    asyncio.run(main())
```

## ✅ Success Criteria

Your optimization is successful when:

1. **Response Time**: P95 Less than 100ms for product browsing
2. **Throughput**: Handle 10,000+ requests/second
3. **Scalability**: Linear scaling with added resources
4. **Cache Hit Rate**: Greater than 95% for popular items
5. **Database**: Less than 10ms query execution time
6. **Reliability**: 99.99% uptime during peak load
7. **Cost**: &lt;$0.001 per transaction

## 🏆 Mastery Challenges

1. **Zero-Downtime Deployment**: Implement blue-green implantação
2. **Global Distribution**: Add multi-region support
3. **ML-Powered Optimization**: Use AI to predict and prevent bottlenecks
4. **Real-time Análises**: Process 1M events/second

## 💡 produção Insights

- **Monitor Everything**: You can't optimize what you can't measure
- **Cache Invalidation**: One of the hardest problems in computer science
- **Database is Usually the Bottleneck**: Optimize queries first
- **Horizontal Scaling**: Design for it from the start
- **Failure is Normal**: Build resilience into every component

## 🎯 Final Assessment

You've mastered Módulo 15 when you can:
- Design systems that scale to millions of users
- Identify and eliminate performance bottlenecks
- Implement sophisticated caching strategies
- Build resilient, self-healing systems
- Use AI to accelerate optimization

Congratulations on completing the Performance and Scalability module! 🎉

Próximo: [Módulo 16: Security Implementation →](/docs/modules/module-16/)