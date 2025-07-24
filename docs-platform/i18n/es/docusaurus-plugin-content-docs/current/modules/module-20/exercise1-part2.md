---
sidebar_position: 9
title: "Exercise 1: Part 2"
description: "## 🧪 Part 3: Testing and Validation"
---

# Ejercicio 1: Blue-Green despliegue - Partee 2 (⭐ Foundation)

## 🧪 Partee 3: Testing and Validation

### Step 5: Create Service Configuration

**Copilot Prompt Suggestion:**
```yaml
# Create a Kubernetes service that:
# - Uses selector to route traffic between blue/green
# - Exposes port 80 mapping to container port 8000
# - Includes annotations for Azure load balancer
# - Has session affinity for consistent routing
# Make it easy to switch between environments
```

**Expected Output:**
Create `kubernetes/service.yaml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: deployment-demo-service
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "false"
    service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: "/health"
spec:
  type: LoadBalancer
  sessionAffinity: ClientIP
  selector:
    app: deployment-demo
    version: blue  # This is what we'll switch between blue/green
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8000
      name: http
```

### Step 6: Create Database Migration Strategy

**Copilot Prompt Suggestion:**
```python
# Create a database migration handler that:
# - Supports backward compatible migrations
# - Checks schema version before deployment
# - Can run migrations in dry-run mode
# - Logs all migration steps
# - Handles rollback if needed
# Use alembic for migrations with async support
```

**Expected Output:**
Create `database/migration_handler.py`:
```python
import asyncio
import logging
from typing import Optional, List
from alembic import command
from alembic.config import Config
from alembic.script import ScriptDirectory
from alembic.migration import MigrationContext
from sqlalchemy.ext.asyncio import create_async_engine
import asyncpg

logger = logging.getLogger(__name__)

class BlueGreenMigrationHandler:
    """
    Handles database migrations for blue-green deployments
    Ensures backward compatibility during transition period
    """
    
    def __init__(self, database_url: str):
        self.database_url = database_url
        self.alembic_cfg = Config("alembic.ini")
        
    async def check_migration_compatibility(self, target_revision: str) -&gt; bool:
        """
        Check if migration is backward compatible
        """
        try:
            # Get current revision
            current = await self.get_current_revision()
            
            # Get migration scripts
            script_dir = ScriptDirectory.from_config(self.alembic_cfg)
            
            # Check if migrations between current and target are marked as compatible
            revisions = list(script_dir.walk_revisions(target_revision, current))
            
            for revision in revisions:
                # Check for backward_compatible flag in migration file
                if hasattr(revision.module, 'backward_compatible'):
                    if not revision.module.backward_compatible:
                        logger.warning(f"Migration {revision.revision} is not backward compatible")
                        return False
                        
            logger.info(f"All migrations from {current} to {target_revision} are backward compatible")
            return True
            
        except Exception as e:
            logger.error(f"Failed to check migration compatibility: {e}")
            return False
    
    async def get_current_revision(self) -&gt; Optional[str]:
        """
        Get current database revision
        """
        engine = create_async_engine(self.database_url)
        
        async with engine.begin() as conn:
            context = await conn.run_sync(
                lambda sync_conn: MigrationContext.configure(sync_conn)
            )
            current_rev = await conn.run_sync(
                lambda sync_conn: context.get_current_revision()
            )
            
        await engine.dispose()
        return current_rev
    
    async def run_migrations(self, target_revision: str, dry_run: bool = False) -&gt; bool:
        """
        Run migrations to target revision
        """
        try:
            logger.info(f"Running migrations to {target_revision} (dry_run={dry_run})")
            
            if dry_run:
                # Just check what would be executed
                command.history(self.alembic_cfg, verbose=True)
                return True
            
            # Check compatibility first
            if not await self.check_migration_compatibility(target_revision):
                logger.error("Migrations are not backward compatible")
                return False
            
            # Run the migrations
            command.upgrade(self.alembic_cfg, target_revision)
            
            logger.info(f"Successfully migrated to {target_revision}")
            return True
            
        except Exception as e:
            logger.error(f"Migration failed: {e}")
            return False
    
    async def create_compatibility_view(self, table_name: str, 
                                      old_columns: List[str], 
                                      new_columns: List[str]):
        """
        Create database view for backward compatibility
        """
        conn = await asyncpg.connect(self.database_url)
        
        try:
            # Create view that maps old column names to new
            view_name = f"{table_name}_compat"
            
            column_mapping = ", ".join([
                f"{new} as {old}" for old, new in zip(old_columns, new_columns)
            ])
            
            query = f"""
            CREATE OR REPLACE VIEW {view_name} AS
            SELECT {column_mapping}
            FROM {table_name};
            """
            
            await conn.execute(query)
            logger.info(f"Created compatibility view {view_name}")
            
        finally:
            await conn.close()
```

### Step 7: Create Green despliegue Configuration

**Copilot Prompt Suggestion:**
```yaml
# Create a green environment deployment that mirrors blue but with:
# - Different version labels
# - Updated image tags
# - Same resource configuration
# - Anti-affinity rules to spread across nodes
# - Readiness gates for careful rollout
```

**Expected Output:**
Create `kubernetes/green-despliegue.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-green
  labels:
    app: deployment-demo
    version: green
spec:
  replicas: 2
  selector:
    matchLabels:
      app: deployment-demo
      version: green
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: deployment-demo
        version: green
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - deployment-demo
              topologyKey: kubernetes.io/hostname
      containers:
      - name: app
        image: module20.azurecr.io/deployment-demo:2.0.0
        ports:
        - containerPort: 8000
        env:
        - name: APP_VERSION
          value: "2.0.0"
        - name: ENVIRONMENT
          value: "green"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database-url
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 3
        startupProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 0
          periodSeconds: 10
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 30
      readinessGates:
      - conditionType: "deployment-demo/ready"
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-green-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: deployment-demo
      version: green
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-green-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app-green
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 60
```

## 🚀 Partee 4: despliegue Execution

### Step 8: Create Monitoring Panel

**Copilot Prompt Suggestion:**
```python
# Create a monitoring script that:
# - Tracks deployment progress in real-time
# - Monitors application metrics from both environments
# - Compares error rates between blue and green
# - Generates deployment report
# - Sends alerts if issues detected
# Use prometheus client and matplotlib for visualization
```

**Expected Output:**
Create `monitoring/despliegue_monitor.py`:
```python
import asyncio
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import logging
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from prometheus_client.parser import text_string_to_metric_families
import httpx
import json

logger = logging.getLogger(__name__)

class DeploymentMonitor:
    """
    Monitors blue-green deployment progress and health
    """
    
    def __init__(self, prometheus_url: str, blue_url: str, green_url: str):
        self.prometheus_url = prometheus_url
        self.blue_url = blue_url
        self.green_url = green_url
        self.metrics_history = {
            'blue': {{'timestamps': [], 'error_rate': [], 'latency': [], 'requests': []}},
            'green': {{'timestamps': [], 'error_rate': [], 'latency': [], 'requests': []}}
        }
        
    async def collect_metrics(self, environment: str, url: str) -&gt; Dict[str, float]:
        """
        Collect metrics from environment
        """
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(f"{url}/metrics", timeout=5.0)
                
                if response.status_code == 200:
                    metrics = response.json()
                    
                    # Calculate error rate
                    total_requests = metrics.get('requests_total', 0)
                    total_errors = metrics.get('errors_total', 0)
                    error_rate = (total_errors / total_requests * 100) if total_requests &gt; 0 else 0
                    
                    return {
                        'error_rate': error_rate,
                        'latency': metrics.get('latency_seconds', 0),
                        'requests': total_requests,
                        'version': metrics.get('version', 'unknown')
                    }
                    
        except Exception as e:
            logger.error(f"Failed to collect metrics from {environment}: {e}")
            
        return {{'error_rate': 0, 'latency': 0, 'requests': 0, 'version': 'unknown'}}
    
    async def monitor_deployment(self, duration_minutes: int = 10, interval_seconds: int = 30):
        """
        Monitor deployment for specified duration
        """
        start_time = datetime.now()
        end_time = start_time + timedelta(minutes=duration_minutes)
        
        logger.info(f"Starting deployment monitoring for {duration_minutes} minutes")
        
        while datetime.now() &lt; end_time:
            # Collect metrics from both environments
            blue_metrics = await self.collect_metrics('blue', self.blue_url)
            green_metrics = await self.collect_metrics('green', self.green_url)
            
            # Store metrics
            timestamp = datetime.now()
            
            self.metrics_history['blue']['timestamps'].append(timestamp)
            self.metrics_history['blue']['error_rate'].append(blue_metrics['error_rate'])
            self.metrics_history['blue']['latency'].append(blue_metrics['latency'])
            self.metrics_history['blue']['requests'].append(blue_metrics['requests'])
            
            self.metrics_history['green']['timestamps'].append(timestamp)
            self.metrics_history['green']['error_rate'].append(green_metrics['error_rate'])
            self.metrics_history['green']['latency'].append(green_metrics['latency'])
            self.metrics_history['green']['requests'].append(green_metrics['requests'])
            
            # Check for anomalies
            await self.check_anomalies(blue_metrics, green_metrics)
            
            # Log current status
            logger.info(f"Blue - Error Rate: {blue_metrics['error_rate']:.2f}%, "
                       f"Latency: {blue_metrics['latency']:.3f}s, "
                       f"Requests: {blue_metrics['requests']}")
            logger.info(f"Green - Error Rate: {green_metrics['error_rate']:.2f}%, "
                       f"Latency: {green_metrics['latency']:.3f}s, "
                       f"Requests: {green_metrics['requests']}")
            
            await asyncio.sleep(interval_seconds)
        
        # Generate report
        self.generate_report()
    
    async def check_anomalies(self, blue_metrics: Dict, green_metrics: Dict):
        """
        Check for deployment anomalies
        """
        # Check error rate threshold
        if green_metrics['error_rate'] &gt; 5.0:
            logger.warning(f"HIGH ERROR RATE in green environment: {green_metrics['error_rate']:.2f}%")
            await self.send_alert("High error rate detected in green environment", green_metrics)
        
        # Check latency increase
        if green_metrics['latency'] &gt; blue_metrics['latency'] * 1.5:
            logger.warning(f"LATENCY DEGRADATION in green: {green_metrics['latency']:.3f}s vs {blue_metrics['latency']:.3f}s")
            await self.send_alert("Latency degradation in green environment", green_metrics)
    
    async def send_alert(self, message: str, metrics: Dict):
        """
        Send alert (implement your alerting mechanism)
        """
        alert_data = {
            'timestamp': datetime.now().isoformat(),
            'message': message,
            'metrics': metrics,
            'severity': 'warning'
        }
        
        # In production, send to alerting system
        logger.warning(f"ALERT: {json.dumps(alert_data, indent=2)}")
    
    def generate_report(self):
        """
        Generate deployment monitoring report with visualizations
        """
        fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 10))
        fig.suptitle('Blue-Green Deployment Monitoring Report', fontsize=16)
        
        # Error Rate Comparison
        ax1.plot(self.metrics_history['blue']['timestamps'], 
                self.metrics_history['blue']['error_rate'], 
                'b-', label='Blue', linewidth=2)
        ax1.plot(self.metrics_history['green']['timestamps'], 
                self.metrics_history['green']['error_rate'], 
                'g-', label='Green', linewidth=2)
        ax1.set_xlabel('Time')
        ax1.set_ylabel('Error Rate (%)')
        ax1.set_title('Error Rate Comparison')
        ax1.legend()
        ax1.grid(True, alpha=0.3)
        
        # Latency Comparison
        ax2.plot(self.metrics_history['blue']['timestamps'], 
                self.metrics_history['blue']['latency'], 
                'b-', label='Blue', linewidth=2)
        ax2.plot(self.metrics_history['green']['timestamps'], 
                self.metrics_history['green']['latency'], 
                'g-', label='Green', linewidth=2)
        ax2.set_xlabel('Time')
        ax2.set_ylabel('Latency (seconds)')
        ax2.set_title('Response Latency Comparison')
        ax2.legend()
        ax2.grid(True, alpha=0.3)
        
        # Request Volume
        ax3.plot(self.metrics_history['blue']['timestamps'], 
                self.metrics_history['blue']['requests'], 
                'b-', label='Blue', linewidth=2)
        ax3.plot(self.metrics_history['green']['timestamps'], 
                self.metrics_history['green']['requests'], 
                'g-', label='Green', linewidth=2)
        ax3.set_xlabel('Time')
        ax3.set_ylabel('Total Requests')
        ax3.set_title('Request Volume')
        ax3.legend()
        ax3.grid(True, alpha=0.3)
        
        # Summary Statistics
        ax4.axis('off')
        
        # Calculate statistics
        blue_avg_error = sum(self.metrics_history['blue']['error_rate']) / len(self.metrics_history['blue']['error_rate'])
        green_avg_error = sum(self.metrics_history['green']['error_rate']) / len(self.metrics_history['green']['error_rate'])
        blue_avg_latency = sum(self.metrics_history['blue']['latency']) / len(self.metrics_history['blue']['latency'])
        green_avg_latency = sum(self.metrics_history['green']['latency']) / len(self.metrics_history['green']['latency'])
        
        summary_text = f"""
        Deployment Summary
        
        Blue Environment:
        - Average Error Rate: {blue_avg_error:.2f}%
        - Average Latency: {blue_avg_latency:.3f}s
        - Total Requests: {self.metrics_history['blue']['requests'][-1] if self.metrics_history['blue']['requests'] else 0}
        
        Green Environment:
        - Average Error Rate: {green_avg_error:.2f}%
        - Average Latency: {green_avg_latency:.3f}s
        - Total Requests: {self.metrics_history['green']['requests'][-1] if self.metrics_history['green']['requests'] else 0}
        
        Deployment Status: {'✅ Healthy' if green_avg_error &lt; 5.0 else '⚠️ Issues Detected'}
        """
        
        ax4.text(0.1, 0.5, summary_text, fontsize=12, verticalalignment='center')
        
        # Format time axis
        for ax in [ax1, ax2, ax3]:
            ax.xaxis.set_major_formatter(mdates.DateFormatter('%H:%M'))
            ax.xaxis.set_major_locator(mdates.MinuteLocator(interval=5))
            plt.setp(ax.xaxis.get_majorticklabels(), rotation=45)
        
        plt.tight_layout()
        
        # Save report
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        report_filename = f'deployment_report_{timestamp}.png'
        plt.savefig(report_filename, dpi=300, bbox_inches='tight')
        logger.info(f"Deployment report saved to {report_filename}")
        
        plt.close()

# Usage example
async def main():
    monitor = DeploymentMonitor(
        prometheus_url="http://prometheus:9090",
        blue_url="http://app-blue:8000",
        green_url="http://app-green:8000"
    )
    
    await monitor.monitor_deployment(duration_minutes=10, interval_seconds=30)

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(main())
```

## ✅ Partee 5: Ejercicio Validation

### Step 9: Create Validation Tests

**Copilot Prompt Suggestion:**
```python
# Create comprehensive tests for blue-green deployment that:
# - Verify both environments are healthy before switch
# - Test traffic routing works correctly
# - Validate zero-downtime during switch
# - Check rollback functionality
# - Measure switch duration
# Use pytest with async support
```

**Expected Output:**
Create `tests/test_blue_green_despliegue.py`:
```python
import pytest
import asyncio
import httpx
from datetime import datetime
import time
from typing import List, Dict
import statistics

@pytest.mark.asyncio
class TestBlueGreenDeployment:
    """
    Comprehensive tests for blue-green deployment
    """
    
    async def test_environment_health(self, blue_url: str, green_url: str):
        """
        Test that both environments are healthy
        """
        async with httpx.AsyncClient() as client:
            # Test blue environment
            blue_response = await client.get(f"{blue_url}/health")
            assert blue_response.status_code == 200
            blue_data = blue_response.json()
            assert blue_data['status'] == 'healthy'
            assert blue_data['environment'] == 'blue'
            
            # Test green environment
            green_response = await client.get(f"{green_url}/health")
            assert green_response.status_code == 200
            green_data = green_response.json()
            assert green_data['status'] == 'healthy'
            assert green_data['environment'] == 'green'
    
    async def test_zero_downtime_switch(self, service_url: str):
        """
        Test that there's no downtime during environment switch
        """
        results = []
        switch_initiated = False
        
        async def continuous_requests():
            """Make continuous requests during switch"""
            async with httpx.AsyncClient(timeout=httpx.Timeout(2.0)) as client:
                while len(results) &lt; 100:  # Make 100 requests
                    try:
                        start = time.time()
                        response = await client.get(f"{service_url}/health")
                        duration = time.time() - start
                        
                        results.append({
                            'timestamp': datetime.now(),
                            'status_code': response.status_code,
                            'duration': duration,
                            'environment': response.json().get('environment'),
                            'success': True
                        })
                    except Exception as e:
                        results.append({
                            'timestamp': datetime.now(),
                            'status_code': 0,
                            'duration': 0,
                            'error': str(e),
                            'success': False
                        })
                    
                    await asyncio.sleep(0.1)  # 10 requests per second
        
        # Start continuous requests
        request_task = asyncio.create_task(continuous_requests())
        
        # Wait for initial requests
        await asyncio.sleep(2)
        
        # Trigger environment switch (in real test, call deployment script)
        # For now, just mark when switch would happen
        switch_initiated = True
        
        # Wait for requests to complete
        await request_task
        
        # Analyze results
        failed_requests = [r for r in results if not r['success']]
        success_rate = (len(results) - len(failed_requests)) / len(results) * 100
        
        # Assert zero downtime
        assert len(failed_requests) == 0, f"Had {len(failed_requests)} failed requests during switch"
        assert success_rate == 100.0, f"Success rate was {success_rate}%, expected 100%"
        
        # Check latency didn't spike
        latencies = [r['duration'] for r in results if r['success']]
        avg_latency = statistics.mean(latencies)
        max_latency = max(latencies)
        
        assert max_latency &lt; 2.0, f"Maximum latency {max_latency}s exceeded 2s threshold"
        assert avg_latency &lt; 0.5, f"Average latency {avg_latency}s exceeded 0.5s threshold"
    
    async def test_traffic_distribution(self, service_url: str, expected_env: str):
        """
        Test that all traffic goes to expected environment
        """
        async with httpx.AsyncClient() as client:
            environments_hit = []
            
            # Make 50 requests
            for _ in range(50):
                response = await client.get(f"{service_url}/")
                data = response.json()
                environments_hit.append(data.get('environment'))
            
            # All requests should hit the same environment
            unique_envs = set(environments_hit)
            assert len(unique_envs) == 1, f"Traffic split across environments: {unique_envs}"
            assert unique_envs.pop() == expected_env, f"Traffic not going to {expected_env}"
    
    async def test_rollback_capability(self, deployment_script: str):
        """
        Test that rollback works correctly
        """
        # This would integrate with actual deployment script
        # For now, we'll simulate the test structure
        
        # Record initial state
        initial_env = await self.get_active_environment()
        
        # Deploy to new environment
        deploy_success = await self.deploy_to_environment('green')
        assert deploy_success, "Deployment to green failed"
        
        # Verify switched
        current_env = await self.get_active_environment()
        assert current_env == 'green', "Did not switch to green"
        
        # Trigger rollback
        rollback_success = await self.rollback_deployment()
        assert rollback_success, "Rollback failed"
        
        # Verify rolled back
        final_env = await self.get_active_environment()
        assert final_env == initial_env, "Did not roll back to initial environment"
    
    async def test_database_compatibility(self, db_url: str):
        """
        Test database works with both application versions
        """
        # This would test that database schema is compatible
        # with both blue and green application versions
        pass
    
    async def get_active_environment(self) -&gt; str:
        """Helper to get current active environment"""
        # Implementation depends on your setup
        return "blue"  # Placeholder
    
    async def deploy_to_environment(self, env: str) -&gt; bool:
        """Helper to deploy to environment"""
        # Implementation depends on your setup
        return True  # Placeholder
    
    async def rollback_deployment(self) -&gt; bool:
        """Helper to rollback deployment"""
        # Implementation depends on your setup
        return True  # Placeholder

# Performance benchmark tests
@pytest.mark.benchmark
async def test_switch_performance(benchmark):
    """
    Benchmark how long environment switch takes
    """
    async def switch_environments():
        # Simulate environment switch
        await asyncio.sleep(0.1)  # Actual switch would update k8s service
        return True
    
    result = benchmark(lambda: asyncio.run(switch_environments()))
    assert result is True
```

## 🎯 Ejercicio Resumen

### What You've Accomplished

In this foundational exercise, you've successfully:

1. ✅ Built a complete blue-green despliegue system
2. ✅ Implemented health checks and monitoring
3. ✅ Created automated despliegue scripts
4. ✅ Designed database migration strategies
5. ✅ Developed comprehensive testing suite
6. ✅ Established monitoring and alerting

### Key Takeaways

- **Zero Downtime**: Blue-green enables instant switching with no service interruption
- **Fácil Rollback**: Anterior version remains available for quick rollback
- **Testing in Production**: New version can be fully tested with producción data
- **Database Challenges**: Schema must be backward compatible during transition

### Common Pitfalls to Avoid

1. **Not testing database compatibility** - Always ensure schema works with both versions
2. **Skipping health checks** - Never switch without verifying new ambiente health
3. **Insufficient monitoring** - Monitor both ambientes during and after switch
4. **Resource doubling** - Plan for 2x resource usage during despliegue

## 🚀 Extension Challenges

Ready to go beyond the basics? Try these additional challenges:

### Challenge 1: Multi-Region Blue-Green
Extend the despliegue to work across multiple Azure regions with Traffic Manager.

### Challenge 2: Automated RollAtrás
Implement automatic rollback based on error rate thresholds.

### Challenge 3: Database Sync
Create a solution for keeping databases in sync during extended blue-green periods.

### Challenge 4: Cost Optimization
Implement auto-scaling that reduces resources in the inactive ambiente.

## 📚 Additional Recursos

- [Azure Blue-Green Deployments](https://learn.microsoft.com/azure/architecture/guide/azure-devops/blue-green-despliegue)
- [Kubernetes Blue-Green Tutorial](https://kubernetes.io/blog/2018/04/30/zero-downtime-despliegue-kubernetes/)
- [Database Migration Strategies](https://martinfowler.com/articles/evodb.html)

---

Congratulations! You've mastered blue-green deployments. Ready for Exercise 2: Canary Deployments? 🎯