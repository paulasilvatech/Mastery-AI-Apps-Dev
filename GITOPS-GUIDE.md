# 🔄 GitOps Implementation Guide

## What is GitOps?

GitOps is a way of implementing Continuous Deployment using Git as a single source of truth for declarative infrastructure and applications.

## Core Principles

1. **Declarative**: System state is declaratively described
2. **Versioned**: State is stored in Git (version controlled)
3. **Automated**: Approved changes are automatically applied
4. **Observable**: System observes and alerts on divergence

## Workshop GitOps Structure

```
mastery-ai-apps-dev/
├── infrastructure/          # Infrastructure as Code
│   ├── environments/       # Environment-specific configs
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   ├── modules/           # Reusable infrastructure modules
│   └── policies/          # Security and compliance policies
├── applications/          # Application deployments
│   ├── manifests/        # Kubernetes manifests
│   └── helm-charts/      # Helm charts
└── .github/
    └── workflows/        # GitOps automation workflows
```

## Implementation Patterns

### 1. Infrastructure GitOps

```yaml
# .github/workflows/infrastructure-gitops.yml
name: Infrastructure GitOps

on:
  push:
    paths:
      - 'infrastructure/**'
    branches:
      - main

jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Terraform Plan
        run: |
          cd infrastructure/environments/${{ github.event.inputs.environment }}
          terraform init
          terraform plan -out=tfplan
      
      - name: Apply on Approval
        if: github.ref == 'refs/heads/main'
        run: terraform apply tfplan
```

### 2. Application GitOps

```yaml
# applications/manifests/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - namespace.yaml
  - deployment.yaml
  - service.yaml
  - ingress.yaml

configMapGenerator:
  - name: app-config
    literals:
      - ENVIRONMENT=production
      - AI_ENDPOINT=$AI_ENDPOINT

images:
  - name: myapp
    newTag: ${IMAGE_TAG}
```

### 3. Progressive Delivery

```yaml
# Canary deployment with Flagger
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: ai-agent-service
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ai-agent-service
  progressDeadlineSeconds: 300
  service:
    port: 80
  analysis:
    interval: 30s
    threshold: 5
    metrics:
      - name: request-success-rate
        thresholdRange:
          min: 99
      - name: request-duration
        thresholdRange:
          max: 500
```

## GitOps for Each Module

### Modules 1-10: Application Development
```yaml
# Simple app deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: module-{{ .ModuleNumber }}-app
spec:
  replicas: 1
  template:
    spec:
      containers:
        - name: app
          image: ghcr.io/workshop/module-{{ .ModuleNumber }}:{{ .Version }}
```

### Modules 11-20: Infrastructure & Enterprise
```hcl
# Terraform GitOps
module "enterprise_app" {
  source = "../../modules/enterprise-app"
  
  environment     = var.environment
  ai_features     = true
  copilot_enabled = true
  
  tags = {
    ManagedBy = "GitOps"
    Module    = "16"
  }
}
```

### Modules 21-25: Agent Deployment
```yaml
# Agent deployment with MCP
apiVersion: v1
kind: ConfigMap
metadata:
  name: mcp-config
data:
  config.json: |
    {
      "servers": {
        "database-agent": {
          "command": "node",
          "args": ["./mcp-server.js"],
          "env": {
            "CONNECTION_STRING": "${DB_CONNECTION}"
          }
        }
      }
    }
```

## Security in GitOps

### 1. Secret Management
```yaml
# Using Sealed Secrets
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: ai-credentials
spec:
  encryptedData:
    OPENAI_API_KEY: AgC3Rf4K... # Encrypted value
```

### 2. Policy as Code
```yaml
# OPA policy for GitOps
package deployment.security

deny[msg] {
  input.kind == "Deployment"
  not input.spec.template.spec.securityContext.runAsNonRoot
  msg := "Containers must run as non-root"
}
```

### 3. RBAC Configuration
```yaml
# GitHub Actions OIDC for Azure
- name: Azure Login with OIDC
  uses: azure/login@v1
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## Monitoring GitOps

### Metrics to Track
- Deployment frequency
- Lead time for changes
- Mean time to recovery
- Change failure rate

### Alerting Rules
```yaml
- alert: GitOpsDeploymentFailed
  expr: |
    increase(gitops_deployment_failures_total[5m]) > 0
  annotations:
    summary: "GitOps deployment failed"
    description: "Deployment {{ $labels.deployment }} failed"
```

## Best Practices

### 1. Branch Protection
```yaml
# branch-protection.yml
protection_rules:
  - name: main
    required_reviews: 2
    dismiss_stale_reviews: true
    require_code_owner_reviews: true
    required_status_checks:
      - "Terraform Plan"
      - "Security Scan"
      - "Unit Tests"
```

### 2. Environment Promotion
```
feature/* → dev → staging → main (prod)
```

### 3. Rollback Strategy
```bash
# Quick rollback
git revert <commit>
git push
# GitOps automatically rolls back
```

### 4. Drift Detection
```yaml
# Scheduled drift detection
- cron: "0 * * * *"
  jobs:
    - name: detect-drift
      plan: true
      workspace: production
```

## GitOps Tools Used in Workshop

### 1. GitHub Actions
Primary CI/CD and GitOps orchestrator

### 2. Terraform/OpenTofu
Infrastructure provisioning with state management

### 3. Flux/ArgoCD
Kubernetes GitOps operators (Module 24)

### 4. Kustomize
Kubernetes configuration management

### 5. Helm
Package management for Kubernetes

## Workshop-Specific GitOps

Each module includes:
- `.gitops/` directory with configurations
- Automated deployment on merge
- Environment-specific overrides
- Rollback procedures

### Module GitOps Structure
```
modules/module-XX/
├── .gitops/
│   ├── dev/
│   │   └── config.yaml
│   ├── staging/
│   │   └── config.yaml
│   └── prod/
│       └── config.yaml
├── infrastructure/
│   └── main.tf
└── .github/
    └── workflows/
        └── deploy.yml
```

## Practical Examples

### Example 1: Auto-Deploy on Push
```yaml
name: Auto Deploy Module
on:
  push:
    paths:
      - 'modules/module-*/src/**'
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Detect Changed Module
        id: changes
        run: |
          echo "module=$(git diff --name-only HEAD^ | grep -oP 'modules/\K[^/]+' | head -1)" >> $GITHUB_OUTPUT
      
      - name: Deploy Module
        run: |
          ./scripts/deploy-module.sh ${{ steps.changes.outputs.module }}
```

### Example 2: Multi-Environment Pipeline
```yaml
name: Environment Promotion
on:
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options:
          - dev
          - staging
          - prod

jobs:
  promote:
    environment: ${{ inputs.environment }}
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to ${{ inputs.environment }}
        run: |
          kubectl apply -k ./environments/${{ inputs.environment }}
```

### Example 3: Agent Deployment Pipeline
```yaml
name: Deploy AI Agent
on:
  push:
    paths:
      - 'agents/**'

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Build Agent Container
        run: |
          docker build -t ghcr.io/${{ github.repository }}/agent:${{ github.sha }} .
          docker push ghcr.io/${{ github.repository }}/agent:${{ github.sha }}
      
      - name: Update Manifest
        run: |
          sed -i "s|image:.*|image: ghcr.io/${{ github.repository }}/agent:${{ github.sha }}|" k8s/deployment.yaml
          
      - name: Apply to Cluster
        run: |
          kubectl apply -f k8s/
```

## Troubleshooting GitOps

### Common Issues

1. **Sync Failures**
   - Check Git permissions
   - Verify webhook configuration
   - Review application logs

2. **Drift Detection**
   - Enable automated sync
   - Configure proper RBAC
   - Monitor drift metrics

3. **Secret Management**
   - Use sealed secrets
   - Implement secret rotation
   - Audit secret access

## GitOps Maturity Model

### Level 1: Basic
- Manual deployments
- Some automation
- Basic version control

### Level 2: Intermediate
- Automated deployments
- Environment separation
- Basic monitoring

### Level 3: Advanced
- Full GitOps implementation
- Progressive delivery
- Comprehensive observability

### Level 4: Expert
- Multi-cluster GitOps
- Advanced policies
- Self-healing systems

## Resources

- [OpenGitOps](https://opengitops.dev/)
- [Flux Documentation](https://fluxcd.io/docs/)
- [ArgoCD Documentation](https://argoproj.github.io/cd/)
- [GitHub Actions Documentation](https://docs.github.com/actions)

---

Remember: GitOps is about treating operations as code - everything in Git, everything automated, everything observable! 🚀

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>

---

## 🔗 Quick Navigation

<div align="center">

| Documentation | Getting Started | Resources |
|:-------------:|:---------------:|:---------:|
| [📚 Modules](modules/README.md) | [🚀 Quick Start](QUICKSTART.md) | [🛠️ Scripts](scripts/README.md) |
| [📋 Prerequisites](PREREQUISITES.md) | [❓ FAQ](FAQ.md) | [📝 Prompt Guide](PROMPT-GUIDE.md) |
| [🔧 Troubleshooting](TROUBLESHOOTING.md) | [🔄 GitOps Guide](GITOPS-GUIDE.md) | [💬 Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions) |

</div>

### 🎯 Start Your Journey

<div align="center">

[**🚀 Begin Module 01 - Introduction to AI-Powered Development**](modules/module-01/README.md)

</div>
