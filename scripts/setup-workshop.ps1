# ========================================================================
# Mastery AI Apps and Development Workshop - Setup Script (PowerShell)
# ========================================================================
# This script sets up the complete workshop environment on Windows
# ========================================================================

# Requires -RunAsAdministrator

# Set error action preference
$ErrorActionPreference = "Stop"

# Colors for output
$colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Blue"
    Cyan = "Cyan"
}

# Workshop variables
$WORKSHOP_NAME = "Mastery AI Apps and Development Workshop"
$REQUIRED_PYTHON_VERSION = "3.11"
$REQUIRED_NODE_VERSION = "18"
$REQUIRED_DOTNET_VERSION = "8"

# Functions
function Print-Header {
    param([string]$Message)
    Write-Host "`n======================================" -ForegroundColor $colors.Blue
    Write-Host $Message -ForegroundColor $colors.Blue
    Write-Host "======================================`n" -ForegroundColor $colors.Blue
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
    Write-Host "ℹ $Message" -ForegroundColor $colors.Cyan
}

function Test-Command {
    param([string]$Command)
    
    try {
        if (Get-Command $Command -ErrorAction SilentlyContinue) {
            Print-Success "$Command is installed"
            return $true
        }
    }
    catch {
        # Ignore error
    }
    
    Print-Error "$Command is not installed"
    return $false
}

function Test-Python {
    if (Test-Command "python") {
        $version = python --version 2>&1 | Select-String -Pattern "\d+\.\d+" | ForEach-Object { $_.Matches[0].Value }
        $majorMinor = [version]$version
        $required = [version]$REQUIRED_PYTHON_VERSION
        
        if ($majorMinor -ge $required) {
            Print-Success "Python $version meets requirement (>= $REQUIRED_PYTHON_VERSION)"
            return $true
        }
        else {
            Print-Error "Python $version does not meet requirement (>= $REQUIRED_PYTHON_VERSION)"
            return $false
        }
    }
    return $false
}

function Test-Node {
    if (Test-Command "node") {
        $version = node --version | Select-String -Pattern "\d+" | ForEach-Object { $_.Matches[0].Value }
        
        if ([int]$version -ge [int]$REQUIRED_NODE_VERSION) {
            Print-Success "Node.js v$version meets requirement (>= $REQUIRED_NODE_VERSION)"
            return $true
        }
        else {
            Print-Error "Node.js v$version does not meet requirement (>= $REQUIRED_NODE_VERSION)"
            return $false
        }
    }
    return $false
}

function Test-DotNet {
    if (Test-Command "dotnet") {
        $version = dotnet --version | Select-String -Pattern "^\d+" | ForEach-Object { $_.Matches[0].Value }
        
        if ([int]$version -ge [int]$REQUIRED_DOTNET_VERSION) {
            Print-Success ".NET SDK $version meets requirement (>= $REQUIRED_DOTNET_VERSION)"
            return $true
        }
        else {
            Print-Error ".NET SDK $version does not meet requirement (>= $REQUIRED_DOTNET_VERSION)"
            return $false
        }
    }
    return $false
}

function Install-Chocolatey {
    if (-not (Test-Command "choco")) {
        Print-Header "Installing Chocolatey Package Manager"
        
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        Print-Success "Chocolatey installed"
    }
}

function Install-Python {
    Print-Header "Installing Python $REQUIRED_PYTHON_VERSION"
    
    choco install python --version=$REQUIRED_PYTHON_VERSION -y
    
    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Install-Node {
    Print-Header "Installing Node.js $REQUIRED_NODE_VERSION"
    
    choco install nodejs --version=$REQUIRED_NODE_VERSION -y
    
    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Install-DotNet {
    Print-Header "Installing .NET SDK $REQUIRED_DOTNET_VERSION"
    
    choco install dotnet-sdk --version=$REQUIRED_DOTNET_VERSION -y
    
    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Install-Docker {
    Print-Header "Installing Docker Desktop"
    
    choco install docker-desktop -y
    
    Print-Warning "Please restart your computer after setup to use Docker"
    Print-Info "Docker Desktop will start automatically after restart"
}

function Install-AzureCLI {
    Print-Header "Installing Azure CLI"
    
    choco install azure-cli -y
    
    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Install-GitHubCLI {
    Print-Header "Installing GitHub CLI"
    
    choco install gh -y
    
    # Refresh environment
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Install-Git {
    if (-not (Test-Command "git")) {
        Print-Header "Installing Git"
        choco install git -y
        
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    }
}

function Install-VSCode {
    Print-Header "Installing VS Code"
    
    if (-not (Test-Command "code")) {
        choco install vscode -y
        
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    }
    
    Print-Success "Installing VS Code extensions..."
    
    $extensions = @(
        "GitHub.copilot",
        "GitHub.copilot-chat",
        "ms-python.python",
        "ms-python.vscode-pylance",
        "ms-dotnettools.csharp",
        "ms-dotnettools.vscode-dotnet-runtime",
        "ms-azuretools.vscode-docker",
        "ms-vscode.azure-account",
        "ms-azuretools.vscode-azureappservice",
        "ms-azuretools.vscode-azurefunctions",
        "ms-kubernetes-tools.vscode-kubernetes-tools",
        "hashicorp.terraform",
        "ms-vscode.vscode-typescript-next",
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint",
        "eamodio.gitlens"
    )
    
    foreach ($ext in $extensions) {
        code --install-extension $ext --force
        Print-Success "Installed: $ext"
    }
}

function Setup-PythonEnvironment {
    Print-Header "Setting up Python environment"
    
    # Create virtual environment
    python -m venv .venv
    Print-Success "Created Python virtual environment"
    
    # Activate and upgrade pip
    & .\.venv\Scripts\Activate.ps1
    python -m pip install --upgrade pip
    
    # Install base packages
    if (Test-Path "requirements.txt") {
        pip install -r requirements.txt
    }
    else {
        Print-Warning "No requirements.txt found, installing base packages..."
        pip install requests python-dotenv pytest black flake8 mypy ipython notebook
    }
    
    Print-Success "Python environment setup complete"
    Print-Warning "Run '.\.venv\Scripts\Activate.ps1' to activate the environment"
}

function Configure-Git {
    Print-Header "Configuring Git"
    
    # Check if git config is already set
    $userName = git config --global user.name 2>$null
    if (-not $userName) {
        $gitUsername = Read-Host "Enter your Git username"
        git config --global user.name $gitUsername
    }
    
    $userEmail = git config --global user.email 2>$null
    if (-not $userEmail) {
        $gitEmail = Read-Host "Enter your Git email"
        git config --global user.email $gitEmail
    }
    
    # Set useful Git aliases
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.st status
    git config --global alias.last 'log -1 HEAD'
    
    Print-Success "Git configuration complete"
}

function Setup-Azure {
    Print-Header "Setting up Azure"
    
    if (Test-Command "az") {
        Print-Warning "Please login to Azure:"
        az login
        
        # List subscriptions
        Print-Success "Available Azure subscriptions:"
        az account list --output table
        
        # Set default subscription if multiple
        $subId = Read-Host "Enter subscription ID to use (press Enter to skip)"
        if ($subId) {
            az account set --subscription $subId
            Print-Success "Set default subscription"
        }
    }
    else {
        Print-Warning "Azure CLI not installed, skipping Azure setup"
    }
}

function Setup-GitHub {
    Print-Header "Setting up GitHub"
    
    if (Test-Command "gh") {
        Print-Warning "Please authenticate with GitHub:"
        gh auth login
        
        # Check GitHub Copilot status
        try {
            gh copilot status 2>$null
            Print-Success "GitHub Copilot is active"
        }
        catch {
            Print-Warning "GitHub Copilot is not active. Please ensure you have an active subscription"
        }
    }
    else {
        Print-Warning "GitHub CLI not installed, skipping GitHub setup"
    }
}

function Create-WorkshopDirectories {
    Print-Header "Creating workshop directories"
    
    $directories = @(
        "infrastructure\bicep",
        "infrastructure\terraform",
        "infrastructure\github-actions",
        "infrastructure\arm-templates",
        "docs",
        ".github\workflows"
    )
    
    foreach ($dir in $directories) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Print-Success "Created: $dir"
    }
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Main function
function Main {
    Clear-Host
    Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     Mastery AI Apps and Development Workshop Setup          ║
║                    (Windows PowerShell)                      ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Blue

    # Check if running as administrator
    if (-not (Test-Administrator)) {
        Print-Error "This script requires administrator privileges"
        Print-Info "Please run PowerShell as Administrator and try again"
        exit 1
    }
    
    # Install Chocolatey if needed
    Install-Chocolatey
    
    # Check and install prerequisites
    Print-Header "Checking prerequisites"
    
    # Git
    Install-Git
    
    # Python
    if (-not (Test-Python)) {
        Install-Python
    }
    
    # Node.js
    if (-not (Test-Node)) {
        Install-Node
    }
    
    # .NET
    if (-not (Test-DotNet)) {
        Install-DotNet
    }
    
    # Docker
    if (-not (Test-Command "docker")) {
        Install-Docker
    }
    
    # Azure CLI
    if (-not (Test-Command "az")) {
        Install-AzureCLI
    }
    
    # GitHub CLI
    if (-not (Test-Command "gh")) {
        Install-GitHubCLI
    }
    
    # VS Code
    Install-VSCode
    
    # Setup environments
    Setup-PythonEnvironment
    Configure-Git
    Setup-Azure
    Setup-GitHub
    Create-WorkshopDirectories
    
    # Final summary
    Print-Header "Setup Complete!"
    
    Write-Host "✓ Workshop environment is ready!" -ForegroundColor Green
    Write-Host "`nNext steps:"
    Write-Host "1. Activate Python environment: " -NoNewline
    Write-Host ".\.venv\Scripts\Activate.ps1" -ForegroundColor Yellow
    Write-Host "2. Start with Module 1: " -NoNewline
    Write-Host "cd modules\module-01" -ForegroundColor Yellow
    Write-Host "3. Open in VS Code: " -NoNewline
    Write-Host "code ." -ForegroundColor Yellow
    Write-Host "`nRun " -NoNewline
    Write-Host ".\scripts\validate-prerequisites.ps1" -ForegroundColor Yellow -NoNewline
    Write-Host " to verify everything is working"
    Write-Host "`nHappy learning! 🚀"
}

# Run main function
Main
