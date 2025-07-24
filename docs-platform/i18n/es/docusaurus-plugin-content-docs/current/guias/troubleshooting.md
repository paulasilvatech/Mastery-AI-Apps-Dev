---
id: troubleshooting
title: Troubleshooting Guide
sidebar_label: Troubleshooting
sidebar_position: 5
---

# Troubleshooting Guía

Common issues and solutions for AI application desarrollo.

## Resumen

This guide helps you:
- Diagnose common problems quickly
- Find solutions that actually work
- Understand why issues occur
- Prevent future problems

## 🔴 Installation Issues

### Python Not Found

**Symptoms:**
```bash
$ python --version
command not found: python
```

**Solutions:**

1. **Use python3 instead:**
   ```bash
   python3 --version
   ```

2. **Create alias (Mac/Linux):**
   ```bash
   echo "alias python=python3" >> ~/.bashrc
   source ~/.bashrc
   ```

3. **Add to PATH (Windows):**
   - Buscar "Environment Variables"
   - Add Python installation path
   - Restart terminal

4. **Reinstall Python:**
   ```bash
   # macOS
   brew install python@3.11
   
   # Windows
   choco install python3
   
   # Linux
   sudo apt install python3.11
   ```

### Pip Installation Failures

**Symptoms:**
```bash
ERROR: Could not install packages due to an EnvironmentError
```

**Solutions:**

1. **Use user installation:**
   ```bash
   pip install --user package-name
   ```

2. **Upgrade pip:**
   ```bash
   python -m pip install --upgrade pip
   ```

3. **Clear pip cache:**
   ```bash
   pip cache purge
   ```

4. **Use virtual ambiente:**
   ```bash
   python -m venv venv
   source venv/bin/activate  # or venv\Scripts\activate on Windows
   pip install package-name
   ```

### SSL Certificate Errors

**Symptoms:**
```
SSLError: [SSL: CERTIFICATE_VERIFY_FAILED]
```

**Solutions:**

1. **Actualizar certificates:**
   ```bash
   # macOS
   brew install ca-certificates
   
   # Linux
   sudo apt-get update && sudo apt-get install ca-certificates
   ```

2. **Temporary workaround (NOT for producción):**
   ```bash
   pip install --trusted-host pypi.org --trusted-host files.pythonhosted.org package-name
   ```

3. **Set ambiente variable:**
   ```bash
   export SSL_CERT_FILE=$(python -m certifi)
   ```

## 🔑 API Key Issues

### Invalid API Key

**Symptoms:**
```
openai.error.AuthenticationError: Invalid API key provided
```

**Solutions:**

1. **Verificar .env file formatting:**
   ```bash
   # Correct
   OPENAI_API_KEY=sk-abcdef123456
   
   # Wrong (no quotes)
   OPENAI_API_KEY="sk-abcdef123456"
   ```

2. **Verify ambiente variable:**
   ```python
   import os
   print(os.getenv("OPENAI_API_KEY"))  # Should not be None
   ```

3. **Reload ambiente:**
   ```python
   from dotenv import load_dotenv
   load_dotenv(override=True)
   ```

4. **Verificar API key permissions:**
   - Log into AbrirAI/Anthropic dashboard
   - Verify key is active
   - Verificar usage limits

### Rate Limit Errors

**Symptoms:**
```
openai.error.RateLimitError: Rate limit reached
```

**Solutions:**

1. **Implement exponential backoff:**
   ```python
   import time
   from openai import OpenAI
   
   def retry_with_backoff(func, max_retries=5):
       for i in range(max_retries):
           try:
               return func()
           except Exception as e:
               if i == max_retries - 1:
                   raise
               wait_time = (2 ** i) + random.uniform(0, 1)
               print(f"Rate limited. Waiting {wait_time:.2f}s...")
               time.sleep(wait_time)
   ```

2. **Add request delays:**
   ```python
   import time
   
   # Add delay between requests
   time.sleep(0.5)  # 500ms delay
   ```

3. **Use different models:**
   ```python
   # If GPT-4 is rate limited, fall back to GPT-3.5
   try:
       response = client.chat.completions.create(model="gpt-4", ...)
   except RateLimitError:
       response = client.chat.completions.create(model="gpt-3.5-turbo", ...)
   ```

### Missing API Key

**Symptoms:**
```
ValueError: OPENAI_API_KEY not found in environment variables
```

**Solutions:**

1. **Create .env file:**
   ```bash
   echo "OPENAI_API_KEY=your-key-here" > .env
   ```

2. **Load in correct location:**
   ```python
   import os
   from pathlib import Path
   from dotenv import load_dotenv
   
   # Load from parent directory
   load_dotenv(Path(__file__).parent / ".env")
   ```

3. **Set system-wide (temporary):**
   ```bash
   export OPENAI_API_KEY=your-key-here  # Mac/Linux
   set OPENAI_API_KEY=your-key-here     # Windows CMD
   $env:OPENAI_API_KEY="your-key-here"  # Windows PowerShell
   ```

## 💻 Runtime Errors

### Módulo Not Found

**Symptoms:**
```
ModuleNotFoundError: No module named 'openai'
```

**Solutions:**

1. **Verificar virtual ambiente:**
   ```bash
   which python  # Should show venv path
   pip list      # Check if module is installed
   ```

2. **Reinstall in correct ambiente:**
   ```bash
   # Activate venv first!
   source venv/bin/activate
   pip install openai
   ```

3. **Verificar Python path:**
   ```python
   import sys
   print(sys.path)  # Should include your project directory
   ```

### Token Limit Exceeded

**Symptoms:**
```
This model's maximum context length is 4096 tokens
```

**Solutions:**

1. **Reduce input size:**
   ```python
   import tiktoken
   
   def count_tokens(text, model="gpt-3.5-turbo"):
       encoding = tiktoken.encoding_for_model(model)
       return len(encoding.encode(text))
   
   # Truncate if needed
   if count_tokens(prompt) > 3000:
       prompt = prompt[:10000]  # Rough truncation
   ```

2. **Use summarization:**
   ```python
   def chunk_and_summarize(long_text, chunk_size=3000):
       chunks = [long_text[i:i+chunk_size] 
                 for i in range(0, len(long_text), chunk_size)]
       
       summaries = []
       for chunk in chunks:
           summary = summarize(chunk)  # Your summarization function
           summaries.append(summary)
       
       return " ".join(summaries)
   ```

3. **Switch to larger context model:**
   ```python
   # Use GPT-4-turbo for longer context
   client.chat.completions.create(
       model="gpt-4-turbo-preview",  # 128k context
       messages=messages
   )
   ```

### Memory Errors

**Symptoms:**
```
MemoryError: Unable to allocate array
```

**Solutions:**

1. **Process in batches:**
   ```python
   def process_large_dataset(data, batch_size=100):
       results = []
       for i in range(0, len(data), batch_size):
           batch = data[i:i+batch_size]
           result = process_batch(batch)
           results.extend(result)
       return results
   ```

2. **Use generators:**
   ```python
   def read_large_file(filename):
       with open(filename, 'r') as f:
           for line in f:
               yield line.strip()
   ```

3. **Clear memory:**
   ```python
   import gc
   
   # Process data
   result = process_data(large_data)
   
   # Clear references
   del large_data
   gc.collect()
   ```

## 🌐 Network Issues

### Connection Timeouts

**Symptoms:**
```
requests.exceptions.ConnectTimeout: Connection timed out
```

**Solutions:**

1. **Increase timeout:**
   ```python
   import httpx
   
   client = OpenAI(
       http_client=httpx.Client(timeout=60.0)
   )
   ```

2. **Add retry logic:**
   ```python
   from tenacity import retry, stop_after_attempt, wait_exponential
   
   @retry(
       stop=stop_after_attempt(3),
       wait=wait_exponential(multiplier=1, min=4, max=10)
   )
   def make_api_call():
       return client.chat.completions.create(...)
   ```

3. **Verificar proxy settings:**
   ```python
   import os
   
   # If behind proxy
   os.environ['HTTP_PROXY'] = 'http://proxy.example.com:8080'
   os.environ['HTTPS_PROXY'] = 'http://proxy.example.com:8080'
   ```

### DNS Resolution Failures

**Symptoms:**
```
socket.gaierror: [Errno -2] Name or service not known
```

**Solutions:**

1. **Verificar internet connection:**
   ```bash
   ping google.com
   ```

2. **Use different DNS:**
   ```bash
   # Add to /etc/resolv.conf (Linux/Mac)
   nameserver 8.8.8.8
   nameserver 8.8.4.4
   ```

3. **Clear DNS cache:**
   ```bash
   # macOS
   sudo dscacheutil -flushcache
   
   # Windows
   ipconfig /flushdns
   
   # Linux
   sudo systemctl restart systemd-resolved
   ```

## 🚀 Performance Issues

### Slow Response Times

**Solutions:**

1. **Use streaming:**
   ```python
   stream = client.chat.completions.create(
       model="gpt-3.5-turbo",
       messages=messages,
       stream=True
   )
   
   for chunk in stream:
       if chunk.choices[0].delta.content:
           print(chunk.choices[0].delta.content, end='')
   ```

2. **Optimize prompts:**
   ```python
   # Instead of multiple calls
   # BAD
   result1 = ask_ai("Summarize this")
   result2 = ask_ai("Extract key points")
   
   # GOOD - Single call
   result = ask_ai("""
   1. Summarize this text
   2. Extract key points
   """)
   ```

3. **Cache responses:**
   ```python
   from functools import lru_cache
   import hashlib
   
   @lru_cache(maxsize=100)
   def cached_api_call(prompt_hash):
       return client.chat.completions.create(...)
   
   # Use hash for caching
   prompt_hash = hashlib.md5(prompt.encode()).hexdigest()
   result = cached_api_call(prompt_hash)
   ```

### High Memory Usage

**Solutions:**

1. **Monitor memory:**
   ```python
   import psutil
   import os
   
   process = psutil.Process(os.getpid())
   print(f"Memory usage: {process.memory_info().rss / 1024 / 1024:.2f} MB")
   ```

2. **Use smaller models:**
   ```python
   # Instead of large models
   model = "gpt-3.5-turbo"  # Instead of gpt-4
   ```

3. **Clear caches:**
   ```python
   # Clear model cache
   if hasattr(model, 'clear_cache'):
       model.clear_cache()
   ```

## 🐛 Debugging Tips

### Enable Detailed Logging

```python
import logging
import openai

# Set up logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Enable HTTP logging
import httpx
httpx_logger = logging.getLogger("httpx")
httpx_logger.setLevel(logging.DEBUG)
```

### Capture Full Error Details

```python
import traceback

try:
    result = risky_operation()
except Exception as e:
    print(f"Error type: {type(e).__name__}")
    print(f"Error message: {str(e)}")
    print(f"Full traceback:\n{traceback.format_exc()}")
```

### Test in Isolation

```python
# Create minimal test case
def test_api_connection():
    """Test basic API connectivity"""
    try:
        client = OpenAI()
        response = client.models.list()
        print("✅ API connection successful")
        return True
    except Exception as e:
        print(f"❌ API connection failed: {e}")
        return False

# Run diagnostic
if __name__ == "__main__":
    test_api_connection()
```

## 🔧 ambiente Debugging

### Verificar Everything Script

```python
#!/usr/bin/env python3
"""Comprehensive environment check"""

import sys
import os
import subprocess
import importlib.metadata

def check_system():
    """Check system information"""
    print("=== System Information ===")
    print(f"Python: {sys.version}")
    print(f"Platform: {sys.platform}")
    print(f"Path: {sys.executable}")
    
def check_packages():
    """Check installed packages"""
    print("\n=== Installed Packages ===")
    required = ['openai', 'anthropic', 'langchain', 'numpy', 'pandas']
    
    for package in required:
        try:
            version = importlib.metadata.version(package)
            print(f"✅ {package}: {version}")
        except importlib.metadata.PackageNotFoundError:
            print(f"❌ {package}: Not installed")

def check_env_vars():
    """Check environment variables"""
    print("\n=== Environment Variables ===")
    vars_to_check = ['OPENAI_API_KEY', 'ANTHROPIC_API_KEY', 'PYTHONPATH']
    
    for var in vars_to_check:
        value = os.getenv(var)
        if value:
            print(f"✅ {var}: Set ({len(value)} chars)")
        else:
            print(f"❌ {var}: Not set")

def check_connectivity():
    """Check internet connectivity"""
    print("\n=== Connectivity ===")
    try:
        import requests
        response = requests.get("https://api.openai.com", timeout=5)
        print(f"✅ OpenAI API: Reachable (Status: {response.status_code})")
    except Exception as e:
        print(f"❌ OpenAI API: {type(e).__name__}")

if __name__ == "__main__":
    check_system()
    check_packages()
    check_env_vars()
    check_connectivity()
```

## 📚 Additional Recursos

### Error Reference

Common error codes and meanings:

- **401**: Authentication failed (check API key)
- **429**: Rate limit exceeded (slow down requests)
- **500**: Server error (retry later)
- **503**: Service unavailable (check status page)

### Useful Commands

```bash
# Check Python environment
python -m site

# List all installed packages
pip freeze

# Check package location
python -c "import openai; print(openai.__file__)"

# Test API directly
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```

### Getting Ayuda

1. **Buscar error message**: Copiar exact error and search
2. **Verificar GitHub issues**: Look for similar problems
3. **Community forums**: Discord, Stack Overflow
4. **Official docs**: Always check latest documentation

---

**Still stuck? Check our [FAQ](./faq.md) or ask in the community forum!**