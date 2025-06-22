# Monitoring Module

This module implements comprehensive monitoring and observability for the Mastery AI Workshop.

## Resources Created

- Log Analytics Workspace
- Application Insights
- Azure Monitor Alerts
- Dashboards
- Action Groups
- Diagnostic Settings

## Usage

```hcl
module "monitoring" {
  source = "../../modules/monitoring"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  environment        = var.environment
  project_name       = var.project_name
  
  log_analytics_config = {
    sku               = "PerGB2018"
    retention_in_days = 30
    daily_quota_gb    = 5
  }
  
  application_insights_config = {
    application_type = "web"
    retention_in_days = 90
    disable_ip_masking = false
  }
  
  alerts = {
    high_cpu = {
      description = "Alert when CPU usage is high"
      severity    = 2
      frequency   = 5
      window_size = 5
      query       = <<-EOT
        Perf
        | where ObjectName == "Processor" and CounterName == "% Processor Time"
        | summarize avg(CounterValue) by bin(TimeGenerated, 5m)
        | where avg_CounterValue > 80
      EOT
      threshold   = 0
      operator    = "GreaterThan"
    }
    
    error_rate = {
      description = "Alert on high error rate"
      severity    = 1
      frequency   = 5
      window_size = 10
      query       = <<-EOT
        requests
        | where success == false
        | summarize errorRate = count() by bin(timestamp, 5m)
        | where errorRate > 10
      EOT
      threshold   = 0
      operator    = "GreaterThan"
    }
  }
  
  action_groups = {
    email = {
      short_name = "email"
      email_receivers = [
        {
          name          = "DevOps Team"
          email_address = "devops@example.com"
        }
      ]
    }
    
    webhook = {
      short_name = "webhook"
      webhook_receivers = [
        {
          name        = "Slack"
          service_uri = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
        }
      ]
    }
  }
  
  enable_diagnostics = true
  enable_metrics     = true
  
  tags = var.tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| resource_group_name | Name of the resource group | string | n/a | yes |
| location | Azure region | string | n/a | yes |
| environment | Environment name | string | n/a | yes |
| project_name | Project name | string | n/a | yes |
| log_analytics_config | Log Analytics configuration | object | n/a | yes |
| application_insights_config | Application Insights configuration | object | n/a | yes |
| alerts | Alert rules configuration | map(object) | {} | no |
| action_groups | Action groups for alerts | map(object) | {} | no |
| enable_diagnostics | Enable diagnostic logs | bool | true | no |
| enable_metrics | Enable metrics collection | bool | true | no |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| log_analytics_workspace_id | Log Analytics workspace ID |
| log_analytics_workspace_key | Log Analytics workspace key |
| application_insights_id | Application Insights ID |
| instrumentation_key | Application Insights instrumentation key |
| connection_string | Application Insights connection string |
| alert_rule_ids | Map of alert rule IDs |
| action_group_ids | Map of action group IDs |

## Monitoring Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Azure Monitor                           │
│                                                          │
│  ┌─────────────────┐  ┌─────────────────┐              │
│  │  Log Analytics  │  │   Application   │              │
│  │   Workspace     │  │    Insights     │              │
│  └────────┬────────┘  └────────┬────────┘              │
│           │                     │                        │
│           └──────────┬──────────┘                       │
│                      │                                   │
│            ┌─────────▼─────────┐                        │
│            │   Alert Rules     │                        │
│            └─────────┬─────────┘                        │
│                      │                                   │
│            ┌─────────▼─────────┐                        │
│            │  Action Groups    │                        │
│            └───────────────────┘                        │
└─────────────────────────────────────────────────────────┘
```

## Key Metrics Tracked

### Application Performance
- Response time (P50, P95, P99)
- Request rate
- Failure rate
- Dependency performance
- Custom business metrics

### Infrastructure Health
- CPU utilization
- Memory usage
- Disk I/O
- Network throughput
- Container metrics

### Security Monitoring
- Failed authentication attempts
- Suspicious activities
- Resource access patterns
- Configuration changes

## Alert Strategies

### Severity Levels
- **Sev 0**: Critical - Immediate action required
- **Sev 1**: Error - Urgent attention needed
- **Sev 2**: Warning - Investigate soon
- **Sev 3**: Informational - Review when possible

### Alert Channels
1. **Email**: Primary notification method
2. **SMS**: Critical alerts only
3. **Webhook**: Integration with Slack/Teams
4. **ITSM**: ServiceNow/Jira integration
5. **Logic Apps**: Custom workflows

## Dashboard Examples

### Application Dashboard
- Real-time request metrics
- Error analysis
- Performance trends
- User activity patterns

### Infrastructure Dashboard
- Resource utilization
- Cost tracking
- Scaling metrics
- Health status

### Security Dashboard
- Access patterns
- Threat detection
- Compliance status
- Audit trails

## Best Practices

1. **Data Retention**: Balance cost vs compliance requirements
2. **Alert Fatigue**: Avoid too many low-priority alerts
3. **Sampling**: Use intelligent sampling for high-volume apps
4. **Custom Metrics**: Track business-specific KPIs
5. **Correlation**: Link logs, metrics, and traces
6. **Automation**: Auto-remediation for common issues
