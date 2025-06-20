# Module 20: Additional Resources

## 📚 Learning Resources

### Books
- **"Release It!" by Michael T. Nygard** - Production-ready software patterns
- **"Site Reliability Engineering" by Google** - Chapter on progressive rollouts
- **"Continuous Delivery" by Jez Humble & David Farley** - Deployment pipeline patterns
- **"Feature Management" by Sasan Gaffari** - Comprehensive guide to feature flags

### Online Courses
- [Progressive Delivery on Pluralsight](https://www.pluralsight.com/courses/progressive-delivery)
- [Advanced Kubernetes on Coursera](https://www.coursera.org/learn/advanced-kubernetes)
- [DevOps Deployment Strategies on LinkedIn Learning](https://www.linkedin.com/learning/devops-deployment-strategies)

### Documentation & Guides
- [Azure Deployment Best Practices](https://learn.microsoft.com/azure/architecture/framework/devops/deployment)
- [GitHub Advanced Deployment](https://docs.github.com/actions/deployment)
- [Kubernetes Progressive Delivery](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/)
- [Feature Flag Guide by Martin Fowler](https://martinfowler.com/articles/feature-toggles.html)

## 🛠️ Tools and Frameworks

### Deployment Orchestration
1. **Flagger** - Progressive delivery operator for Kubernetes
   ```bash
   # Install Flagger
   kubectl apply -k github.com/fluxcd/flagger/kustomize/kubernetes
   ```

2. **Argo Rollouts** - Advanced deployment strategies
   ```bash
   # Install Argo Rollouts
   kubectl create namespace argo-rollouts
   kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
   ```

3. **Spinnaker** - Multi-cloud continuous delivery
   - [Installation Guide](https://spinnaker.io/docs/setup/install/)
   - [Deployment Strategies](https://spinnaker.io/docs/guides/user/kubernetes-v2/deploy/)

### Feature Flag Services
1. **LaunchDarkly** - Enterprise feature management
   ```python
   # Python SDK
   pip install launchdarkly-server-sdk
   
   import ldclient
   ldclient.set_config(ldclient.Config("YOUR_SDK_KEY"))
   client = ldclient.get()
   ```

2. **Split.io** - Feature flags and experimentation
   ```python
   # Python SDK
   pip install splitio-client
   
   from splitio import get_factory
   factory = get_factory('YOUR_API_KEY')
   ```

3. **Unleash** - Open source feature management
   ```bash
   # Docker deployment
   docker run -d -p 4242:4242 \
     -e DATABASE_URL=postgres://... \
     unleashorg/unleash-server
   ```

### Monitoring and Observability
1. **Prometheus + Grafana**
   ```yaml
   # prometheus-values.yaml
   serverFiles:
     prometheus.yml:
       scrape_configs:
         - job_name: canary-metrics
           kubernetes_sd_configs:
             - role: pod
           relabel_configs:
             - source_labels: [__meta_kubernetes_pod_label_version]
               target_label: version
   ```

2. **Azure Monitor**
   ```python
   # Application Insights integration
   from applicationinsights import TelemetryClient
   tc = TelemetryClient('YOUR_INSTRUMENTATION_KEY')
   tc.track_event('DeploymentStarted', {'version': '2.0'})
   ```

3. **Datadog**
   ```python
   # Deployment tracking
   from datadog import initialize, api
   initialize(api_key='YOUR_API_KEY')
   api.Event.create(
       title='Deployment started',
       text='Canary deployment v2.0',
       tags=['deployment:canary', 'version:2.0']
   )
   ```

## 📊 Templates and Examples

### Blue-Green Deployment Template
```yaml
# blue-green-template.yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.appName }}-service
spec:
  selector:
    app: {{ .Values.appName }}
    version: {{ .Values.activeEnvironment }}
  ports:
    - port: 80
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.appName }}-blue
spec:
  replicas: {{ .Values.replicas }}
  selector:
    matchLabels:
      app: {{ .Values.appName }}
      version: blue
  template:
    metadata:
      labels:
        app: {{ .Values.appName }}
        version: blue
    spec:
      containers:
      - name: app
        image: {{ .Values.image }}:{{ .Values.blueVersion }}
        ports:
        - containerPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.appName }}-green
spec:
  replicas: {{ .Values.replicas }}
  selector:
    matchLabels:
      app: {{ .Values.appName }}
      version: green
  template:
    metadata:
      labels:
        app: {{ .Values.appName }}
        version: green
    spec:
      containers:
      - name: app
        image: {{ .Values.image }}:{{ .Values.greenVersion }}
        ports:
        - containerPort: 8080
```

### Canary Analysis Template
```yaml
# canary-analysis.yaml
apiVersion: flagger.app/v1beta1
kind: MetricTemplate
metadata:
  name: canary-metrics
spec:
  provider:
    type: prometheus
    address: http://prometheus:9090
  metrics:
  - name: request-success-rate
    query: |
      sum(
        rate(
          http_requests_total{
            kubernetes_namespace="{{ namespace }}",
            kubernetes_pod_name=~"{{ target }}-[0-9a-zA-Z]+(-[0-9a-zA-Z]+)",
            status!~"5.."
          }[{{ interval }}]
        )
      ) / 
      sum(
        rate(
          http_requests_total{
            kubernetes_namespace="{{ namespace }}",
            kubernetes_pod_name=~"{{ target }}-[0-9a-zA-Z]+(-[0-9a-zA-Z]+)"
          }[{{ interval }}]
        )
      ) * 100
    thresholdRange:
      min: 99
  - name: request-duration
    query: |
      histogram_quantile(
        0.99,
        sum(
          rate(
            http_request_duration_seconds_bucket{
              kubernetes_namespace="{{ namespace }}",
              kubernetes_pod_name=~"{{ target }}-[0-9a-zA-Z]+(-[0-9a-zA-Z]+)"
            }[{{ interval }}]
          )
        ) by (le)
      )
    thresholdRange:
      max: 0.5
```

### Feature Flag Configuration Template
```json
{
  "flags": [
    {
      "key": "new-checkout-flow",
      "name": "New Checkout Flow",
      "description": "Redesigned checkout experience with one-click purchase",
      "type": "boolean",
      "defaultValue": false,
      "targeting": {
        "enabled": true,
        "rules": [
          {
            "id": "beta-users",
            "conditions": [
              {
                "attribute": "user.segment",
                "operator": "contains",
                "value": "beta"
              }
            ],
            "returnValue": true
          },
          {
            "id": "percentage-rollout",
            "conditions": [],
            "percentage": 10,
            "returnValue": true
          }
        ]
      },
      "prerequisites": ["payment-service-v2"],
      "tags": ["frontend", "checkout", "experiment"],
      "owner": "checkout-team@company.com"
    }
  ]
}
```

## 🎯 Production Checklists

### Pre-Deployment Checklist
```markdown
## Blue-Green Pre-Deployment
- [ ] Database migrations tested and backward compatible
- [ ] Load testing completed on green environment
- [ ] Monitoring dashboards configured
- [ ] Rollback procedure documented and tested
- [ ] DNS TTL reduced for quick switching
- [ ] Session management strategy confirmed
- [ ] Health check endpoints verified

## Canary Pre-Deployment
- [ ] Service mesh properly configured
- [ ] Metrics and SLIs defined
- [ ] Automatic rollback thresholds set
- [ ] Canary analysis queries tested
- [ ] Traffic routing rules verified
- [ ] A/B test configuration (if applicable)
- [ ] Gradual rollout schedule defined

## Feature Flag Pre-Deployment
- [ ] Flag configuration reviewed
- [ ] Targeting rules tested
- [ ] Kill switch integration verified
- [ ] Telemetry events configured
- [ ] Flag cleanup schedule defined
- [ ] Performance impact assessed
- [ ] Documentation updated
```

## 🎓 Workshops and Training

### Internal Workshop Materials

1. **Blue-Green Workshop** (2 hours)
   - Infrastructure setup
   - Database migration strategies
   - Hands-on switching exercise
   - Troubleshooting scenarios

2. **Canary Deployment Workshop** (3 hours)
   - Service mesh configuration
   - Metrics and monitoring setup
   - Progressive rollout simulation
   - Failure scenario handling

3. **Feature Flags Masterclass** (4 hours)
   - Flag lifecycle management
   - Advanced targeting techniques
   - Performance optimization
   - Security considerations

### Lab Exercises

#### Lab 1: Zero-Downtime Deployment
```python
"""
Objective: Deploy application update with zero downtime
Duration: 45 minutes
"""

# Setup
git clone https://github.com/workshop/blue-green-lab
cd blue-green-lab

# Tasks:
# 1. Deploy v1.0 to blue environment
# 2. Deploy v2.0 to green environment
# 3. Implement health checks
# 4. Switch traffic with zero downtime
# 5. Verify no requests were dropped

# Validation
./validate-zero-downtime.sh
```

#### Lab 2: Canary with Automatic Rollback
```python
"""
Objective: Implement canary deployment with automatic rollback
Duration: 60 minutes
"""

# Setup
kubectl apply -f canary-lab-setup.yaml

# Tasks:
# 1. Configure Flagger for automatic canary
# 2. Define success criteria (99% success rate)
# 3. Deploy canary with intentional bug
# 4. Observe automatic rollback
# 5. Fix bug and successful deployment

# Validation
kubectl describe canary/my-app
```

## 🌐 Community Resources

### Forums and Communities
- [CNCF Slack](https://slack.cncf.io/) - #progressive-delivery channel
- [DevOps Stack Exchange](https://devops.stackexchange.com/)
- [Reddit r/devops](https://www.reddit.com/r/devops/)
- [LaunchDarkly Community](https://launchdarkly.com/community/)

### Conferences and Talks
- **KubeCon** - Progressive Delivery tracks
- **DevOps Enterprise Summit** - Deployment strategy sessions
- **Feature Flag Summit** - Annual online conference

### Notable Talks
1. "Progressive Delivery at Netflix" - KubeCon 2023
2. "Feature Flags at Scale" - DevOps Summit 2023
3. "Blue-Green Done Right" - SREcon 2023

## 🔗 Useful Links

### GitHub Repositories
- [Flagger Examples](https://github.com/fluxcd/flagger/tree/main/examples)
- [Argo Rollouts Demos](https://github.com/argoproj/rollouts-demo)
- [Feature Flag Examples](https://github.com/launchdarkly/hello-world)
- [Progressive Delivery Patterns](https://github.com/progressive-delivery/patterns)

### Tools Comparison
| Tool | Type | Open Source | Cloud Native | Enterprise Features |
|------|------|-------------|--------------|-------------------|
| Flagger | Canary | ✅ | ✅ | ⭐⭐⭐ |
| Argo Rollouts | Multi-strategy | ✅ | ✅ | ⭐⭐⭐⭐ |
| Spinnaker | Full CD | ✅ | ✅ | ⭐⭐⭐⭐⭐ |
| LaunchDarkly | Feature Flags | ❌ | ✅ | ⭐⭐⭐⭐⭐ |
| Unleash | Feature Flags | ✅ | ✅ | ⭐⭐⭐ |

### Azure-Specific Resources
- [Azure Traffic Manager for Blue-Green](https://learn.microsoft.com/azure/traffic-manager/traffic-manager-routing-methods)
- [Azure App Configuration Feature Flags](https://learn.microsoft.com/azure/azure-app-configuration/concept-feature-management)
- [AKS Deployment Strategies](https://learn.microsoft.com/azure/aks/deployment-strategies)

## 📝 Case Studies

### Netflix: Automated Canary Analysis
- **Challenge**: Deploy 100+ times per day safely
- **Solution**: Automated canary analysis with Kayenta
- **Results**: 99.99% deployment success rate

### Amazon: One-Box Deployments
- **Challenge**: Test in production safely
- **Solution**: Single instance deployments before fleet-wide
- **Results**: 90% reduction in deployment incidents

### Microsoft: Ring-Based Deployments
- **Challenge**: Windows updates to billions of devices
- **Solution**: Progressive ring deployments
- **Results**: Early issue detection, reduced impact

## 🎯 Certification Paths

### Relevant Certifications
1. **Kubernetes Certifications**
   - CKA (Certified Kubernetes Administrator)
   - CKAD (Certified Kubernetes Application Developer)

2. **Cloud Certifications**
   - Azure DevOps Engineer Expert (AZ-400)
   - AWS DevOps Engineer Professional

3. **Site Reliability Engineering**
   - Google Cloud Professional SRE
   - Linux Foundation SRE Certification

---

## 🚀 Your Next Steps

1. **Practice**: Use the lab exercises to gain hands-on experience
2. **Implement**: Start with blue-green in your test environment
3. **Measure**: Track deployment metrics and improve
4. **Share**: Document your learnings and share with your team
5. **Advance**: Move to Module 21 - Introduction to AI Agents

Remember: Mastery comes from practice. Start small, measure everything, and gradually increase complexity.