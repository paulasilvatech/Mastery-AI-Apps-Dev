# 🔧 Troubleshooting Guide

## Common Issues and Solutions

### Setup Issues

#### Git Clone Fails
```bash
# Solution: Use HTTPS instead of SSH
git clone https://github.com/your-username/mastery-ai-code-development.git
```

#### Node.js Version Error
```bash
# Solution: Use nvm to install correct version
nvm install 18
nvm use 18
```

#### Docker Not Running
```bash
# Solution: Start Docker Desktop
# Mac: open -a Docker
# Windows: Start Docker Desktop from Start Menu
# Linux: sudo systemctl start docker
```

### AI Tool Issues

#### GitHub Copilot Not Working
1. Check subscription status
2. Verify VS Code extension is installed
3. Sign out and sign in again
4. Check firewall/proxy settings

#### AI Assistant Timeouts
- Reduce prompt complexity
- Break down into smaller tasks
- Check internet connection
- Try alternative AI models

### Module-Specific Issues

#### Tests Failing
```bash
# Solution: Install dependencies first
npm install
# or
pip install -r requirements.txt
```

#### Permission Errors
```bash
# Solution: Make scripts executable
chmod +x ./scripts/*.sh
```

## Still Stuck?

1. Check our [FAQ](./FAQ.md)
2. Search existing GitHub issues
3. Ask in Discord #help channel
4. Create a new issue with:
   - Error message
   - Steps to reproduce
   - Environment details 