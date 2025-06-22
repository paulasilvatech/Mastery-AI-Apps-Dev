# Module 20: Production Deployment Best Practices

## 🎯 Overview

This guide provides production-ready best practices for implementing blue-green deployments, canary releases, and feature flags. These patterns have been proven at scale by companies like Netflix, Amazon, Google, and Microsoft.

## 🔵 Blue-Green Deployment Best Practices

### 1. Database Management

**✅ DO:**
```python
# Use backward-compatible schema changes
async def apply_migration(version: str):
    """Apply database migration with compatibility check"""
    if version == "2.0":
        # Add new column with default value
        await db.execute("""
            ALTER TABLE users 
            ADD COLUMN IF NOT EXISTS preferences JSONB DEFAULT '{}'
        """)
        
        # Create compatibility view for old code
        await db.execute("""
            CREATE OR REPLACE VIEW users_v1 AS
            SELECT id, name, email FROM users
        """)
```

**❌ DON'T:**
- Make breaking schema changes without compatibility layer
- Drop columns or tables immediately
- Rename columns without views or aliases

### 2. Session Management

**✅ DO:**
```python
# Implement sticky sessions during transition
class SessionRouter:
    def route_request(self, session_id: str) -> str:
        """Route based on session to avoid split-brain"""
        if self.is_existing_session(session_id):
            return self.get_session_environment(session_id)
        else:
            return self.current_active_environment
```

**❌ DON'T:**
- Switch environments mid-session
- Lose session state during switch
- Ignore stateful components

### 3. Health Checks

**✅ DO:**
```python
@app.get("/health/deep")
async def deep_health_check():
    """Comprehensive health check for blue-green"""
    checks = {
        "database": await check_database(),
        "cache": await check_cache(),
        "external_apis": await check_external_services(),
        "disk_space": check_disk_space(),
        "memory": check_memory_usage()
    }
    
    status = "healthy" if all(checks.values()) else "unhealthy"
    return {
        "status": status,
        "checks": checks,
        "version": os.getenv("APP_VERSION"),
        "environment": os.getenv("ENVIRONMENT")
    }
```

## 🐤 Canary Deployment Best Practices

### 1. Traffic Management

**✅ DO:**
```yaml
# Use service mesh for precise traffic control
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: canary-routing
spec:
  http:
  - match:
    - headers:
        x-user-group:
          exact: canary-testers
    route:
    - destination:
        host: app-service
        subset: canary
      weight: 100
  - route:
    - destination:
        host: app-service
        subset: stable
      weight: 95
    - destination:
        host: app-service
        subset: canary
      weight: 5
```

**❌ DON'T:**
- Use random traffic splitting for stateful services
- Ignore user experience consistency
- Skip header-based routing for test users

### 2. Metric Collection

**✅ DO:**
```python
class CanaryMetrics:
    def __init__(self):
        self.metrics = {
            'stable': defaultdict(list),
            'canary': defaultdict(list)
        }
    
    async def collect_and_compare(self):
        """Collect metrics with statistical comparison"""
        # Business metrics
        stable_conversion = await self.get_conversion_rate('stable')
        canary_conversion = await self.get_conversion_rate('canary')
        
        # Performance metrics
        stable_p95 = await self.get_latency_p95('stable')
        canary_p95 = await self.get_latency_p95('canary')
        
        # Statistical significance test
        if self.sample_size > 1000:
            p_value = stats.ttest_ind(
                self.metrics['stable']['conversion'],
                self.metrics['canary']['conversion']
            ).pvalue
            
            if p_value < 0.05 and canary_conversion < stable_conversion * 0.95:
                return "rollback", "Significant conversion degradation"
        
        return "continue", "Metrics within acceptable range"
```

### 3. Rollback Triggers

**✅ DO:**
```python
# Define clear rollback criteria
ROLLBACK_RULES = {
    'error_rate': {
        'threshold': 5.0,
        'comparison': 'absolute',
        'severity': 'critical'
    },
    'latency_p99': {
        'threshold': 1.5,  # 50% increase
        'comparison': 'relative',
        'severity': 'high'
    },
    'conversion_rate': {
        'threshold': 0.95,  # 5% decrease
        'comparison': 'relative',
        'severity': 'medium'
    }
}

async def evaluate_canary_health(metrics):
    for metric, rule in ROLLBACK_RULES.items():
        if should_rollback(metrics[metric], rule):
            return False, f"Rollback triggered by {metric}"
    return True, "All metrics healthy"
```

## 🚩 Feature Flag Best Practices

### 1. Flag Lifecycle Management

**✅ DO:**
```python
class FeatureFlagLifecycle:
    """Manage feature flag lifecycle"""
    
    async def create_flag(self, config: dict):
        # Always set expiration date
        config['expires_at'] = datetime.now() + timedelta(days=90)
        
        # Include ownership information
        config['owner'] = self.get_current_user()
        config['team'] = self.get_user_team()
        
        # Add monitoring
        config['alerts'] = {
            'stale_flag_days': 30,
            'low_usage_threshold': 10
        }
        
        return await self.flag_service.create(config)
    
    async def cleanup_stale_flags(self):
        """Remove old, unused flags"""
        flags = await self.flag_service.get_all()
        
        for flag in flags:
            if flag.is_expired() or flag.usage_last_30_days() == 0:
                await self.archive_flag(flag)
```

**❌ DON'T:**
- Create flags without expiration
- Leave dead code after flag removal
- Use flags for permanent configuration

### 2. Targeting Strategies

**✅ DO:**
```python
# Implement sophisticated targeting
class TargetingEngine:
    def evaluate_user(self, user: User, flag: FeatureFlag) -> bool:
        # 1. Check kill switches first
        if self.kill_switch_active(flag.key):
            return False
        
        # 2. Check user overrides
        if user.id in flag.user_overrides:
            return flag.user_overrides[user.id]
        
        # 3. Check segment membership
        for segment in user.segments:
            if segment in flag.enabled_segments:
                return True
        
        # 4. Percentage rollout with stable hashing
        if flag.rollout_percentage > 0:
            hash_key = f"{flag.key}:{user.id}"
            if self.get_hash_bucket(hash_key) < flag.rollout_percentage:
                return True
        
        return flag.default_value
```

### 3. Performance Optimization

**✅ DO:**
```python
class OptimizedFlagService:
    def __init__(self):
        self.cache = TTLCache(maxsize=10000, ttl=300)  # 5 min cache
        self.bulk_fetch_threshold = 5
    
    async def evaluate_flags(self, user: User, flag_keys: List[str]):
        """Optimized bulk evaluation"""
        # Use bulk fetch for multiple flags
        if len(flag_keys) > self.bulk_fetch_threshold:
            return await self._bulk_evaluate(user, flag_keys)
        
        # Check cache first
        results = {}
        uncached_keys = []
        
        for key in flag_keys:
            cache_key = f"{user.id}:{key}"
            if cache_key in self.cache:
                results[key] = self.cache[cache_key]
            else:
                uncached_keys.append(key)
        
        # Fetch uncached flags
        if uncached_keys:
            fresh_results = await self._fetch_and_evaluate(user, uncached_keys)
            results.update(fresh_results)
            
            # Update cache
            for key, value in fresh_results.items():
                self.cache[f"{user.id}:{key}"] = value
        
        return results
```

## 🔄 Progressive Delivery Best Practices

### 1. Orchestration Patterns

**✅ DO:**
```python
# Implement comprehensive deployment pipelines
class ProgressiveDeliveryPipeline:
    def __init__(self):
        self.stages = []
        self.gates = []
        self.rollback_plan = []
    
    def add_stage(self, stage: DeploymentStage):
        # Validate dependencies
        self._validate_dependencies(stage)
        
        # Add monitoring
        stage.metrics = [
            'error_rate',
            'latency_p95',
            'business_kpi'
        ]
        
        # Define rollback
        stage.rollback_action = self._create_rollback_action(stage)
        
        self.stages.append(stage)
    
    async def execute(self):
        """Execute with automatic gates and monitoring"""
        for stage in self.stages:
            try:
                # Pre-flight checks
                await self._pre_flight_checks(stage)
                
                # Execute stage
                result = await stage.execute()
                
                # Validate results
                await self._validate_stage(stage, result)
                
                # Process gates
                gate_result = await self._process_gates(stage)
                if not gate_result.passed:
                    raise DeploymentGateFailure(gate_result.reason)
                    
            except Exception as e:
                await self._execute_rollback(stage, e)
                raise
```

### 2. Monitoring Integration

**✅ DO:**
```python
# Integrate with monitoring systems
class DeploymentMonitor:
    def __init__(self):
        self.prometheus = PrometheusClient()
        self.datadog = DatadogClient()
        self.pagerduty = PagerDutyClient()
    
    async def track_deployment(self, deployment_id: str):
        # Create deployment marker
        self.datadog.event(
            title=f"Deployment {deployment_id} started",
            tags=['deployment', 'progressive_delivery']
        )
        
        # Set up alerts
        alert_config = {
            'deployment_id': deployment_id,
            'conditions': [
                {
                    'metric': 'error_rate',
                    'threshold': 5.0,
                    'duration': '5m'
                },
                {
                    'metric': 'apdex',
                    'threshold': 0.85,
                    'duration': '10m'
                }
            ]
        }
        
        await self.prometheus.create_alert(alert_config)
```

### 3. GitOps Integration

**✅ DO:**
```yaml
# Define deployments as code
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: progressive-deployment
spec:
  replicas: 10
  strategy:
    canary:
      steps:
      - setWeight: 10
      - pause: {duration: 10m}
      - analysis:
          templates:
          - templateName: success-rate
          args:
          - name: service-name
            value: my-service
      - setWeight: 30
      - pause: {duration: 10m}
      - setWeight: 60
      - pause: {duration: 10m}
      - setWeight: 100
      canaryService: my-service-canary
      stableService: my-service-stable
```

## 🛡️ Security Best Practices

### 1. Feature Flag Security

**✅ DO:**
```python
class SecureFeatureFlagService:
    def __init__(self):
        self.encryption_key = self._load_encryption_key()
    
    def create_flag(self, config: dict):
        # Encrypt sensitive values
        if 'api_key' in config['value']:
            config['value']['api_key'] = self.encrypt(
                config['value']['api_key']
            )
        
        # Add audit trail
        config['created_by'] = self.get_current_user()
        config['created_at'] = datetime.now()
        config['ip_address'] = self.get_client_ip()
        
        # Validate permissions
        if not self.user_can_create_flag(config):
            raise PermissionDenied()
        
        return self._create_flag(config)
```

### 2. Deployment Security

**✅ DO:**
```python
# Implement deployment security checks
class SecureDeploymentOrchestrator:
    async def validate_deployment(self, deployment: Deployment):
        # Verify image signatures
        if not await self.verify_image_signature(deployment.image):
            raise SecurityError("Invalid image signature")
        
        # Check for vulnerabilities
        scan_result = await self.scan_image(deployment.image)
        if scan_result.critical_vulnerabilities > 0:
            raise SecurityError("Critical vulnerabilities found")
        
        # Validate deployment permissions
        if not self.user_has_permission(deployment.environment):
            raise PermissionError("Insufficient permissions")
        
        # Check compliance
        if not self.meets_compliance_requirements(deployment):
            raise ComplianceError("Deployment does not meet compliance")
```

## 📊 Observability Best Practices

### 1. Comprehensive Logging

**✅ DO:**
```python
import structlog

logger = structlog.get_logger()

class DeploymentLogger:
    def log_deployment_event(self, event: str, deployment: Deployment):
        logger.info(
            event,
            deployment_id=deployment.id,
            version=deployment.version,
            environment=deployment.environment,
            strategy=deployment.strategy,
            user=deployment.initiated_by,
            correlation_id=deployment.correlation_id
        )
    
    def log_flag_evaluation(self, flag: str, user: str, result: bool):
        logger.debug(
            "feature_flag_evaluated",
            flag_key=flag,
            user_id=user,
            result=result,
            evaluation_time_ms=self.timer.elapsed_ms()
        )
```

### 2. Distributed Tracing

**✅ DO:**
```python
from opentelemetry import trace

tracer = trace.get_tracer(__name__)

class TracedDeploymentService:
    async def deploy(self, config: dict):
        with tracer.start_as_current_span("deployment.execute") as span:
            span.set_attribute("deployment.id", config['id'])
            span.set_attribute("deployment.version", config['version'])
            
            # Trace each stage
            for stage in config['stages']:
                with tracer.start_as_current_span(f"stage.{stage['name']}"):
                    await self.execute_stage(stage)
```

## 🚀 Performance Best Practices

### 1. Caching Strategies

**✅ DO:**
```python
class CachedFeatureFlagService:
    def __init__(self):
        # Multi-level caching
        self.l1_cache = {}  # In-memory
        self.l2_cache = Redis()  # Distributed
        self.cache_ttl = {
            'flag_config': 300,  # 5 minutes
            'evaluation': 60,    # 1 minute
            'segments': 600      # 10 minutes
        }
    
    async def get_flag(self, key: str):
        # Check L1 cache
        if key in self.l1_cache:
            return self.l1_cache[key]
        
        # Check L2 cache
        cached = await self.l2_cache.get(f"flag:{key}")
        if cached:
            self.l1_cache[key] = cached
            return cached
        
        # Fetch from source
        flag = await self.fetch_flag(key)
        
        # Update caches
        await self.l2_cache.setex(
            f"flag:{key}",
            self.cache_ttl['flag_config'],
            flag
        )
        self.l1_cache[key] = flag
        
        return flag
```

### 2. Connection Pooling

**✅ DO:**
```python
class ConnectionPoolManager:
    def __init__(self):
        self.pools = {
            'redis': self._create_redis_pool(),
            'postgres': self._create_postgres_pool(),
            'http': self._create_http_pool()
        }
    
    def _create_redis_pool(self):
        return redis.ConnectionPool(
            max_connections=50,
            max_connections_per_node=10,
            connection_class=redis.Connection,
            health_check_interval=30
        )
    
    def _create_http_pool(self):
        return aiohttp.TCPConnector(
            limit=100,
            limit_per_host=30,
            ttl_dns_cache=300
        )
```

## 📋 Operational Checklists

### Pre-Deployment Checklist

- [ ] All tests passing in CI/CD
- [ ] Security scan completed
- [ ] Database migrations tested
- [ ] Rollback plan documented
- [ ] Monitoring alerts configured
- [ ] Team notified of deployment
- [ ] Feature flags configured
- [ ] Kill switches tested
- [ ] Load testing completed
- [ ] Documentation updated

### During Deployment Checklist

- [ ] Monitor error rates
- [ ] Watch latency metrics
- [ ] Check business KPIs
- [ ] Verify traffic distribution
- [ ] Monitor resource usage
- [ ] Check downstream services
- [ ] Validate data consistency
- [ ] Monitor user feedback
- [ ] Track deployment progress
- [ ] Keep stakeholders informed

### Post-Deployment Checklist

- [ ] Verify all metrics stable
- [ ] Clean up old resources
- [ ] Update documentation
- [ ] Conduct retrospective
- [ ] Archive old versions
- [ ] Update runbooks
- [ ] Train support team
- [ ] Plan flag cleanup
- [ ] Schedule follow-up review
- [ ] Celebrate success! 🎉

---

Following these best practices will help ensure your production deployments are safe, reliable, and efficient. Remember: the goal is not just to deploy code, but to deliver value to users with confidence.