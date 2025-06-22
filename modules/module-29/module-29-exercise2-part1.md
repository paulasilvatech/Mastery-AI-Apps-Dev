# Exercise 2: Event-Driven Microservices - Part 1: Service Architecture and Setup

## 🎯 Overview

In this first part, you'll design and set up the microservices architecture, establish service boundaries, configure the messaging infrastructure, and create the foundational shared components for the distributed system.

## 📋 Part 1 Objectives

- Design service boundaries using Domain-Driven Design
- Set up the solution structure for microservices
- Configure messaging infrastructure with MassTransit
- Create shared contracts and events
- Implement base classes for event sourcing
- Set up development environment with Docker

## 🏗️ Step 1: Create Solution Structure

### 1.1 Create the Solution

```bash
# Create solution directory
mkdir EcommerceMicroservices
cd EcommerceMicroservices

# Create solution
dotnet new sln -n Microservices

# Create directory structure
mkdir -p src/Services/{Order,Inventory,Payment,Shipping,Notification}
mkdir -p src/Shared/{Contracts,Infrastructure,Domain}
mkdir -p src/ApiGateway
mkdir -p tests/{Unit,Integration,Chaos}
mkdir -p infrastructure/{docker,k8s,scripts}
```

### 1.2 Create Shared Projects

```bash
# Shared Contracts - Events and Commands
cd src/Shared/Contracts
dotnet new classlib -n Ecommerce.Shared.Contracts
cd ../../..
dotnet sln add src/Shared/Contracts/Ecommerce.Shared.Contracts.csproj

# Shared Infrastructure - Base classes and utilities
cd src/Shared/Infrastructure
dotnet new classlib -n Ecommerce.Shared.Infrastructure
cd ../../..
dotnet sln add src/Shared/Infrastructure/Ecommerce.Shared.Infrastructure.csproj

# Shared Domain - Common domain concepts
cd src/Shared/Domain
dotnet new classlib -n Ecommerce.Shared.Domain
cd ../../..
dotnet sln add src/Shared/Domain/Ecommerce.Shared.Domain.csproj
```

### 1.3 Install Shared Dependencies

```bash
# Contracts project
cd src/Shared/Contracts
dotnet add package MassTransit.Abstractions

# Infrastructure project
cd ../Infrastructure
dotnet add package MassTransit
dotnet add package MassTransit.Azure.ServiceBus.Core
dotnet add package Microsoft.Extensions.Hosting
dotnet add package Polly
dotnet add package Serilog.AspNetCore
dotnet add package OpenTelemetry.Instrumentation.AspNetCore
dotnet add package MongoDB.Driver  # For event store

# Domain project
cd ../Domain
dotnet add package MediatR
dotnet add package FluentValidation

cd ../../..
```

## 📦 Step 2: Define Shared Contracts

### 2.1 Create Base Event Types

Create `src/Shared/Contracts/Events/IEvent.cs`:

```csharp
namespace Ecommerce.Shared.Contracts.Events;

public interface IEvent
{
    Guid EventId { get; }
    DateTime OccurredAt { get; }
    string EventType { get; }
    int Version { get; }
}

public interface IDomainEvent : IEvent
{
    Guid AggregateId { get; }
    long AggregateVersion { get; }
}

public interface IIntegrationEvent : IEvent
{
    Guid CorrelationId { get; }
    string Source { get; }
}

public abstract class BaseEvent : IEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTime OccurredAt { get; } = DateTime.UtcNow;
    public virtual string EventType => GetType().Name;
    public virtual int Version => 1;
}

public abstract class DomainEvent : BaseEvent, IDomainEvent
{
    public Guid AggregateId { get; protected set; }
    public long AggregateVersion { get; protected set; }

    protected DomainEvent(Guid aggregateId, long aggregateVersion)
    {
        AggregateId = aggregateId;
        AggregateVersion = aggregateVersion;
    }
}

public abstract class IntegrationEvent : BaseEvent, IIntegrationEvent
{
    public Guid CorrelationId { get; protected set; }
    public string Source { get; protected set; }

    protected IntegrationEvent(Guid correlationId, string source)
    {
        CorrelationId = correlationId;
        Source = source;
    }
}
```

### 2.2 Define Order Events

Create `src/Shared/Contracts/Events/OrderEvents.cs`:

```csharp
namespace Ecommerce.Shared.Contracts.Events;

// Order Domain Events
public record OrderCreated : DomainEvent
{
    public Guid CustomerId { get; init; }
    public List<OrderItem> Items { get; init; }
    public decimal TotalAmount { get; init; }
    public Address ShippingAddress { get; init; }
    public PaymentMethod PaymentMethod { get; init; }

    public OrderCreated(
        Guid orderId,
        long version,
        Guid customerId,
        List<OrderItem> items,
        decimal totalAmount,
        Address shippingAddress,
        PaymentMethod paymentMethod) : base(orderId, version)
    {
        CustomerId = customerId;
        Items = items;
        TotalAmount = totalAmount;
        ShippingAddress = shippingAddress;
        PaymentMethod = paymentMethod;
    }
}

public record OrderConfirmed : DomainEvent
{
    public string ConfirmationNumber { get; init; }
    
    public OrderConfirmed(Guid orderId, long version, string confirmationNumber) 
        : base(orderId, version)
    {
        ConfirmationNumber = confirmationNumber;
    }
}

public record OrderCancelled : DomainEvent
{
    public string Reason { get; init; }
    public string? RefundId { get; init; }
    
    public OrderCancelled(Guid orderId, long version, string reason, string? refundId = null) 
        : base(orderId, version)
    {
        Reason = reason;
        RefundId = refundId;
    }
}

// Order Integration Events
public record OrderSubmitted : IntegrationEvent
{
    public Guid OrderId { get; init; }
    public Guid CustomerId { get; init; }
    public List<OrderItem> Items { get; init; }
    public decimal TotalAmount { get; init; }
    public Address ShippingAddress { get; init; }
    public PaymentMethod PaymentMethod { get; init; }

    public OrderSubmitted(
        Guid correlationId,
        Guid orderId,
        Guid customerId,
        List<OrderItem> items,
        decimal totalAmount,
        Address shippingAddress,
        PaymentMethod paymentMethod) : base(correlationId, "OrderService")
    {
        OrderId = orderId;
        CustomerId = customerId;
        Items = items;
        TotalAmount = totalAmount;
        ShippingAddress = shippingAddress;
        PaymentMethod = paymentMethod;
    }
}

// Value Objects
public record OrderItem(
    Guid ProductId,
    string ProductName,
    string SKU,
    int Quantity,
    decimal UnitPrice,
    decimal TotalPrice);

public record Address(
    string Street,
    string City,
    string State,
    string PostalCode,
    string Country);

public record PaymentMethod(
    string Type,
    string Last4Digits,
    string? Token);
```

### 2.3 Define Inventory Events

Create `src/Shared/Contracts/Events/InventoryEvents.cs`:

```csharp
namespace Ecommerce.Shared.Contracts.Events;

public record InventoryReserved : IntegrationEvent
{
    public Guid OrderId { get; init; }
    public List<ReservedItem> ReservedItems { get; init; }
    public DateTime ExpiresAt { get; init; }

    public InventoryReserved(
        Guid correlationId,
        Guid orderId,
        List<ReservedItem> reservedItems,
        DateTime expiresAt) : base(correlationId, "InventoryService")
    {
        OrderId = orderId;
        ReservedItems = reservedItems;
        ExpiresAt = expiresAt;
    }
}

public record InventoryReservationFailed : IntegrationEvent
{
    public Guid OrderId { get; init; }
    public List<OutOfStockItem> OutOfStockItems { get; init; }
    public string Reason { get; init; }

    public InventoryReservationFailed(
        Guid correlationId,
        Guid orderId,
        List<OutOfStockItem> outOfStockItems,
        string reason) : base(correlationId, "InventoryService")
    {
        OrderId = orderId;
        OutOfStockItems = outOfStockItems;
        Reason = reason;
    }
}

public record InventoryReleased : IntegrationEvent
{
    public Guid OrderId { get; init; }
    public List<Guid> ProductIds { get; init; }

    public InventoryReleased(
        Guid correlationId,
        Guid orderId,
        List<Guid> productIds) : base(correlationId, "InventoryService")
    {
        OrderId = orderId;
        ProductIds = productIds;
    }
}

public record ReservedItem(
    Guid ProductId,
    string SKU,
    int Quantity,
    Guid ReservationId);

public record OutOfStockItem(
    Guid ProductId,
    string SKU,
    int RequestedQuantity,
    int AvailableQuantity);
```

### 2.4 Define Payment Events

Create `src/Shared/Contracts/Events/PaymentEvents.cs`:

```csharp
namespace Ecommerce.Shared.Contracts.Events;

public record PaymentProcessed : IntegrationEvent
{
    public Guid OrderId { get; init; }
    public string TransactionId { get; init; }
    public decimal Amount { get; init; }
    public string Currency { get; init; }
    public DateTime ProcessedAt { get; init; }

    public PaymentProcessed(
        Guid correlationId,
        Guid orderId,
        string transactionId,
        decimal amount,
        string currency) : base(correlationId, "PaymentService")
    {
        OrderId = orderId;
        TransactionId = transactionId;
        Amount = amount;
        Currency = currency;
        ProcessedAt = DateTime.UtcNow;
    }
}

public record PaymentFailed : IntegrationEvent
{
    public Guid OrderId { get; init; }
    public string Reason { get; init; }
    public string? ErrorCode { get; init; }
    public bool IsRetryable { get; init; }

    public PaymentFailed(
        Guid correlationId,
        Guid orderId,
        string reason,
        string? errorCode = null,
        bool isRetryable = false) : base(correlationId, "PaymentService")
    {
        OrderId = orderId;
        Reason = reason;
        ErrorCode = errorCode;
        IsRetryable = isRetryable;
    }
}

public record PaymentRefunded : IntegrationEvent
{
    public Guid OrderId { get; init; }
    public string RefundId { get; init; }
    public decimal Amount { get; init; }
    public string Reason { get; init; }

    public PaymentRefunded(
        Guid correlationId,
        Guid orderId,
        string refundId,
        decimal amount,
        string reason) : base(correlationId, "PaymentService")
    {
        OrderId = orderId;
        RefundId = refundId;
        Amount = amount;
        Reason = reason;
    }
}
```

## 🏛️ Step 3: Create Event Sourcing Infrastructure

### 3.1 Create Event Store Interface

Create `src/Shared/Infrastructure/EventStore/IEventStore.cs`:

```csharp
namespace Ecommerce.Shared.Infrastructure.EventStore;

public interface IEventStore
{
    Task<IEnumerable<IDomainEvent>> GetEventsAsync(
        Guid aggregateId,
        long fromVersion = 0,
        CancellationToken cancellationToken = default);
        
    Task<long> AppendEventsAsync(
        Guid aggregateId,
        long expectedVersion,
        IEnumerable<IDomainEvent> events,
        CancellationToken cancellationToken = default);
        
    Task<IEnumerable<IDomainEvent>> GetEventsAsync(
        DateTime from,
        DateTime to,
        CancellationToken cancellationToken = default);
        
    IAsyncEnumerable<IDomainEvent> SubscribeToStream(
        string streamName,
        CancellationToken cancellationToken = default);
}

public class OptimisticConcurrencyException : Exception
{
    public Guid AggregateId { get; }
    public long ExpectedVersion { get; }
    public long ActualVersion { get; }

    public OptimisticConcurrencyException(
        Guid aggregateId,
        long expectedVersion,
        long actualVersion)
        : base($"Expected version {expectedVersion} but was {actualVersion} for aggregate {aggregateId}")
    {
        AggregateId = aggregateId;
        ExpectedVersion = expectedVersion;
        ActualVersion = actualVersion;
    }
}
```

### 3.2 Implement MongoDB Event Store

Create `src/Shared/Infrastructure/EventStore/MongoEventStore.cs`:

```csharp
namespace Ecommerce.Shared.Infrastructure.EventStore;

public class MongoEventStore : IEventStore
{
    private readonly IMongoCollection<EventDocument> _events;
    private readonly ILogger<MongoEventStore> _logger;

    public MongoEventStore(
        IMongoDatabase database,
        ILogger<MongoEventStore> logger)
    {
        _events = database.GetCollection<EventDocument>("events");
        _logger = logger;
        
        // Create indexes
        CreateIndexes();
    }

    private void CreateIndexes()
    {
        var aggregateIndex = Builders<EventDocument>.IndexKeys
            .Ascending(e => e.AggregateId)
            .Ascending(e => e.AggregateVersion);
            
        var timestampIndex = Builders<EventDocument>.IndexKeys
            .Ascending(e => e.Timestamp);
            
        _events.Indexes.CreateMany(new[]
        {
            new CreateIndexModel<EventDocument>(aggregateIndex),
            new CreateIndexModel<EventDocument>(timestampIndex)
        });
    }

    public async Task<IEnumerable<IDomainEvent>> GetEventsAsync(
        Guid aggregateId,
        long fromVersion = 0,
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<EventDocument>.Filter.And(
            Builders<EventDocument>.Filter.Eq(e => e.AggregateId, aggregateId),
            Builders<EventDocument>.Filter.Gte(e => e.AggregateVersion, fromVersion)
        );

        var documents = await _events
            .Find(filter)
            .SortBy(e => e.AggregateVersion)
            .ToListAsync(cancellationToken);

        return documents.Select(d => d.ToDomainEvent());
    }

    public async Task<long> AppendEventsAsync(
        Guid aggregateId,
        long expectedVersion,
        IEnumerable<IDomainEvent> events,
        CancellationToken cancellationToken = default)
    {
        var session = await _events.Database.Client.StartSessionAsync(cancellationToken: cancellationToken);
        
        try
        {
            return await session.WithTransactionAsync(async (s, ct) =>
            {
                // Check current version
                var currentVersion = await GetCurrentVersionAsync(aggregateId, s, ct);
                
                if (currentVersion != expectedVersion)
                {
                    throw new OptimisticConcurrencyException(aggregateId, expectedVersion, currentVersion);
                }

                // Append events
                var eventDocuments = events.Select(e => EventDocument.FromDomainEvent(e)).ToList();
                
                if (eventDocuments.Any())
                {
                    await _events.InsertManyAsync(s, eventDocuments, cancellationToken: ct);
                }

                return currentVersion + eventDocuments.Count;
            }, cancellationToken: cancellationToken);
        }
        finally
        {
            session.Dispose();
        }
    }

    private async Task<long> GetCurrentVersionAsync(
        Guid aggregateId,
        IClientSessionHandle session,
        CancellationToken cancellationToken)
    {
        var filter = Builders<EventDocument>.Filter.Eq(e => e.AggregateId, aggregateId);
        var sort = Builders<EventDocument>.Sort.Descending(e => e.AggregateVersion);
        
        var lastEvent = await _events
            .Find(session, filter)
            .Sort(sort)
            .FirstOrDefaultAsync(cancellationToken);

        return lastEvent?.AggregateVersion ?? 0;
    }

    public async Task<IEnumerable<IDomainEvent>> GetEventsAsync(
        DateTime from,
        DateTime to,
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<EventDocument>.Filter.And(
            Builders<EventDocument>.Filter.Gte(e => e.Timestamp, from),
            Builders<EventDocument>.Filter.Lte(e => e.Timestamp, to)
        );

        var documents = await _events
            .Find(filter)
            .SortBy(e => e.Timestamp)
            .ToListAsync(cancellationToken);

        return documents.Select(d => d.ToDomainEvent());
    }

    public async IAsyncEnumerable<IDomainEvent> SubscribeToStream(
        string streamName,
        [EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        var options = new ChangeStreamOptions
        {
            FullDocument = ChangeStreamFullDocumentOption.UpdateLookup,
            StartAfter = null
        };

        using var cursor = await _events.WatchAsync(options, cancellationToken);
        
        await foreach (var change in cursor.ToAsyncEnumerable(cancellationToken))
        {
            if (change.OperationType == ChangeStreamOperationType.Insert)
            {
                yield return change.FullDocument.ToDomainEvent();
            }
        }
    }
}

// Event document for MongoDB
public class EventDocument
{
    public ObjectId Id { get; set; }
    public Guid EventId { get; set; }
    public Guid AggregateId { get; set; }
    public long AggregateVersion { get; set; }
    public string EventType { get; set; } = null!;
    public string EventData { get; set; } = null!;
    public DateTime Timestamp { get; set; }
    public Dictionary<string, object> Metadata { get; set; } = new();

    public static EventDocument FromDomainEvent(IDomainEvent domainEvent)
    {
        return new EventDocument
        {
            EventId = domainEvent.EventId,
            AggregateId = domainEvent.AggregateId,
            AggregateVersion = domainEvent.AggregateVersion,
            EventType = domainEvent.EventType,
            EventData = JsonSerializer.Serialize(domainEvent),
            Timestamp = domainEvent.OccurredAt,
            Metadata = new Dictionary<string, object>
            {
                ["Version"] = domainEvent.Version,
                ["Source"] = Environment.MachineName
            }
        };
    }

    public IDomainEvent ToDomainEvent()
    {
        var type = Type.GetType(EventType) ?? 
            throw new InvalidOperationException($"Event type {EventType} not found");
            
        return (IDomainEvent)JsonSerializer.Deserialize(EventData, type)!;
    }
}
```

### 3.3 Create Aggregate Root Base Class

Create `src/Shared/Infrastructure/Domain/AggregateRoot.cs`:

```csharp
namespace Ecommerce.Shared.Infrastructure.Domain;

public abstract class AggregateRoot
{
    private readonly List<IDomainEvent> _uncommittedEvents = new();
    private readonly Dictionary<Type, Action<IDomainEvent>> _eventHandlers = new();

    public Guid Id { get; protected set; }
    public long Version { get; protected set; }
    public DateTime CreatedAt { get; protected set; }
    public DateTime? UpdatedAt { get; protected set; }

    public IReadOnlyList<IDomainEvent> UncommittedEvents => _uncommittedEvents.AsReadOnly();

    protected AggregateRoot()
    {
        RegisterEventHandlers();
    }

    protected abstract void RegisterEventHandlers();

    protected void RegisterEventHandler<TEvent>(Action<TEvent> handler) 
        where TEvent : IDomainEvent
    {
        _eventHandlers[typeof(TEvent)] = e => handler((TEvent)e);
    }

    protected void RaiseEvent(IDomainEvent @event)
    {
        ApplyEvent(@event);
        _uncommittedEvents.Add(@event);
    }

    private void ApplyEvent(IDomainEvent @event)
    {
        if (_eventHandlers.TryGetValue(@event.GetType(), out var handler))
        {
            handler(@event);
            Version = @event.AggregateVersion;
            UpdatedAt = @event.OccurredAt;
        }
        else
        {
            throw new InvalidOperationException(
                $"No handler registered for event type {@event.GetType().Name}");
        }
    }

    public void LoadFromHistory(IEnumerable<IDomainEvent> events)
    {
        foreach (var @event in events.OrderBy(e => e.AggregateVersion))
        {
            ApplyEvent(@event);
        }
    }

    public void MarkEventsAsCommitted()
    {
        _uncommittedEvents.Clear();
    }

    public bool HasUncommittedEvents => _uncommittedEvents.Any();
}

// Repository for event-sourced aggregates
public interface IEventSourcedRepository<T> where T : AggregateRoot
{
    Task<T?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task SaveAsync(T aggregate, CancellationToken cancellationToken = default);
}

public class EventSourcedRepository<T> : IEventSourcedRepository<T> 
    where T : AggregateRoot, new()
{
    private readonly IEventStore _eventStore;
    private readonly ILogger<EventSourcedRepository<T>> _logger;

    public EventSourcedRepository(
        IEventStore eventStore,
        ILogger<EventSourcedRepository<T>> logger)
    {
        _eventStore = eventStore;
        _logger = logger;
    }

    public async Task<T?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var events = await _eventStore.GetEventsAsync(id, cancellationToken: cancellationToken);
        
        if (!events.Any())
            return null;

        var aggregate = new T();
        aggregate.LoadFromHistory(events);
        
        return aggregate;
    }

    public async Task SaveAsync(T aggregate, CancellationToken cancellationToken = default)
    {
        if (!aggregate.HasUncommittedEvents)
            return;

        try
        {
            var expectedVersion = aggregate.Version - aggregate.UncommittedEvents.Count;
            
            await _eventStore.AppendEventsAsync(
                aggregate.Id,
                expectedVersion,
                aggregate.UncommittedEvents,
                cancellationToken);

            aggregate.MarkEventsAsCommitted();
            
            _logger.LogInformation(
                "Saved {EventCount} events for aggregate {AggregateType} {AggregateId}",
                aggregate.UncommittedEvents.Count,
                typeof(T).Name,
                aggregate.Id);
        }
        catch (OptimisticConcurrencyException ex)
        {
            _logger.LogWarning(ex,
                "Concurrency conflict for aggregate {AggregateId}",
                aggregate.Id);
            throw;
        }
    }
}
```

## 🚌 Step 4: Configure Service Bus Infrastructure

### 4.1 Create MassTransit Configuration

Create `src/Shared/Infrastructure/Messaging/ServiceBusConfiguration.cs`:

```csharp
namespace Ecommerce.Shared.Infrastructure.Messaging;

public static class ServiceBusConfiguration
{
    public static IServiceCollection AddServiceBus(
        this IServiceCollection services,
        IConfiguration configuration,
        Action<IBusRegistrationConfigurator>? configure = null)
    {
        services.AddMassTransit(x =>
        {
            x.SetKebabCaseEndpointNameFormatter();

            // Configure consumers
            configure?.Invoke(x);

            // Configure Azure Service Bus
            x.UsingAzureServiceBus((context, cfg) =>
            {
                cfg.Host(configuration["ServiceBus:ConnectionString"]);

                // Configure error handling
                cfg.UseMessageRetry(retry =>
                {
                    retry.Exponential(5,
                        TimeSpan.FromSeconds(1),
                        TimeSpan.FromSeconds(30),
                        TimeSpan.FromSeconds(3));
                });

                // Configure circuit breaker
                cfg.UseCircuitBreaker(cb =>
                {
                    cb.TrackingPeriod = TimeSpan.FromMinutes(1);
                    cb.TripThreshold = 15;
                    cb.ActiveThreshold = 10;
                    cb.ResetInterval = TimeSpan.FromMinutes(5);
                });

                // Configure timeout
                cfg.UseTimeout(t => t.Timeout = TimeSpan.FromSeconds(30));

                // Configure endpoints
                cfg.ConfigureEndpoints(context);
            });
        });

        // Add health checks
        services.AddHealthChecks()
            .AddAzureServiceBusTopic(
                configuration["ServiceBus:ConnectionString"],
                "order-events",
                name: "servicebus");

        return services;
    }
}

// Correlation context for distributed tracing
public interface ICorrelationContext
{
    Guid CorrelationId { get; }
    string? UserId { get; }
    string? TenantId { get; }
    Dictionary<string, string> Headers { get; }
}

public class CorrelationContext : ICorrelationContext
{
    public Guid CorrelationId { get; set; }
    public string? UserId { get; set; }
    public string? TenantId { get; set; }
    public Dictionary<string, string> Headers { get; set; } = new();
}

// Message correlation filter
public class CorrelationIdFilter<T> : IFilter<ConsumeContext<T>> where T : class
{
    private readonly ILogger<CorrelationIdFilter<T>> _logger;

    public CorrelationIdFilter(ILogger<CorrelationIdFilter<T>> logger)
    {
        _logger = logger;
    }

    public async Task Send(ConsumeContext<T> context, IPipe<ConsumeContext<T>> next)
    {
        var correlationId = context.CorrelationId ?? NewId.NextGuid();
        
        using (_logger.BeginScope(new Dictionary<string, object>
        {
            ["CorrelationId"] = correlationId,
            ["MessageType"] = typeof(T).Name
        }))
        {
            _logger.LogInformation(
                "Processing message {MessageType} with correlation {CorrelationId}",
                typeof(T).Name,
                correlationId);

            await next.Send(context);
        }
    }

    public void Probe(ProbeContext context)
    {
        context.CreateFilterScope("correlationId");
    }
}
```

### 4.2 Create Saga Base Class

Create `src/Shared/Infrastructure/Sagas/SagaBase.cs`:

```csharp
namespace Ecommerce.Shared.Infrastructure.Sagas;

public abstract class SagaBase : ISaga
{
    public Guid CorrelationId { get; set; }
    public string CurrentState { get; set; } = null!;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int Version { get; set; }
    
    protected SagaBase()
    {
        CreatedAt = DateTime.UtcNow;
    }

    protected void UpdateState(string newState)
    {
        CurrentState = newState;
        UpdatedAt = DateTime.UtcNow;
        Version++;
    }
}

// Saga persistence
public interface ISagaRepository<TSaga> where TSaga : ISaga
{
    Task<TSaga?> GetAsync(Guid correlationId, CancellationToken cancellationToken = default);
    Task CreateAsync(TSaga saga, CancellationToken cancellationToken = default);
    Task UpdateAsync(TSaga saga, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid correlationId, CancellationToken cancellationToken = default);
}

// MongoDB saga repository
public class MongoSagaRepository<TSaga> : ISagaRepository<TSaga> 
    where TSaga : ISaga, new()
{
    private readonly IMongoCollection<TSaga> _collection;
    private readonly ILogger<MongoSagaRepository<TSaga>> _logger;

    public MongoSagaRepository(
        IMongoDatabase database,
        ILogger<MongoSagaRepository<TSaga>> logger)
    {
        var collectionName = $"{typeof(TSaga).Name.ToLower()}s";
        _collection = database.GetCollection<TSaga>(collectionName);
        _logger = logger;
        
        // Create index on CorrelationId
        var indexKeys = Builders<TSaga>.IndexKeys.Ascending(s => s.CorrelationId);
        _collection.Indexes.CreateOne(new CreateIndexModel<TSaga>(indexKeys));
    }

    public async Task<TSaga?> GetAsync(
        Guid correlationId, 
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<TSaga>.Filter.Eq(s => s.CorrelationId, correlationId);
        return await _collection.Find(filter).FirstOrDefaultAsync(cancellationToken);
    }

    public async Task CreateAsync(
        TSaga saga, 
        CancellationToken cancellationToken = default)
    {
        await _collection.InsertOneAsync(saga, cancellationToken: cancellationToken);
        
        _logger.LogInformation(
            "Created saga {SagaType} with correlation {CorrelationId}",
            typeof(TSaga).Name,
            saga.CorrelationId);
    }

    public async Task UpdateAsync(
        TSaga saga, 
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<TSaga>.Filter.Eq(s => s.CorrelationId, saga.CorrelationId);
        var result = await _collection.ReplaceOneAsync(
            filter, 
            saga, 
            new ReplaceOptions { IsUpsert = false },
            cancellationToken);

        if (result.ModifiedCount == 0)
        {
            throw new InvalidOperationException(
                $"Saga {saga.CorrelationId} not found for update");
        }

        _logger.LogInformation(
            "Updated saga {SagaType} with correlation {CorrelationId}",
            typeof(TSaga).Name,
            saga.CorrelationId);
    }

    public async Task DeleteAsync(
        Guid correlationId, 
        CancellationToken cancellationToken = default)
    {
        var filter = Builders<TSaga>.Filter.Eq(s => s.CorrelationId, correlationId);
        await _collection.DeleteOneAsync(filter, cancellationToken);
        
        _logger.LogInformation(
            "Deleted saga {SagaType} with correlation {CorrelationId}",
            typeof(TSaga).Name,
            correlationId);
    }
}
```

## 🐳 Step 5: Create Docker Development Environment

### 5.1 Create Docker Compose File

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  # SQL Server for service databases
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    environment:
      ACCEPT_EULA: 'Y'
      SA_PASSWORD: 'YourStrong@Passw0rd'
      MSSQL_PID: 'Developer'
    ports:
      - '1433:1433'
    volumes:
      - sqlserver_data:/var/opt/mssql
    networks:
      - microservices

  # MongoDB for event store and sagas
  mongodb:
    image: mongo:6
    ports:
      - '27017:27017'
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: password
    volumes:
      - mongodb_data:/data/db
    networks:
      - microservices

  # Redis for caching and pub/sub
  redis:
    image: redis:alpine
    ports:
      - '6379:6379'
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - microservices

  # Azure Service Bus Emulator (or use Kafka/RabbitMQ for local)
  rabbitmq:
    image: rabbitmq:3-management
    ports:
      - '5672:5672'
      - '15672:15672'
    environment:
      RABBITMQ_DEFAULT_USER: guest
      RABBITMQ_DEFAULT_PASS: guest
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    networks:
      - microservices

  # Seq for centralized logging
  seq:
    image: datalust/seq:latest
    ports:
      - '5341:80'
    environment:
      ACCEPT_EULA: 'Y'
    volumes:
      - seq_data:/data
    networks:
      - microservices

  # Jaeger for distributed tracing
  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - '5775:5775/udp'
      - '6831:6831/udp'
      - '6832:6832/udp'
      - '5778:5778'
      - '16686:16686'
      - '14250:14250'
      - '14268:14268'
      - '14269:14269'
      - '4317:4317'
      - '4318:4318'
      - '9411:9411'
    environment:
      COLLECTOR_OTLP_ENABLED: 'true'
    networks:
      - microservices

volumes:
  sqlserver_data:
  mongodb_data:
  redis_data:
  rabbitmq_data:
  seq_data:

networks:
  microservices:
    driver: bridge
```

### 5.2 Create Development Configuration

Create `docker-compose.override.yml`:

```yaml
version: '3.8'

services:
  # Order Service
  order-service:
    build:
      context: .
      dockerfile: src/Services/Order/Dockerfile
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ConnectionStrings__DefaultConnection=Server=sqlserver;Database=OrderDB;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True
      - ConnectionStrings__EventStore=mongodb://admin:password@mongodb:27017/event-store?authSource=admin
      - ServiceBus__ConnectionString=amqp://guest:guest@rabbitmq:5672
      - Logging__Seq__ServerUrl=http://seq
      - Jaeger__AgentHost=jaeger
      - Jaeger__AgentPort=6831
    ports:
      - '5001:80'
    depends_on:
      - sqlserver
      - mongodb
      - rabbitmq
      - seq
      - jaeger
    networks:
      - microservices

  # Inventory Service
  inventory-service:
    build:
      context: .
      dockerfile: src/Services/Inventory/Dockerfile
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ConnectionStrings__DefaultConnection=Server=sqlserver;Database=InventoryDB;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True
      - ServiceBus__ConnectionString=amqp://guest:guest@rabbitmq:5672
      - Redis__ConnectionString=redis:6379
      - Logging__Seq__ServerUrl=http://seq
      - Jaeger__AgentHost=jaeger
      - Jaeger__AgentPort=6831
    ports:
      - '5002:80'
    depends_on:
      - sqlserver
      - redis
      - rabbitmq
      - seq
      - jaeger
    networks:
      - microservices

  # Payment Service
  payment-service:
    build:
      context: .
      dockerfile: src/Services/Payment/Dockerfile
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ConnectionStrings__DefaultConnection=Server=sqlserver;Database=PaymentDB;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True
      - ServiceBus__ConnectionString=amqp://guest:guest@rabbitmq:5672
      - Logging__Seq__ServerUrl=http://seq
      - Jaeger__AgentHost=jaeger
      - Jaeger__AgentPort=6831
    ports:
      - '5003:80'
    depends_on:
      - sqlserver
      - rabbitmq
      - seq
      - jaeger
    networks:
      - microservices

  # Shipping Service
  shipping-service:
    build:
      context: .
      dockerfile: src/Services/Shipping/Dockerfile
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ConnectionStrings__DefaultConnection=Server=sqlserver;Database=ShippingDB;User Id=sa;Password=YourStrong@Passw0rd;TrustServerCertificate=True
      - ServiceBus__ConnectionString=amqp://guest:guest@rabbitmq:5672
      - Logging__Seq__ServerUrl=http://seq
      - Jaeger__AgentHost=jaeger
      - Jaeger__AgentPort=6831
    ports:
      - '5004:80'
    depends_on:
      - sqlserver
      - rabbitmq
      - seq
      - jaeger
    networks:
      - microservices

  # API Gateway
  api-gateway:
    build:
      context: .
      dockerfile: src/ApiGateway/Dockerfile
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ReverseProxy__Clusters__order__Destinations__destination1__Address=http://order-service
      - ReverseProxy__Clusters__inventory__Destinations__destination1__Address=http://inventory-service
      - ReverseProxy__Clusters__payment__Destinations__destination1__Address=http://payment-service
      - ReverseProxy__Clusters__shipping__Destinations__destination1__Address=http://shipping-service
      - Logging__Seq__ServerUrl=http://seq
    ports:
      - '5000:80'
    depends_on:
      - order-service
      - inventory-service
      - payment-service
      - shipping-service
    networks:
      - microservices
```

### 5.3 Create Local Setup Script

Create `infrastructure/scripts/setup-local.ps1`:

```powershell
# Setup script for local development
Write-Host "Setting up microservices development environment..." -ForegroundColor Green

# Check Docker
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Docker is not installed. Please install Docker Desktop." -ForegroundColor Red
    exit 1
}

# Start infrastructure
Write-Host "Starting infrastructure services..." -ForegroundColor Yellow
docker-compose up -d sqlserver mongodb redis rabbitmq seq jaeger

# Wait for services to be ready
Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Create databases
Write-Host "Creating databases..." -ForegroundColor Yellow
$databases = @("OrderDB", "InventoryDB", "PaymentDB", "ShippingDB", "NotificationDB")

foreach ($db in $databases) {
    docker exec sqlserver /opt/mssql-tools/bin/sqlcmd `
        -S localhost -U sa -P "YourStrong@Passw0rd" `
        -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = '$db') CREATE DATABASE $db"
    
    Write-Host "Created database: $db" -ForegroundColor Green
}

# Create MongoDB databases and collections
Write-Host "Setting up MongoDB..." -ForegroundColor Yellow
docker exec mongodb mongosh --eval "
    use event-store;
    db.createCollection('events');
    db.events.createIndex({ aggregateId: 1, aggregateVersion: 1 });
    db.events.createIndex({ timestamp: 1 });
    
    use saga-store;
    db.createCollection('orderSagas');
    db.orderSagas.createIndex({ correlationId: 1 });
" --username admin --password password --authenticationDatabase admin

Write-Host "Setup complete!" -ForegroundColor Green
Write-Host "Services available at:" -ForegroundColor Cyan
Write-Host "  - RabbitMQ Management: http://localhost:15672 (guest/guest)" -ForegroundColor White
Write-Host "  - Seq Logging: http://localhost:5341" -ForegroundColor White
Write-Host "  - Jaeger Tracing: http://localhost:16686" -ForegroundColor White
Write-Host "  - API Gateway: http://localhost:5000" -ForegroundColor White
```

## 💡 Copilot Prompt Suggestions

**For Event Sourcing Implementation:**
```
Create an Order aggregate root that:
- Inherits from AggregateRoot base class
- Handles OrderCreated, OrderConfirmed, OrderCancelled events
- Implements business rules for order state transitions
- Includes validation for each operation
- Maintains internal state through event sourcing
Include all event handlers and business methods
```

**For Saga Implementation:**
```
Create an OrderSaga using MassTransit that:
- Orchestrates order processing workflow
- Handles all success and failure scenarios
- Implements compensating transactions
- Manages timeouts for each step
- Logs state transitions
Include all state machine configuration
```

**For Service Configuration:**
```
Create a base microservice configuration that:
- Sets up Serilog with Seq sink
- Configures OpenTelemetry with Jaeger
- Adds health checks for all dependencies
- Implements Polly resilience policies
- Configures MassTransit with retry and circuit breaker
Make it reusable across all services
```

## ✅ Part 1 Checklist

Before moving to Part 2, ensure you have:

- [ ] Created solution structure with all projects
- [ ] Defined shared event contracts
- [ ] Implemented event sourcing infrastructure
- [ ] Created aggregate root base class
- [ ] Configured MassTransit service bus
- [ ] Set up Docker development environment
- [ ] Created MongoDB event store
- [ ] Implemented saga base classes
- [ ] Configured logging and tracing

## 🎯 Part 1 Summary

You've successfully:
- Designed service boundaries for the microservices system
- Created a robust event sourcing infrastructure
- Set up messaging with MassTransit and Service Bus
- Configured development environment with Docker
- Established shared contracts for service communication

## ⏭️ Next Steps

Continue to [Part 2: Core Services Implementation](part2-implementation.md) where you'll:
- Implement the Order Service with event sourcing
- Build the Inventory Service with projections
- Create the Payment Service with external integration
- Develop the Shipping Service
- Add the Notification Service

---

**🏆 Achievement**: You've built the foundation for a production-grade microservices system! The infrastructure you've created can handle millions of events and support complex distributed workflows.