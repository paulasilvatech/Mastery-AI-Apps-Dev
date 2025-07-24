---
sidebar_position: 2
title: "Exercise 3: Part 3"
description: "## 🚀 Part 3: Advanced Features and Production Deployment"
---

# Ejercicio 3: Quality Automation System - Partee 3

## 🚀 Partee 3: Avanzado Features and producción despliegue

### Step 16: Add Machine Learning for Quality Prediction

Implement ML-based quality prediction:

```python
# ml/quality_predictor.py
import pickle
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
import numpy as np

class QualityPredictor:
    """Predict future quality trends using ML."""
    
    def __init__(self):
        self.model = None
        self.scaler = StandardScaler()
        self.feature_names = [
            'lines_of_code', 'cyclomatic_complexity', 
            'documentation_coverage', 'test_coverage',
            'total_smells', 'code_duplication'
        ]
        
    async def train(self, historical_data: List[QualityMetrics]):
        """Train ML model on historical data."""
        # Prepare features and labels
        X = []
        y = []
        
        for i in range(len(historical_data) - 1):
            current = historical_data[i]
            next_quality = historical_data[i + 1].overall_quality
            
            # Extract features
            features = [
                getattr(current, name, 0) 
                for name in self.feature_names
            ]
            
            X.append(features)
            y.append(next_quality)
        
        # Train model
        X = np.array(X)
        y = np.array(y)
        
        # Scale features
        X_scaled = self.scaler.fit_transform(X)
        
        # Train Random Forest
        self.model = RandomForestRegressor(
            n_estimators=100,
            max_depth=10,
            random_state=42
        )
        self.model.fit(X_scaled, y)
        
        # Save model
        await self._save_model()
    
    async def predict_quality_trend(
        self, 
        current_metrics: QualityMetrics,
        days_ahead: int = 7
    ) -&gt; List[float]:
        """Predict quality trend for next N days."""
        if not self.model:
            await self._load_model()
        
        predictions = []
        current_features = [
            getattr(current_metrics, name, 0) 
            for name in self.feature_names
        ]
        
        for _ in range(days_ahead):
            # Scale features
            features_scaled = self.scaler.transform([current_features])
            
            # Predict next quality
            next_quality = self.model.predict(features_scaled)[0]
            predictions.append(next_quality)
            
            # Update features for next prediction
            # Simulate gradual changes
            current_features[0] *= 1.01  # Slight code growth
            current_features[-1] = next_quality
        
        return predictions
```

**🤖 Copilot Prompt Suggestion #8:**
```python
# Implement ML-based quality prediction:
# 1. Feature engineering:
#    - Time-based features (day of week, sprint phase)
#    - Team velocity metrics
#    - Code churn rate
#    - Developer experience level
# 2. Model selection:
#    - Random Forest for robustness
#    - LSTM for time series
#    - Ensemble for accuracy
# 3. Training pipeline:
#    - Cross-validation
#    - Hyperparameter tuning
#    - Feature importance analysis
# 4. Predictions:
#    - Next sprint quality
#    - Risk of quality degradation
#    - Suggested interventions
# 5. Explainability:
#    - SHAP values for features
#    - Confidence intervals
#    - Actionable insights
# Update model periodically
```

### Step 17: Create Smart Notificaciones

Build intelligent notification system:

```python
# notifications/smart_notifier.py
from enum import Enum
from typing import List, Dict, Any
import aiosmtplib
from email.message import EmailMessage
import httpx

class NotificationChannel(Enum):
    EMAIL = "email"
    SLACK = "slack"
    GITHUB = "github"
    WEBHOOK = "webhook"

class SmartNotifier:
    """Intelligent notification system for quality events."""
    
    def __init__(self, config: NotificationConfig):
        self.config = config
        self.channels = self._setup_channels()
        self.notification_rules = self._load_rules()
        
    async def notify_quality_event(self, event: QualityEvent):
        """Send smart notifications based on event type and severity."""
        # Determine if notification needed
        if not self._should_notify(event):
            return
        
        # Get relevant channels
        channels = self._get_channels_for_event(event)
        
        # Create notification content
        content = self._create_notification_content(event)
        
        # Send to all channels
        tasks = [
            self._send_to_channel(channel, content)
            for channel in channels
        ]
        await asyncio.gather(*tasks)
    
    def _should_notify(self, event: QualityEvent) -&gt; bool:
        """Determine if event warrants notification."""
        # Check severity threshold
        if event.severity &lt; self.config.min_severity:
            return False
        
        # Check rate limiting
        if self._is_rate_limited(event):
            return False
        
        # Check notification rules
        for rule in self.notification_rules:
            if rule.matches(event):
                return rule.should_notify
        
        return True
    
    async def _send_slack_notification(self, content: NotificationContent):
        """Send notification to Slack."""
        webhook_url = self.config.slack_webhook
        
        # Create Slack message with rich formatting
        slack_message = {
            "text": content.title,
            "attachments": [{
                "color": self._get_color_for_severity(content.severity),
                "fields": [
                    {
                        "title": "Project",
                        "value": content.project,
                        "short": True
                    },
                    {
                        "title": "Quality Score",
                        "value": f"{{content.quality_score:.1f}}%",
                        "short": True
                    }
                ],
                "text": content.message,
                "footer": "Quality Automation System",
                "ts": int(datetime.now().timestamp())
            }]
        }
        
        async with httpx.AsyncClient() as client:
            await client.post(webhook_url, json=slack_message)
```

### Step 18: Implement Quality Workflows

Create automated quality improvement workflows:

```python
# workflows/quality_workflows.py
from typing import List, Optional
import asyncio

class QualityWorkflow:
    """Automated workflow for quality improvement."""
    
    def __init__(self, name: str, trigger: WorkflowTrigger):
        self.name = name
        self.trigger = trigger
        self.steps = []
        self.running = False
        
    def add_step(self, step: WorkflowStep):
        """Add step to workflow."""
        self.steps.append(step)
        return self
    
    async def execute(self, context: WorkflowContext):
        """Execute workflow steps."""
        self.running = True
        results = []
        
        try:
            for step in self.steps:
                # Execute step
                result = await step.execute(context)
                results.append(result)
                
                # Check if should continue
                if not result.success and step.stop_on_failure:
                    break
                
                # Update context
                context.update(result.data)
            
            return WorkflowResult(
                success=all(r.success for r in results),
                results=results
            )
        finally:
            self.running = False

class AutoRefactorWorkflow(QualityWorkflow):
    """Automatically refactor code when quality drops."""
    
    def __init__(self):
        super().__init__(
            "Auto Refactor",
            QualityThresholdTrigger(threshold=70.0)
        )
        
        # Add workflow steps
        self.add_step(AnalyzeCodeStep()) \
            .add_step(IdentifyRefactoringsStep()) \
            .add_step(ApplyRefactoringsStep(auto_approve=False)) \
            .add_step(RunTestsStep()) \
            .add_step(CreatePullRequestStep()) \
            .add_step(NotifyTeamStep())
```

**🤖 Copilot Prompt Suggestion #9:**
```python
# Create comprehensive workflow system:
# 1. Workflow triggers:
#    - Quality threshold breach
#    - Schedule (daily, weekly)
#    - Git events (PR, push)
#    - Manual trigger
# 2. Workflow steps:
#    - Code analysis
#    - Auto-fix issues
#    - Generate documentation
#    - Run tests
#    - Create PR/commit
# 3. Conditional logic:
#    - If/else branches
#    - Loops for multiple files
#    - Parallel execution
# 4. Error handling:
#    - Retry failed steps
#    - Rollback on failure
#    - Alert on errors
# 5. Integration:
#    - GitHub Actions
#    - Jenkins
#    - GitLab CI
# Make workflows configurable
```

### Step 19: Create despliegue Configuration

Set up producción despliegue:

```python
# deployment/docker-compose.yml
version: '3.8'

services:
  quality-api:
    build: 
      context: .
      dockerfile: Dockerfile.api
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:pass@postgres:5432/quality
      - REDIS_URL=redis://redis:6379
    depends_on:
      - postgres
      - redis
    volumes:
      - ./data:/app/data
      
  quality-dashboard:
    build:
      context: .
      dockerfile: Dockerfile.dashboard
    ports:
      - "3000:3000"
    environment:
      - API_URL=http://quality-api:8000
      - WEBSOCKET_URL=ws://quality-worker:8080
    depends_on:
      - quality-api
      
  quality-worker:
    build:
      context: .
      dockerfile: Dockerfile.worker
    environment:
      - REDIS_URL=redis://redis:6379
      - DATABASE_URL=postgresql://user:pass@postgres:5432/quality
    depends_on:
      - postgres
      - redis
    volumes:
      - ./repos:/repos:ro
      
  postgres:
    image: postgres:15
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=quality
    volumes:
      - postgres_data:/var/lib/postgresql/data
      
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

Create Kubernetes despliegue:

```yaml
# deployment/k8s/quality-system.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: quality-system
  labels:
    app: quality-system
spec:
  replicas: 3
  selector:
    matchLabels:
      app: quality-system
  template:
    metadata:
      labels:
        app: quality-system
    spec:
      containers:
      - name: api
        image: quality-system:latest
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: quality-secrets
              key: database-url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: quality-system-service
spec:
  selector:
    app: quality-system
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8000
  type: LoadBalancer
```

### Step 20: Create CLI for Production

Build production CLI tool:

```python
# cli_production.py
import click
from rich.console import Console
from rich.table import Table
import asyncio

console = Console()

@click.group()
@click.version_option(version="1.0.0")
def cli():
    """Production Code Quality Automation System."""
    pass

@cli.command()
@click.option('--config', '-c', type=click.Path(exists=True),
              help='Configuration file path')
def start(config):
    """Start quality automation system."""
    console.print("[bold green]Starting Quality Automation System...[/bold green]")
    
    # Load configuration
    config_data = load_config(config) if config else {}
    
    # Initialize system
    system = QualityAutomationSystem(QualityConfig(**config_data))
    
    # Start components
    asyncio.run(start_system(system))

async def start_system(system: QualityAutomationSystem):
    """Start all system components."""
    tasks = []
    
    # Start API server
    api = QualityAPI(system)
    tasks.append(
        asyncio.create_task(
            uvicorn.run(api.app, host="0.0.0.0", port=8000)
        )
    )
    
    # Start dashboard
    dashboard = QualityDashboard(system)
    tasks.append(
        asyncio.create_task(
            dashboard.run(host="0.0.0.0", port=3000)
        )
    )
    
    # Start file watcher
    watcher = QualityWatcher(system)
    tasks.append(
        asyncio.create_task(
            watcher.start_watching(Path("."))
        )
    )
    
    # Start workflow engine
    workflow_engine = WorkflowEngine(system)
    tasks.append(
        asyncio.create_task(
            workflow_engine.start()
        )
    )
    
    console.print("[bold green]✓ All components started![/bold green]")
    
    # Keep running
    await asyncio.gather(*tasks)

@cli.command()
@click.argument('project_path', type=click.Path(exists=True))
@click.option('--format', '-f', 
              type=click.Choice(['html', 'pdf', 'json']),
              default='html')
def report(project_path, format):
    """Generate quality report for project."""
    asyncio.run(generate_report(project_path, format))

@cli.command()
def status():
    """Check system status."""
    # Check all components
    # Display health status
    # Show current metrics
```

### Step 21: Create Comprehensive Tests

Build end-to-end tests:

```python
# tests/test_e2e.py
import pytest
import asyncio
from pathlib import Path
import tempfile

class TestQualitySystemE2E:
    """End-to-end tests for quality system."""
    
    @pytest.fixture
    async def system(self):
        """Create test system instance."""
        config = QualityConfig(
            min_quality_threshold=70.0,
            enable_auto_fix=True
        )
        system = QualityAutomationSystem(config)
        yield system
        # Cleanup
        await system.shutdown()
    
    @pytest.mark.asyncio
    async def test_complete_workflow(self, system):
        """Test complete quality workflow."""
        # Create test project
        with tempfile.TemporaryDirectory() as tmpdir:
            project_path = Path(tmpdir)
            
            # Create sample Python files
            (project_path / "main.py").write_text('''
def calculate_total(items):
    total = 0
    for item in items:
        if item &gt; 0:
            total = total + item
    return total
''')
            
            # Analyze project
            report = await system.analyze_project(project_path)
            
            # Check metrics
            assert report.metrics.overall_quality &gt; 0
            assert len(report.violations) &gt; 0  # Should find issues
            
            # Apply auto-fix
            fixed_report = await system.auto_fix_issues(report)
            
            # Verify improvements
            assert fixed_report.metrics.overall_quality &gt; report.metrics.overall_quality
            
            # Generate report
            html_report = await system.generate_report(
                project_path, 
                format="html"
            )
            assert "<html>" in html_report
    
    @pytest.mark.asyncio
    async def test_ci_integration(self, system):
        """Test CI/CD integration."""
        # Simulate CI environment
        import os
        os.environ['CI'] = 'true'
        os.environ['GITHUB_ACTIONS'] = 'true'
        
        ci_integration = GitHubActionsIntegration(system)
        
        # Run quality check
        exit_code = await ci_integration.run_quality_check()
        
        # Check output format
        assert exit_code in [0, 1]
```

### Step 22: Create Documentation

Generate comprehensive documentation:

```python
# docs/generate_docs.py
from doc_generator import DocumentationGenerator

async def generate_system_docs():
    """Generate documentation for the quality system."""
    generator = DocumentationGenerator()
    
    # Document all modules
    modules = [
        "quality_system.py",
        "monitors/",
        "reporters/",
        "integrations/",
        "workflows/"
    ]
    
    for module in modules:
        await generator.document_module(Path(module))
    
    # Generate API documentation
    api_docs = await generator.generate_api_docs(
        Path("quality_system.py"),
        format="markdown"
    )
    
    # Create user guide
    user_guide = """
# Quality Automation System User Guide

## Installation

```bash
pip install quality-automation-system
```

## Quick Start

1. Initialize configuration:
```bash
quality-system init
```

2. Start monitoring:
```bash
quality-system start --watch .
```

3. View dashboard:
Open http://localhost:3000

## Configuration

Create `quality.toml`:

```toml
[quality]
min_threshold = 80.0
enable_auto_fix = true

[notifications]
slack_webhook = "https://..."
email_smtp = "smtp.gmail.com"

[rules]
max_complexity = 10
min_test_coverage = 70
```
"""
    
    # Save documentation
    Path("docs/USER_GUIDE.md").write_text(user_guide)
```

## ✅ Exercise Completion Checklist

Verify you've completed all components:

- [ ] Built ML-based quality prediction
- [ ] Created smart notification system
- [ ] Implemented quality workflows
- [ ] Set up Docker deployment
- [ ] Created Kubernetes configs
- [ ] Built production CLI
- [ ] Added comprehensive tests
- [ ] Generated documentation
- [ ] Created CI/CD integration
- [ ] Built monitoring dashboard

### Final System Test

Run the complete system:

```bash
# Build Docker images
docker-compose build

# Start system
docker-compose up -d

# Run tests
pytest tests/ -v

# Check dashboard
open http://localhost:3000

# Run quality check
quality-system analyze . --format html --output report.html

# View metrics
quality-system status
```

## 🎯 Exercise Summary

Congratulations! You've built a production-ready quality automation system that:

1. **Monitors Quality** - Real-time code analysis
2. **Enforces Standards** - Automated quality gates
3. **Fixes Issues** - Intelligent refactoring
4. **Tracks History** - Metrics over time
5. **Predicts Trends** - ML-based forecasting
6. **Integrates Everywhere** - CI/CD, IDEs, chat
7. **Scales Horizontally** - Kubernetes ready

### Key Learnings

- Building production-grade Python systems
- Integrating multiple tools and services
- Creating real-time monitoring systems
- Implementing ML for code quality
- Deploying with Docker/Kubernetes
- Building comprehensive test suites

## 🚀 Extensions and Challenges

### Challenge 1: IDE Extension
Create VS Code extension that shows real-time quality metrics.

### Challenge 2: Multi-Language Support
Extend system to support JavaScript, TypeScript, and Go.

### Challenge 3: Team Analytics
Add developer productivity metrics and team dashboards.

### Challenge 4: AI Code Review
Use LLMs to provide intelligent code review suggestions.

## 📝 Module 05 Summary

You've completed all three exercises in Module 05:

1. **Documentation Generator** - Automated documentation creation
2. **Refactoring Assistant** - Intelligent code improvement
3. **Quality System** - Complete automation platform

You've mastered using AI for code quality, documentation, and automation!

---

🎉 **Outstanding achievement! You've built enterprise-grade quality tools. Ready for Module 06: Multi-File Projects and Workspaces!**