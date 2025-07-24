---
sidebar_position: 6
title: "Exercise 2: Part 2"
description: "## 🔧 Part 2: Service Mesh Integration"
---

# Exercise 2: Canary Deployment - Part 2 (⭐⭐ Application)

## 🔧 Part 2: Service Mesh Integration

### Step 2: Create Service Mesh Configuration

**Copilot Prompt Suggestion:**
```yaml
# Create Istio/Linkerd service mesh configuration for canary that:
# - Defines VirtualService for traffic splitting
# - Implements weighted routing between versions
# - Adds retry and timeout policies
# - Includes circuit breaker configuration
# - Sets up distributed tracing
# - Configures outlier detection
# Support both header-based and weight-based routing
```

**Expected Output:**
Create `service-mesh/virtual-service.yaml`:
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: canary-demo-vs
  namespace: default
spec:
  hosts:
  - canary-demo
  http:
  - match:
    - headers:
        x-canary:
          exact: "true"
    route:
    - destination:
        host: canary-demo
        subset: canary
      weight: 100
  - route:
    - destination:
        host: canary-demo
        subset: stable
      weight: 95  # Will be dynamically updated
    - destination:
        host: canary-demo
        subset: canary
      weight: 5   # Will be dynamically updated
    timeout: 30s
    retries:
      attempts: 3
      perTryTimeout: 10s
      retryOn: gateway-error,connect-failure,refused-stream
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: canary-demo-dr
  namespace: default
spec:
  host: canary-demo
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 100
        http2MaxRequests: 100
        maxRequestsPerConnection: 2
    loadBalancer:
      simple: ROUND_ROBIN
    outlierDetection:
      consecutiveErrors: 5
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
      minHealthPercent: 50
      splitExternalLocalOriginErrors: true
  subsets:
  - name: stable
    labels:
      version: stable
    trafficPolicy:
      portLevelSettings:
      - port:
          number: 8000
        connectionPool:
          tcp:
            maxConnections: 100
  - name: canary
    labels:
      version: canary
    trafficPolicy:
      portLevelSettings:
      - port:
          number: 8000
        connectionPool:
          tcp:
            maxConnections: 50  # Limit canary connections
```

### Step 3: Create A/B Testing Framework

**Copilot Prompt Suggestion:**
```python
# Create an A/B testing framework that:
# - Assigns users consistently to variants (sticky sessions)
# - Tracks user segments and conversion metrics
# - Supports feature flags within canary
# - Integrates with analytics platforms
# - Provides statistical significance calculations
# - Generates A/B test reports
# Use Redis for session storage and numpy for statistics
```

**Expected Output:**
Create `canary/ab_testing.py`:
```python
import hashlib
import json
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass, asdict
import redis.asyncio as redis
import numpy as np
from scipy import stats
import uuid
import logging

logger = logging.getLogger(__name__)

@dataclass
class ABTestConfig:
    test_id: str
    name: str
    variants: List[str]  # e.g., ['control', 'treatment']
    traffic_allocation: Dict[str, float]  # e.g., {{'control': 50, 'treatment': 50}}
    metrics: List[str]  # Metrics to track
    start_date: datetime
    end_date: Optional[datetime] = None
    segment_rules: Dict[str, Any] = None  # User segmentation rules

@dataclass
class ABTestEvent:
    test_id: str
    user_id: str
    variant: str
    event_type: str  # 'exposure', 'conversion', 'custom'
    timestamp: datetime
    properties: Dict[str, Any] = None

class ABTestingFramework:
    """
    A/B testing framework for canary deployments
    """
    
    def __init__(self, redis_url: str):
        self.redis_url = redis_url
        self.redis_client = None
        
    async def connect(self):
        """Initialize Redis connection"""
        self.redis_client = await redis.from_url(self.redis_url)
        
    async def disconnect(self):
        """Close Redis connection"""
        if self.redis_client:
            await self.redis_client.close()
    
    async def create_test(self, config: ABTestConfig) -&gt; bool:
        """
        Create a new A/B test
        """
        try:
            # Validate traffic allocation
            total_traffic = sum(config.traffic_allocation.values())
            if abs(total_traffic - 100) &gt; 0.01:
                raise ValueError(f"Traffic allocation must sum to 100%, got {total_traffic}%")
            
            # Store test configuration
            test_key = f"ab_test:{config.test_id}"
            await self.redis_client.hset(
                test_key,
                mapping={
                    'config': json.dumps(asdict(config), default=str),
                    'status': 'active',
                    'created_at': datetime.now().isoformat()
                }
            )
            
            logger.info(f"Created A/B test: {config.test_id}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to create A/B test: {e}")
            return False
    
    async def get_variant(self, test_id: str, user_id: str, 
                         user_attributes: Dict[str, Any] = None) -&gt; Optional[str]:
        """
        Get variant assignment for a user
        """
        try:
            # Check if user already has assignment
            assignment_key = f"ab_assignment:{test_id}:{user_id}"
            existing_variant = await self.redis_client.get(assignment_key)
            
            if existing_variant:
                return existing_variant.decode()
            
            # Get test configuration
            test_key = f"ab_test:{test_id}"
            config_data = await self.redis_client.hget(test_key, 'config')
            
            if not config_data:
                logger.warning(f"Test {test_id} not found")
                return None
            
            config_dict = json.loads(config_data)
            config = ABTestConfig(**config_dict)
            
            # Check if test is active
            if config.end_date and datetime.now() &gt; datetime.fromisoformat(config.end_date):
                logger.info(f"Test {test_id} has ended")
                return None
            
            # Check segment rules
            if config.segment_rules and user_attributes:
                if not self._check_segment_rules(user_attributes, config.segment_rules):
                    logger.debug(f"User {user_id} doesn't match segment rules")
                    return None
            
            # Assign variant based on consistent hashing
            variant = self._assign_variant(user_id, config.traffic_allocation)
            
            # Store assignment
            await self.redis_client.setex(
                assignment_key,
                timedelta(days=30),
                variant
            )
            
            # Track exposure event
            await self.track_event(ABTestEvent(
                test_id=test_id,
                user_id=user_id,
                variant=variant,
                event_type='exposure',
                timestamp=datetime.now()
            ))
            
            return variant
            
        except Exception as e:
            logger.error(f"Failed to get variant: {e}")
            return None
    
    def _check_segment_rules(self, attributes: Dict[str, Any], 
                           rules: Dict[str, Any]) -&gt; bool:
        """
        Check if user attributes match segment rules
        """
        for key, expected_value in rules.items():
            if key not in attributes:
                return False
                
            actual_value = attributes[key]
            
            # Handle different rule types
            if isinstance(expected_value, dict):
                # Complex rule (e.g., {{"$gt": 18}})
                operator = list(expected_value.keys())[0]
                value = expected_value[operator]
                
                if operator == "$gt" and not (actual_value &gt; value):
                    return False
                elif operator == "$gte" and not (actual_value &gt;= value):
                    return False
                elif operator == "$lt" and not (actual_value &lt; value):
                    return False
                elif operator == "$lte" and not (actual_value &lt;= value):
                    return False
                elif operator == "$in" and actual_value not in value:
                    return False
                elif operator == "$nin" and actual_value in value:
                    return False
            else:
                # Simple equality
                if actual_value != expected_value:
                    return False
                    
        return True
    
    def _assign_variant(self, user_id: str, 
                       traffic_allocation: Dict[str, float]) -&gt; str:
        """
        Assign variant using consistent hashing
        """
        # Generate consistent hash
        hash_input = f"{user_id}".encode()
        hash_value = int(hashlib.md5(hash_input).hexdigest(), 16)
        bucket = (hash_value % 10000) / 100  # 0-99.99
        
        # Assign based on traffic allocation
        cumulative = 0
        for variant, percentage in traffic_allocation.items():
            cumulative += percentage
            if bucket &lt; cumulative:
                return variant
                
        # Fallback to first variant
        return list(traffic_allocation.keys())[0]
    
    async def track_event(self, event: ABTestEvent) -&gt; bool:
        """
        Track an A/B test event
        """
        try:
            # Store event
            event_key = f"ab_events:{event.test_id}:{event.event_type}"
            event_data = json.dumps(asdict(event), default=str)
            
            await self.redis_client.lpush(event_key, event_data)
            
            # Update metrics
            metrics_key = f"ab_metrics:{event.test_id}:{event.variant}"
            
            if event.event_type == 'exposure':
                await self.redis_client.hincrby(metrics_key, 'exposures', 1)
            elif event.event_type == 'conversion':
                await self.redis_client.hincrby(metrics_key, 'conversions', 1)
            
            # Store user action for funnel analysis
            user_actions_key = f"ab_user_actions:{event.test_id}:{event.user_id}"
            await self.redis_client.rpush(user_actions_key, event_data)
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to track event: {e}")
            return False
    
    async def get_test_results(self, test_id: str) -&gt; Dict[str, Any]:
        """
        Get A/B test results with statistical analysis
        """
        try:
            # Get test configuration
            test_key = f"ab_test:{test_id}"
            config_data = await self.redis_client.hget(test_key, 'config')
            
            if not config_data:
                return {{'error': 'Test not found'}}
            
            config_dict = json.loads(config_data)
            config = ABTestConfig(**config_dict)
            
            results = {
                'test_id': test_id,
                'test_name': config.name,
                'start_date': config.start_date,
                'variants': {{}}
            }
            
            # Collect metrics for each variant
            variant_metrics = {}
            
            for variant in config.variants:
                metrics_key = f"ab_metrics:{test_id}:{variant}"
                metrics = await self.redis_client.hgetall(metrics_key)
                
                exposures = int(metrics.get(b'exposures', 0))
                conversions = int(metrics.get(b'conversions', 0))
                
                conversion_rate = (conversions / exposures * 100) if exposures &gt; 0 else 0
                
                variant_metrics[variant] = {
                    'exposures': exposures,
                    'conversions': conversions,
                    'conversion_rate': conversion_rate
                }
                
                results['variants'][variant] = variant_metrics[variant]
            
            # Statistical significance testing (if we have 2 variants)
            if len(config.variants) == 2:
                control, treatment = config.variants[0], config.variants[1]
                
                control_data = variant_metrics[control]
                treatment_data = variant_metrics[treatment]
                
                if control_data['exposures'] &gt; 0 and treatment_data['exposures'] &gt; 0:
                    # Perform chi-square test
                    observed = np.array([
                        [control_data['conversions'], control_data['exposures'] - control_data['conversions']],
                        [treatment_data['conversions'], treatment_data['exposures'] - treatment_data['conversions']]
                    ])
                    
                    chi2, p_value, dof, expected = stats.chi2_contingency(observed)
                    
                    # Calculate lift
                    lift = ((treatment_data['conversion_rate'] - control_data['conversion_rate']) / 
                           control_data['conversion_rate'] * 100) if control_data['conversion_rate'] &gt; 0 else 0
                    
                    # Calculate confidence intervals
                    control_ci = self._calculate_confidence_interval(
                        control_data['conversions'], 
                        control_data['exposures']
                    )
                    treatment_ci = self._calculate_confidence_interval(
                        treatment_data['conversions'], 
                        treatment_data['exposures']
                    )
                    
                    results['analysis'] = {
                        'p_value': p_value,
                        'significant': p_value &lt; 0.05,
                        'lift': lift,
                        'confidence_level': 95,
                        'control_ci': control_ci,
                        'treatment_ci': treatment_ci,
                        'recommendation': self._get_recommendation(p_value, lift)
                    }
            
            return results
            
        except Exception as e:
            logger.error(f"Failed to get test results: {e}")
            return {{'error': str(e)}}
    
    def _calculate_confidence_interval(self, successes: int, trials: int, 
                                     confidence: float = 0.95) -&gt; Tuple[float, float]:
        """
        Calculate confidence interval for conversion rate
        """
        if trials == 0:
            return (0, 0)
            
        p_hat = successes / trials
        z_score = stats.norm.ppf((1 + confidence) / 2)
        margin_of_error = z_score * np.sqrt((p_hat * (1 - p_hat)) / trials)
        
        lower = max(0, p_hat - margin_of_error) * 100
        upper = min(1, p_hat + margin_of_error) * 100
        
        return (round(lower, 2), round(upper, 2))
    
    def _get_recommendation(self, p_value: float, lift: float) -&gt; str:
        """
        Get recommendation based on test results
        """
        if p_value &gt;= 0.05:
            return "No significant difference detected. Continue testing or end experiment."
        elif lift &gt; 0:
            return f"Treatment shows significant improvement (+{lift:.1f}%). Consider rolling out."
        else:
            return f"Treatment shows significant degradation ({lift:.1f}%). Do not roll out."
    
    async def end_test(self, test_id: str) -&gt; bool:
        """
        End an A/B test
        """
        try:
            test_key = f"ab_test:{test_id}"
            await self.redis_client.hset(test_key, 'status', 'completed')
            await self.redis_client.hset(test_key, 'end_date', datetime.now().isoformat())
            
            logger.info(f"Ended A/B test: {test_id}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to end test: {e}")
            return False

# Integration with canary deployment
class CanaryABIntegration:
    """
    Integrates A/B testing with canary deployments
    """
    
    def __init__(self, ab_framework: ABTestingFramework):
        self.ab_framework = ab_framework
        
    async def create_canary_test(self, canary_version: str, stable_version: str,
                                canary_weight: int) -&gt; str:
        """
        Create A/B test for canary deployment
        """
        test_id = f"canary_{canary_version}_{uuid.uuid4().hex[:8]}"
        
        config = ABTestConfig(
            test_id=test_id,
            name=f"Canary Deployment: {stable_version} vs {canary_version}",
            variants=['stable', 'canary'],
            traffic_allocation={
                'stable': 100 - canary_weight,
                'canary': canary_weight
            },
            metrics=['latency', 'errors', 'conversion'],
            start_date=datetime.now()
        )
        
        await self.ab_framework.create_test(config)
        return test_id
    
    async def update_canary_weight(self, test_id: str, new_canary_weight: int):
        """
        Update traffic allocation as canary progresses
        """
        # In practice, this would coordinate with service mesh
        test_key = f"ab_test:{test_id}"
        config_data = await self.ab_framework.redis_client.hget(test_key, 'config')
        
        if config_data:
            config = json.loads(config_data)
            config['traffic_allocation'] = {
                'stable': 100 - new_canary_weight,
                'canary': new_canary_weight
            }
            
            await self.ab_framework.redis_client.hset(
                test_key, 
                'config', 
                json.dumps(config)
            )
```

## 📊 Part 3: Metrics Collection and Analysis

### Step 4: Create Advanced Metrics Collector

**Copilot Prompt Suggestion:**
```python
# Create a metrics collector that:
# - Collects application and infrastructure metrics
# - Calculates SLI/SLO compliance
# - Detects anomalies using statistical methods
# - Correlates metrics across services
# - Generates real-time alerts
# - Exports to Prometheus format
# Use asyncio for concurrent collection
```

**Expected Output:**
Create `canary/metrics_collector.py`:
```python
import asyncio
import time
from typing import Dict, List, Optional, Tuple, Any
from datetime import datetime, timedelta
from dataclasses import dataclass, field
import numpy as np
from prometheus_client import Counter, Histogram, Gauge, generate_latest
import logging
import httpx
from collections import deque
import statistics

logger = logging.getLogger(__name__)

# Prometheus metrics
request_total = Counter('canary_requests_total', 'Total requests', ['version', 'endpoint', 'method', 'status'])
request_duration = Histogram('canary_request_duration_seconds', 'Request duration', ['version', 'endpoint'])
active_connections = Gauge('canary_active_connections', 'Active connections', ['version'])
cpu_usage = Gauge('canary_cpu_usage_percent', 'CPU usage percentage', ['version', 'pod'])
memory_usage = Gauge('canary_memory_usage_bytes', 'Memory usage in bytes', ['version', 'pod'])
error_rate = Gauge('canary_error_rate_percent', 'Error rate percentage', ['version'])
slo_compliance = Gauge('canary_slo_compliance', 'SLO compliance score', ['version', 'slo_type'])

@dataclass
class SLO:
    name: str
    target: float
    metric_type: str  # 'availability', 'latency', 'error_rate'
    threshold: float
    window_minutes: int = 5

@dataclass
class MetricsSample:
    timestamp: datetime
    version: str
    requests: int = 0
    errors: int = 0
    latencies: List[float] = field(default_factory=list)
    cpu_percent: float = 0.0
    memory_bytes: int = 0
    custom_metrics: Dict[str, float] = field(default_factory=dict)

class AdvancedMetricsCollector:
    """
    Advanced metrics collection with anomaly detection
    """
    
    def __init__(self, stable_url: str, canary_url: str, 
                 prometheus_url: Optional[str] = None):
        self.stable_url = stable_url
        self.canary_url = canary_url
        self.prometheus_url = prometheus_url
        
        # Metrics history for anomaly detection
        self.metrics_window = {
            'stable': deque(maxlen=100),  # Keep last 100 samples
            'canary': deque(maxlen=100)
        }
        
        # SLOs
        self.slos = [
            SLO('availability', 99.9, 'availability', 99.9),
            SLO('latency_p95', 95, 'latency', 0.5),  # 95% of requests &lt; 500ms
            SLO('error_rate', 99, 'error_rate', 1.0)  # &lt; 1% errors
        ]
        
        # Anomaly detection parameters
        self.anomaly_threshold = 3.0  # Standard deviations
        self.correlation_window = 20  # Samples for correlation
        
    async def collect_metrics(self) -&gt; Dict[str, MetricsSample]:
        """
        Collect metrics from all sources
        """
        tasks = [
            self._collect_app_metrics('stable', self.stable_url),
            self._collect_app_metrics('canary', self.canary_url)
        ]
        
        if self.prometheus_url:
            tasks.extend([
                self._collect_prometheus_metrics('stable'),
                self._collect_prometheus_metrics('canary')
            ])
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        metrics = {}
        for result in results:
            if isinstance(result, MetricsSample):
                metrics[result.version] = result
            else:
                logger.error(f"Failed to collect metrics: {result}")
        
        # Store in history
        for version, sample in metrics.items():
            self.metrics_window[version].append(sample)
        
        # Update Prometheus metrics
        self._update_prometheus_metrics(metrics)
        
        # Check for anomalies
        anomalies = await self.detect_anomalies()
        if anomalies:
            await self._handle_anomalies(anomalies)
        
        return metrics
    
    async def _collect_app_metrics(self, version: str, url: str) -&gt; MetricsSample:
        """
        Collect application-level metrics
        """
        sample = MetricsSample(
            timestamp=datetime.now(),
            version=version
        )
        
        try:
            async with httpx.AsyncClient() as client:
                # Get metrics endpoint
                response = await client.get(f"{url}/metrics", timeout=5.0)
                
                if response.status_code == 200:
                    data = response.json()
                    
                    sample.requests = data.get('requests_total', 0)
                    sample.errors = data.get('errors_total', 0)
                    sample.latencies = data.get('latency_histogram', [])
                    sample.custom_metrics = data.get('custom', {})
                
                # Get system metrics
                sys_response = await client.get(f"{url}/system/metrics", timeout=5.0)
                
                if sys_response.status_code == 200:
                    sys_data = sys_response.json()
                    sample.cpu_percent = sys_data.get('cpu_percent', 0)
                    sample.memory_bytes = sys_data.get('memory_bytes', 0)
                    
        except Exception as e:
            logger.error(f"Failed to collect metrics from {version}: {e}")
            
        return sample
    
    async def _collect_prometheus_metrics(self, version: str) -&gt; MetricsSample:
        """
        Collect metrics from Prometheus
        """
        sample = MetricsSample(
            timestamp=datetime.now(),
            version=version
        )
        
        try:
            async with httpx.AsyncClient() as client:
                # Query Prometheus for specific metrics
                queries = {
                    'request_rate': f'rate(http_requests_total{{{{version="{{version}}"}}}}[1m])',
                    'error_rate': f'rate(http_requests_total{{{{version="{{version}}",status=~"5.."}}}}[1m])',
                    'latency_p95': f'histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{{{{version="{{version}}"}}}}[1m]))',
                    'cpu_usage': f'avg(rate(container_cpu_usage_seconds_total{{{{pod=~".*{{version}}.*"}}}}[1m]))',
                    'memory_usage': f'avg(container_memory_usage_bytes{{{{pod=~".*{{version}}.*"}}}})'
                }
                
                for metric_name, query in queries.items():
                    response = await client.get(
                        f"{self.prometheus_url}/api/v1/query",
                        params={{'query': query}}
                    )
                    
                    if response.status_code == 200:
                        data = response.json()
                        if data['data']['result']:
                            value = float(data['data']['result'][0]['value'][1])
                            
                            if metric_name == 'request_rate':
                                sample.requests = int(value * 60)  # Convert to requests/min
                            elif metric_name == 'error_rate':
                                sample.errors = int(value * 60)
                            elif metric_name == 'latency_p95':
                                sample.latencies.append(value)
                            elif metric_name == 'cpu_usage':
                                sample.cpu_percent = value * 100
                            elif metric_name == 'memory_usage':
                                sample.memory_bytes = int(value)
                                
        except Exception as e:
            logger.error(f"Failed to query Prometheus for {version}: {e}")
            
        return sample
    
    def _update_prometheus_metrics(self, metrics: Dict[str, MetricsSample]):
        """
        Update Prometheus metrics for export
        """
        for version, sample in metrics.items():
            # Update counters and gauges
            if sample.requests &gt; 0:
                error_rate_value = (sample.errors / sample.requests) * 100
                error_rate.labels(version=version).set(error_rate_value)
            
            cpu_usage.labels(version=version, pod='aggregate').set(sample.cpu_percent)
            memory_usage.labels(version=version, pod='aggregate').set(sample.memory_bytes)
            
            # Calculate SLO compliance
            slo_scores = self.calculate_slo_compliance(version)
            for slo_name, score in slo_scores.items():
                slo_compliance.labels(version=version, slo_type=slo_name).set(score)
    
    async def detect_anomalies(self) -&gt; List[Dict[str, Any]]:
        """
        Detect anomalies using statistical methods
        """
        anomalies = []
        
        for version in ['stable', 'canary']:
            if len(self.metrics_window[version]) &lt; 10:
                continue  # Need enough data
            
            recent_samples = list(self.metrics_window[version])[-10:]
            
            # Check error rate anomaly
            error_rates = [(s.errors / s.requests * 100) if s.requests &gt; 0 else 0 
                          for s in recent_samples]
            
            if error_rates:
                mean_error = statistics.mean(error_rates)
                std_error = statistics.stdev(error_rates) if len(error_rates) &gt; 1 else 0
                current_error = error_rates[-1]
                
                if std_error &gt; 0 and abs(current_error - mean_error) &gt; self.anomaly_threshold * std_error:
                    anomalies.append({
                        'version': version,
                        'type': 'error_rate',
                        'current': current_error,
                        'expected': mean_error,
                        'severity': 'high' if current_error &gt; mean_error else 'medium'
                    })
            
            # Check latency anomaly
            all_latencies = []
            for s in recent_samples:
                all_latencies.extend(s.latencies)
            
            if len(all_latencies) &gt; 10:
                p95_latency = np.percentile(all_latencies, 95)
                historical_p95 = np.percentile(all_latencies[:-len(recent_samples[-1].latencies)], 95)
                
                if p95_latency &gt; historical_p95 * 1.5:  # 50% increase
                    anomalies.append({
                        'version': version,
                        'type': 'latency',
                        'current': p95_latency,
                        'expected': historical_p95,
                        'severity': 'medium'
                    })
            
            # Check resource anomalies
            cpu_values = [s.cpu_percent for s in recent_samples if s.cpu_percent &gt; 0]
            if len(cpu_values) &gt; 3:
                if cpu_values[-1] &gt; 80 and cpu_values[-1] &gt; statistics.mean(cpu_values) * 1.3:
                    anomalies.append({
                        'version': version,
                        'type': 'cpu',
                        'current': cpu_values[-1],
                        'expected': statistics.mean(cpu_values),
                        'severity': 'low'
                    })
        
        # Correlation analysis between versions
        if (len(self.metrics_window['stable']) &gt;= self.correlation_window and 
            len(self.metrics_window['canary']) &gt;= self.correlation_window):
            
            correlation_anomalies = self._detect_correlation_anomalies()
            anomalies.extend(correlation_anomalies)
        
        return anomalies
    
    def _detect_correlation_anomalies(self) -&gt; List[Dict[str, Any]]:
        """
        Detect anomalies by comparing metric correlations
        """
        anomalies = []
        
        # Get recent samples
        stable_samples = list(self.metrics_window['stable'])[-self.correlation_window:]
        canary_samples = list(self.metrics_window['canary'])[-self.correlation_window:]
        
        # Compare error patterns
        stable_errors = [s.errors for s in stable_samples]
        canary_errors = [s.errors for s in canary_samples]
        
        if stable_errors and canary_errors:
            # Check if canary has significantly different error pattern
            _, p_value = stats.mannwhitneyu(stable_errors, canary_errors, alternative='greater')
            
            if p_value &lt; 0.05:  # Statistically significant difference
                anomalies.append({
                    'type': 'correlation',
                    'metric': 'errors',
                    'p_value': p_value,
                    'severity': 'high',
                    'message': 'Canary shows significantly different error pattern'
                })
        
        return anomalies
    
    async def _handle_anomalies(self, anomalies: List[Dict[str, Any]]):
        """
        Handle detected anomalies
        """
        high_severity = [a for a in anomalies if a.get('severity') == 'high']
        
        if high_severity:
            logger.error(f"High severity anomalies detected: {high_severity}")
            # In production, trigger alerts
            
        for anomaly in anomalies:
            logger.warning(f"Anomaly detected: {anomaly}")
    
    def calculate_slo_compliance(self, version: str) -&gt; Dict[str, float]:
        """
        Calculate SLO compliance scores
        """
        scores = {}
        
        if not self.metrics_window[version]:
            return scores
        
        # Get recent samples based on SLO windows
        for slo in self.slos:
            window_samples = []
            cutoff_time = datetime.now() - timedelta(minutes=slo.window_minutes)
            
            for sample in self.metrics_window[version]:
                if sample.timestamp &gt; cutoff_time:
                    window_samples.append(sample)
            
            if not window_samples:
                continue
            
            if slo.metric_type == 'availability':
                total_requests = sum(s.requests for s in window_samples)
                total_errors = sum(s.errors for s in window_samples)
                
                if total_requests &gt; 0:
                    availability = (1 - total_errors / total_requests) * 100
                    scores[slo.name] = min(100, availability / slo.target * 100)
                    
            elif slo.metric_type == 'latency':
                all_latencies = []
                for s in window_samples:
                    all_latencies.extend(s.latencies)
                
                if all_latencies:
                    under_threshold = sum(1 for l in all_latencies if l &lt; slo.threshold)
                    percentage = (under_threshold / len(all_latencies)) * 100
                    scores[slo.name] = min(100, percentage / slo.target * 100)
                    
            elif slo.metric_type == 'error_rate':
                total_requests = sum(s.requests for s in window_samples)
                total_errors = sum(s.errors for s in window_samples)
                
                if total_requests &gt; 0:
                    error_rate = (total_errors / total_requests) * 100
                    if error_rate &lt;= slo.threshold:
                        scores[slo.name] = 100
                    else:
                        scores[slo.name] = max(0, 100 - (error_rate - slo.threshold) * 10)
        
        return scores
    
    def export_metrics(self) -&gt; str:
        """
        Export metrics in Prometheus format
        """
        return generate_latest().decode('utf-8')
```

## ✅ Part 4: Exercise Validation

Continue to [Part 3](./exercise2-part3) for testing, validation, and A/B test analysis...