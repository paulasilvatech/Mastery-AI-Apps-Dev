---
sidebar_position: 5
title: "Exercise 2: Part 2"
description: "## 🌐 Part 3: Service and Ingress Configuration"
---

# Ejercicio 2: Deploy to Kubernetes with AKS ⭐⭐ (Partee 2)

## 🌐 Partee 3: Service and Ingress Configuration

### Step 6: Create Service Manifest

**Copilot Prompt Suggestion:**
```yaml
# Create kubernetes/03-service.yaml with:
# - ClusterIP service for internal communication
# - Proper port configuration
# - Session affinity if needed
# - Service monitoring annotations
```

**Expected Output:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: product-catalog-service
  namespace: production
  labels:
    app: product-catalog
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-internal: "false"
spec:
  type: ClusterIP
  selector:
    app: product-catalog
  ports:
  - name: http
    port: 80
    targetPort: http
    protocol: TCP
  - name: metrics
    port: 9090
    targetPort: metrics
    protocol: TCP
  sessionAffinity: None
```

### Step 7: Configure Ingress

**Copilot Prompt Suggestion:**
```yaml
# Create kubernetes/04-ingress.yaml with:
# - NGINX ingress controller configuration
# - TLS termination
# - Rate limiting annotations
# - URL rewriting rules
# - CORS configuration
```

**Expected Output:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: product-catalog-ingress
  namespace: production
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/rate-limit-burst: "200"
    nginx.ingress.kubernetes.io/limit-rps: "20"
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "60"
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, PUT, DELETE, OPTIONS"
    nginx.ingress.kubernetes.io/cors-allow-headers: "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - api.product-catalog.example.com
    secretName: product-catalog-tls
  rules:
  - host: api.product-catalog.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: product-catalog-service
            port:
              number: 80
```

### Step 8: Install NGINX Ingress Controller

**Copilot Prompt Suggestion:**
```bash
# Create script to install NGINX ingress controller with:
# - Helm chart installation
# - Azure-specific configurations
# - Prometheus metrics enabled
# - Custom resource limits
# File: scripts/install-ingress.sh
```

**Expected Output:**
```bash
#!/bin/bash
set -euo pipefail

echo "Installing NGINX Ingress Controller..."

# Add ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Create ingress-nginx namespace
kubectl create namespace ingress-nginx || true

# Install NGINX Ingress Controller
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  --set controller.metrics.enabled=true \
  --set controller.metrics.serviceMonitor.enabled=true \
  --set controller.resources.requests.cpu=100m \
  --set controller.resources.requests.memory=256Mi \
  --set controller.resources.limits.cpu=500m \
  --set controller.resources.limits.memory=512Mi \
  --set controller.autoscaling.enabled=true \
  --set controller.autoscaling.minReplicas=2 \
  --set controller.autoscaling.maxReplicas=5 \
  --set controller.autoscaling.targetCPUUtilizationPercentage=80 \
  --set controller.autoscaling.targetMemoryUtilizationPercentage=80

# Wait for the ingress controller to be ready
echo "Waiting for ingress controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

# Get the external IP
echo "Getting external IP address..."
EXTERNAL_IP=""
while [ -z "$EXTERNAL_IP" ]; do
  EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller \
    -n ingress-nginx \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  [ -z "$EXTERNAL_IP" ] && sleep 10
done

echo "✓ NGINX Ingress Controller installed!"
echo "External IP: $EXTERNAL_IP"
```

## 📈 Partee 4: Auto-scaling Configuration

### Step 9: Horizontal Pod Autoscaler

**Copilot Prompt Suggestion:**
```yaml
# Create kubernetes/05-hpa.yaml with:
# - HPA based on CPU and memory
# - Custom metrics from Prometheus
# - Scaling behavior policies
# - Min/max replica configuration
```

**Expected Output:**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: product-catalog-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: product-catalog
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
      - type: Pods
        value: 1
        periodSeconds: 120
      selectPolicy: Min
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
      - type: Pods
        value: 2
        periodSeconds: 60
      selectPolicy: Max
```

### Step 10: Vertical Pod Autoscaler (Optional)

**Copilot Prompt Suggestion:**
```yaml
# Create kubernetes/06-vpa.yaml for right-sizing pods:
# - VPA in recommendation mode
# - Update policy for resource requests
# - Container-specific policies
```

**Expected Output:**
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: product-catalog-vpa
  namespace: production
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: product-catalog
  updatePolicy:
    updateMode: "Auto"  # Can be "Off" for recommendation only
  resourcePolicy:
    containerPolicies:
    - containerName: product-catalog
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 1
        memory: 1Gi
      controlledResources: ["cpu", "memory"]
```

## 📊 Partee 5: Monitoring Setup

### Step 11: Deploy Prometheus and Grafana

**Copilot Prompt Suggestion:**
```bash
# Create script to deploy Prometheus and Grafana using Helm:
# - kube-prometheus-stack with custom values
# - Persistent storage for data
# - Ingress configuration
# - Pre-configured dashboards
# File: scripts/install-monitoring.sh
```

**Expected Output:**
```bash
#!/bin/bash
set -euo pipefail

echo "Installing Prometheus and Grafana..."

# Add prometheus-community repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring || true

# Create values file for prometheus
cat &gt; prometheus-values.yaml &lt;<EOF
prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi
    serviceMonitorSelectorNilUsesHelmValues: false
    podMonitorSelectorNilUsesHelmValues: false
    retention: 7d
    resources:
      requests:
        cpu: 500m
        memory: 2Gi
      limits:
        cpu: 1000m
        memory: 4Gi

grafana:
  enabled: true
  adminPassword: admin123!
  persistence:
    enabled: true
    size: 5Gi
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: nginx
    hosts:
      - grafana.product-catalog.example.com
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default
  dashboards:
    default:
      kubernetes-cluster:
        url: https://grafana.com/api/dashboards/7249/revisions/1/download
      kubernetes-pods:
        url: https://grafana.com/api/dashboards/6417/revisions/1/download
      nginx-ingress:
        url: https://grafana.com/api/dashboards/9614/revisions/1/download

alertmanager:
  enabled: true
  config:
    global:
      resolve_timeout: 5m
    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'null'
      routes:
      - match:
          alertname: Watchdog
        receiver: 'null'
    receivers:
    - name: 'null'
EOF

# Install kube-prometheus-stack
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus-values.yaml \
  --wait

echo "✓ Monitoring stack installed!"
echo "Access Grafana at: http://grafana.product-catalog.example.com"
echo "Default credentials: admin / admin123!"
```

### Step 12: Create ServiceMonitor for Application

**Copilot Prompt Suggestion:**
```yaml
# Create kubernetes/07-servicemonitor.yaml to:
# - Scrape metrics from the application
# - Configure proper labels for Prometheus
# - Set scrape interval and timeout
# - Include metric relabeling
```

**Expected Output:**
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: product-catalog-metrics
  namespace: production
  labels:
    app: product-catalog
    prometheus: kube-prometheus
spec:
  selector:
    matchLabels:
      app: product-catalog
  endpoints:
  - port: metrics
    interval: 30s
    scrapeTimeout: 10s
    path: /metrics
    relabelings:
    - sourceLabels: [__meta_kubernetes_pod_name]
      targetLabel: pod
    - sourceLabels: [__meta_kubernetes_pod_node_name]
      targetLabel: node
    - sourceLabels: [__meta_kubernetes_namespace]
      targetLabel: namespace
    metricRelabelings:
    - regex: '(http_request_duration_seconds.*|http_requests_total.*|products_.*)'
      action: keep
      sourceLabels: [__name__]
```

## 🚀 Partee 6: despliegue and Validation

### Step 13: Deploy Everything

**Copilot Prompt Suggestion:**
```bash
# Create deployment script that:
# - Applies all Kubernetes manifests in order
# - Waits for resources to be ready
# - Validates the deployment
# - Shows status and endpoints
# File: scripts/deploy-to-aks.sh
```

**Expected Output:**
```bash
#!/bin/bash
set -euo pipefail

# Configuration
NAMESPACE="production"
ACR_LOGIN_SERVER="${ACR_LOGIN_SERVER:-acrworkshop.azurecr.io}"

echo "Deploying Product Catalog to AKS..."

# Substitute ACR URL in deployment
echo "Updating image reference..."
sed -i.bak "s|\${ACR_LOGIN_SERVER}|$ACR_LOGIN_SERVER|g" kubernetes/02-deployment.yaml

# Apply manifests in order
echo "Applying Kubernetes manifests..."
kubectl apply -f kubernetes/00-namespace.yaml
kubectl apply -f kubernetes/01-config.yaml
kubectl apply -f kubernetes/02-deployment.yaml
kubectl apply -f kubernetes/03-service.yaml
kubectl apply -f kubernetes/04-ingress.yaml
kubectl apply -f kubernetes/05-hpa.yaml
kubectl apply -f kubernetes/07-servicemonitor.yaml

# Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/product-catalog -n $NAMESPACE --timeout=300s

# Check pod status
echo "Checking pod status..."
kubectl get pods -n $NAMESPACE -l app=product-catalog

# Get service endpoints
echo "Service endpoints:"
kubectl get svc -n $NAMESPACE product-catalog-service

# Get ingress status
echo "Ingress status:"
kubectl get ingress -n $NAMESPACE product-catalog-ingress

# Test the deployment
echo "Testing deployment..."
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=product-catalog -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n $NAMESPACE $POD_NAME -- curl -s http://localhost:8000/health | jq .

echo "✓ Deployment complete!"
```

### Step 14: Load Testing and Validation

**Copilot Prompt Suggestion:**
```python
# Create tests/test_kubernetes_deployment.py that:
# - Verifies all pods are running
# - Tests auto-scaling behavior
# - Validates zero-downtime updates
# - Checks monitoring endpoints
# - Performs load testing
```

**Expected Output:**
```python
import subprocess
import json
import time
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed
import pytest

class TestKubernetesDeployment:
    
    @pytest.fixture(scope="class")
    def namespace(self):
        return "production"
    
    @pytest.fixture(scope="class")
    def app_label(self):
        return "app=product-catalog"
    
    def run_kubectl(self, command):
        """Execute kubectl command and return output"""
        result = subprocess.run(
            f"kubectl {command}",
            shell=True,
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            raise Exception(f"kubectl command failed: {result.stderr}")
        return result.stdout
    
    def test_deployment_status(self, namespace, app_label):
        """Test that deployment is running with correct replicas"""
        output = self.run_kubectl(f"get deployment -n {namespace} -l {app_label} -o json")
        deployments = json.loads(output)
        
        assert len(deployments['items']) == 1
        deployment = deployments['items'][0]
        
        # Check replica count
        assert deployment['status']['replicas'] &gt;= 3
        assert deployment['status']['readyReplicas'] == deployment['status']['replicas']
        assert deployment['status']['availableReplicas'] == deployment['status']['replicas']
    
    def test_pod_health(self, namespace, app_label):
        """Test that all pods are healthy"""
        output = self.run_kubectl(f"get pods -n {namespace} -l {app_label} -o json")
        pods = json.loads(output)
        
        for pod in pods['items']:
            # Check pod status
            assert pod['status']['phase'] == 'Running'
            
            # Check all containers are ready
            for container_status in pod['status']['containerStatuses']:
                assert container_status['ready'] is True
                assert container_status['restartCount'] &lt; 3  # No excessive restarts
    
    def test_service_endpoints(self, namespace):
        """Test that service has endpoints"""
        output = self.run_kubectl(f"get endpoints product-catalog-service -n {namespace} -o json")
        endpoints = json.loads(output)
        
        # Should have at least 3 endpoints (one per pod)
        assert len(endpoints['subsets'][0]['addresses']) &gt;= 3
    
    def test_horizontal_autoscaling(self, namespace):
        """Test HPA configuration and metrics"""
        output = self.run_kubectl(f"get hpa product-catalog-hpa -n {namespace} -o json")
        hpa = json.loads(output)
        
        # Check HPA is configured correctly
        assert hpa['spec']['minReplicas'] == 3
        assert hpa['spec']['maxReplicas'] == 10
        
        # Check metrics are being collected
        assert 'currentMetrics' in hpa['status']
    
    def test_ingress_connectivity(self, namespace):
        """Test ingress is accessible"""
        # Get ingress external IP
        output = self.run_kubectl(f"get ingress product-catalog-ingress -n {namespace} -o json")
        ingress = json.loads(output)
        
        # Note: In real environment, would test actual HTTP connectivity
        assert len(ingress['spec']['rules']) &gt; 0
        assert 'tls' in ingress['spec']
    
    def test_zero_downtime_update(self, namespace, app_label):
        """Test rolling update maintains availability"""
        # Trigger a rolling update
        self.run_kubectl(f"set image deployment/product-catalog product-catalog=product-catalog:v2 -n {namespace}")
        
        # Monitor availability during update
        failures = 0
        for i in range(30):  # Check for 30 seconds
            try:
                output = self.run_kubectl(f"get deployment product-catalog -n {namespace} -o json")
                deployment = json.loads(output)
                
                # Ensure we always have available replicas
                available = deployment['status'].get('availableReplicas', 0)
                if available &lt; 2:  # Allow one pod to be updating
                    failures += 1
                
                time.sleep(1)
            except Exception:
                failures += 1
        
        # Rollback for cleanup
        self.run_kubectl(f"rollout undo deployment/product-catalog -n {namespace}")
        
        # Should have minimal failures
        assert failures &lt; 3  # Allow up to 3 seconds of reduced availability
    
    def test_load_handling(self, namespace):
        """Test the service can handle load"""
        # Get a pod to port-forward to
        output = self.run_kubectl(f"get pods -n {namespace} -l {app_label} -o json")
        pods = json.loads(output)
        pod_name = pods['items'][0]['metadata']['name']
        
        # Start port-forward in background
        port_forward = subprocess.Popen(
            f"kubectl port-forward -n {namespace} {pod_name} 8080:8000",
            shell=True
        )
        
        time.sleep(3)  # Wait for port-forward to establish
        
        try:
            # Perform load test
            successful_requests = 0
            failed_requests = 0
            
            def make_request(i):
                try:
                    response = requests.get(
                        "http://localhost:8080/products",
                        timeout=5
                    )
                    if response.status_code == 200:
                        return True
                except Exception:
                    pass
                return False
            
            # Send 100 concurrent requests
            with ThreadPoolExecutor(max_workers=20) as executor:
                futures = [executor.submit(make_request, i) for i in range(100)]
                
                for future in as_completed(futures):
                    if future.result():
                        successful_requests += 1
                    else:
                        failed_requests += 1
            
            # Should handle at least 95% of requests
            success_rate = successful_requests / (successful_requests + failed_requests)
            assert success_rate &gt;= 0.95
            
        finally:
            # Cleanup port-forward
            port_forward.terminate()
    
    def test_monitoring_metrics(self, namespace, app_label):
        """Test that Prometheus metrics are being collected"""
        # Check if ServiceMonitor is created
        output = self.run_kubectl(f"get servicemonitor -n {namespace} -o json")
        monitors = json.loads(output)
        
        assert len(monitors['items']) &gt; 0
        
        # Check if metrics endpoint is accessible from pods
        output = self.run_kubectl(f"get pods -n {namespace} -l {app_label} -o json")
        pods = json.loads(output)
        pod_name = pods['items'][0]['metadata']['name']
        
        # Test metrics endpoint
        metrics_output = self.run_kubectl(
            f"exec -n {namespace} {pod_name} -- curl -s http://localhost:9090/metrics"
        )
        
        # Should contain our custom metrics
        assert "http_requests_total" in metrics_output
        assert "products_created_total" in metrics_output
```

## ✅ Validation Verificarlist

Run through this checklist to ensure your Kubernetes despliegue is complete:

```bash
# 1. Check cluster status
kubectl cluster-info
kubectl get nodes

# 2. Verify namespace and resources
kubectl get all -n production

# 3. Check pod logs
kubectl logs -n production -l app=product-catalog --tail=50

# 4. Test application endpoints
kubectl port-forward -n production svc/product-catalog-service 8080:80
curl http://localhost:8080/health
curl http://localhost:8080/products

# 5. Check HPA status
kubectl get hpa -n production product-catalog-hpa

# 6. Verify monitoring
kubectl get servicemonitor -n production
kubectl get prometheus -n monitoring

# 7. Access Grafana dashboards
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Open http://localhost:3000

# 8. Simulate load for autoscaling
kubectl run -it --rm load-test --image=busybox --restart=Never -- \
  sh -c "while true; do wget -q -O- http://product-catalog-service.production/products; done"
```

## 🎯 Success Criteria

Your Kubernetes despliegue is complete when:

- [ ] AKS cluster is running with 3+ nodes
- [ ] All pods are running and healthy
- [ ] Service is accessible via Ingress
- [ ] HPA scales pods based on load
- [ ] Zero-downtime despliegues work
- [ ] Prometheus collects metrics
- [ ] Grafana displays dashboards
- [ ] Load tests pass successfully
- [ ] Security policies are enforced

## 🚀 Extension Challenges

1. **Service Mesh**: Implement Linkerd or Istio for advanced traffic management
2. **GitOps Deployment**: Set up Flux or ArgoCD for declarative despliegues
3. **Multi-Region**: Deploy to multiple AKS regions with Traffic Manager
4. **Chaos Engineering**: Implement chaos testing with Chaos Mesh
5. **Avanzado Monitoring**: Add distributed tracing with Jaeger

## 📚 Additional Recursos

- [AKS Mejores Prácticas](https://learn.microsoft.com/azure/aks/best-practices)
- [Kubernetes Patterns](https://kubernetes.io/docs/concepts/cluster-administration/manage-despliegue/)
- [HPA Documentación](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)

---

Excellent work! You've successfully deployed a production-grade application to Kubernetes with advanced features. Continue to Exercise 3 to build an event-driven serverless system! 🚀