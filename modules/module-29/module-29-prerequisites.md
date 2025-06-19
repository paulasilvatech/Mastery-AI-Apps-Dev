# Prerequisites for Module 29: Enterprise Architecture Review (.NET)

## 🎯 Required Knowledge

Before starting this module, you must have:

### From Previous Modules
- ✅ **Modules 1-28 Completed**: Full workshop knowledge
- ✅ **Module 26 Especially**: Enterprise patterns with .NET
- ✅ **AI Integration**: Experience from Modules 21-25
- ✅ **Cloud Patterns**: Infrastructure knowledge from Module 28
- ✅ **Security Practices**: DevSecOps from Module 28

### .NET Expertise
- ✅ **C# 10-12**: Modern language features
- ✅ **ASP.NET Core**: Web API, MVC, Blazor basics
- ✅ **Entity Framework Core**: ORM and migrations
- ✅ **Async Programming**: Task, async/await patterns
- ✅ **LINQ**: Query expressions and methods

### Architecture Knowledge
- ✅ **Design Patterns**: GoF and enterprise patterns
- ✅ **Clean Architecture**: Separation of concerns
- ✅ **Domain-Driven Design**: Strategic and tactical patterns
- ✅ **Microservices**: Service boundaries and communication
- ✅ **Event-Driven**: Pub/sub and event sourcing

### Cloud & DevOps
- ✅ **Azure Services**: Core services knowledge
- ✅ **Containers**: Docker and Kubernetes basics
- ✅ **CI/CD**: Pipeline creation and deployment
- ✅ **IaC**: Bicep or Terraform experience
- ✅ **Monitoring**: Logging and metrics

## 🛠️ Required Software

### Development Environment

#### Visual Studio 2022 (Recommended)
```powershell
# Download and install Visual Studio 2022 Enterprise/Professional
# https://visualstudio.microsoft.com/downloads/

# Required Workloads:
# - ASP.NET and web development
# - Azure development
# - .NET desktop development
# - Data storage and processing
# - Container development tools
```

#### Alternative: VS Code with Extensions
```bash
# Install VS Code
winget install Microsoft.VisualStudioCode

# Required extensions
code --install-extension ms-dotnettools.csharp
code --install-extension ms-dotnettools.vscode-dotnet-runtime
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-vscode.azure-account
code --install-extension ms-azuretools.vscode-azurefunctions
code --install-extension GitHub.copilot
code --install-extension ms-semantic-kernel.semantic-kernel
code --install-extension humao.rest-client
```

#### .NET 8 SDK
```bash
# Windows (winget)
winget install Microsoft.DotNet.SDK.8

# macOS
brew install --cask dotnet-sdk

# Linux (Ubuntu/Debian)
wget https://dot.net/v1/dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --channel 8.0

# Verify installation
dotnet --version  # Should show 8.0.x
```

### Essential .NET Global Tools
```bash
# Entity Framework Core tools
dotnet tool install --global dotnet-ef

# Code formatting
dotnet tool install --global dotnet-format

# Architecture tests
dotnet tool install --global dotnet-archtest

# Performance diagnostics
dotnet tool install --global dotnet-counters
dotnet tool install --global dotnet-trace
dotnet tool install --global dotnet-dump

# Security scanning
dotnet tool install --global security-scan

# API documentation
dotnet tool install --global Swashbuckle.AspNetCore.Cli

# Package vulnerability scanning
dotnet tool install --global dotnet-outdated-tool

# Verify tools
dotnet tool list --global
```

### Azure Tools & SDKs
```bash
# Azure CLI
# Windows
winget install Microsoft.AzureCLI

# macOS
brew install azure-cli

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Azure Functions Core Tools
npm install -g azure-functions-core-tools@4

# Azure Storage Explorer
# Download from: https://azure.microsoft.com/features/storage-explorer/

# Azurite (Local Azure Storage Emulator)
npm install -g azurite

# Cosmos DB Emulator (Windows only)
# Download from: https://aka.ms/cosmosdb-emulator
```

### Container Tools
```bash
# Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop/

# Verify Docker
docker --version
docker compose version

# Kubernetes tools
# kubectl
winget install Kubernetes.kubectl

# Helm
winget install Helm.Helm

# k9s (Kubernetes CLI)
winget install k9s

# Kind (Kubernetes in Docker)
winget install Kubernetes.kind
```

### Database Tools
```bash
# SQL Server 2022 Developer Edition
# Download from: https://www.microsoft.com/sql-server/sql-server-downloads

# Alternative: SQL Server in Docker
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=YourStrong@Passw0rd" \
  -p 1433:1433 --name sql2022 --hostname sql2022 \
  -d mcr.microsoft.com/mssql/server:2022-latest

# Azure Data Studio
winget install Microsoft.AzureDataStudio

# Redis
docker run -d -p 6379:6379 --name redis redis:alpine

# PostgreSQL (optional)
docker run -d -p 5432:5432 --name postgres \
  -e POSTGRES_PASSWORD=postgres \
  postgres:16-alpine
```

## 🏗️ Project Setup

### 1. Create Solution Structure
```bash
# Create working directory
mkdir enterprise-architecture-mastery
cd enterprise-architecture-mastery

# Create solution
dotnet new sln -n EnterpriseArchitecture

# Create project structure
mkdir -p src/{Core,Infrastructure,Application,API,Tests}
mkdir -p src/Shared/{Common,AI}
mkdir -p tests/{Unit,Integration,Architecture}
mkdir -p infrastructure/{bicep,kubernetes,scripts}
mkdir -p docs/{architecture,api,deployment}
```

### 2. Install Common NuGet Packages
Create `Directory.Build.props` in solution root:
```xml
<Project>
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <LangVersion>12</LangVersion>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <GenerateDocumentationFile>true</GenerateDocumentationFile>
  </PropertyGroup>

  <ItemGroup>
    <!-- Analyzers -->
    <PackageReference Include="StyleCop.Analyzers" Version="1.2.0-beta.556">
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
    <PackageReference Include="SonarAnalyzer.CSharp" Version="9.16.0.82469">
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
    <PackageReference Include="Microsoft.CodeAnalysis.NetAnalyzers" Version="8.0.0">
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
  </ItemGroup>
</Project>
```

### 3. Create Shared Core Library
```bash
cd src/Shared/Common
dotnet new classlib -n Enterprise.Shared.Common
cd ../AI
dotnet new classlib -n Enterprise.Shared.AI

# Add to solution
cd ../../..
dotnet sln add src/Shared/Common/Enterprise.Shared.Common.csproj
dotnet sln add src/Shared/AI/Enterprise.Shared.AI.csproj
```

Install core packages:
```bash
# Common packages
cd src/Shared/Common
dotnet add package Microsoft.Extensions.DependencyInjection.Abstractions
dotnet add package Microsoft.Extensions.Logging.Abstractions
dotnet add package Microsoft.Extensions.Options
dotnet add package FluentValidation
dotnet add package MediatR
dotnet add package Polly
dotnet add package AutoMapper

# AI packages
cd ../AI
dotnet add package Microsoft.SemanticKernel
dotnet add package Azure.AI.OpenAI
dotnet add package Microsoft.ML
dotnet add package Microsoft.Extensions.AI
```

### 4. Create Base API Project Template
```bash
cd src/API
dotnet new webapi -n Enterprise.API --use-controllers
cd Enterprise.API

# Add essential packages
dotnet add package Microsoft.AspNetCore.OpenApi
dotnet add package Swashbuckle.AspNetCore
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
dotnet add package Microsoft.Identity.Web
dotnet add package AspNetCore.HealthChecks.UI.Client
dotnet add package Serilog.AspNetCore
dotnet add package Serilog.Sinks.Seq
dotnet add package OpenTelemetry.Instrumentation.AspNetCore
dotnet add package OpenTelemetry.Exporter.Prometheus
```

### 5. Configure Local Development Environment

Create `appsettings.Development.json`:
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost,1433;Database=EnterpriseDB;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True",
    "Redis": "localhost:6379",
    "ServiceBus": "Endpoint=sb://localhost.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=test"
  },
  "AzureOpenAI": {
    "Endpoint": "https://your-resource.openai.azure.com/",
    "ApiKey": "your-api-key",
    "DeploymentName": "gpt-4"
  },
  "SemanticKernel": {
    "Services": {
      "AzureOpenAI": {
        "Endpoint": "https://your-resource.openai.azure.com/",
        "ApiKey": "your-api-key"
      }
    }
  },
  "ApplicationInsights": {
    "ConnectionString": "InstrumentationKey=00000000-0000-0000-0000-000000000000"
  }
}
```

### 6. Setup Azure Resources (Local Development)

Create `infrastructure/scripts/setup-local-dev.ps1`:
```powershell
# Setup script for local development
Write-Host "Setting up local development environment..." -ForegroundColor Green

# Start SQL Server
docker run -d `
  --name sql-server `
  -e "ACCEPT_EULA=Y" `
  -e "MSSQL_SA_PASSWORD=YourStrong@Passw0rd" `
  -p 1433:1433 `
  mcr.microsoft.com/mssql/server:2022-latest

# Start Redis
docker run -d `
  --name redis `
  -p 6379:6379 `
  redis:alpine

# Start Azurite (Azure Storage Emulator)
docker run -d `
  --name azurite `
  -p 10000:10000 `
  -p 10001:10001 `
  -p 10002:10002 `
  mcr.microsoft.com/azure-storage/azurite

# Start Seq (Logging)
docker run -d `
  --name seq `
  -e ACCEPT_EULA=Y `
  -p 5341:80 `
  datalust/seq:latest

# Start Jaeger (Tracing)
docker run -d `
  --name jaeger `
  -p 5775:5775/udp `
  -p 6831:6831/udp `
  -p 6832:6832/udp `
  -p 5778:5778 `
  -p 16686:16686 `
  -p 14250:14250 `
  -p 14268:14268 `
  -p 14269:14269 `
  -p 4317:4317 `
  -p 4318:4318 `
  -p 9411:9411 `
  jaegertracing/all-in-one:latest

Write-Host "Local development environment ready!" -ForegroundColor Green
Write-Host "SQL Server: localhost,1433" -ForegroundColor Yellow
Write-Host "Redis: localhost:6379" -ForegroundColor Yellow
Write-Host "Azurite: localhost:10000-10002" -ForegroundColor Yellow
Write-Host "Seq: http://localhost:5341" -ForegroundColor Yellow
Write-Host "Jaeger: http://localhost:16686" -ForegroundColor Yellow
```

## 🧪 Validation Script

Create `validate-prerequisites.ps1`:
```powershell
# Module 29 Prerequisites Validation Script
Write-Host "Validating Module 29 Prerequisites..." -ForegroundColor Cyan

$errors = @()

# Check .NET SDK
Write-Host "`nChecking .NET SDK..." -ForegroundColor Yellow
$dotnetVersion = dotnet --version
if ($dotnetVersion -match "^8\.") {
    Write-Host "✅ .NET 8 SDK installed: $dotnetVersion" -ForegroundColor Green
} else {
    $errors += "❌ .NET 8 SDK not found (found: $dotnetVersion)"
}

# Check required tools
$tools = @(
    @{Name="Docker"; Command="docker --version"},
    @{Name="Git"; Command="git --version"},
    @{Name="Azure CLI"; Command="az --version"},
    @{Name="kubectl"; Command="kubectl version --client"}
)

foreach ($tool in $tools) {
    Write-Host "`nChecking $($tool.Name)..." -ForegroundColor Yellow
    try {
        $result = Invoke-Expression $tool.Command 2>$null
        Write-Host "✅ $($tool.Name) installed" -ForegroundColor Green
    } catch {
        $errors += "❌ $($tool.Name) not found"
    }
}

# Check .NET global tools
Write-Host "`nChecking .NET Global Tools..." -ForegroundColor Yellow
$requiredTools = @("dotnet-ef", "dotnet-format")
$installedTools = dotnet tool list --global

foreach ($tool in $requiredTools) {
    if ($installedTools -match $tool) {
        Write-Host "✅ $tool installed" -ForegroundColor Green
    } else {
        $errors += "❌ $tool not installed"
    }
}

# Check VS Code extensions (if VS Code is used)
if (Get-Command code -ErrorAction SilentlyContinue) {
    Write-Host "`nChecking VS Code Extensions..." -ForegroundColor Yellow
    $extensions = code --list-extensions
    $required = @("ms-dotnettools.csharp", "GitHub.copilot")
    
    foreach ($ext in $required) {
        if ($extensions -contains $ext) {
            Write-Host "✅ $ext installed" -ForegroundColor Green
        } else {
            Write-Host "⚠️  $ext not installed (optional)" -ForegroundColor Yellow
        }
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
if ($errors.Count -eq 0) {
    Write-Host "✅ All prerequisites satisfied!" -ForegroundColor Green
    Write-Host "You're ready to start Module 29!" -ForegroundColor Green
} else {
    Write-Host "❌ Prerequisites check failed:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    Write-Host "`nPlease install missing components before proceeding." -ForegroundColor Yellow
}
```

## 🏃 Quick Start

After installing all prerequisites:

```powershell
# 1. Clone or create project structure
git clone <your-repo> enterprise-architecture-mastery
cd enterprise-architecture-mastery

# 2. Run setup script
./infrastructure/scripts/setup-local-dev.ps1

# 3. Validate prerequisites
./validate-prerequisites.ps1

# 4. Restore packages
dotnet restore

# 5. Build solution
dotnet build

# 6. Run tests
dotnet test

# 7. Start development
code .  # or open in Visual Studio
```

## 📊 Resource Requirements

### Minimum System Requirements
- **CPU**: 8 cores (Intel i7/AMD Ryzen 7)
- **RAM**: 16GB (32GB recommended)
- **Storage**: 100GB free SSD space
- **OS**: Windows 11, macOS 12+, or Linux

### Cloud Resources (for exercises)
- **Azure Subscription**: Free tier acceptable for most exercises
- **Azure OpenAI**: Access required (apply if needed)
- **GitHub**: Account with Copilot subscription
- **Container Registry**: Azure ACR or Docker Hub

## 🚨 Common Setup Issues

### Issue: Docker Desktop not starting
```powershell
# Enable WSL2 (Windows)
wsl --install
wsl --set-default-version 2

# Enable Virtualization in BIOS
# Restart and check Hyper-V is enabled
```

### Issue: .NET SDK not recognized
```powershell
# Add to PATH manually
$env:PATH += ";C:\Program Files\dotnet"

# Or reinstall with:
winget uninstall Microsoft.DotNet.SDK.8
winget install Microsoft.DotNet.SDK.8
```

### Issue: NuGet package restore fails
```powershell
# Clear NuGet cache
dotnet nuget locals all --clear

# Update NuGet sources
dotnet nuget add source https://api.nuget.org/v3/index.json -n nuget.org
```

## 📚 Pre-Module Learning

Before starting, review:

1. **Clean Architecture**
   - [Microsoft Architecture Guide](https://docs.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/)
   - [Clean Architecture Template](https://github.com/jasontaylordev/CleanArchitecture)

2. **Domain-Driven Design**
   - [DDD with .NET](https://docs.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/)
   - [Implementing DDD](https://www.dddcommunity.org/library/vernon_2011/)

3. **Semantic Kernel**
   - [Official Documentation](https://learn.microsoft.com/en-us/semantic-kernel/)
   - [Samples Repository](https://github.com/microsoft/semantic-kernel)

## ✅ Pre-Module Checklist

Before starting the exercises:

- [ ] .NET 8 SDK installed and working
- [ ] Docker Desktop running
- [ ] Azure CLI configured
- [ ] Development IDE ready (VS 2022 or VS Code)
- [ ] All global tools installed
- [ ] Local services running (SQL, Redis, etc.)
- [ ] Solution structure created
- [ ] Base packages restored
- [ ] Validation script passes

## 🎯 Ready to Start?

Once all prerequisites are met:

1. Review the module [README](README.md)
2. Understand enterprise patterns
3. Start with [Exercise 1: Enterprise API Platform](exercises/exercise1-enterprise-api/)
4. Join the module discussion for help

---

**Note**: This module requires more setup than others due to its enterprise focus. Take time to properly configure your environment - it will save hours of troubleshooting later!