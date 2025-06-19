# Module 22: Monitoring Dashboards & Scripts

## 📊 resources/monitoring-dashboards/

### grafana-agent-metrics.json
```json
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": "-- Grafana --",
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "target": {
          "limit": 100,
          "matchAny": false,
          "tags": [],
          "type": "dashboard"
        },
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "id": 1,
  "links": [],
  "liveNow": false,
  "panels": [
    {
      "datasource": {
        "type": "prometheus",
        "uid": "prometheus"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "tooltip": false,
              "viz": false,
              "legend": false
            },
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "reqps"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 0
      },
      "id": 2,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "prometheus"
          },
          "expr": "rate(agent_requests_total[5m])",
          "refId": "A"
        }
      ],
      "title": "Agent Request Rate",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "prometheus"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "thresholds"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "yellow",
                "value": 0.05
              },
              {
                "color": "red",
                "value": 0.1
              }
            ]
          },
          "unit": "percentunit"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 0
      },
      "id": 3,
      "options": {
        "orientation": "auto",
        "reduceOptions": {
          "values": false,
          "calcs": [
            "lastNotNull"
          ],
          "fields": ""
        },
        "showThresholdLabels": false,
        "showThresholdMarkers": true
      },
      "pluginVersion": "9.0.0",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "prometheus"
          },
          "expr": "rate(agent_requests_total{status=\"error\"}[5m]) / rate(agent_requests_total[5m])",
          "refId": "A"
        }
      ],
      "title": "Error Rate",
      "type": "gauge"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "prometheus"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": {
              "tooltip": false,
              "viz": false,
              "legend": false
            },
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "s"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 8
      },
      "id": 4,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "prometheus"
          },
          "expr": "histogram_quantile(0.95, sum(rate(agent_request_duration_seconds_bucket[5m])) by (le))",
          "refId": "A"
        }
      ],
      "title": "95th Percentile Response Time",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "prometheus",
        "uid": "prometheus"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 10,
            "gradientMode": "none",
            "hideFrom": {
              "tooltip": false,
              "viz": false,
              "legend": false
            },
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "never",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "bytes"
        },
        "overrides": []
      },
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 8
      },
      "id": 5,
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "single",
          "sort": "none"
        }
      },
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "prometheus"
          },
          "expr": "agent_memory_usage_bytes",
          "refId": "A"
        }
      ],
      "title": "Memory Usage",
      "type": "timeseries"
    }
  ],
  "refresh": "5s",
  "schemaVersion": 36,
  "style": "dark",
  "tags": ["agents", "monitoring"],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-6h",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "",
  "title": "Agent Performance Dashboard",
  "uid": "agent-metrics",
  "version": 0,
  "weekStart": ""
}
```

### app-insights-queries.md
```markdown
# Application Insights Queries for Agent Monitoring

## 📊 Key Performance Queries

### 1. Agent Request Performance
```kusto
requests
| where name contains "agent"
| where timestamp > ago(1h)
| summarize 
    RequestCount = count(),
    AvgDuration = avg(duration),
    P95Duration = percentile(duration, 95),
    P99Duration = percentile(duration, 99)
    by bin(timestamp, 1m), name
| render timechart
```

### 2. Agent Error Analysis
```kusto
exceptions
| where timestamp > ago(1h)
| where cloud_RoleName contains "agent"
| summarize ErrorCount = count() by type, method, outerMessage
| order by ErrorCount desc
| take 20
```

### 3. Agent Memory Usage Trends
```kusto
performanceCounters
| where timestamp > ago(1h)
| where name == "Private Bytes"
| where cloud_RoleName contains "agent"
| summarize AvgMemory = avg(value) by bin(timestamp, 1m), cloud_RoleInstance
| render timechart
```

### 4. Tool Execution Performance
```kusto
customEvents
| where timestamp > ago(1h)
| where name == "ToolExecution"
| extend 
    ToolName = tostring(customDimensions.tool_name),
    Duration = todouble(customDimensions.execution_time),
    Success = tobool(customDimensions.success)
| summarize 
    TotalCalls = count(),
    SuccessRate = countif(Success) * 100.0 / count(),
    AvgDuration = avg(Duration),
    P95Duration = percentile(Duration, 95)
    by ToolName
| order by TotalCalls desc
```

### 5. Agent State Transitions
```kusto
customEvents
| where timestamp > ago(1h)
| where name == "StateTransition"
| extend 
    AgentName = tostring(customDimensions.agent_name),
    FromState = tostring(customDimensions.from_state),
    ToState = tostring(customDimensions.to_state)
| summarize TransitionCount = count() by AgentName, FromState, ToState
| order by TransitionCount desc
```

### 6. Memory System Performance
```kusto
customEvents
| where timestamp > ago(1h)
| where name == "MemoryOperation"
| extend 
    Operation = tostring(customDimensions.operation),
    MemoryType = tostring(customDimensions.memory_type),
    Duration = todouble(customDimensions.duration_ms)
| summarize 
    OperationCount = count(),
    AvgDuration = avg(Duration),
    P95Duration = percentile(Duration, 95)
    by Operation, MemoryType
| order by OperationCount desc
```

### 7. End-to-End Transaction Flow
```kusto
requests
| where timestamp > ago(1h)
| where name contains "agent"
| join kind=inner (
    dependencies
    | where timestamp > ago(1h)
) on operation_Id
| project 
    timestamp,
    RequestName = name,
    RequestDuration = duration,
    DependencyName = name1,
    DependencyDuration = duration1,
    Success = success and success1
| summarize 
    TotalTransactions = count(),
    SuccessRate = countif(Success) * 100.0 / count(),
    AvgTotalDuration = avg(RequestDuration + DependencyDuration)
    by RequestName, DependencyName
```

### 8. Agent Availability
```kusto
availabilityResults
| where timestamp > ago(24h)
| where name contains "Agent Health Check"
| summarize 
    Availability = countif(success) * 100.0 / count(),
    FailureCount = countif(not success)
    by bin(timestamp, 1h), location
| render timechart
```

## 🚨 Alert Queries

### High Error Rate Alert
```kusto
requests
| where timestamp > ago(5m)
| where name contains "agent"
| summarize 
    ErrorRate = countif(not success) * 100.0 / count()
| where ErrorRate > 5  // Alert if error rate > 5%
```

### Memory Leak Detection
```kusto
performanceCounters
| where timestamp > ago(30m)
| where name == "Private Bytes"
| where cloud_RoleName contains "agent"
| summarize MemoryTrend = series_fit_line(value) by cloud_RoleInstance
| where MemoryTrend[0] > 1000000  // Alert if growing > 1MB/min
```

### Tool Failure Alert
```kusto
customEvents
| where timestamp > ago(5m)
| where name == "ToolExecution"
| extend Success = tobool(customDimensions.success)
| summarize 
    FailureRate = countif(not Success) * 100.0 / count()
    by tostring(customDimensions.tool_name)
| where FailureRate > 20  // Alert if tool failure rate > 20%
```

## 📈 Dashboard Queries

### Agent Overview Dashboard
```kusto
let timeRange = 1h;
let requests = requests
    | where timestamp > ago(timeRange)
    | where name contains "agent";
let exceptions = exceptions
    | where timestamp > ago(timeRange)
    | where cloud_RoleName contains "agent";
let metrics = performanceCounters
    | where timestamp > ago(timeRange)
    | where cloud_RoleName contains "agent";
union 
    (requests | summarize RequestCount = count() | extend Metric = "Total Requests"),
    (requests | summarize AvgDuration = avg(duration) | extend Metric = "Avg Duration (ms)"),
    (exceptions | summarize ErrorCount = count() | extend Metric = "Total Errors"),
    (metrics | where name == "Private Bytes" | summarize AvgMemory = avg(value)/1048576 | extend Metric = "Avg Memory (MB)")
| project Metric, Value = coalesce(RequestCount, AvgDuration, ErrorCount, AvgMemory)
```

## 🔍 Investigation Queries

### Trace Specific Request
```kusto
let requestId = "your-request-id-here";
union requests, dependencies, exceptions, traces, customEvents
| where timestamp > ago(1h)
| where operation_Id == requestId or operation_ParentId == requestId
| order by timestamp asc
| project timestamp, itemType, name, message, duration, success, customDimensions
```

### Agent Performance Comparison
```kusto
requests
| where timestamp > ago(24h)
| where name contains "agent"
| extend AgentType = extract("agent/([^/]+)", 1, name)
| summarize 
    RequestCount = count(),
    AvgDuration = avg(duration),
    P95Duration = percentile(duration, 95),
    ErrorRate = countif(not success) * 100.0 / count()
    by AgentType
| order by RequestCount desc
```
```

### prometheus-alerts.yml
```yaml
# Prometheus Alert Rules for Agent Monitoring

groups:
  - name: agent_alerts
    interval: 30s
    rules:
      # High Error Rate
      - alert: AgentHighErrorRate
        expr: |
          (
            sum(rate(agent_requests_total{status="error"}[5m])) by (agent_name)
            /
            sum(rate(agent_requests_total[5m])) by (agent_name)
          ) > 0.05
        for: 5m
        labels:
          severity: warning
          component: agent
        annotations:
          summary: "High error rate for agent {{ $labels.agent_name }}"
          description: "Agent {{ $labels.agent_name }} has error rate of {{ $value | humanizePercentage }} (threshold: 5%)"

      # Agent Down
      - alert: AgentDown
        expr: up{job="agent"} == 0
        for: 2m
        labels:
          severity: critical
          component: agent
        annotations:
          summary: "Agent {{ $labels.instance }} is down"
          description: "Agent {{ $labels.instance }} has been down for more than 2 minutes"

      # High Response Time
      - alert: AgentHighResponseTime
        expr: |
          histogram_quantile(0.95,
            sum(rate(agent_request_duration_seconds_bucket[5m])) by (agent_name, le)
          ) > 2
        for: 5m
        labels:
          severity: warning
          component: agent
        annotations:
          summary: "High response time for agent {{ $labels.agent_name }}"
          description: "95th percentile response time is {{ $value }}s (threshold: 2s)"

      # Memory Leak Detection
      - alert: AgentMemoryLeak
        expr: |
          (
            agent_memory_usage_bytes - agent_memory_usage_bytes offset 30m
          ) > 100 * 1024 * 1024
        for: 30m
        labels:
          severity: warning
          component: agent
        annotations:
          summary: "Potential memory leak in agent {{ $labels.agent_name }}"
          description: "Memory increased by {{ $value | humanize }}B in last 30 minutes"

      # High Memory Usage
      - alert: AgentHighMemoryUsage
        expr: |
          agent_memory_usage_bytes{memory_type="rss"} > 1 * 1024 * 1024 * 1024
        for: 10m
        labels:
          severity: warning
          component: agent
        annotations:
          summary: "High memory usage for agent {{ $labels.agent_name }}"
          description: "Memory usage is {{ $value | humanize }}B (threshold: 1GB)"

      # Tool Failure Rate
      - alert: ToolHighFailureRate
        expr: |
          (
            sum(rate(agent_tool_executions_total{status="failure"}[5m])) by (tool_name)
            /
            sum(rate(agent_tool_executions_total[5m])) by (tool_name)
          ) > 0.2
        for: 5m
        labels:
          severity: warning
          component: agent_tool
        annotations:
          summary: "High failure rate for tool {{ $labels.tool_name }}"
          description: "Tool {{ $labels.tool_name }} has failure rate of {{ $value | humanizePercentage }}"

      # State Transition Anomaly
      - alert: AgentStateTransitionAnomaly
        expr: |
          rate(agent_state_transitions_total{to_state="error"}[5m]) > 0.1
        for: 5m
        labels:
          severity: warning
          component: agent
        annotations:
          summary: "Frequent error state transitions for {{ $labels.agent_name }}"
          description: "Agent transitioning to error state {{ $value }} times per second"

      # Queue Backlog
      - alert: AgentQueueBacklog
        expr: agent_queue_size > 1000
        for: 5m
        labels:
          severity: warning
          component: agent
        annotations:
          summary: "Large queue backlog for agent {{ $labels.agent_name }}"
          description: "Queue size is {{ $value }} (threshold: 1000)"

      # Long Running Operations
      - alert: AgentLongRunningOperation
        expr: agent_active_requests{duration_seconds="300+"} > 0
        for: 5m
        labels:
          severity: warning
          component: agent
        annotations:
          summary: "Long running operations in agent {{ $labels.agent_name }}"
          description: "{{ $value }} operations running for more than 5 minutes"

  - name: agent_sla_alerts
    interval: 60s
    rules:
      # SLA Violation - Availability
      - alert: AgentSLAAvailability
        expr: |
          (
            sum(rate(agent_requests_total{status="success"}[1h])) by (agent_name)
            /
            sum(rate(agent_requests_total[1h])) by (agent_name)
          ) < 0.99
        for: 5m
        labels:
          severity: critical
          component: agent
          sla: availability
        annotations:
          summary: "SLA violation: Agent {{ $labels.agent_name }} availability below 99%"
          description: "Current availability: {{ $value | humanizePercentage }}"

      # SLA Violation - Response Time
      - alert: AgentSLAResponseTime
        expr: |
          histogram_quantile(0.99,
            sum(rate(agent_request_duration_seconds_bucket[1h])) by (agent_name, le)
          ) > 5
        for: 5m
        labels:
          severity: critical
          component: agent
          sla: latency
        annotations:
          summary: "SLA violation: Agent {{ $labels.agent_name }} P99 latency above 5s"
          description: "Current P99 latency: {{ $value }}s"
```

## 🛠️ Scripts

### scripts/setup-module.sh
```bash
#!/bin/bash

# Module 22 Setup Script
# Sets up the complete environment for Module 22

set -e

echo "🚀 Setting up Module 22: Building Custom Agents"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check Python version
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
REQUIRED_VERSION="3.11"

if ! python3 -c "import sys; exit(0 if sys.version_info >= (3, 11) else 1)"; then
    echo -e "${RED}❌ Python 3.11+ is required. Current version: $PYTHON_VERSION${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Python version: $PYTHON_VERSION${NC}"

# Check Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed${NC}"
    exit 1
fi
NODE_VERSION=$(node --version)
echo -e "${GREEN}✅ Node.js version: $NODE_VERSION${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    exit 1
fi
DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,$//')
echo -e "${GREEN}✅ Docker version: $DOCKER_VERSION${NC}"

# Create virtual environment
echo -e "\n${YELLOW}Creating Python virtual environment...${NC}"
python3 -m venv venv
source venv/bin/activate || . venv/Scripts/activate

# Upgrade pip
echo -e "${YELLOW}Upgrading pip...${NC}"
python -m pip install --upgrade pip

# Install Python packages
echo -e "\n${YELLOW}Installing Python packages...${NC}"
pip install -r requirements.txt

# Create directory structure
echo -e "\n${YELLOW}Creating project structure...${NC}"
mkdir -p src/{agents,analyzers,generators,memory,testing}
mkdir -p templates/{markdown,html,rst}
mkdir -p resources/{agent-templates,monitoring-dashboards,performance-benchmarks,design-patterns}
mkdir -p infrastructure/{docker,kubernetes,terraform}
mkdir -p docs
mkdir -p logs
mkdir -p data

# Copy template files
echo -e "${YELLOW}Copying template files...${NC}"
# Note: In a real setup, these would be copied from a templates directory

# Start infrastructure services
echo -e "\n${YELLOW}Starting infrastructure services...${NC}"

# Start Redis
if ! docker ps | grep -q redis-agents; then
    echo "Starting Redis..."
    docker run -d --name redis-agents -p 6379:6379 redis:7-alpine
    echo -e "${GREEN}✅ Redis started${NC}"
else
    echo -e "${GREEN}✅ Redis already running${NC}"
fi

# Start PostgreSQL
if ! docker ps | grep -q postgres-agents; then
    echo "Starting PostgreSQL..."
    docker run -d --name postgres-agents \
        -e POSTGRES_PASSWORD=agentpass \
        -e POSTGRES_DB=agents \
        -p 5432:5432 \
        postgres:16-alpine
    echo -e "${GREEN}✅ PostgreSQL started${NC}"
else
    echo -e "${GREEN}✅ PostgreSQL already running${NC}"
fi

# Wait for services to be ready
echo -e "\n${YELLOW}Waiting for services to be ready...${NC}"
sleep 5

# Test connections
echo -e "\n${YELLOW}Testing connections...${NC}"

# Test Redis
if python -c "import redis; r = redis.Redis(); print(r.ping())" 2>/dev/null | grep -q True; then
    echo -e "${GREEN}✅ Redis connection successful${NC}"
else
    echo -e "${RED}❌ Redis connection failed${NC}"
fi

# Test PostgreSQL (using environment variables)
export PGPASSWORD=agentpass
if psql -h localhost -U postgres -d agents -c "SELECT 1" &>/dev/null; then
    echo -e "${GREEN}✅ PostgreSQL connection successful${NC}"
else
    echo -e "${RED}❌ PostgreSQL connection failed${NC}"
fi

# Create .env file
echo -e "\n${YELLOW}Creating .env file...${NC}"
if [ ! -f .env ]; then
    cat > .env << EOF
# Module 22 Environment Variables

# API Keys
OPENAI_API_KEY=your-openai-key-here
AZURE_OPENAI_ENDPOINT=your-azure-endpoint-here
AZURE_OPENAI_KEY=your-azure-key-here

# Database
REDIS_URL=redis://localhost:6379
DATABASE_URL=postgresql://postgres:agentpass@localhost:5432/agents

# Agent Configuration
AGENT_LOG_LEVEL=INFO
AGENT_TIMEOUT=300
AGENT_MAX_RETRIES=3

# Monitoring
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000

# Development
DEBUG=false
ENVIRONMENT=development
EOF
    echo -e "${GREEN}✅ .env file created (please update with your API keys)${NC}"
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi

# Install pre-commit hooks
echo -e "\n${YELLOW}Setting up pre-commit hooks...${NC}"
pip install pre-commit
cat > .pre-commit-config.yaml << EOF
repos:
  - repo: https://github.com/psf/black
    rev: 23.0.0
    hooks:
      - id: black
        language_version: python3.11

  - repo: https://github.com/charliermarsh/ruff-pre-commit
    rev: v0.1.0
    hooks:
      - id: ruff

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.7.0
    hooks:
      - id: mypy
        additional_dependencies: [types-all]
EOF

pre-commit install
echo -e "${GREEN}✅ Pre-commit hooks installed${NC}"

# Create VS Code settings
echo -e "\n${YELLOW}Creating VS Code settings...${NC}"
mkdir -p .vscode
cat > .vscode/settings.json << EOF
{
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": false,
    "python.linting.mypyEnabled": true,
    "python.formatting.provider": "black",
    "python.testing.pytestEnabled": true,
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.organizeImports": true
    },
    "[python]": {
        "editor.rulers": [88]
    }
}
EOF
echo -e "${GREEN}✅ VS Code settings created${NC}"

# Final validation
echo -e "\n${YELLOW}Running final validation...${NC}"
python scripts/validate-prerequisites.py

echo -e "\n${GREEN}🎉 Module 22 setup complete!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update .env file with your API keys"
echo "2. Review the module README.md"
echo "3. Start with Exercise 1: Documentation Generation Agent"
echo "4. Run 'source venv/bin/activate' to activate the virtual environment"
```

### scripts/validate-prerequisites.py
```python
#!/usr/bin/env python3
"""
Validate Module 22 Prerequisites
Checks that all requirements are met before starting the module
"""

import sys
import subprocess
import importlib
import os
from typing import List, Tuple
import json

# Color codes for terminal output
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    END = '\033[0m'

def print_status(status: bool, message: str):
    """Print colored status message"""
    if status:
        print(f"{Colors.GREEN}✅ {message}{Colors.END}")
    else:
        print(f"{Colors.RED}❌ {message}{Colors.END}")

def check_python_version() -> Tuple[bool, str]:
    """Check Python version is 3.11+"""
    version = sys.version_info
    if version.major == 3 and version.minor >= 11:
        return True, f"Python {version.major}.{version.minor}.{version.micro}"
    return False, f"Python {version.major}.{version.minor}.{version.micro} (3.11+ required)"

def check_package(package_name: str, min_version: str = None) -> Tuple[bool, str]:
    """Check if a Python package is installed"""
    try:
        module = importlib.import_module(package_name.replace('-', '_'))
        version = getattr(module, '__version__', 'unknown')
        
        if min_version and version != 'unknown':
            # Simple version comparison (may need improvement for complex cases)
            installed = tuple(map(int, version.split('.')[:2]))
            required = tuple(map(int, min_version.split('.')[:2]))
            if installed < required:
                return False, f"{package_name} {version} (>={min_version} required)"
        
        return True, f"{package_name} {version}"
    except ImportError:
        return False, f"{package_name} not installed"

def check_command(command: str) -> Tuple[bool, str]:
    """Check if a system command is available"""
    try:
        result = subprocess.run(
            [command, '--version'],
            capture_output=True,
            text=True,
            check=False
        )
        if result.returncode == 0:
            version = result.stdout.strip().split('\n')[0]
            return True, f"{command}: {version}"
        return False, f"{command} not found"
    except FileNotFoundError:
        return False, f"{command} not found"

def check_docker_services() -> List[Tuple[bool, str]]:
    """Check if required Docker services are running"""
    results = []
    
    try:
        # Check Redis
        result = subprocess.run(
            ['docker', 'ps', '--filter', 'name=redis-agents', '--format', '{{.Names}}'],
            capture_output=True,
            text=True
        )
        redis_running = 'redis-agents' in result.stdout
        results.append((redis_running, "Redis container"))
        
        # Check PostgreSQL
        result = subprocess.run(
            ['docker', 'ps', '--filter', 'name=postgres-agents', '--format', '{{.Names}}'],
            capture_output=True,
            text=True
        )
        postgres_running = 'postgres-agents' in result.stdout
        results.append((postgres_running, "PostgreSQL container"))
        
    except Exception as e:
        results.append((False, f"Docker check failed: {e}"))
    
    return results

def check_connections() -> List[Tuple[bool, str]]:
    """Check database connections"""
    results = []
    
    # Check Redis
    try:
        import redis
        r = redis.Redis(host='localhost', port=6379)
        r.ping()
        results.append((True, "Redis connection"))
    except Exception:
        results.append((False, "Redis connection"))
    
    # Check PostgreSQL
    try:
        import psycopg2
        conn = psycopg2.connect(
            host="localhost",
            database="agents",
            user="postgres",
            password="agentpass"
        )
        conn.close()
        results.append((True, "PostgreSQL connection"))
    except Exception:
        results.append((False, "PostgreSQL connection"))
    
    return results

def check_environment_variables() -> List[Tuple[bool, str]]:
    """Check required environment variables"""
    results = []
    
    # Check .env file exists
    env_exists = os.path.exists('.env')
    results.append((env_exists, ".env file exists"))
    
    # Check key variables
    required_vars = [
        'REDIS_URL',
        'DATABASE_URL'
    ]
    
    # Load .env if it exists
    if env_exists:
        from dotenv import load_dotenv
        load_dotenv()
    
    for var in required_vars:
        value = os.getenv(var)
        results.append((bool(value), f"Environment variable: {var}"))
    
    return results

def main():
    """Run all prerequisite checks"""
    print(f"\n{Colors.BLUE}=== Module 22 Prerequisites Validation ==={Colors.END}\n")
    
    all_checks_passed = True
    
    # Python version
    print(f"{Colors.YELLOW}Checking Python version...{Colors.END}")
    status, message = check_python_version()
    print_status(status, message)
    all_checks_passed &= status
    
    # Required packages
    print(f"\n{Colors.YELLOW}Checking Python packages...{Colors.END}")
    packages = [
        ('semantic-kernel', '0.9.0'),
        ('langchain', '0.1.0'),
        ('pydantic', '2.5.0'),
        ('redis', '5.0.0'),
        ('asyncio', None),
        ('pytest', '7.4.0'),
        ('black', '23.0.0'),
        ('mypy', '1.7.0'),
        ('rich', '13.7.0')
    ]
    
    for package, min_version in packages:
        status, message = check_package(package, min_version)
        print_status(status, message)
        all_checks_passed &= status
    
    # System commands
    print(f"\n{Colors.YELLOW}Checking system commands...{Colors.END}")
    commands = ['git', 'docker', 'node']
    
    for command in commands:
        status, message = check_command(command)
        print_status(status, message)
        all_checks_passed &= status
    
    # Docker services
    print(f"\n{Colors.YELLOW}Checking Docker services...{Colors.END}")
    docker_checks = check_docker_services()
    
    for status, message in docker_checks:
        print_status(status, message)
        all_checks_passed &= status
    
    # Connections
    print(f"\n{Colors.YELLOW}Checking connections...{Colors.END}")
    connection_checks = check_connections()
    
    for status, message in connection_checks:
        print_status(status, message)
        all_checks_passed &= status
    
    # Environment
    print(f"\n{Colors.YELLOW}Checking environment...{Colors.END}")
    env_checks = check_environment_variables()
    
    for status, message in env_checks:
        print_status(status, message)
        all_checks_passed &= status
    
    # VS Code extensions (optional check)
    print(f"\n{Colors.YELLOW}Checking VS Code extensions (optional)...{Colors.END}")
    vscode_extensions = [
        'ms-python.python',
        'GitHub.copilot',
        'GitHub.copilot-chat'
    ]
    
    if os.path.exists('.vscode/extensions.json'):
        print_status(True, "VS Code extensions configured")
    else:
        print_status(False, "VS Code extensions not configured (optional)")
    
    # Final result
    print(f"\n{Colors.BLUE}=== Validation Summary ==={Colors.END}")
    if all_checks_passed:
        print(f"\n{Colors.GREEN}✅ All prerequisites met! You're ready for Module 22!{Colors.END}\n")
        return 0
    else:
        print(f"\n{Colors.RED}❌ Some prerequisites are missing. Please install missing components.{Colors.END}\n")
        return 1

if __name__ == "__main__":
    sys.exit(main())
```

### scripts/run-all-tests.sh
```bash
#!/bin/bash

# Run all tests for Module 22
# This script runs unit tests, integration tests, and benchmarks

set -e

echo "🧪 Running Module 22 Tests"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Activate virtual environment
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
elif [ -f "venv/Scripts/activate" ]; then
    source venv/Scripts/activate
else
    echo -e "${RED}❌ Virtual environment not found${NC}"
    exit 1
fi

# Run linting
echo -e "\n${YELLOW}Running code quality checks...${NC}"
echo "Running Black..."
black --check src/ tests/ || echo -e "${YELLOW}⚠️  Black formatting issues found${NC}"

echo "Running Ruff..."
ruff src/ tests/ || echo -e "${YELLOW}⚠️  Ruff linting issues found${NC}"

echo "Running MyPy..."
mypy src/ --ignore-missing-imports || echo -e "${YELLOW}⚠️  MyPy type issues found${NC}"

# Run unit tests
echo -e "\n${YELLOW}Running unit tests...${NC}"
pytest tests/unit/ -v --cov=src --cov-report=html --cov-report=term

# Run integration tests
echo -e "\n${YELLOW}Running integration tests...${NC}"
pytest tests/integration/ -v -m integration

# Run performance benchmarks
echo -e "\n${YELLOW}Running performance benchmarks...${NC}"
python -m pytest tests/benchmarks/ --benchmark-only --benchmark-autosave

# Run memory profiling
echo -e "\n${YELLOW}Running memory profiling...${NC}"
python -m memory_profiler resources/performance-benchmarks/memory_test.py

# Check test coverage
echo -e "\n${YELLOW}Checking test coverage...${NC}"
coverage report --fail-under=80 || echo -e "${YELLOW}⚠️  Coverage below 80%${NC}"

# Run security checks
echo -e "\n${YELLOW}Running security checks...${NC}"
pip-audit || echo -e "${YELLOW}⚠️  Security vulnerabilities found${NC}"

# Generate test report
echo -e "\n${YELLOW}Generating test report...${NC}"
pytest --html=test_report.html --self-contained-html

echo -e "\n${GREEN}✅ All tests completed!${NC}"
echo -e "View detailed results in:"
echo "  - Coverage report: htmlcov/index.html"
echo "  - Test report: test_report.html"
echo "  - Benchmark results: .benchmarks/"
```

### scripts/cleanup.sh
```bash
#!/bin/bash

# Cleanup script for Module 22
# Removes all created resources and containers

set -e

echo "🧹 Cleaning up Module 22 resources"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Confirm cleanup
read -p "This will remove all Module 22 resources. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled"
    exit 0
fi

# Stop and remove Docker containers
echo -e "\n${YELLOW}Stopping Docker containers...${NC}"

if docker ps -a | grep -q redis-agents; then
    docker stop redis-agents && docker rm redis-agents
    echo -e "${GREEN}✅ Redis container removed${NC}"
fi

if docker ps -a | grep -q postgres-agents; then
    docker stop postgres-agents && docker rm postgres-agents
    echo -e "${GREEN}✅ PostgreSQL container removed${NC}"
fi

# Remove Docker volumes
echo -e "\n${YELLOW}Removing Docker volumes...${NC}"
docker volume ls | grep agents | awk '{print $2}' | xargs -r docker volume rm || true

# Clean Python cache
echo -e "\n${YELLOW}Cleaning Python cache...${NC}"
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
find . -type f -name "*.pyo" -delete 2>/dev/null || true
find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true

# Remove generated files
echo -e "\n${YELLOW}Removing generated files...${NC}"
rm -rf htmlcov/
rm -rf .coverage
rm -rf .pytest_cache/
rm -rf .mypy_cache/
rm -rf .ruff_cache/
rm -rf test_report.html
rm -rf .benchmarks/

# Remove logs
echo -e "\n${YELLOW}Removing logs...${NC}"
rm -rf logs/

# Remove data files (with confirmation)
read -p "Remove data directory? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf data/
    echo -e "${GREEN}✅ Data directory removed${NC}"
fi

# Remove virtual environment (with confirmation)
read -p "Remove virtual environment? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf venv/
    echo -e "${GREEN}✅ Virtual environment removed${NC}"
fi

echo -e "\n${GREEN}✅ Cleanup complete!${NC}"
echo -e "${YELLOW}Note: .env file was preserved. Remove manually if needed.${NC}"
```