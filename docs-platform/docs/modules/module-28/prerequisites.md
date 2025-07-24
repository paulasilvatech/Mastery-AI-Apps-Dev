---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 28"
---

# Prerequisites for Module 28: Advanced DevOps & Security

## 🎯 Required Knowledge

Before starting this module, ensure you have:

### From Previous Modules
- ✅ **Modules 21-25**: Complete understanding of AI agents and MCP
- ✅ **Module 26**: Enterprise .NET patterns
- ✅ **Module 27**: Legacy modernization concepts
- ✅ **Agent Development**: Building and orchestrating AI agents
- ✅ **MCP**: Model Context Protocol implementation

### DevOps Fundamentals
- ✅ **CI/CD**: Pipeline design and implementation
- ✅ **Containerization**: Docker and container orchestration
- ✅ **IaC**: Infrastructure as Code (Terraform/Pulumi)
- ✅ **Git**: Advanced Git workflows and branching strategies
- ✅ **Cloud Platforms**: AWS/Azure/GCP basics

### Security Knowledge
- ✅ **Security Principles**: Zero trust, least privilege
- ✅ **SAST/DAST**: Static and dynamic security testing
- ✅ **Container Security**: Image scanning, runtime protection
- ✅ **Network Security**: Firewalls, segmentation, encryption
- ✅ **Compliance**: GDPR, SOC2, ISO27001 basics

### Programming Skills
- ✅ **Python**: Advanced Python with async programming
- ✅ **Go**: Basic Go for infrastructure tools
- ✅ **YAML**: Configuration and pipeline definitions
- ✅ **Bash/PowerShell**: Scripting for automation
- ✅ **TypeScript**: For frontend dashboards

## 🛠️ Required Software

### Core Development Environment

#### Python Environment
```bash
# Create virtual environment
python -m venv agentic-devops-env

# Activate environment
# Windows
.\agentic-devops-env\Scripts\activate
# macOS/Linux
source agentic-devops-env/bin/activate

# Install required packages
pip install --upgrade pip
pip install -r requirements.txt
```

Create `requirements.txt`:
```txt
# AI/ML Frameworks
openai==1.12.0               # OpenAI API
anthropic==0.18.1            # Claude API
langchain==0.1.9             # Agent framework
langchain-openai==0.0.8      # OpenAI integration
langchain-community==0.0.24  # Community tools
autogen==0.2.19              # Multi-agent framework
crewai==0.22.5               # Agent teams
semantic-kernel==0.4.5       # Microsoft agent framework

# DevOps Tools
kubernetes==29.0.0           # K8s Python client
docker==7.0.0                # Docker API
terraform==1.7.0             # Terraform wrapper
pulumi==3.104.2              # Pulumi IaC
ansible==9.2.0               # Ansible automation

# Security Tools
bandit==1.7.6                # Security linter
safety==3.0.1                # Dependency scanner
cryptography==42.0.2         # Encryption
pyjwt==2.8.0                 # JWT handling
python-jose==3.3.0           # JOSE implementation

# Observability
prometheus-client==0.19.0    # Prometheus metrics
opentelemetry-api==1.22.0    # OpenTelemetry
opentelemetry-sdk==1.22.0    # OTel SDK
elastic-apm==6.20.0          # Elastic APM
datadog==0.48.0              # Datadog integration

# CI/CD
github3.py==4.0.1            # GitHub API
python-gitlab==4.4.0         # GitLab API
jenkins==1.8.0               # Jenkins API
pyyaml==6.0.1                # YAML processing
jinja2==3.1.3                # Template engine

# Agent Development
fastapi==0.109.2             # API framework
uvicorn==0.27.1              # ASGI server
websockets==12.0             # WebSocket support
aiohttp==3.9.3               # Async HTTP
asyncio==3.4.3               # Async support
redis==5.0.1                 # Cache/message broker
celery==5.3.4                # Task queue

# Data & Storage
psycopg2-binary==2.9.9       # PostgreSQL
motor==3.3.2                 # Async MongoDB
elasticsearch==8.12.1        # Elasticsearch
influxdb-client==1.40.0      # Time series DB

# Testing & Quality
pytest==8.0.0                # Testing framework
pytest-asyncio==0.23.4       # Async testing
pytest-cov==4.1.0            # Coverage
pytest-mock==3.12.0          # Mocking
black==24.1.1                # Code formatter
ruff==0.2.1                  # Fast linter
mypy==1.8.0                  # Type checking

# Utilities
pydantic==2.6.0              # Data validation
click==8.1.7                 # CLI framework
rich==13.7.0                 # Terminal UI
structlog==24.1.0            # Structured logging
python-dotenv==1.0.1         # Environment variables
httpx==0.26.0                # HTTP client
tenacity==8.2.3              # Retry logic
```

#### Docker & Kubernetes Setup
```bash
# Install Docker Desktop
# Windows/macOS: Download from https://www.docker.com/products/docker-desktop
# Linux:
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install kubectl
# Windows
winget install Kubernetes.kubectl

# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install kind (Kubernetes in Docker) for local development
# Windows
curl.exe -Lo kind.exe https://kind.sigs.k8s.io/dl/v0.21.0/kind-windows-amd64
Move-Item .\kind.exe C:\Windows\

# macOS
brew install kind

# Linux
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.21.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Create local Kubernetes cluster
kind create cluster --name agentic-devops --config kind-config.yaml
```

Create `kind-config.yaml`:
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30080
        hostPort: 80
        protocol: TCP
      - containerPort: 30443
        hostPort: 443
        protocol: TCP
  - role: worker
  - role: worker
```

#### Infrastructure as Code Tools
```bash
# Install Terraform
# Windows
winget install Hashicorp.Terraform

# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Linux
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Install Pulumi
curl -fsSL https://get.pulumi.com | sh

# Install Helm
# Windows
winget install Helm.Helm

# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Security Tools

#### Container Security
```bash
# Install Trivy for vulnerability scanning
# Windows
curl -LO https://github.com/aquasecurity/trivy/releases/download/v0.49.1/trivy_0.49.1_windows-64bit.zip
Expand-Archive -Path trivy_0.49.1_windows-64bit.zip -DestinationPath .

# macOS
brew install trivy

# Linux
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# Install Falco for runtime security (Linux only)
curl -s https://falco.org/repo/falcosecurity-packages.asc | sudo apt-key add -
echo "deb https://download.falco.org/packages/deb stable main" | sudo tee -a /etc/apt/sources.list.d/falcosecurity.list
sudo apt-get update -y
sudo apt-get install -y falco
```

#### Policy Engines
```bash
# Install Open Policy Agent (OPA)
# Windows
curl -LO https://openpolicyagent.org/downloads/v0.61.0/opa_windows_amd64.exe
Move-Item opa_windows_amd64.exe opa.exe

# macOS
brew install opa

# Linux
curl -L -o opa https://openpolicyagent.org/downloads/v0.61.0/opa_linux_amd64_static
chmod 755 ./opa
sudo mv ./opa /usr/local/bin/

# Install Conftest for policy testing
# Windows
curl -LO https://github.com/open-policy-agent/conftest/releases/download/v0.48.0/conftest_0.48.0_Windows_x86_64.zip
Expand-Archive conftest_0.48.0_Windows_x86_64.zip

# macOS
brew install conftest

# Linux
wget https://github.com/open-policy-agent/conftest/releases/download/v0.48.0/conftest_0.48.0_Linux_x86_64.tar.gz
tar xzf conftest_0.48.0_Linux_x86_64.tar.gz
sudo mv conftest /usr/local/bin
```

### Observability Stack

#### Prometheus & Grafana
```bash
# Using Docker Compose
cat &gt; monitoring-stack.yml &lt;&lt; 'EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./prometheus:/etc/prometheus
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    ports:
      - "9090:9090"
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_INSTALL_PLUGINS=grafana-piechart-panel
    ports:
      - "3000:3000"
    restart: unless-stopped

  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    volumes:
      - ./alertmanager:/etc/alertmanager
    command:
      - '--config.file=/etc/alertmanager/config.yml'
      - '--storage.path=/alertmanager'
    ports:
      - "9093:9093"
    restart: unless-stopped

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    ports:
      - "9100:9100"

  jaeger:
    image: jaegertracing/all-in-one:latest
    container_name: jaeger
    environment:
      - COLLECTOR_OTLP_ENABLED=true
    ports:
      - "16686:16686"
      - "4317:4317"
      - "4318:4318"
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:
EOF

# Create Prometheus configuration
mkdir -p prometheus
cat &gt; prometheus/prometheus.yml &lt;&lt; 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

rule_files:
  - "rules/*.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
EOF

# Start monitoring stack
docker-compose -f monitoring-stack.yml up -d
```

### CI/CD Tools

#### GitHub Actions Runner
```bash
# Create self-hosted runner directory
mkdir actions-runner && cd actions-runner

# Download runner
# Linux x64
curl -o actions-runner-linux-x64-2.313.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.313.0/actions-runner-linux-x64-2.313.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.313.0.tar.gz

# Configure runner (replace with your repo URL and token)
./config.sh --url https://github.com/YOUR-ORG/YOUR-REPO --token YOUR-TOKEN

# Install as service (optional)
sudo ./svc.sh install
sudo ./svc.sh start
```

### Agent Development Tools

#### MCP Server Setup
```bash
# Create MCP server for DevOps tools
mkdir -p mcp-servers/devops-tools
cd mcp-servers/devops-tools

# Initialize Node.js project
npm init -y
npm install @modelcontextprotocol/sdk express

# Create server implementation
cat &gt; server.js &lt;&lt; 'EOF'
const { MCPServer } = require('@modelcontextprotocol/sdk');
const express = require('express');

class DevOpsToolServer extends MCPServer {
  constructor() {
    super({
      name: 'devops-tools',
      description: 'MCP server for DevOps automation',
      version: '1.0.0'
    });

    this.registerTool({
      name: 'deploy',
      description: 'Deploy application to Kubernetes',
      parameters: {
        type: 'object',
        properties: {
          app: { type: 'string', description: 'Application name' },
          version: { type: 'string', description: 'Version to deploy' },
          environment: { type: 'string', enum: ['dev', 'staging', 'prod'] }
        },
        required: ['app', 'version', 'environment']
      },
      handler: this.deployApp.bind(this)
    });

    this.registerTool({
      name: 'scan_security',
      description: 'Run security scan on container image',
      parameters: {
        type: 'object',
        properties: {
          image: { type: 'string', description: 'Container image to scan' }
        },
        required: ['image']
      },
      handler: this.scanSecurity.bind(this)
    });
  }

  async deployApp({ app, version, environment }) {
    // Implementation here
    return { success: true, message: `Deployed ${app} v${version} to ${environment}` };
  }

  async scanSecurity({ image }) {
    // Implementation here
    return { vulnerabilities: [], status: 'clean' };
  }
}

const server = new DevOpsToolServer();
server.start(3000);
EOF
```

## 🏗️ Project Setup

### 1. Create Project Structure
```bash
# Create main project directory
mkdir advanced-devops-security
cd advanced-devops-security

# Create directory structure
mkdir -p {agents/{ci-agent,security-agent,infra-agent,monitoring-agent,orchestrator},pipelines/{templates,policies,workflows},security/{policies,scanners,response,compliance},infrastructure/{terraform,kubernetes,helm,monitoring},tests/{unit,integration,e2e},docs}

# Initialize Git repository
git init
echo "# Advanced DevOps & Security - Agentic DevOps" &gt; README.md
git add README.md
git commit -m "Initial commit"
```

### 2. Configure Environment
```bash
# Create environment file
cat &gt; .env &lt;&lt; 'EOF'
# AI Services
OPENAI_API_KEY=your-openai-key
ANTHROPIC_API_KEY=your-anthropic-key
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_KEY=your-azure-key

# GitHub
GITHUB_TOKEN=your-github-token
GITHUB_ORG=your-org
GITHUB_REPO=your-repo

# Cloud Providers
AWS_ACCESS_KEY_ID=your-aws-key
AWS_SECRET_ACCESS_KEY=your-aws-secret
AWS_REGION=us-east-1

AZURE_SUBSCRIPTION_ID=your-subscription
AZURE_TENANT_ID=your-tenant
AZURE_CLIENT_ID=your-client-id
AZURE_CLIENT_SECRET=your-client-secret

# Kubernetes
KUBECONFIG=~/.kube/config
K8S_NAMESPACE=agentic-devops

# Security
VAULT_ADDR=http://localhost:8200
VAULT_TOKEN=your-vault-token

# Monitoring
PROMETHEUS_URL=http://localhost:9090
GRAFANA_URL=http://localhost:3000
GRAFANA_API_KEY=your-grafana-key

# Databases
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=agentic_devops
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password

REDIS_URL=redis://localhost:6379

# Agent Communication
AGENT_BROKER_URL=nats://localhost:4222
AGENT_API_PORT=8000
EOF

# Add .env to .gitignore
echo -e ".env\n*.pyc\n__pycache__/\n.coverage\n.pytest_cache/\nvenv/\n.vscode/\n.idea/" &gt; .gitignore
```

### 3. Initialize Infrastructure
```bash
# Create Terraform configuration
cat &gt; infrastructure/terraform/main.tf &lt;&lt; 'EOF'
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~&gt; 2.25"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~&gt; 2.12"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Create namespace
resource "kubernetes_namespace" "agentic_devops" {
  metadata {
    name = "agentic-devops"
  }
}
EOF

# Initialize Terraform
cd infrastructure/terraform
terraform init
```

### 4. Setup Kubernetes Resources
```bash
# Create base Kubernetes manifests
cat &gt; infrastructure/kubernetes/namespace.yaml &lt;&lt; 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: agentic-devops
  labels:
    name: agentic-devops
    monitoring: enabled
EOF

# Create RBAC for agents
cat &gt; infrastructure/kubernetes/rbac.yaml &lt;&lt; 'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: devops-agent
  namespace: agentic-devops
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: devops-agent-role
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: devops-agent-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: devops-agent-role
subjects:
  - kind: ServiceAccount
    name: devops-agent
    namespace: agentic-devops
EOF

# Apply to cluster
kubectl apply -f infrastructure/kubernetes/
```

### 5. Create Agent Base Template
```python
# agents/base_agent.py
from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional
import asyncio
import logging
from datetime import datetime
import openai
from langchain.agents import AgentExecutor
from langchain.memory import ConversationBufferWindowMemory
from langchain.tools import Tool
import structlog

class BaseDevOpsAgent(ABC):
    """Base class for all DevOps agents"""
    
    def __init__(self, name: str, description: str, config: Dict[str, Any]):
        self.name = name
        self.description = description
        self.config = config
        self.logger = structlog.get_logger(name=name)
        self.memory = ConversationBufferWindowMemory(k=10)
        self.tools: List[Tool] = []
        self.metrics = {}
        self.initialize()
    
    @abstractmethod
    def initialize(self):
        """Initialize agent-specific resources"""
        pass
    
    @abstractmethod
    async def execute_task(self, task: Dict[str, Any]) -&gt; Dict[str, Any]:
        """Execute a specific task"""
        pass
    
    @abstractmethod
    def get_tools(self) -&gt; List[Tool]:
        """Return list of tools available to this agent"""
        pass
    
    async def run(self):
        """Main agent loop"""
        self.logger.info(f"Starting {self.name} agent")
        
        while True:
            try:
                # Get next task
                task = await self.get_next_task()
                if task:
                    # Execute task
                    result = await self.execute_task(task)
                    
                    # Report results
                    await self.report_result(task, result)
                    
                    # Update metrics
                    self.update_metrics(task, result)
                else:
                    # No tasks, wait
                    await asyncio.sleep(5)
                    
            except Exception as e:
                self.logger.error(f"Agent error: {e}")
                await self.handle_error(e)
    
    async def get_next_task(self) -&gt; Optional[Dict[str, Any]]:
        """Get next task from queue"""
        # Implementation depends on message broker
        pass
    
    async def report_result(self, task: Dict[str, Any], result: Dict[str, Any]):
        """Report task result"""
        self.logger.info(f"Task {task['id']} completed", result=result)
    
    def update_metrics(self, task: Dict[str, Any], result: Dict[str, Any]):
        """Update agent metrics"""
        self.metrics['tasks_completed'] = self.metrics.get('tasks_completed', 0) + 1
        self.metrics['last_task'] = datetime.now().isoformat()
    
    async def handle_error(self, error: Exception):
        """Handle agent errors"""
        self.logger.error(f"Error in {self.name}: {error}")
```

## 🧪 Validation Script

Create `scripts/validate-prerequisites.sh`:
```bash
#!/bin/bash

echo "🔍 Validating Module 28 Prerequisites..."

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check Python
echo -e "\n🐍 Checking Python..."
if command -v python3 &&gt; /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✅ $PYTHON_VERSION${NC}"
    
    # Check key packages
    echo "Checking Python packages..."
    python3 -c "import langchain" 2>/dev/null && echo -e "${GREEN}✅ LangChain${NC}" || echo -e "${YELLOW}⚠️ LangChain not installed${NC}"
    python3 -c "import kubernetes" 2>/dev/null && echo -e "${GREEN}✅ Kubernetes client${NC}" || echo -e "${YELLOW}⚠️ Kubernetes client not installed${NC}"
    python3 -c "import openai" 2>/dev/null && echo -e "${GREEN}✅ OpenAI${NC}" || echo -e "${YELLOW}⚠️ OpenAI not installed${NC}"
else
    echo -e "${RED}❌ Python 3.11+ not found${NC}"
fi

# Check Docker
echo -e "\n🐳 Checking Docker..."
if command -v docker &&gt; /dev/null; then
    if docker ps &&gt; /dev/null; then
        DOCKER_VERSION=$(docker --version)
        echo -e "${GREEN}✅ $DOCKER_VERSION${NC}"
        echo -e "${GREEN}✅ Docker daemon is running${NC}"
    else
        echo -e "${YELLOW}⚠️ Docker installed but daemon not running${NC}"
    fi
else
    echo -e "${RED}❌ Docker not found${NC}"
fi

# Check Kubernetes
echo -e "\n☸️ Checking Kubernetes..."
if command -v kubectl &&gt; /dev/null; then
    KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null || kubectl version --client)
    echo -e "${GREEN}✅ kubectl installed${NC}"
    
    # Check cluster connection
    if kubectl cluster-info &&gt; /dev/null; then
        echo -e "${GREEN}✅ Connected to Kubernetes cluster${NC}"
    else
        echo -e "${YELLOW}⚠️ No Kubernetes cluster connection${NC}"
    fi
else
    echo -e "${RED}❌ kubectl not found${NC}"
fi

# Check Terraform
echo -e "\n🏗️ Checking Terraform..."
if command -v terraform &&gt; /dev/null; then
    TERRAFORM_VERSION=$(terraform version -json | jq -r .terraform_version 2>/dev/null || terraform version | head -n1)
    echo -e "${GREEN}✅ Terraform: $TERRAFORM_VERSION${NC}"
else
    echo -e "${YELLOW}⚠️ Terraform not found (optional)${NC}"
fi

# Check Helm
echo -e "\n⎈ Checking Helm..."
if command -v helm &&gt; /dev/null; then
    HELM_VERSION=$(helm version --short)
    echo -e "${GREEN}✅ $HELM_VERSION${NC}"
else
    echo -e "${YELLOW}⚠️ Helm not found (optional)${NC}"
fi

# Check Git
echo -e "\n📦 Checking Git..."
if command -v git &&gt; /dev/null; then
    GIT_VERSION=$(git --version)
    echo -e "${GREEN}✅ $GIT_VERSION${NC}"
else
    echo -e "${RED}❌ Git not found${NC}"
fi

# Check Security Tools
echo -e "\n🔒 Checking Security Tools..."
command -v trivy &&gt; /dev/null && echo -e "${GREEN}✅ Trivy${NC}" || echo -e "${YELLOW}⚠️ Trivy not installed${NC}"
command -v opa &&gt; /dev/null && echo -e "${GREEN}✅ OPA${NC}" || echo -e "${YELLOW}⚠️ OPA not installed${NC}"

# Check Monitoring
echo -e "\n📊 Checking Monitoring Stack..."
if curl -s http://localhost:9090/-/healthy &&gt; /dev/null; then
    echo -e "${GREEN}✅ Prometheus is running${NC}"
else
    echo -e "${YELLOW}⚠️ Prometheus not accessible${NC}"
fi

if curl -s http://localhost:3000/api/health &&gt; /dev/null; then
    echo -e "${GREEN}✅ Grafana is running${NC}"
else
    echo -e "${YELLOW}⚠️ Grafana not accessible${NC}"
fi

# Test Python agent setup
echo -e "\n🤖 Testing Agent Setup..."
python3 &lt;&lt; 'EOF'
try:
    from langchain.agents import AgentExecutor
    from langchain.memory import ConversationBufferMemory
    print("✅ LangChain agent components working")
except Exception as e:
    print(f"❌ Agent setup error: {e}")
EOF

echo -e "\n✅ Prerequisites check complete!"
```

Make executable:
```bash
chmod +x scripts/validate-prerequisites.sh
./scripts/validate-prerequisites.sh
```

## 📊 Resource Requirements

### Minimum System Requirements
- **CPU**: 8 cores (16 recommended)
- **RAM**: 16GB (32GB recommended)
- **Storage**: 50GB free space
- **OS**: Windows 10/11, macOS 12+, or Linux

### Cloud Resources (Optional)
- **AWS**: t3.large instances or equivalent
- **Azure**: Standard_D4s_v3 or equivalent
- **GCP**: n2-standard-4 or equivalent

## 🚨 Common Setup Issues

### Issue: Kubernetes Connection Failed
```bash
# Create local cluster with kind
kind create cluster --name agentic-devops

# Or use minikube
minikube start --cpus=4 --memory=8192
```

### Issue: Python Package Conflicts
```bash
# Use conda for better isolation
conda create -n agentic-devops python=3.11
conda activate agentic-devops
pip install -r requirements.txt
```

### Issue: Docker Permission Denied
```bash
# Linux: Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Restart Docker service
sudo systemctl restart docker
```

## 📚 Pre-Module Learning

Before starting, review:

1. **DevOps Concepts**
   - [The DevOps Handbook](https://itrevolution.com/product/the-devops-handbook/)
   - [Site Reliability Engineering](https://sre.google/books/)
   - [Kubernetes Documentation](https://kubernetes.io/docs/)

2. **AI Agent Development**
   - [LangChain Documentation](https://python.langchain.com/docs/)
   - [AutoGen Tutorial](https://microsoft.github.io/autogen/)
   - [CrewAI Guide](https://github.com/joaomdmoura/crewAI)

3. **Security Best Practices**
   - [OWASP DevSecOps Guideline](https://owasp.org/www-project-devsecops-guideline/)
   - [Cloud Native Security](https://www.cncf.io/cloud-native-security-whitepaper/)

## ✅ Pre-Module Checklist

Before starting the exercises:

- [ ] Python 3.11+ environment ready
- [ ] Docker and Kubernetes running
- [ ] AI API keys configured
- [ ] Git repository initialized
- [ ] Monitoring stack deployed
- [ ] Security tools installed
- [ ] Validation script passes

## 🎯 Ready to Start?

Once all prerequisites are met:

1. Review the module [README](./index)
2. Understand agentic architectures
3. Start with [Exercise 1: Agentic CI/CD](./exercise1-overview)
4. Join the module discussion for help

---

**Need Help?** Check the [Module 28 Troubleshooting Guide](/docs/guias/troubleshooting) or post in the module discussions.