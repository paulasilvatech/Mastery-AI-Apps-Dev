---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 26"
---

# Prerrequisitos for Módulo 26: .NET Empresarial AI Agents

## 🎯 Required Knowledge

Before starting this module, ensure you have:

### From Anterior Módulos
- ✅ **Módulos 21-25**: Completar AI Agents & MCP track
- ✅ **Agent Fundamentos**: Understanding of AI agent concepts
- ✅ **Production Deployment**: Experience with containerization and Kubernetes
- ✅ **Monitoring & Observability**: Familiarity with metrics and tracing

### .NET desarrollo Skills
- ✅ **C# Proficiency**: Strong knowledge of C# 10+ features
- ✅ **ASP.NET Core**: Web API desarrollo experience
- ✅ **Entity Framework Core**: ORM and data access patterns
- ✅ **Dependency Injection**: IoC container usage
- ✅ **Async Programming**: Task-based asynchronous patterns

### Empresarial Patterns
- ✅ **Design Patterns**: Factory, Repository, Unit of Work
- ✅ **SOLID Principles**: Single Responsibility, Abrir/Cerrard, etc.
- ✅ **Clean Architecture**: Layer separation and dependencies
- ✅ **Domain-Driven Design**: Basic understanding of DDD concepts
- ✅ **CQRS**: Command Query Responsibility Segregation basics

## 🛠️ Required Software

### desarrollo ambiente

#### .NET SDK and Runtime
```powershell
# Check .NET version (must be 8.0 or higher)
dotnet --version

# Install .NET 8 SDK if needed
# Windows (using winget)
winget install Microsoft.DotNet.SDK.8

# macOS
brew install --cask dotnet-sdk

# Linux (Ubuntu)
wget https://dot.net/v1/dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --version 8.0
```

#### IDE Options
1. **Visual Studio 2022** (Recommended for Windows)
   - Community Editarion (free) is sufficient
   - Required workloads:
     - ASP.NET and web desarrollo
     - Azure desarrollo
     - .NET desktop desarrollo

2. **Visual Studio Code** (Cross-platform)
   ```bash
   # Install VS Code
   # Then install extensions:
   code --install-extension ms-dotnettools.csharp
   code --install-extension ms-dotnettools.vscode-dotnet-runtime
   code --install-extension ms-azuretools.vscode-docker
   code --install-extension ms-vscode.azurecli
   code --install-extension ms-azuretools.vscode-azurefunctions
   ```

3. **JetBrains Rider** (Cross-platform, paid)

### Azure Tools
```powershell
# Azure CLI
# Windows
winget install Microsoft.AzureCLI

# macOS
brew install azure-cli

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verify installation
az --version

# Login to Azure
az login

# Azure Functions Core Tools
npm install -g azure-functions-core-tools@4

# Storage Emulator (Windows) or Azurite (Cross-platform)
npm install -g azurite
```

### Database Tools
```powershell
# SQL Server Developer Edition (Windows/Linux)
# Download from: https://www.microsoft.com/sql-server/sql-server-downloads

# OR use Docker
docker pull mcr.microsoft.com/mssql/server:2022-latest

# Run SQL Server in Docker
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=YourStrong@Passw0rd" \
  -p 1433:1433 --name sql2022 --hostname sql2022 \
  -d mcr.microsoft.com/mssql/server:2022-latest

# Azure Data Studio (recommended GUI)
# Download from: https://azure.microsoft.com/products/data-studio/

# Entity Framework Core tools
dotnet tool install --global dotnet-ef
```

### Additional Tools
```powershell
# Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop/

# Redis (for caching)
docker pull redis:alpine
docker run --name redis -p 6379:6379 -d redis:alpine

# RabbitMQ or Azure Service Bus Emulator
docker pull rabbitmq:3-management-alpine
docker run -d --hostname rabbitmq --name rabbitmq \
  -p 15672:15672 -p 5672:5672 \
  rabbitmq:3-management-alpine

# Seq (for structured logging)
docker pull datalust/seq
docker run --name seq -e ACCEPT_EULA=Y \
  -p 5341:5341 -p 80:80 \
  -d datalust/seq
```

## 🏗️ Project Setup

### 1. Create Solution Structure
```powershell
# Create solution directory
mkdir EnterpriseAgentSolution
cd EnterpriseAgentSolution

# Create solution file
dotnet new sln -n EnterpriseAgent

# Create projects
dotnet new classlib -n EnterpriseAgent.Domain -f net8.0
dotnet new classlib -n EnterpriseAgent.Application -f net8.0
dotnet new classlib -n EnterpriseAgent.Infrastructure -f net8.0
dotnet new webapi -n EnterpriseAgent.API -f net8.0
dotnet new xunit -n EnterpriseAgent.Tests -f net8.0

# Add projects to solution
dotnet sln add **/*.csproj

# Create project references
dotnet add EnterpriseAgent.Application/EnterpriseAgent.Application.csproj reference EnterpriseAgent.Domain/EnterpriseAgent.Domain.csproj
dotnet add EnterpriseAgent.Infrastructure/EnterpriseAgent.Infrastructure.csproj reference EnterpriseAgent.Application/EnterpriseAgent.Application.csproj
dotnet add EnterpriseAgent.API/EnterpriseAgent.API.csproj reference EnterpriseAgent.Application/EnterpriseAgent.Application.csproj
dotnet add EnterpriseAgent.API/EnterpriseAgent.API.csproj reference EnterpriseAgent.Infrastructure/EnterpriseAgent.Infrastructure.csproj
dotnet add EnterpriseAgent.Tests/EnterpriseAgent.Tests.csproj reference EnterpriseAgent.Domain/EnterpriseAgent.Domain.csproj
dotnet add EnterpriseAgent.Tests/EnterpriseAgent.Tests.csproj reference EnterpriseAgent.Application/EnterpriseAgent.Application.csproj
```

### 2. Install Required NuGet Packages

Create `Directory.Packages.props` in solution root:
```xml
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>
  
  <ItemGroup>
    &lt;!-- Microsoft AI/ML --&gt;
    <PackageVersion Include="Microsoft.SemanticKernel" Version="1.0.1" />
    <PackageVersion Include="Azure.AI.OpenAI" Version="1.0.0-beta.12" />
    <PackageVersion Include="Microsoft.Azure.CognitiveServices.Vision.ComputerVision" Version="7.0.1" />
    
    <!-- Application Framework -->
    <PackageVersion Include="MediatR" Version="12.2.0" />
    <PackageVersion Include="FluentValidation.AspNetCore" Version="11.3.0" />
    <PackageVersion Include="AutoMapper.Extensions.Microsoft.DependencyInjection" Version="12.0.1" />
    
    <!-- Data Access -->
    <PackageVersion Include="Microsoft.EntityFrameworkCore.SqlServer" Version="8.0.0" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.Tools" Version="8.0.0" />
    <PackageVersion Include="Dapper" Version="2.1.24" />
    
    <!-- Caching -->
    <PackageVersion Include="Microsoft.Extensions.Caching.StackExchangeRedis" Version="8.0.0" />
    <PackageVersion Include="EasyCaching.InMemory" Version="1.9.2" />
    
    <!-- Messaging -->
    <PackageVersion Include="Azure.Messaging.ServiceBus" Version="7.17.1" />
    <PackageVersion Include="MassTransit.Azure.ServiceBus.Core" Version="8.1.3" />
    
    <!-- Resilience -->
    <PackageVersion Include="Polly" Version="8.2.0" />
    <PackageVersion Include="Microsoft.Extensions.Http.Polly" Version="8.0.0" />
    
    <!-- Logging & Monitoring -->
    <PackageVersion Include="Serilog.AspNetCore" Version="8.0.0" />
    <PackageVersion Include="Serilog.Sinks.Seq" Version="6.0.0" />
    <PackageVersion Include="OpenTelemetry.Exporter.Prometheus.AspNetCore" Version="1.7.0-rc.1" />
    <PackageVersion Include="OpenTelemetry.Instrumentation.AspNetCore" Version="1.7.0" />
    
    <!-- Security -->
    <PackageVersion Include="Microsoft.Identity.Web" Version="2.16.0" />
    <PackageVersion Include="Azure.Security.KeyVault.Secrets" Version="4.5.0" />
    
    <!-- Testing -->
    <PackageVersion Include="xunit" Version="2.6.5" />
    <PackageVersion Include="xunit.runner.visualstudio" Version="2.5.6" />
    <PackageVersion Include="Moq" Version="4.20.70" />
    <PackageVersion Include="FluentAssertions" Version="6.12.0" />
    <PackageVersion Include="Microsoft.AspNetCore.Mvc.Testing" Version="8.0.0" />
    <PackageVersion Include="Testcontainers" Version="3.7.0" />
  </ItemGroup>
</Project>
```

### 3. Configure User Secrets
```powershell
# Initialize user secrets for API project
cd EnterpriseAgent.API
dotnet user-secrets init

# Add Azure OpenAI configuration
dotnet user-secrets set "AzureOpenAI:Endpoint" "https://your-resource.openai.azure.com/"
dotnet user-secrets set "AzureOpenAI:ApiKey" "your-api-key"
dotnet user-secrets set "AzureOpenAI:DeploymentName" "gpt-4"

# Add Azure Service Bus connection
dotnet user-secrets set "ServiceBus:ConnectionString" "your-connection-string"

# Add SQL Server connection
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=localhost;Database=EnterpriseAgent;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=true"
```

## 🔧 ambiente Configuration

### 1. Azure Recursos Setup
```bash
# Set variables
RESOURCE_GROUP="rg-enterprise-agents"
LOCATION="eastus"
UNIQUE_ID=$RANDOM

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Azure OpenAI resource
az cognitiveservices account create \
  --name "openai-agents-$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP \
  --kind OpenAI \
  --sku S0 \
  --location $LOCATION

# Deploy GPT-4 model
az cognitiveservices account deployment create \
  --name "openai-agents-$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP \
  --deployment-name gpt-4 \
  --model-name gpt-4 \
  --model-version "0613" \
  --model-format OpenAI \
  --scale-settings-scale-type "Standard"

# Create Service Bus namespace
az servicebus namespace create \
  --name "sb-agents-$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard

# Create Application Insights
az monitor app-insights component create \
  --app "ai-agents-$UNIQUE_ID" \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP \
  --application-type web

# Create Key Vault
az keyvault create \
  --name "kv-agents-$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION
```

### 2. Local desarrollo Configuraciones

Create `appsettings.Development.json`:
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=EnterpriseAgent;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=true",
    "Redis": "localhost:6379"
  },
  "AzureOpenAI": {
    "Endpoint": "https://your-resource.openai.azure.com/",
    "ApiKey": "your-api-key",
    "DeploymentName": "gpt-4"
  },
  "ServiceBus": {
    "ConnectionString": "Endpoint=sb://localhost:5672;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=test"
  },
  "ApplicationInsights": {
    "ConnectionString": "InstrumentationKey=00000000-0000-0000-0000-000000000000"
  },
  "SemanticKernel": {
    "DefaultModel": "gpt-4",
    "MaxTokens": 4096,
    "Temperature": 0.7
  }
}
```

## 🧪 Validation Script

Create `scripts/validate-prerequisites.ps1`:
```powershell
Write-Host "🔍 Validating Module 26 Prerequisites..." -ForegroundColor Cyan

# Check .NET SDK
Write-Host "`n📦 Checking .NET SDK..." -ForegroundColor Yellow
$dotnetVersion = dotnet --version
if ($dotnetVersion -match "^8\.\d+\.\d+$") {
    Write-Host "✅ .NET SDK $dotnetVersion installed" -ForegroundColor Green
} else {
    Write-Host "❌ .NET 8 SDK required. Found: $dotnetVersion" -ForegroundColor Red
}

# Check EF Core tools
Write-Host "`n🛠️ Checking Entity Framework Core tools..." -ForegroundColor Yellow
try {
    $efVersion = dotnet ef --version
    Write-Host "✅ EF Core tools $efVersion installed" -ForegroundColor Green
} catch {
    Write-Host "❌ EF Core tools not installed. Run: dotnet tool install --global dotnet-ef" -ForegroundColor Red
}

# Check Azure CLI
Write-Host "`n☁️ Checking Azure CLI..." -ForegroundColor Yellow
try {
    $azVersion = az version --query '"azure-cli"' -o tsv
    Write-Host "✅ Azure CLI $azVersion installed" -ForegroundColor Green
    
    # Check if logged in
    $account = az account show --query name -o tsv 2>$null
    if ($account) {
        Write-Host "✅ Logged in to Azure account: $account" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Not logged in to Azure. Run: az login" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Azure CLI not installed" -ForegroundColor Red
}

# Check Docker
Write-Host "`n🐳 Checking Docker..." -ForegroundColor Yellow
try {
    docker version --format '{{.Server.Version}}' | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running" -ForegroundColor Red
}

# Check SQL Server
Write-Host "`n💾 Checking SQL Server..." -ForegroundColor Yellow
$sqlRunning = docker ps --filter "name=sql2022" --format "table {{.Names}}" | Select-String "sql2022"
if ($sqlRunning) {
    Write-Host "✅ SQL Server container is running" -ForegroundColor Green
} else {
    Write-Host "⚠️ SQL Server not running. Start with provided docker command" -ForegroundColor Yellow
}

# Check Redis
Write-Host "`n📦 Checking Redis..." -ForegroundColor Yellow
$redisRunning = docker ps --filter "name=redis" --format "table {{.Names}}" | Select-String "redis"
if ($redisRunning) {
    Write-Host "✅ Redis container is running" -ForegroundColor Green
} else {
    Write-Host "⚠️ Redis not running. Start with provided docker command" -ForegroundColor Yellow
}

Write-Host "`n✅ Prerequisites check complete!" -ForegroundColor Green
```

## 📊 Resource Requirements

### Minimum System Requirements
- **CPU**: 4 cores (8 recommended for Visual Studio)
- **RAM**: 8GB (16GB recommended)
- **Storage**: 20GB free space
- **OS**: Windows 10/11, macOS 12+, or Linux (Ubuntu 20.04+)

### Azure Recursos (Free Tier Compatible)
- Azure AbrirAI or AbrirAI API access
- Azure Service Bus (Basic tier)
- Application Insights
- Key Vault (Standard tier)
- Optional: Azure SQL Database

## 🚨 Common Setup Issues

### Issue: NuGet Package Restore Fails
```powershell
# Clear NuGet cache
dotnet nuget locals all --clear

# Restore packages
dotnet restore --force
```

### Issue: SQL Server Connection Failed
```powershell
# Check SQL Server is running
docker ps | Select-String sql

# Test connection
docker exec sql2022 /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P 'YourStrong@Passw0rd' \
  -Q "SELECT @@VERSION"
```

### Issue: Azure AbrirAI Access Denied
```bash
# Check resource exists
az cognitiveservices account show \
  --name "openai-agents-$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP

# Get API key
az cognitiveservices account keys list \
  --name "openai-agents-$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP
```

## 📚 Pre-Módulo Learning

Before starting, review:

1. **C# Avanzado Features**
   - [Async/Await Mejores Prácticas](https://docs.microsoft.com/dotnet/csharp/async)
   - [Pattern Matching](https://docs.microsoft.com/dotnet/csharp/fundamentals/functional/pattern-matching)
   - [Records and Init-Only Properties](https://docs.microsoft.com/dotnet/csharp/whats-new/csharp-9#records)

2. **Empresarial Patterns**
   - [Clean Architecture](https://github.com/ardalis/CleanArchitecture)
   - [DDD Fundamentos](https://docs.microsoft.com/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/)
   - [CQRS Pattern](https://docs.microsoft.com/azure/architecture/patterns/cqrs)

3. **Azure AI Services**
   - [Azure AbrirAI Documentación](https://learn.microsoft.com/azure/ai-services/openai/)
   - [Semantic Kernel Resumen](https://learn.microsoft.com/semantic-kernel/overview/)

## ✅ Pre-Módulo Verificarlist

Before starting the exercises, ensure:

- [ ] .NET 8 SDK instalado and working
- [ ] Visual Studio 2022 or VS Code with C# extensions
- [ ] Docker Desktop running
- [ ] SQL Server and Redis containers started
- [ ] Azure CLI instalado and logged in
- [ ] Solution structure created
- [ ] NuGet packages restored
- [ ] User secrets configurado
- [ ] Validation script passes

## 🎯 Ready to Start?

Once all prerequisites are met:

1. Revisar the [Empresarial Architecture](README.md#-enterprise-architecture)
2. Understand Clean Architecture principles
3. Comience con [Ejercicio 1: Empresarial Agent Framework](./exercise1-overview)
4. Join the module discussion for help

---

**Need Help?** Check the [Module 26 Troubleshooting Guide](/docs/guias/troubleshooting) or post in the module discussions.