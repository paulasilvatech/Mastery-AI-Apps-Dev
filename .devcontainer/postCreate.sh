#!/bin/bash

echo "🚀 Setting up Mastery AI Apps Dev environment..."

# Update package lists
sudo apt-get update

# Install additional tools that might be useful
echo "📦 Installing additional tools..."
sudo apt-get install -y \
    jq \
    tree \
    httpie \
    sqlite3 \
    postgresql-client

# Install global npm packages
echo "📦 Installing global npm packages..."
npm install -g \
    create-react-app \
    create-vite@latest \
    typescript \
    nodemon \
    pm2

# Install Python packages globally
echo "🐍 Installing Python packages..."
pip install --upgrade pip
pip install \
    black \
    flake8 \
    pytest \
    httpx \
    ipython

# Create useful aliases
echo "🔧 Setting up aliases..."
cat >> ~/.bashrc << 'EOL'

# Module navigation aliases
alias mod7="cd $CODESPACE_VSCODE_FOLDER/modules/module-07"
alias mod13="cd $CODESPACE_VSCODE_FOLDER/modules/module-13"

# Git aliases
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gl="git log --oneline"

# Python aliases
alias py="python"
alias pip="pip3"

# Docker aliases
alias d="docker"
alias dc="docker-compose"

# Azure aliases
alias azl="az login --use-device-code"

EOL

# Create a welcome message
cat > ~/.welcome_message.txt << 'EOL'
╔══════════════════════════════════════════════════════════════╗
║           Welcome to Mastery AI Apps Dev Codespace!          ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Quick Commands:                                             ║
║  • mod7    - Go to Module 7 (Web Applications)              ║
║  • mod13   - Go to Module 13 (Infrastructure as Code)       ║
║  • azl     - Azure login with device code                   ║
║                                                              ║
║  All tools are pre-installed and ready to use!              ║
║                                                              ║
║  Happy coding! 🚀                                            ║
╚══════════════════════════════════════════════════════════════╝
EOL

# Display welcome message on terminal start
echo 'cat ~/.welcome_message.txt' >> ~/.bashrc

# Pre-download common Docker images to speed things up
echo "🐳 Pre-pulling common Docker images..."
docker pull python:3.11-slim &
docker pull node:18-alpine &
docker pull nginx:alpine &

# Set up GitHub CLI auth (if not already done)
if ! gh auth status >/dev/null 2>&1; then
    echo "⚠️  GitHub CLI not authenticated. Run 'gh auth login' when ready."
fi

# Create a directory for student work
mkdir -p ~/workspace
ln -s $CODESPACE_VSCODE_FOLDER ~/workspace/course

# Final message
echo "✅ Codespace setup complete!"
echo ""
echo "📌 Quick tips:"
echo "   - Use 'mod7' or 'mod13' to quickly navigate to modules"
echo "   - All course files are in: $CODESPACE_VSCODE_FOLDER"
echo "   - Your workspace is in: ~/workspace"
echo ""
echo "🎯 Ready to start learning!" 