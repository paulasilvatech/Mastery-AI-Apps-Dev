---
sidebar_position: 3
title: "Exercise 2: Overview"
description: "## 🎯 Objective"
---

# Exercício 2: Monitoring & Alerting System (⭐⭐ Médio - 45 minutos)

## 🎯 Objective
Implement a comprehensive monitoring and alerting system for produção AI agents, including metrics collection, visualization, distributed tracing, log aggregation, and intelligent alerting.

## 🧠 O Que Você Aprenderá
- Prometheus metrics collection and queries
- Grafana dashboard creation
- Distributed tracing with Jaeger
- Log aggregation patterns
- Alert rule configuration
- SLI/SLO implementation
- Anomaly detection basics

## 📋 Pré-requisitos
- Completard Exercício 1
- Prometheus and Grafana instalado
- Basic PromQL knowledge
- Understanding of observability concepts

## 📚 Voltarground

Production monitoring for AI agents requires:

- **Metrics**: Quantitative measurements (latency, throughput, errors)
- **Traces**: Request flow through distributed systems
- **Logs**: Detailed event information
- **Alerts**: Proactive notification of issues
- **SLOs**: Service level objectives for reliability
- **Painels**: Visual representation of system health

## 🏗️ Monitoring Architecture

```mermaid
graph TB
    subgraph "AI Agents"
        A1[Agent Pod 1]
        A2[Agent Pod 2]
        A3[Agent Pod N]
    end
    
    subgraph "Collection Layer"
        P[Prometheus]
        J[Jaeger]
        L[Loki]
    end
    
    subgraph "Storage Layer"
        PS[(Prometheus TSDB)]
        JS[(Jaeger Storage)]
        LS[(Loki Storage)]
    end
    
    subgraph "Visualization Layer"
        G[Grafana]
        JU[Jaeger UI]
    end
    
    subgraph "Alerting"
        AM[AlertManager]
        PD[PagerDuty]
        S[Slack]
        E[Email]
    end
    
    A1 --&gt; |Metrics| P
    A2 --&gt; |Metrics| P
    A3 --&gt; |Metrics| P
    
    A1 --&gt; |Traces| J
    A2 --&gt; |Traces| J
    A3 --&gt; |Traces| J
    
    A1 --&gt; |Logs| L
    A2 --&gt; |Logs| L
    A3 --&gt; |Logs| L
    
    P --&gt; PS
    J --&gt; JS
    L --&gt; LS
    
    PS --&gt; G
    JS --&gt; JU
    LS --&gt; G
    
    P --&gt; AM
    AM --&gt; PD
    AM --&gt; S
    AM --&gt; E
    
    style G fill:#FF6B35
    style P fill:#E6522C
    style AM fill:#FF9100
```

## 🛠️ Step-by-Step Instructions

### Step 1: Enhance Agent Metrics

**Copilot Prompt Suggestion:**
```typescript
// Enhance the agent to expose comprehensive metrics including:
// - Request rate, error rate, duration (RED metrics)
// - Business metrics (tasks processed, success rate)
// - Resource utilization metrics
// - Custom agent-specific metrics
// - Trace context propagation
// - Structured logging with correlation IDs
```

Create `agent/src/metrics.ts`:
```typescript
import { Registry, Counter, Histogram, Gauge, Summary } from 'prom-client';
import { Request, Response, NextFunction } from 'express';

// Create custom registry
export const register = new Registry();

// Default metrics (CPU, memory, etc.)
import { collectDefaultMetrics } from 'prom-client';
collectDefaultMetrics({ register });

// HTTP metrics
export const httpRequestDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10],
  registers: [register]
});

export const httpRequestTotal = new Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

// Agent metrics
export const agentTasksTotal = new Counter({
  name: 'agent_tasks_total',
  help: 'Total number of agent tasks processed',
  labelNames: ['task_type', 'status'],
  registers: [register]
});

export const agentTaskDuration = new Histogram({
  name: 'agent_task_duration_seconds',
  help: 'Duration of agent task processing',
  labelNames: ['task_type'],
  buckets: [0.1, 0.5, 1, 2, 5, 10, 30, 60],
  registers: [register]
});

export const agentActiveTasks = new Gauge({
  name: 'agent_active_tasks',
  help: 'Number of currently active tasks',
  labelNames: ['task_type'],
  registers: [register]
});

export const agentQueueSize = new Gauge({
  name: 'agent_queue_size',
  help: 'Number of tasks in queue',
  labelNames: ['priority'],
  registers: [register]
});

// Model metrics
export const modelInferenceLatency = new Summary({
  name: 'model_inference_latency_seconds',
  help: 'Latency of model inference calls',
  labelNames: ['model_name', 'model_version'],
  percentiles: [0.5, 0.9, 0.95, 0.99],
  registers: [register]
});

export const modelTokensProcessed = new Counter({
  name: 'model_tokens_processed_total',
  help: 'Total number of tokens processed',
  labelNames: ['model_name', 'operation'],
  registers: [register]
});

// Error metrics
export const agentErrors = new Counter({
  name: 'agent_errors_total',
  help: 'Total number of agent errors',
  labelNames: ['error_type', 'task_type'],
  registers: [register]
});

// Business metrics
export const businessMetrics = {
  revenue: new Counter({
    name: 'agent_revenue_total',
    help: 'Total revenue generated by agent',
    labelNames: ['currency'],
    registers: [register]
  }),
  
  userSatisfaction: new Gauge({
    name: 'agent_user_satisfaction_score',
    help: 'User satisfaction score (0-100)',
    registers: [register]
  }),
  
  taskValue: new Histogram({
    name: 'agent_task_value',
    help: 'Business value of completed tasks',
    labelNames: ['task_type'],
    buckets: [1, 5, 10, 50, 100, 500, 1000],
    registers: [register]
  })
};

// Middleware for HTTP metrics
export function metricsMiddleware(req: Request, res: Response, next: NextFunction) {
  const start = Date.now();
  
  res.on('finish', () =&gt; {
    const duration = (Date.now() - start) / 1000;
    const route = req.route?.path || req.path;
    const labels = {
      method: req.method,
      route,
      status_code: res.statusCode.toString()
    };
    
    httpRequestDuration.observe(labels, duration);
    httpRequestTotal.inc(labels);
  });
  
  next();
}

// Helper to track agent task metrics
export function trackAgentTask(taskType: string) {
  return {
    start: () =&gt; {
      agentActiveTasks.inc({ task_type: taskType });
      return Date.now();
    },
    
    complete: (startTime: number, success: boolean = true) =&gt; {
      const duration = (Date.now() - startTime) / 1000;
      
      agentActiveTasks.dec({ task_type: taskType });
      agentTasksTotal.inc({ 
        task_type: taskType, 
        status: success ? 'success' : 'failure' 
      });
      agentTaskDuration.observe({ task_type: taskType }, duration);
      
      return duration;
    },
    
    error: (errorType: string) =&gt; {
      agentErrors.inc({ error_type: errorType, task_type: taskType });
    }
  };
}
```

Create `agent/src/tracing.ts`:
```typescript
import { NodeTracerProvider } from '@opentelemetry/sdk-trace-node';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';
import { JaegerExporter } from '@opentelemetry/exporter-jaeger';
import { BatchSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { registerInstrumentations } from '@opentelemetry/instrumentation';
import { HttpInstrumentation } from '@opentelemetry/instrumentation-http';
import { ExpressInstrumentation } from '@opentelemetry/instrumentation-express';
import { trace, context, SpanStatusCode, SpanKind } from '@opentelemetry/api';

// Initialize tracer
export function initializeTracing(serviceName: string) {
  const provider = new NodeTracerProvider({
    resource: new Resource({
      [SemanticResourceAttributes.SERVICE_NAME]: serviceName,
      [SemanticResourceAttributes.SERVICE_VERSION]: process.env.APP_VERSION || '1.0.0',
      [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: process.env.NODE_ENV || 'production',
    }),
  });

  // Configure Jaeger exporter
  const jaegerExporter = new JaegerExporter({
    endpoint: process.env.JAEGER_ENDPOINT || 'http://jaeger-collector:14268/api/traces',
  });

  // Add span processor
  provider.addSpanProcessor(new BatchSpanProcessor(jaegerExporter));

  // Register instrumentations
  registerInstrumentations({
    instrumentations: [
      new HttpInstrumentation({
        requestHook: (span, request) =&gt; {
          span.setAttributes({
            'http.request.body': JSON.stringify(request.body),
          });
        },
      }),
      new ExpressInstrumentation(),
    ],
  });

  // Register the provider
  provider.register();

  return trace.getTracer(serviceName);
}

// Trace decorator for methods
export function Trace(operationName?: string) {
  return function (target: any, propertyKey: string, descriptor: PropertyDescriptor) {
    const originalMethod = descriptor.value;

    descriptor.value = async function (...args: any[]) {
      const tracer = trace.getTracer('ai-agent');
      const spanName = operationName || `${target.constructor.name}.${propertyKey}`;
      
      return tracer.startActiveSpan(spanName, async (span) =&gt; {
        try {
          // Add input attributes
          span.setAttributes({
            'agent.method': propertyKey,
            'agent.args': JSON.stringify(args),
          });

          const result = await originalMethod.apply(this, args);
          
          // Add output attributes
          span.setAttributes({
            'agent.result': JSON.stringify(result),
          });
          
          span.setStatus({ code: SpanStatusCode.OK });
          return result;
        } catch (error: any) {
          span.recordException(error);
          span.setStatus({
            code: SpanStatusCode.ERROR,
            message: error.message,
          });
          throw error;
        } finally {
          span.end();
        }
      });
    };

    return descriptor;
  };
}

// Helper to create custom spans
export function createSpan(name: string, fn: (span: any) =&gt; Promise<any>) {
  const tracer = trace.getTracer('ai-agent');
  
  return tracer.startActiveSpan(name, async (span) =&gt; {
    try {
      const result = await fn(span);
      span.setStatus({ code: SpanStatusCode.OK });
      return result;
    } catch (error: any) {
      span.recordException(error);
      span.setStatus({
        code: SpanStatusCode.ERROR,
        message: error.message,
      });
      throw error;
    } finally {
      span.end();
    }
  });
}
```

Create `agent/src/logging.ts`:
```typescript
import winston from 'winston';
import { trace, context } from '@opentelemetry/api';

// Custom format to include trace context
const traceFormat = winston.format((info) =&gt; {
  const span = trace.getActiveSpan();
  if (span) {
    const spanContext = span.spanContext();
    info.traceId = spanContext.traceId;
    info.spanId = spanContext.spanId;
  }
  return info;
});

// Create logger with structured logging
export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    traceFormat(),
    winston.format.json()
  ),
  defaultMeta: {
    service: 'ai-agent',
    version: process.env.APP_VERSION || '1.0.0',
    environment: process.env.NODE_ENV || 'production',
    hostname: process.env.HOSTNAME,
    pid: process.pid,
  },
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      ),
    }),
  ],
});

// Add contextual logging
export function createContextLogger(context: Record<string, any>) {
  return logger.child(context);
}

// Structured logging helpers
export const logEvent = {
  agentStarted: (agentId: string) =&gt; {
    logger.info('Agent started', {
      event: 'agent_started',
      agentId,
    });
  },
  
  taskReceived: (taskId: string, taskType: string) =&gt; {
    logger.info('Task received', {
      event: 'task_received',
      taskId,
      taskType,
    });
  },
  
  taskCompleted: (taskId: string, duration: number, result: any) =&gt; {
    logger.info('Task completed', {
      event: 'task_completed',
      taskId,
      duration,
      resultSize: JSON.stringify(result).length,
    });
  },
  
  taskFailed: (taskId: string, error: Error) =&gt; {
    logger.error('Task failed', {
      event: 'task_failed',
      taskId,
      error: error.message,
      stack: error.stack,
    });
  },
  
  modelInference: (modelName: string, duration: number, tokens: number) =&gt; {
    logger.info('Model inference completed', {
      event: 'model_inference',
      modelName,
      duration,
      tokens,
      tokensPerSecond: tokens / duration,
    });
  },
};
```

### Step 2: Create Prometheus Configuration

Create `monitoring/prometheus/prometheus.yaml`:
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'production'
    region: 'us-east-1'

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

# Load rules
rule_files:
  - "/etc/prometheus/rules/*.yaml"

# Scrape configurations
scrape_configs:
  # AI Agent metrics
  - job_name: 'ai-agents'
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
            - agent-system
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: kubernetes_pod_name

  # Kubernetes API server
  - job_name: 'kubernetes-apiservers'
    kubernetes_sd_configs:
      - role: endpoints
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
      - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
        action: keep
        regex: default;kubernetes;https

  # Node metrics
  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
      - role: node
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
```

Create `monitoring/prometheus/rules/agent-alerts.yaml`:
```yaml
groups:
  - name: agent_alerts
    interval: 30s
    rules:
      # High error rate
      - alert: AgentHighErrorRate
        expr: |
          (
            sum(rate(agent_errors_total[5m])) by (job)
            /
            sum(rate(agent_tasks_total[5m])) by (job)
          ) &gt; 0.05
        for: 5m
        labels:
          severity: warning
          team: ai-platform
        annotations:
          summary: "High error rate on {{ $labels.job }}"
          description: "Error rate is {{ $value | humanizePercentage }} for {{ $labels.job }}"
          runbook_url: "https://wiki.company.com/runbooks/agent-error-rate"

      # Agent down
      - alert: AgentDown
        expr: up{job="ai-agents"} == 0
        for: 2m
        labels:
          severity: critical
          team: ai-platform
        annotations:
          summary: "Agent {{ $labels.instance }} is down"
          description: "Agent {{ $labels.instance }} has been down for more than 2 minutes"

      # High latency
      - alert: AgentHighLatency
        expr: |
          histogram_quantile(0.95,
            sum(rate(agent_task_duration_seconds_bucket[5m])) by (le, job)
          ) &gt; 5
        for: 10m
        labels:
          severity: warning
          team: ai-platform
        annotations:
          summary: "High latency on {{ $labels.job }}"
          description: "95th percentile latency is {{ $value }}s for {{ $labels.job }}"

      # Queue backup
      - alert: AgentQueueBackup
        expr: agent_queue_size &gt; 100
        for: 5m
        labels:
          severity: warning
          team: ai-platform
        annotations:
          summary: "Agent queue backing up"
          description: "Queue size is {{ $value }} for {{ $labels.job }}"

      # Model inference slow
      - alert: ModelInferenceSlow
        expr: |
          histogram_quantile(0.99,
            sum(rate(model_inference_latency_seconds_bucket[5m])) by (le, model_name)
          ) &gt; 2
        for: 5m
        labels:
          severity: warning
          team: ai-platform
        annotations:
          summary: "Model {{ $labels.model_name }} inference is slow"
          description: "99th percentile inference time is {{ $value }}s"

      # Pod restart
      - alert: AgentPodRestartingTooOften
        expr: |
          increase(kube_pod_container_status_restarts_total{namespace="agent-system"}[1h]) &gt; 5
        labels:
          severity: warning
          team: ai-platform
        annotations:
          summary: "Pod {{ $labels.pod }} restarting frequently"
          description: "Pod has restarted {{ $value }} times in the last hour"

  - name: slo_alerts
    interval: 30s
    rules:
      # SLO: 99.9% availability
      - alert: AgentAvailabilitySLO
        expr: |
          (
            1 - (
              sum(rate(http_requests_total{status_code=~"5.."}[5m]))
              /
              sum(rate(http_requests_total[5m]))
            )
          ) &lt; 0.999
        for: 5m
        labels:
          severity: critical
          team: ai-platform
          slo: availability
        annotations:
          summary: "Agent availability SLO breach"
          description: "Availability is {{ $value | humanizePercentage }}, below 99.9% SLO"

      # SLO: 95% of requests under 1s
      - alert: AgentLatencySLO
        expr: |
          (
            sum(rate(http_request_duration_seconds_bucket{le="1"}[5m]))
            /
            sum(rate(http_request_duration_seconds_count[5m]))
          ) &lt; 0.95
        for: 5m
        labels:
          severity: warning
          team: ai-platform
          slo: latency
        annotations:
          summary: "Agent latency SLO breach"
          description: "Only {{ $value | humanizePercentage }} of requests under 1s"
```

### Step 3: Create Grafana Painels

Create `monitoring/grafana/dashboards/agent-overview.json`:
```json
{
  "dashboard": {
    "title": "AI Agent Overview",
    "uid": "agent-overview",
    "tags": ["ai-agent", "production"],
    "timezone": "browser",
    "schemaVersion": 38,
    "version": 1,
    "panels": [
      {
        "title": "Request Rate",
        "gridPos": {{ "h": 8, "w": 8, "x": 0, "y": 0 }},
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total[5m])) by (method)",
            "legendFormat": "{{{{ method }}}}"
          }
        ],
        "yaxes": [{{ "format": "reqps", "label": "Requests/sec" }}]
      },
      {
        "title": "Error Rate",
        "gridPos": {{ "h": 8, "w": 8, "x": 8, "y": 0 }},
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{{status_code=~\"5..\"}}[5m])) / sum(rate(http_requests_total[5m]))",
            "legendFormat": "Error Rate"
          }
        ],
        "yaxes": [{{ "format": "percentunit", "label": "Error %" }}],
        "thresholds": [
          {{ "value": 0.01, "color": "yellow" }},
          {{ "value": 0.05, "color": "red" }}
        ]
      },
      {
        "title": "Request Duration (p95)",
        "gridPos": {{ "h": 8, "w": 8, "x": 16, "y": 0 }},
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))",
            "legendFormat": "p95"
          }
        ],
        "yaxes": [{{ "format": "s", "label": "Duration" }}]
      },
      {
        "title": "Agent Task Processing",
        "gridPos": {{ "h": 8, "w": 12, "x": 0, "y": 8 }},
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(agent_tasks_total[5m])) by (task_type, status)",
            "legendFormat": "{{{{ task_type }}}} - {{{{ status }}}}"
          }
        ]
      },
      {
        "title": "Active Tasks",
        "gridPos": {{ "h": 8, "w": 12, "x": 12, "y": 8 }},
        "type": "graph",
        "targets": [
          {
            "expr": "sum(agent_active_tasks) by (task_type)",
            "legendFormat": "{{{{ task_type }}}}"
          }
        ]
      },
      {
        "title": "Model Inference Latency",
        "gridPos": {{ "h": 8, "w": 12, "x": 0, "y": 16 }},
        "type": "heatmap",
        "targets": [
          {
            "expr": "sum(rate(model_inference_latency_seconds_bucket[5m])) by (le)",
            "format": "heatmap"
          }
        ]
      },
      {
        "title": "Resource Usage",
        "gridPos": {{ "h": 8, "w": 12, "x": 12, "y": 16 }},
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(container_cpu_usage_seconds_total{{namespace=\"agent-system\"}}[5m])) by (pod)",
            "legendFormat": "CPU {{{{ pod }}}}"
          },
          {
            "expr": "sum(container_memory_usage_bytes{{namespace=\"agent-system\"}}) by (pod) / 1024 / 1024 / 1024",
            "legendFormat": "Memory {{{{ pod }}}}",
            "yaxis": 2
          }
        ],
        "yaxes": [
          {{ "format": "percentunit", "label": "CPU" }},
          {{ "format": "gbytes", "label": "Memory" }}
        ]
      }
    ]
  }
}
```

Create `monitoring/grafana/dashboards/agent-slo.json`:
```json
{
  "dashboard": {
    "title": "AI Agent SLO Dashboard",
    "uid": "agent-slo",
    "tags": ["ai-agent", "slo"],
    "panels": [
      {
        "title": "Availability SLO (99.9%)",
        "type": "stat",
        "gridPos": {{ "h": 8, "w": 8, "x": 0, "y": 0 }},
        "targets": [
          {
            "expr": "1 - (sum(rate(http_requests_total{{status_code=~\"5..\"}}[30d])) / sum(rate(http_requests_total[30d])))"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percentunit",
            "thresholds": {
              "steps": [
                {{ "value": 0.999, "color": "green" }},
                {{ "value": 0.995, "color": "yellow" }},
                {{ "value": 0, "color": "red" }}
              ]
            }
          }
        }
      },
      {
        "title": "Latency SLO (95% &lt; 1s)",
        "type": "stat",
        "gridPos": {{ "h": 8, "w": 8, "x": 8, "y": 0 }},
        "targets": [
          {
            "expr": "sum(rate(http_request_duration_seconds_bucket{{le=\"1\"}}[30d])) / sum(rate(http_request_duration_seconds_count[30d]))"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percentunit",
            "thresholds": {
              "steps": [
                {{ "value": 0.95, "color": "green" }},
                {{ "value": 0.90, "color": "yellow" }},
                {{ "value": 0, "color": "red" }}
              ]
            }
          }
        }
      },
      {
        "title": "Error Budget Remaining",
        "type": "gauge",
        "gridPos": {{ "h": 8, "w": 8, "x": 16, "y": 0 }},
        "targets": [
          {
            "expr": "(0.001 - (sum(increase(http_requests_total{{status_code=~\"5..\"}}[30d])) / sum(increase(http_requests_total[30d])))) / 0.001"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "percentunit",
            "min": 0,
            "max": 1,
            "thresholds": {
              "steps": [
                {{ "value": 0, "color": "red" }},
                {{ "value": 0.2, "color": "yellow" }},
                {{ "value": 0.5, "color": "green" }}
              ]
            }
          }
        }
      }
    ]
  }
}
```

### Step 4: Configure Alerts

Create `monitoring/alertmanager/config.yaml`:
```yaml
global:
  resolve_timeout: 5m
  slack_api_url: 'YOUR_SLACK_WEBHOOK_URL'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'default'
  routes:
    - match:
        severity: critical
      receiver: 'critical'
      continue: true
    - match:
        team: ai-platform
      receiver: 'ai-team'

receivers:
  - name: 'default'
    webhook_configs:
      - url: 'http://localhost:5001/webhook'

  - name: 'critical'
    pagerduty_configs:
      - service_key: 'YOUR_PAGERDUTY_SERVICE_KEY'
    slack_configs:
      - channel: '#alerts-critical'
        title: 'Critical Alert'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}\n{{ .Annotations.description }}{{ end }}'

  - name: 'ai-team'
    slack_configs:
      - channel: '#ai-platform-alerts'
        title: 'AI Platform Alert'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}\n{{ .Annotations.description }}{{ end }}'
        actions:
          - type: button
            text: 'Runbook'
            url: '{{ .Annotations.runbook_url }}'
          - type: button
            text: 'Dashboard'
            url: 'https://grafana.company.com/d/agent-overview'

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
```

### Step 5: Deploy Monitoring Stack

Create `monitoring/deploy-monitoring.sh`:
```bash
#!/bin/bash
set -e

echo "🚀 Deploying Monitoring Stack"

# Create monitoring namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Deploy Prometheus
echo "📊 Deploying Prometheus..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values monitoring/prometheus/values.yaml \
  --set prometheus.prometheusSpec.additionalScrapeConfigs="$(cat monitoring/prometheus/prometheus.yaml)" \
  --set prometheus.prometheusSpec.ruleSelector.matchLabels.prometheus=kube-prometheus \
  --wait

# Apply custom rules
kubectl apply -f monitoring/prometheus/rules/

# Deploy Jaeger
echo "🔍 Deploying Jaeger..."
helm upgrade --install jaeger jaegertracing/jaeger \
  --namespace monitoring \
  --set cassandra.config.max_heap_size=1024M \
  --set cassandra.config.heap_new_size=256M \
  --set query.enabled=true \
  --set collector.enabled=true \
  --set agent.enabled=false \
  --wait

# Deploy Loki
echo "📝 Deploying Loki..."
helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=10Gi \
  --set promtail.enabled=true \
  --wait

# Configure Grafana datasources
echo "📈 Configuring Grafana..."
kubectl apply -f - &lt;<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
  namespace: monitoring
data:
  datasources.yaml: |
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus-kube-prometheus-prometheus:9090
      access: proxy
      isDefault: true
    - name: Jaeger
      type: jaeger
      url: http://jaeger-query:16686
      access: proxy
    - name: Loki
      type: loki
      url: http://loki:3100
      access: proxy
EOF

# Import dashboards
for dashboard in monitoring/grafana/dashboards/*.json; do
  kubectl create configmap $(basename $dashboard .json)-dashboard \
    --from-file=$dashboard \
    --namespace monitoring \
    --dry-run=client -o yaml | kubectl apply -f -
done

echo "✅ Monitoring stack deployed!"
```

### Step 6: Verify Monitoring

Create `monitoring/verify-monitoring.sh`:
```bash
#!/bin/bash

echo "🔍 Verifying Monitoring Stack..."

# Check Prometheus
echo -e "\n📊 Prometheus:"
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus
PROM_POD=$(kubectl get pod -n monitoring -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}')

# Check targets
echo -e "\nPrometheus Targets:"
kubectl exec -n monitoring $PROM_POD -c prometheus -- wget -qO- http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'

# Check Grafana
echo -e "\n📈 Grafana:"
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

# Check Jaeger
echo -e "\n🔍 Jaeger:"
kubectl get pods -n monitoring -l app.kubernetes.io/name=jaeger

# Check AlertManager
echo -e "\n🚨 AlertManager:"
kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager

# Port forward for access
echo -e "\n🌐 Access URLs:"
echo "Prometheus: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "Jaeger: kubectl port-forward -n monitoring svc/jaeger-query 16686:16686"
echo "AlertManager: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093"
```

## 🏃 Running the Exercício

1. **Deploy the monitoring stack:**
```bash
chmod +x monitoring/*.sh
./monitoring/deploy-monitoring.sh
```

2. **Verify monitoring components:**
```bash
./monitoring/verify-monitoring.sh
```

3. **Access dashboards:**
```bash
# Terminal 1: Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Terminal 2: Grafana (admin/prom-operator)
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Terminal 3: Jaeger
kubectl port-forward -n monitoring svc/jaeger-query 16686:16686
```

4. **Generate test load:**
```bash
# Create load generator
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh

# Generate load
while true; do
  wget -q -O- http://ai-agent-service.agent-system/api/v1/process \
    --post-data='{"task":"test","data":{}}'
  sleep 0.5
done
```

5. **Trigger alerts:**
```bash
# Simulate high error rate
for i in {\`1..100\`}; do
  curl -X POST http://localhost:8080/api/v1/process \
    -H "Content-Type: application/json" \
    -d '{"trigger_error": true}'
done
```

## 🎯 Validation

Your monitoring system should now have:
- ✅ Prometheus collecting metrics from all agents
- ✅ Grafana dashboards showing system health
- ✅ Distributed tracing with Jaeger
- ✅ Log aggregation with Loki
- ✅ Alert rules configurado and firing
- ✅ SLO tracking and error budgets
- ✅ Custom business metrics
- ✅ Correlation between metrics, logs, and traces

## 📊 Key Metrics to Monitor

1. **Golden Signals:**
   - Latency (request duration)
   - Traffic (request rate)
   - Errors (error rate)
   - Saturation (resource usage)

2. **Agent-Specific:**
   - Task processing rate
   - Model inference latency
   - Queue depth
   - Token consumption

3. **Business Metrics:**
   - Revenue per task
   - User satisfaction
   - Task completion rate
   - SLA compliance

## 🚀 Bonus Challenges

1. **Add Custom Painels:**
   - Create role-specific views
   - Add mobile-responsive dashboards
   - Implement TV mode for NOC

2. **Avançado Alerting:**
   - Implement anomaly detection
   - Add predictive alerts
   - Create intelligent grouping

3. **Observability as Code:**
   - Generate dashboards from code
   - Automate alert rule creation
   - Versão control everything

4. **Multi-Cluster Monitoring:**
   - Federate Prometheus
   - Cross-region dashboards
   - Global alerting

## 📚 Additional Recursos

- [Prometheus Melhores Práticas](https://prometheus.io/docs/practices/)
- [Grafana Painel Guia](https://grafana.com/docs/grafana/latest/dashboards/)
- [Distributed Tracing](https://opentracing.io/docs/)
- [SRE Workbook](https://sre.google/workbook/)

## ⏭️ Próximo Exercício

Ready for the ultimate challenge? Move on to [Exercício 3: Disaster Recovery System](/docs/modules/module-25/exercise3-overview) where you'll implement automated backup and recovery!