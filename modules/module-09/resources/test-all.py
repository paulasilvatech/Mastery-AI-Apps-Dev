#!/usr/bin/env python3
"""
Comprehensive Test Suite for Module 09: Database Design and Optimization
Run this to validate all exercises and solutions work correctly.

Usage:
    python test_all.py              # Run all tests
    python test_all.py --exercise 1 # Run specific exercise tests
    python test_all.py --benchmark  # Run performance benchmarks
"""

import sys
import os
import asyncio
import argparse
import time
from pathlib import Path
from typing import List, Dict, Any
import pytest
import logging
from datetime import datetime, timedelta

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Test configuration
TEST_DATABASE_URL = os.getenv("TEST_DATABASE_URL", "postgresql://workshop_user:workshop_pass@localhost/ecommerce_test")

class TestRunner:
    """Comprehensive test runner for Module 09"""
    
    def __init__(self):
        self.results = {
            "passed": 0,
            "failed": 0,
            "skipped": 0,
            "errors": []
        }
    
    def print_header(self, text: str):
        """Print formatted header"""
        print("\n" + "=" * 60)
        print(f"🧪 {text}")
        print("=" * 60)
    
    def print_status(self, test_name: str, passed: bool, message: str = ""):
        """Print test status"""
        if passed:
            print(f"✅ {test_name}")
            self.results["passed"] += 1
        else:
            print(f"❌ {test_name}")
            if message:
                print(f"   Error: {message}")
            self.results["failed"] += 1
            self.results["errors"].append(f"{test_name}: {message}")
    
    async def test_environment(self):
        """Test environment setup"""
        self.print_header("Testing Environment Setup")
        
        # Test Python version
        python_version = sys.version_info
        self.print_status(
            "Python Version",
            python_version.major == 3 and python_version.minor >= 11,
            f"Found Python {python_version.major}.{python_version.minor}"
        )
        
        # Test required packages
        required_packages = [
            "sqlalchemy", "psycopg2", "redis", "fastapi",
            "pytest", "alembic", "asyncpg"
        ]
        
        for package in required_packages:
            try:
                __import__(package.replace("-", "_"))
                self.print_status(f"Package: {package}", True)
            except ImportError:
                self.print_status(f"Package: {package}", False, "Not installed")
        
        # Test database connections
        await self.test_database_connections()
    
    async def test_database_connections(self):
        """Test database connections"""
        # Test PostgreSQL
        try:
            import psycopg2
            conn = psycopg2.connect(TEST_DATABASE_URL)
            cursor = conn.cursor()
            cursor.execute("SELECT version();")
            version = cursor.fetchone()[0]
            conn.close()
            self.print_status("PostgreSQL Connection", True, version.split(',')[0])
        except Exception as e:
            self.print_status("PostgreSQL Connection", False, str(e))
        
        # Test Redis
        try:
            import redis
            r = redis.from_url("redis://localhost:6379/0")
            r.ping()
            self.print_status("Redis Connection", True)
        except Exception as e:
            self.print_status("Redis Connection", False, str(e))
        
        # Test AsyncPG
        try:
            import asyncpg
            conn = await asyncpg.connect(TEST_DATABASE_URL)
            version = await conn.fetchval("SELECT version();")
            await conn.close()
            self.print_status("AsyncPG Connection", True)
        except Exception as e:
            self.print_status("AsyncPG Connection", False, str(e))
    
    def test_exercise1(self):
        """Test Exercise 1: E-Commerce Database Schema"""
        self.print_header("Testing Exercise 1: E-Commerce Schema")
        
        try:
            # Import models
            from exercises.exercise1_easy.solution.models import (
                Base, User, Product, Order, create_database
            )
            
            # Test model imports
            self.print_status("Model Imports", True)
            
            # Run pytest for exercise 1
            exit_code = pytest.main([
                "exercises/exercise1_easy/solution/test_schema.py",
                "-v", "--tb=short"
            ])
            
            self.print_status("Exercise 1 Tests", exit_code == 0)
            
        except Exception as e:
            self.print_status("Exercise 1", False, str(e))
    
    async def test_exercise2(self):
        """Test Exercise 2: Query Performance Optimization"""
        self.print_header("Testing Exercise 2: Query Optimization")
        
        try:
            # Import optimization classes
            from exercises.exercise2_medium.solution.optimize import (
                QueryAnalyzer, CacheManager, OptimizedQueries
            )
            
            self.print_status("Optimization Classes Import", True)
            
            # Test query analyzer
            from sqlalchemy import create_engine
            from sqlalchemy.orm import sessionmaker
            
            engine = create_engine(TEST_DATABASE_URL)
            Session = sessionmaker(bind=engine)
            session = Session()
            
            analyzer = QueryAnalyzer(session)
            self.print_status("Query Analyzer Creation", True)
            
            # Test cache manager
            cache = CacheManager()
            await cache.init()
            
            # Test cache operations
            test_key = "test:key"
            test_value = {"data": "test"}
            
            # Test get_or_set
            async def fetch_func():
                return test_value
            
            result = await cache.get_or_set(test_key, fetch_func)
            self.print_status("Cache Operations", result == test_value)
            
            session.close()
            
        except Exception as e:
            self.print_status("Exercise 2", False, str(e))
    
    async def test_exercise3(self):
        """Test Exercise 3: Real-time Analytics System"""
        self.print_header("Testing Exercise 3: Real-time Analytics")
        
        try:
            # Import analytics components
            from exercises.exercise3_hard.solution.analytics import (
                DatabaseManager, VectorSearchEngine, EventProcessor,
                TimeSeriesAnalytics, AnalyticsEngine
            )
            
            self.print_status("Analytics Components Import", True)
            
            # Test analytics engine initialization
            analytics = AnalyticsEngine()
            # Note: Don't actually initialize to avoid external dependencies
            self.print_status("Analytics Engine Creation", True)
            
            # Test event creation
            from exercises.exercise3_hard.solution.analytics import Event, EventType
            
            event = Event(
                event_id="test-123",
                user_id="user-123",
                session_id="session-123",
                event_type=EventType.PAGE_VIEW,
                timestamp=datetime.utcnow(),
                properties={"page": "/home"}
            )
            
            self.print_status("Event Creation", True)
            
        except Exception as e:
            self.print_status("Exercise 3", False, str(e))
    
    async def run_performance_benchmarks(self):
        """Run performance benchmarks"""
        self.print_header("Running Performance Benchmarks")
        
        try:
            import asyncpg
            import numpy as np
            
            # Connect to database
            conn = await asyncpg.connect(TEST_DATABASE_URL)
            
            # Benchmark 1: Simple query
            query_times = []
            query = "SELECT COUNT(*) FROM pg_tables"
            
            for _ in range(100):
                start = time.time()
                await conn.fetchval(query)
                query_times.append(time.time() - start)
            
            avg_time = np.mean(query_times) * 1000
            p95_time = np.percentile(query_times, 95) * 1000
            
            self.print_status(
                "Simple Query Performance",
                avg_time < 10,  # Should be under 10ms
                f"Avg: {avg_time:.2f}ms, P95: {p95_time:.2f}ms"
            )
            
            # Benchmark 2: Connection pool
            pool = await asyncpg.create_pool(
                TEST_DATABASE_URL,
                min_size=5,
                max_size=10
            )
            
            pool_times = []
            for _ in range(100):
                start = time.time()
                async with pool.acquire() as conn:
                    await conn.fetchval("SELECT 1")
                pool_times.append(time.time() - start)
            
            avg_pool_time = np.mean(pool_times) * 1000
            
            self.print_status(
                "Connection Pool Performance",
                avg_pool_time < 5,  # Should be under 5ms
                f"Avg: {avg_pool_time:.2f}ms"
            )
            
            await pool.close()
            await conn.close()
            
        except Exception as e:
            self.print_status("Performance Benchmarks", False, str(e))
    
    def test_best_practices(self):
        """Validate best practices are followed"""
        self.print_header("Validating Best Practices")
        
        checks = [
            ("README.md exists", Path("README.md").exists()),
            ("Prerequisites documented", Path("prerequisites.md").exists()),
            ("Troubleshooting guide", Path("troubleshooting.md").exists()),
            ("Best practices guide", Path("best-practices.md").exists()),
            (".env.example exists", Path(".env.example").exists() or Path(".env").exists()),
            ("Tests directory exists", Path("tests").exists() or Path("exercises").exists()),
        ]
        
        for check_name, passed in checks:
            self.print_status(check_name, passed)
    
    def generate_report(self):
        """Generate test report"""
        self.print_header("Test Summary")
        
        total = self.results["passed"] + self.results["failed"] + self.results["skipped"]
        
        print(f"\nTotal Tests: {total}")
        print(f"✅ Passed: {self.results['passed']}")
        print(f"❌ Failed: {self.results['failed']}")
        print(f"⏭️  Skipped: {self.results['skipped']}")
        
        if self.results["failed"] > 0:
            print("\n❌ Failed Tests:")
            for error in self.results["errors"]:
                print(f"  - {error}")
        
        success_rate = (self.results["passed"] / total * 100) if total > 0 else 0
        print(f"\n📊 Success Rate: {success_rate:.1f}%")
        
        if success_rate == 100:
            print("\n🎉 All tests passed! Module 09 is ready to go!")
        elif success_rate >= 80:
            print("\n⚠️  Most tests passed, but some issues need attention.")
        else:
            print("\n❌ Many tests failed. Please check your setup.")
        
        return 0 if self.results["failed"] == 0 else 1

async def main():
    """Main test execution"""
    parser = argparse.ArgumentParser(description="Test Module 09 exercises and setup")
    parser.add_argument("--exercise", type=int, help="Test specific exercise (1, 2, or 3)")
    parser.add_argument("--benchmark", action="store_true", help="Run performance benchmarks")
    parser.add_argument("--quick", action="store_true", help="Run quick tests only")
    
    args = parser.parse_args()
    
    runner = TestRunner()
    
    print("🚀 Module 09: Database Design and Optimization - Test Suite")
    print("=" * 60)
    
    # Always test environment
    await runner.test_environment()
    
    if args.exercise:
        # Test specific exercise
        if args.exercise == 1:
            runner.test_exercise1()
        elif args.exercise == 2:
            await runner.test_exercise2()
        elif args.exercise == 3:
            await runner.test_exercise3()
        else:
            print(f"Invalid exercise number: {args.exercise}")
    elif args.benchmark:
        # Run benchmarks only
        await runner.run_performance_benchmarks()
    elif args.quick:
        # Quick tests only
        runner.test_best_practices()
    else:
        # Run all tests
        runner.test_exercise1()
        await runner.test_exercise2()
        await runner.test_exercise3()
        runner.test_best_practices()
        
        if not args.quick:
            await runner.run_performance_benchmarks()
    
    # Generate report
    return runner.generate_report()

if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)