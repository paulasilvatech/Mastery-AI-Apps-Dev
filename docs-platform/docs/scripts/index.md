---
id: scripts-index
title: Scripts & Automation
sidebar_label: Overview
sidebar_position: 1
---

# Scripts & Automation

Essential scripts and automation tools for AI application development.

## Introduction

This section provides ready-to-use scripts and automation tools that will accelerate your AI development workflow. From data processing to deployment automation, these scripts are battle-tested and production-ready.

## Available Scripts

### 🔧 Development Tools

Scripts to enhance your development experience:

- **Environment Setup**: Automated environment configuration
- **Code Generation**: Boilerplate generators for common patterns
- **Testing Utilities**: Automated test runners and validators
- **Debugging Helpers**: Tools for troubleshooting AI applications

### 📊 Data Processing

Essential scripts for data handling:

- **Text Preprocessing**: Clean and prepare text for AI models
- **Dataset Builders**: Create training/testing datasets
- **Format Converters**: Convert between different data formats
- **Validation Tools**: Ensure data quality and consistency

### 🤖 Model Management

Tools for working with AI models:

- **Model Downloaders**: Fetch and cache models locally
- **Performance Benchmarks**: Compare model performance
- **Prompt Testers**: Batch test prompts across models
- **Version Control**: Track model and prompt versions

### 🚀 Deployment Automation

Scripts for streamlined deployment:

- **Build Scripts**: Automated building and packaging
- **Deploy Helpers**: One-command deployment tools
- **Health Checkers**: Monitor application health
- **Rollback Tools**: Quick rollback mechanisms

## Quick Start Scripts

### 1. Project Initializer

```bash
#!/bin/bash
# init-ai-project.sh
# Initialize a new AI project with best practices

PROJECT_NAME=$1

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: ./init-ai-project.sh <project-name>"
    exit 1
fi

echo "🚀 Creating AI project: $PROJECT_NAME"

# Create project structure
mkdir -p $PROJECT_NAME/{src,tests,data,models,scripts,docs}
cd $PROJECT_NAME

# Initialize git
git init

# Create virtual environment
python -m venv venv
source venv/bin/activate

# Create requirements.txt
cat > requirements.txt << EOF
openai>=1.0.0
anthropic>=0.3.0
langchain>=0.1.0
python-dotenv>=1.0.0
pytest>=7.4.0
black>=23.10.0
streamlit>=1.28.0
fastapi>=0.104.0
uvicorn>=0.24.0
EOF

# Install dependencies
pip install -r requirements.txt

# Create .env template
cat > .env.example << EOF
OPENAI_API_KEY=your-key-here
ANTHROPIC_API_KEY=your-key-here
MODEL_NAME=gpt-3.5-turbo
TEMPERATURE=0.7
MAX_TOKENS=150
EOF

# Create .gitignore
cat > .gitignore << EOF
.env
venv/
__pycache__/
*.pyc
.pytest_cache/
.DS_Store
*.log
models/*
!models/.gitkeep
data/*
!data/.gitkeep
EOF

# Create README
cat > README.md << EOF
# $PROJECT_NAME

AI application built with modern tools and best practices.

## Setup

1. Create virtual environment: \`python -m venv venv\`
2. Activate: \`source venv/bin/activate\`
3. Install: \`pip install -r requirements.txt\`
4. Configure: Copy \`.env.example\` to \`.env\` and add your API keys

## Usage

[Add usage instructions here]

## Development

- Run tests: \`pytest\`
- Format code: \`black .\`
- Start dev server: \`python src/main.py\`
EOF

# Create main application file
cat > src/main.py << EOF
"""Main application entry point"""
import os
from dotenv import load_dotenv

load_dotenv()

def main():
    """Main function"""
    print(f"Welcome to {PROJECT_NAME}!")
    print(f"Using model: {os.getenv('MODEL_NAME')}")

if __name__ == "__main__":
    main()
EOF

# Create test file
cat > tests/test_main.py << EOF
"""Tests for main application"""
import pytest
from src.main import main

def test_main():
    """Test main function"""
    # Add your tests here
    assert True
EOF

# Create empty directories with .gitkeep
touch models/.gitkeep data/.gitkeep

echo "✅ Project $PROJECT_NAME created successfully!"
echo "📝 Next steps:"
echo "   1. cd $PROJECT_NAME"
echo "   2. source venv/bin/activate"
echo "   3. cp .env.example .env"
echo "   4. Add your API keys to .env"
echo "   5. Start coding!"
```

### 2. API Key Validator

```python
#!/usr/bin/env python3
# validate-api-keys.py
# Validate all API keys in .env file

import os
import sys
from dotenv import load_dotenv
import openai
import anthropic
import requests

def test_openai_key():
    """Test OpenAI API key"""
    try:
        client = openai.OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        models = client.models.list()
        print("✅ OpenAI API key is valid")
        return True
    except Exception as e:
        print(f"❌ OpenAI API key error: {e}")
        return False

def test_anthropic_key():
    """Test Anthropic API key"""
    try:
        client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
        # Make a minimal request
        response = client.messages.create(
            model="claude-3-haiku-20240307",
            max_tokens=10,
            messages=[{"role": "user", "content": "Hi"}]
        )
        print("✅ Anthropic API key is valid")
        return True
    except Exception as e:
        print(f"❌ Anthropic API key error: {e}")
        return False

def test_huggingface_key():
    """Test Hugging Face API key"""
    api_key = os.getenv("HUGGINGFACE_TOKEN")
    if not api_key:
        print("⚠️  Hugging Face token not found (optional)")
        return True
    
    try:
        headers = {"Authorization": f"Bearer {api_key}"}
        response = requests.get(
            "https://huggingface.co/api/whoami", 
            headers=headers
        )
        if response.status_code == 200:
            print("✅ Hugging Face token is valid")
            return True
        else:
            print(f"❌ Hugging Face token error: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Hugging Face token error: {e}")
        return False

def main():
    """Main validation function"""
    print("🔍 Validating API keys...\n")
    
    # Load environment variables
    load_dotenv()
    
    # Track results
    results = []
    
    # Test each API key
    results.append(test_openai_key())
    results.append(test_anthropic_key())
    results.append(test_huggingface_key())
    
    # Summary
    print("\n" + "="*50)
    if all(results):
        print("✅ All API keys validated successfully!")
        sys.exit(0)
    else:
        print("❌ Some API keys failed validation")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

### 3. Batch Prompt Tester

```python
#!/usr/bin/env python3
# batch-prompt-test.py
# Test prompts across multiple models and compare results

import os
import json
import time
from datetime import datetime
from typing import List, Dict
import openai
import anthropic
from dotenv import load_dotenv

load_dotenv()

class PromptTester:
    def __init__(self):
        self.openai_client = openai.OpenAI()
        self.anthropic_client = anthropic.Anthropic()
        self.results = []
    
    def test_prompt(self, prompt: str, models: List[str] = None) -> Dict:
        """Test a prompt across multiple models"""
        if models is None:
            models = ["gpt-3.5-turbo", "gpt-4", "claude-3-haiku-20240307"]
        
        results = {
            "prompt": prompt,
            "timestamp": datetime.now().isoformat(),
            "models": {}
        }
        
        for model in models:
            print(f"Testing {model}...")
            try:
                if model.startswith("gpt"):
                    response = self._test_openai(prompt, model)
                elif model.startswith("claude"):
                    response = self._test_anthropic(prompt, model)
                else:
                    response = {"error": "Unknown model type"}
                
                results["models"][model] = response
                time.sleep(0.5)  # Rate limiting
                
            except Exception as e:
                results["models"][model] = {"error": str(e)}
        
        self.results.append(results)
        return results
    
    def _test_openai(self, prompt: str, model: str) -> Dict:
        """Test with OpenAI model"""
        start_time = time.time()
        
        response = self.openai_client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7,
            max_tokens=150
        )
        
        return {
            "response": response.choices[0].message.content,
            "tokens": response.usage.total_tokens,
            "latency": time.time() - start_time,
            "cost": self._calculate_cost(model, response.usage.total_tokens)
        }
    
    def _test_anthropic(self, prompt: str, model: str) -> Dict:
        """Test with Anthropic model"""
        start_time = time.time()
        
        response = self.anthropic_client.messages.create(
            model=model,
            max_tokens=150,
            messages=[{"role": "user", "content": prompt}]
        )
        
        return {
            "response": response.content[0].text,
            "tokens": response.usage.input_tokens + response.usage.output_tokens,
            "latency": time.time() - start_time,
            "cost": self._calculate_cost(model, response.usage.input_tokens + response.usage.output_tokens)
        }
    
    def _calculate_cost(self, model: str, tokens: int) -> float:
        """Calculate estimated cost"""
        # Rough cost estimates (update with current pricing)
        costs = {
            "gpt-3.5-turbo": 0.002 / 1000,
            "gpt-4": 0.03 / 1000,
            "claude-3-haiku-20240307": 0.0015 / 1000
        }
        return tokens * costs.get(model, 0)
    
    def save_results(self, filename: str = "prompt_test_results.json"):
        """Save results to file"""
        with open(filename, "w") as f:
            json.dump(self.results, f, indent=2)
        print(f"✅ Results saved to {filename}")
    
    def print_comparison(self):
        """Print comparison table"""
        if not self.results:
            print("No results to display")
            return
        
        for result in self.results:
            print(f"\n{'='*80}")
            print(f"Prompt: {result['prompt'][:50]}...")
            print(f"{'='*80}")
            
            for model, data in result["models"].items():
                if "error" in data:
                    print(f"\n{model}: ERROR - {data['error']}")
                else:
                    print(f"\n{model}:")
                    print(f"  Response: {data['response'][:100]}...")
                    print(f"  Tokens: {data['tokens']}")
                    print(f"  Latency: {data['latency']:.2f}s")
                    print(f"  Cost: ${data['cost']:.4f}")

def main():
    """Main function"""
    tester = PromptTester()
    
    # Define test prompts
    prompts = [
        "Explain quantum computing in one sentence.",
        "Write a haiku about artificial intelligence.",
        "What are the top 3 benefits of using Python for data science?"
    ]
    
    # Test each prompt
    for prompt in prompts:
        print(f"\nTesting: {prompt}")
        tester.test_prompt(prompt)
    
    # Display results
    tester.print_comparison()
    
    # Save results
    tester.save_results()

if __name__ == "__main__":
    main()
```

### 4. Performance Monitor

```python
#!/usr/bin/env python3
# monitor-performance.py
# Monitor AI application performance metrics

import psutil
import time
import threading
from datetime import datetime
import matplotlib.pyplot as plt
from collections import deque

class PerformanceMonitor:
    def __init__(self, max_points=100):
        self.max_points = max_points
        self.cpu_history = deque(maxlen=max_points)
        self.memory_history = deque(maxlen=max_points)
        self.time_history = deque(maxlen=max_points)
        self.monitoring = False
        
    def start_monitoring(self):
        """Start monitoring in background thread"""
        self.monitoring = True
        thread = threading.Thread(target=self._monitor_loop)
        thread.daemon = True
        thread.start()
        print("📊 Performance monitoring started...")
    
    def stop_monitoring(self):
        """Stop monitoring"""
        self.monitoring = False
        print("🛑 Performance monitoring stopped")
    
    def _monitor_loop(self):
        """Main monitoring loop"""
        while self.monitoring:
            # Collect metrics
            cpu_percent = psutil.cpu_percent(interval=1)
            memory_percent = psutil.virtual_memory().percent
            current_time = datetime.now()
            
            # Store metrics
            self.cpu_history.append(cpu_percent)
            self.memory_history.append(memory_percent)
            self.time_history.append(current_time)
            
            # Log if high usage
            if cpu_percent > 80:
                print(f"⚠️  High CPU usage: {cpu_percent}%")
            if memory_percent > 80:
                print(f"⚠️  High memory usage: {memory_percent}%")
            
            time.sleep(1)
    
    def plot_metrics(self):
        """Plot performance metrics"""
        if not self.time_history:
            print("No data to plot")
            return
        
        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 8))
        
        # CPU usage
        ax1.plot(self.time_history, self.cpu_history, 'b-')
        ax1.set_ylabel('CPU Usage (%)')
        ax1.set_title('System Performance Metrics')
        ax1.grid(True)
        ax1.set_ylim(0, 100)
        
        # Memory usage
        ax2.plot(self.time_history, self.memory_history, 'r-')
        ax2.set_ylabel('Memory Usage (%)')
        ax2.set_xlabel('Time')
        ax2.grid(True)
        ax2.set_ylim(0, 100)
        
        plt.tight_layout()
        plt.show()
    
    def get_current_stats(self):
        """Get current system stats"""
        return {
            "cpu_percent": psutil.cpu_percent(interval=1),
            "memory_percent": psutil.virtual_memory().percent,
            "memory_available_gb": psutil.virtual_memory().available / (1024**3),
            "disk_usage_percent": psutil.disk_usage('/').percent,
            "network_connections": len(psutil.net_connections()),
            "process_count": len(psutil.pids())
        }
    
    def print_stats(self):
        """Print current stats"""
        stats = self.get_current_stats()
        print("\n📊 Current System Stats:")
        print(f"  CPU Usage: {stats['cpu_percent']}%")
        print(f"  Memory Usage: {stats['memory_percent']}%")
        print(f"  Memory Available: {stats['memory_available_gb']:.2f} GB")
        print(f"  Disk Usage: {stats['disk_usage_percent']}%")
        print(f"  Network Connections: {stats['network_connections']}")
        print(f"  Process Count: {stats['process_count']}")

def main():
    """Example usage"""
    monitor = PerformanceMonitor()
    
    # Start monitoring
    monitor.start_monitoring()
    
    # Simulate some work
    print("Monitoring system performance for 30 seconds...")
    time.sleep(30)
    
    # Stop and display results
    monitor.stop_monitoring()
    monitor.print_stats()
    
    # Plot results
    monitor.plot_metrics()

if __name__ == "__main__":
    main()
```

## Utility Functions

### Text Processing Utilities

```python
# text_utils.py
import re
import tiktoken
from typing import List, Tuple

def count_tokens(text: str, model: str = "gpt-3.5-turbo") -> int:
    """Count tokens in text for specific model"""
    encoding = tiktoken.encoding_for_model(model)
    return len(encoding.encode(text))

def chunk_text(text: str, max_tokens: int = 1000, model: str = "gpt-3.5-turbo") -> List[str]:
    """Chunk text into token-limited segments"""
    encoding = tiktoken.encoding_for_model(model)
    tokens = encoding.encode(text)
    
    chunks = []
    for i in range(0, len(tokens), max_tokens):
        chunk_tokens = tokens[i:i + max_tokens]
        chunk_text = encoding.decode(chunk_tokens)
        chunks.append(chunk_text)
    
    return chunks

def clean_text(text: str) -> str:
    """Clean text for AI processing"""
    # Remove extra whitespace
    text = re.sub(r'\s+', ' ', text)
    
    # Remove special characters but keep punctuation
    text = re.sub(r'[^\w\s\.\,\!\?\-\']', '', text)
    
    # Fix common encoding issues
    replacements = {
        ''': "'",
        ''': "'",
        '"': '"',
        '"': '"',
        '–': '-',
        '—': '-',
        '…': '...'
    }
    
    for old, new in replacements.items():
        text = text.replace(old, new)
    
    return text.strip()

def extract_code_blocks(text: str) -> List[Tuple[str, str]]:
    """Extract code blocks from markdown text"""
    pattern = r'```(\w+)?\n(.*?)\n```'
    matches = re.findall(pattern, text, re.DOTALL)
    return [(lang or 'text', code) for lang, code in matches]
```

### API Retry Logic

```python
# retry_utils.py
import time
import random
from functools import wraps
from typing import Callable, Any

def exponential_backoff(
    max_retries: int = 3,
    base_delay: float = 1.0,
    max_delay: float = 60.0
) -> Callable:
    """Decorator for exponential backoff retry logic"""
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs) -> Any:
            for attempt in range(max_retries):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_retries - 1:
                        raise
                    
                    # Calculate delay with jitter
                    delay = min(base_delay * (2 ** attempt), max_delay)
                    jitter = random.uniform(0, delay * 0.1)
                    total_delay = delay + jitter
                    
                    print(f"Attempt {attempt + 1} failed: {e}")
                    print(f"Retrying in {total_delay:.2f} seconds...")
                    time.sleep(total_delay)
            
            return None
        return wrapper
    return decorator

# Usage example
@exponential_backoff(max_retries=5)
def make_api_call():
    # Your API call here
    pass
```

## Deployment Scripts

### Docker Build and Push

```bash
#!/bin/bash
# docker-build-push.sh
# Build and push Docker images

# Configuration
REGISTRY="your-registry.com"
IMAGE_NAME="ai-app"
VERSION=$(git describe --tags --always)

echo "🐳 Building Docker image..."

# Build image
docker build -t $IMAGE_NAME:$VERSION .
docker tag $IMAGE_NAME:$VERSION $IMAGE_NAME:latest

# Tag for registry
docker tag $IMAGE_NAME:$VERSION $REGISTRY/$IMAGE_NAME:$VERSION
docker tag $IMAGE_NAME:latest $REGISTRY/$IMAGE_NAME:latest

echo "📤 Pushing to registry..."

# Push to registry
docker push $REGISTRY/$IMAGE_NAME:$VERSION
docker push $REGISTRY/$IMAGE_NAME:latest

echo "✅ Build and push complete!"
echo "   Image: $REGISTRY/$IMAGE_NAME:$VERSION"
```

### Health Check Script

```python
#!/usr/bin/env python3
# health_check.py
# Check application health status

import requests
import sys
from typing import Dict, List

def check_endpoint(url: str, expected_status: int = 200) -> Dict:
    """Check if endpoint is healthy"""
    try:
        response = requests.get(url, timeout=5)
        return {
            "url": url,
            "status": response.status_code,
            "healthy": response.status_code == expected_status,
            "response_time": response.elapsed.total_seconds()
        }
    except Exception as e:
        return {
            "url": url,
            "status": None,
            "healthy": False,
            "error": str(e)
        }

def main():
    """Main health check"""
    endpoints = [
        "http://localhost:8000/health",
        "http://localhost:8000/api/v1/status",
        "http://localhost:6333/health"  # Vector DB
    ]
    
    all_healthy = True
    
    print("🏥 Running health checks...\n")
    
    for endpoint in endpoints:
        result = check_endpoint(endpoint)
        
        if result["healthy"]:
            print(f"✅ {result['url']} - OK ({result['response_time']:.2f}s)")
        else:
            print(f"❌ {result['url']} - FAILED")
            if "error" in result:
                print(f"   Error: {result['error']}")
            all_healthy = False
    
    print("\n" + "="*50)
    if all_healthy:
        print("✅ All services healthy!")
        sys.exit(0)
    else:
        print("❌ Some services are unhealthy")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

## Next Steps

Explore more scripts:

1. [Data Processing Scripts](./data-processing.md)
2. [Model Management Tools](./model-management.md)
3. [Testing Automation](./testing-automation.md)
4. [Deployment Helpers](./deployment-helpers.md)
5. [Monitoring Scripts](./monitoring-scripts.md)

## Contributing

Have a useful script? We'd love to include it! 

1. Fork the repository
2. Add your script with documentation
3. Submit a pull request

## Support

- 📚 Check script documentation
- 💬 Ask in #scripts channel on Discord
- 🐛 Report issues on GitHub
- 📧 Email: scripts@workshop.ai

Happy automating! 🚀