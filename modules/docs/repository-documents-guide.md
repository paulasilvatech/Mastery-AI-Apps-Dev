# 📚 Repository-Level Documents Guide

This guide provides templates and examples for all required repository-level documentation.

## 1. PREREQUISITES.md

```markdown
# Prerequisites for Mastery AI Code Development Workshop

## 🖥️ Hardware Requirements

### Minimum
- **CPU**: 4 cores (Intel i5/AMD Ryzen 5 or equivalent)
- **RAM**: 16GB
- **Storage**: 256GB SSD with 100GB free
- **Network**: Stable broadband (25+ Mbps)

### Recommended
- **CPU**: 8+ cores (Intel i7/AMD Ryzen 7 or better)
- **RAM**: 32GB
- **Storage**: 512GB SSD
- **Network**: High-speed connection (100+ Mbps)

## 💻 Software Requirements

### Operating System
- Windows 11 (version 22H2 or later)
- macOS 12 Monterey or later
- Ubuntu 20.04 LTS or later

### Development Tools
```bash
# Required versions
git >= 2.38.0
node >= 18.0.0
python >= 3.11.0
dotnet >= 8.0.0
docker >= 24.0.0
```

### IDE and Extensions
- **Visual Studio Code** (latest)
  - GitHub Copilot extension
  - Python extension
  - C# extension
  - Docker extension
  - Azure Tools extension pack

## 🔑 Accounts and Access

### Required Accounts
1. **GitHub Account**
   - GitHub Copilot subscription (individual or business)
   - Access to GitHub Models (preview)
   
2. **Azure Account**
   - Active subscription (free tier acceptable for most modules)
   - Resource providers registered:
     - Microsoft.CognitiveServices
     - Microsoft.ContainerService
     - Microsoft.Web

3. **Microsoft Account**
   - For Azure portal access
   - Microsoft Learn access

## 🛠️ Pre-Workshop Setup

### Step 1: Install Core Tools
```bash
# Windows (using Chocolatey)
choco install git nodejs python dotnet-sdk docker-desktop vscode azure-cli

# macOS (using Homebrew)
brew install git node python@3.11 dotnet docker visual-studio-code azure-cli

# Linux (Ubuntu/Debian)
sudo apt update
sudo apt install git nodejs python3.11 dotnet-sdk-8.0 docker.io code azure-cli
```

### Step 2: Configure Git
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Step 3: Verify Installations
Run the verification script:
```bash
./scripts/validate-prerequisites.sh
```

## 📋 Track-Specific Prerequisites

### Fundamentals Track (Modules 1-5)
- Basic programming knowledge (any language)
- Understanding of version control concepts

### Intermediate Track (Modules 6-10)
- Completed Fundamentals track
- Basic web development understanding
- Familiarity with databases

### Advanced Track (Modules 11-15)
- Completed Intermediate track
- Basic cloud computing concepts
- Understanding of distributed systems

### Enterprise Track (Modules 16-20)
- Completed Advanced track
- Exposure to production systems
- Basic security awareness

### AI Agents Track (Modules 21-25)
- Completed Enterprise track
- Understanding of async programming
- API development experience

### Enterprise Mastery Track (Modules 26-30)
- All previous tracks completed
- .NET development experience (for Module 26)
- Enterprise architecture concepts
```

## 2. QUICKSTART.md

```markdown
# 🚀 Quick Start Guide - 5 Minutes to First AI Code

## 1️⃣ Clone the Workshop (30 seconds)
```bash
git clone https://github.com/your-org/mastery-ai-code-development.git
cd mastery-ai-code-development
```

## 2️⃣ Run Setup Script (2 minutes)
```bash
# Windows
./scripts/setup-workshop.ps1

# macOS/Linux
./scripts/setup-workshop.sh
```

## 3️⃣ Verify Setup (30 seconds)
```bash
./scripts/quick-verify.sh
```

## 4️⃣ Start Your First Module (2 minutes)
```bash
cd modules/module-01-introduction
code .
```

## 5️⃣ Write Your First AI-Assisted Code
1. Open `exercise1/starter/hello_ai.py`
2. Type this comment:
   ```python
   # Create a function that generates a personalized welcome message
   ```
3. Press `Tab` to accept Copilot's suggestion
4. Run the code: `python hello_ai.py`

## 🎉 Congratulations!
You've just written your first AI-assisted code! Continue with the full Module 1 exercises.

## ⚡ Next Steps
- Complete Module 1 exercises
- Read the main README for workshop overview
- Join the workshop GitHub Discussions
- Explore the resource library

## 🆘 Need Help?
- Check [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)
- Review [FAQ.md](../FAQ.md)
- Search existing GitHub Issues
```

## 3. TROUBLESHOOTING.md

```markdown
# 🔧 Troubleshooting Guide

## Common Issues and Solutions

### 🚫 GitHub Copilot Not Working

#### Symptoms
- No code suggestions appearing
- "GitHub Copilot is not available" message

#### Solutions
1. **Verify subscription**:
   ```bash
   gh copilot status
   ```

2. **Re-authenticate**:
   ```bash
   gh auth refresh -s copilot
   ```

3. **Check VS Code settings**:
   - Open Settings (Ctrl/Cmd + ,)
   - Search "copilot"
   - Ensure "Enable" is checked

4. **Restart VS Code**

### 🔴 Azure Resource Creation Fails

#### Error: "The subscription is not registered"
```bash
# Register required providers
az provider register --namespace Microsoft.CognitiveServices
az provider register --namespace Microsoft.Web
az provider register --namespace Microsoft.ContainerService
```

#### Error: "Quota exceeded"
- Use a different region
- Request quota increase
- Use smaller SKUs for learning

### 🐍 Python Environment Issues

#### Virtual Environment Not Activating
```bash
# Windows
python -m venv venv
.\venv\Scripts\activate

# macOS/Linux
python3 -m venv venv
source venv/bin/activate
```

#### Package Installation Fails
```bash
# Upgrade pip first
python -m pip install --upgrade pip

# Use specific index
pip install -r requirements.txt --index-url https://pypi.org/simple
```

### 🐳 Docker Issues

#### Docker Desktop Not Starting
1. Enable virtualization in BIOS
2. Windows: Enable WSL2
3. Check system resources (RAM/disk)

#### Container Build Fails
```bash
# Clean Docker cache
docker system prune -a
docker builder prune

# Rebuild with no cache
docker build --no-cache -t myapp .
```

### 🔗 MCP Connection Issues

#### MCP Server Not Responding
1. Check server logs:
   ```bash
   docker logs mcp-server
   ```

2. Verify port availability:
   ```bash
   netstat -an | grep 8080
   ```

3. Test connection:
   ```bash
   curl -X POST http://localhost:8080/v1/tools/list
   ```

## Module-Specific Issues

### Module 23 (MCP)
- Ensure Node.js version 18+
- Check firewall settings
- Verify JSON-RPC format

### Module 26 (.NET)
- Clear NuGet cache: `dotnet nuget locals all --clear`
- Restore packages: `dotnet restore`

## Performance Issues

### Slow Copilot Suggestions
1. Check network latency
2. Reduce file size
3. Clear VS Code cache
4. Disable unnecessary extensions

### High Resource Usage
1. Limit Docker resources
2. Close unused applications
3. Increase swap space

## 🔍 Diagnostic Commands

```bash
# System information
./scripts/diagnostic.sh

# Module-specific checks
./scripts/check-module.sh [module-number]

# Resource usage
docker stats
htop  # Linux/macOS
```
```

## 4. FAQ.md

```markdown
# ❓ Frequently Asked Questions

## General Questions

### Q: How long does the complete workshop take?
**A:** The workshop contains 30 modules, each designed for 3 hours. Total time is 90 hours of content. Most participants complete it in 3-6 months depending on their pace and prior experience.

### Q: Can I skip modules?
**A:** Modules are designed to build on each other. While you can skip, we strongly recommend following the sequence for best results. Each track has prerequisites clearly marked.

### Q: What if I get stuck on an exercise?
**A:** Each exercise includes:
- Step-by-step instructions
- Starter code
- Complete solutions
- Troubleshooting guide

Start with the instructions, try the starter code, and reference the solution if needed.

## Technical Questions

### Q: Do I need to pay for GitHub Copilot?
**A:** Yes, GitHub Copilot requires a subscription ($10/month individual or $19/month business). There's a 30-day free trial available.

### Q: Can I use the Azure free tier?
**A:** Yes, most modules work with Azure free tier. Modules 16-30 may require paid services, but costs are minimal (<$50/month if following cleanup procedures).

### Q: What programming languages do I need to know?
**A:** 
- Python (primary language, modules 1-25)
- Basic JavaScript/TypeScript (agent modules 21-25)
- C#/.NET (module 26 and 29)
- COBOL knowledge helpful but not required (module 27)

### Q: Is Windows required?
**A:** No, the workshop supports Windows, macOS, and Linux. Some minor adjustments may be needed for scripts on different platforms.

## Learning Path Questions

### Q: I'm a beginner. Where should I start?
**A:** Start with Module 1 and progress sequentially. The Fundamentals track (1-5) is designed for beginners with basic programming knowledge.

### Q: I'm experienced. Can I fast-track?
**A:** Yes! Complete the prerequisite checker for each track. You might start at Module 6 or 11 depending on your experience.

### Q: What's the difference between exercises?
**A:**
- ⭐ Easy (30-45 min): Guided, step-by-step
- ⭐⭐ Medium (45-60 min): Partial guidance, real scenarios
- ⭐⭐⭐ Hard (60-90 min): Minimal guidance, production-like

## AI and Agent Questions

### Q: What is MCP?
**A:** Model Context Protocol (MCP) is a standard for AI agents to communicate with external tools and systems. Module 23 covers this in depth.

### Q: Do I need to understand agents before Module 21?
**A:** No, but you should complete modules 1-20 first. The agent modules (21-25) build on previous concepts.

### Q: Can I build my own agents after this workshop?
**A:** Absolutely! Modules 21-25 teach you everything needed to build production-ready AI agents.

## Resource Questions

### Q: How do I clean up Azure resources?
**A:** Run the cleanup script after each module:
```bash
./scripts/cleanup-resources.sh --module [number]
```

### Q: Where are the exercise solutions?
**A:** In each exercise folder: `modules/module-XX/exercises/exerciseY/solution/`

### Q: Can I use this workshop for my team?
**A:** Yes, the workshop is designed for both individual and team learning. See the team learning guide in the main README.
```

## 5. PROMPT-GUIDE.md

```markdown
# 🤖 AI Prompting Best Practices Guide

## Core Principles

### 1. Be Specific and Clear
❌ **Poor**: "Create a function"
✅ **Good**: "Create a Python function that validates email addresses using regex"
✅ **Better**: "Create a Python function that validates email addresses using regex, returns boolean, handles None input, and includes docstring with examples"

### 2. Provide Context
```python
# Context: Building a REST API for user management
# Need: Function to hash passwords securely
# Requirements: Use bcrypt, handle salting, return string
# Create a password hashing function
```

### 3. Specify Constraints
```python
# Create a rate limiter class that:
# - Limits to 100 requests per minute
# - Uses Redis for distributed state
# - Thread-safe implementation
# - Returns remaining requests in response
# - Handles Redis connection failures gracefully
```

## Effective Patterns

### Pattern 1: Stepwise Refinement
```python
# Step 1: Create basic structure
# Create a class for managing database connections

# Step 2: Add specific features
# Add connection pooling with max 10 connections

# Step 3: Add error handling
# Add retry logic with exponential backoff
```

### Pattern 2: Example-Driven
```python
# Create a function like this example:
# Input: ["apple", "banana", "apple", "orange", "banana", "apple"]
# Output: {"apple": 3, "banana": 2, "orange": 1}
# But handle any hashable type, not just strings
```

### Pattern 3: Test-First
```python
# Create a function that passes these tests:
# assert calculate_discount(100, 0.1) == 90
# assert calculate_discount(100, 0) == 100
# assert calculate_discount(100, 1) == 0
# Handles invalid inputs by raising ValueError
```

## GitHub Copilot Specific Tips

### 1. Use Comments Strategically
```python
# TODO: Implement caching here
def get_user_data(user_id):
    # Check cache first
    # If not in cache, query database
    # Cache the result with 5-minute TTL
    # Return user data
```

### 2. Leverage Type Hints
```python
from typing import List, Dict, Optional
from datetime import datetime

def process_transactions(
    transactions: List[Dict[str, any]], 
    start_date: Optional[datetime] = None
) -> Dict[str, float]:
    # Copilot will understand the expected types
```

### 3. Natural Language in Docstrings
```python
def optimize_route(locations):
    """
    Find the shortest route visiting all locations exactly once.
    
    This is the traveling salesman problem. Use a greedy approach
    for simplicity: always visit the nearest unvisited location.
    
    Args:
        locations: List of (x, y) coordinate tuples
        
    Returns:
        Ordered list of locations representing the route
    """
```

## Agent Development Prompts

### Creating Agents
```typescript
// Create an MCP server that:
// - Exposes a weather tool
// - Accepts city name as parameter
// - Returns temperature, conditions, and forecast
// - Handles errors gracefully
// - Implements rate limiting
// - Uses OpenWeatherMap API
```

### Multi-Agent Orchestration
```python
# Create an orchestrator that coordinates:
# - Research Agent: Gathers information from web
# - Analysis Agent: Processes and summarizes data
# - Writer Agent: Creates final report
# Agents communicate via message queue
# Handle agent failures with circuit breaker pattern
```

## Advanced Techniques

### 1. Chain-of-Thought Prompting
```python
# Implement a complex calculation step by step:
# 1. First, validate all inputs are positive numbers
# 2. Then, calculate the base price using formula: base = quantity * unit_price
# 3. Apply tiered discount based on quantity thresholds
# 4. Add tax based on customer location
# 5. Round to 2 decimal places
# 6. Return detailed breakdown object
```

### 2. Iterative Refinement
```python
# Create basic version first
class DataProcessor:
    pass

# Now add initialization with configuration
# Now add data validation method
# Now add processing logic with error handling
# Now add logging throughout
# Now add performance metrics
```

### 3. Edge Case Handling
```python
# Create a URL parser that handles:
# - Standard HTTP/HTTPS URLs
# - URLs with ports (example.com:8080)
# - URLs with authentication (user:pass@example.com)
# - URLs with query parameters and fragments
# - International domains (münchen.de)
# - IP addresses (192.168.1.1)
# - Missing protocol (assume https)
# - Trailing slashes
# Return None for invalid URLs
```

## Do's and Don'ts

### Do's ✅
- Include expected input/output examples
- Specify error handling requirements
- Mention performance considerations
- Add security requirements upfront
- Use consistent naming conventions

### Don'ts ❌
- Don't be vague ("make it better")
- Don't assume context without providing it
- Don't request impossible combinations
- Don't ignore language idioms
- Don't skip validation requirements

## Module-Specific Prompting

### For Web Development (Modules 7-8)
- Specify framework (FastAPI, Flask, etc.)
- Include route patterns
- Mention authentication needs
- Define response formats

### For Cloud/DevOps (Modules 12-14)
- Specify cloud provider (Azure)
- Include resource constraints
- Mention security requirements
- Define scaling parameters

### For Agents (Modules 21-25)
- Define agent capabilities clearly
- Specify communication protocols
- Include state management needs
- Define error recovery strategies

## Debugging with AI

### Effective Error Prompts
```python
# Getting error: "KeyError: 'user_id'"
# Stack trace shows error in line 45 of auth.py
# The function is trying to extract user_id from JWT token
# Help me fix this error and handle missing claims gracefully
```

### Performance Optimization
```python
# This function takes 5 seconds for 1000 items
# Profile shows bottleneck in database queries
# Optimize using batch operations and caching
# Maintain same interface and behavior
```

## Remember

1. **Iterate**: First prompt rarely perfect
2. **Experiment**: Try different approaches
3. **Learn**: Save effective prompts
4. **Adapt**: Adjust to Copilot's updates
5. **Combine**: Use multiple techniques together

The best prompt is one that clearly communicates your intent while providing enough context for accurate assistance.
```

## 6. GITOPS-GUIDE.md

```markdown
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
mastery-ai-workshop/
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

1. **Branch Protection**
   - Require PR reviews
   - Enforce status checks
   - Restrict direct pushes

2. **Environment Promotion**
   ```
   feature/* → dev → staging → main (prod)
   ```

3. **Rollback Strategy**
   ```bash
   # Quick rollback
   git revert <commit>
   git push
   # GitOps automatically rolls back
   ```

4. **Drift Detection**
   ```yaml
   # Scheduled drift detection
   - cron: "0 * * * *"
     jobs:
       - name: detect-drift
         plan: true
         workspace: production
   ```

## GitOps Tools Used

1. **GitHub Actions**: CI/CD automation
2. **Terraform**: Infrastructure provisioning
3. **Flux/ArgoCD**: Kubernetes GitOps
4. **Kustomize**: Kubernetes customization
5. **Helm**: Package management

## Workshop-Specific GitOps

Each module includes:
- `.gitops/` directory with configurations
- Automated deployment on merge
- Environment-specific overrides
- Rollback procedures

Remember: GitOps is about treating operations like development - everything in Git, everything automated, everything observable.
```

## Additional Repository Structure

```markdown
# Repository Structure with Required Documents

mastery-ai-code-development/
├── README.md                      # Main workshop overview
├── PREREQUISITES.md               # Detailed setup requirements
├── QUICKSTART.md                 # 5-minute getting started
├── TROUBLESHOOTING.md            # Common issues and solutions
├── FAQ.md                        # Frequently asked questions
├── PROMPT-GUIDE.md               # AI prompting best practices
├── GITOPS-GUIDE.md               # GitOps implementation
├── scripts/                      # Repository-wide scripts
│   ├── setup-workshop.sh
│   ├── validate-prerequisites.sh
│   ├── cleanup-resources.sh
│   └── quick-start.sh
├── infrastructure/               # IaC templates
│   ├── bicep/
│   │   ├── main.bicep
│   │   ├── modules/
│   │   └── parameters/
│   ├── terraform/
│   ├── github-actions/
│   └── arm-templates/
├── docs/                        # Additional documentation
│   ├── architecture-decisions.md
│   ├── security-guidelines.md
│   ├── cost-optimization.md
│   └── monitoring-setup.md
└── modules/                     # 30 workshop modules
    ├── module-01-introduction/
    ├── module-02-copilot-fundamentals/
    └── ... (through module-30)
```
