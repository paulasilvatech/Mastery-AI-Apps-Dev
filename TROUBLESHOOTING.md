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

### Module 1-5 (Fundamentals)
- **Copilot not suggesting**: Write more descriptive comments
- **Python import errors**: Check virtual environment activation
- **Git issues**: Ensure proper configuration with `git config --list`

### Module 6-10 (Intermediate)
- **Web server not starting**: Check port conflicts
- **Database connection fails**: Verify credentials and network
- **API timeouts**: Increase timeout values in code

### Module 11-15 (Advanced)
- **Kubernetes errors**: Check cluster connection with `kubectl cluster-info`
- **Terraform state issues**: Use `terraform refresh`
- **CI/CD pipeline fails**: Check secrets and permissions

### Module 16-20 (Enterprise)
- **Security scan failures**: Update dependencies
- **Monitoring gaps**: Verify Application Insights key
- **Deployment rollbacks**: Check deployment logs

### Module 21-25 (AI Agents)
- **Agent communication fails**: Verify MCP server is running
- **Function calling errors**: Check function signatures
- **Timeout in orchestration**: Increase async timeouts

### Module 26-30 (Mastery)
- **.NET build errors**: Clear NuGet cache with `dotnet nuget locals all --clear`
- **COBOL conversion issues**: Verify legacy code format
- **Integration test failures**: Check all service dependencies

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

## Platform-Specific Issues

### Windows
- **Script execution blocked**: Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- **Path too long**: Enable long path support in Windows
- **Line ending issues**: Configure Git with `git config --global core.autocrlf true`

### macOS
- **Permission denied**: Use `sudo` for system-wide installations
- **Homebrew issues**: Run `brew doctor` and follow recommendations
- **Python SSL errors**: Update certificates with `brew install ca-certificates`

### Linux
- **Package not found**: Update package lists with `sudo apt update`
- **Permission issues**: Add user to required groups (docker, etc.)
- **Display issues**: Set `DISPLAY` environment variable for GUI apps

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

## Emergency Recovery

### Reset Module
```bash
# Backup your work
./scripts/backup-progress.sh --modules [number]

# Clean module
rm -rf modules/module-XX/exercises/
git checkout modules/module-XX/exercises/
```

### Reset Environment
```bash
# Deactivate virtual environment
deactivate  # If active

# Remove and recreate
rm -rf .venv
python -m venv .venv
source .venv/bin/activate  # or .\.venv\Scripts\activate on Windows
pip install -r requirements.txt
```

### Reset Docker
```bash
# Stop all containers
docker stop $(docker ps -aq)

# Remove all containers
docker rm $(docker ps -aq)

# Clean system
docker system prune -a --volumes
```

## Still Having Issues?

1. **Search existing issues**: [GitHub Issues](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/issues)
2. **Ask the community**: [GitHub Discussions](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev/discussions)
3. **Check module README**: Each module has specific troubleshooting
4. **Review prerequisites**: Run `./scripts/validate-prerequisites.sh`

## Reporting New Issues

When reporting issues, please include:
1. Module number and exercise
2. Error message (full text)
3. Steps to reproduce
4. System information (OS, versions)
5. What you've already tried

---

Remember: Every error is a learning opportunity! 🚀

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
