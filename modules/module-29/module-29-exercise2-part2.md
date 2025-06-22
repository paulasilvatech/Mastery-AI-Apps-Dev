# Exercise 2: Event-Driven Microservices - Part 2: Core Services Implementation

## 🎯 Overview

In this part, you'll implement the core microservices: Order, Inventory, Payment, Shipping, and Notification services. Each service will have its own bounded context, database, and will communicate through events.

## 📋 Part 2 Objectives

- Implement Order Service with event sourcing
- Build Inventory Service with CQRS and projections
- Create Payment Service with external gateway integration
- Develop Shipping Service with provider abstraction
- Add Notification Service with multi-channel support
- Implement health checks and monitoring

## 🛍️ Step 1: Implement Order Service

### 1.1 Create Order Service Project

```bash
cd src/Services/Order
dotnet new webapi -n Ecommerce.Order.API
cd ../../..
dotnet sln add src/Services/Order/Ecommerce.Order.API.csproj

# Add references
cd src/Services/Order
dotnet add reference ../../Shared/Contracts/Ecommerce.Shared.Contracts.csproj
dotnet add reference ../../Shared/Infrastructure/Ecommerce.Shared.Infrastructure.csproj

# Add packages
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package MongoDB.Driver
cd ../../..
```

### 1.2 Create Order Aggregate

Create `src/Services/Order/Domain/Order.cs`:

```csharp
namespace Ecommerce.Order.Domain;

public class Order : AggregateRoot
{
    private List<OrderItem> _items = new();
    private OrderStatus _status;
    private Guid _customerId;
    private decimal _totalAmount;
    private Address? _shippingAddress;
    private PaymentMethod? _paymentMethod;
    private string? _confirmationNumber;
    private string? _cancellationReason;

    public OrderStatus Status => _status;
    public Guid CustomerId => _customerId;
    public decimal TotalAmount => _totalAmount;
    public IReadOnlyList<OrderItem> Items => _items.AsReadOnly();
    public Address? ShippingAddress => _shippingAddress;
    public PaymentMethod? PaymentMethod => _paymentMethod;
    public string? ConfirmationNumber => _confirmationNumber;

    private Order() : base() { } // For reconstruction

    public static Order Create(
        Guid customerId,
        List<OrderItem> items,
        Address shippingAddress,
        PaymentMethod paymentMethod)
    {
        if (customerId == Guid.Empty)
            throw new ArgumentException("Customer ID is required", nameof(customerId));
            
        if (items == null || !items.Any())
            throw new ArgumentException("Order must contain at least one item", nameof(items));
            
        if (shippingAddress == null)
            throw new ArgumentNullException(nameof(shippingAddress));
            
        if (paymentMethod == null)
            throw new ArgumentNullException(nameof(paymentMethod));

        var order = new Order
        {
            Id = Guid.NewGuid(),
            Version = 0
        };

        var totalAmount = items.Sum(i => i.TotalPrice);

        order.RaiseEvent(new OrderCreated(
            order.Id,
            1,
            customerId,
            items,
            totalAmount,
            shippingAddress,
            paymentMethod));

        return order;
    }

    public void Confirm(string confirmationNumber)
    {
        if (_status != OrderStatus.Pending)
            throw new InvalidOperationException(
                $"Cannot confirm order in {_status} status");

        if (string.IsNullOrWhiteSpace(confirmationNumber))
            throw new ArgumentException("Confirmation number is required", nameof(confirmationNumber));

        RaiseEvent(new OrderConfirmed(Id, Version + 1, confirmationNumber));
    }

    public void Cancel(string reason, string? refundId = null)
    {
        if (_status == OrderStatus.Cancelled)
            throw new InvalidOperationException("Order is already cancelled");

        if (_status == OrderStatus.Shipped || _status == OrderStatus.Delivered)
            throw new InvalidOperationException(
                $"Cannot cancel order in {_status} status");

        if (string.IsNullOrWhiteSpace(reason))
            throw new ArgumentException("Cancellation reason is required", nameof(reason));

        RaiseEvent(new OrderCancelled(Id, Version + 1, reason, refundId));
    }

    public void MarkAsShipped(string trackingNumber)
    {
        if (_status != OrderStatus.Confirmed)
            throw new InvalidOperationException(
                $"Cannot ship order in {_status} status");

        RaiseEvent(new OrderShipped(Id, Version + 1, trackingNumber, DateTime.UtcNow));
    }

    public void MarkAsDelivered(DateTime deliveredAt)
    {
        if (_status != OrderStatus.Shipped)
            throw new InvalidOperationException(
                $"Cannot deliver order in {_status} status");

        RaiseEvent(new OrderDelivered(Id, Version + 1, deliveredAt));
    }

    protected override void RegisterEventHandlers()
    {
        RegisterEventHandler<OrderCreated>(Apply);
        RegisterEventHandler<OrderConfirmed>(Apply);
        RegisterEventHandler<OrderCancelled>(Apply);
        RegisterEventHandler<OrderShipped>(Apply);
        RegisterEventHandler<OrderDelivered>(Apply);
    }

    private void Apply(OrderCreated @event)
    {
        Id = @event.AggregateId;
        _customerId = @event.CustomerId;
        _items = @event.Items.ToList();
        _totalAmount = @event.TotalAmount;
        _shippingAddress = @event.ShippingAddress;
        _paymentMethod = @event.PaymentMethod;
        _status = OrderStatus.Pending;
        CreatedAt = @event.OccurredAt;
    }

    private void Apply(OrderConfirmed @event)
    {
        _status = OrderStatus.Confirmed;
        _confirmationNumber = @event.ConfirmationNumber;
    }

    private void Apply(OrderCancelled @event)
    {
        _status = OrderStatus.Cancelled;
        _cancellationReason = @event.Reason;
    }

    private void Apply(OrderShipped @event)
    {
        _status = OrderStatus.Shipped;
    }

    private void Apply(OrderDelivered @event)
    {
        _status = OrderStatus.Delivered;
    }
}

public enum OrderStatus
{
    Pending,
    Confirmed,
    Shipped,
    Delivered,
    Cancelled
}

// Additional domain events
public record OrderShipped(
    Guid OrderId,
    long Version,
    string TrackingNumber,
    DateTime ShippedAt) : DomainEvent(OrderId, Version);

public record OrderDelivered(
    Guid OrderId,
    long Version,
    DateTime DeliveredAt) : DomainEvent(OrderId, Version);
```

### 1.3 Create Order Commands and Handlers

Create `src/Services/Order/Application/Commands/CreateOrderCommand.cs`:

```csharp
namespace Ecommerce.Order.Application.Commands;

public record CreateOrderCommand : IRequest<Result<OrderDto>>
{
    public Guid CustomerId { get; init; }
    public List<OrderItemDto> Items { get; init; } = new();
    public AddressDto ShippingAddress { get; init; } = null!;
    public PaymentMethodDto PaymentMethod { get; init; } = null!;
}

public class CreateOrderCommandValidator : AbstractValidator<CreateOrderCommand>
{
    public CreateOrderCommandValidator()
    {
        RuleFor(x => x.CustomerId)
            .NotEmpty().WithMessage("Customer ID is required");

        RuleFor(x => x.Items)
            .NotEmpty().WithMessage("Order must contain at least one item")
            .ForEach(item => item.SetValidator(new OrderItemValidator()));

        RuleFor(x => x.ShippingAddress)
            .NotNull().WithMessage("Shipping address is required")
            .SetValidator(new AddressValidator());

        RuleFor(x => x.PaymentMethod)
            .NotNull().WithMessage("Payment method is required")
            .SetValidator(new PaymentMethodValidator());
    }
}

public class CreateOrderCommandHandler : IRequestHandler<CreateOrderCommand, Result<OrderDto>>
{
    private readonly IEventSourcedRepository<Domain.Order> _orderRepository;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly ILogger<CreateOrderCommandHandler> _logger;
    private readonly IMapper _mapper;

    public CreateOrderCommandHandler(
        IEventSourcedRepository<Domain.Order> orderRepository,
        IPublishEndpoint publishEndpoint,
        ILogger<CreateOrderCommandHandler> logger,
        IMapper mapper)
    {
        _orderRepository = orderRepository;
        _publishEndpoint = publishEndpoint;
        _logger = logger;
        _mapper = mapper;
    }

    public async Task<Result<OrderDto>> Handle(
        CreateOrderCommand request,
        CancellationToken cancellationToken)
    {
        try
        {
            // Map DTOs to domain objects
            var items = _mapper.Map<List<OrderItem>>(request.Items);
            var address = _mapper.Map<Address>(request.ShippingAddress);
            var paymentMethod = _mapper.Map<PaymentMethod>(request.PaymentMethod);

            // Create order aggregate
            var order = Domain.Order.Create(
                request.CustomerId,
                items,
                address,
                paymentMethod);

            // Save to event store
            await _orderRepository.SaveAsync(order, cancellationToken);

            // Publish integration event
            var integrationEvent = new OrderSubmitted(
                order.Id,
                order.Id,
                request.CustomerId,
                items,
                order.TotalAmount,
                address,
                paymentMethod);

            await _publishEndpoint.Publish(integrationEvent, cancellationToken);

            _logger.LogInformation(
                "Order {OrderId} created for customer {CustomerId}",
                order.Id,
                request.CustomerId);

            var orderDto = _mapper.Map<OrderDto>(order);
            return Result<OrderDto>.Success(orderDto);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Error creating order for customer {CustomerId}",
                request.CustomerId);
                
            return Result<OrderDto>.Failure($"Failed to create order: {ex.Message}");
        }
    }
}

// DTOs
public record OrderDto(
    Guid Id,
    Guid CustomerId,
    List<OrderItemDto> Items,
    decimal TotalAmount,
    OrderStatus Status,
    AddressDto ShippingAddress,
    string? ConfirmationNumber,
    DateTime CreatedAt,
    DateTime? UpdatedAt);

public record OrderItemDto(
    Guid ProductId,
    string ProductName,
    string SKU,
    int Quantity,
    decimal UnitPrice,
    decimal TotalPrice);

public record AddressDto(
    string Street,
    string City,
    string State,
    string PostalCode,
    string Country);

public record PaymentMethodDto(
    string Type,
    string Last4Digits,
    string? Token);
```

### 1.4 Create Order Saga

Create `src/Services/Order/Sagas/OrderSaga.cs`:

```csharp
namespace Ecommerce.Order.Sagas;

public class OrderSaga : SagaBase,
    ISaga,
    InitiatedBy<OrderSubmitted>,
    Orchestrates<InventoryReserved>,
    Orchestrates<InventoryReservationFailed>,
    Orchestrates<PaymentProcessed>,
    Orchestrates<PaymentFailed>,
    Orchestrates<ShippingLabelCreated>,
    Orchestrates<ShippingFailed>
{
    public Guid OrderId { get; set; }
    public Guid CustomerId { get; set; }
    public decimal TotalAmount { get; set; }
    public List<OrderItem> Items { get; set; } = new();
    public List<Guid> ReservationIds { get; set; } = new();
    public string? PaymentTransactionId { get; set; }
    public string? ShippingTrackingNumber { get; set; }
    public string? FailureReason { get; set; }

    public async Task Consume(ConsumeContext<OrderSubmitted> context)
    {
        var message = context.Message;
        
        OrderId = message.OrderId;
        CustomerId = message.CustomerId;
        TotalAmount = message.TotalAmount;
        Items = message.Items;
        UpdateState("AwaitingInventoryReservation");

        // Request inventory reservation
        await context.Publish(new ReserveInventory(
            CorrelationId,
            OrderId,
            Items.Select(i => new InventoryReservationItem(
                i.ProductId,
                i.SKU,
                i.Quantity)).ToList()));

        Log.Information(
            "Order saga started for order {OrderId}",
            OrderId);
    }

    public async Task Consume(ConsumeContext<InventoryReserved> context)
    {
        if (CurrentState != "AwaitingInventoryReservation")
            return;

        var message = context.Message;
        ReservationIds = message.ReservedItems.Select(r => r.ReservationId).ToList();
        UpdateState("AwaitingPayment");

        // Process payment
        await context.Publish(new ProcessPayment(
            CorrelationId,
            OrderId,
            CustomerId,
            TotalAmount,
            "USD", // Currency should come from order
            context.Message.PaymentMethod));

        Log.Information(
            "Inventory reserved for order {OrderId}",
            OrderId);
    }

    public async Task Consume(ConsumeContext<InventoryReservationFailed> context)
    {
        if (CurrentState != "AwaitingInventoryReservation")
            return;

        FailureReason = context.Message.Reason;
        UpdateState("Failed");

        // Cancel order
        await context.Publish(new CancelOrder(
            CorrelationId,
            OrderId,
            FailureReason));

        // Notify customer
        await context.Publish(new SendNotification(
            CorrelationId,
            CustomerId,
            "OrderCancelled",
            new Dictionary<string, object>
            {
                ["OrderId"] = OrderId,
                ["Reason"] = FailureReason
            }));

        Log.Warning(
            "Order {OrderId} failed due to inventory: {Reason}",
            OrderId,
            FailureReason);
    }

    public async Task Consume(ConsumeContext<PaymentProcessed> context)
    {
        if (CurrentState != "AwaitingPayment")
            return;

        var message = context.Message;
        PaymentTransactionId = message.TransactionId;
        UpdateState("AwaitingShipping");

        // Create shipping label
        await context.Publish(new CreateShippingLabel(
            CorrelationId,
            OrderId,
            CustomerId,
            context.Message.ShippingAddress,
            Items.Select(i => new ShippingItem(
                i.ProductId,
                i.ProductName,
                i.Quantity)).ToList()));

        Log.Information(
            "Payment processed for order {OrderId}, transaction {TransactionId}",
            OrderId,
            PaymentTransactionId);
    }

    public async Task Consume(ConsumeContext<PaymentFailed> context)
    {
        if (CurrentState != "AwaitingPayment")
            return;

        FailureReason = context.Message.Reason;
        UpdateState("Compensating");

        // Release inventory
        await context.Publish(new ReleaseInventory(
            CorrelationId,
            OrderId,
            ReservationIds));

        // Cancel order
        await context.Publish(new CancelOrder(
            CorrelationId,
            OrderId,
            FailureReason));

        // Notify customer
        await context.Publish(new SendNotification(
            CorrelationId,
            CustomerId,
            "PaymentFailed",
            new Dictionary<string, object>
            {
                ["OrderId"] = OrderId,
                ["Reason"] = FailureReason
            }));

        UpdateState("Failed");

        Log.Warning(
            "Payment failed for order {OrderId}: {Reason}",
            OrderId,
            FailureReason);
    }

    public async Task Consume(ConsumeContext<ShippingLabelCreated> context)
    {
        if (CurrentState != "AwaitingShipping")
            return;

        var message = context.Message;
        ShippingTrackingNumber = message.TrackingNumber;
        UpdateState("Completed");

        // Confirm order
        await context.Publish(new ConfirmOrder(
            CorrelationId,
            OrderId,
            GenerateConfirmationNumber()));

        // Send confirmation notification
        await context.Publish(new SendNotification(
            CorrelationId,
            CustomerId,
            "OrderConfirmed",
            new Dictionary<string, object>
            {
                ["OrderId"] = OrderId,
                ["ConfirmationNumber"] = GenerateConfirmationNumber(),
                ["TrackingNumber"] = ShippingTrackingNumber
            }));

        Log.Information(
            "Order {OrderId} completed successfully",
            OrderId);
    }

    public async Task Consume(ConsumeContext<ShippingFailed> context)
    {
        if (CurrentState != "AwaitingShipping")
            return;

        FailureReason = context.Message.Reason;
        UpdateState("Compensating");

        // Refund payment
        await context.Publish(new RefundPayment(
            CorrelationId,
            OrderId,
            PaymentTransactionId!,
            TotalAmount,
            "Shipping failed"));

        // Release inventory
        await context.Publish(new ReleaseInventory(
            CorrelationId,
            OrderId,
            ReservationIds));

        // Cancel order
        await context.Publish(new CancelOrder(
            CorrelationId,
            OrderId,
            FailureReason));

        UpdateState("Failed");

        Log.Warning(
            "Shipping failed for order {OrderId}: {Reason}",
            OrderId,
            FailureReason);
    }

    private string GenerateConfirmationNumber()
    {
        return $"ORD-{DateTime.UtcNow:yyyyMMdd}-{OrderId.ToString()[..8].ToUpper()}";
    }
}

// Saga commands
public record ReserveInventory(
    Guid CorrelationId,
    Guid OrderId,
    List<InventoryReservationItem> Items) : CorrelatedBy<Guid>;

public record InventoryReservationItem(
    Guid ProductId,
    string SKU,
    int Quantity);

public record ProcessPayment(
    Guid CorrelationId,
    Guid OrderId,
    Guid CustomerId,
    decimal Amount,
    string Currency,
    PaymentMethod PaymentMethod) : CorrelatedBy<Guid>;

public record CreateShippingLabel(
    Guid CorrelationId,
    Guid OrderId,
    Guid CustomerId,
    Address ShippingAddress,
    List<ShippingItem> Items) : CorrelatedBy<Guid>;

public record ShippingItem(
    Guid ProductId,
    string ProductName,
    int Quantity);

public record CancelOrder(
    Guid CorrelationId,
    Guid OrderId,
    string Reason) : CorrelatedBy<Guid>;

public record ConfirmOrder(
    Guid CorrelationId,
    Guid OrderId,
    string ConfirmationNumber) : CorrelatedBy<Guid>;

public record ReleaseInventory(
    Guid CorrelationId,
    Guid OrderId,
    List<Guid> ReservationIds) : CorrelatedBy<Guid>;

public record RefundPayment(
    Guid CorrelationId,
    Guid OrderId,
    string TransactionId,
    decimal Amount,
    string Reason) : CorrelatedBy<Guid>;

public record SendNotification(
    Guid CorrelationId,
    Guid UserId,
    string TemplateId,
    Dictionary<string, object> Parameters) : CorrelatedBy<Guid>;
```

### 1.5 Configure Order Service

Create `src/Services/Order/Program.cs`:

```csharp
var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure MongoDB for event store
builder.Services.AddSingleton<IMongoClient>(sp =>
{
    var connectionString = builder.Configuration.GetConnectionString("EventStore");
    return new MongoClient(connectionString);
});

builder.Services.AddScoped(sp =>
{
    var client = sp.GetRequiredService<IMongoClient>();
    return client.GetDatabase("order-events");
});

// Configure event store
builder.Services.AddScoped<IEventStore, MongoEventStore>();
builder.Services.AddScoped(typeof(IEventSourcedRepository<>), typeof(EventSourcedRepository<>));

// Configure SQL Server for read models
builder.Services.AddDbContext<OrderReadDbContext>(options =>
{
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        sqlOptions =>
        {
            sqlOptions.EnableRetryOnFailure(5, TimeSpan.FromSeconds(10), null);
        });
});

// Add MediatR
builder.Services.AddMediatR(cfg =>
{
    cfg.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly());
});

// Add AutoMapper
builder.Services.AddAutoMapper(Assembly.GetExecutingAssembly());

// Configure MassTransit
builder.Services.AddServiceBus(builder.Configuration, cfg =>
{
    cfg.AddConsumer<OrderEventConsumer>();
    cfg.AddSaga<OrderSaga>()
        .MongoDbRepository(r =>
        {
            r.Connection = builder.Configuration.GetConnectionString("EventStore");
            r.DatabaseName = "saga-store";
        });
});

// Add health checks
builder.Services.AddHealthChecks()
    .AddSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        name: "sql-read-model")
    .AddMongoDb(
        builder.Configuration.GetConnectionString("EventStore"),
        name: "mongo-event-store");

// Configure logging
builder.Host.UseSerilog((context, services, configuration) => configuration
    .ReadFrom.Configuration(context.Configuration)
    .ReadFrom.Services(services)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.Seq(context.Configuration["Logging:Seq:ServerUrl"]));

// Configure OpenTelemetry
builder.Services.AddOpenTelemetry()
    .WithTracing(tracing => tracing
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddSqlClientInstrumentation()
        .AddSource("MassTransit")
        .AddJaegerExporter(options =>
        {
            options.AgentHost = builder.Configuration["Jaeger:AgentHost"];
            options.AgentPort = builder.Configuration.GetValue<int>("Jaeger:AgentPort");
        }));

var app = builder.Build();

// Configure middleware
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseSerilogRequestLogging();
app.UseRouting();
app.UseAuthorization();
app.MapControllers();
app.MapHealthChecks("/health");

// Run migrations
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<OrderReadDbContext>();
    await dbContext.Database.MigrateAsync();
}

app.Run();
```

## 📦 Step 2: Implement Inventory Service

### 2.1 Create Inventory Service

Create `src/Services/Inventory/Domain/InventoryItem.cs`:

```csharp
namespace Ecommerce.Inventory.Domain;

public class InventoryItem
{
    private readonly List<Reservation> _reservations = new();
    
    public Guid Id { get; private set; }
    public Guid ProductId { get; private set; }
    public string SKU { get; private set; } = null!;
    public string ProductName { get; private set; } = null!;
    public int QuantityOnHand { get; private set; }
    public int QuantityReserved { get; private set; }
    public int QuantityAvailable => QuantityOnHand - QuantityReserved;
    public int ReorderPoint { get; private set; }
    public int ReorderQuantity { get; private set; }
    public DateTime LastRestocked { get; private set; }
    public DateTime LastUpdated { get; private set; }
    
    public IReadOnlyCollection<Reservation> Reservations => _reservations.AsReadOnly();

    protected InventoryItem() { } // For EF

    public static InventoryItem Create(
        Guid productId,
        string sku,
        string productName,
        int initialQuantity,
        int reorderPoint,
        int reorderQuantity)
    {
        if (productId == Guid.Empty)
            throw new ArgumentException("Product ID is required", nameof(productId));
            
        if (string.IsNullOrWhiteSpace(sku))
            throw new ArgumentException("SKU is required", nameof(sku));
            
        if (initialQuantity < 0)
            throw new ArgumentException("Initial quantity cannot be negative", nameof(initialQuantity));

        return new InventoryItem
        {
            Id = Guid.NewGuid(),
            ProductId = productId,
            SKU = sku,
            ProductName = productName,
            QuantityOnHand = initialQuantity,
            QuantityReserved = 0,
            ReorderPoint = reorderPoint,
            ReorderQuantity = reorderQuantity,
            LastRestocked = DateTime.UtcNow,
            LastUpdated = DateTime.UtcNow
        };
    }

    public Result<Reservation> Reserve(Guid orderId, int quantity, TimeSpan duration)
    {
        if (quantity <= 0)
            return Result<Reservation>.Failure("Quantity must be greater than zero");
            
        if (quantity > QuantityAvailable)
            return Result<Reservation>.Failure(
                $"Insufficient inventory. Available: {QuantityAvailable}, Requested: {quantity}");

        var reservation = new Reservation(
            Guid.NewGuid(),
            orderId,
            ProductId,
            quantity,
            DateTime.UtcNow.Add(duration));

        _reservations.Add(reservation);
        QuantityReserved += quantity;
        LastUpdated = DateTime.UtcNow;

        return Result<Reservation>.Success(reservation);
    }

    public Result ReleaseReservation(Guid reservationId)
    {
        var reservation = _reservations.FirstOrDefault(r => r.Id == reservationId);
        
        if (reservation == null)
            return Result.Failure("Reservation not found");

        _reservations.Remove(reservation);
        QuantityReserved -= reservation.Quantity;
        LastUpdated = DateTime.UtcNow;

        return Result.Success();
    }

    public void CommitReservation(Guid reservationId)
    {
        var reservation = _reservations.FirstOrDefault(r => r.Id == reservationId);
        
        if (reservation == null)
            throw new InvalidOperationException("Reservation not found");

        _reservations.Remove(reservation);
        QuantityOnHand -= reservation.Quantity;
        QuantityReserved -= reservation.Quantity;
        LastUpdated = DateTime.UtcNow;
    }

    public void Restock(int quantity)
    {
        if (quantity <= 0)
            throw new ArgumentException("Restock quantity must be greater than zero", nameof(quantity));

        QuantityOnHand += quantity;
        LastRestocked = DateTime.UtcNow;
        LastUpdated = DateTime.UtcNow;
    }

    public void ExpireReservations()
    {
        var expiredReservations = _reservations
            .Where(r => r.ExpiresAt <= DateTime.UtcNow)
            .ToList();

        foreach (var reservation in expiredReservations)
        {
            _reservations.Remove(reservation);
            QuantityReserved -= reservation.Quantity;
        }

        if (expiredReservations.Any())
        {
            LastUpdated = DateTime.UtcNow;
        }
    }

    public bool NeedsReorder => QuantityAvailable <= ReorderPoint;
}

public class Reservation
{
    public Guid Id { get; private set; }
    public Guid OrderId { get; private set; }
    public Guid ProductId { get; private set; }
    public int Quantity { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime ExpiresAt { get; private set; }

    public Reservation(
        Guid id,
        Guid orderId,
        Guid productId,
        int quantity,
        DateTime expiresAt)
    {
        Id = id;
        OrderId = orderId;
        ProductId = productId;
        Quantity = quantity;
        CreatedAt = DateTime.UtcNow;
        ExpiresAt = expiresAt;
    }

    protected Reservation() { } // For EF
}
```

### 2.2 Create Inventory Event Handlers

Create `src/Services/Inventory/Consumers/ReserveInventoryConsumer.cs`:

```csharp
namespace Ecommerce.Inventory.Consumers;

public class ReserveInventoryConsumer : IConsumer<ReserveInventory>
{
    private readonly InventoryDbContext _dbContext;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly ILogger<ReserveInventoryConsumer> _logger;
    private readonly IConfiguration _configuration;

    public ReserveInventoryConsumer(
        InventoryDbContext dbContext,
        IPublishEndpoint publishEndpoint,
        ILogger<ReserveInventoryConsumer> logger,
        IConfiguration configuration)
    {
        _dbContext = dbContext;
        _publishEndpoint = publishEndpoint;
        _logger = logger;
        _configuration = configuration;
    }

    public async Task Consume(ConsumeContext<ReserveInventory> context)
    {
        var message = context.Message;
        var reservedItems = new List<ReservedItem>();
        var failedItems = new List<OutOfStockItem>();
        
        using var transaction = await _dbContext.Database.BeginTransactionAsync();
        
        try
        {
            var reservationDuration = TimeSpan.FromMinutes(
                _configuration.GetValue<int>("Inventory:ReservationDurationMinutes", 30));

            foreach (var item in message.Items)
            {
                var inventoryItem = await _dbContext.InventoryItems
                    .Include(i => i.Reservations)
                    .FirstOrDefaultAsync(i => i.ProductId == item.ProductId);

                if (inventoryItem == null)
                {
                    failedItems.Add(new OutOfStockItem(
                        item.ProductId,
                        item.SKU,
                        item.Quantity,
                        0));
                    continue;
                }

                var reservationResult = inventoryItem.Reserve(
                    message.OrderId,
                    item.Quantity,
                    reservationDuration);

                if (reservationResult.IsSuccess)
                {
                    reservedItems.Add(new ReservedItem(
                        item.ProductId,
                        item.SKU,
                        item.Quantity,
                        reservationResult.Value!.Id));
                }
                else
                {
                    failedItems.Add(new OutOfStockItem(
                        item.ProductId,
                        item.SKU,
                        item.Quantity,
                        inventoryItem.QuantityAvailable));
                }
            }

            if (failedItems.Any())
            {
                // Rollback if any item failed
                await transaction.RollbackAsync();
                
                await _publishEndpoint.Publish(new InventoryReservationFailed(
                    context.Message.CorrelationId,
                    message.OrderId,
                    failedItems,
                    "One or more items are out of stock"));

                _logger.LogWarning(
                    "Inventory reservation failed for order {OrderId}. Out of stock items: {Count}",
                    message.OrderId,
                    failedItems.Count);
            }
            else
            {
                // All items reserved successfully
                await _dbContext.SaveChangesAsync();
                await transaction.CommitAsync();
                
                await _publishEndpoint.Publish(new InventoryReserved(
                    context.Message.CorrelationId,
                    message.OrderId,
                    reservedItems,
                    DateTime.UtcNow.Add(reservationDuration)));

                _logger.LogInformation(
                    "Inventory reserved for order {OrderId}. Items: {Count}",
                    message.OrderId,
                    reservedItems.Count);
            }
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            
            _logger.LogError(ex,
                "Error processing inventory reservation for order {OrderId}",
                message.OrderId);
                
            throw;
        }
    }
}
```

### 2.3 Create Inventory Projections

Create `src/Services/Inventory/Projections/InventoryProjection.cs`:

```csharp
namespace Ecommerce.Inventory.Projections;

public class InventoryProjection : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<InventoryProjection> _logger;
    private readonly IDistributedCache _cache;

    public InventoryProjection(
        IServiceProvider serviceProvider,
        ILogger<InventoryProjection> logger,
        IDistributedCache cache)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
        _cache = cache;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<InventoryDbContext>();
                
                // Update inventory summaries
                var inventorySummaries = await dbContext.InventoryItems
                    .GroupBy(i => new { i.ProductId, i.SKU, i.ProductName })
                    .Select(g => new InventorySummary
                    {
                        ProductId = g.Key.ProductId,
                        SKU = g.Key.SKU,
                        ProductName = g.Key.ProductName,
                        TotalOnHand = g.Sum(i => i.QuantityOnHand),
                        TotalReserved = g.Sum(i => i.QuantityReserved),
                        TotalAvailable = g.Sum(i => i.QuantityAvailable),
                        LocationCount = g.Count(),
                        LastUpdated = DateTime.UtcNow
                    })
                    .ToListAsync(stoppingToken);

                // Cache summaries
                foreach (var summary in inventorySummaries)
                {
                    var cacheKey = $"inventory:summary:{summary.ProductId}";
                    await _cache.SetStringAsync(
                        cacheKey,
                        JsonSerializer.Serialize(summary),
                        new DistributedCacheEntryOptions
                        {
                            SlidingExpiration = TimeSpan.FromMinutes(5)
                        },
                        stoppingToken);
                }

                // Check for low stock items
                var lowStockItems = await dbContext.InventoryItems
                    .Where(i => i.NeedsReorder)
                    .Select(i => new LowStockAlert
                    {
                        ProductId = i.ProductId,
                        SKU = i.SKU,
                        ProductName = i.ProductName,
                        QuantityAvailable = i.QuantityAvailable,
                        ReorderPoint = i.ReorderPoint,
                        ReorderQuantity = i.ReorderQuantity
                    })
                    .ToListAsync(stoppingToken);

                if (lowStockItems.Any())
                {
                    // Publish low stock events
                    using var publishScope = _serviceProvider.CreateScope();
                    var publishEndpoint = publishScope.ServiceProvider
                        .GetRequiredService<IPublishEndpoint>();
                        
                    await publishEndpoint.Publish(new LowStockDetected(
                        lowStockItems,
                        DateTime.UtcNow), stoppingToken);
                }

                _logger.LogInformation(
                    "Inventory projection updated. Summaries: {SummaryCount}, Low stock: {LowStockCount}",
                    inventorySummaries.Count,
                    lowStockItems.Count);

                // Run every minute
                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating inventory projections");
                await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
            }
        }
    }
}

public class InventorySummary
{
    public Guid ProductId { get; set; }
    public string SKU { get; set; } = null!;
    public string ProductName { get; set; } = null!;
    public int TotalOnHand { get; set; }
    public int TotalReserved { get; set; }
    public int TotalAvailable { get; set; }
    public int LocationCount { get; set; }
    public DateTime LastUpdated { get; set; }
}

public record LowStockAlert(
    Guid ProductId,
    string SKU,
    string ProductName,
    int QuantityAvailable,
    int ReorderPoint,
    int ReorderQuantity);

public record LowStockDetected(
    List<LowStockAlert> Items,
    DateTime DetectedAt) : IntegrationEvent(Guid.NewGuid(), "InventoryService");
```

## 💳 Step 3: Implement Payment Service

### 3.1 Create Payment Gateway Interface

Create `src/Services/Payment/Gateways/IPaymentGateway.cs`:

```csharp
namespace Ecommerce.Payment.Gateways;

public interface IPaymentGateway
{
    Task<PaymentResult> ProcessPaymentAsync(PaymentRequest request, CancellationToken cancellationToken = default);
    Task<RefundResult> ProcessRefundAsync(RefundRequest request, CancellationToken cancellationToken = default);
    Task<PaymentStatus> GetPaymentStatusAsync(string transactionId, CancellationToken cancellationToken = default);
    bool SupportsPaymentMethod(string paymentMethodType);
}

public record PaymentRequest(
    string PaymentMethodToken,
    decimal Amount,
    string Currency,
    string Description,
    Dictionary<string, string> Metadata);

public record PaymentResult(
    bool IsSuccess,
    string? TransactionId,
    string? ErrorCode,
    string? ErrorMessage,
    Dictionary<string, string> AdditionalData);

public record RefundRequest(
    string TransactionId,
    decimal Amount,
    string Reason);

public record RefundResult(
    bool IsSuccess,
    string? RefundId,
    string? ErrorMessage);

public enum PaymentStatus
{
    Pending,
    Processing,
    Completed,
    Failed,
    Refunded,
    PartiallyRefunded
}

// Mock payment gateway for testing
public class MockPaymentGateway : IPaymentGateway
{
    private readonly ILogger<MockPaymentGateway> _logger;
    private readonly Random _random = new();

    public MockPaymentGateway(ILogger<MockPaymentGateway> logger)
    {
        _logger = logger;
    }

    public async Task<PaymentResult> ProcessPaymentAsync(
        PaymentRequest request,
        CancellationToken cancellationToken = default)
    {
        await Task.Delay(TimeSpan.FromSeconds(1), cancellationToken); // Simulate processing
        
        // Simulate different scenarios
        var scenario = _random.Next(100);
        
        if (scenario < 85) // 85% success rate
        {
            var transactionId = $"TXN-{Guid.NewGuid().ToString()[..8].ToUpper()}";
            
            _logger.LogInformation(
                "Payment processed successfully. Transaction: {TransactionId}, Amount: {Amount} {Currency}",
                transactionId,
                request.Amount,
                request.Currency);
                
            return new PaymentResult(
                true,
                transactionId,
                null,
                null,
                new Dictionary<string, string>
                {
                    ["ProcessedAt"] = DateTime.UtcNow.ToString("O"),
                    ["Gateway"] = "Mock"
                });
        }
        else if (scenario < 95) // 10% insufficient funds
        {
            return new PaymentResult(
                false,
                null,
                "INSUFFICIENT_FUNDS",
                "The card has insufficient funds",
                new Dictionary<string, string>());
        }
        else // 5% card declined
        {
            return new PaymentResult(
                false,
                null,
                "CARD_DECLINED",
                "The card was declined",
                new Dictionary<string, string>());
        }
    }

    public async Task<RefundResult> ProcessRefundAsync(
        RefundRequest request,
        CancellationToken cancellationToken = default)
    {
        await Task.Delay(TimeSpan.FromSeconds(1), cancellationToken);
        
        var refundId = $"REF-{Guid.NewGuid().ToString()[..8].ToUpper()}";
        
        _logger.LogInformation(
            "Refund processed. RefundId: {RefundId}, TransactionId: {TransactionId}, Amount: {Amount}",
            refundId,
            request.TransactionId,
            request.Amount);
            
        return new RefundResult(true, refundId, null);
    }

    public Task<PaymentStatus> GetPaymentStatusAsync(
        string transactionId,
        CancellationToken cancellationToken = default)
    {
        return Task.FromResult(PaymentStatus.Completed);
    }

    public bool SupportsPaymentMethod(string paymentMethodType)
    {
        return paymentMethodType.ToLower() is "card" or "credit_card" or "debit_card";
    }
}
```

### 3.2 Create Payment Service Consumer

Create `src/Services/Payment/Consumers/ProcessPaymentConsumer.cs`:

```csharp
namespace Ecommerce.Payment.Consumers;

public class ProcessPaymentConsumer : IConsumer<ProcessPayment>
{
    private readonly IPaymentGateway _paymentGateway;
    private readonly PaymentDbContext _dbContext;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly ILogger<ProcessPaymentConsumer> _logger;

    public ProcessPaymentConsumer(
        IPaymentGateway paymentGateway,
        PaymentDbContext dbContext,
        IPublishEndpoint publishEndpoint,
        ILogger<ProcessPaymentConsumer> logger)
    {
        _paymentGateway = paymentGateway;
        _dbContext = dbContext;
        _publishEndpoint = publishEndpoint;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<ProcessPayment> context)
    {
        var message = context.Message;
        
        try
        {
            // Check if payment already exists (idempotency)
            var existingPayment = await _dbContext.Payments
                .FirstOrDefaultAsync(p => p.OrderId == message.OrderId);
                
            if (existingPayment != null && existingPayment.Status == PaymentStatus.Completed)
            {
                _logger.LogWarning(
                    "Payment already processed for order {OrderId}",
                    message.OrderId);
                return;
            }

            // Create payment record
            var payment = new PaymentRecord
            {
                Id = Guid.NewGuid(),
                OrderId = message.OrderId,
                CustomerId = message.CustomerId,
                Amount = message.Amount,
                Currency = message.Currency,
                PaymentMethod = message.PaymentMethod.Type,
                Status = PaymentStatus.Processing,
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.Payments.Add(payment);
            await _dbContext.SaveChangesAsync();

            // Process payment through gateway
            var paymentRequest = new PaymentRequest(
                message.PaymentMethod.Token ?? string.Empty,
                message.Amount,
                message.Currency,
                $"Payment for order {message.OrderId}",
                new Dictionary<string, string>
                {
                    ["OrderId"] = message.OrderId.ToString(),
                    ["CustomerId"] = message.CustomerId.ToString()
                });

            var result = await _paymentGateway.ProcessPaymentAsync(paymentRequest);

            if (result.IsSuccess)
            {
                // Update payment record
                payment.TransactionId = result.TransactionId;
                payment.Status = PaymentStatus.Completed;
                payment.ProcessedAt = DateTime.UtcNow;
                payment.GatewayResponse = JsonSerializer.Serialize(result.AdditionalData);
                
                await _dbContext.SaveChangesAsync();

                // Publish success event
                await _publishEndpoint.Publish(new PaymentProcessed(
                    context.Message.CorrelationId,
                    message.OrderId,
                    result.TransactionId!,
                    message.Amount,
                    message.Currency));

                _logger.LogInformation(
                    "Payment processed successfully for order {OrderId}. Transaction: {TransactionId}",
                    message.OrderId,
                    result.TransactionId);
            }
            else
            {
                // Update payment record
                payment.Status = PaymentStatus.Failed;
                payment.FailureReason = result.ErrorMessage;
                payment.FailureCode = result.ErrorCode;
                payment.ProcessedAt = DateTime.UtcNow;
                
                await _dbContext.SaveChangesAsync();

                // Determine if retryable
                var isRetryable = result.ErrorCode != "CARD_DECLINED" && 
                                 result.ErrorCode != "INVALID_CARD";

                // Publish failure event
                await _publishEndpoint.Publish(new PaymentFailed(
                    context.Message.CorrelationId,
                    message.OrderId,
                    result.ErrorMessage ?? "Payment processing failed",
                    result.ErrorCode,
                    isRetryable));

                _logger.LogWarning(
                    "Payment failed for order {OrderId}. Error: {ErrorCode} - {ErrorMessage}",
                    message.OrderId,
                    result.ErrorCode,
                    result.ErrorMessage);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Error processing payment for order {OrderId}",
                message.OrderId);
                
            // Publish failure event
            await _publishEndpoint.Publish(new PaymentFailed(
                context.Message.CorrelationId,
                message.OrderId,
                "Internal error processing payment",
                "INTERNAL_ERROR",
                true));
        }
    }
}
```

## 🚚 Step 4: Implement Shipping Service

Create `src/Services/Shipping/Consumers/CreateShippingLabelConsumer.cs`:

```csharp
namespace Ecommerce.Shipping.Consumers;

public class CreateShippingLabelConsumer : IConsumer<CreateShippingLabel>
{
    private readonly IShippingProvider _shippingProvider;
    private readonly ShippingDbContext _dbContext;
    private readonly IPublishEndpoint _publishEndpoint;
    private readonly ILogger<CreateShippingLabelConsumer> _logger;

    public CreateShippingLabelConsumer(
        IShippingProvider shippingProvider,
        ShippingDbContext dbContext,
        IPublishEndpoint publishEndpoint,
        ILogger<CreateShippingLabelConsumer> logger)
    {
        _shippingProvider = shippingProvider;
        _dbContext = dbContext;
        _publishEndpoint = publishEndpoint;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<CreateShippingLabel> context)
    {
        var message = context.Message;
        
        try
        {
            // Create shipment record
            var shipment = new Shipment
            {
                Id = Guid.NewGuid(),
                OrderId = message.OrderId,
                CustomerId = message.CustomerId,
                RecipientName = $"{message.ShippingAddress.Street}",
                ShippingAddress = message.ShippingAddress,
                Items = message.Items,
                Status = ShipmentStatus.LabelCreating,
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.Shipments.Add(shipment);
            await _dbContext.SaveChangesAsync();

            // Create shipping label
            var labelRequest = new CreateLabelRequest(
                message.ShippingAddress,
                CalculatePackageWeight(message.Items),
                CalculatePackageDimensions(message.Items),
                "STANDARD", // Shipping service type
                message.OrderId.ToString());

            var labelResult = await _shippingProvider.CreateLabelAsync(labelRequest);

            if (labelResult.IsSuccess)
            {
                // Update shipment
                shipment.TrackingNumber = labelResult.TrackingNumber;
                shipment.LabelUrl = labelResult.LabelUrl;
                shipment.Carrier = labelResult.Carrier;
                shipment.EstimatedDeliveryDate = labelResult.EstimatedDeliveryDate;
                shipment.Status = ShipmentStatus.LabelCreated;
                
                await _dbContext.SaveChangesAsync();

                // Publish success event
                await _publishEndpoint.Publish(new ShippingLabelCreated(
                    context.Message.CorrelationId,
                    message.OrderId,
                    labelResult.TrackingNumber!,
                    labelResult.Carrier!,
                    labelResult.LabelUrl!,
                    labelResult.EstimatedDeliveryDate!.Value));

                _logger.LogInformation(
                    "Shipping label created for order {OrderId}. Tracking: {TrackingNumber}",
                    message.OrderId,
                    labelResult.TrackingNumber);
            }
            else
            {
                // Update shipment
                shipment.Status = ShipmentStatus.Failed;
                shipment.FailureReason = labelResult.ErrorMessage;
                
                await _dbContext.SaveChangesAsync();

                // Publish failure event
                await _publishEndpoint.Publish(new ShippingFailed(
                    context.Message.CorrelationId,
                    message.OrderId,
                    labelResult.ErrorMessage ?? "Failed to create shipping label"));

                _logger.LogWarning(
                    "Failed to create shipping label for order {OrderId}. Error: {Error}",
                    message.OrderId,
                    labelResult.ErrorMessage);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Error creating shipping label for order {OrderId}",
                message.OrderId);
                
            await _publishEndpoint.Publish(new ShippingFailed(
                context.Message.CorrelationId,
                message.OrderId,
                "Internal error creating shipping label"));
        }
    }

    private decimal CalculatePackageWeight(List<ShippingItem> items)
    {
        // Mock weight calculation
        return items.Sum(i => i.Quantity * 0.5m); // 0.5 kg per item
    }

    private PackageDimensions CalculatePackageDimensions(List<ShippingItem> items)
    {
        // Mock dimension calculation
        var totalItems = items.Sum(i => i.Quantity);
        return new PackageDimensions(
            Length: 30 + (totalItems * 2),
            Width: 20 + (totalItems * 1),
            Height: 10 + (totalItems * 1),
            Unit: "cm");
    }
}

// Shipping events
public record ShippingLabelCreated(
    Guid CorrelationId,
    Guid OrderId,
    string TrackingNumber,
    string Carrier,
    string LabelUrl,
    DateTime EstimatedDeliveryDate) : IntegrationEvent(CorrelationId, "ShippingService");

public record ShippingFailed(
    Guid CorrelationId,
    Guid OrderId,
    string Reason) : IntegrationEvent(CorrelationId, "ShippingService");
```

## 📧 Step 5: Implement Notification Service

Create `src/Services/Notification/Consumers/SendNotificationConsumer.cs`:

```csharp
namespace Ecommerce.Notification.Consumers;

public class SendNotificationConsumer : IConsumer<SendNotification>
{
    private readonly INotificationChannelFactory _channelFactory;
    private readonly ITemplateService _templateService;
    private readonly IUserPreferenceService _preferenceService;
    private readonly NotificationDbContext _dbContext;
    private readonly ILogger<SendNotificationConsumer> _logger;

    public SendNotificationConsumer(
        INotificationChannelFactory channelFactory,
        ITemplateService templateService,
        IUserPreferenceService preferenceService,
        NotificationDbContext dbContext,
        ILogger<SendNotificationConsumer> logger)
    {
        _channelFactory = channelFactory;
        _templateService = templateService;
        _preferenceService = preferenceService;
        _dbContext = dbContext;
        _logger = logger;
    }

    public async Task Consume(ConsumeContext<SendNotification> context)
    {
        var message = context.Message;
        
        try
        {
            // Get user preferences
            var preferences = await _preferenceService.GetUserPreferencesAsync(message.UserId);
            
            if (!preferences.IsSubscribedToTemplate(message.TemplateId))
            {
                _logger.LogInformation(
                    "User {UserId} is not subscribed to template {TemplateId}",
                    message.UserId,
                    message.TemplateId);
                return;
            }

            // Get template
            var template = await _templateService.GetTemplateAsync(message.TemplateId);
            
            if (template == null)
            {
                _logger.LogWarning(
                    "Template {TemplateId} not found",
                    message.TemplateId);
                return;
            }

            // Render template with parameters
            var renderedContent = await _templateService.RenderTemplateAsync(
                template,
                message.Parameters);

            // Send through each enabled channel
            var tasks = new List<Task<NotificationResult>>();
            
            if (preferences.EmailEnabled && !string.IsNullOrEmpty(preferences.Email))
            {
                var emailChannel = _channelFactory.GetChannel(NotificationChannel.Email);
                tasks.Add(emailChannel.SendAsync(new EmailNotification(
                    preferences.Email,
                    renderedContent.Subject,
                    renderedContent.HtmlBody,
                    renderedContent.TextBody)));
            }

            if (preferences.SmsEnabled && !string.IsNullOrEmpty(preferences.PhoneNumber))
            {
                var smsChannel = _channelFactory.GetChannel(NotificationChannel.Sms);
                tasks.Add(smsChannel.SendAsync(new SmsNotification(
                    preferences.PhoneNumber,
                    renderedContent.SmsBody)));
            }

            if (preferences.PushEnabled && !string.IsNullOrEmpty(preferences.DeviceToken))
            {
                var pushChannel = _channelFactory.GetChannel(NotificationChannel.Push);
                tasks.Add(pushChannel.SendAsync(new PushNotification(
                    preferences.DeviceToken,
                    renderedContent.Subject,
                    renderedContent.PushBody,
                    message.Parameters)));
            }

            // Wait for all channels
            var results = await Task.WhenAll(tasks);

            // Record notification
            var notification = new NotificationRecord
            {
                Id = Guid.NewGuid(),
                UserId = message.UserId,
                TemplateId = message.TemplateId,
                Channels = results.Select(r => r.Channel).ToList(),
                Status = results.All(r => r.IsSuccess) 
                    ? NotificationStatus.Sent 
                    : NotificationStatus.PartiallyFailed,
                SentAt = DateTime.UtcNow,
                CorrelationId = context.Message.CorrelationId
            };

            _dbContext.Notifications.Add(notification);
            await _dbContext.SaveChangesAsync();

            _logger.LogInformation(
                "Notification sent to user {UserId} via {ChannelCount} channels",
                message.UserId,
                results.Length);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Error sending notification to user {UserId}",
                message.UserId);
        }
    }
}
```

## 💡 Copilot Prompt Suggestions

**For Service Implementation:**
```
Create a background service that:
- Monitors expired inventory reservations
- Releases them automatically
- Publishes events for released reservations
- Runs every 5 minutes
- Handles errors gracefully
Include proper logging and cancellation token usage
```

**For Integration Testing:**
```
Create an integration test for the order saga that:
- Uses TestContainers for infrastructure
- Tests the complete happy path
- Tests compensation on payment failure
- Verifies all events are published
- Checks final state consistency
Use xUnit and FluentAssertions
```

**For Performance Optimization:**
```
Optimize the inventory reservation process:
- Use bulk operations for multiple items
- Implement optimistic concurrency
- Add Redis caching for hot products
- Use database hints for locking
- Include performance metrics
Show before and after performance comparison
```

## ✅ Part 2 Checklist

Before moving to Part 3, ensure you have:

- [ ] Implemented Order Service with event sourcing
- [ ] Created Order aggregate with business logic
- [ ] Built Inventory Service with reservations
- [ ] Implemented Payment Service with gateway abstraction
- [ ] Created Shipping Service with provider integration
- [ ] Added Notification Service with multi-channel support
- [ ] Configured all services with health checks
- [ ] Set up logging and monitoring
- [ ] Tested service communication

## 🎯 Part 2 Summary

You've successfully:
- Built five microservices with clear boundaries
- Implemented event sourcing for the Order service
- Created CQRS with projections in Inventory service
- Integrated external gateways in Payment and Shipping
- Built a flexible notification system
- Established monitoring and health checks

## ⏭️ Next Steps

Continue to [Part 3: Saga Integration and Testing](part3-integration.md) where you'll:
- Complete the saga orchestration
- Add comprehensive integration tests
- Implement chaos engineering tests
- Deploy to Kubernetes
- Monitor the complete system

---

**🏆 Achievement**: You've built the core of a production-grade microservices system! Each service is independently deployable, scalable, and follows best practices for distributed systems.