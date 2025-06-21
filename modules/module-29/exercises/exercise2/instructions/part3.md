# Exercise 2: Event-Driven Microservices - Part 3: Saga Integration and Testing

## 🎯 Overview

In this final part, you'll complete the saga orchestration, implement comprehensive testing including chaos engineering, deploy the system to Kubernetes, and set up monitoring for the complete microservices ecosystem.

## 📋 Part 3 Objectives

- Complete saga orchestration with timeout handling
- Implement integration tests for the complete workflow
- Add chaos engineering tests
- Deploy to Kubernetes with proper configuration
- Set up distributed tracing and monitoring
- Validate system resilience and performance

## 🔄 Step 1: Complete Saga Orchestration

### 1.1 Add Timeout Handling to Saga

Update `src/Services/Order/Sagas/OrderSaga.cs`:

```csharp
namespace Ecommerce.Order.Sagas;

public class OrderSagaDefinition : SagaDefinition<OrderSaga>
{
    public OrderSagaDefinition()
    {
        // Configure correlation
        Endpoint(e => e.Name = "order-saga");
        
        // Configure timeouts
        RequestTimeout<ReserveInventory>(TimeSpan.FromMinutes(2));
        RequestTimeout<ProcessPayment>(TimeSpan.FromMinutes(3));
        RequestTimeout<CreateShippingLabel>(TimeSpan.FromMinutes(5));
    }

    protected override void ConfigureSaga(
        IReceiveEndpointConfigurator endpointConfigurator,
        ISagaConfigurator<OrderSaga> sagaConfigurator)
    {
        // Configure retry policy
        endpointConfigurator.UseMessageRetry(r => r.Intervals(
            TimeSpan.FromSeconds(5),
            TimeSpan.FromSeconds(10),
            TimeSpan.FromSeconds(30)));

        // Configure circuit breaker
        endpointConfigurator.UseCircuitBreaker(cb =>
        {
            cb.TrackingPeriod = TimeSpan.FromMinutes(1);
            cb.TripThreshold = 5;
            cb.ActiveThreshold = 3;
            cb.ResetInterval = TimeSpan.FromMinutes(5);
        });

        // Configure concurrency
        sagaConfigurator.UseConcurrentMessageLimit(10);
    }
}

// Enhanced saga with timeout handling
public partial class OrderSaga
{
    public async Task Consume(ConsumeContext<RequestTimeout<ReserveInventory>> context)
    {
        if (CurrentState != "AwaitingInventoryReservation")
            return;

        _logger.LogWarning(
            "Inventory reservation timeout for order {OrderId}",
            OrderId);

        FailureReason = "Inventory reservation timed out";
        UpdateState("Failed");

        // Cancel the order
        await context.Publish(new CancelOrder(
            CorrelationId,
            OrderId,
            FailureReason));

        // Notify customer
        await context.Publish(new SendNotification(
            CorrelationId,
            CustomerId,
            "OrderTimeout",
            new Dictionary<string, object>
            {
                ["OrderId"] = OrderId,
                ["Stage"] = "Inventory Reservation",
                ["Reason"] = FailureReason
            }));
    }

    public async Task Consume(ConsumeContext<RequestTimeout<ProcessPayment>> context)
    {
        if (CurrentState != "AwaitingPayment")
            return;

        _logger.LogWarning(
            "Payment processing timeout for order {OrderId}",
            OrderId);

        FailureReason = "Payment processing timed out";
        UpdateState("Compensating");

        // Release inventory reservations
        await context.Publish(new ReleaseInventory(
            CorrelationId,
            OrderId,
            ReservationIds));

        // Cancel the order
        await context.Publish(new CancelOrder(
            CorrelationId,
            OrderId,
            FailureReason));

        UpdateState("Failed");
    }

    // Add saga metrics
    private static readonly Counter OrdersStarted = Metrics
        .CreateCounter("order_saga_started_total", "Total number of order sagas started");
        
    private static readonly Counter OrdersCompleted = Metrics
        .CreateCounter("order_saga_completed_total", "Total number of order sagas completed");
        
    private static readonly Counter OrdersFailed = Metrics
        .CreateCounter("order_saga_failed_total", "Total number of order sagas failed");
        
    private static readonly Histogram SagaDuration = Metrics
        .CreateHistogram("order_saga_duration_seconds", "Duration of order saga execution");

    private void RecordMetrics()
    {
        switch (CurrentState)
        {
            case "Completed":
                OrdersCompleted.Inc();
                SagaDuration.Observe((DateTime.UtcNow - CreatedAt).TotalSeconds);
                break;
            case "Failed":
                OrdersFailed.Inc();
                break;
        }
    }
}
```

### 1.2 Add Saga State Machine Visualization

Create `src/Services/Order/Sagas/OrderSagaStateMachine.cs`:

```csharp
namespace Ecommerce.Order.Sagas;

public class OrderSagaStateMachine : MassTransitStateMachine<OrderSagaState>
{
    public State AwaitingInventoryReservation { get; private set; } = null!;
    public State AwaitingPayment { get; private set; } = null!;
    public State AwaitingShipping { get; private set; } = null!;
    public State Compensating { get; private set; } = null!;
    public State Completed { get; private set; } = null!;
    public State Failed { get; private set; } = null!;

    public Event<OrderSubmitted> OrderSubmitted { get; private set; } = null!;
    public Event<InventoryReserved> InventoryReserved { get; private set; } = null!;
    public Event<InventoryReservationFailed> InventoryReservationFailed { get; private set; } = null!;
    public Event<PaymentProcessed> PaymentProcessed { get; private set; } = null!;
    public Event<PaymentFailed> PaymentFailed { get; private set; } = null!;
    public Event<ShippingLabelCreated> ShippingLabelCreated { get; private set; } = null!;
    public Event<ShippingFailed> ShippingFailed { get; private set; } = null!

    public OrderSagaStateMachine()
    {
        InstanceState(x => x.CurrentState);

        Event(() => OrderSubmitted, x => x.CorrelateById(context => context.Message.OrderId));
        Event(() => InventoryReserved, x => x.CorrelateById(context => context.Message.OrderId));
        Event(() => InventoryReservationFailed, x => x.CorrelateById(context => context.Message.OrderId));
        Event(() => PaymentProcessed, x => x.CorrelateById(context => context.Message.OrderId));
        Event(() => PaymentFailed, x => x.CorrelateById(context => context.Message.OrderId));
        Event(() => ShippingLabelCreated, x => x.CorrelateById(context => context.Message.OrderId));
        Event(() => ShippingFailed, x => x.CorrelateById(context => context.Message.OrderId));

        Initially(
            When(OrderSubmitted)
                .Then(context =>
                {
                    context.Saga.OrderId = context.Message.OrderId;
                    context.Saga.CustomerId = context.Message.CustomerId;
                    context.Saga.TotalAmount = context.Message.TotalAmount;
                    context.Saga.Items = context.Message.Items;
                })
                .PublishAsync(context => context.Init<ReserveInventory>(new
                {
                    context.Saga.CorrelationId,
                    context.Saga.OrderId,
                    Items = context.Saga.Items.Select(i => new
                    {
                        i.ProductId,
                        i.SKU,
                        i.Quantity
                    })
                }))
                .TransitionTo(AwaitingInventoryReservation)
        );

        During(AwaitingInventoryReservation,
            When(InventoryReserved)
                .Then(context =>
                {
                    context.Saga.ReservationIds = context.Message.ReservedItems
                        .Select(r => r.ReservationId).ToList();
                })
                .PublishAsync(context => context.Init<ProcessPayment>(new
                {
                    context.Saga.CorrelationId,
                    context.Saga.OrderId,
                    context.Saga.CustomerId,
                    Amount = context.Saga.TotalAmount,
                    Currency = "USD",
                    PaymentMethod = context.Saga.PaymentMethod
                }))
                .TransitionTo(AwaitingPayment),
                
            When(InventoryReservationFailed)
                .Then(context =>
                {
                    context.Saga.FailureReason = context.Message.Reason;
                })
                .PublishAsync(context => context.Init<CancelOrder>(new
                {
                    context.Saga.CorrelationId,
                    context.Saga.OrderId,
                    Reason = context.Saga.FailureReason
                }))
                .TransitionTo(Failed)
                .Finalize()
        );

        During(AwaitingPayment,
            When(PaymentProcessed)
                .Then(context =>
                {
                    context.Saga.PaymentTransactionId = context.Message.TransactionId;
                })
                .PublishAsync(context => context.Init<CreateShippingLabel>(new
                {
                    context.Saga.CorrelationId,
                    context.Saga.OrderId,
                    context.Saga.CustomerId,
                    ShippingAddress = context.Saga.ShippingAddress,
                    Items = context.Saga.Items.Select(i => new
                    {
                        i.ProductId,
                        i.ProductName,
                        i.Quantity
                    })
                }))
                .TransitionTo(AwaitingShipping),
                
            When(PaymentFailed)
                .Then(context =>
                {
                    context.Saga.FailureReason = context.Message.Reason;
                })
                .TransitionTo(Compensating)
                .PublishAsync(context => context.Init<ReleaseInventory>(new
                {
                    context.Saga.CorrelationId,
                    context.Saga.OrderId,
                    context.Saga.ReservationIds
                }))
        );

        During(AwaitingShipping,
            When(ShippingLabelCreated)
                .Then(context =>
                {
                    context.Saga.ShippingTrackingNumber = context.Message.TrackingNumber;
                })
                .PublishAsync(context => context.Init<ConfirmOrder>(new
                {
                    context.Saga.CorrelationId,
                    context.Saga.OrderId,
                    ConfirmationNumber = GenerateConfirmationNumber(context.Saga)
                }))
                .TransitionTo(Completed)
                .Finalize(),
                
            When(ShippingFailed)
                .TransitionTo(Compensating)
                .PublishAsync(context => context.Init<RefundPayment>(new
                {
                    context.Saga.CorrelationId,
                    context.Saga.OrderId,
                    TransactionId = context.Saga.PaymentTransactionId,
                    Amount = context.Saga.TotalAmount,
                    Reason = "Shipping failed"
                }))
        );

        SetCompletedWhenFinalized();
    }

    private static string GenerateConfirmationNumber(OrderSagaState saga)
    {
        return $"ORD-{DateTime.UtcNow:yyyyMMdd}-{saga.OrderId.ToString()[..8].ToUpper()}";
    }
}

public class OrderSagaState : SagaStateMachineInstance
{
    public Guid CorrelationId { get; set; }
    public string CurrentState { get; set; } = null!;
    public Guid OrderId { get; set; }
    public Guid CustomerId { get; set; }
    public decimal TotalAmount { get; set; }
    public List<OrderItem> Items { get; set; } = new();
    public List<Guid> ReservationIds { get; set; } = new();
    public string? PaymentTransactionId { get; set; }
    public string? ShippingTrackingNumber { get; set; }
    public string? FailureReason { get; set; }
    public Address? ShippingAddress { get; set; }
    public PaymentMethod? PaymentMethod { get; set; }
}
```

## 🧪 Step 2: Integration Testing

### 2.1 Create Test Infrastructure

Create `tests/Integration/TestInfrastructure/MicroservicesTestFactory.cs`:

```csharp
namespace Ecommerce.Tests.Integration.TestInfrastructure;

public class MicroservicesTestFactory : IAsyncLifetime
{
    private readonly MsSqlContainer _sqlContainer;
    private readonly MongoDbContainer _mongoContainer;
    private readonly RedisContainer _redisContainer;
    private readonly RabbitMqContainer _rabbitMqContainer;
    private readonly Dictionary<string, WebApplicationFactory<Program>> _serviceFactories;
    
    public MicroservicesTestFactory()
    {
        _sqlContainer = new MsSqlBuilder()
            .WithImage("mcr.microsoft.com/mssql/server:2022-latest")
            .Build();
            
        _mongoContainer = new MongoDbBuilder()
            .WithImage("mongo:6")
            .Build();
            
        _redisContainer = new RedisBuilder()
            .WithImage("redis:alpine")
            .Build();
            
        _rabbitMqContainer = new RabbitMqBuilder()
            .WithImage("rabbitmq:3-management")
            .Build();
            
        _serviceFactories = new Dictionary<string, WebApplicationFactory<Program>>();
    }

    public async Task InitializeAsync()
    {
        // Start all containers in parallel
        await Task.WhenAll(
            _sqlContainer.StartAsync(),
            _mongoContainer.StartAsync(),
            _redisContainer.StartAsync(),
            _rabbitMqContainer.StartAsync()
        );

        // Configure service factories
        await ConfigureServices();
    }

    private async Task ConfigureServices()
    {
        var sqlConnectionString = _sqlContainer.GetConnectionString();
        var mongoConnectionString = _mongoContainer.GetConnectionString();
        var redisConnectionString = _redisContainer.GetConnectionString();
        var rabbitMqConnectionString = _rabbitMqContainer.GetConnectionString();

        // Order Service
        _serviceFactories["Order"] = CreateServiceFactory<Order.API.Program>(builder =>
        {
            builder.ConfigureServices(services =>
            {
                RemoveService<IMongoClient>(services);
                services.AddSingleton<IMongoClient>(_ => new MongoClient(mongoConnectionString));
                
                RemoveService<DbContextOptions<OrderReadDbContext>>(services);
                services.AddDbContext<OrderReadDbContext>(options =>
                    options.UseSqlServer(sqlConnectionString));
            });
        });

        // Similar configuration for other services...
    }

    public HttpClient GetServiceClient(string serviceName)
    {
        if (!_serviceFactories.TryGetValue(serviceName, out var factory))
            throw new ArgumentException($"Service {serviceName} not configured");
            
        return factory.CreateClient();
    }

    public async Task DisposeAsync()
    {
        foreach (var factory in _serviceFactories.Values)
        {
            await factory.DisposeAsync();
        }

        await Task.WhenAll(
            _sqlContainer.DisposeAsync().AsTask(),
            _mongoContainer.DisposeAsync().AsTask(),
            _redisContainer.DisposeAsync().AsTask(),
            _rabbitMqContainer.DisposeAsync().AsTask()
        );
    }

    private WebApplicationFactory<T> CreateServiceFactory<T>(
        Action<IWebHostBuilder> configure) where T : class
    {
        return new WebApplicationFactory<T>()
            .WithWebHostBuilder(builder =>
            {
                configure(builder);
                builder.UseEnvironment("Testing");
            });
    }

    private static void RemoveService<T>(IServiceCollection services)
    {
        var descriptor = services.SingleOrDefault(d => d.ServiceType == typeof(T));
        if (descriptor != null)
            services.Remove(descriptor);
    }
}
```

### 2.2 Create End-to-End Order Test

Create `tests/Integration/Scenarios/OrderProcessingTests.cs`:

```csharp
namespace Ecommerce.Tests.Integration.Scenarios;

[Collection("Microservices")]
public class OrderProcessingTests : IClassFixture<MicroservicesTestFactory>
{
    private readonly MicroservicesTestFactory _factory;
    private readonly ITestOutputHelper _output;

    public OrderProcessingTests(
        MicroservicesTestFactory factory,
        ITestOutputHelper output)
    {
        _factory = factory;
        _output = output;
    }

    [Fact]
    public async Task CompleteOrderFlow_ShouldProcessSuccessfully()
    {
        // Arrange
        var orderClient = _factory.GetServiceClient("Order");
        var customerId = Guid.NewGuid();
        
        var createOrderRequest = new CreateOrderCommand
        {
            CustomerId = customerId,
            Items = new List<OrderItemDto>
            {
                new(Guid.NewGuid(), "Laptop", "LAPTOP-001", 1, 999.99m, 999.99m),
                new(Guid.NewGuid(), "Mouse", "MOUSE-001", 2, 29.99m, 59.98m)
            },
            ShippingAddress = new AddressDto(
                "123 Main St", "Seattle", "WA", "98101", "USA"),
            PaymentMethod = new PaymentMethodDto(
                "card", "4242", "test_token_123")
        };

        // Act - Create order
        var response = await orderClient.PostAsJsonAsync(
            "/api/v1/orders", 
            createOrderRequest);

        // Assert - Order created
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        
        var order = await response.Content.ReadFromJsonAsync<OrderDto>();
        order.Should().NotBeNull();
        order!.Status.Should().Be(OrderStatus.Pending);
        
        _output.WriteLine($"Order created: {order.Id}");

        // Wait for saga to complete
        await WaitForOrderStatus(
            orderClient,
            order.Id,
            OrderStatus.Confirmed,
            TimeSpan.FromSeconds(30));

        // Verify final state
        var finalOrderResponse = await orderClient.GetAsync($"/api/v1/orders/{order.Id}");
        var finalOrder = await finalOrderResponse.Content.ReadFromJsonAsync<OrderDto>();
        
        finalOrder!.Status.Should().Be(OrderStatus.Confirmed);
        finalOrder.ConfirmationNumber.Should().NotBeNullOrEmpty();
        
        _output.WriteLine($"Order confirmed: {finalOrder.ConfirmationNumber}");
    }

    [Fact]
    public async Task OrderWithInsufficientInventory_ShouldBeCancelled()
    {
        // Arrange
        var orderClient = _factory.GetServiceClient("Order");
        var inventoryClient = _factory.GetServiceClient("Inventory");
        
        // Set up inventory with low stock
        var productId = Guid.NewGuid();
        await CreateInventoryItem(inventoryClient, productId, "SCARCE-001", 1);

        var createOrderRequest = new CreateOrderCommand
        {
            CustomerId = Guid.NewGuid(),
            Items = new List<OrderItemDto>
            {
                new(productId, "Scarce Item", "SCARCE-001", 5, 100m, 500m)
            },
            ShippingAddress = new AddressDto(
                "456 Oak Ave", "Portland", "OR", "97201", "USA"),
            PaymentMethod = new PaymentMethodDto(
                "card", "4242", "test_token_456")
        };

        // Act
        var response = await orderClient.PostAsJsonAsync(
            "/api/v1/orders", 
            createOrderRequest);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        
        var order = await response.Content.ReadFromJsonAsync<OrderDto>();
        
        // Wait for cancellation
        await WaitForOrderStatus(
            orderClient,
            order!.Id,
            OrderStatus.Cancelled,
            TimeSpan.FromSeconds(20));

        // Verify cancellation reason
        var cancelledOrderResponse = await orderClient.GetAsync($"/api/v1/orders/{order.Id}");
        var cancelledOrder = await cancelledOrderResponse.Content.ReadFromJsonAsync<OrderDto>();
        
        cancelledOrder!.Status.Should().Be(OrderStatus.Cancelled);
        
        _output.WriteLine($"Order cancelled due to insufficient inventory");
    }

    [Fact]
    public async Task OrderWithPaymentFailure_ShouldReleaseInventoryAndCancel()
    {
        // Arrange
        var orderClient = _factory.GetServiceClient("Order");
        
        var createOrderRequest = new CreateOrderCommand
        {
            CustomerId = Guid.NewGuid(),
            Items = new List<OrderItemDto>
            {
                new(Guid.NewGuid(), "Test Product", "TEST-001", 1, 50m, 50m)
            },
            ShippingAddress = new AddressDto(
                "789 Pine St", "Denver", "CO", "80202", "USA"),
            PaymentMethod = new PaymentMethodDto(
                "card", "0000", "declined_token") // Token that triggers decline
        };

        // Act
        var response = await orderClient.PostAsJsonAsync(
            "/api/v1/orders", 
            createOrderRequest);

        // Assert
        var order = await response.Content.ReadFromJsonAsync<OrderDto>();
        
        // Wait for cancellation due to payment failure
        await WaitForOrderStatus(
            orderClient,
            order!.Id,
            OrderStatus.Cancelled,
            TimeSpan.FromSeconds(30));

        // Verify inventory was released
        // This would require checking inventory service state
        
        _output.WriteLine($"Order cancelled due to payment failure, inventory released");
    }

    private async Task WaitForOrderStatus(
        HttpClient client,
        Guid orderId,
        OrderStatus expectedStatus,
        TimeSpan timeout)
    {
        var stopwatch = Stopwatch.StartNew();
        
        while (stopwatch.Elapsed < timeout)
        {
            var response = await client.GetAsync($"/api/v1/orders/{orderId}");
            
            if (response.IsSuccessStatusCode)
            {
                var order = await response.Content.ReadFromJsonAsync<OrderDto>();
                
                if (order?.Status == expectedStatus)
                {
                    return;
                }
            }
            
            await Task.Delay(TimeSpan.FromSeconds(1));
        }
        
        throw new TimeoutException(
            $"Order {orderId} did not reach status {expectedStatus} within {timeout}");
    }

    private async Task CreateInventoryItem(
        HttpClient inventoryClient,
        Guid productId,
        string sku,
        int quantity)
    {
        var createInventoryRequest = new
        {
            ProductId = productId,
            SKU = sku,
            ProductName = "Test Product",
            InitialQuantity = quantity,
            ReorderPoint = 5,
            ReorderQuantity = 10
        };

        var response = await inventoryClient.PostAsJsonAsync(
            "/api/v1/inventory/items",
            createInventoryRequest);
            
        response.EnsureSuccessStatusCode();
    }
}
```

## 🌪️ Step 3: Chaos Engineering Tests

### 3.1 Create Chaos Test Base

Create `tests/Chaos/ChaosTestBase.cs`:

```csharp
namespace Ecommerce.Tests.Chaos;

public abstract class ChaosTestBase : IAsyncLifetime
{
    protected MicroservicesTestFactory Factory { get; }
    protected ITestOutputHelper Output { get; }
    protected ChaosMonkey ChaosMonkey { get; }
    
    protected ChaosTestBase(
        MicroservicesTestFactory factory,
        ITestOutputHelper output)
    {
        Factory = factory;
        Output = output;
        ChaosMonkey = new ChaosMonkey();
    }

    public Task InitializeAsync() => Task.CompletedTask;
    public Task DisposeAsync() => ChaosMonkey.RestoreOrder();
}

public class ChaosMonkey
{
    private readonly List<IDisposable> _chaosActions = new();
    
    public async Task<IDisposable> InjectNetworkLatency(
        string serviceName,
        TimeSpan latency,
        double percentage = 0.5)
    {
        // Use tc (traffic control) or similar to inject latency
        var action = new NetworkLatencyAction(serviceName, latency, percentage);
        await action.Apply();
        _chaosActions.Add(action);
        return action;
    }
    
    public async Task<IDisposable> KillService(string serviceName)
    {
        var action = new KillServiceAction(serviceName);
        await action.Apply();
        _chaosActions.Add(action);
        return action;
    }
    
    public async Task<IDisposable> ConsumeResources(
        string serviceName,
        int cpuPercentage = 80,
        int memoryMB = 500)
    {
        var action = new ResourceConsumptionAction(
            serviceName, 
            cpuPercentage, 
            memoryMB);
        await action.Apply();
        _chaosActions.Add(action);
        return action;
    }
    
    public async Task<IDisposable> DropMessages(
        string queueName,
        double percentage = 0.1)
    {
        var action = new MessageDropAction(queueName, percentage);
        await action.Apply();
        _chaosActions.Add(action);
        return action;
    }
    
    public async Task RestoreOrder()
    {
        foreach (var action in _chaosActions)
        {
            action.Dispose();
        }
        _chaosActions.Clear();
        
        // Wait for system to stabilize
        await Task.Delay(TimeSpan.FromSeconds(5));
    }
}
```

### 3.2 Create Resilience Tests

Create `tests/Chaos/ResilienceTests.cs`:

```csharp
namespace Ecommerce.Tests.Chaos;

[Collection("Chaos")]
public class ResilienceTests : ChaosTestBase
{
    public ResilienceTests(
        MicroservicesTestFactory factory,
        ITestOutputHelper output) : base(factory, output)
    {
    }

    [Fact]
    public async Task OrderProcessing_WithNetworkLatency_ShouldCompleteEventually()
    {
        // Arrange
        var orderClient = Factory.GetServiceClient("Order");
        
        // Inject 500ms latency on 50% of network calls
        using (await ChaosMonkey.InjectNetworkLatency("Inventory", TimeSpan.FromMilliseconds(500)))
        using (await ChaosMonkey.InjectNetworkLatency("Payment", TimeSpan.FromMilliseconds(500)))
        {
            // Act
            var startTime = DateTime.UtcNow;
            var response = await CreateTestOrder(orderClient);
            
            // Assert
            response.StatusCode.Should().Be(HttpStatusCode.Created);
            
            var order = await response.Content.ReadFromJsonAsync<OrderDto>();
            
            // Should complete but take longer
            await WaitForOrderCompletion(orderClient, order!.Id, TimeSpan.FromMinutes(2));
            
            var duration = DateTime.UtcNow - startTime;
            Output.WriteLine($"Order completed with latency in {duration.TotalSeconds}s");
            
            // Verify it took longer than normal
            duration.Should().BeGreaterThan(TimeSpan.FromSeconds(10));
        }
    }

    [Fact]
    public async Task OrderProcessing_WithServiceFailure_ShouldRecover()
    {
        // Arrange
        var orderClient = Factory.GetServiceClient("Order");
        var order = await CreateAndGetOrder(orderClient);
        
        // Act - Kill payment service mid-processing
        await Task.Delay(TimeSpan.FromSeconds(2)); // Let it start processing
        
        using (await ChaosMonkey.KillService("Payment"))
        {
            // Wait for timeout
            await Task.Delay(TimeSpan.FromSeconds(10));
        }
        
        // Payment service should recover
        await Task.Delay(TimeSpan.FromSeconds(5));
        
        // Assert - Order should eventually complete or cancel properly
        var finalOrder = await GetOrder(orderClient, order.Id);
        
        finalOrder.Status.Should().BeOneOf(
            OrderStatus.Confirmed,  // Retry succeeded
            OrderStatus.Cancelled); // Properly cancelled
            
        Output.WriteLine($"Order {finalOrder.Status} after payment service recovery");
    }

    [Fact]
    public async Task OrderProcessing_WithMessageLoss_ShouldUseRetries()
    {
        // Arrange
        var orderClient = Factory.GetServiceClient("Order");
        
        // Drop 30% of messages
        using (await ChaosMonkey.DropMessages("order-events", 0.3))
        {
            // Act - Create multiple orders
            var tasks = Enumerable.Range(0, 10)
                .Select(_ => CreateTestOrder(orderClient))
                .ToList();
                
            var responses = await Task.WhenAll(tasks);
            
            // Assert - All should succeed despite message loss
            responses.Should().AllSatisfy(r => 
                r.StatusCode.Should().Be(HttpStatusCode.Created));
                
            // Wait for processing with retries
            var orders = new List<OrderDto>();
            foreach (var response in responses)
            {
                var order = await response.Content.ReadFromJsonAsync<OrderDto>();
                orders.Add(order!);
            }
            
            // Check completion rate
            var completionTasks = orders.Select(o => 
                CheckOrderEventualState(orderClient, o.Id, TimeSpan.FromMinutes(3)));
                
            var results = await Task.WhenAll(completionTasks);
            
            var successRate = results.Count(r => r == OrderStatus.Confirmed) / (double)results.Length;
            
            Output.WriteLine($"Success rate with 30% message loss: {successRate:P}");
            
            // Should have high success rate due to retries
            successRate.Should().BeGreaterThan(0.8);
        }
    }

    [Fact]
    public async Task OrderProcessing_WithResourceExhaustion_ShouldDegradeGracefully()
    {
        // Arrange
        var orderClient = Factory.GetServiceClient("Order");
        
        // Consume resources on inventory service
        using (await ChaosMonkey.ConsumeResources("Inventory", cpuPercentage: 90, memoryMB: 800))
        {
            // Act - Create orders under resource pressure
            var tasks = new List<Task<HttpResponseMessage>>();
            var stopwatch = Stopwatch.StartNew();
            
            for (int i = 0; i < 20; i++)
            {
                tasks.Add(CreateTestOrder(orderClient));
                await Task.Delay(100); // Stagger requests
            }
            
            var responses = await Task.WhenAll(tasks);
            stopwatch.Stop();
            
            // Assert
            var successCount = responses.Count(r => r.IsSuccessStatusCode);
            var avgResponseTime = stopwatch.ElapsedMilliseconds / 20.0;
            
            Output.WriteLine($"Under resource pressure: {successCount}/20 succeeded");
            Output.WriteLine($"Average response time: {avgResponseTime}ms");
            
            // Should handle some requests even under pressure
            successCount.Should().BeGreaterThan(10);
            
            // Response times should be elevated but not timeout
            avgResponseTime.Should().BeLessThan(5000);
        }
    }

    [Fact]
    public async Task SagaCompensation_WithMultipleFailures_ShouldMaintainConsistency()
    {
        // Arrange
        var orderClient = Factory.GetServiceClient("Order");
        var inventoryClient = Factory.GetServiceClient("Inventory");
        
        // Get initial inventory state
        var initialInventory = await GetInventoryLevels(inventoryClient);
        
        // Inject failures
        using (await ChaosMonkey.KillService("Shipping"))
        using (await ChaosMonkey.InjectNetworkLatency("Payment", TimeSpan.FromSeconds(10)))
        {
            // Act - Create orders that will fail
            var failedOrders = new List<OrderDto>();
            
            for (int i = 0; i < 5; i++)
            {
                var response = await CreateTestOrder(orderClient);
                if (response.IsSuccessStatusCode)
                {
                    var order = await response.Content.ReadFromJsonAsync<OrderDto>();
                    failedOrders.Add(order!);
                }
            }
            
            // Wait for compensations
            await Task.Delay(TimeSpan.FromSeconds(30));
        }
        
        // Assert - Check system consistency
        var finalInventory = await GetInventoryLevels(inventoryClient);
        
        // Inventory should be restored after compensations
        foreach (var item in initialInventory)
        {
            var finalItem = finalInventory.FirstOrDefault(i => i.ProductId == item.ProductId);
            finalItem.Should().NotBeNull();
            finalItem!.AvailableQuantity.Should().Be(
                item.AvailableQuantity,
                "Inventory should be restored after compensation");
        }
        
        Output.WriteLine("System maintained consistency after multiple failures");
    }

    private async Task<HttpResponseMessage> CreateTestOrder(HttpClient orderClient)
    {
        var request = new CreateOrderCommand
        {
            CustomerId = Guid.NewGuid(),
            Items = new List<OrderItemDto>
            {
                new(Guid.NewGuid(), "Chaos Test Product", "CHAOS-001", 1, 99.99m, 99.99m)
            },
            ShippingAddress = new AddressDto(
                "123 Chaos St", "Chaos City", "CS", "12345", "USA"),
            PaymentMethod = new PaymentMethodDto("card", "4242", "test_token")
        };
        
        return await orderClient.PostAsJsonAsync("/api/v1/orders", request);
    }

    private async Task WaitForOrderCompletion(
        HttpClient client,
        Guid orderId,
        TimeSpan timeout)
    {
        var endTime = DateTime.UtcNow.Add(timeout);
        
        while (DateTime.UtcNow < endTime)
        {
            var order = await GetOrder(client, orderId);
            
            if (order.Status == OrderStatus.Confirmed || 
                order.Status == OrderStatus.Cancelled)
            {
                return;
            }
            
            await Task.Delay(TimeSpan.FromSeconds(2));
        }
        
        throw new TimeoutException($"Order {orderId} did not complete within {timeout}");
    }

    private async Task<OrderStatus> CheckOrderEventualState(
        HttpClient client,
        Guid orderId,
        TimeSpan timeout)
    {
        try
        {
            await WaitForOrderCompletion(client, orderId, timeout);
            var order = await GetOrder(client, orderId);
            return order.Status;
        }
        catch (TimeoutException)
        {
            return OrderStatus.Pending; // Still processing
        }
    }
}
```

## 🚀 Step 4: Kubernetes Deployment

### 4.1 Create Kubernetes Manifests

Create `k8s/base/namespace.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ecommerce-microservices
  labels:
    name: ecommerce-microservices
    istio-injection: enabled
```

Create `k8s/services/order-service.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  namespace: ecommerce-microservices
  labels:
    app: order-service
    version: v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: order-service
      version: v1
  template:
    metadata:
      labels:
        app: order-service
        version: v1
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: order-service
      containers:
      - name: order-service
        image: ecommerce/order-service:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
          name: http
        - containerPort: 8081
          name: metrics
        env:
        - name: ASPNETCORE_ENVIRONMENT
          value: "Production"
        - name: ASPNETCORE_URLS
          value: "http://+:8080"
        - name: ConnectionStrings__DefaultConnection
          valueFrom:
            secretKeyRef:
              name: order-service-secrets
              key: sql-connection
        - name: ConnectionStrings__EventStore
          valueFrom:
            secretKeyRef:
              name: order-service-secrets
              key: mongo-connection
        - name: ServiceBus__ConnectionString
          valueFrom:
            secretKeyRef:
              name: shared-secrets
              key: servicebus-connection
        - name: Jaeger__AgentHost
          value: jaeger-agent.istio-system
        - name: Jaeger__AgentPort
          value: "6831"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 30
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15"]
---
apiVersion: v1
kind: Service
metadata:
  name: order-service
  namespace: ecommerce-microservices
  labels:
    app: order-service
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
  - port: 8081
    targetPort: 8081
    protocol: TCP
    name: metrics
  selector:
    app: order-service
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: order-service
  namespace: ecommerce-microservices
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: order-service-pdb
  namespace: ecommerce-microservices
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: order-service
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: order-service-hpa
  namespace: ecommerce-microservices
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: order-service
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 60
      - type: Pods
        value: 2
        periodSeconds: 60
      selectPolicy: Max
```

### 4.2 Create Istio Service Mesh Configuration

Create `k8s/istio/virtual-service.yaml`:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: order-service
  namespace: ecommerce-microservices
spec:
  hosts:
  - order-service
  http:
  - match:
    - headers:
        x-version:
          exact: v2
    route:
    - destination:
        host: order-service
        subset: v2
      weight: 100
  - route:
    - destination:
        host: order-service
        subset: v1
      weight: 90
    - destination:
        host: order-service
        subset: v2
      weight: 10
    timeout: 30s
    retries:
      attempts: 3
      perTryTimeout: 10s
      retryOn: 5xx,retriable-4xx,refused-stream,cancelled,deadline-exceeded,internal,resource-exhausted,unavailable
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: order-service
  namespace: ecommerce-microservices
spec:
  host: order-service
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        http2MaxRequests: 100
        maxRequestsPerConnection: 2
    loadBalancer:
      simple: LEAST_REQUEST
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
      minHealthPercent: 50
      splitExternalLocalOriginErrors: true
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

## 📊 Step 5: Monitoring and Observability

### 5.1 Create Grafana Dashboard

Create `monitoring/dashboards/microservices-dashboard.json`:

```json
{
  "dashboard": {
    "title": "Ecommerce Microservices Dashboard",
    "panels": [
      {
        "title": "Order Processing Rate",
        "targets": [
          {
            "expr": "sum(rate(order_saga_started_total[5m]))",
            "legendFormat": "Orders Started"
          },
          {
            "expr": "sum(rate(order_saga_completed_total[5m]))",
            "legendFormat": "Orders Completed"
          },
          {
            "expr": "sum(rate(order_saga_failed_total[5m]))",
            "legendFormat": "Orders Failed"
          }
        ]
      },
      {
        "title": "Service Response Times (p95)",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (service, le))",
            "legendFormat": "{{service}}"
          }
        ]
      },
      {
        "title": "Service Error Rates",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{status_code=~\"5..\"}[5m])) by (service) / sum(rate(http_requests_total[5m])) by (service)",
            "legendFormat": "{{service}}"
          }
        ]
      },
      {
        "title": "Saga State Distribution",
        "targets": [
          {
            "expr": "sum(order_saga_state_count) by (state)",
            "legendFormat": "{{state}}"
          }
        ]
      },
      {
        "title": "Message Bus Throughput",
        "targets": [
          {
            "expr": "sum(rate(masstransit_messages_received_total[5m])) by (message_type)",
            "legendFormat": "{{message_type}}"
          }
        ]
      },
      {
        "title": "Inventory Levels",
        "targets": [
          {
            "expr": "avg(inventory_available_quantity) by (product_name)",
            "legendFormat": "{{product_name}}"
          }
        ]
      }
    ]
  }
}
```

### 5.2 Create Alerts

Create `monitoring/alerts/saga-alerts.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: saga-alerts
  namespace: ecommerce-microservices
spec:
  groups:
  - name: saga.rules
    interval: 30s
    rules:
    - alert: HighOrderFailureRate
      expr: |
        (sum(rate(order_saga_failed_total[5m])) / sum(rate(order_saga_started_total[5m]))) > 0.1
      for: 5m
      labels:
        severity: critical
        service: order-saga
      annotations:
        summary: "High order failure rate detected"
        description: "Order failure rate is {{ $value | humanizePercentage }} over the last 5 minutes"
        
    - alert: SagaProcessingDelayed
      expr: |
        histogram_quantile(0.95, sum(rate(order_saga_duration_seconds_bucket[5m])) by (le)) > 60
      for: 10m
      labels:
        severity: warning
        service: order-saga
      annotations:
        summary: "Order processing is slow"
        description: "95th percentile order processing time is {{ $value }}s"
        
    - alert: InventoryReservationFailures
      expr: |
        sum(rate(inventory_reservation_failed_total[5m])) > 5
      for: 5m
      labels:
        severity: warning
        service: inventory
      annotations:
        summary: "High inventory reservation failures"
        description: "{{ $value }} inventory reservations failed in the last 5 minutes"
        
    - alert: PaymentServiceDown
      expr: |
        up{job="payment-service"} == 0
      for: 1m
      labels:
        severity: critical
        service: payment
      annotations:
        summary: "Payment service is down"
        description: "Payment service has been down for more than 1 minute"
```

## 💡 Copilot Prompt Suggestions

**For Load Testing:**
```
Create a k6 load test script that:
- Simulates 1000 concurrent users
- Creates orders with varying item counts
- Measures end-to-end latency
- Tracks success/failure rates
- Generates HTML report
Include ramp-up and cool-down periods
```

**For Deployment Automation:**
```
Create a GitHub Actions workflow that:
- Builds all microservice Docker images
- Runs integration tests
- Deploys to Kubernetes staging
- Runs smoke tests
- Promotes to production on approval
Include rollback capabilities
```

**For Monitoring:**
```
Create a custom Prometheus exporter that:
- Tracks business metrics (order value, popular products)
- Monitors saga state transitions
- Calculates compensation rates
- Exposes inventory turnover metrics
Use the Prometheus .NET client library
```

## ✅ Part 3 Checklist

Ensure you have:

- [ ] Completed saga orchestration with timeouts
- [ ] Implemented comprehensive integration tests
- [ ] Created chaos engineering tests
- [ ] Tested system resilience
- [ ] Created Kubernetes deployments
- [ ] Configured service mesh
- [ ] Set up monitoring dashboards
- [ ] Defined alerts for critical metrics
- [ ] Validated end-to-end workflow

## 🎯 Exercise Summary

Congratulations! You've successfully built a production-grade event-driven microservices system with:

- **Event Sourcing** for audit and replay capabilities
- **Saga Orchestration** for distributed transactions
- **CQRS Pattern** for scalable read/write operations
- **Resilience Patterns** for fault tolerance
- **Comprehensive Testing** including chaos engineering
- **Cloud-Native Deployment** with Kubernetes
- **Complete Observability** with metrics and tracing

## 🏆 Key Achievements

1. **Distributed System Design**
   - Clear service boundaries
   - Event-driven communication
   - Eventual consistency
   - Compensating transactions

2. **Production Readiness**
   - Health checks and probes
   - Graceful shutdowns
   - Circuit breakers
   - Retry policies

3. **Scalability**
   - Horizontal pod autoscaling
   - Database per service
   - Caching strategies
   - Async processing

4. **Observability**
   - Distributed tracing
   - Structured logging
   - Business metrics
   - Performance monitoring

## 📊 Performance Results

Your implementation should achieve:
- ✅ 10,000+ orders per minute
- ✅ <5 second end-to-end processing
- ✅ 99.9% success rate
- ✅ Automatic failure recovery
- ✅ Zero data loss

## 🎉 Completion

You've completed Exercise 2! This microservices architecture can scale to handle millions of transactions while maintaining consistency and reliability.

## ⏭️ Next Steps

1. Review the complete solution
2. Try additional scenarios:
   - Implement returns and refunds saga
   - Add recommendation service
   - Create analytics pipeline
3. Move on to [Exercise 3: AI-Powered Enterprise System](../exercise3-ai-enterprise/)

---

**🌟 Exceptional Work!** You've mastered event-driven microservices architecture, implementing patterns used by leading e-commerce platforms. This foundation enables you to build systems that scale globally while maintaining reliability and performance!