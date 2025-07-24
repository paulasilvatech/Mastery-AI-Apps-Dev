---
sidebar_position: 8
title: "Exercise 2: Part 1"
description: "## 🎯 Exercise Overview"
---

# Exercise 2: Canary Deployment (⭐⭐ Application)

## 🎯 Exercise Overview

In this application-level exercise, you'll implement a sophisticated canary deployment system that gradually rolls out changes while monitoring key metrics. You'll use GitHub Copilot to build automated traffic shifting, metrics analysis, and rollback triggers.

**Duration**: 45-60 minutes  
**Difficulty**: ⭐⭐ Application  
**Success Rate**: 80%

## 🎓 Learning Objectives

By completing this exercise, you will:

1. **Implement Progressive Traffic Shifting**: Route traffic incrementally to new version
2. **Build Automated Metrics Analysis**: Monitor and compare canary performance
3. **Create Rollback Triggers**: Automatically revert on degradation
4. **Design A/B Testing Integration**: Support feature comparison
5. **Implement Canary Gateways**: Control promotion criteria
6. **Monitor User Experience**: Track real user metrics

## 📚 Concepts Covered

### Canary Deployment Pattern

Canary deployment gradually shifts production traffic from the stable version to the new version:

```mermaid
graph LR
    subgraph "Traffic Distribution Over Time"
        T0[Time 0<br/>Stable: 100%<br/>Canary: 0%]
        T1[Time 1<br/>Stable: 95%<br/>Canary: 5%]
        T2[Time 2<br/>Stable: 75%<br/>Canary: 25%]
        T3[Time 3<br/>Stable: 50%<br/>Canary: 50%]
        T4[Time 4<br/>Stable: 0%<br/>Canary: 100%]
    end
    
    T0 --&gt; T1
    T1 --&gt; T2
    T2 --&gt; T3
    T3 --&gt; T4
    
    T1 -.-&gt;|Rollback if issues| T0
    T2 -.-&gt;|Rollback if issues| T0
```

## 🛠️ Part 1: Canary Infrastructure

### Step 1: Create Canary Controller

**Copilot Prompt Suggestion:**
```python
# Create a canary deployment controller that:
# - Manages traffic percentage between stable and canary
# - Implements progressive traffic shifting with configurable steps
# - Monitors metrics and compares stable vs canary
# - Triggers automatic rollback on threshold breach
# - Supports manual promotion/rollback
# - Logs all decisions with reasoning
# Use kubernetes client and implement as async class
```

**Expected Output:**
Create `canary/controller.py`:
```python
import asyncio
import logging
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass
from enum import Enum
import httpx
from kubernetes import client, config
import numpy as np
from scipy import stats

logger = logging.getLogger(__name__)

class CanaryState(Enum):
    INITIALIZING = "initializing"
    PROGRESSING = "progressing"
    SUCCEEDED = "succeeded"
    FAILED = "failed"
    PAUSED = "paused"

@dataclass
class CanaryMetrics:
    timestamp: datetime
    request_count: int
    error_count: int
    latency_p50: float
    latency_p95: float
    latency_p99: float
    
    @property
    def error_rate(self) -&gt; float:
        return (self.error_count / self.request_count * 100) if self.request_count &gt; 0 else 0

@dataclass
class CanaryConfig:
    name: str
    namespace: str = "default"
    stable_version: str = "stable"
    canary_version: str = "canary"
    initial_canary_weight: int = 5
    canary_increment: int = 10
    max_canary_weight: int = 100
    promotion_interval_seconds: int = 300
    analysis_interval_seconds: int = 60
    
    # Thresholds
    max_error_rate: float = 5.0  # percentage
    max_latency_increase: float = 50.0  # percentage
    min_request_count: int = 100  # minimum requests for analysis
    
    # Statistical confidence
    confidence_level: float = 0.95
    
class CanaryController:
    """
    Advanced canary deployment controller with automated analysis
    """
    
    def __init__(self, config: CanaryConfig):
        self.config = config
        self.state = CanaryState.INITIALIZING
        self.current_canary_weight = 0
        self.start_time = None
        self.promotion_history = []
        self.metrics_history = {
            'stable': [],
            'canary': []
        }
        
        # Initialize Kubernetes client
        try:
            config.load_incluster_config()
        except:
            config.load_kube_config()
        
        self.v1 = client.CoreV1Api()
        self.apps_v1 = client.AppsV1Api()
        self.networking_v1 = client.NetworkingV1Api()
        
    async def start_canary(self) -&gt; bool:
        """
        Start canary deployment process
        """
        logger.info(f"Starting canary deployment for {self.config.name}")
        
        try:
            # Verify both versions are healthy
            if not await self.verify_deployments_health():
                logger.error("Deployment health check failed")
                return False
            
            # Set initial canary weight
            self.current_canary_weight = self.config.initial_canary_weight
            await self.update_traffic_split(self.current_canary_weight)
            
            self.state = CanaryState.PROGRESSING
            self.start_time = datetime.now()
            
            logger.info(f"Canary deployment started with {self.current_canary_weight}% traffic")
            
            # Start monitoring loop
            asyncio.create_task(self.monitor_canary())
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to start canary: {e}")
            self.state = CanaryState.FAILED
            return False
    
    async def verify_deployments_health(self) -&gt; bool:
        """
        Verify both stable and canary deployments are healthy
        """
        for version in [self.config.stable_version, self.config.canary_version]:
            deployment_name = f"{self.config.name}-{version}"
            
            try:
                deployment = self.apps_v1.read_namespaced_deployment(
                    name=deployment_name,
                    namespace=self.config.namespace
                )
                
                ready_replicas = deployment.status.ready_replicas or 0
                desired_replicas = deployment.spec.replicas
                
                if ready_replicas &lt; desired_replicas:
                    logger.error(f"Deployment {deployment_name} not fully ready: {ready_replicas}/{desired_replicas}")
                    return False
                    
            except Exception as e:
                logger.error(f"Failed to check deployment {deployment_name}: {e}")
                return False
                
        return True
    
    async def update_traffic_split(self, canary_percentage: int) -&gt; bool:
        """
        Update traffic split using Kubernetes service mesh or ingress
        """
        try:
            # Using Kubernetes weighted services approach
            stable_weight = 100 - canary_percentage
            
            # Update stable service
            stable_service = self.v1.read_namespaced_service(
                name=f"{self.config.name}-stable",
                namespace=self.config.namespace
            )
            stable_service.metadata.annotations['nginx.ingress.kubernetes.io/canary-weight'] = '0'
            
            self.v1.patch_namespaced_service(
                name=f"{self.config.name}-stable",
                namespace=self.config.namespace,
                body=stable_service
            )
            
            # Update canary service
            canary_service = self.v1.read_namespaced_service(
                name=f"{self.config.name}-canary",
                namespace=self.config.namespace
            )
            canary_service.metadata.annotations['nginx.ingress.kubernetes.io/canary'] = 'true'
            canary_service.metadata.annotations['nginx.ingress.kubernetes.io/canary-weight'] = str(canary_percentage)
            
            self.v1.patch_namespaced_service(
                name=f"{self.config.name}-canary",
                namespace=self.config.namespace,
                body=canary_service
            )
            
            logger.info(f"Updated traffic split: Stable={stable_weight}%, Canary={canary_percentage}%")
            
            self.promotion_history.append({
                'timestamp': datetime.now(),
                'canary_weight': canary_percentage,
                'action': 'traffic_update'
            })
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to update traffic split: {e}")
            return False
    
    async def collect_metrics(self, version: str) -&gt; Optional[CanaryMetrics]:
        """
        Collect metrics from Prometheus or application endpoints
        """
        try:
            # In production, query Prometheus
            # For demo, query application metrics endpoint
            url = f"http://{self.config.name}-{version}/metrics"
            
            async with httpx.AsyncClient() as client:
                response = await client.get(url, timeout=5.0)
                
                if response.status_code == 200:
                    data = response.json()
                    
                    metrics = CanaryMetrics(
                        timestamp=datetime.now(),
                        request_count=data.get('requests_total', 0),
                        error_count=data.get('errors_total', 0),
                        latency_p50=data.get('latency_p50', 0),
                        latency_p95=data.get('latency_p95', 0),
                        latency_p99=data.get('latency_p99', 0)
                    )
                    
                    return metrics
                    
        except Exception as e:
            logger.error(f"Failed to collect metrics for {version}: {e}")
            
        return None
    
    async def analyze_metrics(self) -&gt; Tuple[bool, str]:
        """
        Analyze metrics and determine if canary should continue
        Returns: (should_continue, reason)
        """
        # Get recent metrics (last 5 minutes)
        recent_window = datetime.now() - timedelta(seconds=self.config.analysis_interval_seconds)
        
        recent_stable = [m for m in self.metrics_history['stable'] 
                        if m.timestamp &gt; recent_window]
        recent_canary = [m for m in self.metrics_history['canary'] 
                        if m.timestamp &gt; recent_window]
        
        if not recent_stable or not recent_canary:
            return True, "Insufficient data for analysis"
        
        # Check minimum request count
        canary_requests = sum(m.request_count for m in recent_canary)
        if canary_requests &lt; self.config.min_request_count:
            return True, f"Insufficient requests ({canary_requests} &lt; {self.config.min_request_count})"
        
        # Compare error rates
        stable_error_rate = np.mean([m.error_rate for m in recent_stable])
        canary_error_rate = np.mean([m.error_rate for m in recent_canary])
        
        if canary_error_rate &gt; self.config.max_error_rate:
            return False, f"Canary error rate too high: {canary_error_rate:.2f}% &gt; {self.config.max_error_rate}%"
        
        if canary_error_rate &gt; stable_error_rate * 1.5:
            return False, f"Canary error rate increased: {canary_error_rate:.2f}% vs stable {stable_error_rate:.2f}%"
        
        # Compare latencies
        stable_p95 = np.mean([m.latency_p95 for m in recent_stable])
        canary_p95 = np.mean([m.latency_p95 for m in recent_canary])
        
        latency_increase = ((canary_p95 - stable_p95) / stable_p95 * 100) if stable_p95 &gt; 0 else 0
        
        if latency_increase &gt; self.config.max_latency_increase:
            return False, f"Canary latency increased by {latency_increase:.1f}% (p95: {canary_p95:.3f}s vs {stable_p95:.3f}s)"
        
        # Statistical significance test
        if len(recent_stable) &gt;= 10 and len(recent_canary) &gt;= 10:
            # Compare error rates statistically
            stable_errors = [m.error_rate for m in recent_stable]
            canary_errors = [m.error_rate for m in recent_canary]
            
            _, p_value = stats.mannwhitneyu(stable_errors, canary_errors, alternative='less')
            
            if p_value &lt; (1 - self.config.confidence_level):
                return False, f"Statistical test failed: canary significantly worse (p={p_value:.4f})"
        
        return True, "All metrics within acceptable thresholds"
    
    async def monitor_canary(self):
        """
        Main monitoring loop for canary deployment
        """
        logger.info("Starting canary monitoring loop")
        
        while self.state == CanaryState.PROGRESSING:
            try:
                # Collect metrics
                stable_metrics = await self.collect_metrics(self.config.stable_version)
                canary_metrics = await self.collect_metrics(self.config.canary_version)
                
                if stable_metrics:
                    self.metrics_history['stable'].append(stable_metrics)
                if canary_metrics:
                    self.metrics_history['canary'].append(canary_metrics)
                
                # Analyze metrics
                should_continue, reason = await self.analyze_metrics()
                
                if not should_continue:
                    logger.warning(f"Canary analysis failed: {reason}")
                    await self.rollback_canary(reason)
                    break
                
                # Check if it's time to promote
                time_since_last_promotion = datetime.now() - (
                    self.promotion_history[-1]['timestamp'] 
                    if self.promotion_history 
                    else self.start_time
                )
                
                if time_since_last_promotion.total_seconds() &gt;= self.config.promotion_interval_seconds:
                    # Promote canary
                    if self.current_canary_weight &lt; self.config.max_canary_weight:
                        new_weight = min(
                            self.current_canary_weight + self.config.canary_increment,
                            self.config.max_canary_weight
                        )
                        
                        logger.info(f"Promoting canary from {self.current_canary_weight}% to {new_weight}%")
                        
                        if await self.update_traffic_split(new_weight):
                            self.current_canary_weight = new_weight
                            
                            if self.current_canary_weight &gt;= self.config.max_canary_weight:
                                await self.complete_canary()
                                break
                    
                # Wait before next check
                await asyncio.sleep(self.config.analysis_interval_seconds)
                
            except Exception as e:
                logger.error(f"Error in monitoring loop: {e}")
                await self.rollback_canary(f"Monitoring error: {e}")
                break
    
    async def rollback_canary(self, reason: str):
        """
        Rollback canary deployment
        """
        logger.warning(f"Rolling back canary deployment: {reason}")
        
        self.state = CanaryState.FAILED
        
        # Reset traffic to stable
        await self.update_traffic_split(0)
        
        # Record rollback
        self.promotion_history.append({
            'timestamp': datetime.now(),
            'canary_weight': 0,
            'action': 'rollback',
            'reason': reason
        })
        
        # Generate rollback report
        await self.generate_report('rollback')
    
    async def complete_canary(self):
        """
        Successfully complete canary deployment
        """
        logger.info("Canary deployment completed successfully")
        
        self.state = CanaryState.SUCCEEDED
        
        # Record completion
        self.promotion_history.append({
            'timestamp': datetime.now(),
            'canary_weight': 100,
            'action': 'completed'
        })
        
        # Generate success report
        await self.generate_report('success')
    
    async def generate_report(self, status: str):
        """
        Generate deployment report
        """
        duration = datetime.now() - self.start_time
        
        report = {
            'deployment': self.config.name,
            'status': status,
            'duration': str(duration),
            'start_time': self.start_time.isoformat(),
            'end_time': datetime.now().isoformat(),
            'final_canary_weight': self.current_canary_weight,
            'promotion_history': self.promotion_history,
            'metrics_summary': {
                'stable': self._summarize_metrics(self.metrics_history['stable']),
                'canary': self._summarize_metrics(self.metrics_history['canary'])
            }
        }
        
        logger.info(f"Canary deployment report: {report}")
        
        # In production, send to monitoring system
        return report
    
    def _summarize_metrics(self, metrics: List[CanaryMetrics]) -&gt; Dict:
        """
        Summarize metrics for reporting
        """
        if not metrics:
            return {}
        
        return {
            'total_requests': sum(m.request_count for m in metrics),
            'average_error_rate': np.mean([m.error_rate for m in metrics]),
            'average_latency_p50': np.mean([m.latency_p50 for m in metrics]),
            'average_latency_p95': np.mean([m.latency_p95 for m in metrics]),
            'average_latency_p99': np.mean([m.latency_p99 for m in metrics])
        }
    
    async def pause_canary(self):
        """
        Pause canary progression
        """
        if self.state == CanaryState.PROGRESSING:
            self.state = CanaryState.PAUSED
            logger.info("Canary deployment paused")
    
    async def resume_canary(self):
        """
        Resume canary progression
        """
        if self.state == CanaryState.PAUSED:
            self.state = CanaryState.PROGRESSING
            logger.info("Canary deployment resumed")
            asyncio.create_task(self.monitor_canary())
```

## 🔧 Part 2: Service Mesh Integration

Continue to [Part 2](./exercise2-part2) for service mesh configuration and advanced traffic management...