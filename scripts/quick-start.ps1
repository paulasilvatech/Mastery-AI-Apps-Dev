# Quick Start Script for Mastery AI Code Development Workshop
# PowerShell version for Windows users

$ErrorActionPreference = "Stop"

# Colors
function Write-Status($message) {
    Write-Host "[INFO] $message" -ForegroundColor Blue
}

function Write-Success($message) {
    Write-Host "[✓] $message" -ForegroundColor Green
}

function Write-Warning($message) {
    Write-Host "[WARNING] $message" -ForegroundColor Yellow
}

function Write-Error($message) {
    Write-Host "[ERROR] $message" -ForegroundColor Red
}

# Banner
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║     🚀 Mastery AI Code Development - Quick Start 🚀       ║" -ForegroundColor Blue
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""

# Check critical requirements
Write-Status "Checking critical requirements..."

# Check Python
try {
    $pythonVersion = python --version 2>&1
    Write-Success "Python installed: $pythonVersion"
} catch {
    Write-Error "Python 3 is required but not installed!"
    Write-Host "Please install Python 3.11 or later from https://python.org"
    exit 1
}

# Check Git
try {
    $gitVersion = git --version
    Write-Success "Git installed: $gitVersion"
} catch {
    Write-Error "Git is required but not installed!"
    Write-Host "Please install Git from https://git-scm.com"
    exit 1
}

# Check VS Code
try {
    $codeVersion = code --version 2>&1
    Write-Success "VS Code is installed"
} catch {
    Write-Warning "VS Code not found in PATH. Make sure it's installed!"
    Write-Host "Download from: https://code.visualstudio.com"
}

# Check GitHub CLI (optional)
try {
    $ghVersion = gh --version
    Write-Success "GitHub CLI is installed"
    
    # Check Copilot status
    try {
        gh copilot status | Out-Null
        Write-Success "GitHub Copilot is active!"
    } catch {
        Write-Warning "GitHub Copilot not configured. Run: gh auth login"
    }
} catch {
    Write-Warning "GitHub CLI not installed (optional)"
}

Write-Host ""
Write-Status "Setting up Module 01..."

# Navigate to module 01
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent $scriptPath
$modulePath = Join-Path $rootPath "modules\module-01"

if (-not (Test-Path $modulePath)) {
    Write-Error "Module 01 directory not found!"
    exit 1
}

Set-Location $modulePath

# Create Python virtual environment
Write-Status "Creating Python virtual environment..."
python -m venv venv
Write-Success "Virtual environment created"

# Activate virtual environment
Write-Status "Activating virtual environment..."
& ".\venv\Scripts\Activate.ps1"
Write-Success "Virtual environment activated"

# Create requirements.txt if it doesn't exist
if (-not (Test-Path "requirements.txt")) {
    @"
# Basic requirements for Module 01
pytest>=7.0.0
black>=23.0.0
flake8>=6.0.0
"@ | Out-File -FilePath "requirements.txt" -Encoding UTF8
    Write-Success "Created requirements.txt"
}

# Install basic packages
Write-Status "Installing Python packages..."
python -m pip install --quiet --upgrade pip
pip install --quiet -r requirements.txt
Write-Success "Packages installed"

# Create VS Code settings if not exists
$vscodeDir = ".vscode"
if (-not (Test-Path $vscodeDir)) {
    New-Item -ItemType Directory -Path $vscodeDir | Out-Null
}

$settingsFile = Join-Path $vscodeDir "settings.json"
if (-not (Test-Path $settingsFile)) {
    @'
{
    "python.defaultInterpreterPath": "./venv/Scripts/python.exe",
    "python.terminal.activateEnvironment": true,
    "github.copilot.enable": {
        "*": true,
        "yaml": true,
        "plaintext": true,
        "markdown": true
    },
    "editor.inlineSuggest.enabled": true,
    "editor.suggestOnTriggerCharacters": true,
    "python.linting.enabled": true,
    "python.linting.flake8Enabled": true,
    "python.formatting.provider": "black"
}
'@ | Out-File -FilePath $settingsFile -Encoding UTF8
    Write-Success "Created VS Code settings"
}

# Create quick reference file
@'
# 🚀 Quick Reference - Module 01

## GitHub Copilot Shortcuts

| Action | Windows | macOS |
|--------|---------|-------|
| Accept suggestion | `Tab` | `Tab` |
| Dismiss suggestion | `Esc` | `Esc` |
| Next suggestion | `Alt + ]` | `Option + ]` |
| Previous suggestion | `Alt + [` | `Option + [` |
| Open Copilot | `Ctrl + Enter` | `Cmd + Enter` |
| Copilot Chat | `Ctrl + Shift + I` | `Cmd + Shift + I` |

## Quick Commands

```powershell
# Run your first AI file
cd exercises\exercise1-easy\starter
python hello_ai.py

# Run tests
cd ..\tests
python -m pytest test_hello_ai.py

# Format code with Black
black hello_ai.py

# Check code style
flake8 hello_ai.py
```

## Tips for Success

1. **Write clear comments** before coding
2. **Be specific** in your prompts
3. **Iterate** - first suggestion isn't always best
4. **Review** generated code before using

Happy coding with AI! 🤖
'@ | Out-File -FilePath "QUICK_REFERENCE.md" -Encoding UTF8

Write-Success "Created quick reference guide"

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✨ Quick Start Complete! ✨" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "📁 You're in: $modulePath"
Write-Host "📝 Virtual environment: activated"
Write-Host "📦 Packages: installed"
Write-Host "⚙️  VS Code: configured"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Open VS Code: " -NoNewline
Write-Host "code ." -ForegroundColor Blue
Write-Host "2. Open the exercise: " -NoNewline
Write-Host "exercises\exercise1-easy\starter\hello_ai.py" -ForegroundColor Blue
Write-Host "3. Start coding with Copilot!"
Write-Host ""
Write-Host "💡 See QUICK_REFERENCE.md for shortcuts and tips"
Write-Host ""
Write-Host "Happy AI coding! 🚀" -ForegroundColor Green
