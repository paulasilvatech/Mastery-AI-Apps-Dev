# Module 12: Cloud-Native Development Troubleshooting Guide

## 🐳 Docker Issues

### Container Build Failures

#### Problem: "no space left on device"
```bash
# Solution 1: Clean up Docker system
docker system prune -a --volumes

# Solution 2: Increase Docker Desktop disk space
# Docker Desktop > Settings > Resources > Disk image size

# Solution 3: Remove specific large images
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | sort -k 3 -h
docker rmi <large-image-id>
```

#### Problem: "Cannot connect to the Docker daemon"
```bash
# Windows WSL2
wsl --shutdown
# Restart Docker Desktop

# Linux
sudo systemctl restart docker
sudo usermod -aG docker $USER
newgrp docker

# macOS
# Restart Docker Desktop from menu bar
```

#### Problem: Multi-stage build not working
```dockerfile
# Ensure you're using BuildKit
# Add to Dockerfile:
# syntax=docker/dockerfile:1

# Or enable BuildKit:
export DOCKER_BUILDKIT=1

# For Docker Compose:
export COMPOSE_DOCKER_CLI_BUILD=1
```

### Container Runtime Issues

#### Problem: Container exits immediately
```bash
# Debug with interactive shell
docker run -it --entrypoint /bin/sh <image>

# Check logs
docker logs <container-id>

# Common fix: Ensure process doesn't exit
# Wrong:
CMD ["python", "app.py"]

# Right:
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0"]
```

#### Problem: Health check always failing
```python
# Debug health check
docker inspect <container> --format='{{json .State.Health}}'

# Test health check manually
docker exec <container> curl http://localhost:8000/health

# Common issues:
# 1. Service not ready during start period
# 2. Wrong port or path
# 3. Dependencies not available
```

## ☸️ Kubernetes Issues

### Cluster Connection Problems

#### Problem: "Unable to connect to the server"
```bash
# Check current context
kubectl config current-context

# List all contexts
kubectl config get-contexts

# Switch to correct context
kubectl config use-context aks-workshop-module12

# Re-authenticate with Azure
az aks get-credentials --resource-group rg-workshop-module12 --name aks-workshop-module12

# Verify connection
kubectl cluster-info
```

#### Problem: "error: You must be logged in to the server (Unauthorized)"
```bash
# Refresh AKS credentials
az aks get-credentials --resource-group <rg> --name <cluster> --overwrite-existing

# Check Azure login
az account show

# Re-login if needed
az login
```

### Pod Issues

#### Problem: Pod stuck in "Pending"
```bash
# Check pod events
kubectl describe pod <pod-name> -n production

# Common causes:
# 1. Insufficient resources
kubectl top nodes
kubectl describe nodes

# 2. Image pull errors
kubectl get events -n production --field-selector reason=Failed

# 3. PVC not bound
kubectl get pvc -n production
```

#### Problem: Pod keeps crashing (CrashLoopBackOff)
```bash
# Check logs
kubectl logs <pod-name> -n production --previous

# Check resource limits
kubectl describe pod <pod-name> -n production | grep -A 5 "Limits:"

# Interactive debugging
kubectl run debug --image=busybox -it --rm --restart=Never -- sh

# Copy failed pod for debugging
kubectl debug <pod-name> -n production -it --copy-to=debug-pod --container=<container>
```

#### Problem: "ImagePullBackOff"
```bash
# Check ACR connection
az aks check-acr --resource-group <rg> --name <cluster> --acr <acr-name>

# Verify image exists
az acr repository show --name <acr-name> --image product-catalog:latest

# Check pull secrets
kubectl get secrets -n production
kubectl describe secret <pull-secret> -n production

# Re-attach ACR to AKS
az aks update --resource-group <rg> --name <cluster> --attach-acr <acr-resource-id>
```

### Service and Networking Issues

#### Problem: Service not accessible
```bash
# Check service endpoints
kubectl get endpoints -n production

# Test service internally
kubectl run curl --image=curlimages/curl -it --rm --restart=Never -- curl http://product-catalog-service.production/health

# Check service selector matches pod labels
kubectl get pods -n production --show-labels
kubectl get svc product-catalog-service -n production -o yaml | grep selector -A 2
```

#### Problem: Ingress not working
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress status
kubectl get ingress -n production
kubectl describe ingress product-catalog-ingress -n production

# Test with port-forward
kubectl port-forward -n production svc/product-catalog-service 8080:80

# Check DNS
nslookup api.product-catalog.example.com
```

## ⚡ Azure Functions Issues

### Deployment Problems

#### Problem: "Function app not found"
```bash
# Check function app exists
az functionapp list --resource-group <rg> --query "[].name"

# Check deployment status
func azure functionapp publish <app-name> --python

# Enable detailed logging
func azure functionapp publish <app-name> --python --build remote --verbose
```

#### Problem: "Module not found" errors
```python
# Ensure requirements.txt is complete
pip freeze > requirements.txt

# For local imports, check PYTHONPATH
# In function.json:
{
  "scriptFile": "__init__.py",
  "entryPoint": "main",
  "pythonPath": "."
}

# Project structure should be:
FunctionName/
├── __init__.py
├── function.json
shared/
├── __init__.py
├── models.py
```

### Runtime Issues

#### Problem: Function not triggering
```bash
# Check function status
az functionapp function show --resource-group <rg> --name <app> --function-name <function>

# Check bindings in function.json
{
  "bindings": [
    {
      "type": "eventGridTrigger",
      "name": "event",
      "direction": "in"
    }
  ]
}

# Verify Event Grid subscription
az eventgrid event-subscription list --source-resource-id <topic-resource-id>
```

#### Problem: "Azure.Core.AmqpException" with Service Bus
```python
# Check connection string
print(os.environ.get('SERVICE_BUS_CONNECTION_STRING'))

# Verify queue exists
from azure.servicebus.management import ServiceBusAdministrationClient
admin = ServiceBusAdministrationClient.from_connection_string(conn_str)
queues = list(admin.list_queues())

# Common fix: Ensure connection string has EntityPath
# Wrong: Endpoint=sb://namespace.servicebus.windows.net/;...
# Right: Endpoint=sb://namespace.servicebus.windows.net/;...;EntityPath=queue-name
```

### Performance Issues

#### Problem: Function cold starts are slow
```python
# Solution 1: Premium plan
az functionapp plan create --name <plan> --resource-group <rg> --sku EP1

# Solution 2: Pre-warm dependencies
# At module level (outside function):
import azure.cosmos
import azure.servicebus

cosmos_client = None

def get_cosmos_client():
    global cosmos_client
    if not cosmos_client:
        cosmos_client = CosmosClient.from_connection_string(...)
    return cosmos_client

# Solution 3: Always On for App Service Plan
az functionapp config set --name <app> --resource-group <rg> --always-on true
```

## 🔧 Integration Issues

### Event Grid Problems

#### Problem: Events not being delivered
```bash
# Check dead letter events
az eventgrid event-subscription show --name <sub-name> --source-resource-id <topic-id> --include-full-endpoint-url

# Monitor metrics
az monitor metrics list --resource <topic-resource-id> --metric "DeliverySuccessCount,DeliveryAttemptFailCount"

# Test with Azure CLI
az eventgrid topic event publish --topic-name <topic> -g <rg> --subject "test" --data '{"test": "data"}'
```

#### Problem: "Webhook validation handshake failed"
```python
# Implement validation in your function
import json

async def main(req: func.HttpRequest) -> func.HttpResponse:
    # Handle validation
    if req.get_json().get('validationCode'):
        validation_code = req.get_json()['validationCode']
        return func.HttpResponse(
            json.dumps({'validationResponse': validation_code}),
            mimetype='application/json'
        )
    
    # Handle actual events
    # ...
```

### Cosmos DB Issues

#### Problem: "Request rate is large"
```python
# Solution 1: Increase RU/s
az cosmosdb sql container throughput update --resource-group <rg> --account-name <account> --database-name <db> --name <container> --throughput 1000

# Solution 2: Implement retry logic
from azure.cosmos.exceptions import CosmosHttpResponseError
import time

@retry(stop_max_attempt_number=3, wait_exponential_multiplier=1000)
def write_with_retry(container, document):
    try:
        return container.create_item(body=document)
    except CosmosHttpResponseError as e:
        if e.status_code == 429:  # Too Many Requests
            time.sleep(e.headers['x-ms-retry-after-ms'] / 1000)
            raise
        raise
```

#### Problem: "Cross partition query is required but disabled"
```python
# Enable cross-partition queries
results = container.query_items(
    query="SELECT * FROM c WHERE c.category = @category",
    parameters=[{"name": "@category", "value": "electronics"}],
    enable_cross_partition_query=True  # Add this
)
```

## 📊 Monitoring and Debugging

### Application Insights Issues

#### Problem: No telemetry data appearing
```python
# Verify connection string
print(os.environ.get('APPLICATION_INSIGHTS_KEY'))

# Force flush telemetry
from applicationinsights import TelemetryClient
tc = TelemetryClient(instrumentation_key)
tc.track_event('TestEvent')
tc.flush()

# Check sampling rate
# In host.json:
{
  "logging": {
    "applicationInsights": {
      "samplingSettings": {
        "isEnabled": true,
        "maxTelemetryItemsPerSecond": 20,
        "excludedTypes": "Request"
      }
    }
  }
}
```

### Log Stream Issues

#### Problem: Logs not appearing
```bash
# Enable application logging
az webapp log config --name <app> --resource-group <rg> --application-logging filesystem --level information

# Stream logs
az webapp log tail --name <app> --resource-group <rg>

# For Functions
func azure functionapp logstream <app-name>

# Check Log Analytics
az monitor log-analytics query --workspace <workspace-id> --analytics-query "traces | where message contains 'error'"
```

## 🚨 Emergency Procedures

### Rollback Deployment
```bash
# Kubernetes rollback
kubectl rollout undo deployment/product-catalog -n production
kubectl rollout status deployment/product-catalog -n production

# Check rollout history
kubectl rollout history deployment/product-catalog -n production
```

### Circuit Breaker Tripped
```python
# Reset circuit breaker
from circuitbreaker import CircuitBreakerError

try:
    result = await call_service()
except CircuitBreakerError:
    # Circuit is open, service is down
    logger.error("Circuit breaker is open")
    # Manual reset if needed
    circuit_breaker.reset()
```

### Resource Cleanup
```bash
# Emergency cleanup script
#!/bin/bash
RESOURCE_GROUP="rg-workshop-module12"

# Stop all services
kubectl scale deployment --all --replicas=0 -n production

# Delete expensive resources
az aks stop --resource-group $RESOURCE_GROUP --name aks-workshop-module12
az cosmosdb delete --resource-group $RESOURCE_GROUP --name <cosmos-account> --yes

# Full cleanup (careful!)
# az group delete --name $RESOURCE_GROUP --yes --no-wait
```

## 💡 Prevention Tips

1. **Always use resource limits** in Kubernetes to prevent resource exhaustion
2. **Implement health checks** at every layer
3. **Use structured logging** for easier debugging
4. **Set up alerts** for critical metrics
5. **Practice chaos engineering** to find issues early
6. **Document your runbooks** for common issues
7. **Use staging environments** for testing
8. **Implement feature flags** for safe rollouts

## 📞 Getting Help

1. Check Azure service health: https://status.azure.com
2. Review GitHub issues for known problems
3. Use Azure Support if you have a support plan
4. Community forums:
   - Stack Overflow (tag: azure-aks, azure-functions)
   - Microsoft Q&A
   - Reddit r/AZURE

Remember: Most issues have been encountered before. Search error messages and check documentation before panic sets in!