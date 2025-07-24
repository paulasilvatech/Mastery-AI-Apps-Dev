---
sidebar_position: 3
title: "Exercise 3: Part 1"
description: "**Duration:** 60-90 minutes"
---

# Exercício 3: Empresarial Pipeline with AI (⭐⭐⭐)

**Duração:** 60-90 minutos  
**Difficulty:** Difícil  
**Success Rate:** 60%

## 🎯 Objetivos de Aprendizagem

In this advanced exercise, you will:
- Build a self-optimizing CI/CD pipeline using AI
- Implement intelligent failure prediction and prevention
- Create adaptive implantação strategies based on metrics
- Integrate GitHub Copilot for workflow generation
- Build custom GitHub Actions with AI capabilities
- Implement cost optimization through intelligent scheduling
- Create comprehensive observability with AI insights

## 📋 Scenario

You're the DevOps lead for an enterprise application serving millions of users. The CEO wants a "self-healing, self-optimizing" implantação pipeline that can predict failures, optimize costs, and adapt implantação strategies based on real-time metrics. You'll leverage AI at every stage of the pipeline.

## 🏗️ Architecture Visão Geral

```mermaid
graph TB
    subgraph "AI-Powered Pipeline"
        A[Code Push] --&gt; B[AI Code Analysis]
        B --&gt; C{Risk Score}
        C --&gt;|High Risk| D[Extended Testing]
        C --&gt;|Low Risk| E[Standard Testing]
        
        D --&gt; F[AI Test Generation]
        E --&gt; F
        
        F --&gt; G[Predictive Failure Analysis]
        G --&gt; H{Deploy Strategy}
        
        H --&gt;|Safe| I[Progressive Rollout]
        H --&gt;|Risky| J[Canary Deployment]
        H --&gt;|Critical| K[Blue-Green]
        
        I --&gt; L[AI Monitoring]
        J --&gt; L
        K --&gt; L
        
        L --&gt; M{Anomaly Detection}
        M --&gt;|Issue| N[Auto Rollback]
        M --&gt;|Success| O[Scale Decision]
        
        O --&gt; P[Cost Optimization]
    end
    
    style B fill:#f9f,stroke:#333,stroke-width:4px
    style G fill:#f9f,stroke:#333,stroke-width:4px
    style L fill:#f9f,stroke:#333,stroke-width:4px
```

## 📝 Partee 1: AI-Powered Code Analysis and Risk Assessment

### Step 1: Create AI Analysis Action

Let's create a custom GitHub Action that uses AI to analyze code changes:

**.github/actions/ai-code-analysis/action.yml:**

**Copilot Prompt Suggestion:**
```yaml
# Create a composite action that:
# - Analyzes code changes using git diff
# - Sends changes to OpenAI for risk assessment
# - Evaluates complexity, security risks, and potential bugs
# - Generates a risk score (0-100)
# - Suggests appropriate testing strategies
# - Creates detailed analysis report
# Include inputs for OpenAI API key and model selection
```

**Expected Output:**
```yaml
name: 'AI Code Analysis'
description: 'Analyze code changes and assess deployment risk using AI'
inputs:
  openai-api-key:
    description: 'OpenAI API Key'
    required: true
  github-token:
    description: 'GitHub Token'
    required: true
  base-branch:
    description: 'Base branch for comparison'
    default: 'main'
  model:
    description: 'OpenAI model to use'
    default: 'gpt-4'

outputs:
  risk-score:
    description: 'Risk score (0-100)'
    value: ${{ steps.analyze.outputs.risk-score }}
  analysis-report:
    description: 'Detailed analysis report'
    value: ${{ steps.analyze.outputs.report }}
  recommended-tests:
    description: 'AI-recommended test scenarios'
    value: ${{ steps.analyze.outputs.tests }}

runs:
  using: 'composite'
  steps:
    - name: Get code changes
      id: diff
      shell: bash
      run: |
        # Get diff between current branch and base
        git fetch origin ${{ inputs.base-branch }}
        DIFF=$(git diff origin/${{ inputs.base-branch }}...HEAD --unified=5)
        
        # Get list of changed files
        CHANGED_FILES=$(git diff --name-only origin/${{ inputs.base-branch }}...HEAD)
        
        # Save diff to file for processing
        echo "$DIFF" &gt; diff.txt
        echo "$CHANGED_FILES" &gt; changed_files.txt
        
        # Calculate basic metrics
        LINES_ADDED=$(git diff --stat origin/${{ inputs.base-branch }}...HEAD | grep -E '[0-9]+ insertion' | grep -oE '[0-9]+' | head -1)
        LINES_DELETED=$(git diff --stat origin/${{ inputs.base-branch }}...HEAD | grep -E '[0-9]+ deletion' | grep -oE '[0-9]+' | head -1)
        FILES_CHANGED=$(echo "$CHANGED_FILES" | wc -l)
        
        echo "lines-added=$LINES_ADDED" &gt;&gt; $GITHUB_OUTPUT
        echo "lines-deleted=$LINES_DELETED" &gt;&gt; $GITHUB_OUTPUT
        echo "files-changed=$FILES_CHANGED" &gt;&gt; $GITHUB_OUTPUT
    
    - name: Analyze with AI
      id: analyze
      shell: python
      env:
        OPENAI_API_KEY: ${{ inputs.openai-api-key }}
      run: |
        import os
        import json
        import openai
        from pathlib import Path
        
        # Initialize OpenAI
        openai.api_key = os.environ['OPENAI_API_KEY']
        
        # Read diff
        diff_content = Path('diff.txt').read_text()[:3000]  # Limit for API
        changed_files = Path('changed_files.txt').read_text().strip().split('\n')
        
        # Prepare analysis prompt
        prompt = f"""
        Analyze the following code changes and provide a comprehensive risk assessment:
        
        Changed files: {', '.join(changed_files)}
        
        Code diff:
        {diff_content}
        
        Please provide:
        1. Risk score (0-100) based on:
           - Complexity of changes
           - Potential for bugs
           - Security implications
           - Performance impact
           - Breaking changes
        
        2. Detailed analysis including:
           - Main risks identified
           - Specific areas of concern
           - Potential impact on system
        
        3. Recommended test scenarios
        
        Format response as JSON with keys: risk_score, analysis, recommended_tests
        """
        
        # Get AI analysis
        response = openai.ChatCompletion.create(
            model="${{ inputs.model }}",
            messages=[
                {"role": "system", "content": "You are an expert code reviewer and DevOps engineer."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.3
        )
        
        # Parse response
        try:
            result = json.loads(response.choices[0].message.content)
        except:
            # Fallback if JSON parsing fails
            result = {
                "risk_score": 50,
                "analysis": response.choices[0].message.content,
                "recommended_tests": ["standard test suite"]
            }
        
        # Write outputs
        with open(os.environ['GITHUB_OUTPUT'], 'a') as f:
            f.write(f"risk-score={result['risk_score']}\n")
            f.write(f"report={json.dumps(result['analysis'])}\n")
            f.write(f"tests={json.dumps(result['recommended_tests'])}\n")
        
        # Create markdown report
        report_md = f"""
        # AI Code Analysis Report 🤖
        
        ## Risk Assessment
        - **Risk Score:** {result['risk_score']}/100
        - **Files Changed:** {len(changed_files)}
        - **Lines Added:** ${{ steps.diff.outputs.lines-added }}
        - **Lines Deleted:** ${{ steps.diff.outputs.lines-deleted }}
        
        ## Analysis
        {result['analysis']}
        
        ## Recommended Tests
        {chr(10).join([f"- {test}" for test in result['recommended_tests']])}
        """
        
        # Save report
        Path('analysis_report.md').write_text(report_md)
    
    - name: Comment on PR
      if: github.event_name == 'pull_request'
      uses: actions/github-script@v7
      with:
        github-token: ${{ inputs.github-token }}
        script: |
          const fs = require('fs');
          const report = fs.readFileSync('analysis_report.md', 'utf8');
          
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: report
          });
```

### Step 2: Create Intelligent implantação Strategy Selector

**.github/actions/implantação-strategy/action.yml:**

**Copilot Prompt Suggestion:**
```yaml
# Create an action that:
# - Takes risk score and metrics as input
# - Analyzes current system load and error rates
# - Considers time of day and day of week
# - Recommends optimal deployment strategy
# - Configures deployment parameters
# - Provides reasoning for the selection
```

**Expected Output:**
```yaml
name: 'AI Deployment Strategy Selector'
description: 'Select optimal deployment strategy based on risk and metrics'
inputs:
  risk-score:
    description: 'Risk score from code analysis'
    required: true
  metrics-api-endpoint:
    description: 'Endpoint for current metrics'
    required: true
  metrics-api-key:
    description: 'API key for metrics'
    required: true

outputs:
  strategy:
    description: 'Recommended deployment strategy'
    value: ${{ steps.select.outputs.strategy }}
  parameters:
    description: 'Strategy-specific parameters'
    value: ${{ steps.select.outputs.parameters }}
  reasoning:
    description: 'Explanation for strategy selection'
    value: ${{ steps.select.outputs.reasoning }}

runs:
  using: 'composite'
  steps:
    - name: Fetch current metrics
      id: metrics
      shell: bash
      run: |
        # Fetch current system metrics
        METRICS=$(curl -s -H "Authorization: Bearer ${{ inputs.metrics-api-key }}" \
          "${{ inputs.metrics-api-endpoint }}/api/metrics/current")
        
        # Extract key metrics
        ERROR_RATE=$(echo $METRICS | jq -r '.errorRate // 0')
        ACTIVE_USERS=$(echo $METRICS | jq -r '.activeUsers // 0')
        RESPONSE_TIME=$(echo $METRICS | jq -r '.avgResponseTime // 0')
        
        echo "error-rate=$ERROR_RATE" &gt;&gt; $GITHUB_OUTPUT
        echo "active-users=$ACTIVE_USERS" &gt;&gt; $GITHUB_OUTPUT
        echo "response-time=$RESPONSE_TIME" &gt;&gt; $GITHUB_OUTPUT
    
    - name: Select deployment strategy
      id: select
      shell: python
      run: |
        import os
        import json
        from datetime import datetime
        
        # Input parameters
        risk_score = int("${{ inputs.risk-score }}")
        error_rate = float("${{ steps.metrics.outputs.error-rate }}")
        active_users = int("${{ steps.metrics.outputs.active-users }}")
        response_time = float("${{ steps.metrics.outputs.response-time }}")
        
        # Time-based factors
        now = datetime.utcnow()
        is_business_hours = 9 &lt;= now.hour &lt;= 17
        is_weekday = now.weekday() &lt; 5
        is_peak_time = is_business_hours and is_weekday
        
        # Strategy selection logic
        if risk_score &gt; 80 or error_rate &gt; 5:
            strategy = "blue-green"
            parameters = {
                "pre_deployment_wait": 300,
                "health_check_interval": 30,
                "rollback_threshold": 1,
                "smoke_test_duration": 600
            }
            reasoning = f"High risk score ({risk_score}) or error rate ({error_rate}%) requires safest deployment method"
        
        elif risk_score &gt; 50 or is_peak_time:
            strategy = "canary"
            parameters = {
                "initial_percentage": 5,
                "increment": 10,
                "interval_minutes": 15,
                "success_threshold": 99.5,
                "max_duration": 120
            }
            reasoning = f"Medium risk ({risk_score}) or peak time deployment needs gradual rollout"
        
        elif active_users &lt; 1000 and not is_peak_time:
            strategy = "rolling"
            parameters = {
                "batch_size": 33,
                "pause_between_batches": 60,
                "health_check_wait": 30
            }
            reasoning = f"Low traffic ({active_users} users) allows standard rolling deployment"
        
        else:
            strategy = "progressive"
            parameters = {
                "stages": [10, 25, 50, 100],
                "stage_duration": 300,
                "metrics_threshold": {
                    "error_rate": 1,
                    "response_time": 1000
                }
            }
            reasoning = "Default progressive deployment for balanced risk and impact"
        
        # Adjust parameters based on current metrics
        if response_time &gt; 500:
            parameters["health_check_wait"] = parameters.get("health_check_wait", 30) * 2
            reasoning += f". Extended health checks due to high response time ({response_time}ms)"
        
        # Write outputs
        with open(os.environ['GITHUB_OUTPUT'], 'a') as f:
            f.write(f"strategy={strategy}\n")
            f.write(f"parameters={json.dumps(parameters)}\n")
            f.write(f"reasoning={reasoning}\n")
        
        # Create summary
        print(f"Selected Strategy: {strategy}")
        print(f"Reasoning: {reasoning}")
        print(f"Parameters: {json.dumps(parameters, indent=2)}")
```

### Step 3: Create the Main Empresarial Pipeline

**.github/workflows/enterprise-pipeline.yml:**

```yaml
name: Enterprise AI-Powered Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 2 * * *'  # Nightly builds

env:
  PYTHON_VERSION: '3.11'
  NODE_VERSION: '18'

jobs:
  ai-analysis:
    name: AI Code Analysis
    runs-on: ubuntu-latest
    outputs:
      risk-score: ${{ steps.ai-analyze.outputs.risk-score }}
      analysis-report: ${{ steps.ai-analyze.outputs.analysis-report }}
      recommended-tests: ${{ steps.ai-analyze.outputs.recommended-tests }}
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      with:
        fetch-depth: 0  # Full history for analysis
    
    - name: AI Code Analysis
      id: ai-analyze
      uses: ./.github/actions/ai-code-analysis
      with:
        openai-api-key: ${{ secrets.OPENAI_API_KEY }}
        github-token: ${{ secrets.GITHUB_TOKEN }}
        base-branch: ${{ github.base_ref || 'main' }}
    
    - name: Upload analysis report
      uses: actions/upload-artifact@v3
      with:
        name: ai-analysis-report
        path: analysis_report.md
```

**Continuar to Partee 2 for test generation and implantação...**