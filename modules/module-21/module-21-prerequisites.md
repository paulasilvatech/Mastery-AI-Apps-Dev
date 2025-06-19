# Prerequisites for Module 21: Introduction to AI Agents

## 🎯 Required Knowledge

Before starting this module, ensure you have:

### From Previous Modules
- ✅ **Module 1-5**: Solid GitHub Copilot fundamentals
- ✅ **Module 6-10**: Experience with multi-file operations
- ✅ **Module 11-15**: Understanding of architecture patterns
- ✅ **Module 16-20**: Enterprise development practices

### Programming Skills
- ✅ **Python 3.11+**: Advanced proficiency required
- ✅ **Async Programming**: Understanding of asyncio
- ✅ **OOP Concepts**: Classes, inheritance, abstractions
- ✅ **Design Patterns**: Factory, Observer, Strategy

### Technical Concepts
- ✅ **REST APIs**: Creating and consuming
- ✅ **Event-Driven Architecture**: Basic understanding
- ✅ **State Management**: Managing complex application state
- ✅ **Error Handling**: Exception management patterns

## 🛠️ Required Tools

### Development Environment
```bash
# Verify Python version
python --version  # Should be 3.11 or higher

# Verify Node.js (for some exercises)
node --version    # Should be 18.0 or higher

# Verify Git
git --version     # Should be 2.38 or higher
```

### Python Packages
```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows
.\venv\Scripts\activate
# macOS/Linux
source venv/bin/activate

# Install required packages
pip install -r requirements.txt
```

**requirements.txt**:
```txt
# Core packages
aiohttp>=3.9.0
asyncio>=3.11.0
pydantic>=2.5.0
python-dotenv>=1.0.0

# AI/ML packages
openai>=1.10.0
langchain>=0.1.0
semantic-kernel>=0.5.0

# Development tools
pytest>=7.4.0
pytest-asyncio>=0.21.0
black>=23.0.0
mypy>=1.7.0

# Monitoring
prometheus-client>=0.19.0
structlog>=23.2.0
```

### VS Code Extensions
Ensure these extensions are installed and configured:
- ✅ GitHub Copilot
- ✅ GitHub Copilot Chat
- ✅ Python
- ✅ Pylance
- ✅ Python Test Explorer
- ✅ GitLens

### Azure Resources
```bash
# Required Azure services
- Azure OpenAI Service (GPT-4 deployment)
- Azure Container Instances
- Azure Monitor
- Azure Key Vault

# Create resources using provided script
./scripts/setup-module-21-azure.sh
```

## 📋 Pre-Module Checklist

### 1. Verify GitHub Copilot Access
```bash
# Check Copilot status
gh copilot status

# Should show:
# ✓ Copilot is enabled
# ✓ Copilot Chat is available
```

### 2. Test Azure Connection
```python
# test_azure_connection.py
import os
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

# Test Key Vault connection
credential = DefaultAzureCredential()
vault_url = f"https://{os.getenv('KEY_VAULT_NAME')}.vault.azure.net/"
client = SecretClient(vault_url=vault_url, credential=credential)

try:
    secret = client.get_secret("test-secret")
    print("✅ Azure connection successful")
except Exception as e:
    print(f"❌ Azure connection failed: {e}")
```

### 3. Validate Environment
Run the validation script:
```bash
python scripts/validate-module-21.py
```

Expected output:
```
✅ Python version: 3.11.6
✅ Required packages installed
✅ VS Code extensions detected
✅ GitHub Copilot active
✅ Azure services accessible
✅ All prerequisites met!
```

## 🚀 Quick Setup

If you're starting fresh, use our quick setup script:
```bash
# Clone the module repository
git clone https://github.com/workshop/module-21-ai-agents.git
cd module-21-ai-agents

# Run setup script
./scripts/quick-setup.sh
```

## ⚠️ Common Issues

### Issue: "Module not found" errors
**Solution**: Ensure virtual environment is activated
```bash
# Windows
.\venv\Scripts\activate
# macOS/Linux
source venv/bin/activate
```

### Issue: Azure authentication fails
**Solution**: Login to Azure CLI
```bash
az login
az account set --subscription "Your Subscription Name"
```

### Issue: Copilot not providing suggestions
**Solution**: Check Copilot settings
1. Open VS Code settings (Cmd/Ctrl + ,)
2. Search for "copilot"
3. Ensure "Enable" is checked
4. Restart VS Code

## 📚 Recommended Reading

Before starting the exercises, review:
- [Introduction to AI Agents](https://docs.microsoft.com/ai-agents)
- [GitHub Copilot Agent Architecture](https://github.blog/copilot-agents)
- [Async Programming in Python](https://docs.python.org/3/library/asyncio.html)

## ✅ Ready to Start?

Once all prerequisites are met, proceed to:
- 📖 Read the module overview in [README.md](README.md)
- 🏃 Start with [Exercise 1: Build Your First Copilot Agent](exercises/exercise1-easy/README.md)
- 🎯 Complete all three exercises
- 🚀 Build your independent project

---

**Need Help?** Check the [workshop FAQ](../../FAQ.md) or post in the GitHub Discussions.