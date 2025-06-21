# .NET Enterprise AI Agents Best Practices

## 🎯 Overview

This guide provides comprehensive best practices for building enterprise-grade AI agents using .NET, covering architecture, security, performance, and maintainability.

## 📋 Table of Contents

1. [Architecture Best Practices](#architecture-best-practices)
2. [Domain-Driven Design](#domain-driven-design)
3. [AI Integration Patterns](#ai-integration-patterns)
4. [Security & Compliance](#security--compliance)
5. [Performance Optimization](#performance-optimization)
6. [Testing Strategies](#testing-strategies)
7. [Deployment & Operations](#deployment--operations)
8. [Code Quality](#code-quality)

## 🏗️ Architecture Best Practices

### 1. Clean Architecture Principles

#### ✅ DO: Maintain Strict Layer Separation
```csharp
// Domain Layer - No dependencies
namespace EnterpriseAgent.Domain.Entities
{
    public class Agent
    {
        // Pure business logic, no framework dependencies
        public void ProcessMessage(Message message)
        {
            // Business rules only
        }
    }
}

// Application Layer - Depends only on Domain
namespace EnterpriseAgent.Application.Services
{
    public class AgentService
    {
        private readonly IAgentRepository _repository;
        // Orchestrates domain objects
    }
}

// Infrastructure Layer - Implements interfaces
namespace EnterpriseAgent.Infrastructure.Repositories
{
    public class AgentRepository : IAgentRepository
    {
        private readonly DbContext _context;
        // Data access implementation
    }
}
```

#### ❌ DON'T: Create Circular Dependencies
```csharp
// Bad: Domain depending on Infrastructure
public class Agent
{
    private readonly DbContext _context; // Never do this!
}
```

### 2. Dependency Injection

#### ✅ DO: Use Constructor Injection
```csharp
public class AgentOrchestrator
{
    private readonly IAgentService _agentService;
    private readonly IAIService _aiService;
    private readonly ILogger<AgentOrchestrator> _logger;

    public AgentOrchestrator(
        IAgentService agentService,
        IAIService aiService,
        ILogger<AgentOrchestrator> logger)
    {
        _agentService = agentService ?? throw new ArgumentNullException(nameof(agentService));
        _aiService = aiService ?? throw new ArgumentNullException(nameof(aiService));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }
}
```

#### ✅ DO: Register Services with Appropriate Lifetimes
```csharp
public static class DependencyInjection
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        // Singleton - Shared across all requests
        services.AddSingleton<IAIService, AzureOpenAIService>();
        services.AddSingleton<ICacheService, RedisCacheService>();
        
        // Scoped - Per request
        services.AddScoped<IAgentService, AgentService>();
        services.AddScoped<IUnitOfWork, UnitOfWork>();
        
        // Transient - New instance each time
        services.AddTransient<IMessageProcessor, MessageProcessor>();
        
        return services;
    }
}
```

### 3. CQRS Implementation

#### ✅ DO: Separate Commands and Queries
```csharp
// Command - Changes state
public record CreateAgentCommand : IRequest<AgentDto>
{
    public string Name { get; init; }
    public string Model { get; init; }
}

public class CreateAgentCommandHandler : IRequestHandler<CreateAgentCommand, AgentDto>
{
    public async Task<AgentDto> Handle(CreateAgentCommand request, CancellationToken cancellationToken)
    {
        // Modify state
        var agent = Agent.Create(request.Name, request.Model);
        await _repository.AddAsync(agent, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return _mapper.Map<AgentDto>(agent);
    }
}

// Query - Reads state
public record GetAgentByIdQuery : IRequest<AgentDto>
{
    public Guid AgentId { get; init; }
}

public class GetAgentByIdQueryHandler : IRequestHandler<GetAgentByIdQuery, AgentDto>
{
    public async Task<AgentDto> Handle(GetAgentByIdQuery request, CancellationToken cancellationToken)
    {
        // Read-only operation
        var agent = await _repository.GetByIdAsync(request.AgentId, cancellationToken);
        return _mapper.Map<AgentDto>(agent);
    }
}
```

## 🎨 Domain-Driven Design

### 1. Aggregate Design

#### ✅ DO: Design Small, Focused Aggregates
```csharp
public class Agent : AggregateRoot
{
    private readonly List<Tool> _tools = new();
    
    public string Name { get; private set; }
    public AgentStatus Status { get; private set; }
    public IReadOnlyCollection<Tool> Tools => _tools.AsReadOnly();

    // Business methods that maintain invariants
    public void AddTool(Tool tool)
    {
        if (_tools.Count >= 10)
            throw new DomainException("Agent cannot have more than 10 tools");
            
        if (_tools.Any(t => t.Name == tool.Name))
            throw new DomainException($"Tool {tool.Name} already exists");
            
        _tools.Add(tool);
        AddDomainEvent(new ToolAddedEvent(Id, tool.Name));
    }
}
```

### 2. Value Objects

#### ✅ DO: Use Value Objects for Domain Concepts
```csharp
public class Temperature : ValueObject
{
    public decimal Value { get; }
    public TemperatureUnit Unit { get; }

    public Temperature(decimal value, TemperatureUnit unit)
    {
        if (value < 0 || value > 2)
            throw new ArgumentException("Temperature must be between 0 and 2");
            
        Value = value;
        Unit = unit;
    }

    public Temperature ToFahrenheit()
    {
        if (Unit == TemperatureUnit.Fahrenheit)
            return this;
            
        var fahrenheit = (Value * 9 / 5) + 32;
        return new Temperature(fahrenheit, TemperatureUnit.Fahrenheit);
    }

    protected override IEnumerable<object> GetEqualityComponents()
    {
        yield return Value;
        yield return Unit;
    }
}
```

### 3. Domain Events

#### ✅ DO: Raise Domain Events for Important Changes
```csharp
public class AgentActivatedEvent : IDomainEvent
{
    public Guid AgentId { get; }
    public DateTime ActivatedAt { get; }
    
    public AgentActivatedEvent(Guid agentId)
    {
        AgentId = agentId;
        ActivatedAt = DateTime.UtcNow;
    }
}

// Handle domain events
public class AgentActivatedEventHandler : INotificationHandler<AgentActivatedEvent>
{
    public async Task Handle(AgentActivatedEvent notification, CancellationToken cancellationToken)
    {
        // Send notifications
        // Update analytics
        // Trigger workflows
    }
}
```

## 🤖 AI Integration Patterns

### 1. Service Abstraction

#### ✅ DO: Abstract AI Services
```csharp
public interface IAIService
{
    Task<string> GenerateTextAsync(string prompt, AIParameters parameters);
    Task<EmbeddingVector> GenerateEmbeddingAsync(string text);
    Task<AIResponse> ChatCompletionAsync(List<ChatMessage> messages);
}

// Implementation can be swapped
public class AzureOpenAIService : IAIService { }
public class OpenAIService : IAIService { }
public class AnthropicService : IAIService { }
```

### 2. Retry and Circuit Breaker

#### ✅ DO: Implement Resilience Patterns
```csharp
public class ResilientAIService : IAIService
{
    private readonly IAIService _innerService;
    private readonly IAsyncPolicy<string> _retryPolicy;

    public ResilientAIService(IAIService innerService)
    {
        _innerService = innerService;
        
        _retryPolicy = Policy
            .HandleResult<string>(string.IsNullOrEmpty)
            .Or<HttpRequestException>()
            .Or<TaskCanceledException>()
            .WaitAndRetryAsync(
                3,
                retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)),
                onRetry: (outcome, timespan, retryCount, context) =>
                {
                    var logger = context.Values["logger"] as ILogger;
                    logger?.LogWarning(
                        "Retry {RetryCount} after {Delay}ms",
                        retryCount,
                        timespan.TotalMilliseconds
                    );
                });
    }

    public async Task<string> GenerateTextAsync(string prompt, AIParameters parameters)
    {
        var context = new Context { ["logger"] = _logger };
        return await _retryPolicy.ExecuteAsync(
            async (ctx) => await _innerService.GenerateTextAsync(prompt, parameters),
            context
        );
    }
}
```

### 3. Prompt Engineering

#### ✅ DO: Use Structured Prompt Templates
```csharp
public class PromptTemplate
{
    private readonly string _template;
    private readonly Dictionary<string, object> _variables;

    public PromptTemplate(string template)
    {
        _template = template;
        _variables = new Dictionary<string, object>();
    }

    public PromptTemplate WithVariable(string name, object value)
    {
        _variables[name] = value;
        return this;
    }

    public string Build()
    {
        var result = _template;
        foreach (var (key, value) in _variables)
        {
            result = result.Replace($"{{{key}}}", value?.ToString() ?? string.Empty);
        }
        return result;
    }
}

// Usage
var prompt = new PromptTemplate(@"
You are a {role} assistant.
User Query: {query}
Context: {context}

Please provide a helpful response.
")
.WithVariable("role", "customer service")
.WithVariable("query", userInput)
.WithVariable("context", conversationHistory)
.Build();
```

## 🔒 Security & Compliance

### 1. Input Validation

#### ✅ DO: Validate All Inputs
```csharp
public class CreateAgentCommandValidator : AbstractValidator<CreateAgentCommand>
{
    public CreateAgentCommandValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Agent name is required")
            .Length(3, 100).WithMessage("Agent name must be between 3 and 100 characters")
            .Matches(@"^[a-zA-Z0-9\s-_]+$").WithMessage("Agent name contains invalid characters");

        RuleFor(x => x.SystemPrompt)
            .NotEmpty().WithMessage("System prompt is required")
            .MaximumLength(4000).WithMessage("System prompt cannot exceed 4000 characters")
            .Must(NotContainSensitiveData).WithMessage("System prompt contains sensitive data");

        RuleFor(x => x.Model)
            .NotEmpty().WithMessage("Model is required")
            .Must(BeValidModel).WithMessage("Invalid model specified");
    }

    private bool NotContainSensitiveData(string input)
    {
        // Check for PII patterns
        var patterns = new[]
        {
            @"\b\d{3}-\d{2}-\d{4}\b", // SSN
            @"\b\d{16}\b", // Credit card
        };

        return !patterns.Any(pattern => Regex.IsMatch(input, pattern));
    }

    private bool BeValidModel(string model)
    {
        var validModels = new[] { "gpt-4", "gpt-3.5-turbo", "claude-3" };
        return validModels.Contains(model);
    }
}
```

### 2. Data Encryption

#### ✅ DO: Encrypt Sensitive Data
```csharp
[AttributeUsage(AttributeTargets.Property)]
public class EncryptedAttribute : Attribute { }

public class EncryptionValueConverter : ValueConverter<string, string>
{
    private readonly IEncryptionService _encryptionService;

    public EncryptionValueConverter(IEncryptionService encryptionService)
        : base(
            v => encryptionService.Encrypt(v),
            v => encryptionService.Decrypt(v))
    {
        _encryptionService = encryptionService;
    }
}

// Apply in DbContext
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    foreach (var entityType in modelBuilder.Model.GetEntityTypes())
    {
        foreach (var property in entityType.GetProperties())
        {
            if (property.PropertyInfo?.GetCustomAttribute<EncryptedAttribute>() != null)
            {
                property.SetValueConverter(new EncryptionValueConverter(_encryptionService));
            }
        }
    }
}
```

### 3. Audit Logging

#### ✅ DO: Implement Comprehensive Audit Logging
```csharp
public class AuditableEntity
{
    public DateTime CreatedAt { get; set; }
    public string CreatedBy { get; set; }
    public DateTime? ModifiedAt { get; set; }
    public string? ModifiedBy { get; set; }
}

public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
{
    var entries = ChangeTracker.Entries<AuditableEntity>();
    var userId = _currentUserService.UserId;

    foreach (var entry in entries)
    {
        switch (entry.State)
        {
            case EntityState.Added:
                entry.Entity.CreatedAt = DateTime.UtcNow;
                entry.Entity.CreatedBy = userId;
                break;
            case EntityState.Modified:
                entry.Entity.ModifiedAt = DateTime.UtcNow;
                entry.Entity.ModifiedBy = userId;
                break;
        }

        // Create audit log entry
        if (entry.State != EntityState.Unchanged)
        {
            var auditEntry = new AuditLog
            {
                EntityName = entry.Entity.GetType().Name,
                Action = entry.State.ToString(),
                UserId = userId,
                Timestamp = DateTime.UtcNow,
                Changes = GetChanges(entry)
            };
            
            await _auditRepository.AddAsync(auditEntry, cancellationToken);
        }
    }

    return await base.SaveChangesAsync(cancellationToken);
}
```

## 🚀 Performance Optimization

### 1. Async Best Practices

#### ✅ DO: Use Async/Await Properly
```csharp
public class AgentService
{
    // Good: Async all the way
    public async Task<AgentResponse> ProcessMessageAsync(string message)
    {
        // Don't block async code
        var agent = await _repository.GetActiveAgentAsync();
        
        // Process concurrently when possible
        var tasksToRun = new[]
        {
            _aiService.GenerateResponseAsync(message),
            _analyticsService.LogMessageAsync(message),
            _cacheService.GetContextAsync()
        };
        
        await Task.WhenAll(tasksToRun);
        
        return new AgentResponse
        {
            Response = tasksToRun[0].Result,
            Context = tasksToRun[2].Result
        };
    }
    
    // Configure await when context doesn't matter
    public async Task<string> GetCachedValueAsync(string key)
    {
        return await _cache.GetAsync(key).ConfigureAwait(false);
    }
}
```

### 2. Caching Strategies

#### ✅ DO: Implement Multi-Level Caching
```csharp
public class CachingAgentService : IAgentService
{
    private readonly IAgentService _innerService;
    private readonly IMemoryCache _memoryCache;
    private readonly IDistributedCache _distributedCache;
    
    public async Task<Agent> GetAgentAsync(Guid id)
    {
        // L1: Memory cache
        if (_memoryCache.TryGetValue($"agent:{id}", out Agent agent))
            return agent;
        
        // L2: Distributed cache
        var cached = await _distributedCache.GetAsync($"agent:{id}");
        if (cached != null)
        {
            agent = JsonSerializer.Deserialize<Agent>(cached);
            _memoryCache.Set($"agent:{id}", agent, TimeSpan.FromMinutes(5));
            return agent;
        }
        
        // L3: Database
        agent = await _innerService.GetAgentAsync(id);
        
        // Cache for next time
        var serialized = JsonSerializer.SerializeToUtf8Bytes(agent);
        await _distributedCache.SetAsync(
            $"agent:{id}",
            serialized,
            new DistributedCacheEntryOptions
            {
                SlidingExpiration = TimeSpan.FromMinutes(15)
            }
        );
        
        _memoryCache.Set($"agent:{id}", agent, TimeSpan.FromMinutes(5));
        
        return agent;
    }
}
```

### 3. Database Optimization

#### ✅ DO: Optimize Entity Framework Queries
```csharp
public class OptimizedAgentRepository : IAgentRepository
{
    public async Task<IEnumerable<Agent>> GetActiveAgentsAsync()
    {
        return await _context.Agents
            .AsNoTracking() // Read-only query
            .Include(a => a.Tools) // Eager load to avoid N+1
            .Where(a => a.Status == AgentStatus.Active)
            .OrderBy(a => a.Name)
            .Take(100) // Limit results
            .ToListAsync();
    }
    
    public async Task<Agent?> GetAgentWithConversationsAsync(Guid id)
    {
        return await _context.Agents
            .Include(a => a.Conversations.Where(c => c.Status == ConversationStatus.Active))
            .ThenInclude(c => c.Messages.OrderByDescending(m => m.Timestamp).Take(10))
            .AsSplitQuery() // Split to avoid cartesian explosion
            .FirstOrDefaultAsync(a => a.Id == id);
    }
}
```

## 🧪 Testing Strategies

### 1. Unit Testing

#### ✅ DO: Test Business Logic Thoroughly
```csharp
public class AgentTests
{
    [Fact]
    public void AddTool_WhenToolDoesNotExist_ShouldAddSuccessfully()
    {
        // Arrange
        var agent = Agent.Create("TestAgent", "gpt-4", "System prompt");
        var tool = new Tool("Calculator", "Performs calculations");
        
        // Act
        agent.AddTool(tool);
        
        // Assert
        agent.Tools.Should().ContainSingle();
        agent.Tools.First().Name.Should().Be("Calculator");
        agent.DomainEvents.Should().ContainSingle(e => e is ToolAddedEvent);
    }
    
    [Fact]
    public void AddTool_WhenToolExists_ShouldThrowException()
    {
        // Arrange
        var agent = Agent.Create("TestAgent", "gpt-4", "System prompt");
        var tool = new Tool("Calculator", "Performs calculations");
        agent.AddTool(tool);
        
        // Act
        var act = () => agent.AddTool(tool);
        
        // Assert
        act.Should().Throw<DomainException>()
            .WithMessage("Tool Calculator already exists");
    }
}
```

### 2. Integration Testing

#### ✅ DO: Test Full Stack Integration
```csharp
public class AgentIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly HttpClient _client;

    public AgentIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                // Replace real services with test doubles
                services.RemoveAll<IAIService>();
                services.AddSingleton<IAIService, MockAIService>();
            });
        });
        
        _client = _factory.CreateClient();
    }

    [Fact]
    public async Task CreateAgent_ShouldReturnCreatedAgent()
    {
        // Arrange
        var command = new
        {
            name = "TestAgent",
            model = "gpt-4",
            systemPrompt = "Test prompt"
        };
        
        // Act
        var response = await _client.PostAsJsonAsync("/api/agents", command);
        
        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        var agent = await response.Content.ReadFromJsonAsync<AgentDto>();
        agent.Should().NotBeNull();
        agent.Name.Should().Be("TestAgent");
    }
}
```

### 3. Performance Testing

#### ✅ DO: Include Performance Tests
```csharp
[Collection("Performance")]
public class AgentPerformanceTests
{
    [Fact]
    public async Task ProcessMessage_ShouldCompleteWithinSLA()
    {
        // Arrange
        var service = new AgentService();
        var message = "Test message";
        var stopwatch = new Stopwatch();
        
        // Act
        stopwatch.Start();
        var result = await service.ProcessMessageAsync(message);
        stopwatch.Stop();
        
        // Assert
        stopwatch.ElapsedMilliseconds.Should().BeLessThan(1000); // 1 second SLA
    }
}
```

## 🚢 Deployment & Operations

### 1. Configuration Management

#### ✅ DO: Use Strongly Typed Configuration
```csharp
public class AIConfiguration
{
    public string Endpoint { get; set; }
    public string ApiKey { get; set; }
    public string DeploymentName { get; set; }
    public int MaxRetries { get; set; } = 3;
    public int TimeoutSeconds { get; set; } = 30;
}

// In Startup/Program.cs
services.Configure<AIConfiguration>(configuration.GetSection("AI"));

// In service
public class AIService
{
    private readonly AIConfiguration _config;
    
    public AIService(IOptions<AIConfiguration> options)
    {
        _config = options.Value;
    }
}
```

### 2. Health Checks

#### ✅ DO: Implement Comprehensive Health Checks
```csharp
public class AIServiceHealthCheck : IHealthCheck
{
    private readonly IAIService _aiService;
    
    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var response = await _aiService.GenerateTextAsync(
                "Test prompt",
                new AIParameters { MaxTokens = 10 }
            );
            
            return HealthCheckResult.Healthy("AI service is responsive");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy(
                "AI service is not responding",
                ex,
                new Dictionary<string, object>
                {
                    ["error"] = ex.Message,
                    ["type"] = ex.GetType().Name
                }
            );
        }
    }
}

// Register health checks
services.AddHealthChecks()
    .AddCheck<AIServiceHealthCheck>("ai_service")
    .AddDbContextCheck<ApplicationDbContext>()
    .AddRedis(redisConnectionString)
    .AddAzureBlobStorage(storageConnectionString);
```

### 3. Monitoring and Telemetry

#### ✅ DO: Implement Structured Logging and Metrics
```csharp
public class InstrumentedAgentService : IAgentService
{
    private readonly IAgentService _innerService;
    private readonly ILogger<InstrumentedAgentService> _logger;
    private readonly IMetrics _metrics;
    
    public async Task<AgentResponse> ProcessMessageAsync(string message)
    {
        using var activity = Activity.StartActivity("ProcessMessage");
        using var timer = _metrics.Measure.Timer.Time("agent.message.processing");
        
        try
        {
            _logger.LogInformation(
                "Processing message for agent {AgentId} with length {MessageLength}",
                _agentId,
                message.Length
            );
            
            var response = await _innerService.ProcessMessageAsync(message);
            
            _metrics.Measure.Counter.Increment("agent.message.processed");
            
            return response;
        }
        catch (Exception ex)
        {
            _metrics.Measure.Counter.Increment("agent.message.failed");
            
            _logger.LogError(
                ex,
                "Failed to process message for agent {AgentId}",
                _agentId
            );
            
            throw;
        }
    }
}
```

## 📝 Code Quality

### 1. Code Organization

#### ✅ DO: Follow Consistent Project Structure
```
src/
├── EnterpriseAgent.Domain/
│   ├── Aggregates/
│   ├── Entities/
│   ├── ValueObjects/
│   ├── Events/
│   ├── Exceptions/
│   └── Services/
├── EnterpriseAgent.Application/
│   ├── Commands/
│   ├── Queries/
│   ├── Services/
│   ├── DTOs/
│   ├── Mappings/
│   └── Validators/
├── EnterpriseAgent.Infrastructure/
│   ├── Persistence/
│   ├── Services/
│   ├── Caching/
│   └── Messaging/
└── EnterpriseAgent.API/
    ├── Controllers/
    ├── Middleware/
    ├── Filters/
    └── Extensions/
```

### 2. Documentation

#### ✅ DO: Document Public APIs
```csharp
/// <summary>
/// Processes a message using the configured AI agent.
/// </summary>
/// <param name="message">The message to process.</param>
/// <param name="context">Optional context for the conversation.</param>
/// <param name="cancellationToken">Cancellation token.</param>
/// <returns>The agent's response including any actions taken.</returns>
/// <exception cref="ArgumentNullException">Thrown when message is null.</exception>
/// <exception cref="AgentNotAvailableException">Thrown when no agent is available.</exception>
/// <example>
/// <code>
/// var response = await agentService.ProcessMessageAsync(
///     "What's the weather like?",
///     new ConversationContext { UserId = "user123" }
/// );
/// </code>
/// </example>
public async Task<AgentResponse> ProcessMessageAsync(
    string message,
    ConversationContext? context = null,
    CancellationToken cancellationToken = default)
{
    // Implementation
}
```

### 3. Code Analysis

#### ✅ DO: Use Code Analysis Tools
```xml
<!-- In .csproj files -->
<PropertyGroup>
  <AnalysisLevel>latest</AnalysisLevel>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
  <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
</PropertyGroup>

<ItemGroup>
  <PackageReference Include="Microsoft.CodeAnalysis.NetAnalyzers" Version="8.0.0" />
  <PackageReference Include="SonarAnalyzer.CSharp" Version="9.12.0.78982" />
  <PackageReference Include="StyleCop.Analyzers" Version="1.2.0-beta.507" />
</ItemGroup>
```

## 🎯 Key Takeaways

1. **Architecture Matters**: Clean Architecture ensures maintainability and testability
2. **Domain First**: Focus on business logic before technical implementation
3. **Security by Design**: Build security into every layer
4. **Performance is a Feature**: Optimize early and measure constantly
5. **Test Everything**: Comprehensive testing prevents production issues
6. **Monitor and Measure**: You can't improve what you don't measure

## 📚 Additional Resources

- [.NET Application Architecture Guides](https://dotnet.microsoft.com/learn/dotnet/architecture-guides)
- [Domain-Driven Design Reference](https://www.domainlanguage.com/ddd/reference/)
- [Enterprise Integration Patterns](https://www.enterpriseintegrationpatterns.com/)
- [Azure Architecture Center](https://docs.microsoft.com/azure/architecture/)

---

Remember: Best practices evolve. Stay current with the .NET ecosystem and continuously refine your approach based on team experience and project requirements.