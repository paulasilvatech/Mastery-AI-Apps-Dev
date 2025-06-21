# Exercise 3: Feature Flags & Progressive Delivery - Part 3 (⭐⭐⭐ Mastery)

## 🔐 Part 4: Kill Switches and Emergency Controls

### Step 4: Create Kill Switch System

**Copilot Prompt Suggestion:**
```python
# Create a kill switch system that:
# - Provides instant feature disabling across all services
# - Implements circuit breaker patterns for automatic protection
# - Tracks activation history and impact
# - Supports granular control (user, region, service level)
# - Integrates with incident management
# - Provides API and UI for emergency access
# Use Redis for low-latency switches with automatic failover
```

**Expected Output:**
Create `progressive_delivery/kill_switch.py`:
```python
import asyncio
from typing import Dict, List, Optional, Set, Any, Callable
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from enum import Enum
import json
import redis.asyncio as redis
from pydantic import BaseModel, Field
import logging
import hashlib
from collections import defaultdict
import aiohttp

logger = logging.getLogger(__name__)

class KillSwitchScope(str, Enum):
    GLOBAL = "global"
    REGION = "region"
    SERVICE = "service"
    USER_SEGMENT = "user_segment"
    FEATURE = "feature"

class KillSwitchState(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    TRIGGERED = "triggered"
    RECOVERING = "recovering"

class CircuitState(str, Enum):
    CLOSED = "closed"  # Normal operation
    OPEN = "open"      # Failing, reject requests
    HALF_OPEN = "half_open"  # Testing recovery

@dataclass
class KillSwitchConfig:
    """Kill switch configuration"""
    id: str
    name: str
    description: str
    scope: KillSwitchScope
    scope_value: Optional[str] = None  # e.g., region name, service name
    
    # Trigger conditions
    auto_trigger_enabled: bool = True
    error_threshold: float = 50.0  # Percentage
    latency_threshold: float = 2.0  # Seconds
    volume_threshold: int = 100  # Minimum requests for evaluation
    
    # Circuit breaker settings
    circuit_breaker_enabled: bool = True
    failure_count_threshold: int = 5
    success_count_threshold: int = 5
    timeout_seconds: int = 60
    half_open_requests: int = 3
    
    # Recovery settings
    auto_recovery_enabled: bool = True
    recovery_delay_seconds: int = 300
    gradual_recovery: bool = True
    recovery_percentage_steps: List[int] = field(default_factory=lambda: [10, 25, 50, 100])
    
    # Metadata
    created_at: datetime = field(default_factory=datetime.now)
    created_by: str = "system"
    tags: List[str] = field(default_factory=list)
    
    # Impact tracking
    affected_features: List[str] = field(default_factory=list)
    affected_services: List[str] = field(default_factory=list)
    notification_channels: List[str] = field(default_factory=list)

@dataclass
class KillSwitchActivation:
    """Record of kill switch activation"""
    switch_id: str
    activated_at: datetime
    activated_by: str
    reason: str
    auto_triggered: bool = False
    
    # Impact metrics
    requests_affected: int = 0
    error_rate_before: float = 0.0
    error_rate_after: float = 0.0
    
    # Recovery info
    deactivated_at: Optional[datetime] = None
    recovery_duration_seconds: Optional[int] = None
    recovery_successful: bool = False

class CircuitBreaker:
    """Circuit breaker implementation for kill switches"""
    
    def __init__(self, config: KillSwitchConfig):
        self.config = config
        self.state = CircuitState.CLOSED
        self.failure_count = 0
        self.success_count = 0
        self.last_failure_time: Optional[datetime] = None
        self.half_open_requests = 0
        self.state_changed_at = datetime.now()
        
    async def call(self, func: Callable, *args, **kwargs) -> Any:
        """Execute function through circuit breaker"""
        if self.state == CircuitState.OPEN:
            # Check if we should transition to half-open
            if (datetime.now() - self.state_changed_at).total_seconds() > self.config.timeout_seconds:
                self._transition_to_half_open()
            else:
                raise Exception("Circuit breaker is OPEN")
        
        try:
            # Execute the function
            result = await func(*args, **kwargs)
            
            # Record success
            self._on_success()
            return result
            
        except Exception as e:
            # Record failure
            self._on_failure()
            raise e
    
    def _on_success(self):
        """Handle successful call"""
        self.failure_count = 0
        
        if self.state == CircuitState.HALF_OPEN:
            self.success_count += 1
            if self.success_count >= self.config.success_count_threshold:
                self._transition_to_closed()
    
    def _on_failure(self):
        """Handle failed call"""
        self.failure_count += 1
        self.last_failure_time = datetime.now()
        
        if self.state == CircuitState.HALF_OPEN:
            self._transition_to_open()
        elif self.failure_count >= self.config.failure_count_threshold:
            self._transition_to_open()
    
    def _transition_to_open(self):
        """Transition to OPEN state"""
        self.state = CircuitState.OPEN
        self.state_changed_at = datetime.now()
        self.half_open_requests = 0
        logger.warning(f"Circuit breaker {self.config.id} transitioned to OPEN")
    
    def _transition_to_half_open(self):
        """Transition to HALF_OPEN state"""
        self.state = CircuitState.HALF_OPEN
        self.state_changed_at = datetime.now()
        self.success_count = 0
        self.half_open_requests = 0
        logger.info(f"Circuit breaker {self.config.id} transitioned to HALF_OPEN")
    
    def _transition_to_closed(self):
        """Transition to CLOSED state"""
        self.state = CircuitState.CLOSED
        self.state_changed_at = datetime.now()
        self.failure_count = 0
        self.success_count = 0
        logger.info(f"Circuit breaker {self.config.id} transitioned to CLOSED")

class KillSwitchService:
    """
    Centralized kill switch management service
    """
    
    def __init__(self, redis_url: str, feature_flag_service=None):
        self.redis_url = redis_url
        self.redis_client: Optional[redis.Redis] = None
        self.feature_flag_service = feature_flag_service
        self.circuit_breakers: Dict[str, CircuitBreaker] = {}
        self.metrics_buffer: Dict[str, List[Dict[str, Any]]] = defaultdict(list)
        self._monitoring_task: Optional[asyncio.Task] = None
        
    async def connect(self):
        """Initialize connections"""
        self.redis_client = await redis.from_url(self.redis_url)
        # Start monitoring
        self._monitoring_task = asyncio.create_task(self._monitor_switches())
        
    async def disconnect(self):
        """Cleanup connections"""
        if self._monitoring_task:
            self._monitoring_task.cancel()
        if self.redis_client:
            await self.redis_client.close()
    
    async def create_kill_switch(self, config: KillSwitchConfig) -> bool:
        """Create a new kill switch"""
        try:
            switch_key = f"kill_switch:{config.id}"
            
            # Check if already exists
            if await self.redis_client.exists(switch_key):
                raise ValueError(f"Kill switch {config.id} already exists")
            
            # Store configuration
            await self.redis_client.hset(
                switch_key,
                mapping={
                    "config": json.dumps(dataclass_to_dict(config), default=str),
                    "state": KillSwitchState.INACTIVE,
                    "created_at": datetime.now().isoformat()
                }
            )
            
            # Create circuit breaker
            if config.circuit_breaker_enabled:
                self.circuit_breakers[config.id] = CircuitBreaker(config)
            
            # Index by scope
            await self.redis_client.sadd(f"kill_switches:scope:{config.scope}", config.id)
            
            logger.info(f"Created kill switch: {config.id}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to create kill switch: {e}")
            raise
    
    async def activate_kill_switch(self, switch_id: str, reason: str, 
                                  activated_by: str = "system") -> bool:
        """Activate a kill switch"""
        try:
            switch_key = f"kill_switch:{switch_id}"
            
            # Get current state
            current_state = await self.redis_client.hget(switch_key, "state")
            if current_state == KillSwitchState.TRIGGERED:
                logger.warning(f"Kill switch {switch_id} already triggered")
                return True
            
            # Get configuration
            config_data = await self.redis_client.hget(switch_key, "config")
            if not config_data:
                raise ValueError(f"Kill switch {switch_id} not found")
            
            config = KillSwitchConfig(**json.loads(config_data))
            
            # Update state
            await self.redis_client.hset(switch_key, "state", KillSwitchState.TRIGGERED)
            
            # Record activation
            activation = KillSwitchActivation(
                switch_id=switch_id,
                activated_at=datetime.now(),
                activated_by=activated_by,
                reason=reason,
                auto_triggered=activated_by == "system"
            )
            
            activation_key = f"kill_switch_activation:{switch_id}:{activation.activated_at.timestamp()}"
            await self.redis_client.set(
                activation_key,
                json.dumps(dataclass_to_dict(activation), default=str),
                ex=86400 * 30  # Keep for 30 days
            )
            
            # Apply kill switch effects
            await self._apply_kill_switch(config)
            
            # Send notifications
            await self._send_notifications(config, activation)
            
            logger.warning(f"Kill switch {switch_id} ACTIVATED: {reason}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to activate kill switch: {e}")
            raise
    
    async def deactivate_kill_switch(self, switch_id: str, 
                                    deactivated_by: str = "system") -> bool:
        """Deactivate a kill switch"""
        try:
            switch_key = f"kill_switch:{switch_id}"
            
            # Update state
            await self.redis_client.hset(switch_key, "state", KillSwitchState.INACTIVE)
            
            # Get configuration
            config_data = await self.redis_client.hget(switch_key, "config")
            config = KillSwitchConfig(**json.loads(config_data))
            
            # Remove kill switch effects
            await self._remove_kill_switch(config)
            
            logger.info(f"Kill switch {switch_id} deactivated by {deactivated_by}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to deactivate kill switch: {e}")
            raise
    
    async def _apply_kill_switch(self, config: KillSwitchConfig):
        """Apply kill switch effects"""
        # Disable affected features
        if self.feature_flag_service and config.affected_features:
            for feature in config.affected_features:
                await self.feature_flag_service.update_flag(
                    feature,
                    {"enabled": False, "kill_switch_triggered": True}
                )
        
        # Set scope-based switches
        if config.scope == KillSwitchScope.GLOBAL:
            await self.redis_client.set("kill_switch:global:active", "1")
        elif config.scope == KillSwitchScope.REGION:
            await self.redis_client.set(f"kill_switch:region:{config.scope_value}:active", "1")
        elif config.scope == KillSwitchScope.SERVICE:
            await self.redis_client.set(f"kill_switch:service:{config.scope_value}:active", "1")
        
        # Broadcast to services
        await self._broadcast_kill_switch(config, "activate")
    
    async def _remove_kill_switch(self, config: KillSwitchConfig):
        """Remove kill switch effects"""
        # Re-enable features if gradual recovery not enabled
        if self.feature_flag_service and config.affected_features and not config.gradual_recovery:
            for feature in config.affected_features:
                await self.feature_flag_service.update_flag(
                    feature,
                    {"enabled": True, "kill_switch_triggered": False}
                )
        
        # Remove scope-based switches
        if config.scope == KillSwitchScope.GLOBAL:
            await self.redis_client.delete("kill_switch:global:active")
        elif config.scope == KillSwitchScope.REGION:
            await self.redis_client.delete(f"kill_switch:region:{config.scope_value}:active")
        elif config.scope == KillSwitchScope.SERVICE:
            await self.redis_client.delete(f"kill_switch:service:{config.scope_value}:active")
        
        # Broadcast to services
        await self._broadcast_kill_switch(config, "deactivate")
    
    async def _broadcast_kill_switch(self, config: KillSwitchConfig, action: str):
        """Broadcast kill switch action to services"""
        message = {
            "type": "kill_switch",
            "action": action,
            "switch_id": config.id,
            "scope": config.scope,
            "scope_value": config.scope_value,
            "timestamp": datetime.now().isoformat()
        }
        
        # Publish to Redis pub/sub
        await self.redis_client.publish(
            "kill_switch_events",
            json.dumps(message)
        )
    
    async def check_kill_switch(self, switch_id: Optional[str] = None,
                              scope: Optional[KillSwitchScope] = None,
                              scope_value: Optional[str] = None) -> bool:
        """Check if a kill switch is active"""
        # Check specific switch
        if switch_id:
            state = await self.redis_client.hget(f"kill_switch:{switch_id}", "state")
            return state == KillSwitchState.TRIGGERED
        
        # Check scope-based switches
        if scope:
            if scope == KillSwitchScope.GLOBAL:
                return await self.redis_client.get("kill_switch:global:active") == "1"
            elif scope == KillSwitchScope.REGION and scope_value:
                return await self.redis_client.get(f"kill_switch:region:{scope_value}:active") == "1"
            elif scope == KillSwitchScope.SERVICE and scope_value:
                return await self.redis_client.get(f"kill_switch:service:{scope_value}:active") == "1"
        
        return False
    
    async def record_request_metrics(self, switch_id: str, 
                                   success: bool, latency: float,
                                   error_type: Optional[str] = None):
        """Record metrics for kill switch monitoring"""
        metric = {
            "timestamp": datetime.now().isoformat(),
            "success": success,
            "latency": latency,
            "error_type": error_type
        }
        
        # Buffer metrics for batch processing
        self.metrics_buffer[switch_id].append(metric)
        
        # Process if buffer is full
        if len(self.metrics_buffer[switch_id]) >= 100:
            await self._process_metrics_batch(switch_id)
    
    async def _process_metrics_batch(self, switch_id: str):
        """Process a batch of metrics"""
        if switch_id not in self.metrics_buffer:
            return
        
        metrics = self.metrics_buffer[switch_id]
        self.metrics_buffer[switch_id] = []
        
        if not metrics:
            return
        
        # Calculate statistics
        total_requests = len(metrics)
        failed_requests = sum(1 for m in metrics if not m["success"])
        error_rate = (failed_requests / total_requests) * 100
        avg_latency = sum(m["latency"] for m in metrics) / total_requests
        
        # Store aggregated metrics
        metric_key = f"kill_switch_metrics:{switch_id}:{int(datetime.now().timestamp())}"
        await self.redis_client.hset(
            metric_key,
            mapping={
                "total_requests": total_requests,
                "error_rate": error_rate,
                "avg_latency": avg_latency,
                "timestamp": datetime.now().isoformat()
            }
        )
        await self.redis_client.expire(metric_key, 3600)  # Keep for 1 hour
        
        # Check if auto-trigger conditions are met
        await self._check_auto_trigger(switch_id, error_rate, avg_latency, total_requests)
    
    async def _check_auto_trigger(self, switch_id: str, error_rate: float, 
                                avg_latency: float, volume: int):
        """Check if kill switch should be auto-triggered"""
        # Get configuration
        config_data = await self.redis_client.hget(f"kill_switch:{switch_id}", "config")
        if not config_data:
            return
        
        config = KillSwitchConfig(**json.loads(config_data))
        
        if not config.auto_trigger_enabled:
            return
        
        # Check volume threshold
        if volume < config.volume_threshold:
            return
        
        # Check error threshold
        if error_rate > config.error_threshold:
            await self.activate_kill_switch(
                switch_id,
                f"Auto-triggered: Error rate {error_rate:.1f}% exceeds threshold {config.error_threshold}%",
                "system"
            )
            return
        
        # Check latency threshold
        if avg_latency > config.latency_threshold:
            await self.activate_kill_switch(
                switch_id,
                f"Auto-triggered: Latency {avg_latency:.2f}s exceeds threshold {config.latency_threshold}s",
                "system"
            )
    
    async def _monitor_switches(self):
        """Background task to monitor kill switches"""
        while True:
            try:
                # Process any remaining metrics
                for switch_id in list(self.metrics_buffer.keys()):
                    if self.metrics_buffer[switch_id]:
                        await self._process_metrics_batch(switch_id)
                
                # Check for recovery
                await self._check_auto_recovery()
                
                await asyncio.sleep(10)  # Check every 10 seconds
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Error in kill switch monitoring: {e}")
                await asyncio.sleep(30)
    
    async def _check_auto_recovery(self):
        """Check if any kill switches should auto-recover"""
        # Get all triggered switches
        cursor = 0
        while True:
            cursor, keys = await self.redis_client.scan(
                cursor, match="kill_switch:*", count=100
            )
            
            for key in keys:
                if key.decode().count(":") == 1:  # Main switch keys only
                    state = await self.redis_client.hget(key, "state")
                    if state == KillSwitchState.TRIGGERED:
                        switch_id = key.decode().split(":")[1]
                        await self._check_switch_recovery(switch_id)
            
            if cursor == 0:
                break
    
    async def _check_switch_recovery(self, switch_id: str):
        """Check if a switch should recover"""
        # Get configuration
        config_data = await self.redis_client.hget(f"kill_switch:{switch_id}", "config")
        if not config_data:
            return
        
        config = KillSwitchConfig(**json.loads(config_data))
        
        if not config.auto_recovery_enabled:
            return
        
        # Get latest activation
        pattern = f"kill_switch_activation:{switch_id}:*"
        cursor = 0
        latest_activation = None
        
        while True:
            cursor, keys = await self.redis_client.scan(cursor, match=pattern, count=100)
            
            for key in keys:
                activation_data = await self.redis_client.get(key)
                if activation_data:
                    activation = json.loads(activation_data)
                    if not latest_activation or activation['activated_at'] > latest_activation['activated_at']:
                        latest_activation = activation
            
            if cursor == 0:
                break
        
        if not latest_activation:
            return
        
        # Check if recovery delay has passed
        activated_at = datetime.fromisoformat(latest_activation['activated_at'])
        if (datetime.now() - activated_at).total_seconds() < config.recovery_delay_seconds:
            return
        
        # Check current metrics
        recent_metrics = await self._get_recent_metrics(switch_id, minutes=5)
        if not recent_metrics:
            return
        
        avg_error_rate = sum(m['error_rate'] for m in recent_metrics) / len(recent_metrics)
        avg_latency = sum(m['avg_latency'] for m in recent_metrics) / len(recent_metrics)
        
        # Check if metrics are healthy
        if avg_error_rate < config.error_threshold * 0.5 and avg_latency < config.latency_threshold * 0.5:
            if config.gradual_recovery:
                await self._start_gradual_recovery(switch_id, config)
            else:
                await self.deactivate_kill_switch(switch_id, "auto-recovery")
    
    async def _start_gradual_recovery(self, switch_id: str, config: KillSwitchConfig):
        """Start gradual recovery process"""
        logger.info(f"Starting gradual recovery for kill switch {switch_id}")
        
        # Update state to recovering
        await self.redis_client.hset(f"kill_switch:{switch_id}", "state", KillSwitchState.RECOVERING)
        
        # Re-enable features gradually
        if self.feature_flag_service and config.affected_features:
            for step, percentage in enumerate(config.recovery_percentage_steps):
                for feature in config.affected_features:
                    await self.feature_flag_service.update_flag(
                        feature,
                        {
                            "enabled": True,
                            "rollout_percentage": percentage,
                            "kill_switch_recovering": True
                        }
                    )
                
                # Monitor at each step
                await asyncio.sleep(60)  # Wait 1 minute between steps
                
                # Check metrics
                recent_metrics = await self._get_recent_metrics(switch_id, minutes=1)
                if recent_metrics:
                    avg_error_rate = sum(m['error_rate'] for m in recent_metrics) / len(recent_metrics)
                    
                    if avg_error_rate > config.error_threshold:
                        # Recovery failed, re-trigger
                        await self.activate_kill_switch(
                            switch_id,
                            f"Recovery failed at {percentage}% - error rate {avg_error_rate:.1f}%",
                            "system"
                        )
                        return
        
        # Recovery complete
        await self.deactivate_kill_switch(switch_id, "auto-recovery")
    
    async def _get_recent_metrics(self, switch_id: str, minutes: int) -> List[Dict[str, Any]]:
        """Get recent metrics for a switch"""
        metrics = []
        pattern = f"kill_switch_metrics:{switch_id}:*"
        min_timestamp = datetime.now() - timedelta(minutes=minutes)
        
        cursor = 0
        while True:
            cursor, keys = await self.redis_client.scan(cursor, match=pattern, count=100)
            
            for key in keys:
                timestamp = int(key.decode().split(":")[-1])
                if datetime.fromtimestamp(timestamp) > min_timestamp:
                    metric_data = await self.redis_client.hgetall(key)
                    if metric_data:
                        metrics.append({
                            'error_rate': float(metric_data.get(b'error_rate', 0)),
                            'avg_latency': float(metric_data.get(b'avg_latency', 0)),
                            'total_requests': int(metric_data.get(b'total_requests', 0))
                        })
            
            if cursor == 0:
                break
        
        return metrics
    
    async def _send_notifications(self, config: KillSwitchConfig, 
                                activation: KillSwitchActivation):
        """Send notifications about kill switch activation"""
        for channel in config.notification_channels:
            try:
                if channel.startswith("slack:"):
                    await self._send_slack_notification(channel, config, activation)
                elif channel.startswith("pagerduty:"):
                    await self._send_pagerduty_alert(channel, config, activation)
                elif channel.startswith("email:"):
                    await self._send_email_notification(channel, config, activation)
            except Exception as e:
                logger.error(f"Failed to send notification to {channel}: {e}")
    
    async def _send_slack_notification(self, channel: str, config: KillSwitchConfig,
                                     activation: KillSwitchActivation):
        """Send Slack notification"""
        webhook_url = channel.replace("slack:", "")
        
        message = {
            "text": f"🚨 Kill Switch Activated: {config.name}",
            "attachments": [{
                "color": "danger",
                "fields": [
                    {"title": "Switch", "value": config.name, "short": True},
                    {"title": "Scope", "value": f"{config.scope} - {config.scope_value}", "short": True},
                    {"title": "Reason", "value": activation.reason, "short": False},
                    {"title": "Activated By", "value": activation.activated_by, "short": True},
                    {"title": "Time", "value": activation.activated_at.strftime("%Y-%m-%d %H:%M:%S UTC"), "short": True}
                ]
            }]
        }
        
        async with aiohttp.ClientSession() as session:
            await session.post(webhook_url, json=message)
    
    async def get_kill_switch_dashboard(self) -> Dict[str, Any]:
        """Get dashboard data for all kill switches"""
        dashboard = {
            "total_switches": 0,
            "active_switches": 0,
            "triggered_switches": [],
            "recent_activations": [],
            "metrics_summary": {},
            "by_scope": defaultdict(int)
        }
        
        # Get all switches
        cursor = 0
        while True:
            cursor, keys = await self.redis_client.scan(
                cursor, match="kill_switch:*", count=100
            )
            
            for key in keys:
                if key.decode().count(":") == 1:  # Main switch keys
                    dashboard["total_switches"] += 1
                    
                    # Get state and config
                    data = await self.redis_client.hmget(key, ["state", "config"])
                    state = data[0]
                    config_data = data[1]
                    
                    if state == KillSwitchState.TRIGGERED:
                        dashboard["active_switches"] += 1
                        
                        if config_data:
                            config = json.loads(config_data)
                            dashboard["triggered_switches"].append({
                                "id": config["id"],
                                "name": config["name"],
                                "scope": config["scope"]
                            })
                    
                    if config_data:
                        config = json.loads(config_data)
                        dashboard["by_scope"][config["scope"]] += 1
            
            if cursor == 0:
                break
        
        # Get recent activations
        activation_pattern = "kill_switch_activation:*"
        recent_activations = []
        
        cursor = 0
        while True:
            cursor, keys = await self.redis_client.scan(
                cursor, match=activation_pattern, count=50
            )
            
            for key in keys:
                activation_data = await self.redis_client.get(key)
                if activation_data:
                    activation = json.loads(activation_data)
                    recent_activations.append(activation)
            
            if cursor == 0:
                break
        
        # Sort and limit recent activations
        recent_activations.sort(key=lambda x: x['activated_at'], reverse=True)
        dashboard["recent_activations"] = recent_activations[:10]
        
        return dashboard

def dataclass_to_dict(obj):
    """Convert dataclass to dict for JSON serialization"""
    if hasattr(obj, '__dataclass_fields__'):
        return {k: dataclass_to_dict(v) for k, v in obj.__dict__.items()}
    elif isinstance(obj, list):
        return [dataclass_to_dict(item) for item in obj]
    elif isinstance(obj, dict):
        return {k: dataclass_to_dict(v) for k, v in obj.items()}
    else:
        return obj

# Predefined kill switches for common scenarios
PREDEFINED_KILL_SWITCHES = [
    KillSwitchConfig(
        id="global_emergency",
        name="Global Emergency Stop",
        description="Disables all non-critical features globally",
        scope=KillSwitchScope.GLOBAL,
        affected_features=["new_features", "experimental_features"],
        error_threshold=25.0,
        auto_recovery_enabled=False,
        notification_channels=["slack:emergency-webhook", "pagerduty:critical"]
    ),
    KillSwitchConfig(
        id="payment_protection",
        name="Payment System Protection",
        description="Protects payment processing from failures",
        scope=KillSwitchScope.SERVICE,
        scope_value="payment-service",
        affected_features=["new_payment_flow", "instant_checkout"],
        error_threshold=5.0,
        latency_threshold=1.0,
        auto_trigger_enabled=True,
        circuit_breaker_enabled=True,
        gradual_recovery=True
    ),
    KillSwitchConfig(
        id="region_us_east",
        name="US East Region Switch",
        description="Regional kill switch for US East",
        scope=KillSwitchScope.REGION,
        scope_value="us-east-1",
        affected_services=["api", "web", "mobile-backend"],
        error_threshold=30.0,
        auto_recovery_enabled=True,
        recovery_delay_seconds=600
    )
]
```

## 📊 Part 5: Telemetry and Analytics

### Step 5: Create Telemetry System

**Copilot Prompt Suggestion:**
```python
# Create a telemetry system that:
# - Tracks feature flag evaluations and impacts
# - Monitors deployment progression in real-time
# - Correlates business metrics with deployments
# - Provides attribution analysis for changes
# - Generates automated insights and recommendations
# - Exports data to analytics platforms
# Use event streaming with Apache Kafka compatibility
```

**Expected Output:**
Create `progressive_delivery/telemetry.py`:
```python
import asyncio
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from enum import Enum
import json
import uuid
from collections import defaultdict
import numpy as np
from aiokafka import AIOKafkaProducer, AIOKafkaConsumer
import pandas as pd
from sklearn.linear_model import LinearRegression
import logging

logger = logging.getLogger(__name__)

class EventType(str, Enum):
    FLAG_EVALUATED = "flag_evaluated"
    FLAG_UPDATED = "flag_updated"
    DEPLOYMENT_STARTED = "deployment_started"
    DEPLOYMENT_STAGE_COMPLETED = "deployment_stage_completed"
    DEPLOYMENT_FAILED = "deployment_failed"
    KILL_SWITCH_TRIGGERED = "kill_switch_triggered"
    METRIC_RECORDED = "metric_recorded"
    USER_ACTION = "user_action"
    ERROR_OCCURRED = "error_occurred"

@dataclass
class TelemetryEvent:
    """Base telemetry event"""
    event_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    event_type: EventType = EventType.FLAG_EVALUATED
    timestamp: datetime = field(default_factory=datetime.now)
    
    # Context
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    request_id: Optional[str] = None
    
    # Event specific data
    data: Dict[str, Any] = field(default_factory=dict)
    
    # Metadata
    service_name: Optional[str] = None
    service_version: Optional[str] = None
    environment: Optional[str] = None
    region: Optional[str] = None

@dataclass
class MetricDefinition:
    """Definition of a tracked metric"""
    name: str
    type: str  # counter, gauge, histogram
    unit: str
    description: str
    tags: List[str] = field(default_factory=list)
    
    # Aggregation settings
    aggregation_method: str = "avg"  # avg, sum, max, min, p95
    window_seconds: int = 60
    
    # Alert thresholds
    warning_threshold: Optional[float] = None
    critical_threshold: Optional[float] = None

class TelemetryService:
    """
    Comprehensive telemetry service for progressive delivery
    """
    
    def __init__(self, kafka_bootstrap_servers: str):
        self.kafka_servers = kafka_bootstrap_servers
        self.producer: Optional[AIOKafkaProducer] = None
        self.consumer: Optional[AIOKafkaConsumer] = None
        
        # In-memory buffers
        self.event_buffer: List[TelemetryEvent] = []
        self.metric_buffer: Dict[str, List[Tuple[datetime, float]]] = defaultdict(list)
        
        # Analytics cache
        self.attribution_cache: Dict[str, Any] = {}
        self.correlation_cache: Dict[str, float] = {}
        
        # Metric definitions
        self.metrics: Dict[str, MetricDefinition] = {}
        self._register_default_metrics()
        
    def _register_default_metrics(self):
        """Register default metrics"""
        default_metrics = [
            MetricDefinition(
                name="deployment.duration",
                type="histogram",
                unit="seconds",
                description="Time taken for deployment stages"
            ),
            MetricDefinition(
                name="feature_flag.evaluation_rate",
                type="counter",
                unit="evaluations/sec",
                description="Rate of feature flag evaluations"
            ),
            MetricDefinition(
                name="kill_switch.activation_count",
                type="counter",
                unit="activations",
                description="Number of kill switch activations"
            ),
            MetricDefinition(
                name="error_rate",
                type="gauge",
                unit="percentage",
                description="Application error rate",
                warning_threshold=5.0,
                critical_threshold=10.0
            ),
            MetricDefinition(
                name="conversion_rate",
                type="gauge",
                unit="percentage",
                description="User conversion rate",
                aggregation_method="avg"
            ),
            MetricDefinition(
                name="revenue_per_user",
                type="gauge",
                unit="dollars",
                description="Average revenue per user",
                aggregation_method="avg"
            )
        ]
        
        for metric in default_metrics:
            self.metrics[metric.name] = metric
    
    async def connect(self):
        """Initialize connections"""
        # Create Kafka producer
        self.producer = AIOKafkaProducer(
            bootstrap_servers=self.kafka_servers,
            value_serializer=lambda v: json.dumps(v, default=str).encode()
        )
        await self.producer.start()
        
        # Create consumer for analytics
        self.consumer = AIOKafkaConsumer(
            'telemetry_events',
            bootstrap_servers=self.kafka_servers,
            value_deserializer=lambda v: json.loads(v.decode())
        )
        await self.consumer.start()
        
        # Start background tasks
        asyncio.create_task(self._process_event_buffer())
        asyncio.create_task(self._process_analytics())
    
    async def disconnect(self):
        """Cleanup connections"""
        if self.producer:
            await self.producer.stop()
        if self.consumer:
            await self.consumer.stop()
    
    async def track_event(self, event: TelemetryEvent):
        """Track a telemetry event"""
        # Add to buffer for batching
        self.event_buffer.append(event)
        
        # Process immediately if buffer is large
        if len(self.event_buffer) >= 100:
            await self._flush_event_buffer()
    
    async def track_metric(self, name: str, value: float, tags: Dict[str, str] = None):
        """Track a metric value"""
        if name not in self.metrics:
            logger.warning(f"Unknown metric: {name}")
            return
        
        # Create metric event
        event = TelemetryEvent(
            event_type=EventType.METRIC_RECORDED,
            data={
                "metric_name": name,
                "value": value,
                "tags": tags or {}
            }
        )
        
        await self.track_event(event)
        
        # Buffer for aggregation
        self.metric_buffer[name].append((datetime.now(), value))
    
    async def track_flag_evaluation(self, flag_key: str, user_id: str,
                                  value: Any, variation: Optional[str] = None,
                                  evaluation_time_ms: float = 0):
        """Track feature flag evaluation"""
        event = TelemetryEvent(
            event_type=EventType.FLAG_EVALUATED,
            user_id=user_id,
            data={
                "flag_key": flag_key,
                "value": value,
                "variation": variation,
                "evaluation_time_ms": evaluation_time_ms
            }
        )
        
        await self.track_event(event)
    
    async def track_deployment_event(self, deployment_id: str, stage: str,
                                   status: str, duration_seconds: Optional[float] = None):
        """Track deployment progression"""
        event_type = EventType.DEPLOYMENT_STARTED
        if status == "completed":
            event_type = EventType.DEPLOYMENT_STAGE_COMPLETED
        elif status == "failed":
            event_type = EventType.DEPLOYMENT_FAILED
        
        event = TelemetryEvent(
            event_type=event_type,
            data={
                "deployment_id": deployment_id,
                "stage": stage,
                "status": status,
                "duration_seconds": duration_seconds
            }
        )
        
        await self.track_event(event)
        
        # Track duration metric
        if duration_seconds:
            await self.track_metric(
                "deployment.duration",
                duration_seconds,
                {"stage": stage, "status": status}
            )
    
    async def track_user_action(self, user_id: str, action: str,
                              properties: Dict[str, Any] = None):
        """Track user behavior"""
        event = TelemetryEvent(
            event_type=EventType.USER_ACTION,
            user_id=user_id,
            data={
                "action": action,
                "properties": properties or {}
            }
        )
        
        await self.track_event(event)
    
    async def _process_event_buffer(self):
        """Background task to process event buffer"""
        while True:
            try:
                await asyncio.sleep(5)  # Process every 5 seconds
                await self._flush_event_buffer()
            except Exception as e:
                logger.error(f"Error processing event buffer: {e}")
    
    async def _flush_event_buffer(self):
        """Flush events to Kafka"""
        if not self.event_buffer:
            return
        
        events_to_send = self.event_buffer[:1000]  # Limit batch size
        self.event_buffer = self.event_buffer[1000:]
        
        # Send to Kafka
        for event in events_to_send:
            await self.producer.send(
                'telemetry_events',
                value=dataclass_to_dict(event)
            )
        
        logger.debug(f"Flushed {len(events_to_send)} events to Kafka")
    
    async def _process_analytics(self):
        """Background task to process analytics"""
        while True:
            try:
                # Consume events for analytics
                records = await self.consumer.getmany(timeout_ms=1000)
                
                for topic_partition, messages in records.items():
                    for message in messages:
                        event = message.value
                        await self._analyze_event(event)
                
                # Periodic analysis
                await self._run_attribution_analysis()
                await self._detect_anomalies()
                
                await asyncio.sleep(30)  # Run every 30 seconds
                
            except Exception as e:
                logger.error(f"Error in analytics processing: {e}")
                await asyncio.sleep(60)
    
    async def _analyze_event(self, event: Dict[str, Any]):
        """Analyze individual event for insights"""
        event_type = event.get('event_type')
        
        if event_type == EventType.FLAG_EVALUATED:
            # Track flag usage patterns
            flag_key = event['data']['flag_key']
            user_id = event.get('user_id')
            value = event['data']['value']
            
            # Update attribution data
            if flag_key not in self.attribution_cache:
                self.attribution_cache[flag_key] = {
                    'evaluations': 0,
                    'unique_users': set(),
                    'value_distribution': defaultdict(int)
                }
            
            self.attribution_cache[flag_key]['evaluations'] += 1
            self.attribution_cache[flag_key]['unique_users'].add(user_id)
            self.attribution_cache[flag_key]['value_distribution'][str(value)] += 1
        
        elif event_type == EventType.USER_ACTION:
            # Track user behavior for correlation
            action = event['data']['action']
            if action in ['purchase', 'conversion', 'signup']:
                # Store for correlation analysis
                pass
    
    async def _run_attribution_analysis(self):
        """Run attribution analysis for feature impacts"""
        # Get recent metrics
        recent_metrics = await self._get_recent_metrics(minutes=60)
        
        # For each active feature flag
        for flag_key, flag_data in self.attribution_cache.items():
            if flag_data['evaluations'] < 100:
                continue  # Need sufficient data
            
            # Calculate impact metrics
            impact = await self._calculate_feature_impact(flag_key, recent_metrics)
            
            if impact:
                # Store attribution results
                await self._store_attribution(flag_key, impact)
    
    async def _calculate_feature_impact(self, flag_key: str, 
                                      metrics: Dict[str, List[float]]) -> Optional[Dict[str, float]]:
        """Calculate the impact of a feature on business metrics"""
        # This is a simplified example - in production use more sophisticated methods
        flag_data = self.attribution_cache.get(flag_key, {})
        
        if not flag_data or flag_data['evaluations'] < 100:
            return None
        
        # Calculate adoption rate
        unique_users = len(flag_data['unique_users'])
        adoption_rate = unique_users / max(1000, unique_users) * 100  # Simplified
        
        # Estimate impact on key metrics
        impact = {
            'adoption_rate': adoption_rate,
            'estimated_revenue_impact': 0.0,
            'estimated_conversion_impact': 0.0,
            'confidence_score': 0.0
        }
        
        # Use value distribution to estimate impact
        value_dist = flag_data['value_distribution']
        if 'true' in value_dist and 'false' in value_dist:
            treatment_pct = value_dist['true'] / (value_dist['true'] + value_dist['false'])
            
            # Simplified impact calculation
            if 'conversion_rate' in metrics and len(metrics['conversion_rate']) > 2:
                # Use linear regression for trend
                X = np.arange(len(metrics['conversion_rate'])).reshape(-1, 1)
                y = np.array(metrics['conversion_rate'])
                
                model = LinearRegression()
                model.fit(X, y)
                
                trend = model.coef_[0]
                
                # Attribute portion of trend to feature
                impact['estimated_conversion_impact'] = trend * treatment_pct * 100
                impact['confidence_score'] = min(0.95, model.score(X, y))
        
        return impact
    
    async def _detect_anomalies(self):
        """Detect anomalies in metrics"""
        for metric_name, values in self.metric_buffer.items():
            if len(values) < 10:
                continue
            
            # Get recent values
            recent_values = [v for t, v in values if t > datetime.now() - timedelta(minutes=10)]
            
            if len(recent_values) < 5:
                continue
            
            # Simple anomaly detection using z-score
            mean = np.mean(recent_values)
            std = np.std(recent_values)
            
            if std > 0:
                z_scores = [(v - mean) / std for v in recent_values[-3:]]
                
                # Check for anomalies
                for z_score, value in zip(z_scores, recent_values[-3:]):
                    if abs(z_score) > 3:
                        await self._handle_anomaly(metric_name, value, z_score)
    
    async def _handle_anomaly(self, metric_name: str, value: float, z_score: float):
        """Handle detected anomaly"""
        logger.warning(f"Anomaly detected in {metric_name}: value={value}, z_score={z_score}")
        
        # Create anomaly event
        event = TelemetryEvent(
            event_type=EventType.ERROR_OCCURRED,
            data={
                "type": "metric_anomaly",
                "metric_name": metric_name,
                "value": value,
                "z_score": z_score,
                "severity": "high" if abs(z_score) > 4 else "medium"
            }
        )
        
        await self.track_event(event)
    
    async def get_deployment_analytics(self, deployment_id: str) -> Dict[str, Any]:
        """Get analytics for a specific deployment"""
        analytics = {
            'deployment_id': deployment_id,
            'stages': {},
            'total_duration': 0,
            'error_count': 0,
            'affected_users': 0,
            'business_impact': {}
        }
        
        # Query events for this deployment
        # In production, this would query a data store
        
        return analytics
    
    async def get_feature_analytics(self, flag_key: str, 
                                  time_range: timedelta) -> Dict[str, Any]:
        """Get analytics for a feature flag"""
        analytics = {
            'flag_key': flag_key,
            'time_range': str(time_range),
            'usage': {
                'total_evaluations': 0,
                'unique_users': 0,
                'evaluation_rate': 0.0
            },
            'performance': {
                'avg_evaluation_time_ms': 0.0,
                'p95_evaluation_time_ms': 0.0
            },
            'impact': {
                'conversion_lift': 0.0,
                'revenue_impact': 0.0,
                'confidence_interval': [0.0, 0.0]
            },
            'distribution': {}
        }
        
        # Get data from attribution cache
        if flag_key in self.attribution_cache:
            flag_data = self.attribution_cache[flag_key]
            analytics['usage']['total_evaluations'] = flag_data['evaluations']
            analytics['usage']['unique_users'] = len(flag_data['unique_users'])
            analytics['distribution'] = dict(flag_data['value_distribution'])
        
        return analytics
    
    async def generate_insights(self) -> List[Dict[str, Any]]:
        """Generate automated insights and recommendations"""
        insights = []
        
        # Analyze feature adoption
        for flag_key, flag_data in self.attribution_cache.items():
            if flag_data['evaluations'] > 1000:
                adoption_rate = len(flag_data['unique_users']) / max(1000, flag_data['evaluations']) * 100
                
                if adoption_rate < 10:
                    insights.append({
                        'type': 'low_adoption',
                        'severity': 'medium',
                        'feature': flag_key,
                        'message': f"Feature {flag_key} has low adoption ({adoption_rate:.1f}%)",
                        'recommendation': "Consider improving feature discovery or targeting"
                    })
        
        # Analyze deployment patterns
        # This would analyze deployment history
        
        # Analyze error patterns
        if 'error_rate' in self.metric_buffer:
            recent_errors = [v for t, v in self.metric_buffer['error_rate'] 
                           if t > datetime.now() - timedelta(hours=1)]
            
            if recent_errors and np.mean(recent_errors) > 5.0:
                insights.append({
                    'type': 'high_error_rate',
                    'severity': 'high',
                    'message': f"Error rate is elevated ({np.mean(recent_errors):.1f}%)",
                    'recommendation': "Investigate recent deployments and consider rollback"
                })
        
        return insights
    
    async def export_to_analytics_platform(self, platform: str, 
                                         time_range: timedelta) -> bool:
        """Export telemetry data to external analytics platforms"""
        try:
            if platform == "bigquery":
                await self._export_to_bigquery(time_range)
            elif platform == "snowflake":
                await self._export_to_snowflake(time_range)
            elif platform == "databricks":
                await self._export_to_databricks(time_range)
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to export to {platform}: {e}")
            return False
    
    async def _export_to_bigquery(self, time_range: timedelta):
        """Export to Google BigQuery"""
        # Implementation would use BigQuery client
        logger.info(f"Exporting {time_range} of data to BigQuery")
    
    async def _get_recent_metrics(self, minutes: int) -> Dict[str, List[float]]:
        """Get recent metric values"""
        cutoff = datetime.now() - timedelta(minutes=minutes)
        recent_metrics = {}
        
        for metric_name, values in self.metric_buffer.items():
            recent_values = [v for t, v in values if t > cutoff]
            if recent_values:
                recent_metrics[metric_name] = recent_values
        
        return recent_metrics
    
    async def _store_attribution(self, flag_key: str, impact: Dict[str, float]):
        """Store attribution results"""
        # In production, store in a database
        logger.info(f"Attribution for {flag_key}: {impact}")

# Utility function
def dataclass_to_dict(obj):
    """Convert dataclass to dict for JSON serialization"""
    if hasattr(obj, '__dataclass_fields__'):
        return {k: dataclass_to_dict(v) for k, v in obj.__dict__.items()}
    elif isinstance(obj, list):
        return [dataclass_to_dict(item) for item in obj]
    elif isinstance(obj, dict):
        return {k: dataclass_to_dict(v) for k, v in obj.items()}
    elif isinstance(obj, set):
        return list(obj)
    else:
        return obj
```

## ✅ Part 6: Complete System Testing

### Step 6: Create Integration Tests

**Copilot Prompt Suggestion:**
```python
# Create comprehensive integration tests that:
# - Test the complete progressive delivery workflow
# - Validate feature flag targeting and segmentation
# - Test kill switch activation and recovery
# - Verify telemetry data collection and analysis
# - Simulate failure scenarios and rollbacks
# - Measure system performance under load
# Use pytest with async support and test containers
```

**Expected Output:**
Create `tests/test_progressive_delivery_integration.py`:
```python
import pytest
import asyncio
from datetime import datetime, timedelta
import json
from unittest.mock import Mock, AsyncMock, patch
import numpy as np

from progressive_delivery.orchestrator import (
    ProgressiveDeliveryOrchestrator,
    ProgressiveDeployment,
    DeploymentStage,
    DeploymentStrategy,
    BlueGreenExecutor,
    CanaryExecutor,
    FeatureFlagExecutor
)
from feature_flags.service import (
    FeatureFlagService,
    FeatureFlagConfig,
    FlagEvaluationContext,
    FlagType
)
from feature_flags.segmentation import (
    SegmentationService,
    Segment,
    SegmentType,
    UserProfile
)
from progressive_delivery.kill_switch import (
    KillSwitchService,
    KillSwitchConfig,
    KillSwitchScope
)
from progressive_delivery.telemetry import (
    TelemetryService,
    TelemetryEvent,
    EventType
)

@pytest.fixture
async def test_environment():
    """Create test environment with all services"""
    # Mock Redis
    redis_url = "redis://localhost:6379/0"
    
    # Create services
    flag_service = FeatureFlagService(redis_url)
    segment_service = SegmentationService(redis_url)
    kill_switch_service = KillSwitchService(redis_url, flag_service)
    telemetry_service = TelemetryService("localhost:9092")
    
    # Mock connections
    flag_service.redis_client = AsyncMock()
    segment_service.redis_client = AsyncMock()
    kill_switch_service.redis_client = AsyncMock()
    telemetry_service.producer = AsyncMock()
    
    # Create orchestrator
    orchestrator = ProgressiveDeliveryOrchestrator()
    
    # Register executors
    blue_green_executor = BlueGreenExecutor(Mock(), Mock())
    canary_executor = CanaryExecutor(Mock(), Mock())
    feature_flag_executor = FeatureFlagExecutor(flag_service, segment_service)
    
    orchestrator.register_executor(DeploymentStrategy.BLUE_GREEN, blue_green_executor)
    orchestrator.register_executor(DeploymentStrategy.CANARY, canary_executor)
    orchestrator.register_executor(DeploymentStrategy.FEATURE_FLAG, feature_flag_executor)
    
    yield {
        'orchestrator': orchestrator,
        'flag_service': flag_service,
        'segment_service': segment_service,
        'kill_switch_service': kill_switch_service,
        'telemetry_service': telemetry_service
    }
    
    # Cleanup
    await flag_service.disconnect()
    await segment_service.disconnect()
    await kill_switch_service.disconnect()
    await telemetry_service.disconnect()

@pytest.mark.asyncio
class TestProgressiveDeliveryIntegration:
    """Integration tests for complete progressive delivery system"""
    
    async def test_complete_deployment_workflow(self, test_environment):
        """Test a complete multi-stage deployment"""
        orchestrator = test_environment['orchestrator']
        
        # Create deployment configuration
        config = {
            "name": "Test Feature Release",
            "version": "1.0.0",
            "stages": [
                {
                    "name": "backend_deployment",
                    "strategy": "blue_green",
                    "config": {
                        "app_name": "test-api",
                        "image": "test:1.0.0"
                    }
                },
                {
                    "name": "feature_flag_rollout",
                    "strategy": "feature_flag",
                    "dependencies": ["backend_deployment"],
                    "config": {
                        "flag_key": "test_feature",
                        "progressive_rollout": True,
                        "rollout_stages": [
                            {"percentage": 10, "duration_minutes": 1},
                            {"percentage": 50, "duration_minutes": 1},
                            {"percentage": 100, "duration_minutes": 1}
                        ]
                    }
                }
            ]
        }
        
        # Create deployment
        deployment = await orchestrator.create_deployment(config)
        assert deployment.id
        assert len(deployment.stages) == 2
        
        # Mock executor responses
        for executor in orchestrator.executors.values():
            executor.execute = AsyncMock(return_value=(True, "Success"))
            executor.validate = AsyncMock(return_value=(True, "Validated"))
        
        # Start deployment
        success = await orchestrator.start_deployment(deployment.id)
        assert success
        
        # Wait for completion (with timeout)
        max_wait = 10
        start_time = datetime.now()
        
        while deployment.status == "in_progress":
            await asyncio.sleep(0.5)
            if (datetime.now() - start_time).total_seconds() > max_wait:
                break
        
        # Verify deployment completed
        status = orchestrator.get_deployment_status(deployment.id)
        assert status
        assert all(stage['status'] in ['completed', 'in_progress'] 
                  for stage in status['stages'])
    
    async def test_feature_flag_with_segmentation(self, test_environment):
        """Test feature flag evaluation with user segmentation"""
        flag_service = test_environment['flag_service']
        segment_service = test_environment['segment_service']
        
        # Create user segment
        segment = Segment(
            id="beta_users",
            name="Beta Users",
            type=SegmentType.RULE_BASED,
            rules=[{"field": "user_type", "operator": "equals", "value": "beta"}]
        )
        
        # Mock segment creation
        segment_service.redis_client.exists = AsyncMock(return_value=False)
        segment_service.redis_client.hset = AsyncMock(return_value=True)
        segment_service.redis_client.sadd = AsyncMock(return_value=True)
        
        await segment_service.create_segment(segment)
        
        # Create feature flag with targeting
        flag_config = FeatureFlagConfig(
            key="beta_feature",
            name="Beta Feature",
            flag_type=FlagType.BOOLEAN,
            default_value=False,
            targeting_enabled=True,
            targeting_rules=[{
                "attribute": "user_segment",
                "operator": "contains",
                "value": "beta_users",
                "return_value": True
            }]
        )
        
        # Mock flag operations
        flag_service.redis_client.exists = AsyncMock(return_value=False)
        flag_service.redis_client.hset = AsyncMock(return_value=True)
        flag_service.redis_client.hget = AsyncMock(
            return_value=flag_config.json()
        )
        
        await flag_service.create_flag(flag_config)
        
        # Test evaluation for beta user
        beta_context = FlagEvaluationContext(
            user_id="user123",
            attributes={"user_type": "beta", "user_segment": ["beta_users"]}
        )
        
        result = await flag_service.evaluate_flag("beta_feature", beta_context)
        assert result.value == True
        assert result.reason == "targeting_match"
        
        # Test evaluation for regular user
        regular_context = FlagEvaluationContext(
            user_id="user456",
            attributes={"user_type": "regular"}
        )
        
        result = await flag_service.evaluate_flag("beta_feature", regular_context)
        assert result.value == False
        assert result.reason == "default"
    
    async def test_kill_switch_activation_and_recovery(self, test_environment):
        """Test kill switch activation and auto-recovery"""
        kill_switch_service = test_environment['kill_switch_service']
        flag_service = test_environment['flag_service']
        
        # Create kill switch
        switch_config = KillSwitchConfig(
            id="test_protection",
            name="Test Protection Switch",
            scope=KillSwitchScope.FEATURE,
            affected_features=["risky_feature"],
            error_threshold=10.0,
            auto_trigger_enabled=True,
            auto_recovery_enabled=True,
            recovery_delay_seconds=5
        )
        
        # Mock Redis operations
        kill_switch_service.redis_client.exists = AsyncMock(return_value=False)
        kill_switch_service.redis_client.hset = AsyncMock(return_value=True)
        kill_switch_service.redis_client.hget = AsyncMock(side_effect=[
            json.dumps(dataclass_to_dict(switch_config), default=str),
            "inactive"
        ])
        kill_switch_service.redis_client.sadd = AsyncMock(return_value=True)
        
        await kill_switch_service.create_kill_switch(switch_config)
        
        # Simulate high error rate
        for i in range(100):
            await kill_switch_service.record_request_metrics(
                "test_protection",
                success=i % 5 != 0,  # 20% error rate
                latency=0.1,
                error_type="test_error" if i % 5 == 0 else None
            )
        
        # Process metrics batch
        await kill_switch_service._process_metrics_batch("test_protection")
        
        # Verify kill switch would be triggered
        # (In real test, this would happen automatically)
        assert len(kill_switch_service.metrics_buffer["test_protection"]) == 0
    
    async def test_telemetry_and_analytics(self, test_environment):
        """Test telemetry collection and analysis"""
        telemetry_service = test_environment['telemetry_service']
        
        # Track various events
        events = [
            TelemetryEvent(
                event_type=EventType.FLAG_EVALUATED,
                user_id="user1",
                data={"flag_key": "test_flag", "value": True}
            ),
            TelemetryEvent(
                event_type=EventType.DEPLOYMENT_STARTED,
                data={"deployment_id": "deploy1", "stage": "canary"}
            ),
            TelemetryEvent(
                event_type=EventType.USER_ACTION,
                user_id="user1",
                data={"action": "purchase", "amount": 99.99}
            )
        ]
        
        for event in events:
            await telemetry_service.track_event(event)
        
        # Verify events buffered
        assert len(telemetry_service.event_buffer) == 3
        
        # Flush buffer
        await telemetry_service._flush_event_buffer()
        
        # Verify producer called
        assert telemetry_service.producer.send.call_count == 3
        
        # Test metric tracking
        await telemetry_service.track_metric("conversion_rate", 15.5)
        await telemetry_service.track_metric("error_rate", 2.1)
        
        # Generate insights
        insights = await telemetry_service.generate_insights()
        assert isinstance(insights, list)
    
    async def test_deployment_rollback_scenario(self, test_environment):
        """Test deployment rollback on failure"""
        orchestrator = test_environment['orchestrator']
        
        # Create deployment with failure scenario
        config = {
            "name": "Failing Deployment",
            "version": "2.0.0",
            "stages": [
                {
                    "name": "stage1",
                    "strategy": "blue_green",
                    "config": {"app_name": "test-app"}
                },
                {
                    "name": "stage2",
                    "strategy": "canary",
                    "dependencies": ["stage1"],
                    "config": {"app_name": "test-app"},
                    "rollback_on_failure": True
                }
            ]
        }
        
        deployment = await orchestrator.create_deployment(config)
        
        # Mock first stage success, second stage failure
        blue_green_executor = orchestrator.executors[DeploymentStrategy.BLUE_GREEN]
        canary_executor = orchestrator.executors[DeploymentStrategy.CANARY]
        
        blue_green_executor.execute = AsyncMock(return_value=(True, "Success"))
        blue_green_executor.validate = AsyncMock(return_value=(True, "Valid"))
        blue_green_executor.rollback = AsyncMock(return_value=(True, "Rolled back"))
        
        canary_executor.execute = AsyncMock(return_value=(False, "Deployment failed"))
        canary_executor.rollback = AsyncMock(return_value=(True, "Rolled back"))
        
        # Start deployment
        await orchestrator.start_deployment(deployment.id)
        
        # Wait for processing
        await asyncio.sleep(2)
        
        # Verify rollback was called
        assert blue_green_executor.rollback.called
        assert deployment.status == "failed"
    
    async def test_progressive_delivery_performance(self, test_environment):
        """Test system performance under load"""
        flag_service = test_environment['flag_service']
        telemetry_service = test_environment['telemetry_service']
        
        # Create multiple flags
        flags = []
        for i in range(10):
            flag = FeatureFlagConfig(
                key=f"perf_flag_{i}",
                name=f"Performance Flag {i}",
                flag_type=FlagType.BOOLEAN,
                default_value=False,
                rollout_enabled=True,
                rollout_percentage=50
            )
            flags.append(flag)
        
        # Mock flag operations for performance
        flag_service.redis_client.hget = AsyncMock(
            side_effect=[f.json() for f in flags] * 100
        )
        flag_service.redis_client.hincrby = AsyncMock()
        
        # Simulate high-volume evaluations
        start_time = datetime.now()
        evaluation_tasks = []
        
        for i in range(1000):
            context = FlagEvaluationContext(
                user_id=f"user_{i % 100}",
                attributes={"segment": "test"}
            )
            
            task = flag_service.evaluate_flag(f"perf_flag_{i % 10}", context)
            evaluation_tasks.append(task)
        
        # Execute all evaluations concurrently
        results = await asyncio.gather(*evaluation_tasks, return_exceptions=True)
        
        duration = (datetime.now() - start_time).total_seconds()
        
        # Verify performance
        successful_evaluations = sum(1 for r in results if not isinstance(r, Exception))
        assert successful_evaluations > 950  # Allow some failures
        assert duration < 5.0  # Should complete within 5 seconds
        
        # Calculate throughput
        throughput = successful_evaluations / duration
        logger.info(f"Evaluation throughput: {throughput:.2f} evaluations/second")

@pytest.mark.asyncio
class TestEndToEndScenarios:
    """End-to-end scenario tests"""
    
    async def test_feature_launch_scenario(self, test_environment):
        """Test complete feature launch workflow"""
        # This test simulates launching a new feature with:
        # 1. Backend deployment (blue-green)
        # 2. Feature flag creation with targeting
        # 3. Canary rollout to users
        # 4. Kill switch protection
        # 5. Telemetry tracking
        
        orchestrator = test_environment['orchestrator']
        flag_service = test_environment['flag_service']
        kill_switch_service = test_environment['kill_switch_service']
        telemetry_service = test_environment['telemetry_service']
        
        # Step 1: Create deployment plan
        deployment_config = {
            "name": "New Checkout Feature",
            "version": "3.0.0",
            "stages": [
                {
                    "name": "api_deployment",
                    "strategy": "blue_green",
                    "config": {
                        "app_name": "checkout-api",
                        "image": "checkout:3.0.0"
                    }
                },
                {
                    "name": "enable_feature",
                    "strategy": "feature_flag",
                    "dependencies": ["api_deployment"],
                    "config": {
                        "flag_key": "new_checkout",
                        "progressive_rollout": True,
                        "rollout_stages": [
                            {"percentage": 5, "duration_minutes": 5},
                            {"percentage": 25, "duration_minutes": 10},
                            {"percentage": 50, "duration_minutes": 30},
                            {"percentage": 100, "duration_minutes": 60}
                        ]
                    }
                },
                {
                    "name": "frontend_rollout",
                    "strategy": "canary",
                    "dependencies": ["enable_feature"],
                    "config": {
                        "app_name": "checkout-ui",
                        "initial_weight": 10,
                        "increment": 20,
                        "interval_seconds": 300
                    }
                }
            ]
        }
        
        # Step 2: Create kill switch for protection
        kill_switch = KillSwitchConfig(
            id="checkout_protection",
            name="Checkout Protection",
            scope=KillSwitchScope.FEATURE,
            affected_features=["new_checkout"],
            error_threshold=5.0,
            auto_trigger_enabled=True
        )
        
        await kill_switch_service.create_kill_switch(kill_switch)
        
        # Step 3: Start deployment
        deployment = await orchestrator.create_deployment(deployment_config)
        
        # Mock successful execution
        for executor in orchestrator.executors.values():
            executor.execute = AsyncMock(return_value=(True, "Success"))
            executor.validate = AsyncMock(return_value=(True, "Valid"))
        
        await orchestrator.start_deployment(deployment.id)
        
        # Step 4: Simulate user interactions
        for i in range(100):
            # Track flag evaluation
            await telemetry_service.track_flag_evaluation(
                "new_checkout",
                f"user_{i}",
                i % 2 == 0,  # 50% get new experience
                evaluation_time_ms=np.random.normal(10, 2)
            )
            
            # Track user actions
            if i % 10 == 0:
                await telemetry_service.track_user_action(
                    f"user_{i}",
                    "checkout_completed",
                    {"amount": np.random.uniform(50, 500)}
                )
        
        # Step 5: Verify everything worked
        status = orchestrator.get_deployment_status(deployment.id)
        assert status
        
        # Check telemetry collected
        assert len(telemetry_service.event_buffer) > 0
        
        # Generate insights
        insights = await telemetry_service.generate_insights()
        assert isinstance(insights, list)

# Helper function for tests
def dataclass_to_dict(obj):
    """Convert dataclass to dict for JSON serialization"""
    if hasattr(obj, '__dataclass_fields__'):
        return {k: dataclass_to_dict(v) for k, v in obj.__dict__.items()}
    elif isinstance(obj, list):
        return [dataclass_to_dict(item) for item in obj]
    elif isinstance(obj, dict):
        return {k: dataclass_to_dict(v) for k, v in obj.items()}
    else:
        return obj
```

## 🎯 Exercise Summary

### What You've Accomplished

In this mastery-level exercise, you've successfully:

1. ✅ Built a complete feature flag service with advanced targeting
2. ✅ Implemented sophisticated user segmentation with ML capabilities
3. ✅ Created a progressive delivery orchestrator combining all strategies
4. ✅ Developed kill switches with automatic protection and recovery
5. ✅ Built comprehensive telemetry with analytics and insights
6. ✅ Tested the entire system with integration scenarios

### Key Takeaways

- **Unified Strategy**: Progressive delivery combines multiple deployment strategies for maximum control
- **Feature Flags as Code**: Treat feature flags as first-class deployment artifacts
- **Segmentation Power**: Advanced targeting enables precise control over feature exposure
- **Safety First**: Kill switches provide essential protection for production systems
- **Data-Driven**: Telemetry and analytics enable informed decisions
- **Automation**: Orchestration reduces manual intervention and human error

### Architecture Best Practices

1. **Separation of Concerns**: Each component has a specific responsibility
2. **Event-Driven**: Use events for loose coupling between services
3. **Resilience**: Circuit breakers and fallbacks prevent cascading failures
4. **Observability**: Comprehensive telemetry enables debugging and optimization
5. **Testability**: Design for testing with dependency injection and mocking

## 🚀 Production Considerations

### Performance Optimization
- Use caching for flag evaluations
- Batch telemetry events
- Implement connection pooling
- Use CDN for flag definitions

### Security Hardening
- Encrypt sensitive flag values
- Implement RBAC for flag management
- Audit all flag changes
- Secure WebSocket connections

### Scalability Patterns
- Horizontal scaling for flag service
- Partitioned telemetry storage
- Regional flag replication
- Edge computing for evaluations

## 📚 Additional Resources

- [Progressive Delivery Patterns](https://www.infoq.com/articles/progressive-delivery-patterns/)
- [Feature Flag Best Practices](https://featureflags.io/feature-flag-best-practices/)
- [LaunchDarkly Architecture](https://launchdarkly.com/blog/tagged/architecture/)
- [Kill Switch Patterns](https://martinfowler.com/articles/patterns-of-distributed-systems/circuit-breaker.html)

---

🎉 **Congratulations!** You've mastered the most advanced deployment strategies! You now have the skills to implement enterprise-grade progressive delivery systems that give you complete control over production deployments.

### 🏆 Module Completion

You've successfully completed Module 20: Production Deployment Strategies! 

**Your Journey**:
- ✅ Exercise 1: Blue-Green Deployment (Foundation)
- ✅ Exercise 2: Canary Deployment (Application)  
- ✅ Exercise 3: Feature Flags & Progressive Delivery (Mastery)

You're now ready to move on to Module 21: Introduction to AI Agents! 🤖