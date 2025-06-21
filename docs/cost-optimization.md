# Cost Optimization Guide

This guide helps you minimize costs while maximizing learning value throughout the Mastery AI Code Development Workshop.

## 💰 Cost Overview

### Estimated Monthly Costs by Track

| Track | Modules | Estimated Cost | Key Services |
|-------|---------|---------------|--------------|
| Fundamentals | 1-5 | $5-10 | Basic compute, storage |
| Intermediate | 6-10 | $10-25 | Web apps, databases |
| Advanced | 11-15 | $25-50 | AKS, multiple services |
| Enterprise | 16-20 | $50-100 | Full enterprise stack |
| AI Agents | 21-25 | $30-60 | AI services, compute |
| Mastery | 26-30 | $50-100 | Comprehensive setup |

## 🎯 Free Tier Optimization

### Azure Free Account Benefits
- $200 credit for first 30 days
- 12 months of free services
- Always free services

### Always Free Services
```yaml
Storage Account: 5GB LRS
App Service: 10 web apps (F1 tier)
Functions: 1M executions/month
Cosmos DB: 1000 RU/s, 25GB storage
AI Services: Limited free calls
```

### Module-Specific Free Tier Usage
```bash
# Modules 1-5: Stay within free tier
az webapp create --name myapp --plan free-plan --runtime "PYTHON|3.11"

# Modules 6-10: Use B1 tier during exercises only
az appservice plan update --name myplan --sku B1
# Remember to scale down after exercises!
az appservice plan update --name myplan --sku F1
```

## 📊 Cost Monitoring

### Setting Up Cost Alerts
```bash
# Create budget alert
az consumption budget create \
  --amount 50 \
  --budget-name "workshop-budget" \
  --category Cost \
  --time-grain Monthly \
  --start-date 2025-01-01 \
  --end-date 2025-12-31 \
  --threshold 80 90 100 \
  --contact-emails your-email@example.com
```

### Cost Analysis Dashboard
```python
# Module 19: Cost tracking script
from azure.mgmt.consumption import ConsumptionManagementClient
from datetime import datetime, timedelta

def get_daily_costs(subscription_id):
    # Get costs for last 7 days
    end_date = datetime.now()
    start_date = end_date - timedelta(days=7)
    
    query = {
        "type": "Usage",
        "timeframe": "Custom",
        "time_period": {
            "from": start_date.isoformat(),
            "to": end_date.isoformat()
        },
        "dataset": {
            "granularity": "Daily",
            "aggregation": {
                "totalCost": {
                    "name": "Cost",
                    "function": "Sum"
                }
            }
        }
    }
    return consumption_client.query.usage(scope, query)
```

## 🔧 Resource Optimization

### Compute Optimization

#### Development/Testing
```bash
# Use spot instances for non-critical workloads
az vm create \
  --name dev-vm \
  --priority Spot \
  --max-price 0.05 \
  --eviction-policy Deallocate
```

#### Auto-shutdown Policies
```json
{
  "properties": {
    "status": "Enabled",
    "dailyRecurrence": {
      "time": "1900"
    },
    "timeZoneId": "UTC",
    "notificationSettings": {
      "status": "Disabled"
    }
  }
}
```

### Storage Optimization

#### Lifecycle Management
```json
{
  "rules": [
    {
      "name": "archive-old-logs",
      "type": "Lifecycle",
      "definition": {
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["logs/"]
        },
        "actions": {
          "baseBlob": {
            "tierToArchive": {
              "daysAfterModificationGreaterThan": 30
            },
            "delete": {
              "daysAfterModificationGreaterThan": 90
            }
          }
        }
      }
    }
  ]
}
```

### Database Optimization

#### Serverless Options
```python
# Cosmos DB serverless for modules 9-15
cosmos_client = CosmosClient(
    url=endpoint,
    credential=key,
    consistency_level='Session'
)

database = cosmos_client.create_database_if_not_exists(
    id='workshop-db',
    offer_throughput=None  # Serverless mode
)
```

## 🚀 AI Services Cost Control

### OpenAI/Azure OpenAI
```python
# Implement token limits
def limited_completion(prompt, max_tokens=100):
    try:
        response = openai.Completion.create(
            engine="gpt-35-turbo",
            prompt=prompt,
            max_tokens=max_tokens,
            temperature=0.7
        )
        return response.choices[0].text
    except RateLimitError:
        time.sleep(60)  # Wait before retry
        return limited_completion(prompt, max_tokens)
```

### Caching AI Responses
```python
# Module 22-25: Cache expensive AI calls
import hashlib
from azure.cosmos import CosmosClient

def get_cached_response(prompt):
    prompt_hash = hashlib.md5(prompt.encode()).hexdigest()
    
    # Check cache first
    cached = cache_container.read_item(
        item=prompt_hash,
        partition_key=prompt_hash
    )
    
    if cached and not is_expired(cached):
        return cached['response']
    
    # Generate new response
    response = generate_ai_response(prompt)
    
    # Cache for 24 hours
    cache_container.upsert_item({
        'id': prompt_hash,
        'prompt': prompt,
        'response': response,
        'timestamp': datetime.utcnow().isoformat(),
        'ttl': 86400
    })
    
    return response
```

## 📅 Module-by-Module Cost Tips

### Modules 1-5 (Fundamentals)
- Use local development primarily
- Deploy to free tier only for testing
- Clean up resources after each module

### Modules 6-10 (Intermediate)
- Share resources between exercises
- Use SQLite for development, Azure SQL free tier for deployment
- Implement connection pooling

### Modules 11-15 (Advanced)
- Use AKS dev/test pricing
- Single node clusters for learning
- Spot instances for worker nodes

### Modules 16-20 (Enterprise)
- Time-box enterprise features testing
- Use dev/test subscriptions
- Implement aggressive auto-scaling policies

### Modules 21-25 (AI Agents)
- Batch AI requests
- Use smaller models for development
- Implement request throttling

## 🧹 Cleanup Scripts

### Daily Cleanup
```bash
#!/bin/bash
# cleanup-daily.sh

# Stop all App Services
az webapp list --query "[].name" -o tsv | \
  xargs -I {} az webapp stop --name {}

# Deallocate VMs
az vm list --query "[].name" -o tsv | \
  xargs -I {} az vm deallocate --name {}

# Scale down AKS
az aks scale --name workshop-aks \
  --node-count 0 \
  --nodepool-name nodepool1
```

### Module Cleanup
```bash
# Run after completing each module
./scripts/cleanup-resources.sh --module $MODULE_NUMBER
```

## 💡 Pro Tips

1. **Resource Groups**: Use one per module for easy cleanup
2. **Tags**: Tag everything for cost tracking
3. **Schedules**: Automate start/stop for resources
4. **Monitoring**: Check costs daily
5. **Alerts**: Set up budget alerts at 50%, 80%, 100%

## 📈 Cost Tracking Template

```excel
| Date | Module | Service | Cost | Notes |
|------|--------|---------|------|-------|
| 2025-01-20 | 1 | App Service | $0.50 | Free tier |
| 2025-01-21 | 2 | Storage | $0.10 | Minimal usage |
| 2025-01-22 | 3 | Cosmos DB | $0.00 | Free tier |
```

## 🎓 Educational Discounts

- **Azure for Students**: $100 credit, no credit card
- **GitHub Student Pack**: Free GitHub Copilot
- **Visual Studio Dev Essentials**: $200 Azure credit
- **Microsoft Learn Sandbox**: Free temporary resources

Remember: The goal is learning, not spending. Always clean up resources after each session!
