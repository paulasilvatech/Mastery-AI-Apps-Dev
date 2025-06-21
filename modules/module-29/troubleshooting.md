# Enterprise .NET Troubleshooting Guide

## 🔍 Overview

This comprehensive guide helps diagnose and resolve common issues when building enterprise .NET applications. Each issue includes symptoms, root causes, diagnostic steps, and proven solutions.

## 📋 Quick Diagnostics

### System Health Check Script
```powershell
# Enterprise .NET System Health Check
Write-Host "🔍 Running Enterprise .NET Diagnostics..." -ForegroundColor Cyan

# Check .NET SDK
$dotnetInfo = dotnet --info
Write-Host "`n🎯 .NET Environment:" -ForegroundColor Yellow
Write-Host $dotnetInfo

# Check running services
Write-Host "`n🐳 Docker Services:" -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check database connectivity
Write-Host "`n💾 Database Connection:" -ForegroundColor Yellow
try {
    $connectionString = "Server=localhost,1433;Database=master;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True"
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    Write-Host "✅ SQL Server connected" -ForegroundColor Green
    $connection.Close()
} catch {
    Write-Host "❌ SQL Server connection failed: $_" -ForegroundColor Red
}

# Check Redis
Write-Host "`n📦 Redis Connection:" -ForegroundColor Yellow
try {
    $redisTest = docker exec redis redis-cli ping
    if ($redisTest -eq "PONG") {
        Write-Host "✅ Redis connected" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Redis connection failed" -ForegroundColor Red
}

# Check API health
Write-Host "`n🌐 API Health:" -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:5000/health" -Method Get
    Write-Host "✅ API is healthy" -ForegroundColor Green
} catch {
    Write-Host "❌ API health check failed" -ForegroundColor Red
}

Write-Host "`n✅ Diagnostics complete!" -ForegroundColor Cyan
```

## 🚨 Common Issues and Solutions

### 1. Build and Compilation Errors

#### Issue: Package Version Conflicts
**Symptoms:**
```
error NU1605: Detected package downgrade
error CS0433: The type exists in both assemblies
```

**Solution:**
```xml
<!-- In Directory.Build.props - Centralize package versions -->
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>
</Project>

<!-- In Directory.Packages.props -->
<Project>
  <ItemGroup>
    <PackageVersion Include="Microsoft.EntityFrameworkCore" Version="8.0.1" />
    <PackageVersion Include="Microsoft.Extensions.DependencyInjection" Version="8.0.0" />
    <PackageVersion Include="Newtonsoft.Json" Version="13.0.3" />
  </ItemGroup>
</Project>
```

Clear and rebuild:
```bash
dotnet clean
dotnet restore
dotnet build --no-restore
```

#### Issue: Nullable Reference Types Warnings
**Symptoms:**
```
warning CS8618: Non-nullable property must contain a non-null value
warning CS8625: Cannot convert null literal to non-nullable reference type
```

**Solution:**
```csharp
// Option 1: Initialize in constructor
public class Order
{
    public string OrderNumber { get; set; }
    public Customer Customer { get; set; }
    
    public Order()
    {
        OrderNumber = string.Empty;
        Customer = new Customer();
    }
}

// Option 2: Use nullable reference types properly
public class Order
{
    public string OrderNumber { get; set; } = null!; // Not null after initialization
    public Customer? Customer { get; set; } // Explicitly nullable
    
    // Initialize in factory method
    public static Order Create(string orderNumber)
    {
        return new Order { OrderNumber = orderNumber };
    }
}

// Option 3: Disable for specific properties
#pragma warning disable CS8618
    public string LegacyProperty { get; set; }
#pragma warning restore CS8618
```

### 2. Entity Framework Core Issues

#### Issue: Migration Fails
**Symptoms:**
```
The migration '20240120123456_InitialCreate' has already been applied to the database
Unable to create an object of type 'ApplicationDbContext'
```

**Solution:**
```bash
# Reset migrations (development only!)
dotnet ef database drop -f
dotnet ef migrations remove
dotnet ef migrations add InitialCreate
dotnet ef database update

# For specific DbContext
dotnet ef migrations add InitialCreate -c ApplicationDbContext -p Infrastructure -s API

# Fix design-time DbContext creation
```

Create `DesignTimeDbContextFactory.cs`:
```csharp
public class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<ApplicationDbContext>
{
    public ApplicationDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<ApplicationDbContext>();
        
        // Read from appsettings.json
        IConfigurationRoot configuration = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json")
            .AddJsonFile("appsettings.Development.json", optional: true)
            .Build();
            
        var connectionString = configuration.GetConnectionString("DefaultConnection");
        optionsBuilder.UseSqlServer(connectionString);
        
        return new ApplicationDbContext(optionsBuilder.Options);
    }
}
```

#### Issue: Lazy Loading Causing N+1 Queries
**Symptoms:**
- Slow API responses
- Multiple database queries in logs
- High database CPU usage

**Solution:**
```csharp
// Disable lazy loading globally
protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
{
    optionsBuilder
        .UseSqlServer(connectionString)
        .UseLazyLoadingProxies(false); // Explicitly disable
}

// Use eager loading with Include
public async Task<Order> GetOrderWithDetailsAsync(Guid orderId)
{
    return await _context.Orders
        .Include(o => o.Customer)
        .Include(o => o.Items)
            .ThenInclude(i => i.Product)
        .AsSplitQuery() // Use split queries for multiple includes
        .FirstOrDefaultAsync(o => o.Id == orderId);
}

// Use projection for read-only scenarios
public async Task<OrderDto> GetOrderSummaryAsync(Guid orderId)
{
    return await _context.Orders
        .Where(o => o.Id == orderId)
        .Select(o => new OrderDto
        {
            Id = o.Id,
            CustomerName = o.Customer.Name,
            ItemCount = o.Items.Count(),
            TotalAmount = o.Items.Sum(i => i.Quantity * i.UnitPrice)
        })
        .FirstOrDefaultAsync();
}
```

### 3. Dependency Injection Issues

#### Issue: Service Resolution Failures
**Symptoms:**
```
InvalidOperationException: Unable to resolve service for type
Cannot consume scoped service from singleton
```

**Solution:**
```csharp
// Check service lifetimes
public class ServiceDiagnostics
{
    public static void ValidateServiceLifetimes(IServiceCollection services)
    {
        var serviceProvider = services.BuildServiceProvider();
        var scopedInSingleton = new List<string>();
        
        foreach (var service in services.Where(s => s.Lifetime == ServiceLifetime.Singleton))
        {
            var implementation = service.ImplementationType ?? service.ImplementationInstance?.GetType();
            if (implementation == null) continue;
            
            var constructor = implementation.GetConstructors().FirstOrDefault();
            if (constructor == null) continue;
            
            foreach (var parameter in constructor.GetParameters())
            {
                var paramService = services.FirstOrDefault(s => s.ServiceType == parameter.ParameterType);
                if (paramService?.Lifetime == ServiceLifetime.Scoped)
                {
                    scopedInSingleton.Add($"{implementation.Name} depends on scoped {parameter.ParameterType.Name}");
                }
            }
        }
        
        if (scopedInSingleton.Any())
        {
            throw new InvalidOperationException($"Scoped services in singleton detected:\n{string.Join("\n", scopedInSingleton)}");
        }
    }
}

// Fix: Use IServiceScopeFactory for scoped dependencies in singletons
public class MySingletonService
{
    private readonly IServiceScopeFactory _scopeFactory;
    
    public MySingletonService(IServiceScopeFactory scopeFactory)
    {
        _scopeFactory = scopeFactory;
    }
    
    public async Task DoWorkAsync()
    {
        using var scope = _scopeFactory.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        
        // Use dbContext within scope
        await dbContext.SaveChangesAsync();
    }
}
```

#### Issue: Circular Dependencies
**Symptoms:**
```
A circular dependency was detected for the service
```

**Solution:**
```csharp
// Break circular dependency with lazy resolution
public interface IServiceA
{
    void DoWork();
}

public interface IServiceB
{
    void Process();
}

// Bad: Circular dependency
public class ServiceA : IServiceA
{
    private readonly IServiceB _serviceB;
    public ServiceA(IServiceB serviceB) => _serviceB = serviceB;
}

public class ServiceB : IServiceB
{
    private readonly IServiceA _serviceA;
    public ServiceB(IServiceA serviceA) => _serviceA = serviceA;
}

// Good: Use Lazy<T> or IServiceProvider
public class ServiceA : IServiceA
{
    private readonly Lazy<IServiceB> _serviceB;
    
    public ServiceA(IServiceProvider serviceProvider)
    {
        _serviceB = new Lazy<IServiceB>(() => serviceProvider.GetRequiredService<IServiceB>());
    }
    
    public void DoWork()
    {
        _serviceB.Value.Process();
    }
}

// Better: Refactor to eliminate circular dependency
public interface IEventBus
{
    void Publish<T>(T @event);
}

public class ServiceA : IServiceA
{
    private readonly IEventBus _eventBus;
    
    public ServiceA(IEventBus eventBus) => _eventBus = eventBus;
    
    public void DoWork()
    {
        // Publish event instead of direct dependency
        _eventBus.Publish(new WorkCompletedEvent());
    }
}
```

### 4. Performance Issues

#### Issue: Slow API Response Times
**Symptoms:**
- Response times > 1 second
- High CPU or memory usage
- Database connection pool exhaustion

**Diagnosis:**
```csharp
// Add performance logging
public class PerformanceLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<PerformanceLoggingMiddleware> _logger;
    
    public async Task InvokeAsync(HttpContext context)
    {
        var stopwatch = Stopwatch.StartNew();
        
        try
        {
            await _next(context);
        }
        finally
        {
            stopwatch.Stop();
            
            if (stopwatch.ElapsedMilliseconds > 500)
            {
                _logger.LogWarning(
                    "Slow request: {Method} {Path} took {ElapsedMilliseconds}ms",
                    context.Request.Method,
                    context.Request.Path,
                    stopwatch.ElapsedMilliseconds);
            }
        }
    }
}

// Add profiling
services.AddMiniProfiler(options =>
{
    options.RouteBasePath = "/profiler";
    options.ColorScheme = StackExchange.Profiling.ColorScheme.Dark;
}).AddEntityFramework();
```

**Solution:**
```csharp
// 1. Optimize database queries
public async Task<List<OrderSummaryDto>> GetOrderSummariesAsync()
{
    // Bad: Loading entire entities
    var orders = await _context.Orders
        .Include(o => o.Customer)
        .Include(o => o.Items)
        .ToListAsync();
    
    return orders.Select(o => new OrderSummaryDto { /* mapping */ }).ToList();
    
    // Good: Project only needed data
    return await _context.Orders
        .Select(o => new OrderSummaryDto
        {
            Id = o.Id,
            CustomerName = o.Customer.Name,
            TotalAmount = o.Items.Sum(i => i.Quantity * i.UnitPrice),
            ItemCount = o.Items.Count()
        })
        .ToListAsync();
}

// 2. Implement caching
public class CachedOrderService
{
    private readonly IMemoryCache _cache;
    private readonly IOrderRepository _repository;
    
    public async Task<Order> GetOrderAsync(Guid id)
    {
        return await _cache.GetOrCreateAsync($"order_{id}", async entry =>
        {
            entry.SlidingExpiration = TimeSpan.FromMinutes(5);
            entry.Priority = CacheItemPriority.Normal;
            
            return await _repository.GetByIdAsync(id);
        });
    }
}

// 3. Use async operations properly
public async Task<IActionResult> ProcessOrdersAsync()
{
    // Bad: Blocking async calls
    var orders = GetOrdersAsync().Result;
    
    // Good: Async all the way
    var orders = await GetOrdersAsync();
    
    // Process in parallel when appropriate
    var tasks = orders.Select(order => ProcessOrderAsync(order));
    await Task.WhenAll(tasks);
    
    return Ok();
}
```

### 5. Authentication & Authorization Issues

#### Issue: JWT Token Validation Fails
**Symptoms:**
```
401 Unauthorized
Bearer error="invalid_token"
IDX10223: Lifetime validation failed
```

**Solution:**
```csharp
// Configure JWT properly
services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = configuration["Jwt:Issuer"],
            ValidAudience = configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(configuration["Jwt:Key"])),
            ClockSkew = TimeSpan.FromMinutes(5) // Allow 5 minutes clock skew
        };
        
        // Add detailed error handling
        options.Events = new JwtBearerEvents
        {
            OnAuthenticationFailed = context =>
            {
                var logger = context.HttpContext.RequestServices
                    .GetRequiredService<ILogger<Program>>();
                    
                logger.LogError(context.Exception, 
                    "Authentication failed: {Error}", 
                    context.Exception.Message);
                    
                if (context.Exception.GetType() == typeof(SecurityTokenExpiredException))
                {
                    context.Response.Headers.Add("Token-Expired", "true");
                }
                
                return Task.CompletedTask;
            },
            OnChallenge = context =>
            {
                context.HandleResponse();
                context.Response.StatusCode = 401;
                context.Response.ContentType = "application/json";
                
                var result = JsonSerializer.Serialize(new
                {
                    error = "unauthorized",
                    error_description = context.ErrorDescription ?? "You are not authorized"
                });
                
                return context.Response.WriteAsync(result);
            }
        };
    });
```

#### Issue: CORS Errors
**Symptoms:**
```
Access to XMLHttpRequest has been blocked by CORS policy
No 'Access-Control-Allow-Origin' header is present
```

**Solution:**
```csharp
// Configure CORS properly
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowSpecificOrigins", builder =>
    {
        builder
            .WithOrigins(
                "https://localhost:3000",
                "https://myapp.azurewebsites.net")
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials()
            .SetPreflightMaxAge(TimeSpan.FromSeconds(2520));
    });
    
    // Development policy
    if (Environment.IsDevelopment())
    {
        options.AddPolicy("DevelopmentCors", builder =>
        {
            builder
                .AllowAnyOrigin()
                .AllowAnyMethod()
                .AllowAnyHeader();
        });
    }
});

// Apply in correct order
app.UseCors("AllowSpecificOrigins");
app.UseAuthentication();
app.UseAuthorization();
```

### 6. Deployment Issues

#### Issue: Application Fails in Docker
**Symptoms:**
```
System.Globalization.CultureNotFoundException
Could not find file '/app/appsettings.json'
```

**Solution:**
```dockerfile
# Fix culture issues
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

# Set invariant globalization
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8

# Install ICU libraries
RUN apt-get update && apt-get install -y libicu-dev

# Fix file copying
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy all project files
COPY ["src/", "src/"]
COPY ["*.sln", "./"]

# Restore
RUN dotnet restore

# Build and publish
WORKDIR "/src/src/Enterprise.API"
RUN dotnet publish "Enterprise.API.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .

# Ensure appsettings.json is copied
COPY --from=build /src/src/Enterprise.API/appsettings*.json ./

ENTRYPOINT ["dotnet", "Enterprise.API.dll"]
```

#### Issue: Azure Deployment Fails
**Symptoms:**
```
HTTP Error 500.30 - ASP.NET Core app failed to start
The specified framework 'Microsoft.NETCore.App', version '8.0.0' was not found
```

**Solution:**
```xml
<!-- Ensure self-contained deployment -->
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <RuntimeIdentifier>win-x64</RuntimeIdentifier>
    <SelfContained>true</SelfContained>
    <PublishSingleFile>false</PublishSingleFile>
    <PublishReadyToRun>true</PublishReadyToRun>
  </PropertyGroup>
</Project>
```

Azure CLI deployment:
```bash
# Build for Azure
dotnet publish -c Release -r win-x64 --self-contained true

# Deploy to Azure
az webapp deployment source config-zip \
  --resource-group myResourceGroup \
  --name myapp \
  --src publish.zip
```

### 7. Memory & Resource Issues

#### Issue: Memory Leaks
**Symptoms:**
- Increasing memory usage over time
- OutOfMemoryException
- Slow garbage collection

**Diagnosis:**
```csharp
// Add memory diagnostics
public class MemoryDiagnosticsController : ControllerBase
{
    [HttpGet("diagnostics/memory")]
    public IActionResult GetMemoryInfo()
    {
        var gcInfo = new
        {
            Gen0Collections = GC.CollectionCount(0),
            Gen1Collections = GC.CollectionCount(1),
            Gen2Collections = GC.CollectionCount(2),
            TotalMemory = GC.GetTotalMemory(false) / 1024 / 1024,
            AllocatedMemory = GC.GetTotalAllocatedBytes() / 1024 / 1024,
            WorkingSet = Process.GetCurrentProcess().WorkingSet64 / 1024 / 1024
        };
        
        return Ok(gcInfo);
    }
}
```

**Solution:**
```csharp
// 1. Dispose resources properly
public class OrderService : IDisposable
{
    private readonly HttpClient _httpClient;
    private bool _disposed;
    
    public OrderService(IHttpClientFactory httpClientFactory)
    {
        _httpClient = httpClientFactory.CreateClient("OrderApi");
    }
    
    public void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }
    
    protected virtual void Dispose(bool disposing)
    {
        if (!_disposed)
        {
            if (disposing)
            {
                _httpClient?.Dispose();
            }
            _disposed = true;
        }
    }
}

// 2. Use object pooling for expensive objects
public class ConnectionPool
{
    private readonly ObjectPool<ExpensiveObject> _pool;
    
    public ConnectionPool()
    {
        var policy = new DefaultPooledObjectPolicy<ExpensiveObject>();
        _pool = new DefaultObjectPool<ExpensiveObject>(policy, 100);
    }
    
    public async Task<T> ExecuteAsync<T>(Func<ExpensiveObject, Task<T>> operation)
    {
        var obj = _pool.Get();
        try
        {
            return await operation(obj);
        }
        finally
        {
            _pool.Return(obj);
        }
    }
}

// 3. Avoid capturing unnecessary variables in closures
public class BadExample
{
    private readonly LargeObject _largeObject = new();
    
    public Task ProcessAsync()
    {
        // Bad: Captures entire class instance
        return Task.Run(() =>
        {
            Console.WriteLine(_largeObject.Name);
        });
    }
}

public class GoodExample
{
    private readonly LargeObject _largeObject = new();
    
    public Task ProcessAsync()
    {
        // Good: Capture only what's needed
        var name = _largeObject.Name;
        return Task.Run(() =>
        {
            Console.WriteLine(name);
        });
    }
}
```

### 8. Semantic Kernel / AI Integration Issues

#### Issue: AI Service Timeout
**Symptoms:**
```
TaskCanceledException: The operation was canceled
HttpRequestException: Request timeout
```

**Solution:**
```csharp
// Configure proper timeouts and retry policies
services.AddSingleton<IKernel>(sp =>
{
    var builder = Kernel.CreateBuilder();
    
    // Configure HTTP client with retry
    var httpClient = new HttpClient(new PollyHttpMessageHandler());
    httpClient.Timeout = TimeSpan.FromSeconds(60);
    
    builder.AddAzureOpenAIChatCompletion(
        deploymentName: configuration["AzureOpenAI:DeploymentName"],
        endpoint: configuration["AzureOpenAI:Endpoint"],
        apiKey: configuration["AzureOpenAI:ApiKey"],
        httpClient: httpClient);
        
    return builder.Build();
});

// Polly retry handler
public class PollyHttpMessageHandler : DelegatingHandler
{
    protected override async Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request,
        CancellationToken cancellationToken)
    {
        var policy = Policy
            .HandleResult<HttpResponseMessage>(r => !r.IsSuccessStatusCode)
            .Or<TaskCanceledException>()
            .WaitAndRetryAsync(
                3,
                retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)),
                onRetry: (outcome, timespan, retryCount, context) =>
                {
                    var logger = context.Values["logger"] as ILogger;
                    logger?.LogWarning(
                        "Retry {RetryCount} after {Delay}s",
                        retryCount,
                        timespan.TotalSeconds);
                });
                
        return await policy.ExecuteAsync(async () =>
            await base.SendAsync(request, cancellationToken));
    }
}
```

## 🔧 Diagnostic Tools

### Application Insights Integration
```csharp
// Configure Application Insights
builder.Services.AddApplicationInsightsTelemetry(options =>
{
    options.ConnectionString = configuration["ApplicationInsights:ConnectionString"];
    options.EnableAdaptiveSampling = false; // Disable in development
    options.EnableDebugLogger = true;
});

// Custom telemetry
public class TelemetryService
{
    private readonly TelemetryClient _telemetryClient;
    
    public void TrackCustomEvent(string eventName, Dictionary<string, string> properties)
    {
        _telemetryClient.TrackEvent(eventName, properties);
    }
    
    public void TrackPerformance(string name, double value)
    {
        _telemetryClient.TrackMetric(name, value);
    }
    
    public IOperationHolder<RequestTelemetry> StartOperation(string operationName)
    {
        return _telemetryClient.StartOperation<RequestTelemetry>(operationName);
    }
}
```

### Health Check Dashboard
```csharp
// Startup configuration
app.UseHealthChecksUI(options =>
{
    options.UIPath = "/health-ui";
    options.ApiPath = "/health-api";
});

// appsettings.json
{
  "HealthChecksUI": {
    "HealthChecks": [
      {
        "Name": "API Health",
        "Uri": "https://localhost:5001/health"
      }
    ],
    "EvaluationTimeInSeconds": 10,
    "MinimumSecondsBetweenFailureNotifications": 60
  }
}
```

## 🛠️ Performance Profiling

### Using dotnet-trace
```bash
# Start trace
dotnet-trace collect --process-id $(dotnet-trace ps | grep Enterprise.API | awk '{print $1}') --providers Microsoft-Windows-DotNETRuntime

# Analyze trace
dotnet-trace convert trace.nettrace --format speedscope
```

### Using BenchmarkDotNet
```csharp
[MemoryDiagnoser]
[SimpleJob(RuntimeMoniker.Net80)]
public class RepositoryBenchmark
{
    private ApplicationDbContext _context;
    
    [GlobalSetup]
    public void Setup()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase("BenchmarkDb")
            .Options;
            
        _context = new ApplicationDbContext(options);
        SeedData();
    }
    
    [Benchmark]
    public async Task GetOrdersWithIncludes()
    {
        var orders = await _context.Orders
            .Include(o => o.Customer)
            .Include(o => o.Items)
            .ToListAsync();
    }
    
    [Benchmark]
    public async Task GetOrdersWithProjection()
    {
        var orders = await _context.Orders
            .Select(o => new { o.Id, o.Customer.Name, ItemCount = o.Items.Count() })
            .ToListAsync();
    }
}
```

## 🆘 Emergency Procedures

### 1. Production Database Rollback
```sql
-- Create backup before any changes
BACKUP DATABASE [ProductionDB] 
TO DISK = N'C:\Backups\ProductionDB_Emergency.bak' 
WITH NOFORMAT, INIT, NAME = N'Emergency Backup', 
SKIP, NOREWIND, NOUNLOAD, STATS = 10

-- Rollback migration
EXEC sp_executesql N'DELETE FROM [__EFMigrationsHistory] WHERE [MigrationId] = @p0',
N'@p0 nvarchar(150)',
@p0=N'20240120123456_ProblematicMigration'

-- Apply rollback script
-- Run compensating migration or manual fixes
```

### 2. Emergency Performance Fix
```csharp
// Temporary cache everything
public class EmergencyCacheMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IMemoryCache _cache;
    
    public async Task InvokeAsync(HttpContext context)
    {
        if (context.Request.Method == "GET")
        {
            var key = context.Request.Path + context.Request.QueryString;
            
            if (_cache.TryGetValue(key, out byte[] cachedResponse))
            {
                await context.Response.BodyWriter.WriteAsync(cachedResponse);
                return;
            }
            
            var originalBody = context.Response.Body;
            using var responseBody = new MemoryStream();
            context.Response.Body = responseBody;
            
            await _next(context);
            
            context.Response.Body.Seek(0, SeekOrigin.Begin);
            var response = new byte[context.Response.Body.Length];
            await context.Response.Body.ReadAsync(response);
            context.Response.Body.Seek(0, SeekOrigin.Begin);
            
            _cache.Set(key, response, TimeSpan.FromMinutes(5));
            
            await responseBody.CopyToAsync(originalBody);
        }
        else
        {
            await _next(context);
        }
    }
}
```

## ✅ Troubleshooting Checklist

When issues occur:

- [ ] Check application logs in Seq/Application Insights
- [ ] Verify database connectivity and query performance
- [ ] Check memory and CPU usage
- [ ] Review recent deployments and changes
- [ ] Validate configuration settings
- [ ] Check external service dependencies
- [ ] Review error rates and response times
- [ ] Verify authentication/authorization
- [ ] Check for package updates/security patches
- [ ] Test with minimal reproduction

## 📚 Additional Resources

### Debugging Tools
- [PerfView](https://github.com/Microsoft/perfview) - CPU and memory profiling
- [dotMemory](https://www.jetbrains.com/dotmemory/) - Memory profiler
- [BenchmarkDotNet](https://benchmarkdotnet.org/) - Micro-benchmarking
- [MiniProfiler](https://miniprofiler.com/) - Lightweight profiler

### Documentation
- [.NET Diagnostics](https://docs.microsoft.com/en-us/dotnet/core/diagnostics/)
- [EF Core Performance](https://docs.microsoft.com/en-us/ef/core/performance/)
- [ASP.NET Core Troubleshooting](https://docs.microsoft.com/en-us/aspnet/core/test/troubleshoot)

### Community Resources
- [Stack Overflow - .NET](https://stackoverflow.com/questions/tagged/.net)
- [r/dotnet](https://www.reddit.com/r/dotnet/)
- [.NET Discord](https://aka.ms/dotnet-discord)

---

**Remember**: When troubleshooting enterprise applications, always start with the basics - logs, metrics, and recent changes. Most issues have simple causes with complex symptoms.