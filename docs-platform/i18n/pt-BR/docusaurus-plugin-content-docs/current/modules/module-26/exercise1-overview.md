---
sidebar_position: 4
title: "Exercise 1: Overview"
description: "## 🎯 Objective"
---

# Exercício 1: Empresarial Agent Framework (⭐ Fácil - 30 minutos)

## 🎯 Objective
Build a foundational enterprise-grade AI agent framework using .NET 8, implementing Clean Architecture, CQRS pattern, and Domain-Driven Design principles.

## 🧠 O Que Você Aprenderá
- Clean Architecture implementation in .NET
- Domain-Driven Design for AI agents
- CQRS pattern with MediatR
- Dependency injection and IoC
- Repository and Unit of Work patterns
- Basic agent orchestration

## 📋 Pré-requisitos
- .NET 8 SDK instalado
- Visual Studio 2022 or VS Code
- Basic understanding of C# and ASP.NET Core
- Completard module prerequisites setup

## 📚 Voltarground

Empresarial AI agents require a robust architectural foundation that ensures:

- **Separation of Concerns**: Clear boundaries between layers
- **Testability**: Fácil unit and integration testing
- **Maintainability**: Clean, organized code structure
- **Scalability**: Support for growing requirements
- **Flexibility**: Fácil to extend and modify

We'll implement Clean Architecture with:
- **Domain Layer**: Core business logic and entities
- **Application Layer**: Use cases and application logic
- **Infrastructure Layer**: External concerns (DB, APIs)
- **Presentation Layer**: Web API endpoints

## 🏗️ Architecture Visão Geral

```mermaid
graph TB
    subgraph "Presentation Layer"
        API[Web API Controllers]
        MW[Middleware]
    end
    
    subgraph "Application Layer"
        CMD[Commands]
        QRY[Queries]
        HDL[Handlers]
        VAL[Validators]
        MAP[Mappings]
    end
    
    subgraph "Domain Layer"
        AGT[Agent Aggregate]
        CNV[Conversation Entity]
        MSG[Message Value Object]
        EVT[Domain Events]
        SVC[Domain Services]
    end
    
    subgraph "Infrastructure Layer"
        DB[EF Core DbContext]
        REPO[Repositories]
        AI[AI Service]
        CACHE[Cache Service]
    end
    
    API --&gt; CMD
    API --&gt; QRY
    CMD --&gt; HDL
    QRY --&gt; HDL
    HDL --&gt; AGT
    HDL --&gt; SVC
    AGT --&gt; EVT
    HDL --&gt; REPO
    REPO --&gt; DB
    SVC --&gt; AI
    
    style API fill:#512BD4
    style AGT fill:#68217A
    style AI fill:#0078D4
```

## 🛠️ Step-by-Step Instructions

### Step 1: Configurar Domain Layer

**Copilot Prompt Suggestion:**
```csharp
// Create domain entities for an AI agent system that includes:
// - Agent aggregate root with properties like Id, Name, Model, SystemPrompt
// - Conversation entity with Messages collection
// - Message value object with Role, Content, Timestamp
// - Domain events for agent lifecycle
// - Follow DDD principles with private setters and factory methods
```

Create `Domain/Entities/Agent.cs`:
```csharp
using EnterpriseAgent.Domain.Common;
using EnterpriseAgent.Domain.Events;
using EnterpriseAgent.Domain.ValueObjects;

namespace EnterpriseAgent.Domain.Entities;

public class Agent : AggregateRoot
{
    private readonly List<Conversation> _conversations = new();
    private readonly List<Tool> _tools = new();

    public string Name { get; private set; }
    public string Model { get; private set; }
    public string SystemPrompt { get; private set; }
    public AgentStatus Status { get; private set; }
    public AgentCapabilities Capabilities { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime? LastActiveAt { get; private set; }

    public IReadOnlyCollection<Conversation> Conversations =&gt; _conversations.AsReadOnly();
    public IReadOnlyCollection<Tool> Tools =&gt; _tools.AsReadOnly();

    // EF Core constructor
    private Agent() { }

    // Factory method for creating new agents
    public static Agent Create(
        string name,
        string model,
        string systemPrompt,
        AgentCapabilities capabilities)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Agent name is required", nameof(name));
        
        if (string.IsNullOrWhiteSpace(model))
            throw new ArgumentException("Model is required", nameof(model));

        var agent = new Agent
        {
            Id = Guid.NewGuid(),
            Name = name,
            Model = model,
            SystemPrompt = systemPrompt,
            Status = AgentStatus.Inactive,
            Capabilities = capabilities,
            CreatedAt = DateTime.UtcNow
        };

        agent.AddDomainEvent(new AgentCreatedEvent(agent.Id, agent.Name));
        
        return agent;
    }

    public Conversation StartConversation(string userId, string initialMessage)
    {
        if (Status != AgentStatus.Active)
            throw new InvalidOperationException("Agent must be active to start conversations");

        var conversation = Conversation.Create(Id, userId, initialMessage);
        _conversations.Add(conversation);
        
        LastActiveAt = DateTime.UtcNow;
        
        AddDomainEvent(new ConversationStartedEvent(Id, conversation.Id, userId));
        
        return conversation;
    }

    public void Activate()
    {
        if (Status == AgentStatus.Active)
            return;

        Status = AgentStatus.Active;
        AddDomainEvent(new AgentActivatedEvent(Id));
    }

    public void Deactivate()
    {
        if (Status == AgentStatus.Inactive)
            return;

        Status = AgentStatus.Inactive;
        AddDomainEvent(new AgentDeactivatedEvent(Id));
    }

    public void AddTool(Tool tool)
    {
        if (_tools.Any(t =&gt; t.Name == tool.Name))
            throw new InvalidOperationException($"Tool {tool.Name} already exists");

        _tools.Add(tool);
        AddDomainEvent(new ToolAddedEvent(Id, tool.Name));
    }

    public void UpdateSystemPrompt(string newPrompt)
    {
        if (string.IsNullOrWhiteSpace(newPrompt))
            throw new ArgumentException("System prompt cannot be empty", nameof(newPrompt));

        var oldPrompt = SystemPrompt;
        SystemPrompt = newPrompt;
        
        AddDomainEvent(new SystemPromptUpdatedEvent(Id, oldPrompt, newPrompt));
    }
}

public enum AgentStatus
{
    Inactive,
    Active,
    Maintenance,
    Deprecated
}
```

Create `Domain/Entities/Conversation.cs`:
```csharp
using EnterpriseAgent.Domain.Common;
using EnterpriseAgent.Domain.ValueObjects;

namespace EnterpriseAgent.Domain.Entities;

public class Conversation : Entity
{
    private readonly List<Message> _messages = new();

    public Guid AgentId { get; private set; }
    public string UserId { get; private set; }
    public ConversationStatus Status { get; private set; }
    public DateTime StartedAt { get; private set; }
    public DateTime? EndedAt { get; private set; }
    public ConversationMetadata Metadata { get; private set; }

    public IReadOnlyCollection<Message> Messages =&gt; _messages.AsReadOnly();

    private Conversation() { }

    public static Conversation Create(Guid agentId, string userId, string initialMessage)
    {
        var conversation = new Conversation
        {
            Id = Guid.NewGuid(),
            AgentId = agentId,
            UserId = userId,
            Status = ConversationStatus.Active,
            StartedAt = DateTime.UtcNow,
            Metadata = ConversationMetadata.Default()
        };

        var userMessage = Message.CreateUserMessage(initialMessage);
        conversation._messages.Add(userMessage);

        return conversation;
    }

    public void AddMessage(Message message)
    {
        if (Status != ConversationStatus.Active)
            throw new InvalidOperationException("Cannot add messages to inactive conversation");

        _messages.Add(message);
        
        // Update metadata
        Metadata = Metadata.IncrementMessageCount();
    }

    public void End()
    {
        if (Status != ConversationStatus.Active)
            return;

        Status = ConversationStatus.Completed;
        EndedAt = DateTime.UtcNow;
    }

    public TimeSpan GetDuration()
    {
        var endTime = EndedAt ?? DateTime.UtcNow;
        return endTime - StartedAt;
    }
}

public enum ConversationStatus
{
    Active,
    Completed,
    Abandoned,
    Failed
}
```

Create `Domain/ValueObjects/Message.cs`:
```csharp
using EnterpriseAgent.Domain.Common;

namespace EnterpriseAgent.Domain.ValueObjects;

public class Message : ValueObject
{
    public MessageRole Role { get; private set; }
    public string Content { get; private set; }
    public DateTime Timestamp { get; private set; }
    public Dictionary<string, object> Metadata { get; private set; }

    private Message() { }

    public static Message CreateUserMessage(string content)
    {
        return new Message
        {
            Role = MessageRole.User,
            Content = content ?? throw new ArgumentNullException(nameof(content)),
            Timestamp = DateTime.UtcNow,
            Metadata = new Dictionary<string, object>()
        };
    }

    public static Message CreateAssistantMessage(string content, Dictionary<string, object>? metadata = null)
    {
        return new Message
        {
            Role = MessageRole.Assistant,
            Content = content ?? throw new ArgumentNullException(nameof(content)),
            Timestamp = DateTime.UtcNow,
            Metadata = metadata ?? new Dictionary<string, object>()
        };
    }

    public static Message CreateSystemMessage(string content)
    {
        return new Message
        {
            Role = MessageRole.System,
            Content = content ?? throw new ArgumentNullException(nameof(content)),
            Timestamp = DateTime.UtcNow,
            Metadata = new Dictionary<string, object>()
        };
    }

    protected override IEnumerable<object> GetEqualityComponents()
    {
        yield return Role;
        yield return Content;
        yield return Timestamp;
    }
}

public enum MessageRole
{
    System,
    User,
    Assistant,
    Function
}
```

Create `Domain/Common/AggregateRoot.cs`:
```csharp
namespace EnterpriseAgent.Domain.Common;

public abstract class AggregateRoot : Entity
{
    private readonly List<IDomainEvent> _domainEvents = new();
    
    public IReadOnlyCollection<IDomainEvent> DomainEvents =&gt; _domainEvents.AsReadOnly();

    protected void AddDomainEvent(IDomainEvent domainEvent)
    {
        _domainEvents.Add(domainEvent);
    }

    public void ClearDomainEvents()
    {
        _domainEvents.Clear();
    }
}
```

### Step 2: Create Application Layer

Create `Application/Agents/Commands/CreateAgentCommand.cs`:
```csharp
using MediatR;
using EnterpriseAgent.Domain.Entities;
using EnterpriseAgent.Domain.ValueObjects;

namespace EnterpriseAgent.Application.Agents.Commands;

public record CreateAgentCommand : IRequest<AgentDto>
{
    public string Name { get; init; } = string.Empty;
    public string Model { get; init; } = string.Empty;
    public string SystemPrompt { get; init; } = string.Empty;
    public List<string> Capabilities { get; init; } = new();
}

public class CreateAgentCommandHandler : IRequestHandler<CreateAgentCommand, AgentDto>
{
    private readonly IAgentRepository _agentRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<CreateAgentCommandHandler> _logger;

    public CreateAgentCommandHandler(
        IAgentRepository agentRepository,
        IUnitOfWork unitOfWork,
        ILogger<CreateAgentCommandHandler> logger)
    {
        _agentRepository = agentRepository;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<AgentDto> Handle(CreateAgentCommand request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Creating new agent: {AgentName}", request.Name);

        var capabilities = new AgentCapabilities(
            request.Capabilities.Contains("text"),
            request.Capabilities.Contains("voice"),
            request.Capabilities.Contains("vision"),
            request.Capabilities.Contains("function-calling")
        );

        var agent = Agent.Create(
            request.Name,
            request.Model,
            request.SystemPrompt,
            capabilities
        );

        await _agentRepository.AddAsync(agent, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Agent created successfully: {AgentId}", agent.Id);

        return new AgentDto
        {
            Id = agent.Id,
            Name = agent.Name,
            Model = agent.Model,
            SystemPrompt = agent.SystemPrompt,
            Status = agent.Status.ToString(),
            Capabilities = request.Capabilities,
            CreatedAt = agent.CreatedAt
        };
    }
}
```

Create `Application/Agents/Commands/CreateAgentCommandValidator.cs`:
```csharp
using FluentValidation;

namespace EnterpriseAgent.Application.Agents.Commands;

public class CreateAgentCommandValidator : AbstractValidator<CreateAgentCommand>
{
    private readonly string[] _validModels = { "gpt-4", "gpt-3.5-turbo", "claude-3", "llama-2" };
    private readonly string[] _validCapabilities = { "text", "voice", "vision", "function-calling" };

    public CreateAgentCommandValidator()
    {
        RuleFor(x =&gt; x.Name)
            .NotEmpty().WithMessage("Agent name is required")
            .MaximumLength(100).WithMessage("Agent name must not exceed 100 characters")
            .Matches("^[a-zA-Z0-9-_]+$").WithMessage("Agent name can only contain letters, numbers, hyphens, and underscores");

        RuleFor(x =&gt; x.Model)
            .NotEmpty().WithMessage("Model is required")
            .Must(BeValidModel).WithMessage($"Model must be one of: {string.Join(", ", _validModels)}");

        RuleFor(x =&gt; x.SystemPrompt)
            .NotEmpty().WithMessage("System prompt is required")
            .MaximumLength(4000).WithMessage("System prompt must not exceed 4000 characters");

        RuleFor(x =&gt; x.Capabilities)
            .NotEmpty().WithMessage("At least one capability must be specified")
            .Must(BeValidCapabilities).WithMessage($"Invalid capability. Valid options: {string.Join(", ", _validCapabilities)}");
    }

    private bool BeValidModel(string model)
    {
        return _validModels.Contains(model, StringComparer.OrdinalIgnoreCase);
    }

    private bool BeValidCapabilities(List<string> capabilities)
    {
        return capabilities.All(c =&gt; _validCapabilities.Contains(c, StringComparer.OrdinalIgnoreCase));
    }
}
```

Create `Application/Agents/Queries/GetAgentByIdQuery.cs`:
```csharp
using MediatR;
using EnterpriseAgent.Application.Common.Exceptions;

namespace EnterpriseAgent.Application.Agents.Queries;

public record GetAgentByIdQuery(Guid AgentId) : IRequest<AgentDto>;

public class GetAgentByIdQueryHandler : IRequestHandler<GetAgentByIdQuery, AgentDto>
{
    private readonly IAgentRepository _agentRepository;
    private readonly IMapper _mapper;

    public GetAgentByIdQueryHandler(IAgentRepository agentRepository, IMapper mapper)
    {
        _agentRepository = agentRepository;
        _mapper = mapper;
    }

    public async Task<AgentDto> Handle(GetAgentByIdQuery request, CancellationToken cancellationToken)
    {
        var agent = await _agentRepository.GetByIdAsync(request.AgentId, cancellationToken);
        
        if (agent == null)
        {
            throw new NotFoundException($"Agent with ID {request.AgentId} not found");
        }

        return _mapper.Map<AgentDto>(agent);
    }
}
```

### Step 3: Implement Infrastructure Layer

Create `Infrastructure/Persistence/AgentDbContext.cs`:
```csharp
using Microsoft.EntityFrameworkCore;
using EnterpriseAgent.Domain.Entities;
using EnterpriseAgent.Domain.Common;
using System.Reflection;

namespace EnterpriseAgent.Infrastructure.Persistence;

public class AgentDbContext : DbContext, IUnitOfWork
{
    private readonly IMediator _mediator;
    private readonly IDateTime _dateTime;

    public AgentDbContext(
        DbContextOptions<AgentDbContext> options,
        IMediator mediator,
        IDateTime dateTime) : base(options)
    {
        _mediator = mediator;
        _dateTime = dateTime;
    }

    public DbSet<Agent> Agents =&gt; Set<Agent>();
    public DbSet<Conversation> Conversations =&gt; Set<Conversation>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
        base.OnModelCreating(modelBuilder);
    }

    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        // Handle domain events
        var domainEvents = ChangeTracker.Entries<AggregateRoot>()
            .SelectMany(x =&gt; x.Entity.DomainEvents)
            .ToList();

        var result = await base.SaveChangesAsync(cancellationToken);

        // Dispatch domain events after saving
        foreach (var domainEvent in domainEvents)
        {
            await _mediator.Publish(domainEvent, cancellationToken);
        }

        return result;
    }
}
```

Create `Infrastructure/Persistence/Repositories/AgentRepository.cs`:
```csharp
using Microsoft.EntityFrameworkCore;
using EnterpriseAgent.Domain.Entities;
using EnterpriseAgent.Application.Common.Interfaces;

namespace EnterpriseAgent.Infrastructure.Persistence.Repositories;

public class AgentRepository : IAgentRepository
{
    private readonly AgentDbContext _context;

    public AgentRepository(AgentDbContext context)
    {
        _context = context;
    }

    public async Task<Agent?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _context.Agents
            .Include(a => a.Tools)
            .Include(a => a.Conversations)
                .ThenInclude(c => c.Messages)
            .FirstOrDefaultAsync(a => a.Id == id, cancellationToken);
    }

    public async Task<IEnumerable<Agent>&gt; GetAllAsync(CancellationToken cancellationToken = default)
    {
        return await _context.Agents
            .Include(a =&gt; a.Tools)
            .ToListAsync(cancellationToken);
    }

    public async Task<IEnumerable<Agent>&gt; GetActiveAgentsAsync(CancellationToken cancellationToken = default)
    {
        return await _context.Agents
            .Where(a =&gt; a.Status == AgentStatus.Active)
            .Include(a =&gt; a.Tools)
            .ToListAsync(cancellationToken);
    }

    public async Task AddAsync(Agent agent, CancellationToken cancellationToken = default)
    {
        await _context.Agents.AddAsync(agent, cancellationToken);
    }

    public void Update(Agent agent)
    {
        _context.Agents.Update(agent);
    }

    public void Remove(Agent agent)
    {
        _context.Agents.Remove(agent);
    }

    public async Task<bool> ExistsAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _context.Agents.AnyAsync(a =&gt; a.Id == id, cancellationToken);
    }

    public async Task<Agent?> GetByNameAsync(string name, CancellationToken cancellationToken = default)
    {
        return await _context.Agents
            .FirstOrDefaultAsync(a => a.Name == name, cancellationToken);
    }
}
```

Create `Infrastructure/Services/AzureAbrirAIService.cs`:
```csharp
using Azure;
using Azure.AI.OpenAI;
using EnterpriseAgent.Application.Common.Interfaces;
using Microsoft.Extensions.Options;

namespace EnterpriseAgent.Infrastructure.Services;

public class AzureOpenAIService : IAIService
{
    private readonly OpenAIClient _client;
    private readonly AzureOpenAIOptions _options;
    private readonly ILogger<AzureOpenAIService> _logger;

    public AzureOpenAIService(
        IOptions<AzureOpenAIOptions> options,
        ILogger<AzureOpenAIService> logger)
    {
        _options = options.Value;
        _logger = logger;
        
        _client = new OpenAIClient(
            new Uri(_options.Endpoint),
            new AzureKeyCredential(_options.ApiKey)
        );
    }

    public async Task<string> GetCompletionAsync(
        string prompt,
        string model,
        Dictionary<string, object>? parameters = null,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var chatCompletionsOptions = new ChatCompletionsOptions()
            {
                DeploymentName = model,
                Messages =
                {
                    new ChatRequestSystemMessage(prompt),
                },
                Temperature = parameters?.GetValueOrDefault("temperature") as float? ?? 0.7f,
                MaxTokens = parameters?.GetValueOrDefault("maxTokens") as int? ?? 2000,
                TopP = parameters?.GetValueOrDefault("topP") as float? ?? 0.95f,
            };

            Response<ChatCompletions> response = await _client.GetChatCompletionsAsync(
                chatCompletionsOptions,
                cancellationToken
            );

            return response.Value.Choices[0].Message.Content;
        }
        catch (RequestFailedException ex)
        {
            _logger.LogError(ex, "Azure OpenAI request failed");
            throw new InvalidOperationException("AI service request failed", ex);
        }
    }

    public async Task<ChatResponse> GetChatCompletionAsync(
        List<ChatMessage> messages,
        string model,
        Dictionary<string, object>? parameters = null,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var chatCompletionsOptions = new ChatCompletionsOptions()
            {
                DeploymentName = model,
                Temperature = parameters?.GetValueOrDefault("temperature") as float? ?? 0.7f,
                MaxTokens = parameters?.GetValueOrDefault("maxTokens") as int? ?? 2000,
            };

            // Convert messages
            foreach (var message in messages)
            {
                switch (message.Role.ToLower())
                {
                    case "system":
                        chatCompletionsOptions.Messages.Add(new ChatRequestSystemMessage(message.Content));
                        break;
                    case "user":
                        chatCompletionsOptions.Messages.Add(new ChatRequestUserMessage(message.Content));
                        break;
                    case "assistant":
                        chatCompletionsOptions.Messages.Add(new ChatRequestAssistantMessage(message.Content));
                        break;
                }
            }

            Response<ChatCompletions> response = await _client.GetChatCompletionsAsync(
                chatCompletionsOptions,
                cancellationToken
            );

            var choice = response.Value.Choices[0];
            
            return new ChatResponse
            {
                Content = choice.Message.Content,
                Role = choice.Message.Role.ToString(),
                FinishReason = choice.FinishReason.ToString(),
                Usage = new TokenUsage
                {
                    PromptTokens = response.Value.Usage.PromptTokens,
                    CompletionTokens = response.Value.Usage.CompletionTokens,
                    TotalTokens = response.Value.Usage.TotalTokens
                }
            };
        }
        catch (RequestFailedException ex)
        {
            _logger.LogError(ex, "Azure OpenAI chat request failed");
            throw new InvalidOperationException("AI service request failed", ex);
        }
    }
}
```

### Step 4: Create Web API Layer

Create `API/Controllers/AgentsController.cs`:
```csharp
using Microsoft.AspNetCore.Mvc;
using MediatR;
using EnterpriseAgent.Application.Agents.Commands;
using EnterpriseAgent.Application.Agents.Queries;

namespace EnterpriseAgent.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AgentsController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly ILogger<AgentsController> _logger;

    public AgentsController(IMediator mediator, ILogger<AgentsController> logger)
    {
        _mediator = mediator;
        _logger = logger;
    }

    /// <summary>
    /// Create a new AI agent
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(AgentDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<AgentDto>&gt; CreateAgent(
        [FromBody] CreateAgentCommand command,
        CancellationToken cancellationToken)
    {
        _logger.LogInformation("Creating agent: {AgentName}", command.Name);
        
        var result = await _mediator.Send(command, cancellationToken);
        
        return CreatedAtAction(
            nameof(GetAgent),
            new { id = result.Id },
            result
        );
    }

    /// <summary>
    /// Get agent by ID
    /// </summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(AgentDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<AgentDto>&gt; GetAgent(
        Guid id,
        CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetAgentByIdQuery(id), cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// List all agents
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(IEnumerable<AgentDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<IEnumerable<AgentDto>&gt;&gt; ListAgents(
        [FromQuery] bool? activeOnly = false,
        CancellationToken cancellationToken = default)
    {
        var query = new ListAgentsQuery { ActiveOnly = activeOnly ?? false };
        var result = await _mediator.Send(query, cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// Activate an agent
    /// </summary>
    [HttpPost("{id:guid}/activate")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ActivateAgent(
        Guid id,
        CancellationToken cancellationToken)
    {
        await _mediator.Send(new ActivateAgentCommand(id), cancellationToken);
        return NoContent();
    }

    /// <summary>
    /// Start a conversation with an agent
    /// </summary>
    [HttpPost("{id:guid}/conversations")]
    [ProducesResponseType(typeof(ConversationDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ConversationDto>&gt; StartConversation(
        Guid id,
        [FromBody] StartConversationCommand command,
        CancellationToken cancellationToken)
    {
        command = command with { AgentId = id };
        var result = await _mediator.Send(command, cancellationToken);
        
        return CreatedAtAction(
            nameof(GetConversation),
            new { agentId = id, conversationId = result.Id },
            result
        );
    }

    /// <summary>
    /// Get conversation details
    /// </summary>
    [HttpGet("{agentId:guid}/conversations/{conversationId:guid}")]
    [ProducesResponseType(typeof(ConversationDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ConversationDto>&gt; GetConversation(
        Guid agentId,
        Guid conversationId,
        CancellationToken cancellationToken)
    {
        var query = new GetConversationQuery(agentId, conversationId);
        var result = await _mediator.Send(query, cancellationToken);
        return Ok(result);
    }
}
```

### Step 5: Configure Dependency Injection

Create `API/Program.cs`:
```csharp
using EnterpriseAgent.Application;
using EnterpriseAgent.Infrastructure;
using EnterpriseAgent.API.Middleware;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.Seq(builder.Configuration["Seq:ServerUrl"] ?? "http://localhost:5341")
    .CreateLogger();

builder.Host.UseSerilog();

// Add services
builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =&gt;
{
    c.SwaggerDoc("v1", new() { Title = "Enterprise Agent API", Version = "v1" });
});

// Add health checks
builder.Services.AddHealthChecks()
    .AddDbContextCheck<AgentDbContext>()
    .AddRedis(builder.Configuration.GetConnectionString("Redis"));

var app = builder.Build();

// Configure pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseMiddleware<ErrorHandlingMiddleware>();
app.UseMiddleware<RequestLoggingMiddleware>();

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHealthChecks("/health");

// Initialize database
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<AgentDbContext>();
    await context.Database.MigrateAsync();
}

Log.Information("Enterprise Agent API started");

app.Run();
```

Create `Application/DependencyInjection.cs`:
```csharp
using Microsoft.Extensions.DependencyInjection;
using System.Reflection;
using FluentValidation;
using MediatR;

namespace EnterpriseAgent.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddAutoMapper(Assembly.GetExecutingAssembly());
        services.AddValidatorsFromAssembly(Assembly.GetExecutingAssembly());
        services.AddMediatR(cfg =&gt;
        {
            cfg.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly());
            cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));
            cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(LoggingBehavior<,>));
            cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(PerformanceBehavior<,>));
        });

        return services;
    }
}
```

Create `Infrastructure/DependencyInjection.cs`:
```csharp
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.EntityFrameworkCore;
using EnterpriseAgent.Infrastructure.Persistence;
using EnterpriseAgent.Infrastructure.Services;
using EnterpriseAgent.Application.Common.Interfaces;
using Microsoft.Extensions.Caching.StackExchangeRedis;

namespace EnterpriseAgent.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // Database
        services.AddDbContext<AgentDbContext>(options =&gt;
            options.UseSqlServer(
                configuration.GetConnectionString("DefaultConnection"),
                b =&gt; b.MigrationsAssembly(typeof(AgentDbContext).Assembly.FullName)));

        services.AddScoped<IUnitOfWork>(provider =&gt; provider.GetRequiredService<AgentDbContext>());
        services.AddScoped<IAgentRepository, AgentRepository>();

        // Caching
        services.AddStackExchangeRedisCache(options =&gt;
        {
            options.Configuration = configuration.GetConnectionString("Redis");
            options.InstanceName = "EnterpriseAgent";
        });

        // AI Services
        services.Configure<AzureOpenAIOptions>(configuration.GetSection("AzureOpenAI"));
        services.AddSingleton<IAIService, AzureOpenAIService>();

        // Other services
        services.AddSingleton<IDateTime, DateTimeService>();
        
        return services;
    }
}
```

### Step 6: Create Tests

Create `Tests/Domain/AgentTests.cs`:
```csharp
using Xunit;
using FluentAssertions;
using EnterpriseAgent.Domain.Entities;
using EnterpriseAgent.Domain.ValueObjects;
using EnterpriseAgent.Domain.Events;

namespace EnterpriseAgent.Tests.Domain;

public class AgentTests
{
    [Fact]
    public void Create_ValidParameters_CreatesAgent()
    {
        // Arrange
        var name = "TestAgent";
        var model = "gpt-4";
        var systemPrompt = "You are a helpful assistant.";
        var capabilities = new AgentCapabilities(true, false, false, true);

        // Act
        var agent = Agent.Create(name, model, systemPrompt, capabilities);

        // Assert
        agent.Should().NotBeNull();
        agent.Name.Should().Be(name);
        agent.Model.Should().Be(model);
        agent.SystemPrompt.Should().Be(systemPrompt);
        agent.Status.Should().Be(AgentStatus.Inactive);
        agent.DomainEvents.Should().ContainSingle(e =&gt; e is AgentCreatedEvent);
    }

    [Theory]
    [InlineData("", "gpt-4", "prompt")]
    [InlineData("Agent", "", "prompt")]
    [InlineData("Agent", "gpt-4", null)]
    public void Create_InvalidParameters_ThrowsException(string name, string model, string systemPrompt)
    {
        // Arrange
        var capabilities = new AgentCapabilities(true, false, false, false);

        // Act & Assert
        var act = () =&gt; Agent.Create(name, model, systemPrompt, capabilities);
        act.Should().Throw<ArgumentException>();
    }

    [Fact]
    public void Activate_InactiveAgent_ActivatesAndRaisesEvent()
    {
        // Arrange
        var agent = CreateTestAgent();

        // Act
        agent.Activate();

        // Assert
        agent.Status.Should().Be(AgentStatus.Active);
        agent.DomainEvents.Should().Contain(e =&gt; e is AgentActivatedEvent);
    }

    private Agent CreateTestAgent()
    {
        return Agent.Create(
            "TestAgent",
            "gpt-4",
            "Test system prompt",
            new AgentCapabilities(true, false, false, true)
        );
    }
}
```

## 🏃 Running the Exercício

1. **Build the solution:**
```powershell
dotnet build
```

2. **Run database migrations:**
```powershell
cd EnterpriseAgent.API
dotnet ef database update
```

3. **Run the API:**
```powershell
dotnet run
```

4. **Test the API:**
```bash
# Create an agent
curl -X POST https://localhost:7001/api/agents \
  -H "Content-Type: application/json" \
  -d '{
    "name": "CustomerServiceAgent",
    "model": "gpt-4",
    "systemPrompt": "You are a helpful customer service agent.",
    "capabilities": ["text", "function-calling"]
  }'

# Get agent
curl https://localhost:7001/api/agents/{agent-id}

# Activate agent
curl -X POST https://localhost:7001/api/agents/{agent-id}/activate
```

5. **Run tests:**
```powershell
dotnet test
```

## 🎯 Validation

Your enterprise agent framework should now have:
- ✅ Clean Architecture with proper layer separation
- ✅ Domain-Driven Design with aggregates and value objects
- ✅ CQRS pattern using MediatR
- ✅ Repository pattern with Unit of Work
- ✅ Dependency injection configurado
- ✅ Validation using FluentValidation
- ✅ Basic API endpoints working
- ✅ Domain events published

## 🚀 Bonus Challenges

1. **Add Semantic Kernel Integration:**
   - Integrate Microsoft Semantic Kernel
   - Create skill orchestration
   - Implement memory management

2. **Implement Event Sourcing:**
   - Store all domain events
   - Create event store
   - Implement replay functionality

3. **Add Real-time Features:**
   - Implement SignalR hub
   - Stream conversation responses
   - Real-time agent status updates

4. **Enhanced Security:**
   - Add JWT authentication
   - Implement role-based access
   - Add API rate limiting

## 📚 Additional Recursos

- [Clean Architecture in .NET](https://github.com/ardalis/CleanArchitecture)
- [Domain-Driven Design Fundamentos](https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/)
- [MediatR Documentação](https://github.com/jbogard/MediatR)
- [Semantic Kernel Documentação](https://learn.microsoft.com/semantic-kernel/)

## ⏭️ Próximo Exercício

Ready to add multi-modal capabilities? Move on to [Exercício 2: Multi-Modal Agent System](/docs/modules/module-26/exercise2-overview) where you'll implement voice, vision, and document processing!