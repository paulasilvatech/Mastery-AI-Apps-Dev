# Module 20: Troubleshooting Guide

## 🔍 Common Issues and Solutions

This guide helps you troubleshoot common problems encountered with blue-green deployments, canary releases, and feature flags.

## 🔵 Blue-Green Deployment Issues

### Issue: Traffic Not Switching to New Environment

**Symptoms:**
- Service still routing to old environment after switch
- Inconsistent routing (some requests to blue, some to green)
- Health checks passing but traffic not switching

**Solutions:**

1. **Check Load Balancer Configuration**
```bash
# Verify current backend pool
kubectl describe service deployment-demo-service

# Check endpoints
kubectl get endpoints deployment-demo-service -o yaml

# Verify selector labels
kubectl get service deployment-demo-service -o jsonpath='{.spec.selector}'
```

2. **Fix Service Selector**
```yaml
# Update service to point to new environment
kubectl patch service deployment-demo-service -p '{"spec":{"selector":{"version":"green"}}}'

# Verify the change
kubectl get service deployment-demo-service -o yaml | grep -A 2 selector
```

3. **Check DNS Caching**
```python
# Force DNS refresh in application
import socket
socket.setdefaulttimeout(1)

# Clear local DNS cache
# Linux
os.system('sudo systemd-resolve --flush-caches')
# macOS
os.system('sudo dscacheutil -flushcache')
```

### Issue: Database Migration Failures

**Symptoms:**
- New version fails to start due to schema mismatch
- Data inconsistency between environments
- Migration locks preventing deployment

**Solutions:**

1. **Check Migration Status**
```sql
-- Check current schema version
SELECT version, applied_at, success 
FROM schema_migrations 
ORDER BY version DESC LIMIT 10;

-- Check for locks
SELECT pid, usename, query_start, state, query 
FROM pg_stat_activity 
WHERE query LIKE '%ALTER TABLE%' OR query LIKE '%CREATE INDEX%';
```

2. **Fix Migration Lock**
```python
async def fix_migration_lock():
    """Release stuck migration lock"""
    try:
        # Kill blocking queries
        await db.execute("""
            SELECT pg_terminate_backend(pid) 
            FROM pg_stat_activity 
            WHERE state = 'idle in transaction' 
            AND query_start < NOW() - INTERVAL '10 minutes'
        """)
        
        # Release advisory lock
        await db.execute("SELECT pg_advisory_unlock_all()")
        
        # Reset migration state
        await db.execute("""
            UPDATE schema_migrations 
            SET locked = FALSE 
            WHERE locked = TRUE 
            AND locked_at < NOW() - INTERVAL '1 hour'
        """)
    except Exception as e:
        logger.error(f"Failed to release lock: {e}")
```

3. **Implement Backward Compatible Migrations**
```python
# Safe column addition
async def add_column_safely(table: str, column: str, type: str, default: Any):
    """Add column with backward compatibility"""
    # Step 1: Add nullable column
    await db.execute(f"""
        ALTER TABLE {table} 
        ADD COLUMN IF NOT EXISTS {column} {type}
    """)
    
    # Step 2: Backfill with default
    await db.execute(f"""
        UPDATE {table} 
        SET {column} = %s 
        WHERE {column} IS NULL
    """, (default,))
    
    # Step 3: Add NOT NULL constraint (in next deployment)
    # This allows old code to work during transition
```

### Issue: Session State Lost During Switch

**Symptoms:**
- Users logged out after deployment
- Shopping carts emptied
- Form data lost

**Solutions:**

1. **Implement Shared Session Store**
```python
# Use Redis for session storage
from redis import Redis
import pickle

class SharedSessionStore:
    def __init__(self, redis_url: str):
        self.redis = Redis.from_url(redis_url)
        self.ttl = 3600  # 1 hour
    
    async def save_session(self, session_id: str, data: dict):
        """Save session to shared store"""
        serialized = pickle.dumps(data)
        await self.redis.setex(
            f"session:{session_id}",
            self.ttl,
            serialized
        )
    
    async def load_session(self, session_id: str) -> dict:
        """Load session from shared store"""
        data = await self.redis.get(f"session:{session_id}")
        return pickle.loads(data) if data else {}
```

2. **Implement Sticky Sessions**
```nginx
# Nginx configuration for sticky sessions
upstream backend {
    ip_hash;  # Ensure same client goes to same server
    server blue-env:8000 max_fails=3 fail_timeout=30s;
    server green-env:8000 max_fails=3 fail_timeout=30s backup;
}
```

## 🐤 Canary Deployment Issues

### Issue: Canary Not Receiving Traffic

**Symptoms:**
- Canary pods running but no traffic
- Metrics show 0 requests to canary
- Service mesh not routing correctly

**Solutions:**

1. **Verify Service Mesh Configuration**
```bash
# Check Istio virtual service
kubectl get virtualservice canary-demo-vs -o yaml

# Verify destination rules
kubectl get destinationrule canary-demo-dr -o yaml

# Check pod labels
kubectl get pods -l version=canary --show-labels
```

2. **Fix Traffic Routing**
```yaml
# Update virtual service weights
kubectl patch virtualservice canary-demo-vs --type='json' -p='[
  {
    "op": "replace",
    "path": "/spec/http/0/route/1/weight",
    "value": 20
  }
]'
```

3. **Debug with Istioctl**
```bash
# Analyze configuration
istioctl analyze

# Check proxy configuration
istioctl proxy-config routes deploy/canary-v2 

# Test with curl
kubectl exec -it debug-pod -- curl -H "Host: canary-demo" http://canary-demo/health
```

### Issue: Metrics Not Showing Canary Performance

**Symptoms:**
- Prometheus not scraping canary pods
- Metrics missing version labels
- Can't differentiate stable vs canary

**Solutions:**

1. **Fix Prometheus Scraping**
```yaml
# Ensure pods have correct annotations
apiVersion: v1
kind: Pod
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
  labels:
    app: demo
    version: canary  # Critical for differentiation
```

2. **Add Version Labels to Metrics**
```python
from prometheus_client import Counter, Histogram

# Include version in metric labels
request_count = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status', 'version']
)

# Record with version
request_count.labels(
    method='GET',
    endpoint='/api/users',
    status='200',
    version=os.getenv('VERSION', 'unknown')
).inc()
```

### Issue: Canary Rollback Not Working

**Symptoms:**
- Rollback triggered but traffic still going to canary
- Old version not available
- State inconsistency

**Solutions:**

1. **Manual Rollback Steps**
```bash
# Step 1: Set canary weight to 0
kubectl patch virtualservice canary-demo-vs --type='json' -p='[
  {"op": "replace", "path": "/spec/http/0/route/1/weight", "value": 0}
]'

# Step 2: Scale down canary deployment
kubectl scale deployment canary-v2 --replicas=0

# Step 3: Verify traffic restored
kubectl exec -it debug-pod -- \
  for i in {1..10}; do curl http://canary-demo/version; done
```

2. **Implement Automated Rollback**
```python
class CanaryRollback:
    async def emergency_rollback(self, canary_name: str):
        """Emergency rollback procedure"""
        try:
            # 1. Stop canary traffic immediately
            await self.set_canary_weight(canary_name, 0)
            
            # 2. Mark canary as failed
            await self.update_canary_state(canary_name, "failed")
            
            # 3. Scale down canary pods
            await self.scale_deployment(f"{canary_name}-canary", 0)
            
            # 4. Clear any caches
            await self.clear_cdn_cache(canary_name)
            
            # 5. Notify team
            await self.send_rollback_notification(canary_name)
            
            return True
        except Exception as e:
            logger.error(f"Rollback failed: {e}")
            # Implement circuit breaker to stable
            await self.activate_kill_switch(canary_name)
            raise
```

## 🚩 Feature Flag Issues

### Issue: Feature Flag Not Evaluating Correctly

**Symptoms:**
- Users not seeing expected features
- Flag returning wrong values
- Inconsistent behavior across requests

**Solutions:**

1. **Debug Flag Evaluation**
```python
class FeatureFlagDebugger:
    def debug_evaluation(self, flag_key: str, user_context: dict):
        """Step-by-step flag evaluation debugging"""
        print(f"Debugging flag: {flag_key}")
        print(f"User context: {user_context}")
        
        # 1. Check flag exists
        flag = self.get_flag(flag_key)
        if not flag:
            print(f"ERROR: Flag {flag_key} not found")
            return
        
        # 2. Check if enabled
        if not flag.enabled:
            print(f"Flag is DISABLED, returning default: {flag.default_value}")
            return flag.default_value
        
        # 3. Check targeting rules
        for i, rule in enumerate(flag.targeting_rules):
            print(f"Evaluating rule {i}: {rule}")
            if self.matches_rule(user_context, rule):
                print(f"Rule {i} MATCHED, returning: {rule.return_value}")
                return rule.return_value
        
        # 4. Check percentage rollout
        hash_value = self.get_hash(f"{flag_key}:{user_context['user_id']}")
        print(f"Hash value: {hash_value}, rollout: {flag.rollout_percentage}%")
        
        if hash_value < flag.rollout_percentage:
            print(f"Within rollout percentage, returning: True")
            return True
        
        print(f"No rules matched, returning default: {flag.default_value}")
        return flag.default_value
```

2. **Fix Cache Inconsistency**
```python
async def fix_flag_cache():
    """Clear and rebuild flag cache"""
    # Clear all cache layers
    local_cache.clear()
    await redis_cache.flushdb()
    
    # Rebuild from source
    flags = await database.get_all_flags()
    for flag in flags:
        await redis_cache.set(
            f"flag:{flag.key}",
            flag.to_json(),
            ex=300  # 5 minute TTL
        )
    
    logger.info(f"Rebuilt cache with {len(flags)} flags")
```

### Issue: Flag Targeting Not Working

**Symptoms:**
- Specific users not getting targeted features
- Segment rules not applying
- Percentage rollout incorrect

**Solutions:**

1. **Validate User Attributes**
```python
def validate_user_context(context: dict) -> List[str]:
    """Validate user context for targeting"""
    errors = []
    
    # Check required fields
    if 'user_id' not in context:
        errors.append("user_id is required")
    
    # Validate data types
    for key, value in context.items():
        if value is None:
            errors.append(f"{key} is None")
        elif isinstance(value, float) and math.isnan(value):
            errors.append(f"{key} is NaN")
    
    # Check for common mistakes
    if 'email' in context and '@' not in str(context['email']):
        errors.append("Invalid email format")
    
    return errors
```

2. **Debug Targeting Rules**
```python
class TargetingDebugger:
    def debug_rule(self, rule: dict, context: dict):
        """Debug why a targeting rule isn't matching"""
        attribute = rule['attribute']
        operator = rule['operator']
        target_value = rule['value']
        actual_value = context.get(attribute)
        
        print(f"Rule: {attribute} {operator} {target_value}")
        print(f"Actual value: {actual_value} (type: {type(actual_value)})")
        
        if actual_value is None:
            print(f"ERROR: Attribute '{attribute}' not found in context")
            return False
        
        # Type conversion issues
        if operator in ['greater_than', 'less_than']:
            try:
                actual_num = float(actual_value)
                target_num = float(target_value)
                print(f"Numeric comparison: {actual_num} {operator} {target_num}")
            except ValueError as e:
                print(f"ERROR: Cannot convert to number: {e}")
                return False
        
        # Case sensitivity issues
        if operator in ['equals', 'contains'] and isinstance(actual_value, str):
            print(f"Note: Comparison is case-sensitive")
            print(f"  Actual: '{actual_value}'")
            print(f"  Target: '{target_value}'")
```

### Issue: Feature Flag Performance Problems

**Symptoms:**
- Slow page loads when flags enabled
- High latency on flag evaluation
- Database connection exhaustion

**Solutions:**

1. **Optimize Flag Evaluation**
```python
class OptimizedFlagEvaluator:
    def __init__(self):
        self.batch_size = 50
        self.cache_ttl = 300
        
    async def evaluate_flags_batch(self, user_id: str, flag_keys: List[str]):
        """Batch evaluate multiple flags"""
        # Single cache check
        cache_keys = [f"{user_id}:{key}" for key in flag_keys]
        cached_results = await self.redis.mget(cache_keys)
        
        results = {}
        missing_keys = []
        
        for i, (key, cached) in enumerate(zip(flag_keys, cached_results)):
            if cached:
                results[key] = json.loads(cached)
            else:
                missing_keys.append(key)
        
        # Batch fetch missing flags
        if missing_keys:
            flags = await self.db.get_flags_batch(missing_keys)
            
            # Parallel evaluation
            tasks = []
            for flag in flags:
                task = self.evaluate_single(user_id, flag)
                tasks.append(task)
            
            evaluations = await asyncio.gather(*tasks)
            
            # Cache results
            pipe = self.redis.pipeline()
            for flag, result in zip(flags, evaluations):
                results[flag.key] = result
                cache_key = f"{user_id}:{flag.key}"
                pipe.setex(cache_key, self.cache_ttl, json.dumps(result))
            
            await pipe.execute()
        
        return results
```

2. **Implement Connection Pooling**
```python
# Database connection pool
from asyncpg import create_pool

class DatabasePool:
    def __init__(self):
        self.pool = None
        
    async def init(self):
        self.pool = await create_pool(
            dsn=DATABASE_URL,
            min_size=10,
            max_size=20,
            max_queries=50000,
            max_inactive_connection_lifetime=300.0,
            command_timeout=10.0
        )
    
    async def get_flags(self, keys: List[str]):
        async with self.pool.acquire() as conn:
            # Use prepared statement for performance
            stmt = await conn.prepare("""
                SELECT key, config, enabled 
                FROM feature_flags 
                WHERE key = ANY($1::text[])
            """)
            
            return await stmt.fetch(keys)
```

## 🔄 Progressive Delivery Issues

### Issue: Deployment Pipeline Stuck

**Symptoms:**
- Pipeline not progressing to next stage
- Gates not being evaluated
- Timeout without error

**Solutions:**

1. **Debug Pipeline State**
```python
async def debug_pipeline(deployment_id: str):
    """Debug stuck deployment pipeline"""
    deployment = await get_deployment(deployment_id)
    
    print(f"Deployment: {deployment.name}")
    print(f"Status: {deployment.status}")
    print(f"Current Stage: {deployment.current_stage}")
    
    # Check stage states
    for stage in deployment.stages:
        print(f"\nStage: {stage.name}")
        print(f"  Status: {stage.status}")
        print(f"  Started: {stage.started_at}")
        print(f"  Error: {stage.error_message}")
        
        # Check dependencies
        for dep in stage.dependencies:
            dep_stage = next(s for s in deployment.stages if s.name == dep)
            print(f"  Dependency {dep}: {dep_stage.status}")
        
        # Check gates
        for gate in stage.gates:
            print(f"  Gate {gate.type}: {gate.status}")
            if gate.type == "metric_based":
                metrics = await get_gate_metrics(gate)
                print(f"    Metrics: {metrics}")
```

2. **Force Pipeline Progression**
```python
async def force_stage_completion(deployment_id: str, stage_name: str):
    """Force a stuck stage to complete"""
    # WARNING: Use only in emergencies
    
    deployment = await get_deployment(deployment_id)
    stage = next(s for s in deployment.stages if s.name == stage_name)
    
    # Log manual intervention
    await audit_log(
        action="force_stage_completion",
        deployment_id=deployment_id,
        stage=stage_name,
        user=get_current_user(),
        reason=input("Reason for manual intervention: ")
    )
    
    # Update stage status
    stage.status = "completed"
    stage.completed_at = datetime.now()
    stage.forced = True
    
    await save_deployment(deployment)
    
    # Resume pipeline
    await resume_deployment(deployment_id)
```

### Issue: Kill Switch Not Triggering

**Symptoms:**
- High error rates but kill switch not activating
- Metrics not being collected
- Thresholds not being evaluated

**Solutions:**

1. **Verify Kill Switch Configuration**
```python
async def diagnose_kill_switch(switch_id: str):
    """Diagnose why kill switch isn't triggering"""
    switch = await get_kill_switch(switch_id)
    
    print(f"Kill Switch: {switch.name}")
    print(f"State: {switch.state}")
    print(f"Auto-trigger: {switch.auto_trigger_enabled}")
    print(f"Error threshold: {switch.error_threshold}%")
    print(f"Volume threshold: {switch.volume_threshold}")
    
    # Check recent metrics
    metrics = await get_recent_metrics(switch_id, minutes=10)
    
    if not metrics:
        print("ERROR: No metrics found - check metric collection")
        return
    
    # Calculate current rates
    total_requests = sum(m['requests'] for m in metrics)
    total_errors = sum(m['errors'] for m in metrics)
    error_rate = (total_errors / total_requests * 100) if total_requests > 0 else 0
    
    print(f"\nCurrent Metrics:")
    print(f"  Requests: {total_requests}")
    print(f"  Errors: {total_errors}")
    print(f"  Error rate: {error_rate:.2f}%")
    
    # Check why not triggering
    if total_requests < switch.volume_threshold:
        print(f"Not triggering: Volume {total_requests} < {switch.volume_threshold}")
    elif error_rate < switch.error_threshold:
        print(f"Not triggering: Error rate {error_rate:.2f}% < {switch.error_threshold}%")
    else:
        print("ERROR: Should be triggering - check automation")
```

2. **Fix Metric Collection**
```python
# Ensure metrics are being sent
class MetricCollector:
    def __init__(self):
        self.buffer = []
        self.flush_interval = 10  # seconds
        self.last_flush = time.time()
    
    async def record_request(self, success: bool, latency: float):
        """Record request with automatic flushing"""
        self.buffer.append({
            'timestamp': datetime.now(),
            'success': success,
            'latency': latency
        })
        
        # Force flush if buffer is large or time elapsed
        if len(self.buffer) >= 100 or \
           time.time() - self.last_flush > self.flush_interval:
            await self.flush()
    
    async def flush(self):
        """Flush metrics to kill switch service"""
        if not self.buffer:
            return
        
        try:
            await kill_switch_service.record_metrics_batch(
                switch_id=self.switch_id,
                metrics=self.buffer
            )
            self.buffer = []
            self.last_flush = time.time()
        except Exception as e:
            logger.error(f"Failed to flush metrics: {e}")
            # Keep buffer for retry
```

## 🔧 General Troubleshooting Tools

### Health Check Script
```python
#!/usr/bin/env python3
"""
Comprehensive health check for deployment system
"""

async def health_check():
    results = {
        'timestamp': datetime.now().isoformat(),
        'status': 'healthy',
        'checks': {}
    }
    
    # Check Feature Flag Service
    try:
        flags = await flag_service.get_all_flags()
        results['checks']['feature_flags'] = {
            'status': 'healthy',
            'count': len(flags)
        }
    except Exception as e:
        results['checks']['feature_flags'] = {
            'status': 'unhealthy',
            'error': str(e)
        }
        results['status'] = 'unhealthy'
    
    # Check Kill Switch Service
    try:
        switches = await kill_switch_service.get_all_switches()
        active = sum(1 for s in switches if s.state == 'triggered')
        results['checks']['kill_switches'] = {
            'status': 'healthy',
            'total': len(switches),
            'active': active
        }
    except Exception as e:
        results['checks']['kill_switches'] = {
            'status': 'unhealthy',
            'error': str(e)
        }
        results['status'] = 'unhealthy'
    
    # Check Database
    try:
        await db.execute("SELECT 1")
        results['checks']['database'] = {'status': 'healthy'}
    except Exception as e:
        results['checks']['database'] = {
            'status': 'unhealthy',
            'error': str(e)
        }
        results['status'] = 'unhealthy'
    
    # Check Redis
    try:
        await redis.ping()
        results['checks']['redis'] = {'status': 'healthy'}
    except Exception as e:
        results['checks']['redis'] = {
            'status': 'unhealthy',
            'error': str(e)
        }
        results['status'] = 'unhealthy'
    
    return results

if __name__ == "__main__":
    import asyncio
    results = asyncio.run(health_check())
    print(json.dumps(results, indent=2))
    sys.exit(0 if results['status'] == 'healthy' else 1)
```

### Deployment Debugger
```bash
#!/bin/bash
# deployment-debugger.sh - Debug deployment issues

DEPLOYMENT_ID=$1

if [ -z "$DEPLOYMENT_ID" ]; then
    echo "Usage: $0 <deployment_id>"
    exit 1
fi

echo "=== Debugging Deployment $DEPLOYMENT_ID ==="

# Check deployment status
echo -e "\n📊 Deployment Status:"
kubectl get deployments -l deployment-id=$DEPLOYMENT_ID

# Check pods
echo -e "\n🔍 Pod Status:"
kubectl get pods -l deployment-id=$DEPLOYMENT_ID

# Check recent events
echo -e "\n📅 Recent Events:"
kubectl get events --sort-by='.lastTimestamp' | grep $DEPLOYMENT_ID | tail -20

# Check service endpoints
echo -e "\n🔗 Service Endpoints:"
kubectl get ep -l deployment-id=$DEPLOYMENT_ID

# Check logs from failed pods
echo -e "\n📝 Failed Pod Logs:"
for pod in $(kubectl get pods -l deployment-id=$DEPLOYMENT_ID --field-selector=status.phase=Failed -o name); do
    echo "=== Logs for $pod ==="
    kubectl logs $pod --tail=50
done

# Check resource usage
echo -e "\n📈 Resource Usage:"
kubectl top pods -l deployment-id=$DEPLOYMENT_ID

# Check network policies
echo -e "\n🌐 Network Policies:"
kubectl get networkpolicies -l deployment-id=$DEPLOYMENT_ID

# Generate report
echo -e "\n📄 Generating Debug Report..."
kubectl cluster-info dump --namespaces default --output-directory=/tmp/debug-$DEPLOYMENT_ID
echo "Debug report saved to /tmp/debug-$DEPLOYMENT_ID"
```

### Emergency Procedures

**Complete System Rollback:**
```python
async def emergency_rollback_all():
    """Emergency procedure to rollback everything"""
    logger.critical("EMERGENCY ROLLBACK INITIATED")
    
    # 1. Activate all kill switches
    switches = await kill_switch_service.get_all_switches()
    for switch in switches:
        await kill_switch_service.activate(
            switch.id, 
            "Emergency rollback",
            "emergency_procedure"
        )
    
    # 2. Disable all feature flags
    flags = await flag_service.get_all_flags()
    for flag in flags:
        await flag_service.update_flag(
            flag.key,
            {"enabled": False}
        )
    
    # 3. Route all traffic to stable
    await traffic_manager.set_all_stable()
    
    # 4. Stop all deployments
    active_deployments = await deployment_service.get_active()
    for deployment in active_deployments:
        await deployment_service.abort(deployment.id)
    
    # 5. Clear all caches
    await cache_service.flush_all()
    
    # 6. Notify on-call
    await alert_service.page_oncall(
        severity="critical",
        message="Emergency rollback executed"
    )
    
    logger.critical("Emergency rollback completed")
```

---

Remember: In production, always follow your incident response procedures and communicate with your team when troubleshooting deployment issues.