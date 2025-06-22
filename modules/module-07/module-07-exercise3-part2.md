# Exercise 3: AI Operations Dashboard (Part 2)

## 📋 Step 2: Core Services Implementation (20 minutes)

### 2.1 Metrics Service

Create `backend/app/services/metrics_service.py`:

**Copilot Prompt Suggestion:**
```python
# Create metrics service that:
# - Collects agent metrics (CPU, memory, requests, errors)
# - Stores metrics in InfluxDB for time series
# - Calculates aggregations (avg, max, min, p95)
# - Provides real-time metric streams
# - Handles metric alerts based on thresholds
# Include async operations and error handling
```

**Expected Copilot Output:**
```python
from typing import List, Dict, Optional, Any
from datetime import datetime, timedelta
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS
import asyncio
from collections import defaultdict
import statistics

from ..core.config import settings
from ..models.models import Agent, Metric, Alert, AlertSeverity
from ..schemas.schemas import MetricData, MetricAggregation

class MetricsService:
    def __init__(self):
        self.client = InfluxDBClient(
            url=settings.INFLUXDB_URL,
            token=settings.INFLUXDB_TOKEN,
            org=settings.INFLUXDB_ORG
        )
        self.write_api = self.client.write_api(write_options=SYNCHRONOUS)
        self.query_api = self.client.query_api()
        
        # Alert thresholds
        self.thresholds = {
            "cpu": {"warning": 70, "critical": 90},
            "memory": {"warning": 80, "critical": 95},
            "error_rate": {"warning": 5, "critical": 10},
            "latency": {"warning": 1000, "critical": 3000}
        }
    
    async def record_metric(
        self, 
        agent_id: int, 
        metric_type: str, 
        value: float, 
        unit: str = None,
        tags: Dict[str, str] = None
    ) -> None:
        """Record a metric to InfluxDB"""
        point = Point("agent_metrics") \
            .tag("agent_id", str(agent_id)) \
            .tag("metric_type", metric_type) \
            .field("value", value) \
            .time(datetime.utcnow())
        
        if unit:
            point.tag("unit", unit)
        
        if tags:
            for key, val in tags.items():
                point.tag(key, str(val))
        
        try:
            self.write_api.write(bucket=settings.INFLUXDB_BUCKET, record=point)
        except Exception as e:
            # Log error but don't fail
            print(f"Failed to write metric: {e}")
    
    async def get_metrics(
        self,
        agent_id: int,
        metric_type: str,
        start_time: datetime,
        end_time: datetime = None,
        aggregation: str = None
    ) -> List[MetricData]:
        """Query metrics from InfluxDB"""
        if not end_time:
            end_time = datetime.utcnow()
        
        # Build Flux query
        if aggregation:
            query = f'''
                from(bucket: "{settings.INFLUXDB_BUCKET}")
                |> range(start: {start_time.isoformat()}Z, stop: {end_time.isoformat()}Z)
                |> filter(fn: (r) => r["agent_id"] == "{agent_id}")
                |> filter(fn: (r) => r["metric_type"] == "{metric_type}")
                |> aggregateWindow(every: 1m, fn: {aggregation}, createEmpty: false)
                |> yield(name: "{aggregation}")
            '''
        else:
            query = f'''
                from(bucket: "{settings.INFLUXDB_BUCKET}")
                |> range(start: {start_time.isoformat()}Z, stop: {end_time.isoformat()}Z)
                |> filter(fn: (r) => r["agent_id"] == "{agent_id}")
                |> filter(fn: (r) => r["metric_type"] == "{metric_type}")
                |> yield()
            '''
        
        try:
            result = self.query_api.query(query)
            metrics = []
            
            for table in result:
                for record in table.records:
                    metrics.append(MetricData(
                        timestamp=record.get_time(),
                        value=record.get_value(),
                        metric_type=metric_type,
                        agent_id=agent_id,
                        tags=record.values
                    ))
            
            return metrics
        except Exception as e:
            print(f"Failed to query metrics: {e}")
            return []
    
    async def calculate_aggregations(
        self,
        agent_id: int,
        metric_type: str,
        period_minutes: int = 60
    ) -> MetricAggregation:
        """Calculate metric aggregations for a period"""
        start_time = datetime.utcnow() - timedelta(minutes=period_minutes)
        metrics = await self.get_metrics(agent_id, metric_type, start_time)
        
        if not metrics:
            return MetricAggregation(
                avg=0, min=0, max=0, p95=0, count=0
            )
        
        values = [m.value for m in metrics]
        
        return MetricAggregation(
            avg=statistics.mean(values),
            min=min(values),
            max=max(values),
            p95=self._calculate_percentile(values, 95),
            count=len(values)
        )
    
    def _calculate_percentile(self, values: List[float], percentile: int) -> float:
        """Calculate percentile value"""
        if not values:
            return 0
        
        sorted_values = sorted(values)
        index = int(len(sorted_values) * (percentile / 100))
        return sorted_values[min(index, len(sorted_values) - 1)]
    
    async def check_alerts(
        self,
        agent_id: int,
        metric_type: str,
        current_value: float
    ) -> Optional[Alert]:
        """Check if metric triggers an alert"""
        if metric_type not in self.thresholds:
            return None
        
        thresholds = self.thresholds[metric_type]
        severity = None
        message = None
        
        if current_value >= thresholds["critical"]:
            severity = AlertSeverity.CRITICAL
            message = f"{metric_type} is critically high: {current_value:.2f}"
        elif current_value >= thresholds["warning"]:
            severity = AlertSeverity.WARNING
            message = f"{metric_type} is above warning threshold: {current_value:.2f}"
        
        if severity:
            return Alert(
                agent_id=agent_id,
                severity=severity,
                title=f"High {metric_type} Alert",
                message=message,
                details={
                    "metric_type": metric_type,
                    "current_value": current_value,
                    "threshold": thresholds
                }
            )
        
        return None
    
    async def get_dashboard_metrics(
        self,
        agent_ids: List[int],
        period_minutes: int = 60
    ) -> Dict[str, Any]:
        """Get aggregated metrics for dashboard"""
        start_time = datetime.utcnow() - timedelta(minutes=period_minutes)
        dashboard_data = {
            "summary": {
                "total_agents": len(agent_ids),
                "active_alerts": 0,
                "avg_cpu": 0,
                "avg_memory": 0,
                "total_requests": 0,
                "error_rate": 0
            },
            "time_series": defaultdict(list),
            "agents": {}
        }
        
        # Aggregate metrics per agent
        for agent_id in agent_ids:
            agent_metrics = {}
            
            for metric_type in ["cpu", "memory", "requests", "errors"]:
                metrics = await self.get_metrics(
                    agent_id, metric_type, start_time
                )
                
                if metrics:
                    # Add to time series
                    for metric in metrics:
                        dashboard_data["time_series"][metric_type].append({
                            "timestamp": metric.timestamp.isoformat(),
                            "value": metric.value,
                            "agent_id": agent_id
                        })
                    
                    # Calculate agent aggregations
                    values = [m.value for m in metrics]
                    agent_metrics[metric_type] = {
                        "current": values[-1] if values else 0,
                        "avg": statistics.mean(values) if values else 0,
                        "max": max(values) if values else 0
                    }
            
            dashboard_data["agents"][agent_id] = agent_metrics
        
        # Calculate summary
        if dashboard_data["agents"]:
            all_cpu = [
                m["cpu"]["current"] 
                for m in dashboard_data["agents"].values() 
                if "cpu" in m
            ]
            all_memory = [
                m["memory"]["current"] 
                for m in dashboard_data["agents"].values() 
                if "memory" in m
            ]
            
            dashboard_data["summary"]["avg_cpu"] = statistics.mean(all_cpu) if all_cpu else 0
            dashboard_data["summary"]["avg_memory"] = statistics.mean(all_memory) if all_memory else 0
        
        return dashboard_data

# Singleton instance
metrics_service = MetricsService()
```

### 2.2 Agent Management Service

Create `backend/app/services/agent_service.py`:

**Copilot Prompt Suggestion:**
```python
# Create agent management service that:
# - Manages agent lifecycle (create, start, stop, delete)
# - Integrates with Kubernetes for deployments
# - Monitors agent health
# - Handles auto-scaling based on metrics
# - Manages agent configurations
# - Provides agent status updates
# Include Kubernetes client and async operations
```

**Expected Copilot Output:**
```python
from typing import List, Dict, Optional
from datetime import datetime, timedelta
import asyncio
from kubernetes import client, config
from kubernetes.client import V1Deployment, V1Service
import yaml
import json

from ..core.config import settings
from ..models.models import Agent, AgentStatus, Deployment, DeploymentStatus
from ..services.metrics_service import metrics_service
from sqlalchemy.ext.asyncio import AsyncSession

class AgentService:
    def __init__(self):
        # Initialize Kubernetes client
        if settings.K8S_IN_CLUSTER:
            config.load_incluster_config()
        else:
            config.load_kube_config(config_file=settings.K8S_CONFIG_FILE)
        
        self.k8s_apps = client.AppsV1Api()
        self.k8s_core = client.CoreV1Api()
        self.namespace = settings.K8S_NAMESPACE
        
        # Agent templates
        self.deployment_templates = {
            "llm": self._get_llm_template(),
            "classifier": self._get_classifier_template(),
            "extractor": self._get_extractor_template()
        }
    
    def _get_llm_template(self) -> Dict:
        """Get LLM agent deployment template"""
        return {
            "apiVersion": "apps/v1",
            "kind": "Deployment",
            "metadata": {
                "name": "agent-{agent_id}",
                "labels": {
                    "app": "ai-agent",
                    "type": "llm",
                    "agent-id": "{agent_id}"
                }
            },
            "spec": {
                "replicas": 1,
                "selector": {
                    "matchLabels": {
                        "app": "ai-agent",
                        "agent-id": "{agent_id}"
                    }
                },
                "template": {
                    "metadata": {
                        "labels": {
                            "app": "ai-agent",
                            "type": "llm",
                            "agent-id": "{agent_id}"
                        }
                    },
                    "spec": {
                        "containers": [{
                            "name": "agent",
                            "image": "ai-agents/llm:latest",
                            "resources": {
                                "requests": {
                                    "memory": "256Mi",
                                    "cpu": "250m"
                                },
                                "limits": {
                                    "memory": "{memory_limit}",
                                    "cpu": "{cpu_limit}"
                                }
                            },
                            "env": [
                                {"name": "AGENT_ID", "value": "{agent_id}"},
                                {"name": "AGENT_CONFIG", "value": "{config}"}
                            ],
                            "ports": [{"containerPort": 8080}]
                        }]
                    }
                }
            }
        }
    
    def _get_classifier_template(self) -> Dict:
        """Get classifier agent deployment template"""
        # Similar structure with different image
        template = self._get_llm_template()
        template["spec"]["template"]["spec"]["containers"][0]["image"] = "ai-agents/classifier:latest"
        return template
    
    def _get_extractor_template(self) -> Dict:
        """Get extractor agent deployment template"""
        template = self._get_llm_template()
        template["spec"]["template"]["spec"]["containers"][0]["image"] = "ai-agents/extractor:latest"
        return template
    
    async def create_agent(
        self,
        db: AsyncSession,
        agent: Agent
    ) -> Agent:
        """Create and deploy a new agent"""
        try:
            # Get deployment template
            template = self.deployment_templates.get(
                agent.type, 
                self.deployment_templates["llm"]
            )
            
            # Fill template with agent data
            deployment_yaml = yaml.safe_load(
                yaml.dump(template).format(
                    agent_id=agent.id,
                    memory_limit=agent.memory_limit,
                    cpu_limit=agent.cpu_limit,
                    config=json.dumps(agent.config)
                )
            )
            
            # Create Kubernetes deployment
            deployment = self.k8s_apps.create_namespaced_deployment(
                namespace=self.namespace,
                body=deployment_yaml
            )
            
            # Update agent with deployment info
            agent.k8s_deployment = deployment.metadata.name
            agent.status = AgentStatus.DEPLOYING
            
            # Create deployment record
            deployment_record = Deployment(
                agent_id=agent.id,
                version="1.0.0",
                status=DeploymentStatus.IN_PROGRESS,
                k8s_deployment=deployment.metadata.name,
                manifest=deployment_yaml,
                started_at=datetime.utcnow()
            )
            
            db.add(deployment_record)
            await db.commit()
            
            # Start monitoring deployment
            asyncio.create_task(self._monitor_deployment(agent.id, deployment_record.id))
            
            return agent
            
        except Exception as e:
            agent.status = AgentStatus.ERROR
            await db.commit()
            raise Exception(f"Failed to create agent: {str(e)}")
    
    async def _monitor_deployment(self, agent_id: int, deployment_id: int):
        """Monitor deployment progress"""
        max_attempts = 30
        attempt = 0
        
        while attempt < max_attempts:
            try:
                # Check deployment status
                deployment = self.k8s_apps.read_namespaced_deployment_status(
                    name=f"agent-{agent_id}",
                    namespace=self.namespace
                )
                
                ready_replicas = deployment.status.ready_replicas or 0
                desired_replicas = deployment.spec.replicas
                
                if ready_replicas == desired_replicas:
                    # Deployment successful
                    # Update agent and deployment status in database
                    # This would need database session handling
                    break
                
            except Exception as e:
                print(f"Error monitoring deployment: {e}")
            
            attempt += 1
            await asyncio.sleep(10)
    
    async def scale_agent(
        self,
        agent: Agent,
        replicas: int
    ) -> None:
        """Scale agent deployment"""
        try:
            # Update Kubernetes deployment
            body = {"spec": {"replicas": replicas}}
            
            self.k8s_apps.patch_namespaced_deployment_scale(
                name=agent.k8s_deployment,
                namespace=self.namespace,
                body=body
            )
            
            agent.replica_count = replicas
            
        except Exception as e:
            raise Exception(f"Failed to scale agent: {str(e)}")
    
    async def stop_agent(self, agent: Agent) -> None:
        """Stop agent by scaling to 0"""
        await self.scale_agent(agent, 0)
        agent.status = AgentStatus.STOPPED
    
    async def start_agent(self, agent: Agent) -> None:
        """Start agent by scaling to desired replicas"""
        await self.scale_agent(agent, agent.replica_count or 1)
        agent.status = AgentStatus.RUNNING
    
    async def delete_agent(self, agent: Agent) -> None:
        """Delete agent deployment"""
        try:
            # Delete Kubernetes deployment
            self.k8s_apps.delete_namespaced_deployment(
                name=agent.k8s_deployment,
                namespace=self.namespace
            )
            
            agent.status = AgentStatus.STOPPED
            
        except Exception as e:
            raise Exception(f"Failed to delete agent: {str(e)}")
    
    async def get_agent_health(self, agent: Agent) -> Dict:
        """Get agent health status"""
        health = {
            "status": agent.status,
            "healthy": False,
            "replicas": {"desired": 0, "ready": 0},
            "metrics": {}
        }
        
        try:
            # Get deployment status
            deployment = self.k8s_apps.read_namespaced_deployment_status(
                name=agent.k8s_deployment,
                namespace=self.namespace
            )
            
            health["replicas"]["desired"] = deployment.spec.replicas
            health["replicas"]["ready"] = deployment.status.ready_replicas or 0
            health["healthy"] = health["replicas"]["ready"] > 0
            
            # Get recent metrics
            if health["healthy"]:
                for metric_type in ["cpu", "memory"]:
                    agg = await metrics_service.calculate_aggregations(
                        agent.id, metric_type, period_minutes=5
                    )
                    health["metrics"][metric_type] = {
                        "current": agg.avg,
                        "max": agg.max
                    }
            
        except Exception as e:
            print(f"Error getting agent health: {e}")
        
        return health
    
    async def auto_scale_check(self, agent: Agent) -> Optional[int]:
        """Check if agent needs auto-scaling"""
        if not agent.config.get("auto_scaling", {}).get("enabled", False):
            return None
        
        # Get recent CPU metrics
        cpu_agg = await metrics_service.calculate_aggregations(
            agent.id, "cpu", period_minutes=10
        )
        
        current_replicas = agent.replica_count
        min_replicas = agent.config.get("auto_scaling", {}).get("min_replicas", 1)
        max_replicas = agent.config.get("auto_scaling", {}).get("max_replicas", 10)
        
        # Scale up if CPU > 70%
        if cpu_agg.avg > 70 and current_replicas < max_replicas:
            return min(current_replicas + 1, max_replicas)
        
        # Scale down if CPU < 30%
        if cpu_agg.avg < 30 and current_replicas > min_replicas:
            return max(current_replicas - 1, min_replicas)
        
        return None

# Singleton instance
agent_service = AgentService()
```

### 2.3 WebSocket Manager

Create `backend/app/services/websocket_manager.py`:

**Copilot Prompt Suggestion:**
```python
# Create WebSocket connection manager that:
# - Manages client connections per user
# - Broadcasts real-time metrics to subscribers
# - Handles connection lifecycle (connect, disconnect, heartbeat)
# - Implements room-based subscriptions (per agent)
# - Queues messages for offline clients
# - Rate limits message sending
# Include connection pooling and error recovery
```

**Expected Copilot Output:**
```python
from typing import Dict, Set, List, Optional
from fastapi import WebSocket, WebSocketDisconnect
import json
import asyncio
from datetime import datetime, timedelta
from collections import defaultdict
import aioredis

from ..core.config import settings

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[int, Set[WebSocket]] = defaultdict(set)
        self.user_connections: Dict[WebSocket, int] = {}
        self.subscriptions: Dict[WebSocket, Set[str]] = defaultdict(set)
        self.message_queue: Dict[int, List[dict]] = defaultdict(list)
        self.last_activity: Dict[WebSocket, datetime] = {}
        self.redis_client = None
        
    async def initialize(self):
        """Initialize Redis connection for pub/sub"""
        self.redis_client = await aioredis.create_redis_pool(
            settings.REDIS_URL,
            encoding='utf-8'
        )
        
        # Start heartbeat checker
        asyncio.create_task(self._heartbeat_checker())
    
    async def connect(
        self, 
        websocket: WebSocket, 
        user_id: int
    ) -> bool:
        """Accept WebSocket connection"""
        # Check connection limit
        if len(self.active_connections[user_id]) >= settings.WS_MAX_CONNECTIONS_PER_USER:
            await websocket.close(code=4000, reason="Connection limit exceeded")
            return False
        
        await websocket.accept()
        self.active_connections[user_id].add(websocket)
        self.user_connections[websocket] = user_id
        self.last_activity[websocket] = datetime.utcnow()
        
        # Send queued messages
        if user_id in self.message_queue:
            for message in self.message_queue[user_id][:50]:  # Limit to 50 messages
                await self._send_message(websocket, message)
            self.message_queue[user_id].clear()
        
        # Send connection success
        await self._send_message(websocket, {
            "type": "connection",
            "status": "connected",
            "timestamp": datetime.utcnow().isoformat()
        })
        
        return True
    
    async def disconnect(self, websocket: WebSocket):
        """Handle WebSocket disconnection"""
        user_id = self.user_connections.get(websocket)
        
        if user_id:
            self.active_connections[user_id].discard(websocket)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]
            
            del self.user_connections[websocket]
        
        if websocket in self.subscriptions:
            del self.subscriptions[websocket]
        
        if websocket in self.last_activity:
            del self.last_activity[websocket]
    
    async def subscribe(
        self, 
        websocket: WebSocket, 
        channel: str
    ):
        """Subscribe to a channel (e.g., agent:123)"""
        self.subscriptions[websocket].add(channel)
        
        await self._send_message(websocket, {
            "type": "subscription",
            "channel": channel,
            "status": "subscribed",
            "timestamp": datetime.utcnow().isoformat()
        })
    
    async def unsubscribe(
        self, 
        websocket: WebSocket, 
        channel: str
    ):
        """Unsubscribe from a channel"""
        self.subscriptions[websocket].discard(channel)
        
        await self._send_message(websocket, {
            "type": "subscription",
            "channel": channel,
            "status": "unsubscribed",
            "timestamp": datetime.utcnow().isoformat()
        })
    
    async def broadcast_to_channel(
        self, 
        channel: str, 
        message: dict
    ):
        """Broadcast message to all subscribers of a channel"""
        # Add channel info to message
        message["channel"] = channel
        message["timestamp"] = datetime.utcnow().isoformat()
        
        # Find all connections subscribed to this channel
        for websocket, channels in self.subscriptions.items():
            if channel in channels:
                await self._send_message(websocket, message)
    
    async def send_to_user(
        self, 
        user_id: int, 
        message: dict
    ):
        """Send message to specific user"""
        if user_id in self.active_connections:
            for websocket in self.active_connections[user_id]:
                await self._send_message(websocket, message)
        else:
            # Queue message for offline user
            self._queue_message(user_id, message)
    
    async def broadcast_metrics(
        self, 
        agent_id: int, 
        metrics: dict
    ):
        """Broadcast metrics update for an agent"""
        await self.broadcast_to_channel(
            f"agent:{agent_id}",
            {
                "type": "metrics",
                "agent_id": agent_id,
                "data": metrics
            }
        )
    
    async def broadcast_alert(
        self, 
        agent_id: int, 
        alert: dict
    ):
        """Broadcast alert for an agent"""
        await self.broadcast_to_channel(
            f"agent:{agent_id}",
            {
                "type": "alert",
                "agent_id": agent_id,
                "data": alert
            }
        )
    
    async def broadcast_status(
        self, 
        agent_id: int, 
        status: str
    ):
        """Broadcast agent status change"""
        await self.broadcast_to_channel(
            f"agent:{agent_id}",
            {
                "type": "status",
                "agent_id": agent_id,
                "data": {"status": status}
            }
        )
    
    async def handle_message(
        self, 
        websocket: WebSocket, 
        message: str
    ):
        """Handle incoming WebSocket message"""
        try:
            data = json.loads(message)
            self.last_activity[websocket] = datetime.utcnow()
            
            message_type = data.get("type")
            
            if message_type == "ping":
                await self._send_message(websocket, {"type": "pong"})
            
            elif message_type == "subscribe":
                channel = data.get("channel")
                if channel:
                    await self.subscribe(websocket, channel)
            
            elif message_type == "unsubscribe":
                channel = data.get("channel")
                if channel:
                    await self.unsubscribe(websocket, channel)
            
            else:
                await self._send_message(websocket, {
                    "type": "error",
                    "message": f"Unknown message type: {message_type}"
                })
                
        except json.JSONDecodeError:
            await self._send_message(websocket, {
                "type": "error",
                "message": "Invalid JSON"
            })
        except Exception as e:
            await self._send_message(websocket, {
                "type": "error",
                "message": str(e)
            })
    
    async def _send_message(
        self, 
        websocket: WebSocket, 
        message: dict
    ):
        """Send message to WebSocket with error handling"""
        try:
            await websocket.send_json(message)
        except WebSocketDisconnect:
            await self.disconnect(websocket)
        except Exception as e:
            print(f"Error sending message: {e}")
            await self.disconnect(websocket)
    
    def _queue_message(
        self, 
        user_id: int, 
        message: dict
    ):
        """Queue message for offline user"""
        # Limit queue size to prevent memory issues
        if len(self.message_queue[user_id]) < 100:
            self.message_queue[user_id].append(message)
    
    async def _heartbeat_checker(self):
        """Check for inactive connections"""
        while True:
            try:
                current_time = datetime.utcnow()
                timeout = timedelta(seconds=settings.WS_HEARTBEAT_INTERVAL * 2)
                
                # Find inactive connections
                inactive = []
                for websocket, last_active in self.last_activity.items():
                    if current_time - last_active > timeout:
                        inactive.append(websocket)
                
                # Disconnect inactive connections
                for websocket in inactive:
                    await self.disconnect(websocket)
                    try:
                        await websocket.close(code=4001, reason="Heartbeat timeout")
                    except:
                        pass
                
            except Exception as e:
                print(f"Error in heartbeat checker: {e}")
            
            await asyncio.sleep(settings.WS_HEARTBEAT_INTERVAL)

# Singleton instance
websocket_manager = ConnectionManager()
```

## ✅ Checkpoint 2

Before proceeding to API implementation, verify:
- [ ] Metrics service handles InfluxDB operations
- [ ] Agent service integrates with Kubernetes
- [ ] WebSocket manager handles connections properly
- [ ] All services use async operations
- [ ] Error handling is comprehensive

Continue to Part 3 for API endpoints and WebSocket implementation...