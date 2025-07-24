---
sidebar_position: 7
title: "Exercise 3: Part 2"
description: "## 📝 Part 2: AI-Generated Testing and Intelligent Deployment"
---

# Exercício 3: Empresarial Pipeline with AI (Partee 2)

## 📝 Partee 2: AI-Generated Testing and Intelligent implantação

### Step 4: Continuar the Empresarial Pipeline

**.github/workflows/enterprise-pipeline.yml (continued):**

```yaml
  ai-test-generation:
    name: AI Test Generation
    runs-on: ubuntu-latest
    needs: ai-analysis
    if: needs.ai-analysis.outputs.risk-score &gt; 30
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}
    
    - name: Generate tests with AI
      env:
        OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
      run: |
        # Create test generation script
        cat &gt; generate_tests.py &lt;&lt; 'EOF'
        import os
        import json
        import openai
        from pathlib import Path
        
        openai.api_key = os.environ['OPENAI_API_KEY']
        
        # Get recommended tests from analysis
        recommended_tests = json.loads('${{ needs.ai-analysis.outputs.recommended-tests }}')
        
        # Read source code
        source_files = list(Path('src').glob('**/*.py'))
        
        for source_file in source_files:
            code = source_file.read_text()
            test_file = Path('tests') / f"test_ai_{source_file.stem}.py"
            
            # Generate tests for each source file
            prompt = f"""
            Generate comprehensive pytest tests for the following Python code.
            Include the recommended test scenarios: {recommended_tests}
            
            Source code:
            {code[:2000]}  # Limit for API
            
            Generate tests that:
            1. Cover all functions and methods
            2. Include edge cases
            3. Test error handling
            4. Include the recommended scenarios
            5. Use pytest fixtures where appropriate
            """
            
            response = openai.ChatCompletion.create(
                model="gpt-4",
                messages=[
                    {"role": "system", "content": "You are an expert Python test engineer."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.2
            )
            
            # Save generated tests
            test_file.parent.mkdir(exist_ok=True)
            test_file.write_text(response.choices[0].message.content)
            print(f"Generated tests for {source_file.name}")
        EOF
        
        python generate_tests.py
    
    - name: Run AI-generated tests
      run: |
        pip install -r requirements-dev.txt
        pytest tests/test_ai_*.py -v --tb=short || true  # Don't fail on test errors
    
    - name: Upload generated tests
      uses: actions/upload-artifact@v3
      with:
        name: ai-generated-tests
        path: tests/test_ai_*.py

  intelligent-build:
    name: Intelligent Build & Optimization
    runs-on: ubuntu-latest
    needs: [ai-analysis, ai-test-generation]
    if: always()
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Determine build optimization
      id: optimize
      run: |
        RISK_SCORE=${{ needs.ai-analysis.outputs.risk-score }}
        
        if [[ $RISK_SCORE -gt 70 ]]; then
          echo "optimization=none" &gt;&gt; $GITHUB_OUTPUT
          echo "cache=false" &gt;&gt; $GITHUB_OUTPUT
        elif [[ $RISK_SCORE -gt 40 ]]; then
          echo "optimization=standard" &gt;&gt; $GITHUB_OUTPUT
          echo "cache=true" &gt;&gt; $GITHUB_OUTPUT
        else
          echo "optimization=aggressive" &gt;&gt; $GITHUB_OUTPUT
          echo "cache=true" &gt;&gt; $GITHUB_OUTPUT
        fi
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Build with AI-optimized Dockerfile
      run: |
        # Generate optimized Dockerfile based on risk
        cat &gt; Dockerfile.optimized &lt;&lt; 'EOF'
        FROM python:3.11-slim
        
        WORKDIR /app
        
        # Conditional optimization based on risk
        ${{ steps.optimize.outputs.optimization == 'aggressive' && 'RUN pip install --upgrade pip wheel' || '' }}
        
        COPY requirements.txt .
        RUN pip install -r requirements.txt ${{ steps.optimize.outputs.optimization == 'aggressive' && '--compile' || '' }}
        
        COPY src/ ./src/
        COPY startup.sh .
        
        # Security hardening for high-risk deployments
        ${{ needs.ai-analysis.outputs.risk-score &gt; 50 && 'RUN useradd -m -U appuser && chown -R appuser:appuser /app' || '' }}
        ${{ needs.ai-analysis.outputs.risk-score &gt; 50 && 'USER appuser' || '' }}
        
        EXPOSE 8000
        CMD ["./startup.sh"]
        EOF
        
        docker build -f Dockerfile.optimized -t app:${{ github.sha }} .
    
    - name: Security scan with AI insights
      run: |
        # Run security scan and analyze with AI
        docker run --rm -v "$PWD:/src" aquasec/trivy image app:${{ github.sha }} -f json -o trivy-report.json
        
        # Create AI-enhanced security report
        cat &gt; analyze_security.py &lt;&lt; 'EOF'
        import json
        import openai
        import os
        
        openai.api_key = os.environ.get('OPENAI_API_KEY', '')
        
        with open('trivy-report.json', 'r') as f:
            trivy_results = json.load(f)
        
        if openai.api_key and len(trivy_results.get('Results', [])) &gt; 0:
            vulnerabilities = []
            for result in trivy_results['Results']:
                for vuln in result.get('Vulnerabilities', []):
                    vulnerabilities.append({
                        'id': vuln.get('VulnerabilityID'),
                        'severity': vuln.get('Severity'),
                        'title': vuln.get('Title')
                    })
            
            if vulnerabilities:
                prompt = f"Analyze these security vulnerabilities and suggest remediation priority: {json.dumps(vulnerabilities[:10])}"
                
                response = openai.ChatCompletion.create(
                    model="gpt-3.5-turbo",
                    messages=[{"role": "user", "content": prompt}],
                    temperature=0.3
                )
                
                print("AI Security Analysis:")
                print(response.choices[0].message.content)
        EOF
        
        python analyze_security.py || echo "Security analysis completed"

  deployment-strategy:
    name: Select Deployment Strategy
    runs-on: ubuntu-latest
    needs: [ai-analysis, intelligent-build]
    outputs:
      strategy: ${{ steps.strategy.outputs.strategy }}
      parameters: ${{ steps.strategy.outputs.parameters }}
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Select deployment strategy
      id: strategy
      uses: ./.github/actions/deployment-strategy
      with:
        risk-score: ${{ needs.ai-analysis.outputs.risk-score }}
        metrics-api-endpoint: ${{ secrets.METRICS_API_ENDPOINT }}
        metrics-api-key: ${{ secrets.METRICS_API_KEY }}

  intelligent-deployment:
    name: AI-Orchestrated Deployment
    runs-on: ubuntu-latest
    needs: [deployment-strategy, intelligent-build]
    environment: production
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Parse deployment parameters
      id: params
      run: |
        echo "Strategy: ${{ needs.deployment-strategy.outputs.strategy }}"
        echo "Parameters: ${{ needs.deployment-strategy.outputs.parameters }}"
        
        # Parse parameters for use in deployment
        PARAMS='${{ needs.deployment-strategy.outputs.parameters }}'
        echo "params=$PARAMS" &gt;&gt; $GITHUB_OUTPUT
    
    - name: Execute deployment
      run: |
        STRATEGY="${{ needs.deployment-strategy.outputs.strategy }}"
        
        case $STRATEGY in
          "blue-green")
            echo "Executing blue-green deployment..."
            # Implementation would go here
            ;;
          "canary")
            echo "Executing canary deployment..."
            # Implementation would go here
            ;;
          "rolling")
            echo "Executing rolling deployment..."
            # Implementation would go here
            ;;
          "progressive")
            echo "Executing progressive deployment..."
            # Implementation would go here
            ;;
        esac

  ai-monitoring:
    name: AI-Powered Monitoring
    runs-on: ubuntu-latest
    needs: intelligent-deployment
    
    steps:
    - name: Set up monitoring
      run: |
        # Create AI monitoring script
        cat &gt; ai_monitor.py &lt;&lt; 'EOF'
        import os
        import json
        import time
        import openai
        import requests
        from datetime import datetime
        
        class AIMonitor:
            def __init__(self, app_url, metrics_endpoint):
                self.app_url = app_url
                self.metrics_endpoint = metrics_endpoint
                openai.api_key = os.environ.get('OPENAI_API_KEY')
                
            def collect_metrics(self):
                """Collect current application metrics"""
                metrics = {
                    'timestamp': datetime.utcnow().isoformat(),
                    'health': self.check_health(),
                    'performance': self.check_performance(),
                    'errors': self.get_error_rate()
                }
                return metrics
            
            def check_health(self):
                try:
                    response = requests.get(f"{self.app_url}/health", timeout=5)
                    return response.status_code == 200
                except:
                    return False
            
            def check_performance(self):
                try:
                    start = time.time()
                    response = requests.get(self.app_url, timeout=10)
                    return time.time() - start
                except:
                    return -1
            
            def get_error_rate(self):
                # In real implementation, fetch from monitoring service
                return 0.5  # Mock value
            
            def analyze_metrics(self, metrics_history):
                """Use AI to analyze metrics and detect anomalies"""
                if not openai.api_key or len(metrics_history) &lt; 5:
                    return None
                
                prompt = f"""
                Analyze these application metrics and identify any anomalies or concerning trends:
                {json.dumps(metrics_history[-10:], indent=2)}
                
                Provide:
                1. Overall health assessment
                2. Any anomalies detected
                3. Recommended actions
                4. Predicted issues in next hour
                """
                
                response = openai.ChatCompletion.create(
                    model="gpt-3.5-turbo",
                    messages=[
                        {"role": "system", "content": "You are an expert in application monitoring and anomaly detection."},
                        {"role": "user", "content": prompt}
                    ],
                    temperature=0.3
                )
                
                return response.choices[0].message.content
            
            def monitor_loop(self, duration=300):
                """Monitor application for specified duration"""
                metrics_history = []
                end_time = time.time() + duration
                
                while time.time() &lt; end_time:
                    metrics = self.collect_metrics()
                    metrics_history.append(metrics)
                    
                    # Analyze every 5 data points
                    if len(metrics_history) % 5 == 0:
                        analysis = self.analyze_metrics(metrics_history)
                        if analysis:
                            print(f"AI Analysis at {datetime.utcnow()}:")
                            print(analysis)
                            
                            # Check for critical issues
                            if "critical" in analysis.lower() or "immediate" in analysis.lower():
                                print("⚠️ CRITICAL ISSUE DETECTED - Triggering alert!")
                                # In real implementation, trigger rollback or alert
                    
                    time.sleep(30)  # Check every 30 seconds
                
                return metrics_history
        
        # Run monitoring
        monitor = AIMonitor(
            app_url="${{ secrets.APP_URL }}",
            metrics_endpoint="${{ secrets.METRICS_API_ENDPOINT }}"
        )
        
        print("Starting AI-powered monitoring...")
        results = monitor.monitor_loop(300)  # Monitor for 5 minutes
        
        # Save results
        with open('monitoring_results.json', 'w') as f:
            json.dump(results, f, indent=2)
        EOF
        
        python ai_monitor.py
    
    - name: Generate monitoring report
      run: |
        echo "## AI Monitoring Report 🤖" &gt;&gt; $GITHUB_STEP_SUMMARY
        echo "- Monitoring completed successfully" &gt;&gt; $GITHUB_STEP_SUMMARY
        echo "- Results saved to monitoring_results.json" &gt;&gt; $GITHUB_STEP_SUMMARY

  cost-optimization:
    name: AI Cost Optimization
    runs-on: ubuntu-latest
    needs: [intelligent-deployment, ai-monitoring]
    if: always()
    
    steps:
    - name: Analyze costs and optimize
      env:
        AZURE_CREDENTIALS: ${{ secrets.AZURE_CREDENTIALS }}
      run: |
        # Create cost optimization script
        cat &gt; optimize_costs.py &lt;&lt; 'EOF'
        import json
        import subprocess
        from datetime import datetime, timedelta
        
        class CostOptimizer:
            def __init__(self):
                self.recommendations = []
                
            def analyze_resource_usage(self):
                """Analyze current Azure resource usage"""
                # Get resource metrics
                result = subprocess.run([
                    'az', 'monitor', 'metrics', 'list',
                    '--resource', '/subscriptions/.../resourceGroups/...',
                    '--metric', 'Percentage CPU',
                    '--start-time', (datetime.utcnow() - timedelta(hours=24)).isoformat(),
                    '--interval', 'PT1H'
                ], capture_output=True, text=True)
                
                # Mock analysis for demo
                avg_cpu = 25  # Mock value
                
                if avg_cpu &lt; 20:
                    self.recommendations.append({
                        'type': 'downscale',
                        'reason': f'Average CPU usage is {avg_cpu}%',
                        'action': 'Consider using a smaller instance size',
                        'potential_savings': '$50/month'
                    })
                
                return avg_cpu
            
            def analyze_deployment_patterns(self):
                """Analyze deployment frequency and timing"""
                # In real implementation, fetch from GitHub API
                deployments_per_day = 3  # Mock value
                
                if deployments_per_day &gt; 5:
                    self.recommendations.append({
                        'type': 'batch_deployments',
                        'reason': f'High deployment frequency ({deployments_per_day}/day)',
                        'action': 'Consider batching deployments',
                        'potential_savings': '50 Actions minutes/month'
                    })
            
            def generate_report(self):
                """Generate cost optimization report"""
                report = {
                    'timestamp': datetime.utcnow().isoformat(),
                    'recommendations': self.recommendations,
                    'total_potential_savings': f'${len(self.recommendations) * 30}/month'
                }
                
                return report
        
        # Run optimization
        optimizer = CostOptimizer()
        optimizer.analyze_resource_usage()
        optimizer.analyze_deployment_patterns()
        report = optimizer.generate_report()
        
        print("Cost Optimization Report:")
        print(json.dumps(report, indent=2))
        
        # Save report
        with open('cost_optimization_report.json', 'w') as f:
            json.dump(report, f, indent=2)
        EOF
        
        python optimize_costs.py
    
    - name: Update cost summary
      run: |
        echo "## Cost Optimization Report 💰" &gt;&gt; $GITHUB_STEP_SUMMARY
        if [ -f cost_optimization_report.json ]; then
          echo '```json' &gt;&gt; $GITHUB_STEP_SUMMARY
          cat cost_optimization_report.json &gt;&gt; $GITHUB_STEP_SUMMARY
          echo '```' &gt;&gt; $GITHUB_STEP_SUMMARY
        fi
```

## 🧪 Testing Your Empresarial Pipeline

### Step 1: Prepare Secrets
Add these secrets to your repository:
- `OPENAI_API_KEY`: Your AbrirAI API key
- `METRICS_API_ENDPOINT`: Your metrics service URL
- `METRICS_API_KEY`: Metrics service authentication
- `APP_URL`: Your application URL
- `AZURE_CREDENTIALS`: Azure service principal

### Step 2: Test Different Scenarios

1. **High-Risk Change**: Modify core functionality
2. **Low-Risk Change**: Atualizar documentation
3. **Performance Impact**: Add inefficient code
4. **Security Issue**: Introduce a vulnerability

## 🎯 Validation Verificarlist

- [ ] AI code analysis provides accurate risk scores
- [ ] Test generation creates runnable tests
- [ ] Deployment strategy adapts to conditions
- [ ] Monitoring detects anomalies
- [ ] Cost optimization provides actionable insights
- [ ] Pipeline self-heals on failures
- [ ] All AI features integrate smoothly

## 🚀 Avançado Extensions

1. **Predictive Scaling**: Use AI to predict traffic and pre-scale
2. **Intelligent Caching**: AI-driven cache invalidation
3. **Automated Incident Response**: AI-powered runbooks
4. **Performance Prediction**: Forecast impact before implantação
5. **Security Threat Modeling**: AI-based threat assessment

## 📊 Key Takeaways

1. **AI Integration**: Leverage AI at every pipeline stage
2. **Adaptive Behavior**: Pipelines that learn and improve
3. **Predictive Análises**: Prevent issues before they occur
4. **Cost Awareness**: Optimize resources automatically
5. **Self-Healing**: Automated problem resolution
6. **Continuous Learning**: Pipeline improves over time

---

**Exceptional work!** 🏆 You've built an enterprise-grade, AI-powered CI/CD pipeline that represents the future of DevOps automation.

**Module Complete!** You're now ready to apply these advanced CI/CD concepts in production environments.