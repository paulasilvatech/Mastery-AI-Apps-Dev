---
sidebar_position: 4
title: "Exercise 3: Part 2"
description: "## 🚀 Part 2: Implementation and Integration"
---

# Ejercicio 3: Quality Automation System - Partee 2

## 🚀 Partee 2: Implementation and Integration

### Step 9: Implement the Core Quality System

Now let's build the complete quality automation system:

```python
# quality_system.py
import asyncio
from typing import Dict, List, Optional, Any, AsyncIterator
from pathlib import Path
from datetime import datetime
import json
import aiofiles
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from collections import defaultdict
import sqlite3

class QualityAutomationSystem:
    """Complete quality automation system."""
    
    def __init__(self, config: Optional[QualityConfig] = None):
        self.config = config or QualityConfig()
        self.monitors = self._initialize_monitors()
        self.rules_engine = QualityRulesEngine(self.config.rules)
        self.metrics_calculator = MetricsCalculator()
        self.history = QualityHistory()
        
    def _initialize_monitors(self) -&gt; List[QualityMonitor]:
        """Initialize all quality monitors."""
        return [
            ComplexityMonitor(),
            DocumentationMonitor(),
            CodeSmellMonitor(),
            TestCoverageMonitor(),
            DuplicationMonitor()
        ]
    
    async def analyze_file(self, filepath: Path) -&gt; QualityReport:
        """
        Perform complete quality analysis on a file.
        
        Args:
            filepath: Path to Python file to analyze
            
        Returns:
            Comprehensive quality report
        """
        # Read file content
        async with aiofiles.open(filepath, 'r') as f:
            code = await f.read()
        
        # Run all monitors in parallel
        monitor_tasks = [
            monitor.analyze(code, filepath) 
            for monitor in self.monitors
        ]
        results = await asyncio.gather(*monitor_tasks)
        
        # Combine results
        combined_metrics = self._combine_monitor_results(results)
        
        # Calculate overall metrics
        quality_metrics = self._calculate_quality_metrics(combined_metrics)
        
        # Evaluate rules
        violations = self.rules_engine.evaluate(quality_metrics)
        
        # Generate improvements
        improvements = self._suggest_improvements(quality_metrics, violations)
        
        # Store in history
        await self.history.store(filepath, quality_metrics)
        
        return QualityReport(
            filepath=filepath,
            timestamp=datetime.now(),
            metrics=quality_metrics,
            violations=violations,
            improvements=improvements
        )
```

**🤖 Copilot Prompt Suggestion #5:**
```python
# Implement comprehensive file analysis:
# 1. Parallel monitor execution:
#    - Use asyncio.gather() for speed
#    - Handle monitor failures gracefully
#    - Timeout long-running monitors
# 2. Result combination:
#    - Merge metrics from all monitors
#    - Handle conflicting data
#    - Normalize different formats
# 3. Quality calculation:
#    - Apply weighted scoring
#    - Consider critical issues
#    - Calculate trends
# 4. Improvement generation:
#    - Prioritize by impact
#    - Group related issues
#    - Provide actionable steps
# 5. History tracking:
#    - Store metrics over time
#    - Calculate improvements
#    - Identify patterns
# Return complete analysis
```

### Step 10: Implement Real-time Monitoring

Add file watching capabilities:

```python
class QualityWatcher(FileSystemEventHandler):
    """Watch files for changes and trigger analysis."""
    
    def __init__(self, quality_system: QualityAutomationSystem):
        self.quality_system = quality_system
        self.analysis_queue = asyncio.Queue()
        self.running = False
        
    async def start_watching(self, path: Path):
        """Start watching directory for changes."""
        self.running = True
        
        # Start file observer
        observer = Observer()
        observer.schedule(self, str(path), recursive=True)
        observer.start()
        
        # Process analysis queue
        asyncio.create_task(self._process_queue())
        
        # Keep running
        try:
            while self.running:
                await asyncio.sleep(1)
        finally:
            observer.stop()
            observer.join()
    
    def on_modified(self, event):
        """Handle file modification events."""
        if not event.is_directory and event.src_path.endswith('.py'):
            # Add to analysis queue
            asyncio.create_task(
                self.analysis_queue.put(Path(event.src_path))
            )
    
    async def _process_queue(self):
        """Process files in analysis queue."""
        while self.running:
            try:
                filepath = await asyncio.wait_for(
                    self.analysis_queue.get(), 
                    timeout=1.0
                )
                
                # Analyze file
                report = await self.quality_system.analyze_file(filepath)
                
                # Emit quality event
                await self._emit_quality_event(report)
                
            except asyncio.TimeoutError:
                continue
```

### Step 11: Create Quality Panel

Build a real-time dashboard:

```python
# dashboards/quality_dashboard.py
from flask import Flask, render_template, jsonify
from flask_socketio import SocketIO, emit
import plotly.graph_objs as go
import plotly.utils

class QualityDashboard:
    """Real-time quality monitoring dashboard."""
    
    def __init__(self, quality_system: QualityAutomationSystem):
        self.app = Flask(__name__)
        self.socketio = SocketIO(self.app, cors_allowed_origins="*")
        self.quality_system = quality_system
        self._setup_routes()
        
    def _setup_routes(self):
        """Setup dashboard routes."""
        
        @self.app.route('/')
        def index():
            return render_template('dashboard.html')
        
        @self.app.route('/api/metrics/<path>')
        async def get_metrics(path):
            """Get current metrics for a file/project."""
            metrics = await self.quality_system.get_current_metrics(path)
            return jsonify(metrics.to_dict())
        
        @self.app.route('/api/history/<path>')
        async def get_history(path):
            """Get historical metrics."""
            history = await self.quality_system.history.get_history(
                path, 
                days=30
            )
            
            # Create time series chart
            chart = self._create_quality_chart(history)
            
            return jsonify({
                'chart': json.dumps(chart, cls=plotly.utils.PlotlyJSONEncoder),
                'current': history[-1].to_dict() if history else None
            })
        
        @self.socketio.on('subscribe')
        def handle_subscribe(data):
            """Subscribe to real-time updates."""
            path = data.get('path')
            emit('subscribed', {{'path': path}})
    
    def _create_quality_chart(self, history: List[QualityMetrics]) -&gt; dict:
        """Create Plotly chart for quality metrics."""
        # Extract time series data
        timestamps = [m.timestamp for m in history]
        quality_scores = [m.overall_quality for m in history]
        
        # Create line chart
        trace = go.Scatter(
            x=timestamps,
            y=quality_scores,
            mode='lines+markers',
            name='Overall Quality',
            line=dict(color='rgb(67, 178, 145)', width=2)
        )
        
        layout = go.Layout(
            title='Code Quality Over Time',
            xaxis=dict(title='Date'),
            yaxis=dict(title='Quality Score', range=[0, 100]),
            showlegend=True
        )
        
        return {{'data': [trace], 'layout': layout}}
```

**🤖 Copilot Prompt Suggestion #6:**
```python
# Create comprehensive dashboard:
# 1. Real-time metrics display:
#    - Current quality score (big number)
#    - Gauge charts for each metric
#    - Traffic lights for thresholds
# 2. Historical charts:
#    - Line chart for quality over time
#    - Stacked area for metric breakdown
#    - Heatmap for file quality
# 3. Issue tracking:
#    - List of current violations
#    - Severity indicators
#    - Quick fix buttons
# 4. Project overview:
#    - File tree with quality colors
#    - Worst files list
#    - Recent improvements
# 5. WebSocket updates:
#    - Push changes in real-time
#    - Animate metric changes
#    - Show notifications
# Use Bootstrap for responsive design
```

### Step 12: Implement CI/CD Integration

Create GitHub Actions integration:

```python
# integrations/github_actions.py
import os
import sys
from pathlib import Path

class GitHubActionsIntegration:
    """Integration with GitHub Actions CI/CD."""
    
    def __init__(self, quality_system: QualityAutomationSystem):
        self.quality_system = quality_system
        
    async def run_quality_check(self) -&gt; int:
        """Run quality check for CI/CD pipeline."""
        # Get changed files from git
        changed_files = self._get_changed_files()
        
        # Analyze all Python files
        all_reports = []
        for filepath in changed_files:
            if filepath.suffix == '.py':
                report = await self.quality_system.analyze_file(filepath)
                all_reports.append(report)
        
        # Generate CI output
        self._generate_ci_output(all_reports)
        
        # Check for failures
        has_errors = any(
            v.severity == "error" 
            for r in all_reports 
            for v in r.violations
        )
        
        return 1 if has_errors else 0
    
    def _generate_ci_output(self, reports: List[QualityReport]):
        """Generate GitHub Actions formatted output."""
        for report in reports:
            # GitHub Actions annotation format
            for violation in report.violations:
                print(
                    f"::{{violation.severity}} "
                    f"file={report.filepath},"
                    f"line={violation.line},"
                    f"col={violation.column}::"
                    f"{violation.message}"
                )
        
        # Summary
        total_issues = sum(len(r.violations) for r in reports)
        avg_quality = sum(r.metrics.overall_quality for r in reports) / len(reports)
        
        print(f"\n## Quality Check Summary")
        print(f"- Files analyzed: {len(reports)}")
        print(f"- Total issues: {total_issues}")
        print(f"- Average quality: {avg_quality:.1f}%")
```

### Step 13: Create Report Generators

Build multiple report formats:

```python
# reporters/report_generator.py
from jinja2 import Template
import markdown
import pdfkit

class ReportGenerator:
    """Generate quality reports in various formats."""
    
    def __init__(self, template_dir: Path):
        self.template_dir = template_dir
        
    async def generate_html_report(
        self, 
        project_path: Path,
        metrics: ProjectMetrics
    ) -&gt; str:
        """Generate comprehensive HTML report."""
        # Load template
        template = self._load_template('report.html')
        
        # Prepare data
        report_data = {
            'project_name': project_path.name,
            'timestamp': datetime.now(),
            'overall_quality': metrics.overall_quality,
            'quality_level': metrics.quality_level.name,
            'metrics': metrics,
            'top_issues': self._get_top_issues(metrics),
            'improvements': self._get_improvements(metrics),
            'file_breakdown': self._get_file_breakdown(metrics)
        }
        
        # Render template
        html = template.render(**report_data)
        
        return html
    
    async def generate_markdown_report(
        self,
        project_path: Path,
        metrics: ProjectMetrics
    ) -&gt; str:
        """Generate Markdown report for Git repositories."""
        template = self._load_template('report.md')
        
        # Generate quality badge
        badge_url = self._generate_badge_url(metrics.quality_level)
        
        report_data = {
            'badge_url': badge_url,
            'project_name': project_path.name,
            'metrics': metrics,
            'summary': self._generate_summary(metrics)
        }
        
        return template.render(**report_data)
```

**🤖 Copilot Prompt Suggestion #7:**
```python
# Create comprehensive report generator:
# 1. HTML Report features:
#    - Executive summary
#    - Interactive charts (Chart.js)
#    - Drill-down by file
#    - Code snippets with issues
#    - Fix suggestions
# 2. Markdown report:
#    - README-friendly format
#    - Quality badges
#    - Summary tables
#    - Top issues list
# 3. PDF generation:
#    - Professional layout
#    - Charts and graphs
#    - Page numbers
#    - Table of contents
# 4. JSON export:
#    - Machine-readable format
#    - All metrics included
#    - Historical data
# 5. Email reports:
#    - Daily/weekly summaries
#    - Trend analysis
#    - Action items
# Use Jinja2 for templating
```

### Step 14: Implement Quality Historial

Ruta metrics over time:

```python
class QualityHistory:
    """Store and retrieve historical quality metrics."""
    
    def __init__(self, db_path: Path = Path("quality.db")):
        self.db_path = db_path
        self._init_database()
        
    def _init_database(self):
        """Initialize SQLite database."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS quality_metrics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                filepath TEXT NOT NULL,
                timestamp DATETIME NOT NULL,
                overall_quality REAL NOT NULL,
                documentation_coverage REAL,
                test_coverage REAL,
                complexity REAL,
                smells INTEGER,
                metrics_json TEXT,
                INDEX idx_filepath_timestamp (filepath, timestamp)
            )
        ''')
        
        conn.commit()
        conn.close()
    
    async def store(self, filepath: Path, metrics: QualityMetrics):
        """Store metrics in history."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO quality_metrics (
                filepath, timestamp, overall_quality,
                documentation_coverage, test_coverage,
                complexity, smells, metrics_json
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            str(filepath),
            metrics.timestamp,
            metrics.overall_quality,
            metrics.documentation_coverage,
            metrics.test_coverage,
            metrics.cyclomatic_complexity,
            metrics.total_smells,
            json.dumps(metrics.to_dict())
        ))
        
        conn.commit()
        conn.close()
    
    async def get_history(
        self, 
        filepath: Path, 
        days: int = 30
    ) -&gt; List[QualityMetrics]:
        """Retrieve historical metrics."""
        # Query database
        # Convert to QualityMetrics objects
        # Return sorted by timestamp
```

### Step 15: Create Quality API

Build REST API for external integration:

```python
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse

class QualityAPI:
    """REST API for quality system."""
    
    def __init__(self, quality_system: QualityAutomationSystem):
        self.app = FastAPI(title="Code Quality API")
        self.quality_system = quality_system
        self._setup_routes()
        
    def _setup_routes(self):
        """Setup API routes."""
        
        @self.app.get("/health")
        async def health_check():
            return {{"status": "healthy"}}
        
        @self.app.post("/analyze")
        async def analyze_code(request: AnalyzeRequest):
            """Analyze code quality."""
            try:
                # Create temp file
                with tempfile.NamedTemporaryFile(
                    mode='w', 
                    suffix='.py', 
                    delete=False
                ) as f:
                    f.write(request.code)
                    temp_path = Path(f.name)
                
                # Analyze
                report = await self.quality_system.analyze_file(temp_path)
                
                # Clean up
                temp_path.unlink()
                
                return JSONResponse(
                    content=report.to_dict(),
                    status_code=200
                )
                
            except Exception as e:
                raise HTTPException(status_code=500, detail=str(e))
        
        @self.app.get("/metrics/{project}")
        async def get_project_metrics(project: str):
            """Get project-wide metrics."""
            metrics = await self.quality_system.get_project_metrics(project)
            return metrics.to_dict()
        
        @self.app.post("/enforce")
        async def enforce_standards(request: EnforceRequest):
            """Check code against quality standards."""
            # Run quality checks
            # Return pass/fail with details
```

## ✅ Progress Verificarpoint

At this point, you should have:
- ✅ Implemented core quality system
- ✅ Created real-time monitoring
- ✅ Built quality dashboard
- ✅ Added CI/CD integration
- ✅ Created report generators
- ✅ Implemented quality history
- ✅ Built REST API

### Integration Test

Test the complete system:

```python
# test_integration.py
async def test_full_system():
    # Initialize system
    system = QualityAutomationSystem()
    
    # Analyze a project
    project_path = Path("sample_project")
    metrics = await system.analyze_project(project_path)
    
    # Check dashboard
    dashboard = QualityDashboard(system)
    assert dashboard.app is not None
    
    # Test CI/CD integration
    ci = GitHubActionsIntegration(system)
    exit_code = await ci.run_quality_check()
    assert exit_code in [0, 1]
    
    # Generate report
    generator = ReportGenerator(Path("templates"))
    html_report = await generator.generate_html_report(
        project_path, 
        metrics
    )
    assert "<html>" in html_report
    
    print("✅ All integrations working!")

# Run test
asyncio.run(test_full_system())
```

## 🎯 Partee 2 Resumen

You've successfully:
1. Implemented the complete quality system
2. Added real-time monitoring capabilities
3. Created interactive dashboards
4. Integrated with CI/CD pipelines
5. Built comprehensive reporting
6. Added historical tracking
7. Created REST API for integration

**Siguiente**: Continuar to Partee 3 where we'll add advanced features, despliegue, and create the final producción system!

---

💡 **Pro Tip**: Use async/await throughout for better performance. Quality checks can be slow, so parallel processing is essential for responsive systems!