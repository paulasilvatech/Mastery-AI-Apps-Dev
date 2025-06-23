# Module 07 Prerequisites

## 🚀 GitHub Codespaces (Recommended)

The easiest way to get started is using GitHub Codespaces, which provides a complete development environment in your browser.

### Option 1: Using GitHub Codespaces

1. **Fork the Repository**
   - Go to the main course repository
   - Click the "Fork" button in the top-right corner
   - This will create a copy of the entire repository in your account

2. **Create a Codespace**
   - In your forked repository, click the green "Code" button
   - Select the "Codespaces" tab
   - Click "Create codespace on main"
   - Wait for the environment to be ready (2-3 minutes)

3. **Navigate to Module 07**
   ```bash
   cd modules/module-07
   ```

4. **All tools are pre-installed!** 
   - Node.js 18.x ✅
   - Python 3.11 ✅
   - Docker ✅
   - VS Code Extensions ✅
   - GitHub Copilot ✅

### Option 2: Local Development

If you prefer to work locally, you'll need to install the following:

## 📋 System Requirements

- **Operating System**: Windows 10+, macOS 10.15+, or Ubuntu 20.04+
- **RAM**: Minimum 8GB (16GB recommended)
- **Disk Space**: At least 10GB free space
- **Internet**: Stable connection for package downloads

## 🛠️ Required Software

### 1. Node.js (18.x or later)
```bash
# Verify installation
node --version  # Should show v18.x.x or higher
```

### 2. Python (3.9 or later)
```bash
# Verify installation
python --version  # Should show Python 3.9.x or higher
```

### 3. Docker Desktop
- Download from [Docker Official Site](https://www.docker.com/products/docker-desktop/)
- Required for containerization exercises

### 4. Git
```bash
# Verify installation
git --version
```

### 5. Visual Studio Code
- Download from [code.visualstudio.com](https://code.visualstudio.com/)
- Install these extensions:
  - GitHub Copilot
  - Python
  - Pylance
  - ESLint
  - Prettier
  - Tailwind CSS IntelliSense

### 6. GitHub Copilot
- Active subscription required
- Sign in through VS Code

## 🔧 Development Setup

### For Codespaces Users

The development environment is already configured! Just run:

```bash
# Verify everything is working
cd modules/module-07
./scripts/validate-module-07.sh
```

### For Local Development

1. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR-USERNAME/REPOSITORY-NAME.git
   cd REPOSITORY-NAME/modules/module-07
   ```

2. **Install dependencies**
   ```bash
   # Frontend dependencies
   cd exercises/exercise1-todo-app/starter/frontend
   npm install
   
   # Backend dependencies
   cd ../backend
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

## 💡 Tips for Codespaces

### Resource Management
- **Free tier**: 60 hours/month of Codespaces usage
- **Stop your Codespace** when not in use to save hours
- **Delete old Codespaces** to free up storage

### Performance Tips
- Use a **4-core machine type** for better performance
- **Prebuild** option available for faster startup
- Browser-based VS Code works great, but you can also connect from desktop VS Code

### Working with the Repository
Since you forked the entire repository:
- Focus only on the `modules/module-07` directory
- Create branches for each exercise:
  ```bash
  git checkout -b module07-exercise1
  ```
- Push changes to your fork:
  ```bash
  git add .
  git commit -m "Complete exercise 1"
  git push origin module07-exercise1
  ```

## ✅ Validation Checklist

Run this script to ensure your environment is ready:

```bash
cd modules/module-07
./scripts/validate-module-07.sh
```

Expected output:
```
✅ Node.js 18.x installed
✅ Python 3.9+ installed
✅ Docker running
✅ Git configured
✅ VS Code extensions installed
✅ GitHub Copilot authenticated
✅ All prerequisites met!
```

## 🆘 Troubleshooting

### Codespaces Issues
- **Codespace won't start**: Check your usage limits
- **Extensions missing**: Rebuild the container
- **Performance slow**: Upgrade to a larger machine type

### Local Development Issues
- **Port conflicts**: Change ports in `.env` files
- **Permission errors**: Check file ownership
- **Module not found**: Verify you're in the correct directory

## 📌 Important Notes

1. **Fork vs Clone**: You must fork the repository to use Codespaces
2. **Costs**: Codespaces is free for 60 hours/month on the free tier
3. **Persistence**: Your work is saved in your fork
4. **Collaboration**: You can share your Codespace with others

Ready to start? Proceed to [Exercise 1](exercises/exercise1-todo-app/README.md)!
