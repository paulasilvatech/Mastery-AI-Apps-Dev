# .NET Enterprise AI Agents Troubleshooting Guide

## 🔍 Overview

This guide helps diagnose and resolve common issues when building enterprise AI agents with .NET. Each issue includes symptoms, diagnostic steps, and solutions.

## 📋 Quick Diagnostics

### Diagnostic PowerShell Script
```powershell
# Quick health check for .NET AI Agent solution

Write-Host "🔍 Running .NET AI Agent Diagnostics..." -ForegroundColor Cyan

# Check .NET SDK
Write-Host "`n📦 .NET SDK Check:" -ForegroundColor Yellow
dotnet --list-sdks

# Check project dependencies
Write-Host "`n📚 NuGet Package Status:" -ForegroundColor Yellow
dotnet list package --outdated
dotnet list package --vulnerable

# Check database connection
Write-Host "`n💾 Database Connection:" -ForegroundColor Yellow
dotnet ef database-info

# Check Azure services
Write-Host "`n☁️ Azure Services:" -ForegroundColor Yellow
az account show
az cognitiveservices account list --output table

# Run tests
Write-Host "`n🧪 Running Tests:" -ForegroundColor Yellow
dotnet test --no-build --verbosity normal

Write-Host "`n✅ Diagnostics complete!" -ForegroundColor Green
```

## 🚨 Common Issues and Solutions

### 1. Build and Compilation Errors

#### Issue: Package Version Conflicts
**Symptoms:**
- Build errors mentioning version conflicts
- `NU1605` or `NU1608` warnings
- Assembly binding redirects needed

**Solution:**
```xml
<!-- Use Central Package Management in Directory.Packages.props -->
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>
  
  <ItemGroup>
    <PackageVersion Include="Microsoft.EntityFrameworkCore" Version="8.0.0" />
    <PackageVersion Include="Microsoft.EntityFrameworkCore.SqlServer" Version="8.0.0" />
    <!-- Ensure all related packages use same version -->
  </ItemGroup>
</Project>
```

**Fix conflicts:**
```powershell
# Clear NuGet cache
dotnet nuget locals all --clear

# Restore with locked mode
dotnet restore --locked-mode

# Update all packages to latest compatible versions
dotnet add package Microsoft.EntityFrameworkCore --version 8.0.0
```

#### Issue: Missing Method Exceptions at Runtime
**Symptoms:**
- `MissingMethodException` or `TypeLoadException`
- Works in development but fails in production

**Diagnostic:**
```powershell
# Check assembly versions
dotnet list package --include-transitive

# Publish and inspect output
dotnet publish -c Release -o ./publish
dir ./publish/*.dll | Select-Object Name, @{Name="Version";Expression={(Get-Item $_.FullName).VersionInfo.FileVersion}}
```

**Solution:**
```xml
<!-- Ensure consistent runtime versions -->
<PropertyGroup>
  <RuntimeFrameworkVersion>8.0.0</RuntimeFrameworkVersion>
  <PlatformTarget>x64</PlatformTarget>
  <PublishSingleFile>false</PublishSingleFile>
  <PublishTrimmed>false</PublishTrimmed>
</PropertyGroup>
```

### 2. Entity Framework Issues

#### Issue: Migration Failures
**Symptoms:**
- "No migrations configuration type was found"
- "Unable to create an object of type 'DbContext'"

**Solution:**
```csharp
// Create a design-time factory
public class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<ApplicationDbContext>
{
    public ApplicationDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<ApplicationDbContext>();
        
        // Use a default connection string for migrations
        optionsBuilder.UseSqlServer(
            "Server=(localdb)\\mssqllocaldb;Database=EnterpriseAgent;Trusted_Connection=True;");
        
        return new ApplicationDbContext(optionsBuilder.Options);
    }
}
```

**Generate migrations correctly:**
```powershell
# Specify startup project and context
dotnet ef migrations add InitialCreate `
  --project src/Infrastructure `
  --startup-project src/API `
  --context ApplicationDbContext `
  --output-dir Persistence/Migrations
```

#### Issue: Slow Queries
**Symptoms:**
- Timeout exceptions
- High database CPU usage
- Slow API responses

**Diagnostic:**
```csharp
// Enable query logging
protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
{
    optionsBuilder
        .LogTo(Console.WriteLine, LogLevel.Information)
        .EnableSensitiveDataLogging()
        .EnableDetailedErrors();
}
```

**Solution:**
```csharp
// Optimize queries
public async Task<List<Agent>> GetActiveAgentsOptimized()
{
    return await _context.Agents
        .AsNoTracking() // Don't track for read-only
        .Include(a => a.Tools) // Prevent N+1
        .Where(a => a.Status == AgentStatus.Active)
        .OrderBy(a => a.Name)
        .Take(100) // Always limit results
        .AsSplitQuery() // Split complex queries
        .ToListAsync();
}

// Add indexes
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    modelBuilder.Entity<Agent>()
        .HasIndex(a => a.Status)
        .HasFilter("[Status] = 1"); // Filtered index for active agents
        
    modelBuilder.Entity<Message>()
        .HasIndex(m => new { m.ConversationId, m.Timestamp });
}
```

### 3. Azure AI Services Issues

#### Issue: 401 Unauthorized
**Symptoms:**
- `AuthenticationFailedException`
- "401 (Unauthorized)" responses

**Diagnostic:**
```powershell
# Check Azure credentials
az account show
az cognitiveservices account keys list --name "your-resource" --resource-group "your-rg"

# Test endpoint directly
$headers = @{
    "api-key" = "your-key"
    "Content-Type" = "application/json"
}
$body = @{
    "messages" = @(
        @{
            "role" = "user"
            "content" = "Hello"
        }
    )
} | ConvertTo-Json

Invoke-RestMethod `
    -Uri "https://your-resource.openai.azure.com/openai/deployments/gpt-4/chat/completions?api-version=2023-12-01-preview" `
    -Method Post `
    -Headers $headers `
    -Body $body
```

**Solution:**
```csharp
// Proper configuration setup
public class AzureOpenAIService : IAIService
{
    private readonly OpenAIClient _client;
    private readonly ILogger<AzureOpenAIService> _logger;
    
    public AzureOpenAIService(IConfiguration configuration, ILogger<AzureOpenAIService> logger)
    {
        _logger = logger;
        
        var endpoint = configuration["AzureOpenAI:Endpoint"];
        var apiKey = configuration["AzureOpenAI:ApiKey"];
        
        if (string.IsNullOrEmpty(endpoint) || string.IsNullOrEmpty(apiKey))
        {
            throw new InvalidOperationException(
                "Azure OpenAI endpoint and API key must be configured. " +
                "Check your appsettings.json or user secrets.");
        }
        
        try
        {
            _client = new OpenAIClient(
                new Uri(endpoint),
                new AzureKeyCredential(apiKey)
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to initialize Azure OpenAI client");
            throw new InvalidOperationException("Failed to initialize AI service", ex);
        }
    }
}
```

#### Issue: Rate Limiting (429 Too Many Requests)
**Symptoms:**
- `RequestFailedException` with status code 429
- "Rate limit exceeded" errors

**Solution:**
```csharp
// Implement retry with exponential backoff
public class RateLimitedAIService : IAIService
{
    private readonly IAIService _innerService;
    private readonly IAsyncPolicy<ChatResponse> _retryPolicy;
    
    public RateLimitedAIService(IAIService innerService)
    {
        _innerService = innerService;
        
        _retryPolicy = Policy
            .HandleResult<ChatResponse>(r => r == null)
            .Or<RequestFailedException>(ex => ex.Status == 429)
            .WaitAndRetryAsync(
                retryCount: 5,
                sleepDurationProvider: retryAttempt => 
                {
                    var delay = TimeSpan.FromSeconds(Math.Pow(2, retryAttempt));
                    return delay;
                },
                onRetry: (outcome, timespan, retryCount, context) =>
                {
                    var logger = context.Values["logger"] as ILogger;
                    logger?.LogWarning(
                        "Rate limited. Retry {RetryCount} after {Delay}s",
                        retryCount,
                        timespan.TotalSeconds
                    );
                });
    }
    
    public async Task<ChatResponse> GetChatCompletionAsync(
        List<ChatMessage> messages,
        CancellationToken cancellationToken = default)
    {
        var context = new Context { ["logger"] = _logger };
        
        return await _retryPolicy.ExecuteAsync(
            async (ctx) => await _innerService.GetChatCompletionAsync(messages, cancellationToken),
            context
        );
    }
}
```

### 4. Memory and Performance Issues

#### Issue: High Memory Usage / Memory Leaks
**Symptoms:**
- `OutOfMemoryException`
- Constantly increasing memory usage
- Slow garbage collection

**Diagnostic:**
```csharp
// Add memory diagnostics
public class MemoryDiagnosticsMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<MemoryDiagnosticsMiddleware> _logger;
    
    public async Task InvokeAsync(HttpContext context)
    {
        var before = GC.GetTotalMemory(false);
        
        await _next(context);
        
        var after = GC.GetTotalMemory(false);
        var allocated = after - before;
        
        if (allocated > 10_000_000) // 10MB
        {
            _logger.LogWarning(
                "High memory allocation detected: {Bytes:N0} bytes for {Path}",
                allocated,
                context.Request.Path
            );
        }
    }
}
```

**Solution:**
```csharp
// Fix common memory leaks

// 1. Dispose HttpClient properly
public class AIService : IDisposable
{
    private readonly HttpClient _httpClient;
    
    public AIService(HttpClient httpClient) // Injected by IHttpClientFactory
    {
        _httpClient = httpClient;
    }
    
    // DON'T create new HttpClient instances
    // DON'T forget to dispose
}

// 2. Use streaming for large data
public async Task<IActionResult> DownloadLargeFile()
{
    var stream = await _fileService.GetFileStreamAsync();
    return File(stream, "application/octet-stream", "large-file.bin");
}

// 3. Clear collections when done
public class ConversationManager : IDisposable
{
    private readonly List<Message> _messages = new();
    
    public void Dispose()
    {
        _messages.Clear();
    }
}

// 4. Use object pooling for frequently created objects
public class MessageProcessor
{
    private readonly ObjectPool<StringBuilder> _stringBuilderPool;
    
    public string ProcessMessages(IEnumerable<Message> messages)
    {
        var sb = _stringBuilderPool.Get();
        try
        {
            foreach (var message in messages)
            {
                sb.AppendLine(message.Content);
            }
            return sb.ToString();
        }
        finally
        {
            _stringBuilderPool.Return(sb);
        }
    }
}
```

### 5. Dependency Injection Issues

#### Issue: Unable to Resolve Service
**Symptoms:**
- `InvalidOperationException: Unable to resolve service`
- "No service for type 'X' has been registered"

**Diagnostic:**
```csharp
// Debug service registration
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        // ... registrations ...
        
        // Debug: List all registered services
        #if DEBUG
        var serviceDescriptions = services
            .Where(s => s.ServiceType.Namespace?.StartsWith("EnterpriseAgent") == true)
            .Select(s => $"{s.ServiceType.Name} -> {s.ImplementationType?.Name} ({s.Lifetime})")
            .ToList();
            
        foreach (var description in serviceDescriptions)
        {
            Console.WriteLine(description);
        }
        #endif
    }
}
```

**Solution:**
```csharp
// Ensure proper registration order and lifetimes
public static class DependencyInjection
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        // Register in correct order (interfaces before implementations)
        services.AddScoped<IUnitOfWork, UnitOfWork>();
        services.AddScoped<IAgentRepository, AgentRepository>();
        
        // Use correct lifetimes
        services.AddSingleton<ICacheService, RedisCacheService>(); // Stateless
        services.AddScoped<IAgentService, AgentService>(); // Per request
        services.AddTransient<IValidator<CreateAgentCommand>, CreateAgentCommandValidator>(); // Lightweight
        
        // Register generic types
        services.AddScoped(typeof(IRepository<>), typeof(Repository<>));
        
        // Register with factory when needed
        services.AddScoped<IAIService>(provider =>
        {
            var config = provider.GetRequiredService<IConfiguration>();
            var logger = provider.GetRequiredService<ILogger<AzureOpenAIService>>();
            
            return new AzureOpenAIService(config, logger);
        });
        
        return services;
    }
}
```

#### Issue: Circular Dependencies
**Symptoms:**
- `StackOverflowException`
- "A circular dependency was detected"

**Solution:**
```csharp
// Break circular dependencies with interfaces and events

// Bad: Circular dependency
public class AgentService
{
    public AgentService(INotificationService notifications) { }
}

public class NotificationService
{
    public NotificationService(IAgentService agents) { } // Circular!
}

// Good: Use events
public class AgentService
{
    private readonly IEventBus _eventBus;
    
    public async Task CreateAgent()
    {
        // ... create agent ...
        await _eventBus.PublishAsync(new AgentCreatedEvent(agent.Id));
    }
}

public class NotificationService : IEventHandler<AgentCreatedEvent>
{
    public async Task Handle(AgentCreatedEvent evt)
    {
        // Send notification
    }
}
```

### 6. Async/Await Issues

#### Issue: Deadlocks
**Symptoms:**
- Application hangs
- Tasks never complete
- UI freezes (in desktop apps)

**Diagnostic:**
```csharp
// Detect potential deadlocks
public class DeadlockDetectionMiddleware
{
    public async Task InvokeAsync(HttpContext context)
    {
        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(30));
        
        try
        {
            await _next(context).WaitAsync(cts.Token);
        }
        catch (OperationCanceledException)
        {
            _logger.LogError(
                "Potential deadlock detected for {Path}",
                context.Request.Path
            );
            throw new TimeoutException("Request timeout - possible deadlock");
        }
    }
}
```

**Solution:**
```csharp
// Avoid common async pitfalls

// Bad: Blocking on async
public string GetData()
{
    return GetDataAsync().Result; // Can cause deadlock!
}

// Good: Async all the way
public async Task<string> GetDataAsync()
{
    return await _service.GetDataAsync();
}

// Bad: Not using ConfigureAwait
public async Task<string> GetCachedDataAsync()
{
    return await _cache.GetAsync("key"); // Can cause deadlock in certain contexts
}

// Good: Use ConfigureAwait(false) in libraries
public async Task<string> GetCachedDataAsync()
{
    return await _cache.GetAsync("key").ConfigureAwait(false);
}

// Bad: Async void
public async void ProcessMessage() // Can't catch exceptions!
{
    await _service.ProcessAsync();
}

// Good: Return Task
public async Task ProcessMessageAsync()
{
    await _service.ProcessAsync();
}
```

### 7. Multi-Modal Processing Issues

#### Issue: Large File Upload Failures
**Symptoms:**
- "Request body too large"
- Connection timeouts during upload
- Memory exceptions

**Solution:**
```csharp
// Configure large file support
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        // Configure form options
        services.Configure<FormOptions>(options =>
        {
            options.MultipartBodyLengthLimit = 104857600; // 100MB
            options.MemoryBufferThreshold = Int32.MaxValue;
        });
        
        // Configure Kestrel
        services.Configure<KestrelServerOptions>(options =>
        {
            options.Limits.MaxRequestBodySize = 104857600; // 100MB
            options.Limits.RequestHeadersTimeout = TimeSpan.FromMinutes(2);
        });
    }
}

// Stream large files
[DisableRequestSizeLimit]
[RequestFormLimits(MultipartBodyLengthLimit = 104857600)]
public async Task<IActionResult> UploadLargeFile(IFormFile file)
{
    using var stream = file.OpenReadStream();
    
    // Process in chunks
    var buffer = new byte[4096];
    int bytesRead;
    
    while ((bytesRead = await stream.ReadAsync(buffer, 0, buffer.Length)) > 0)
    {
        await ProcessChunkAsync(buffer, bytesRead);
    }
    
    return Ok();
}
```

### 8. Security and Authentication Issues

#### Issue: CORS Errors
**Symptoms:**
- "Access-Control-Allow-Origin" errors
- Preflight request failures

**Solution:**
```csharp
// Configure CORS properly
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddCors(options =>
        {
            options.AddPolicy("AllowSpecificOrigins", policy =>
            {
                policy.WithOrigins(
                        "https://localhost:3000",
                        "https://app.example.com"
                    )
                    .AllowAnyHeader()
                    .AllowAnyMethod()
                    .AllowCredentials()
                    .SetPreflightMaxAge(TimeSpan.FromMinutes(10));
            });
        });
    }
    
    public void Configure(IApplicationBuilder app)
    {
        app.UseCors("AllowSpecificOrigins");
        // Must be before UseAuthentication
    }
}
```

#### Issue: JWT Token Validation Failures
**Symptoms:**
- 401 Unauthorized despite valid token
- "IDX10223: Lifetime validation failed"

**Solution:**
```csharp
// Configure JWT properly
services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = configuration["AzureAd:Authority"];
        options.Audience = configuration["AzureAd:Audience"];
        
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ClockSkew = TimeSpan.FromMinutes(5), // Allow clock skew
            NameClaimType = "name",
            RoleClaimType = "roles"
        };
        
        // Debug token issues
        options.Events = new JwtBearerEvents
        {
            OnAuthenticationFailed = context =>
            {
                var logger = context.HttpContext.RequestServices
                    .GetRequiredService<ILogger<Startup>>();
                    
                logger.LogError(
                    context.Exception,
                    "Authentication failed: {Error}",
                    context.Exception.Message
                );
                
                return Task.CompletedTask;
            }
        };
    });
```

## 🛠️ Diagnostic Tools

### Application Insights Integration
```csharp
// Add detailed telemetry
public class TelemetryInitializer : ITelemetryInitializer
{
    public void Initialize(ITelemetry telemetry)
    {
        if (telemetry is RequestTelemetry request)
        {
            request.Properties["Environment"] = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT");
            request.Properties["Version"] = Assembly.GetExecutingAssembly().GetName().Version?.ToString();
        }
    }
}

// Track custom events
public class AgentService
{
    private readonly TelemetryClient _telemetryClient;
    
    public async Task ProcessMessageAsync(string message)
    {
        using var operation = _telemetryClient.StartOperation<RequestTelemetry>("ProcessMessage");
        
        try
        {
            // Process...
            
            _telemetryClient.TrackEvent("MessageProcessed", new Dictionary<string, string>
            {
                ["MessageLength"] = message.Length.ToString(),
                ["AgentId"] = _agentId.ToString()
            });
        }
        catch (Exception ex)
        {
            _telemetryClient.TrackException(ex);
            operation.Telemetry.Success = false;
            throw;
        }
    }
}
```

### Health Check Dashboard
```csharp
// Comprehensive health checks
public class Startup
{
    public void ConfigureServices(IServiceCollection services)
    {
        services.AddHealthChecks()
            .AddCheck("self", () => HealthCheckResult.Healthy())
            .AddDbContextCheck<ApplicationDbContext>(
                name: "database",
                failureStatus: HealthStatus.Unhealthy,
                tags: new[] { "db", "sql" })
            .AddCheck<AzureOpenAIHealthCheck>("azure-openai")
            .AddCheck<RedisHealthCheck>("redis")
            .AddCheck<BlobStorageHealthCheck>("blob-storage");
            
        services.AddHealthChecksUI()
            .AddInMemoryStorage();
    }
}
```

## 📊 Performance Profiling

### MiniProfiler Setup
```csharp
// Add profiling
services.AddMiniProfiler(options =>
{
    options.RouteBasePath = "/profiler";
    options.ColorScheme = StackExchange.Profiling.ColorScheme.Dark;
}).AddEntityFramework();

// Profile specific code
public async Task<List<Agent>> GetAgentsAsync()
{
    using (MiniProfiler.Current.Step("GetAgents"))
    {
        using (MiniProfiler.Current.Step("Database Query"))
        {
            return await _context.Agents.ToListAsync();
        }
    }
}
```

## 🔧 Emergency Procedures

### Database Connection Recovery
```powershell
# Reset connection pool
dotnet run --ConnectionStrings:DefaultConnection="Server=...;Connection Timeout=30;Connection Lifetime=0;"

# Force migration
dotnet ef database update --force

# Create new migration from scratch
dotnet ef database drop --force
dotnet ef migrations remove
dotnet ef migrations add Initial
dotnet ef database update
```

### Clear All Caches
```csharp
public class CacheController : ControllerBase
{
    [HttpPost("clear-all")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ClearAllCaches()
    {
        // Clear memory cache
        if (_memoryCache is MemoryCache memCache)
        {
            memCache.Clear();
        }
        
        // Clear distributed cache
        await _distributedCache.RemoveAsync("*");
        
        // Clear specific caches
        var cacheKeys = new[] { "agents", "conversations", "users" };
        foreach (var key in cacheKeys)
        {
            await _distributedCache.RemoveAsync(key);
        }
        
        return Ok("All caches cleared");
    }
}
```

## 📚 Additional Resources

- [.NET Troubleshooting Guide](https://docs.microsoft.com/troubleshoot/dotnet/)
- [Entity Framework Core Troubleshooting](https://docs.microsoft.com/ef/core/miscellaneous/logging)
- [Azure AI Services Troubleshooting](https://docs.microsoft.com/azure/cognitive-services/openai/troubleshooting)
- [Performance Diagnostics](https://docs.microsoft.com/dotnet/core/diagnostics/)

---

**Remember**: When troubleshooting, always:
1. Check logs first
2. Reproduce in a controlled environment
3. Use proper diagnostic tools
4. Document the solution
5. Add tests to prevent recurrence