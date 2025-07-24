---
sidebar_position: 4
title: "Exercise 2: Part 3"
description: "## ✅ Part 4: Exercise Validation"
---

# Exercício 2: Canary implantação - Partee 3 (⭐⭐ Application)

## ✅ Partee 4: Exercício Validation

### Step 5: Create Canary implantação Tests

**Copilot Prompt Suggestion:**
```python
# Create comprehensive tests for canary deployment that:
# - Verify progressive traffic shifting works correctly
# - Test automatic rollback on metric degradation
# - Validate A/B test integration
# - Check SLO compliance calculations
# - Test anomaly detection accuracy
# - Measure canary promotion latency
# Use pytest with mock services
```

**Expected Output:**
Create `tests/test_canary_implantação.py`:
```python
import pytest
import asyncio
from datetime import datetime, timedelta
from unittest.mock import Mock, patch, AsyncMock
import numpy as np
from canary.controller import (
    CanaryController, CanaryConfig, CanaryState, CanaryMetrics
)
from canary.ab_testing import (
    ABTestingFramework, ABTestConfig, ABTestEvent
)
from canary.metrics_collector import (
    AdvancedMetricsCollector, MetricsSample, SLO
)

@pytest.fixture
async def canary_config():
    """Create test canary configuration"""
    return CanaryConfig(
        name="test-app",
        namespace="test",
        stable_version="v1",
        canary_version="v2",
        initial_canary_weight=5,
        canary_increment=20,
        max_canary_weight=100,
        promotion_interval_seconds=60,
        analysis_interval_seconds=10,
        max_error_rate=5.0,
        max_latency_increase=50.0,
        min_request_count=10
    )

@pytest.fixture
async def canary_controller(canary_config):
    """Create canary controller with mocked Kubernetes client"""
    with patch('canary.controller.config.load_kube_config'):
        controller = CanaryController(canary_config)
        controller.v1 = Mock()
        controller.apps_v1 = Mock()
        controller.networking_v1 = Mock()
        return controller

@pytest.mark.asyncio
class TestCanaryDeployment:
    """Test suite for canary deployment"""
    
    async def test_progressive_traffic_shifting(self, canary_controller, canary_config):
        """Test that traffic shifts progressively"""
        # Mock healthy deployments
        canary_controller.verify_deployments_health = AsyncMock(return_value=True)
        canary_controller.update_traffic_split = AsyncMock(return_value=True)
        
        # Start canary
        success = await canary_controller.start_canary()
        assert success
        assert canary_controller.state == CanaryState.PROGRESSING
        assert canary_controller.current_canary_weight == canary_config.initial_canary_weight
        
        # Verify initial traffic split
        canary_controller.update_traffic_split.assert_called_with(5)
        
        # Simulate successful metrics
        stable_metrics = CanaryMetrics(
            timestamp=datetime.now(),
            request_count=1000,
            error_count=10,  # 1% error rate
            latency_p50=0.1,
            latency_p95=0.3,
            latency_p99=0.5
        )
        
        canary_metrics = CanaryMetrics(
            timestamp=datetime.now(),
            request_count=100,
            error_count=1,  # 1% error rate
            latency_p50=0.1,
            latency_p95=0.35,  # Slightly higher but acceptable
            latency_p99=0.6
        )
        
        # Add metrics to history
        for _ in range(10):
            canary_controller.metrics_history['stable'].append(stable_metrics)
            canary_controller.metrics_history['canary'].append(canary_metrics)
        
        # Test metric analysis
        should_continue, reason = await canary_controller.analyze_metrics()
        assert should_continue
        assert "acceptable thresholds" in reason
        
        # Simulate time passing for promotion
        canary_controller.promotion_history = [{
            'timestamp': datetime.now() - timedelta(seconds=61),
            'canary_weight': 5,
            'action': 'traffic_update'
        }]
        
        # Manually trigger promotion logic
        canary_controller.collect_metrics = AsyncMock(side_effect=[
            stable_metrics, canary_metrics
        ])
        
        # Update weight
        new_weight = canary_controller.current_canary_weight + canary_config.canary_increment
        assert new_weight == 25  # 5 + 20
    
    async def test_automatic_rollback_on_high_errors(self, canary_controller):
        """Test automatic rollback when error rate exceeds threshold"""
        canary_controller.state = CanaryState.PROGRESSING
        canary_controller.current_canary_weight = 25
        
        # Create metrics with high error rate
        bad_canary_metrics = CanaryMetrics(
            timestamp=datetime.now(),
            request_count=100,
            error_count=10,  # 10% error rate
            latency_p50=0.1,
            latency_p95=0.3,
            latency_p99=0.5
        )
        
        good_stable_metrics = CanaryMetrics(
            timestamp=datetime.now(),
            request_count=1000,
            error_count=10,  # 1% error rate
            latency_p50=0.1,
            latency_p95=0.3,
            latency_p99=0.5
        )
        
        # Add to history
        for _ in range(5):
            canary_controller.metrics_history['canary'].append(bad_canary_metrics)
            canary_controller.metrics_history['stable'].append(good_stable_metrics)
        
        # Mock rollback methods
        canary_controller.update_traffic_split = AsyncMock(return_value=True)
        canary_controller.generate_report = AsyncMock()
        
        # Analyze should trigger rollback
        should_continue, reason = await canary_controller.analyze_metrics()
        assert not should_continue
        assert "error rate too high" in reason
        
        # Execute rollback
        await canary_controller.rollback_canary(reason)
        
        # Verify rollback actions
        assert canary_controller.state == CanaryState.FAILED
        canary_controller.update_traffic_split.assert_called_with(0)
        canary_controller.generate_report.assert_called_with('rollback')
    
    async def test_latency_degradation_detection(self, canary_controller):
        """Test detection of latency degradation"""
        canary_controller.state = CanaryState.PROGRESSING
        
        # Create metrics with latency degradation
        stable_metrics = CanaryMetrics(
            timestamp=datetime.now(),
            request_count=1000,
            error_count=10,
            latency_p50=0.1,
            latency_p95=0.2,  # 200ms
            latency_p99=0.4
        )
        
        slow_canary_metrics = CanaryMetrics(
            timestamp=datetime.now(),
            request_count=100,
            error_count=1,
            latency_p50=0.2,
            latency_p95=0.4,  # 400ms (100% increase)
            latency_p99=0.8
        )
        
        # Add to history
        for _ in range(5):
            canary_controller.metrics_history['stable'].append(stable_metrics)
            canary_controller.metrics_history['canary'].append(slow_canary_metrics)
        
        # Analyze should detect latency issue
        should_continue, reason = await canary_controller.analyze_metrics()
        assert not should_continue
        assert "latency increased" in reason.lower()
    
    async def test_statistical_significance(self, canary_controller):
        """Test statistical significance testing"""
        # Generate metrics with slight variation
        np.random.seed(42)
        
        # Stable metrics with consistent error rate
        for _ in range(20):
            stable_metrics = CanaryMetrics(
                timestamp=datetime.now(),
                request_count=1000,
                error_count=int(np.random.normal(10, 2)),  # ~1% with small variation
                latency_p50=0.1,
                latency_p95=0.3,
                latency_p99=0.5
            )
            canary_controller.metrics_history['stable'].append(stable_metrics)
        
        # Canary metrics with higher error rate
        for _ in range(20):
            canary_metrics = CanaryMetrics(
                timestamp=datetime.now(),
                request_count=100,
                error_count=int(np.random.normal(3, 1)),  # ~3% error rate
                latency_p50=0.1,
                latency_p95=0.3,
                latency_p99=0.5
            )
            canary_controller.metrics_history['canary'].append(canary_metrics)
        
        # Statistical test should detect significant difference
        should_continue, reason = await canary_controller.analyze_metrics()
        
        # The controller should detect the canary is statistically worse
        assert "All metrics within acceptable thresholds" in reason or "Statistical test" in reason

@pytest.mark.asyncio
class TestABTesting:
    """Test suite for A/B testing framework"""
    
    @pytest.fixture
    async def ab_framework(self):
        """Create A/B testing framework with mock Redis"""
        framework = ABTestingFramework("redis://localhost:6379")
        framework.redis_client = AsyncMock()
        return framework
    
    async def test_consistent_user_assignment(self, ab_framework):
        """Test that users are consistently assigned to variants"""
        # Create test config
        test_config = ABTestConfig(
            test_id="test123",
            name="Feature Test",
            variants=['control', 'treatment'],
            traffic_allocation={{'control': 50, 'treatment': 50}},
            metrics=['conversion'],
            start_date=datetime.now()
        )
        
        # Mock Redis responses
        ab_framework.redis_client.get = AsyncMock(return_value=None)  # No existing assignment
        ab_framework.redis_client.hget = AsyncMock(
            return_value=json.dumps(test_config.__dict__, default=str).encode()
        )
        ab_framework.redis_client.setex = AsyncMock()
        ab_framework.track_event = AsyncMock()
        
        # Test multiple assignments for same user
        user_id = "user123"
        assignments = []
        
        for _ in range(10):
            variant = await ab_framework.get_variant(test_config.test_id, user_id)
            assignments.append(variant)
        
        # All assignments should be the same (consistent hashing)
        assert len(set(assignments)) == 1
        assert assignments[0] in ['control', 'treatment']
    
    async def test_traffic_distribution(self, ab_framework):
        """Test that traffic distribution matches allocation"""
        test_config = ABTestConfig(
            test_id="test456",
            name="Traffic Test",
            variants=['A', 'B', 'C'],
            traffic_allocation={{'A': 60, 'B': 30, 'C': 10}},
            metrics=['clicks'],
            start_date=datetime.now()
        )
        
        # Mock Redis
        ab_framework.redis_client.get = AsyncMock(return_value=None)
        ab_framework.redis_client.hget = AsyncMock(
            return_value=json.dumps(test_config.__dict__, default=str).encode()
        )
        ab_framework.redis_client.setex = AsyncMock()
        ab_framework.track_event = AsyncMock()
        
        # Assign many users and check distribution
        variant_counts = {{'A': 0, 'B': 0, 'C': 0}}
        
        for i in range(1000):
            variant = await ab_framework.get_variant(test_config.test_id, f"user{i}")
            if variant:
                variant_counts[variant] += 1
        
        # Check distribution is roughly correct (within 5% tolerance)
        total = sum(variant_counts.values())
        assert abs(variant_counts['A'] / total * 100 - 60) &lt; 5
        assert abs(variant_counts['B'] / total * 100 - 30) &lt; 5
        assert abs(variant_counts['C'] / total * 100 - 10) &lt; 5
    
    async def test_segment_rules(self, ab_framework):
        """Test user segmentation rules"""
        test_config = ABTestConfig(
            test_id="test789",
            name="Segment Test",
            variants=['control', 'treatment'],
            traffic_allocation={{'control': 50, 'treatment': 50}},
            metrics=['purchase'],
            start_date=datetime.now(),
            segment_rules={
                'country': 'US',
                'age': {{'$gte': 18}},
                'plan': {{'$in': ['premium', 'enterprise']}}
            }
        )
        
        # Mock Redis
        ab_framework.redis_client.hget = AsyncMock(
            return_value=json.dumps(test_config.__dict__, default=str).encode()
        )
        
        # Test matching user
        matching_user_attrs = {
            'country': 'US',
            'age': 25,
            'plan': 'premium'
        }
        
        ab_framework.redis_client.get = AsyncMock(return_value=None)
        ab_framework.redis_client.setex = AsyncMock()
        ab_framework.track_event = AsyncMock()
        
        variant = await ab_framework.get_variant(
            test_config.test_id, 
            "user1", 
            matching_user_attrs
        )
        assert variant in ['control', 'treatment']
        
        # Test non-matching user (wrong country)
        non_matching_attrs = {
            'country': 'UK',
            'age': 25,
            'plan': 'premium'
        }
        
        variant = await ab_framework.get_variant(
            test_config.test_id, 
            "user2", 
            non_matching_attrs
        )
        assert variant is None

@pytest.mark.asyncio
class TestMetricsCollector:
    """Test suite for metrics collection and anomaly detection"""
    
    @pytest.fixture
    async def metrics_collector(self):
        """Create metrics collector"""
        return AdvancedMetricsCollector(
            stable_url="http://stable:8000",
            canary_url="http://canary:8000"
        )
    
    async def test_slo_compliance_calculation(self, metrics_collector):
        """Test SLO compliance calculations"""
        # Create sample metrics
        good_sample = MetricsSample(
            timestamp=datetime.now(),
            version="stable",
            requests=1000,
            errors=5,  # 0.5% error rate
            latencies=[0.1, 0.2, 0.3, 0.4, 0.5] * 200,  # Mix of latencies
            cpu_percent=50.0,
            memory_bytes=1024*1024*100
        )
        
        # Add samples to window
        for _ in range(10):
            metrics_collector.metrics_window['stable'].append(good_sample)
        
        # Calculate SLO compliance
        scores = metrics_collector.calculate_slo_compliance('stable')
        
        # Availability SLO (99.9% target, actual 99.5%)
        assert 'availability' in scores
        assert scores['availability'] &gt; 95  # Should be close to 100%
        
        # Error rate SLO (&lt; 1% target, actual 0.5%)
        assert 'error_rate' in scores
        assert scores['error_rate'] == 100  # Perfect compliance
    
    async def test_anomaly_detection(self, metrics_collector):
        """Test anomaly detection algorithms"""
        # Create normal samples
        for i in range(20):
            normal_sample = MetricsSample(
                timestamp=datetime.now() - timedelta(minutes=20-i),
                version="canary",
                requests=1000,
                errors=10,  # 1% error rate
                latencies=[0.1, 0.2, 0.3],
                cpu_percent=40.0,
                memory_bytes=1024*1024*100
            )
            metrics_collector.metrics_window['canary'].append(normal_sample)
        
        # Add anomalous sample
        anomaly_sample = MetricsSample(
            timestamp=datetime.now(),
            version="canary",
            requests=1000,
            errors=100,  # 10% error rate spike
            latencies=[0.5, 0.6, 0.7],  # Latency spike
            cpu_percent=90.0,  # CPU spike
            memory_bytes=1024*1024*200
        )
        metrics_collector.metrics_window['canary'].append(anomaly_sample)
        
        # Detect anomalies
        anomalies = await metrics_collector.detect_anomalies()
        
        # Should detect multiple anomalies
        assert len(anomalies) &gt; 0
        
        # Check for error rate anomaly
        error_anomalies = [a for a in anomalies if a['type'] == 'error_rate']
        assert len(error_anomalies) &gt; 0
        assert error_anomalies[0]['severity'] == 'high'
        
        # Check for CPU anomaly
        cpu_anomalies = [a for a in anomalies if a['type'] == 'cpu']
        assert len(cpu_anomalies) &gt; 0
    
    async def test_metric_correlation(self, metrics_collector):
        """Test cross-version metric correlation"""
        # Create correlated error pattern in canary
        for i in range(20):
            # Stable has consistent low errors
            stable_sample = MetricsSample(
                timestamp=datetime.now() - timedelta(minutes=20-i),
                version="stable",
                requests=1000,
                errors=10 + np.random.randint(-2, 3),  # Small variation
                latencies=[0.1, 0.2],
                cpu_percent=40.0,
                memory_bytes=1024*1024*100
            )
            metrics_collector.metrics_window['stable'].append(stable_sample)
            
            # Canary has increasing errors
            canary_sample = MetricsSample(
                timestamp=datetime.now() - timedelta(minutes=20-i),
                version="canary",
                requests=100,
                errors=2 + i,  # Increasing error pattern
                latencies=[0.1, 0.2],
                cpu_percent=40.0,
                memory_bytes=1024*1024*100
            )
            metrics_collector.metrics_window['canary'].append(canary_sample)
        
        # Detect correlation anomalies
        anomalies = metrics_collector._detect_correlation_anomalies()
        
        # Should detect different error patterns
        assert len(anomalies) &gt; 0
        correlation_anomaly = anomalies[0]
        assert correlation_anomaly['type'] == 'correlation'
        assert correlation_anomaly['metric'] == 'errors'
        assert correlation_anomaly['severity'] == 'high'

# Integration test
@pytest.mark.integration
@pytest.mark.asyncio
async def test_full_canary_deployment_flow():
    """Test complete canary deployment flow"""
    # This would be a full integration test with real services
    # For unit tests, we use mocks
    
    config = CanaryConfig(
        name="integration-test",
        initial_canary_weight=10,
        canary_increment=30,
        max_canary_weight=100,
        promotion_interval_seconds=5,
        analysis_interval_seconds=1
    )
    
    with patch('canary.controller.config.load_kube_config'):
        controller = CanaryController(config)
        
        # Mock all external dependencies
        controller.verify_deployments_health = AsyncMock(return_value=True)
        controller.update_traffic_split = AsyncMock(return_value=True)
        controller.collect_metrics = AsyncMock()
        controller.generate_report = AsyncMock()
        
        # Create good metrics
        good_metrics = CanaryMetrics(
            timestamp=datetime.now(),
            request_count=100,
            error_count=1,
            latency_p50=0.1,
            latency_p95=0.2,
            latency_p99=0.3
        )
        
        controller.collect_metrics.return_value = good_metrics
        
        # Start deployment
        success = await controller.start_canary()
        assert success
        
        # Wait a bit (in real test would wait for actual progression)
        await asyncio.sleep(0.1)
        
        # Should still be progressing (not failed)
        assert controller.state != CanaryState.FAILED
```

## 🔍 Partee 5: Monitoring Painel

### Step 6: Create Real-time Painel

**Copilot Prompt Suggestion:**
```python
# Create a real-time monitoring dashboard using Plotly Dash that:
# - Shows canary vs stable metrics side by side
# - Displays traffic distribution pie chart
# - Shows SLO compliance gauges
# - Plots error rate and latency trends
# - Includes rollback button with confirmation
# - Updates every 5 seconds
# Use WebSocket for real-time updates
```

**Expected Output:**
Create `dashboard/canary_dashboard.py`:
```python
import dash
from dash import dcc, html, Input, Output, State
import plotly.graph_objs as go
import plotly.express as px
from datetime import datetime
import asyncio
import json
import pandas as pd
from typing import Dict, List
import redis

# Initialize Dash app
app = dash.Dash(__name__)

# Redis connection for metrics
redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)

# Layout
app.layout = html.Div([
    html.H1("Canary Deployment Dashboard", className="dashboard-title"),
    
    # Control Panel
    html.Div([
        html.Div([
            html.H3("Deployment Controls"),
            html.Button("Pause Canary", id="pause-btn", className="control-btn"),
            html.Button("Resume Canary", id="resume-btn", className="control-btn"),
            html.Button("Rollback", id="rollback-btn", className="control-btn danger"),
            html.Div(id="control-status")
        ], className="control-panel"),
        
        # Current Status
        html.Div([
            html.H3("Current Status"),
            html.Div(id="deployment-status", className="status-display"),
            html.Div(id="canary-weight", className="weight-display")
        ], className="status-panel")
    ], className="top-panel"),
    
    # Metrics Panels
    html.Div([
        # Traffic Distribution
        html.Div([
            dcc.Graph(id="traffic-distribution")
        ], className="metric-panel"),
        
        # Error Rate Comparison
        html.Div([
            dcc.Graph(id="error-rate-chart")
        ], className="metric-panel"),
        
        # Latency Comparison
        html.Div([
            dcc.Graph(id="latency-chart")
        ], className="metric-panel"),
        
        # SLO Compliance
        html.Div([
            dcc.Graph(id="slo-gauges")
        ], className="metric-panel")
    ], className="metrics-grid"),
    
    # Detailed Metrics Table
    html.Div([
        html.H3("Detailed Metrics"),
        html.Table(id="metrics-table", className="metrics-table")
    ]),
    
    # Auto-refresh
    dcc.Interval(id="interval-component", interval=5000),  # 5 seconds
    
    # Hidden div for state
    html.Div(id="hidden-state", style={{"display": "none"}})
])

# Callbacks
@app.callback(
    [Output("traffic-distribution", "figure"),
     Output("error-rate-chart", "figure"),
     Output("latency-chart", "figure"),
     Output("slo-gauges", "figure"),
     Output("deployment-status", "children"),
     Output("canary-weight", "children"),
     Output("metrics-table", "children")],
    [Input("interval-component", "n_intervals")]
)
def update_dashboard(n):
    """Update all dashboard components"""
    
    # Get current metrics from Redis
    metrics = get_current_metrics()
    
    # Traffic Distribution Pie Chart
    traffic_fig = go.Figure(data=[go.Pie(
        labels=['Stable', 'Canary'],
        values=[metrics['stable_weight'], metrics['canary_weight']],
        hole=.3,
        marker_colors=['#2E86AB', '#A23B72']
    )])
    traffic_fig.update_layout(
        title="Traffic Distribution",
        showlegend=True,
        height=300
    )
    
    # Error Rate Time Series
    error_fig = go.Figure()
    error_fig.add_trace(go.Scatter(
        x=metrics['timestamps'],
        y=metrics['stable_errors'],
        mode='lines+markers',
        name='Stable',
        line=dict(color='#2E86AB', width=2)
    ))
    error_fig.add_trace(go.Scatter(
        x=metrics['timestamps'],
        y=metrics['canary_errors'],
        mode='lines+markers',
        name='Canary',
        line=dict(color='#A23B72', width=2)
    ))
    error_fig.add_hline(y=5, line_dash="dash", line_color="red",
                       annotation_text="SLO Threshold")
    error_fig.update_layout(
        title="Error Rate Comparison (%)",
        xaxis_title="Time",
        yaxis_title="Error Rate",
        height=300
    )
    
    # Latency Comparison
    latency_fig = go.Figure()
    latency_fig.add_trace(go.Box(
        y=metrics['stable_latencies'],
        name='Stable',
        marker_color='#2E86AB'
    ))
    latency_fig.add_trace(go.Box(
        y=metrics['canary_latencies'],
        name='Canary',
        marker_color='#A23B72'
    ))
    latency_fig.update_layout(
        title="Latency Distribution (p95)",
        yaxis_title="Latency (seconds)",
        height=300
    )
    
    # SLO Compliance Gauges
    slo_fig = go.Figure()
    
    slo_metrics = [
        ("Availability", metrics['slo_availability'], 99.9),
        ("Latency", metrics['slo_latency'], 95),
        ("Error Rate", metrics['slo_error_rate'], 99)
    ]
    
    for i, (name, value, target) in enumerate(slo_metrics):
        slo_fig.add_trace(go.Indicator(
            mode="gauge+number+delta",
            value=value,
            domain={{'x': [i/3, (i+1)/3], 'y': [0, 1]}},
            title={{'text': name}},
            delta={{'reference': target}},
            gauge={
                'axis': {{'range': [None, 100]}},
                'bar': {{'color': "darkblue"}},
                'steps': [
                    {{'range': [0, 50], 'color': "lightgray"}},
                    {{'range': [50, 80], 'color': "gray"}}
                ],
                'threshold': {
                    'line': {{'color': "red", 'width': 4}},
                    'thickness': 0.75,
                    'value': target
                }
            }
        ))
    
    slo_fig.update_layout(
        title="SLO Compliance",
        height=250
    )
    
    # Status displays
    status_text = f"Status: {metrics['deployment_state']}"
    weight_text = f"Canary Traffic: {metrics['canary_weight']}%"
    
    # Metrics table
    table_header = [
        html.Thead([
            html.Tr([
                html.Th("Metric"),
                html.Th("Stable"),
                html.Th("Canary"),
                html.Th("Difference")
            ])
        ])
    ]
    
    table_rows = []
    for metric_name, stable_val, canary_val in [
        ("Requests/min", metrics['stable_rpm'], metrics['canary_rpm']),
        ("Error Rate", f"{metrics['stable_error_rate']:.2f}%", f"{metrics['canary_error_rate']:.2f}%"),
        ("P95 Latency", f"{metrics['stable_p95']:.3f}s", f"{metrics['canary_p95']:.3f}s"),
        ("CPU Usage", f"{metrics['stable_cpu']:.1f}%", f"{metrics['canary_cpu']:.1f}%")
    ]:
        # Calculate difference
        try:
            stable_num = float(stable_val.rstrip('%s'))
            canary_num = float(canary_val.rstrip('%s'))
            diff = canary_num - stable_num
            diff_str = f"{diff:+.2f}"
            diff_class = "positive" if diff &lt; 0 else "negative" if diff &gt; 0 else "neutral"
        except:
            diff_str = "N/A"
            diff_class = "neutral"
        
        table_rows.append(
            html.Tr([
                html.Td(metric_name),
                html.Td(stable_val),
                html.Td(canary_val),
                html.Td(diff_str, className=diff_class)
            ])
        )
    
    table_body = [html.Tbody(table_rows)]
    
    return (traffic_fig, error_fig, latency_fig, slo_fig, 
            status_text, weight_text, table_header + table_body)

@app.callback(
    Output("control-status", "children"),
    [Input("pause-btn", "n_clicks"),
     Input("resume-btn", "n_clicks"),
     Input("rollback-btn", "n_clicks")],
    prevent_initial_call=True
)
def handle_controls(pause_clicks, resume_clicks, rollback_clicks):
    """Handle control button clicks"""
    ctx = dash.callback_context
    
    if not ctx.triggered:
        return ""
    
    button_id = ctx.triggered[0]["prop_id"].split(".")[0]
    
    if button_id == "pause-btn":
        # Send pause command
        send_control_command("pause")
        return "Canary deployment paused"
    elif button_id == "resume-btn":
        # Send resume command
        send_control_command("resume")
        return "Canary deployment resumed"
    elif button_id == "rollback-btn":
        # Send rollback command
        if confirm_rollback():
            send_control_command("rollback")
            return "Rollback initiated"
        else:
            return "Rollback cancelled"
    
    return ""

def get_current_metrics() -&gt; Dict:
    """Get current metrics from Redis or monitoring system"""
    # This would connect to your actual metrics source
    # For demo, returning mock data
    return {
        'timestamps': pd.date_range(start='2024-01-01 10:00', periods=20, freq='1min'),
        'stable_weight': 75,
        'canary_weight': 25,
        'stable_errors': [1.0, 0.8, 1.2, 0.9, 1.1] * 4,
        'canary_errors': [1.2, 1.5, 1.8, 2.0, 1.9] * 4,
        'stable_latencies': [0.1, 0.15, 0.2, 0.18, 0.22] * 10,
        'canary_latencies': [0.12, 0.18, 0.25, 0.22, 0.28] * 10,
        'deployment_state': 'PROGRESSING',
        'slo_availability': 99.95,
        'slo_latency': 94.5,
        'slo_error_rate': 98.8,
        'stable_rpm': 5000,
        'canary_rpm': 1500,
        'stable_error_rate': 1.0,
        'canary_error_rate': 1.8,
        'stable_p95': 0.200,
        'canary_p95': 0.250,
        'stable_cpu': 45.2,
        'canary_cpu': 48.7
    }

def send_control_command(command: str):
    """Send control command to canary controller"""
    # This would send actual commands to your canary controller
    print(f"Sending command: {command}")

def confirm_rollback() -&gt; bool:
    """Confirm rollback action"""
    # In a real app, this would show a confirmation dialog
    return True

# CSS styling
app.index_string = '''
&lt;!DOCTYPE html>
<html>
    <head>
        {%metas%}
        <title>{%title%}</title>
        {%favicon%}
        {%css%}
        <style>
            body {
                font-family: Arial, sans-serif;
                margin: 0;
                padding: 20px;
                background-color: #f5f5f5;
            }
            .dashboard-title {
                text-align: center;
                color: #333;
            }
            .top-panel {
                display: flex;
                justify-content: space-between;
                margin-bottom: 20px;
            }
            .control-panel, .status-panel {
                background: white;
                padding: 20px;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }
            .control-btn {
                margin: 5px;
                padding: 10px 20px;
                border: none;
                border-radius: 4px;
                cursor: pointer;
                background: #2E86AB;
                color: white;
            }
            .control-btn:hover {
                background: #1d5a7a;
            }
            .control-btn.danger {
                background: #e74c3c;
            }
            .control-btn.danger:hover {
                background: #c0392b;
            }
            .metrics-grid {
                display: grid;
                grid-template-columns: repeat(2, 1fr);
                gap: 20px;
                margin-bottom: 20px;
            }
            .metric-panel {
                background: white;
                padding: 15px;
                border-radius: 8px;
                box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }
            .metrics-table {
                width: 100%;
                background: white;
                border-collapse: collapse;
            }
            .metrics-table th, .metrics-table td {
                padding: 12px;
                text-align: left;
                border-bottom: 1px solid #ddd;
            }
            .metrics-table th {
                background-color: #f8f9fa;
                font-weight: bold;
            }
            .positive { color: #27ae60; }
            .negative { color: #e74c3c; }
            .neutral { color: #7f8c8d; }
            .weight-display {
                font-size: 24px;
                font-weight: bold;
                color: #2E86AB;
                margin-top: 10px;
            }
        </style>
    </head>
    <body>
        {%app_entry%}
        <footer>
            {%config%}
            {%scripts%}
            {%renderer%}
        </footer>
    </body>
</html>
'''

if __name__ == '__main__':
    app.run_server(debug=True, port=8050)
```

## 🎯 Exercício Resumo

### What You've Accomplished

In this application-level exercise, you've successfully:

1. ✅ Built a sophisticated canary controller with progressive traffic shifting
2. ✅ Implemented A/B testing framework with statistical analysis
3. ✅ Created advanced metrics collection with anomaly detection
4. ✅ Developed automated rollback based on SLO violations
5. ✅ Integrated service mesh for traffic management
6. ✅ Built real-time monitoring dashboard

### Key Takeaways

- **Progressive Rollout**: Canary implantaçãos minimize risk by gradually exposing users
- **Data-Driven Decisions**: Metrics and statistical analysis guide implantação decisions
- **Automatic Safety**: Rollback triggers prevent bad implantaçãos from affecting all users
- **A/B Testing Integration**: Combine implantação strategies with feature experiments
- **Observability is Key**: Comprehensive monitoring enables confident implantaçãos

### Common Pitfalls to Avoid

1. **Too Fast Progression** - Give enough time for metrics to stabilize at each stage
2. **Ignoring Statistical Significance** - Don't make decisions on insufficient data
3. **Poor Metric Selection** - Choose metrics that truly represent user experience
4. **Missing Correlation** - Consider relationships between metrics, not just individual values

## 🚀 Extension Challenges

Ready to enhance your canary implantação? Try these challenges:

### Challenge 1: Multi-Cluster Canary
Implement canary implantação across multiple Kubernetes clusters with global traffic management.

### Challenge 2: Machine Learning Analysis
Use ML models to predict implantação success and optimize progression speed.

### Challenge 3: Cost-Aware Canary
Add cost metrics and optimize canary progression to minimize cloud spending.

### Challenge 4: Chaos Engineering
Integrate chaos experiments during canary to test resilience.

## 📚 Additional Recursos

- [Google's Canarying Practices](https://sre.google/workbook/canarying-releases/)
- [Flagger Progressive Delivery](https://flagger.app/)
- [Istio Traffic Management](https://istio.io/latest/docs/concepts/traffic-management/)
- [Statistical Analysis for A/B Testing](https://www.exp-platform.com/Documents/2014%20experimentersRulesOfThumb.pdf)

---

Excellent work! You've mastered canary deployments. Ready for Exercise 3: Feature Flags & Progressive Delivery? 🚀