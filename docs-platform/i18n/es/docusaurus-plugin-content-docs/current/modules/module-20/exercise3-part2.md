---
sidebar_position: 5
title: "Exercise 3: Part 2"
description: "## 🔄 Part 3: Progressive Delivery Orchestration"
---

# Ejercicio 3: Feature Flags & Progressive Delivery - Partee 2 (⭐⭐⭐ Mastery)

## 🔄 Partee 3: Progressive Delivery Orchestration

### Step 3: Create Progressive Delivery Orchestrator

**Copilot Prompt Suggestion:**
```python
# Create a progressive delivery orchestrator that:
# - Combines blue-green, canary, and feature flags strategies
# - Implements deployment workflows with state management
# - Provides automated decision gates based on metrics
# - Supports multi-stage deployments with dependencies
# - Includes rollback at any stage
# - Tracks deployment history and analytics
# - Integrates with GitOps for configuration
# Use state machine pattern with asyncio
```

**Expected Output:**
Create `progressive_delivery/orchestrator.py`:
```python
import asyncio
from typing import Dict, List, Optional, Any, Callable, Tuple
from datetime import datetime, timedelta
from enum import Enum
from dataclasses import dataclass, field
import json
import uuid
from abc import ABC, abstractmethod
import logging
import yaml
from prometheus_client import Counter, Histogram, Gauge

logger = logging.getLogger(__name__)

# Metrics
deployment_stage_duration = Histogram(
    'progressive_delivery_stage_duration_seconds',
    'Duration of each deployment stage',
    ['deployment_id', 'stage_name']
)
deployment_success_rate = Gauge(
    'progressive_delivery_success_rate',
    'Success rate of deployments',
    ['strategy']
)
rollback_counter = Counter(
    'progressive_delivery_rollbacks_total',
    'Total number of rollbacks',
    ['stage', 'reason']
)

class DeploymentStrategy(str, Enum):
    BLUE_GREEN = "blue_green"
    CANARY = "canary"
    FEATURE_FLAG = "feature_flag"
    PROGRESSIVE = "progressive"
    SHADOW = "shadow"

class StageStatus(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    VALIDATING = "validating"
    COMPLETED = "completed"
    FAILED = "failed"
    ROLLED_BACK = "rolled_back"
    PAUSED = "paused"

class GateType(str, Enum):
    MANUAL = "manual"
    AUTOMATIC = "automatic"
    SCHEDULED = "scheduled"
    METRIC_BASED = "metric_based"

@dataclass
class DeploymentGate:
    """Decision gate between deployment stages"""
    type: GateType
    conditions: Dict[str, Any]
    timeout_minutes: int = 30
    
    # Metric-based gates
    metrics: List[Dict[str, Any]] = field(default_factory=list)
    threshold_config: Dict[str, float] = field(default_factory=dict)
    
    # Manual approval
    required_approvers: List[str] = field(default_factory=list)
    approvals: List[Dict[str, Any]] = field(default_factory=list)

@dataclass
class DeploymentStage:
    """Individual stage in progressive deployment"""
    name: str
    strategy: DeploymentStrategy
    config: Dict[str, Any]
    gates: List[DeploymentGate] = field(default_factory=list)
    dependencies: List[str] = field(default_factory=list)
    
    # Status tracking
    status: StageStatus = StageStatus.PENDING
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    error_message: Optional[str] = None
    
    # Rollback configuration
    rollback_on_failure: bool = True
    rollback_stages: List[str] = field(default_factory=list)

@dataclass
class ProgressiveDeployment:
    """Complete progressive deployment configuration"""
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    name: str = ""
    version: str = ""
    stages: List[DeploymentStage] = field(default_factory=list)
    
    # Global configuration
    max_duration_hours: int = 24
    parallel_stages: bool = False
    
    # Status
    status: StageStatus = StageStatus.PENDING
    current_stage: Optional[str] = None
    created_at: datetime = field(default_factory=datetime.now)
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    
    # History
    stage_history: List[Dict[str, Any]] = field(default_factory=list)
    metrics_summary: Dict[str, Any] = field(default_factory=dict)

class StageExecutor(ABC):
    """Abstract base class for stage execution"""
    
    @abstractmethod
    async def execute(self, stage: DeploymentStage, context: Dict[str, Any]) -&gt; Tuple[bool, str]:
        """Execute deployment stage"""
        pass
    
    @abstractmethod
    async def validate(self, stage: DeploymentStage, context: Dict[str, Any]) -&gt; Tuple[bool, str]:
        """Validate stage deployment"""
        pass
    
    @abstractmethod
    async def rollback(self, stage: DeploymentStage, context: Dict[str, Any]) -&gt; Tuple[bool, str]:
        """Rollback stage deployment"""
        pass

class BlueGreenExecutor(StageExecutor):
    """Executor for blue-green deployments"""
    
    def __init__(self, k8s_client, traffic_manager):
        self.k8s_client = k8s_client
        self.traffic_manager = traffic_manager
    
    async def execute(self, stage: DeploymentStage, context: Dict[str, Any]) -&gt; Tuple[bool, str]:
        """Execute blue-green deployment"""
        try:
            config = stage.config
            
            # Deploy to inactive environment
            target_env = "green" if context.get("active_env") == "blue" else "blue"
            
            logger.info(f"Deploying to {target_env} environment")
            
            # Update deployment
            success = await self.k8s_client.update_deployment(
                name=f"{config['app_name']}-{target_env}",
                image=config['image'],
                namespace=config.get('namespace', 'default')
            )
            
            if not success:
                return False, "Failed to update deployment"
            
            # Wait for deployment to be ready
            ready = await self.k8s_client.wait_for_deployment(
                name=f"{config['app_name']}-{target_env}",
                timeout_seconds=300
            )
            
            if not ready:
                return False, "Deployment not ready in time"
            
            context['target_env'] = target_env
            return True, f"Successfully deployed to {target_env}"
            
        except Exception as e:
            logger.error(f"Blue-green execution failed: {e}")
            return False, str(e)
    
    async def validate(self, stage: DeploymentStage, context: Dict[str, Any]) -&gt; Tuple[bool, str]:
        """Validate blue-green deployment"""
        try:
            target_env = context.get('target_env')
            config = stage.config
            
            # Run health checks
            health_url = f"http://{config['app_name']}-{target_env}/health"
            healthy = await self._check_health(health_url, retries=5)
            
            if not healthy:
                return False, "Health check failed"
            
            # Run smoke tests if configured
            if 'smoke_tests' in config:
                passed = await self._run_smoke_tests(config['smoke_tests'], target_env)
                if not passed:
                    return False, "Smoke tests failed"
            
            return True, "Validation successful"
            
        except Exception as e:
            logger.error(f"Validation failed: {e}")
            return False, str(e)
    
    async def rollback(self, stage: DeploymentStage, context: Dict[str, Any]) -&gt; Tuple[bool, str]:
        """Rollback blue-green deployment"""
        # For blue-green, rollback is just not switching traffic
        # The old environment is still running
        return True, "Rollback successful (traffic not switched)"
    
    async def _check_health(self, url: str, retries: int) -&gt; bool:
        """Check health endpoint"""
        import httpx
        
        for i in range(retries):
            try:
                async with httpx.AsyncClient() as client:
                    response = await client.get(url, timeout=5.0)
                    if response.status_code == 200:
                        return True
            except:
                pass
            
            await asyncio.sleep(2 ** i)  # Exponential backoff
        
        return False
    
    async def _run_smoke_tests(self, tests: List[Dict[str, Any]], environment: str) -&gt; bool:
        """Run smoke tests against environment"""
        # Implementation would run actual tests
        logger.info(f"Running {len(tests)} smoke tests against {environment}")
        await asyncio.sleep(5)  # Simulate test execution
        return True

class CanaryExecutor(StageExecutor):
    """Executor for canary deployments"""
    
    def __init__(self, canary_controller, metrics_collector):
        self.canary_controller = canary_controller
        self.metrics_collector = metrics_collector
    
    async def execute(self, stage: DeploymentStage, context: Dict[str, Any]) -&gt; Tuple[bool, str]:
        """Execute canary deployment"""
        try:
            config = stage.config
            
            # Start canary deployment
            canary_config = {
                'name': config['app_name'],
                'initial_weight': config.get('initial_weight', 5),
                'increment': config.get('increment', 10),
                'max_weight': config.get('max_weight', 100),
                'interval_seconds': config.get('interval_seconds', 300)
            }
            
            success = await self.canary_controller.start_canary(canary_config)
            
            if success:
                context['canary_id'] = canary_config['name']
                return True, "Canary deployment started"
            else:
                return False, "Failed to start canary"
                
        except Exception as e:
            logger.error(f"Canary execution failed: {e}")
            return False, str(e)
    
    async def validate(self, stage: DeploymentStage, context: Dict[str, Any]) -&gt; Tuple[bool, str]:
        """Monitor canary progress"""
        try:
            canary_id = context.get('canary_id')
            
            # Monitor canary for configured duration
            monitor_duration = stage.config.get('monitor_duration_minutes', 30)
            end_time = datetime.now() + timedelta(minutes=monitor_duration)
            
            while datetime.now() &lt; end_time:
                # Check canary status
                status = await self.canary_controller.get_status(canary_id)
                
                if status['state'] == 'failed':
                    return False, f"Canary failed: {status.get('reason')}"
                elif status['state'] == 'succeeded':
                    return True, "Canary deployment completed successfully"
                
                # Check metrics
                metrics = await self.metrics_collector.get_canary_metrics(canary_id)
                if self._check_metric_thresholds(metrics, stage.config):
                    await asyncio.sleep(30)  # Check every 30 seconds
                else:
                    return False, "Metrics exceeded thresholds"
            
            return True, "Canary monitoring completed"
            
        except Exception as e:
            logger.error(f"Canary validation failed: {e}")
            return False, str(e)
    
    async def rollback(self, stage: DeploymentStage, context: Dict[str, Any]) -&gt; Tuple[bool, str]:
        """Rollback canary deployment"""
        try:
            canary_id = context.get('canary_id')
            if canary_id:
                await self.canary_controller.rollback(canary_id)
            return True, "Canary rolled back"
        except Exception as e:
            return False, str(e)
    
    def _check_metric_thresholds(self, metrics: Dict[str, Any], config: Dict[str, Any]) -&gt; bool:
        """Check if metrics are within thresholds"""
        thresholds = config.get('thresholds', {})
        
        for metric, threshold in thresholds.items():
            if metric in metrics:
                if metrics[metric] &gt; threshold:
                    logger.warning(f"Metric {metric} exceeded threshold: {metrics[metric]} &gt; {threshold}")
                    return False
        
        return True

class FeatureFlagExecutor(StageExecutor):
    """Executor for feature flag deployments"""
    
    def __init__(self, flag_service, segment_service):
        self.flag_service = flag_service
        self.segment_service = segment_service
    
    async def execute(self, stage: DeploymentStage, context: Dict[str, Any]) -&gt; Tuple[bool, str]:
        """Execute feature flag deployment"""
        try:
            config = stage.config
            
            # Create or update feature flag
            flag_config = {
                'key': config['flag_key'],
                'name': config.get('name', config['flag_key']),
                'description': config.get('description', ''),
                'flag_type': config.get('type', 'boolean'),
                'default_value': config.get('default_value', False),
                'enabled': True,
                'rollout_enabled': config.get('rollout_enabled', True),
                'rollout_percentage': config.get('initial_percentage', 0),
                'targeting_enabled': config.get('targeting_enabled', False),
                'targeting_rules': config.get('targeting_rules', [])
            }
            
            # Check if flag exists
            existing = await self.flag_service.get_flag(config['flag_key'])
            
            if existing:
                success = await self.flag_service.update_flag(
                    config['flag_key'],
                    flag_config
                )
            else:
                success = await self.flag_service.create_flag(flag_config)
            
            if success:
                context['flag_key'] = config['flag_key']
                return True, f"Feature flag {config['flag_key']} deployed"
            else:
                return False, "Failed to deploy feature flag"
                
        except Exception as e:
            logger.error(f"Feature flag execution failed: {e}")
            return False, str(e)
    
    async def validate(self, stage: DeploymentStage, context: Dict[str, Any]) -&gt; Tuple[bool, str]:
        """Validate feature flag deployment"""
        try:
            flag_key = context.get('flag_key')
            config = stage.config
            
            # Progressive rollout
            if config.get('progressive_rollout'):
                rollout_stages = config['rollout_stages']
                
                for rollout_stage in rollout_stages:
                    percentage = rollout_stage['percentage']
                    duration_minutes = rollout_stage.get('duration_minutes', 60)
                    
                    # Update rollout percentage
                    await self.flag_service.update_flag(
                        flag_key,
                        {{'rollout_percentage': percentage}}
                    )
                    
                    logger.info(f"Updated {flag_key} rollout to {percentage}%")
                    
                    # Monitor for duration
                    end_time = datetime.now() + timedelta(minutes=duration_minutes)
                    
                    while datetime.now() &lt; end_time:
                        # Check metrics
                        metrics = await self._get_flag_metrics(flag_key)
                        
                        if not self._validate_flag_metrics(metrics, rollout_stage):
                            return False, f"Metrics validation failed at {percentage}%"
                        
                        await asyncio.sleep(60)  # Check every minute
                
                return True, "Progressive rollout completed"
            else:
                # Simple validation
                return True, "Feature flag validation completed"
                
        except Exception as e:
            logger.error(f"Feature flag validation failed: {e}")
            return False, str(e)
    
    async def rollback(self, stage: DeploymentStage, context: Dict[str, Any]) -&gt; Tuple[bool, str]:
        """Rollback feature flag deployment"""
        try:
            flag_key = context.get('flag_key')
            if flag_key:
                # Disable flag
                await self.flag_service.update_flag(
                    flag_key,
                    {{'enabled': False, 'rollout_percentage': 0}}
                )
            return True, "Feature flag disabled"
        except Exception as e:
            return False, str(e)
    
    async def _get_flag_metrics(self, flag_key: str) -&gt; Dict[str, Any]:
        """Get metrics for feature flag"""
        # Implementation would query actual metrics
        return {
            'evaluation_count': 10000,
            'true_count': 5000,
            'false_count': 5000,
            'error_rate': 0.1,
            'latency_p95': 0.150
        }
    
    def _validate_flag_metrics(self, metrics: Dict[str, Any], config: Dict[str, Any]) -&gt; bool:
        """Validate flag metrics against thresholds"""
        thresholds = config.get('thresholds', {})
        
        if 'max_error_rate' in thresholds:
            if metrics.get('error_rate', 0) &gt; thresholds['max_error_rate']:
                return False
        
        if 'max_latency_p95' in thresholds:
            if metrics.get('latency_p95', 0) &gt; thresholds['max_latency_p95']:
                return False
        
        return True

class ProgressiveDeliveryOrchestrator:
    """
    Orchestrates complex progressive delivery workflows
    """
    
    def __init__(self):
        self.executors: Dict[DeploymentStrategy, StageExecutor] = {}
        self.active_deployments: Dict[str, ProgressiveDeployment] = {}
        self.deployment_history: List[ProgressiveDeployment] = []
        
    def register_executor(self, strategy: DeploymentStrategy, executor: StageExecutor):
        """Register a stage executor"""
        self.executors[strategy] = executor
    
    async def create_deployment(self, config: Dict[str, Any]) -&gt; ProgressiveDeployment:
        """Create a new progressive deployment from configuration"""
        deployment = ProgressiveDeployment(
            name=config['name'],
            version=config['version'],
            max_duration_hours=config.get('max_duration_hours', 24),
            parallel_stages=config.get('parallel_stages', False)
        )
        
        # Parse stages
        for stage_config in config['stages']:
            stage = DeploymentStage(
                name=stage_config['name'],
                strategy=DeploymentStrategy(stage_config['strategy']),
                config=stage_config.get('config', {}),
                dependencies=stage_config.get('dependencies', []),
                rollback_on_failure=stage_config.get('rollback_on_failure', True)
            )
            
            # Parse gates
            for gate_config in stage_config.get('gates', []):
                gate = DeploymentGate(
                    type=GateType(gate_config['type']),
                    conditions=gate_config.get('conditions', {}),
                    timeout_minutes=gate_config.get('timeout_minutes', 30),
                    metrics=gate_config.get('metrics', []),
                    threshold_config=gate_config.get('thresholds', {})
                )
                stage.gates.append(gate)
            
            deployment.stages.append(stage)
        
        # Validate deployment
        validation_errors = self._validate_deployment(deployment)
        if validation_errors:
            raise ValueError(f"Invalid deployment configuration: {validation_errors}")
        
        # Store deployment
        self.active_deployments[deployment.id] = deployment
        
        logger.info(f"Created progressive deployment: {deployment.id}")
        return deployment
    
    def _validate_deployment(self, deployment: ProgressiveDeployment) -&gt; List[str]:
        """Validate deployment configuration"""
        errors = []
        
        # Check for circular dependencies
        stage_names = {stage.name for stage in deployment.stages}
        for stage in deployment.stages:
            for dep in stage.dependencies:
                if dep not in stage_names:
                    errors.append(f"Stage {stage.name} depends on unknown stage {dep}")
        
        # Check executor availability
        for stage in deployment.stages:
            if stage.strategy not in self.executors:
                errors.append(f"No executor registered for strategy {stage.strategy}")
        
        return errors
    
    async def start_deployment(self, deployment_id: str) -&gt; bool:
        """Start a progressive deployment"""
        deployment = self.active_deployments.get(deployment_id)
        if not deployment:
            raise ValueError(f"Deployment {deployment_id} not found")
        
        if deployment.status != StageStatus.PENDING:
            raise ValueError(f"Deployment {deployment_id} already started")
        
        deployment.status = StageStatus.IN_PROGRESS
        deployment.started_at = datetime.now()
        
        # Start deployment execution
        asyncio.create_task(self._execute_deployment(deployment))
        
        return True
    
    async def _execute_deployment(self, deployment: ProgressiveDeployment):
        """Execute deployment workflow"""
        context = {
            'deployment_id': deployment.id,
            'version': deployment.version,
            'start_time': deployment.started_at
        }
        
        try:
            # Execute stages
            if deployment.parallel_stages:
                await self._execute_parallel_stages(deployment, context)
            else:
                await self._execute_sequential_stages(deployment, context)
            
            # Mark deployment as completed
            deployment.status = StageStatus.COMPLETED
            deployment.completed_at = datetime.now()
            
            logger.info(f"Deployment {deployment.id} completed successfully")
            
        except Exception as e:
            logger.error(f"Deployment {deployment.id} failed: {e}")
            deployment.status = StageStatus.FAILED
            
            # Trigger rollback if configured
            await self._rollback_deployment(deployment, context, str(e))
        
        finally:
            # Move to history
            self.deployment_history.append(deployment)
            del self.active_deployments[deployment.id]
    
    async def _execute_sequential_stages(self, deployment: ProgressiveDeployment, 
                                       context: Dict[str, Any]):
        """Execute stages sequentially"""
        completed_stages = set()
        
        while len(completed_stages) &lt; len(deployment.stages):
            # Find next stage to execute
            next_stage = None
            for stage in deployment.stages:
                if stage.name not in completed_stages:
                    # Check dependencies
                    if all(dep in completed_stages for dep in stage.dependencies):
                        next_stage = stage
                        break
            
            if not next_stage:
                raise ValueError("No executable stage found - check dependencies")
            
            # Execute stage
            await self._execute_stage(deployment, next_stage, context)
            completed_stages.add(next_stage.name)
    
    async def _execute_parallel_stages(self, deployment: ProgressiveDeployment, 
                                     context: Dict[str, Any]):
        """Execute independent stages in parallel"""
        completed_stages = set()
        executing_stages = set()
        
        while len(completed_stages) &lt; len(deployment.stages):
            # Find stages that can be executed
            executable_stages = []
            for stage in deployment.stages:
                if (stage.name not in completed_stages and 
                    stage.name not in executing_stages):
                    # Check dependencies
                    if all(dep in completed_stages for dep in stage.dependencies):
                        executable_stages.append(stage)
            
            if not executable_stages and not executing_stages:
                raise ValueError("No executable stages found")
            
            # Execute stages in parallel
            if executable_stages:
                tasks = []
                for stage in executable_stages:
                    executing_stages.add(stage.name)
                    task = asyncio.create_task(
                        self._execute_stage(deployment, stage, context)
                    )
                    tasks.append((stage.name, task))
                
                # Wait for any to complete
                for stage_name, task in tasks:
                    try:
                        await task
                        completed_stages.add(stage_name)
                        executing_stages.remove(stage_name)
                    except Exception as e:
                        logger.error(f"Stage {stage_name} failed: {e}")
                        raise
            else:
                # Wait a bit before checking again
                await asyncio.sleep(5)
    
    async def _execute_stage(self, deployment: ProgressiveDeployment, 
                           stage: DeploymentStage, context: Dict[str, Any]):
        """Execute a single deployment stage"""
        logger.info(f"Executing stage: {stage.name}")
        
        stage.status = StageStatus.IN_PROGRESS
        stage.started_at = datetime.now()
        deployment.current_stage = stage.name
        
        # Record stage start
        deployment.stage_history.append({
            'stage': stage.name,
            'action': 'started',
            'timestamp': datetime.now().isoformat()
        })
        
        try:
            # Get executor
            executor = self.executors.get(stage.strategy)
            if not executor:
                raise ValueError(f"No executor for strategy {stage.strategy}")
            
            # Execute stage
            with deployment_stage_duration.labels(
                deployment_id=deployment.id,
                stage_name=stage.name
            ).time():
                success, message = await executor.execute(stage, context)
            
            if not success:
                raise Exception(f"Stage execution failed: {message}")
            
            # Validate stage
            stage.status = StageStatus.VALIDATING
            success, message = await executor.validate(stage, context)
            
            if not success:
                raise Exception(f"Stage validation failed: {message}")
            
            # Process gates
            for gate in stage.gates:
                gate_passed = await self._process_gate(gate, stage, context)
                if not gate_passed:
                    raise Exception(f"Gate {gate.type} failed")
            
            # Mark stage as completed
            stage.status = StageStatus.COMPLETED
            stage.completed_at = datetime.now()
            
            deployment.stage_history.append({
                'stage': stage.name,
                'action': 'completed',
                'timestamp': datetime.now().isoformat(),
                'duration_seconds': (stage.completed_at - stage.started_at).total_seconds()
            })
            
            logger.info(f"Stage {stage.name} completed successfully")
            
        except Exception as e:
            stage.status = StageStatus.FAILED
            stage.error_message = str(e)
            
            deployment.stage_history.append({
                'stage': stage.name,
                'action': 'failed',
                'timestamp': datetime.now().isoformat(),
                'error': str(e)
            })
            
            raise
    
    async def _process_gate(self, gate: DeploymentGate, stage: DeploymentStage,
                          context: Dict[str, Any]) -&gt; bool:
        """Process deployment gate"""
        logger.info(f"Processing {gate.type} gate for stage {stage.name}")
        
        if gate.type == GateType.MANUAL:
            return await self._process_manual_gate(gate, context)
        elif gate.type == GateType.AUTOMATIC:
            return True  # Auto-approve
        elif gate.type == GateType.SCHEDULED:
            return await self._process_scheduled_gate(gate, context)
        elif gate.type == GateType.METRIC_BASED:
            return await self._process_metric_gate(gate, context)
        
        return False
    
    async def _process_manual_gate(self, gate: DeploymentGate, 
                                  context: Dict[str, Any]) -&gt; bool:
        """Process manual approval gate"""
        # In production, this would integrate with approval system
        # For demo, auto-approve after delay
        logger.info("Waiting for manual approval...")
        await asyncio.sleep(5)
        return True
    
    async def _process_scheduled_gate(self, gate: DeploymentGate, 
                                    context: Dict[str, Any]) -&gt; bool:
        """Process scheduled gate"""
        if 'schedule_time' in gate.conditions:
            target_time = datetime.fromisoformat(gate.conditions['schedule_time'])
            wait_seconds = (target_time - datetime.now()).total_seconds()
            
            if wait_seconds &gt; 0:
                logger.info(f"Waiting until {target_time} to proceed")
                await asyncio.sleep(wait_seconds)
        
        return True
    
    async def _process_metric_gate(self, gate: DeploymentGate, 
                                 context: Dict[str, Any]) -&gt; bool:
        """Process metric-based gate"""
        # Monitor metrics for gate duration
        end_time = datetime.now() + timedelta(minutes=gate.timeout_minutes)
        
        while datetime.now() &lt; end_time:
            # Collect metrics
            metrics = await self._collect_gate_metrics(gate.metrics, context)
            
            # Check thresholds
            passed = True
            for metric_name, threshold in gate.threshold_config.items():
                if metric_name in metrics:
                    if metrics[metric_name] &gt; threshold:
                        logger.warning(f"Metric {metric_name} exceeds threshold: "
                                     f"{metrics[metric_name]} &gt; {threshold}")
                        passed = False
            
            if passed:
                logger.info("Metric gate passed")
                return True
            
            # Wait before next check
            await asyncio.sleep(60)
        
        logger.error("Metric gate timed out")
        return False
    
    async def _collect_gate_metrics(self, metric_configs: List[Dict[str, Any]], 
                                  context: Dict[str, Any]) -&gt; Dict[str, float]:
        """Collect metrics for gate evaluation"""
        # In production, query actual metrics
        # For demo, return sample metrics
        return {
            'error_rate': 0.5,
            'latency_p95': 0.200,
            'cpu_usage': 45.0,
            'memory_usage': 60.0
        }
    
    async def _rollback_deployment(self, deployment: ProgressiveDeployment,
                                 context: Dict[str, Any], reason: str):
        """Rollback failed deployment"""
        logger.warning(f"Rolling back deployment {deployment.id}: {reason}")
        
        rollback_counter.labels(
            stage=deployment.current_stage or "unknown",
            reason=reason[:50]  # Truncate reason for label
        ).inc()
        
        # Find stages to rollback
        stages_to_rollback = []
        for stage in reversed(deployment.stages):
            if stage.status in [StageStatus.COMPLETED, StageStatus.IN_PROGRESS]:
                stages_to_rollback.append(stage)
                if not stage.rollback_on_failure:
                    break
        
        # Execute rollbacks
        for stage in stages_to_rollback:
            try:
                executor = self.executors.get(stage.strategy)
                if executor:
                    success, message = await executor.rollback(stage, context)
                    
                    deployment.stage_history.append({
                        'stage': stage.name,
                        'action': 'rolled_back',
                        'timestamp': datetime.now().isoformat(),
                        'success': success,
                        'message': message
                    })
                    
                    if success:
                        stage.status = StageStatus.ROLLED_BACK
                    else:
                        logger.error(f"Failed to rollback stage {stage.name}: {message}")
            except Exception as e:
                logger.error(f"Error during rollback of stage {stage.name}: {e}")
    
    async def pause_deployment(self, deployment_id: str) -&gt; bool:
        """Pause an active deployment"""
        deployment = self.active_deployments.get(deployment_id)
        if deployment and deployment.status == StageStatus.IN_PROGRESS:
            deployment.status = StageStatus.PAUSED
            return True
        return False
    
    async def resume_deployment(self, deployment_id: str) -&gt; bool:
        """Resume a paused deployment"""
        deployment = self.active_deployments.get(deployment_id)
        if deployment and deployment.status == StageStatus.PAUSED:
            deployment.status = StageStatus.IN_PROGRESS
            # Resume execution
            asyncio.create_task(self._execute_deployment(deployment))
            return True
        return False
    
    def get_deployment_status(self, deployment_id: str) -&gt; Optional[Dict[str, Any]]:
        """Get current deployment status"""
        deployment = self.active_deployments.get(deployment_id)
        if not deployment:
            # Check history
            for hist_deployment in self.deployment_history:
                if hist_deployment.id == deployment_id:
                    deployment = hist_deployment
                    break
        
        if deployment:
            return {
                'id': deployment.id,
                'name': deployment.name,
                'version': deployment.version,
                'status': deployment.status,
                'current_stage': deployment.current_stage,
                'stages': [
                    {
                        'name': stage.name,
                        'status': stage.status,
                        'started_at': stage.started_at.isoformat() if stage.started_at else None,
                        'completed_at': stage.completed_at.isoformat() if stage.completed_at else None,
                        'error': stage.error_message
                    }
                    for stage in deployment.stages
                ],
                'created_at': deployment.created_at.isoformat(),
                'started_at': deployment.started_at.isoformat() if deployment.started_at else None,
                'completed_at': deployment.completed_at.isoformat() if deployment.completed_at else None,
                'stage_history': deployment.stage_history
            }
        
        return None

# Example deployment configuration
EXAMPLE_PROGRESSIVE_DEPLOYMENT = {
    "name": "Multi-Stage Feature Release",
    "version": "2.0.0",
    "max_duration_hours": 48,
    "parallel_stages": False,
    "stages": [
        {
            "name": "deploy_backend",
            "strategy": "blue_green",
            "config": {
                "app_name": "api-service",
                "image": "api:2.0.0",
                "namespace": "production",
                "smoke_tests": [
                    {{"endpoint": "/health", "expected_status": 200}},
                    {{"endpoint": "/api/v2/status", "expected_status": 200}}
                ]
            },
            "gates": [
                {
                    "type": "metric_based",
                    "metrics": ["error_rate", "latency_p95"],
                    "thresholds": {
                        "error_rate": 1.0,
                        "latency_p95": 0.5
                    },
                    "timeout_minutes": 15
                }
            ]
        },
        {
            "name": "enable_feature_flag",
            "strategy": "feature_flag",
            "dependencies": ["deploy_backend"],
            "config": {
                "flag_key": "new_checkout_flow",
                "name": "New Checkout Flow",
                "description": "Redesigned checkout experience",
                "progressive_rollout": True,
                "rollout_stages": [
                    {
                        "percentage": 5,
                        "duration_minutes": 60,
                        "thresholds": {
                            "max_error_rate": 2.0,
                            "max_latency_p95": 0.6
                        }
                    },
                    {
                        "percentage": 25,
                        "duration_minutes": 120,
                        "thresholds": {
                            "max_error_rate": 1.5,
                            "max_latency_p95": 0.5
                        }
                    },
                    {
                        "percentage": 50,
                        "duration_minutes": 240,
                        "thresholds": {
                            "max_error_rate": 1.0,
                            "max_latency_p95": 0.5
                        }
                    },
                    {
                        "percentage": 100,
                        "duration_minutes": 480,
                        "thresholds": {
                            "max_error_rate": 1.0,
                            "max_latency_p95": 0.5
                        }
                    }
                ],
                "targeting_enabled": True,
                "targeting_rules": [
                    {
                        "attribute": "user_segment",
                        "operator": "in",
                        "value": ["beta_testers", "employees"],
                        "return_value": True
                    }
                ]
            },
            "gates": [
                {
                    "type": "manual",
                    "required_approvers": ["product_manager", "engineering_lead"]
                }
            ]
        },
        {
            "name": "frontend_canary",
            "strategy": "canary",
            "dependencies": ["enable_feature_flag"],
            "config": {
                "app_name": "web-frontend",
                "initial_weight": 5,
                "increment": 15,
                "max_weight": 100,
                "interval_seconds": 600,
                "monitor_duration_minutes": 60,
                "thresholds": {
                    "error_rate": 1.0,
                    "bounce_rate": 30.0,
                    "conversion_rate_drop": 5.0
                }
            },
            "rollback_on_failure": True
        }
    ]
}
```

## 🔐 Partee 4: Kill Switches and Emergency Controls

Continuar to [Partee 3](./exercise3-part3) for implementing kill switches, telemetry, and testing the complete system...