# Module 15: Comprehensive Performance Test Suite

import pytest
import asyncio
import time
import statistics
from typing import List, Dict, Any
import httpx
import redis.asyncio as redis
from unittest.mock import Mock, patch
import random
from datetime import datetime, timedelta

# Import modules from exercises
from app.cache.local_cache import LocalCache
from app.cache.redis_cache import RedisCache
from app.cache.cache_manager import CacheManager
from load_balancer.algorithms import RoundRobinBalancer, LeastConnectionsBalancer
from load_balancer.circuit_breaker import CircuitBreaker
from load_balancer.health_check import HealthChecker

# ==================== Exercise 1: Caching Tests ====================

class TestCachingSystem:
    """Test suite for Exercise 1: Caching Fundamentals"""
    
    @pytest.fixture
    async def local_cache(self):
        cache = LocalCache(max_size=100, default_ttl=5)
        yield cache
        await cache.clear()
    
    @pytest.fixture
    async def redis_cache(self):
        cache = RedisCache("redis://localhost:6379", prefix="test:")
        await cache.connect()
        yield cache
        await cache.clear()
        await cache.disconnect()
    
    @pytest.fixture
    async def cache_manager(self, local_cache, redis_cache):
        return CacheManager(local_cache, redis_cache, namespace="test")
    
    @pytest.mark.asyncio
    async def test_cache_performance(self, cache_manager):
        """Test cache performance improvement"""
        # Simulate slow database query
        query_time = 0.1  # 100ms
        call_count = 0
        
        async def slow_fetch():
            nonlocal call_count
            call_count += 1
            await asyncio.sleep(query_time)
            return {"data": "expensive_result", "timestamp": time.time()}
        
        # First call should be slow
        start = time.time()
        result1 = await cache_manager.get("test_key", slow_fetch)
        first_call_time = time.time() - start
        
        assert first_call_time >= query_time
        assert call_count == 1
        
        # Second call should be fast (from cache)
        start = time.time()
        result2 = await cache_manager.get("test_key", slow_fetch)
        second_call_time = time.time() - start
        
        assert second_call_time < query_time / 10  # At least 10x faster
        assert call_count == 1  # Fetch not called again
        assert result1 == result2
    
    @pytest.mark.asyncio
    async def test_cache_hit_rate(self, cache_manager):
        """Test cache hit rate under load"""
        # Populate cache with test data
        test_keys = [f"key_{i}" for i in range(50)]
        for key in test_keys:
            await cache_manager.set(key, f"value_{key}")
        
        # Simulate requests with 80/20 pattern
        total_requests = 1000
        hot_keys = test_keys[:10]  # 20% of keys
        
        hits = 0
        misses = 0
        
        for _ in range(total_requests):
            if random.random() < 0.8:  # 80% of requests
                key = random.choice(hot_keys)
            else:
                key = random.choice(test_keys)
            
            value = await cache_manager.get(key)
            if value:
                hits += 1
            else:
                misses += 1
        
        hit_rate = hits / total_requests
        assert hit_rate > 0.95  # Should achieve >95% hit rate
    
    @pytest.mark.asyncio
    async def test_cache_eviction(self, local_cache):
        """Test LRU eviction policy"""
        # Fill cache to capacity
        cache_size = 5
        local_cache.max_size = cache_size
        
        for i in range(cache_size):
            await local_cache.set(f"key_{i}", f"value_{i}")
        
        # Access some keys to update LRU order
        await local_cache.get("key_1")  # Most recently used
        await local_cache.get("key_3")
        
        # Add new item, should evict key_0 (least recently used)
        await local_cache.set("key_new", "value_new")
        
        assert await local_cache.get("key_0") is None  # Evicted
        assert await local_cache.get("key_1") == "value_1"  # Still present
        assert await local_cache.get("key_new") == "value_new"
    
    @pytest.mark.asyncio
    async def test_cache_ttl(self, cache_manager):
        """Test TTL expiration"""
        # Set with short TTL
        await cache_manager.set("expire_test", "value", ttl=1)
        
        # Should exist immediately
        assert await cache_manager.get("expire_test") == "value"
        
        # Wait for expiration
        await asyncio.sleep(1.5)
        
        # Should be expired
        assert await cache_manager.get("expire_test") is None
    
    @pytest.mark.asyncio
    async def test_concurrent_cache_access(self, cache_manager):
        """Test cache under concurrent access"""
        concurrent_users = 100
        requests_per_user = 10
        
        async def user_requests(user_id: int):
            results = []
            for i in range(requests_per_user):
                key = f"shared_key_{i % 5}"  # 5 shared keys
                
                # Simulate cache miss with fetch
                async def fetch():
                    await asyncio.sleep(0.01)
                    return f"data_{key}"
                
                value = await cache_manager.get(key, fetch)
                results.append(value)
            return results
        
        # Run concurrent users
        start = time.time()
        tasks = [user_requests(i) for i in range(concurrent_users)]
        all_results = await asyncio.gather(*tasks)
        duration = time.time() - start
        
        # Verify correctness
        for results in all_results:
            for i, value in enumerate(results):
                expected = f"data_shared_key_{i % 5}"
                assert value == expected
        
        # Should complete quickly due to caching
        assert duration < 5  # Should not take 100 * 10 * 0.01 = 10 seconds

# ==================== Exercise 2: Load Balancing Tests ====================

class TestLoadBalancing:
    """Test suite for Exercise 2: Load Balancing at Scale"""
    
    @pytest.fixture
    def servers(self):
        return [
            {"id": "server1", "url": "http://localhost:8001", "weight": 1},
            {"id": "server2", "url": "http://localhost:8002", "weight": 2},
            {"id": "server3", "url": "http://localhost:8003", "weight": 1},
        ]
    
    @pytest.mark.asyncio
    async def test_round_robin_distribution(self, servers):
        """Test round-robin load distribution"""
        balancer = RoundRobinBalancer(servers)
        
        # Track server selection
        selection_count = {s["id"]: 0 for s in servers}
        
        # Make requests
        num_requests = 300
        for _ in range(num_requests):
            server = await balancer.select_server(servers)
            selection_count[server["id"]] += 1
        
        # Verify even distribution
        expected_per_server = num_requests / len(servers)
        for server_id, count in selection_count.items():
            deviation = abs(count - expected_per_server) / expected_per_server
            assert deviation < 0.05  # Less than 5% deviation
    
    @pytest.mark.asyncio
    async def test_least_connections(self):
        """Test least connections algorithm"""
        servers = [Mock(id=f"server{i}", active_connections=0) for i in range(3)]
        balancer = LeastConnectionsBalancer(servers)
        
        # Simulate different connection counts
        servers[0].active_connections = 10
        servers[1].active_connections = 5
        servers[2].active_connections = 15
        
        # Should select server with least connections
        selected = await balancer.select_server(servers)
        assert selected.id == "server1"  # 5 connections
        
        # Simulate connection
        servers[1].active_connections += 1
        
        # Next selection
        selected = await balancer.select_server(servers)
        assert selected.id == "server1"  # Still least with 6
    
    @pytest.mark.asyncio
    async def test_circuit_breaker(self):
        """Test circuit breaker functionality"""
        breaker = CircuitBreaker(
            failure_threshold=3,
            recovery_timeout=1,
            expected_exception=Exception
        )
        
        # Simulate failures
        for i in range(3):
            with pytest.raises(Exception):
                async with breaker:
                    raise Exception("Service failure")
        
        # Circuit should be open
        assert breaker.state == "OPEN"
        
        # Should reject requests immediately
        with pytest.raises(Exception, match="Circuit breaker is OPEN"):
            async with breaker:
                pass
        
        # Wait for recovery timeout
        await asyncio.sleep(1.1)
        
        # Should transition to HALF_OPEN
        # Simulate successful request
        async with breaker:
            pass  # Success
        
        # Should be closed again
        assert breaker.state == "CLOSED"
    
    @pytest.mark.asyncio
    async def test_health_checking(self):
        """Test health check mechanism"""
        servers = [
            Mock(id="server1", url="http://localhost:8001"),
            Mock(id="server2", url="http://localhost:8002"),
        ]
        
        health_checker = HealthChecker(servers, interval=0.1)
        
        # Mock health check responses
        async def mock_health_check(server):
            if server.id == "server1":
                return Mock(status_code=200)
            else:
                raise Exception("Connection failed")
        
        health_checker.check_server_health = mock_health_check
        
        # Start health checker
        await health_checker.start()
        await asyncio.sleep(0.5)  # Let it run a few checks
        
        # Check server status
        healthy_servers = await health_checker.get_healthy_servers()
        assert len(healthy_servers) == 1
        assert healthy_servers[0].id == "server1"
        
        await health_checker.stop()
    
    @pytest.mark.asyncio
    async def test_failover(self):
        """Test failover behavior"""
        # Simulate load balancer with failing server
        class FailingServer:
            def __init__(self, fail_count):
                self.fail_count = fail_count
                self.requests = 0
            
            async def handle_request(self):
                self.requests += 1
                if self.requests <= self.fail_count:
                    raise Exception("Server error")
                return {"status": "ok"}
        
        servers = [
            FailingServer(fail_count=2),  # Fails first 2 requests
            FailingServer(fail_count=0),   # Always succeeds
        ]
        
        # Simple failover logic
        async def request_with_failover():
            for server in servers:
                try:
                    return await server.handle_request()
                except Exception:
                    continue
            raise Exception("All servers failed")
        
        # First request should failover to server2
        result = await request_with_failover()
        assert result["status"] == "ok"
        assert servers[0].requests == 1
        assert servers[1].requests == 1

# ==================== Exercise 3: Production Optimization Tests ====================

class TestProductionOptimization:
    """Test suite for Exercise 3: Production Performance"""
    
    @pytest.mark.asyncio
    async def test_database_sharding(self):
        """Test database sharding logic"""
        from core.database.sharding import ShardRouter, ShardConfig
        
        shards = [
            ShardConfig("shard1", "postgresql://localhost/shard1", ("a", "f")),
            ShardConfig("shard2", "postgresql://localhost/shard2", ("g", "m")),
            ShardConfig("shard3", "postgresql://localhost/shard3", ("n", "s")),
            ShardConfig("shard4", "postgresql://localhost/shard4", ("t", "z")),
        ]
        
        router = ShardRouter(shards)
        
        # Test consistent routing
        test_keys = ["alice", "bob", "charlie", "zebra"]
        shard_assignments = {}
        
        for key in test_keys:
            shard = router.get_shard(key)
            shard_assignments[key] = shard.shard_id
        
        # Verify same key always routes to same shard
        for key in test_keys:
            for _ in range(10):
                shard = router.get_shard(key)
                assert shard.shard_id == shard_assignments[key]
    
    @pytest.mark.asyncio
    async def test_query_optimization(self):
        """Test query optimization suggestions"""
        from core.optimization.query_optimizer import QueryOptimizer
        
        # Mock connection pool
        mock_pool = Mock()
        optimizer = QueryOptimizer(mock_pool)
        
        # Test plan analysis
        slow_plan = {
            "Node Type": "Seq Scan",
            "Plan Rows": 50000,
            "Execution Time": 500
        }
        
        suggestions = optimizer._analyze_plan(slow_plan)
        assert "index" in suggestions[0].lower()
    
    @pytest.mark.asyncio
    async def test_performance_under_load(self):
        """Integration test: Full system under load"""
        # This would typically run against a real test environment
        
        async def simulate_user_session():
            async with httpx.AsyncClient() as client:
                # Browse products
                resp = await client.get("http://localhost:8000/products")
                assert resp.status_code == 200
                
                products = resp.json()
                
                # View specific product
                if products:
                    product_id = products[0]["id"]
                    resp = await client.get(f"http://localhost:8000/products/{product_id}")
                    assert resp.status_code == 200
                
                # Add to cart
                resp = await client.post(
                    "http://localhost:8000/cart/add",
                    json={"product_id": product_id, "quantity": 1}
                )
                assert resp.status_code in [200, 201]
        
        # Run concurrent sessions
        concurrent_users = 50
        tasks = [simulate_user_session() for _ in range(concurrent_users)]
        
        start = time.time()
        results = await asyncio.gather(*tasks, return_exceptions=True)
        duration = time.time() - start
        
        # Calculate success rate
        successes = sum(1 for r in results if not isinstance(r, Exception))
        success_rate = successes / concurrent_users
        
        # Performance assertions
        assert success_rate > 0.95  # 95% success rate
        assert duration < 10  # Complete within 10 seconds
    
    @pytest.mark.asyncio
    async def test_cache_warming(self):
        """Test cache warming effectiveness"""
        from core.cache.cache_warmer import CacheWarmer
        
        cache = {}  # Simple dict as cache
        
        # Historical access pattern
        access_history = [
            ("product:1", 100),  # Accessed 100 times
            ("product:2", 80),
            ("product:3", 60),
            ("product:4", 40),
            ("product:5", 20),
        ]
        
        warmer = CacheWarmer(cache)
        
        # Warm cache based on history
        async def fetch_product(key):
            await asyncio.sleep(0.01)  # Simulate DB query
            return f"data_for_{key}"
        
        await warmer.warm_cache(access_history, fetch_product)
        
        # Verify most accessed items are cached
        assert "product:1" in cache
        assert "product:2" in cache
        assert "product:3" in cache

# ==================== Performance Benchmark Suite ====================

class PerformanceBenchmark:
    """Comprehensive performance benchmarking"""
    
    @pytest.mark.benchmark
    async def test_response_time_percentiles(self):
        """Measure response time percentiles"""
        response_times = []
        
        async with httpx.AsyncClient() as client:
            for _ in range(1000):
                start = time.time()
                resp = await client.get("http://localhost:8000/health")
                response_times.append(time.time() - start)
        
        # Calculate percentiles
        response_times.sort()
        p50 = response_times[int(len(response_times) * 0.50)]
        p95 = response_times[int(len(response_times) * 0.95)]
        p99 = response_times[int(len(response_times) * 0.99)]
        
        print(f"\nResponse Time Percentiles:")
        print(f"P50: {p50*1000:.2f}ms")
        print(f"P95: {p95*1000:.2f}ms")
        print(f"P99: {p99*1000:.2f}ms")
        
        # Assertions
        assert p50 < 0.050  # P50 < 50ms
        assert p95 < 0.100  # P95 < 100ms
        assert p99 < 0.200  # P99 < 200ms
    
    @pytest.mark.benchmark
    async def test_throughput(self):
        """Measure maximum throughput"""
        duration = 10  # seconds
        requests_completed = 0
        
        async def make_requests():
            nonlocal requests_completed
            async with httpx.AsyncClient() as client:
                while True:
                    try:
                        resp = await client.get("http://localhost:8000/products")
                        if resp.status_code == 200:
                            requests_completed += 1
                    except:
                        pass
        
        # Run multiple concurrent workers
        workers = 50
        tasks = [make_requests() for _ in range(workers)]
        
        # Run for specified duration
        await asyncio.wait_for(
            asyncio.gather(*tasks, return_exceptions=True),
            timeout=duration
        )
        
        throughput = requests_completed / duration
        print(f"\nThroughput: {throughput:.2f} requests/second")
        
        assert throughput > 1000  # Should handle >1000 req/s

# ==================== Validation Script ====================

async def validate_module_completion():
    """Validate that all module objectives are met"""
    
    print("🔍 Validating Module 15 Completion...\n")
    
    checks = {
        "Caching System": False,
        "Load Balancing": False,
        "Performance Optimization": False,
        "Monitoring": False,
        "Documentation": False,
    }
    
    # Check caching implementation
    try:
        cache = LocalCache()
        await cache.set("test", "value")
        assert await cache.get("test") == "value"
        checks["Caching System"] = True
        print("✅ Caching System implemented")
    except:
        print("❌ Caching System not working")
    
    # Check load balancing
    try:
        from load_balancer.balancer import LoadBalancer
        checks["Load Balancing"] = True
        print("✅ Load Balancing implemented")
    except:
        print("❌ Load Balancing not found")
    
    # Check performance optimizations
    try:
        from core.optimization.query_optimizer import QueryOptimizer
        checks["Performance Optimization"] = True
        print("✅ Performance Optimization implemented")
    except:
        print("❌ Performance Optimization not found")
    
    # Check monitoring
    try:
        resp = httpx.get("http://localhost:8000/metrics")
        checks["Monitoring"] = resp.status_code == 200
        print("✅ Monitoring endpoint active")
    except:
        print("❌ Monitoring endpoint not responding")
    
    # Check documentation
    import os
    docs = ["README.md", "best-practices.md", "troubleshooting.md"]
    checks["Documentation"] = all(os.path.exists(doc) for doc in docs)
    if checks["Documentation"]:
        print("✅ Documentation complete")
    else:
        print("❌ Documentation incomplete")
    
    # Summary
    print("\n📊 Module 15 Completion Summary:")
    completed = sum(checks.values())
    total = len(checks)
    print(f"Completed: {completed}/{total} ({completed/total*100:.0f}%)")
    
    if completed == total:
        print("\n🎉 Congratulations! Module 15 is complete!")
    else:
        print("\n⚠️  Some components are missing. Please review.")

if __name__ == "__main__":
    # Run validation
    asyncio.run(validate_module_completion())