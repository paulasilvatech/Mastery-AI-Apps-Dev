# ========================================================================
# Mastery AI Apps and Development Workshop - Quick Start Script (PowerShell)
# ========================================================================
# Get started with the workshop in 5 minutes! (Windows PowerShell)
# ========================================================================

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors for output
$colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Blue"
    Purple = "Magenta"
    Cyan = "Cyan"
}

# Workshop variables
$WORKSHOP_NAME = "Mastery AI Apps and Development Workshop"
$FIRST_MODULE = "module-01"

# Timer
$START_TIME = Get-Date

# Functions
function Print-Header {
    param([string]$Message)
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $colors.Blue
    Write-Host $Message -ForegroundColor $colors.Blue
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor $colors.Blue
}

function Print-Step {
    param([string]$Message)
    Write-Host "▶ $Message" -ForegroundColor $colors.Cyan
}

function Print-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor $colors.Green
}

function Print-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor $colors.Red
}

function Print-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor $colors.Yellow
}

function Print-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor $colors.Purple
}

function Show-Progress {
    param(
        [int]$Current,
        [int]$Total
    )
    
    $percent = [int](($Current / $Total) * 100)
    $filled = [int]($percent / 5)
    
    Write-Host -NoNewline "`r["
    Write-Host -NoNewline ("█" * $filled) -ForegroundColor Green
    Write-Host -NoNewline ("░" * (20 - $filled))
    Write-Host -NoNewline "] $percent%"
    
    if ($Current -eq $Total) {
        Write-Host ""
    }
}

function Test-Command {
    param([string]$Command)
    
    try {
        if (Get-Command $Command -ErrorAction SilentlyContinue) {
            return $true
        }
    }
    catch {
        # Ignore error
    }
    return $false
}

function Check-CriticalRequirements {
    Print-Header "🚀 Quick Requirements Check"
    
    $requirementsMet = $true
    
    # Check Git
    Print-Step "Checking Git..."
    if (Test-Command "git") {
        Print-Success "Git installed"
    }
    else {
        Print-Error "Git not found - required for workshop"
        $requirementsMet = $false
    }
    
    # Check Python
    Print-Step "Checking Python..."
    if (Test-Command "python") {
        $version = python --version 2>&1
        Print-Success "Python $version found"
    }
    else {
        Print-Warning "Python 3 not found - will need for exercises"
    }
    
    # Check VS Code
    Print-Step "Checking VS Code..."
    if (Test-Command "code") {
        Print-Success "VS Code installed"
    }
    else {
        Print-Warning "VS Code not found - recommended editor"
    }
    
    # Check GitHub CLI
    Print-Step "Checking GitHub CLI..."
    if (Test-Command "gh") {
        try {
            gh auth status 2>&1 | Out-Null
            Print-Success "GitHub CLI authenticated"
        }
        catch {
            Print-Warning "GitHub CLI not authenticated - run 'gh auth login'"
        }
    }
    else {
        Print-Warning "GitHub CLI not found - useful for workshop"
    }
    
    if (-not $requirementsMet) {
        Print-Error "Critical requirements missing!"
        Print-Info "Run .\scripts\setup-workshop.ps1 for complete setup"
        exit 1
    }
}

function Setup-FirstModule {
    Print-Header "📁 Setting Up Your First Module"
    
    # Navigate to first module
    try {
        Set-Location "modules\$FIRST_MODULE"
        Print-Success "Navigated to Module 1"
    }
    catch {
        Print-Error "Cannot find modules directory"
        Print-Info "Make sure you're in the workshop root directory"
        exit 1
    }
    
    # Create starter files if they don't exist
    if (-not (Test-Path "hello_ai.py")) {
        Print-Step "Creating your first AI-powered Python file..."
        
        @'
#!/usr/bin/env python3
"""
Your first AI-powered code!
Type comments to get GitHub Copilot suggestions.
"""

# TODO: Create a function that generates a personalized welcome message
# Hint: Press Tab to accept Copilot's suggestion!


# TODO: Create a function that returns the current date and time in a friendly format


# TODO: Create a main function that uses both functions above


if __name__ == "__main__":
    # TODO: Call the main function
    pass
'@ | Out-File -FilePath "hello_ai.py" -Encoding UTF8
        
        Print-Success "Created hello_ai.py"
    }
    
    # Create a simple exercise
    if (-not (Test-Path "exercise1.py")) {
        @'
"""
Exercise 1: AI-Assisted Calculator

Use GitHub Copilot to help you create a simple calculator.
Follow the TODOs and let Copilot assist you!
"""

# TODO: Create a Calculator class with methods for:
# - add(a, b)
# - subtract(a, b)  
# - multiply(a, b)
# - divide(a, b) - handle division by zero!


# TODO: Create a function that takes user input and performs calculations


# TODO: Add a main function with a simple menu


if __name__ == "__main__":
    print("Welcome to your AI-assisted calculator!")
    # TODO: Run the calculator
'@ | Out-File -FilePath "exercise1.py" -Encoding UTF8
        
        Print-Success "Created exercise1.py"
    }
}

function Create-QuickReference {
    Print-Header "📚 Creating Quick Reference"
    
    @'
# Quick Reference Guide

## 🎯 GitHub Copilot Shortcuts

### VS Code
- **Accept suggestion**: `Tab`
- **Next suggestion**: `Alt + ]`
- **Previous suggestion**: `Alt + [`
- **Open Copilot**: `Ctrl + Shift + I`

## 💡 Effective Copilot Prompts

### For Functions
```python
# Create a function that validates email addresses using regex
# It should return True for valid emails, False otherwise
# Handle edge cases like missing @ or invalid domains
```

### For Classes
```python
# Create a User class with:
# - Properties: name, email, age
# - Method to validate email
# - Method to check if user is adult (18+)
# - String representation method
```

### For Error Handling
```python
# Add try-except blocks to handle:
# - File not found errors
# - Network connection errors
# - Invalid input errors
# Return meaningful error messages
```

## 🚀 Quick Commands

```bash
# Activate Python environment
.\.venv\Scripts\activate     # Windows
source .venv/bin/activate    # Linux/Mac

# Run Python file
python hello_ai.py

# Open in VS Code
code .

# Check Copilot status
gh copilot status
```

## 📋 Module Progress Tracker

- [ ] Module 1: Introduction to AI-Powered Development
- [ ] Module 2: GitHub Copilot Core Features
- [ ] Module 3: Effective Prompting Techniques
- [ ] Module 4: AI-Assisted Debugging and Testing
- [ ] Module 5: Documentation and Code Quality

## 🔗 Useful Links

- [Workshop Repository](https://github.com/paulasilvatech/Mastery-AI-Apps-Dev)
- [GitHub Copilot Docs](https://docs.github.com/copilot)
- [VS Code Shortcuts](https://code.visualstudio.com/shortcuts/keyboard-shortcuts-windows.pdf)

## 💬 Getting Help

1. Check module README files
2. Review exercise solutions
3. Consult troubleshooting guide
4. Ask Copilot for help!

---
Happy coding with AI! 🤖✨
'@ | Out-File -FilePath "QUICK_REFERENCE.md" -Encoding UTF8
    
    Print-Success "Created QUICK_REFERENCE.md"
}

function Setup-VSCodeWorkspace {
    Print-Header "⚙️ Configuring VS Code Workspace"
    
    # Create VS Code workspace settings
    New-Item -ItemType Directory -Path ".vscode" -Force | Out-Null
    
    @'
{
    "github.copilot.enable": {
        "*": true,
        "yaml": true,
        "plaintext": true,
        "markdown": true
    },
    "editor.inlineSuggest.enabled": true,
    "editor.suggestSelection": "first",
    "python.defaultInterpreterPath": ".venv\\Scripts\\python.exe",
    "python.terminal.activateEnvironment": true,
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "files.autoSave": "onFocusChange",
    "editor.formatOnSave": true,
    "editor.wordWrap": "on",
    "terminal.integrated.defaultProfile.windows": "PowerShell"
}
'@ | Out-File -FilePath ".vscode\settings.json" -Encoding UTF8
    
    # Create recommended extensions
    @'
{
    "recommendations": [
        "GitHub.copilot",
        "GitHub.copilot-chat",
        "ms-python.python",
        "ms-python.vscode-pylance",
        "ms-toolsai.jupyter",
        "esbenp.prettier-vscode"
    ]
}
'@ | Out-File -FilePath ".vscode\extensions.json" -Encoding UTF8
    
    Print-Success "VS Code workspace configured"
}

function Show-Tips {
    Print-Header "💡 Pro Tips for Getting Started"
    
    $tips = @(
        "Press Tab to accept Copilot suggestions"
        "Write descriptive comments to get better suggestions"
        "Use Ctrl+Enter to see multiple suggestions"
        "Break complex problems into smaller functions"
        "Review Copilot suggestions before accepting"
        "Use type hints for better Python suggestions"
        "Experiment with different comment styles"
        "Try pair programming with Copilot!"
    )
    
    for ($i = 0; $i -lt $tips.Count; $i++) {
        Write-Host "$($i+1). " -NoNewline -ForegroundColor Cyan
        Write-Host $tips[$i]
        Start-Sleep -Milliseconds 300
    }
}

function Final-Setup {
    Print-Header "🎉 Final Steps"
    
    # Calculate elapsed time
    $END_TIME = Get-Date
    $ELAPSED = $END_TIME - $START_TIME
    $MINUTES = [int]$ELAPSED.TotalMinutes
    $SECONDS = $ELAPSED.Seconds
    
    Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║            🎊 Quick Start Complete! 🎊                       ║
║                                                              ║
║         Time taken: $MINUTES`m $SECONDS`s                              ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Green
    
    Write-Host "`n📂 Your workshop structure:" -ForegroundColor $colors.Purple
    Write-Host @"
mastery-ai-apps-dev/
├── modules/
│   ├── module-01/ $("← You are here" | Write-Host -ForegroundColor Green -NoNewline)
│   │   ├── hello_ai.py
│   │   └── exercise1.py
│   └── ... (29 more modules)
├── scripts/
├── QUICK_REFERENCE.md
└── README.md
"@
    
    Write-Host "`n🚀 Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Open VS Code: " -NoNewline
    Write-Host "code ." -ForegroundColor Cyan
    Write-Host "2. Open hello_ai.py and start coding with Copilot!"
    Write-Host "3. Try the exercises in exercise1.py"
    Write-Host "4. Check QUICK_REFERENCE.md for tips"
    
    Write-Host "`nHappy learning with AI! 🤖✨" -ForegroundColor Green
}

function Interactive-Mode {
    Clear-Host
    Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   🚀 Mastery AI Apps and Development Workshop               ║
║              5-Minute Quick Start                            ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Blue
    
    Write-Host "Welcome! Let's get you started with AI-powered development in 5 minutes." -ForegroundColor Cyan
    Write-Host ""
    
    Read-Host "Press Enter to begin the quick setup..."
    
    # Run setup steps with progress
    $steps = 5
    $current = 0
    
    Write-Host "`nStarting quick setup..." -ForegroundColor Yellow
    Write-Host ""
    
    # Step 1
    $current++
    Show-Progress $current $steps
    Check-CriticalRequirements
    
    # Step 2
    $current++
    Show-Progress $current $steps
    Setup-FirstModule
    
    # Step 3
    $current++
    Show-Progress $current $steps
    Create-QuickReference
    
    # Step 4
    $current++
    Show-Progress $current $steps
    Setup-VSCodeWorkspace
    
    # Step 5
    $current++
    Show-Progress $current $steps
    Show-Tips
    
    # Final
    Final-Setup
}

# Main execution
function Main {
    # Check if we're in the right directory
    if (-not (Test-Path "README.md") -or -not (Test-Path "modules")) {
        Print-Error "Please run this script from the workshop root directory"
        exit 1
    }
    
    # Run interactive setup
    Interactive-Mode
}

# Run main function
Main
