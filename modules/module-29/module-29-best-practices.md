# Enterprise .NET Best Practices

## 🎯 Overview

This guide provides comprehensive best practices for building enterprise-grade .NET applications. These patterns and principles ensure your solutions are maintainable, scalable, secure, and ready for production.

## 📋 Table of Contents

1. [Architecture Principles](#architecture-principles)
2. [Clean Architecture Implementation](#clean-architecture-implementation)
3. [Domain-Driven Design](#domain-driven-design)
4. [API Design](#api-design)
5. [Security Best Practices](#security-best-practices)
6. [Performance Optimization](#performance-optimization)
7. [AI Integration Patterns](#ai-integration-patterns)
8. [Testing Strategies](#testing-strategies)
9. [Observability & Monitoring](#observability--monitoring)
10. [Deployment & DevOps](#deployment--devops)

## 🏗️ Architecture Principles

### 1. Separation of Concerns

#### ✅ DO: Layer Your Application Properly
```csharp
// Domain Layer - Pure business logic
namespace Enterprise.Domain.Entities;

public class Order : AggregateRoot
{
    private readonly List<OrderItem> _items = new();
    
    public Guid Id { get; private set; }
    public CustomerId CustomerId { get; private set; }
    public Money TotalAmount { get; private set; }
    public OrderStatus Status { get; private set; }
    public IReadOnlyCollection<OrderItem> Items => _items.AsReadOnly();
    
    protected Order() { } // For EF
    
    public static Order Create(CustomerId customerId)
    {
        var order = new Order
        {
            Id = Guid.NewGuid(),
            CustomerId = customerId,
            Status = OrderStatus.Pending,
            TotalAmount = Money.Zero
        };
        
        order.AddDomainEvent(new OrderCreatedEvent(order.Id, customerId));
        return order;
    }
    
    public Result AddItem(Product product, int quantity)
    {
        if (Status != OrderStatus.Pending)
            return Result.Failure("Cannot add items to non-pending order");
            
        var item = OrderItem.Create(product, quantity);
        _items.Add(item);
        
        RecalculateTotal();
        return Result.Success();
    }
    
    private void RecalculateTotal()
    {
        TotalAmount = _items.Aggregate(
            Money.Zero, 
            (total, item) => total + item.TotalPrice
        );
    }
}

// Application Layer - Use cases
namespace Enterprise.Application.Orders.Commands;

public record CreateOrderCommand(Guid CustomerId) : IRequest<Result<OrderDto>>;

public class CreateOrderCommandHandler : IRequestHandler<CreateOrderCommand, Result<OrderDto>>
{
    private readonly IOrderRepository _orderRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IMapper _mapper;
    
    public CreateOrderCommandHandler(
        IOrderRepository orderRepository,
        IUnitOfWork unitOfWork,
        IMapper mapper)
    {
        _orderRepository = orderRepository;
        _unitOfWork = unitOfWork;
        _mapper = mapper;
    }
    
    public async Task<Result<OrderDto>> Handle(
        CreateOrderCommand request, 
        CancellationToken cancellationToken)
    {
        var customerId = new CustomerId(request.CustomerId);
        var order = Order.Create(customerId);
        
        await _orderRepository.AddAsync(order, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        
        return Result.Success(_mapper.Map<OrderDto>(order));
    }
}

// Infrastructure Layer - Data access
namespace Enterprise.Infrastructure.Persistence.Repositories;

public class OrderRepository : IOrderRepository
{
    private readonly ApplicationDbContext _context;
    
    public OrderRepository(ApplicationDbContext context)
    {
        _context = context;
    }
    
    public async Task<Order?> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        return await _context.Orders
            .Include(o => o.Items)
            .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);
    }
    
    public async Task AddAsync(Order order, CancellationToken cancellationToken)
    {
        await _context.Orders.AddAsync(order, cancellationToken);
    }
}
```

#### ❌ DON'T: Mix Concerns
```csharp
// Bad: Everything in one place
public class OrderService
{
    public async Task<Order> CreateOrder(Guid customerId)
    {
        // Domain logic mixed with data access
        using var connection = new SqlConnection(_connectionString);
        var order = new Order 
        { 
            Id = Guid.NewGuid(), 
            CustomerId = customerId,
            Status = "Pending" // Magic strings
        };
        
        // SQL in service layer
        await connection.ExecuteAsync(
            "INSERT INTO Orders (Id, CustomerId, Status) VALUES (@Id, @CustomerId, @Status)", 
            order);
            
        // Business logic mixed with infrastructure
        await SendEmail(customerId, "Order created"); // Email in service
        
        return order;
    }
}
```

### 2. Dependency Inversion

#### ✅ DO: Depend on Abstractions
```csharp
// Define interfaces in Application layer
namespace Enterprise.Application.Common.Interfaces;

public interface IEmailService
{
    Task SendAsync(EmailMessage message, CancellationToken cancellationToken = default);
}

public interface ICurrentUserService
{
    string? UserId { get; }
    string? UserName { get; }
    bool IsAuthenticated { get; }
    IEnumerable<string> Roles { get; }
}

// Implement in Infrastructure layer
namespace Enterprise.Infrastructure.Services;

public class EmailService : IEmailService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<EmailService> _logger;
    
    public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }
    
    public async Task SendAsync(EmailMessage message, CancellationToken cancellationToken)
    {
        try
        {
            // Use SendGrid, SMTP, or cloud service
            var apiKey = _configuration["SendGrid:ApiKey"];
            var client = new SendGridClient(apiKey);
            
            var msg = new SendGridMessage
            {
                From = new EmailAddress(_configuration["Email:From"]),
                Subject = message.Subject,
                HtmlContent = message.Body
            };
            
            msg.AddTo(message.To);
            
            var response = await client.SendEmailAsync(msg, cancellationToken);
            
            if (response.StatusCode != HttpStatusCode.OK)
            {
                _logger.LogError("Failed to send email. Status: {StatusCode}", response.StatusCode);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending email to {To}", message.To);
            throw;
        }
    }
}
```

### 3. Single Responsibility

#### ✅ DO: One Class, One Purpose
```csharp
// Good: Each class has a single responsibility
public class OrderValidator : AbstractValidator<CreateOrderCommand>
{
    public OrderValidator()
    {
        RuleFor(x => x.CustomerId)
            .NotEmpty()
            .WithMessage("Customer ID is required");
            
        RuleFor(x => x.Items)
            .NotEmpty()
            .WithMessage("Order must contain at least one item");
    }
}

public class OrderPricingService
{
    private readonly IDiscountService _discountService;
    private readonly ITaxCalculator _taxCalculator;
    
    public Money CalculateTotalPrice(Order order)
    {
        var subtotal = order.Items.Sum(i => i.TotalPrice);
        var discount = _discountService.CalculateDiscount(order);
        var tax = _taxCalculator.CalculateTax(subtotal - discount);
        
        return subtotal - discount + tax;
    }
}

public class OrderNotificationService
{
    private readonly IEmailService _emailService;
    private readonly ISmsService _smsService;
    
    public async Task NotifyOrderCreated(Order order)
    {
        await Task.WhenAll(
            _emailService.SendOrderConfirmation(order),
            _smsService.SendOrderNotification(order)
        );
    }
}
```

## 🧹 Clean Architecture Implementation

### Project Structure
```
src/
├── Enterprise.Domain/           # Enterprise business rules
│   ├── Entities/               # Domain entities
│   ├── ValueObjects/           # Value objects
│   ├── Events/                 # Domain events
│   ├── Exceptions/             # Domain exceptions
│   └── Common/                 # Base classes & interfaces
│
├── Enterprise.Application/      # Application business rules
│   ├── Common/                 # Interfaces, mappings, behaviors
│   ├── Features/               # Use cases (Commands/Queries)
│   │   ├── Orders/
│   │   │   ├── Commands/
│   │   │   └── Queries/
│   │   └── Products/
│   └── DTOs/                   # Data transfer objects
│
├── Enterprise.Infrastructure/   # External concerns
│   ├── Persistence/            # Database, repositories
│   ├── Services/               # External service implementations
│   ├── Identity/               # Authentication/Authorization
│   └── AI/                     # AI service integrations
│
└── Enterprise.API/             # Presentation layer
    ├── Controllers/            # API endpoints
    ├── Middleware/             # Custom middleware
    ├── Filters/                # Action filters
    └── Extensions/             # Service configuration
```

### Dependency Configuration
```csharp
// In API project - Program.cs
var builder = WebApplication.CreateBuilder(args);

// Add layers
builder.Services
    .AddApplication()
    .AddInfrastructure(builder.Configuration)
    .AddPresentation();

// Application layer registration
public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddMediatR(cfg => 
        {
            cfg.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly());
            cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));
            cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(LoggingBehavior<,>));
            cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(PerformanceBehavior<,>));
        });
        
        services.AddValidatorsFromAssembly(Assembly.GetExecutingAssembly());
        services.AddAutoMapper(Assembly.GetExecutingAssembly());
        
        return services;
    }
}
```

## 🏛️ Domain-Driven Design

### Aggregate Design
```csharp
public abstract class AggregateRoot : Entity
{
    private readonly List<IDomainEvent> _domainEvents = new();
    public IReadOnlyCollection<IDomainEvent> DomainEvents => _domainEvents.AsReadOnly();
    
    protected void AddDomainEvent(IDomainEvent domainEvent)
    {
        _domainEvents.Add(domainEvent);
    }
    
    public void ClearDomainEvents()
    {
        _domainEvents.Clear();
    }
}

// Rich domain model with behavior
public class Customer : AggregateRoot
{
    private readonly List<Address> _addresses = new();
    private readonly List<PaymentMethod> _paymentMethods = new();
    
    public CustomerId Id { get; private set; }
    public PersonName Name { get; private set; }
    public Email Email { get; private set; }
    public CustomerStatus Status { get; private set; }
    public CustomerTier Tier { get; private set; }
    public Credits AvailableCredits { get; private set; }
    
    public IReadOnlyCollection<Address> Addresses => _addresses.AsReadOnly();
    public IReadOnlyCollection<PaymentMethod> PaymentMethods => _paymentMethods.AsReadOnly();
    
    protected Customer() { } // For EF
    
    public static Result<Customer> Create(
        PersonName name, 
        Email email,
        Address initialAddress)
    {
        if (name == null) return Result<Customer>.Failure("Name is required");
        if (email == null) return Result<Customer>.Failure("Email is required");
        if (initialAddress == null) return Result<Customer>.Failure("Address is required");
        
        var customer = new Customer
        {
            Id = new CustomerId(Guid.NewGuid()),
            Name = name,
            Email = email,
            Status = CustomerStatus.Active,
            Tier = CustomerTier.Standard,
            AvailableCredits = Credits.Zero
        };
        
        customer._addresses.Add(initialAddress);
        customer.AddDomainEvent(new CustomerCreatedEvent(customer.Id, email));
        
        return Result<Customer>.Success(customer);
    }
    
    public Result UpgradeTier()
    {
        if (Status != CustomerStatus.Active)
            return Result.Failure("Only active customers can be upgraded");
            
        var newTier = Tier switch
        {
            CustomerTier.Standard => CustomerTier.Premium,
            CustomerTier.Premium => CustomerTier.VIP,
            CustomerTier.VIP => null,
            _ => null
        };
        
        if (newTier == null)
            return Result.Failure("Customer is already at highest tier");
            
        Tier = newTier.Value;
        AddDomainEvent(new CustomerTierUpgradedEvent(Id, newTier.Value));
        
        return Result.Success();
    }
}
```

### Value Objects
```csharp
public record Money : IComparable<Money>
{
    public decimal Amount { get; }
    public Currency Currency { get; }
    
    public Money(decimal amount, Currency currency)
    {
        if (amount < 0)
            throw new ArgumentException("Amount cannot be negative", nameof(amount));
            
        Amount = Math.Round(amount, currency.DecimalPlaces);
        Currency = currency;
    }
    
    public static Money Zero => new(0, Currency.USD);
    
    public static Money operator +(Money left, Money right)
    {
        if (left.Currency != right.Currency)
            throw new InvalidOperationException("Cannot add money with different currencies");
            
        return new Money(left.Amount + right.Amount, left.Currency);
    }
    
    public static Money operator -(Money left, Money right)
    {
        if (left.Currency != right.Currency)
            throw new InvalidOperationException("Cannot subtract money with different currencies");
            
        return new Money(left.Amount - right.Amount, left.Currency);
    }
    
    public static Money operator *(Money money, decimal multiplier)
    {
        return new Money(money.Amount * multiplier, money.Currency);
    }
    
    public int CompareTo(Money? other)
    {
        if (other is null) return 1;
        if (Currency != other.Currency)
            throw new InvalidOperationException("Cannot compare money with different currencies");
            
        return Amount.CompareTo(other.Amount);
    }
}

public record Email
{
    private static readonly Regex EmailRegex = new(
        @"^[^@\s]+@[^@\s]+\.[^@\s]+$",
        RegexOptions.Compiled | RegexOptions.IgnoreCase);
    
    public string Value { get; }
    
    public Email(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
            throw new ArgumentException("Email cannot be empty", nameof(value));
            
        if (!EmailRegex.IsMatch(value))
            throw new ArgumentException("Invalid email format", nameof(value));
            
        Value = value.ToLowerInvariant();
    }
    
    public static implicit operator string(Email email) => email.Value;
    public override string ToString() => Value;
}
```

### Domain Services
```csharp
public interface IOrderPricingService
{
    Money CalculateOrderTotal(Order order, Customer customer);
}

public class OrderPricingService : IOrderPricingService
{
    private readonly IPromotionRepository _promotionRepository;
    private readonly ITaxService _taxService;
    
    public OrderPricingService(
        IPromotionRepository promotionRepository,
        ITaxService taxService)
    {
        _promotionRepository = promotionRepository;
        _taxService = taxService;
    }
    
    public Money CalculateOrderTotal(Order order, Customer customer)
    {
        var subtotal = order.Items.Sum(item => item.TotalPrice);
        
        // Apply customer tier discount
        var tierDiscount = customer.Tier switch
        {
            CustomerTier.Premium => 0.05m,
            CustomerTier.VIP => 0.10m,
            _ => 0m
        };
        
        var afterTierDiscount = subtotal * (1 - tierDiscount);
        
        // Apply promotions
        var activePromotions = _promotionRepository
            .GetActivePromotions()
            .Where(p => p.IsApplicableTo(order, customer));
            
        var promotionDiscount = activePromotions
            .Select(p => p.CalculateDiscount(afterTierDiscount))
            .DefaultIfEmpty(Money.Zero)
            .Max();
            
        var afterPromotions = afterTierDiscount - promotionDiscount;
        
        // Calculate tax
        var tax = _taxService.CalculateTax(afterPromotions, customer.DefaultAddress);
        
        return afterPromotions + tax;
    }
}
```

## 🌐 API Design

### RESTful API Best Practices
```csharp
[ApiController]
[Route("api/v{version:apiVersion}/[controller]")]
[ApiVersion("1.0")]
[Produces("application/json")]
public class OrdersController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly ILogger<OrdersController> _logger;
    
    public OrdersController(IMediator mediator, ILogger<OrdersController> logger)
    {
        _mediator = mediator;
        _logger = logger;
    }
    
    /// <summary>
    /// Get order by ID
    /// </summary>
    /// <param name="id">Order ID</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Order details</returns>
    /// <response code="200">Order found</response>
    /// <response code="404">Order not found</response>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(Guid id, CancellationToken cancellationToken)
    {
        var query = new GetOrderByIdQuery(id);
        var result = await _mediator.Send(query, cancellationToken);
        
        return result.Match<IActionResult>(
            order => Ok(order),
            notFound => NotFound(new ProblemDetails 
            { 
                Title = "Order not found",
                Detail = $"Order with ID {id} was not found",
                Status = StatusCodes.Status404NotFound,
                Instance = HttpContext.Request.Path
            })
        );
    }
    
    /// <summary>
    /// Create a new order
    /// </summary>
    /// <param name="request">Order creation request</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Created order</returns>
    /// <response code="201">Order created successfully</response>
    /// <response code="400">Invalid request</response>
    [HttpPost]
    [ProducesResponseType(typeof(OrderDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create(
        [FromBody] CreateOrderRequest request,
        CancellationToken cancellationToken)
    {
        var command = new CreateOrderCommand(
            request.CustomerId,
            request.Items.Select(i => new OrderItemDto(i.ProductId, i.Quantity)).ToList()
        );
        
        var result = await _mediator.Send(command, cancellationToken);
        
        return result.Match<IActionResult>(
            order => CreatedAtAction(
                nameof(GetById), 
                new { id = order.Id }, 
                order),
            validationFailed => BadRequest(new ValidationProblemDetails
            {
                Errors = validationFailed.Errors
                    .GroupBy(e => e.PropertyName)
                    .ToDictionary(g => g.Key, g => g.Select(e => e.ErrorMessage).ToArray())
            })
        );
    }
    
    /// <summary>
    /// Get orders with pagination and filtering
    /// </summary>
    /// <param name="request">Query parameters</param>
    /// <param name="cancellationToken">Cancellation token</param>
    /// <returns>Paginated list of orders</returns>
    [HttpGet]
    [ProducesResponseType(typeof(PagedResult<OrderSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetOrders(
        [FromQuery] GetOrdersRequest request,
        CancellationToken cancellationToken)
    {
        var query = new GetOrdersQuery
        {
            PageNumber = request.PageNumber ?? 1,
            PageSize = request.PageSize ?? 20,
            Status = request.Status,
            CustomerId = request.CustomerId,
            FromDate = request.FromDate,
            ToDate = request.ToDate,
            SortBy = request.SortBy ?? "CreatedAt",
            SortDirection = request.SortDirection ?? SortDirection.Descending
        };
        
        var result = await _mediator.Send(query, cancellationToken);
        
        // Add pagination headers
        Response.Headers.Add("X-Page-Number", result.PageNumber.ToString());
        Response.Headers.Add("X-Page-Size", result.PageSize.ToString());
        Response.Headers.Add("X-Total-Count", result.TotalCount.ToString());
        Response.Headers.Add("X-Total-Pages", result.TotalPages.ToString());
        
        return Ok(result);
    }
}
```

### Global Error Handling
```csharp
public class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionMiddleware> _logger;
    private readonly IWebHostEnvironment _environment;
    
    public GlobalExceptionMiddleware(
        RequestDelegate next,
        ILogger<GlobalExceptionMiddleware> logger,
        IWebHostEnvironment environment)
    {
        _next = next;
        _logger = logger;
        _environment = environment;
    }
    
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "An unhandled exception occurred");
            await HandleExceptionAsync(context, ex);
        }
    }
    
    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.ContentType = "application/problem+json";
        
        var problemDetails = exception switch
        {
            ValidationException validationEx => new ValidationProblemDetails
            {
                Status = StatusCodes.Status400BadRequest,
                Title = "Validation failed",
                Detail = "One or more validation errors occurred",
                Errors = validationEx.Errors
                    .GroupBy(e => e.PropertyName)
                    .ToDictionary(g => g.Key, g => g.Select(e => e.ErrorMessage).ToArray())
            },
            
            NotFoundException notFoundEx => new ProblemDetails
            {
                Status = StatusCodes.Status404NotFound,
                Title = "Resource not found",
                Detail = notFoundEx.Message
            },
            
            UnauthorizedException => new ProblemDetails
            {
                Status = StatusCodes.Status401Unauthorized,
                Title = "Unauthorized",
                Detail = "You are not authorized to perform this action"
            },
            
            ForbiddenException => new ProblemDetails
            {
                Status = StatusCodes.Status403Forbidden,
                Title = "Forbidden",
                Detail = "You don't have permission to access this resource"
            },
            
            ConflictException conflictEx => new ProblemDetails
            {
                Status = StatusCodes.Status409Conflict,
                Title = "Conflict",
                Detail = conflictEx.Message
            },
            
            _ => new ProblemDetails
            {
                Status = StatusCodes.Status500InternalServerError,
                Title = "Internal server error",
                Detail = _environment.IsDevelopment() 
                    ? exception.ToString() 
                    : "An error occurred while processing your request"
            }
        };
        
        problemDetails.Instance = context.Request.Path;
        problemDetails.Extensions["traceId"] = Activity.Current?.Id ?? context.TraceIdentifier;
        
        context.Response.StatusCode = problemDetails.Status ?? StatusCodes.Status500InternalServerError;
        
        await context.Response.WriteAsJsonAsync(problemDetails);
    }
}
```

## 🔒 Security Best Practices

### Authentication & Authorization
```csharp
// Program.cs configuration
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("RequireAdminRole", policy => 
        policy.RequireRole("Admin"));
        
    options.AddPolicy("RequirePremiumTier", policy =>
        policy.RequireClaim("CustomerTier", "Premium", "VIP"));
        
    options.AddPolicy("ResourceOwner", policy =>
        policy.Requirements.Add(new ResourceOwnerRequirement()));
});

// Custom authorization handler
public class ResourceOwnerRequirement : IAuthorizationRequirement { }

public class ResourceOwnerAuthorizationHandler : AuthorizationHandler<ResourceOwnerRequirement, Order>
{
    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        ResourceOwnerRequirement requirement,
        Order resource)
    {
        var userId = context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        
        if (userId != null && resource.CustomerId.ToString() == userId)
        {
            context.Succeed(requirement);
        }
        
        return Task.CompletedTask;
    }
}

// Usage in controller
[HttpPut("{id:guid}")]
[Authorize]
public async Task<IActionResult> UpdateOrder(Guid id, UpdateOrderRequest request)
{
    var order = await _orderService.GetByIdAsync(id);
    if (order == null) return NotFound();
    
    var authResult = await _authorizationService.AuthorizeAsync(
        User, order, "ResourceOwner");
        
    if (!authResult.Succeeded)
        return Forbid();
        
    // Update order...
}
```

### Input Validation & Sanitization
```csharp
public class CreateProductCommandValidator : AbstractValidator<CreateProductCommand>
{
    public CreateProductCommandValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Product name is required")
            .Length(3, 100).WithMessage("Product name must be between 3 and 100 characters")
            .Matches(@"^[a-zA-Z0-9\s\-_]+$").WithMessage("Product name contains invalid characters");
            
        RuleFor(x => x.Description)
            .MaximumLength(1000).WithMessage("Description cannot exceed 1000 characters")
            .Must(BeValidHtml).WithMessage("Description contains invalid HTML");
            
        RuleFor(x => x.Price)
            .GreaterThan(0).WithMessage("Price must be greater than 0")
            .LessThanOrEqualTo(999999.99m).WithMessage("Price cannot exceed 999,999.99");
            
        RuleFor(x => x.CategoryId)
            .NotEmpty().WithMessage("Category is required")
            .MustAsync(CategoryExists).WithMessage("Category does not exist");
    }
    
    private bool BeValidHtml(string html)
    {
        if (string.IsNullOrEmpty(html)) return true;
        
        // Use AntiXss or similar library
        var sanitized = HtmlSanitizer.Sanitize(html);
        return sanitized == html;
    }
    
    private async Task<bool> CategoryExists(Guid categoryId, CancellationToken cancellationToken)
    {
        // Check if category exists in database
        return await _categoryRepository.ExistsAsync(categoryId, cancellationToken);
    }
}
```

### Secure Configuration
```csharp
// Use User Secrets in development
builder.Configuration.AddUserSecrets<Program>();

// Use Azure Key Vault in production
if (builder.Environment.IsProduction())
{
    var keyVaultEndpoint = new Uri($"https://{builder.Configuration["KeyVaultName"]}.vault.azure.net/");
    builder.Configuration.AddAzureKeyVault(keyVaultEndpoint, new DefaultAzureCredential());
}

// Secure configuration model
public class SecurityOptions
{
    public const string Section = "Security";
    
    [Required]
    public string JwtKey { get; set; } = null!;
    
    [Required, Range(1, 24)]
    public int TokenExpirationHours { get; set; } = 8;
    
    [Required]
    public string[] AllowedOrigins { get; set; } = Array.Empty<string>();
    
    public bool RequireHttps { get; set; } = true;
    
    public RateLimitOptions RateLimit { get; set; } = new();
}

// Configure with validation
builder.Services
    .AddOptions<SecurityOptions>()
    .Bind(builder.Configuration.GetSection(SecurityOptions.Section))
    .ValidateDataAnnotations()
    .ValidateOnStart();
```

## ⚡ Performance Optimization

### Async/Await Best Practices
```csharp
// ✅ DO: Use async all the way
public async Task<IActionResult> GetProducts([FromQuery] int pageSize = 20)
{
    // Good: Async database call
    var products = await _context.Products
        .AsNoTracking()
        .OrderBy(p => p.Name)
        .Take(pageSize)
        .Select(p => new ProductDto
        {
            Id = p.Id,
            Name = p.Name,
            Price = p.Price
        })
        .ToListAsync();
        
    return Ok(products);
}

// ❌ DON'T: Block async code
public IActionResult GetProductsBad([FromQuery] int pageSize = 20)
{
    // Bad: Blocking async call
    var products = _context.Products
        .AsNoTracking()
        .OrderBy(p => p.Name)
        .Take(pageSize)
        .ToListAsync()
        .Result; // Never do this!
        
    return Ok(products);
}

// ✅ DO: Configure await properly
public async Task<List<Product>> GetActiveProductsAsync()
{
    // ConfigureAwait(false) in library code
    var products = await _repository
        .GetAllAsync()
        .ConfigureAwait(false);
        
    return products.Where(p => p.IsActive).ToList();
}
```

### Caching Strategies
```csharp
// Memory cache with proper patterns
public class CachedProductService : IProductService
{
    private readonly IProductRepository _repository;
    private readonly IMemoryCache _cache;
    private readonly ILogger<CachedProductService> _logger;
    
    public async Task<Product?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var cacheKey = $"product_{id}";
        
        // Try to get from cache
        if (_cache.TryGetValue<Product>(cacheKey, out var cached))
        {
            _logger.LogDebug("Cache hit for product {ProductId}", id);
            return cached;
        }
        
        // Get from database
        var product = await _repository.GetByIdAsync(id, cancellationToken);
        
        if (product != null)
        {
            // Cache with sliding expiration
            var cacheOptions = new MemoryCacheEntryOptions()
                .SetSlidingExpiration(TimeSpan.FromMinutes(5))
                .SetAbsoluteExpiration(TimeSpan.FromHours(1))
                .SetPriority(CacheItemPriority.Normal)
                .RegisterPostEvictionCallback(OnCacheEviction);
                
            _cache.Set(cacheKey, product, cacheOptions);
        }
        
        return product;
    }
    
    private void OnCacheEviction(object key, object value, EvictionReason reason, object state)
    {
        _logger.LogDebug("Cache item {Key} evicted. Reason: {Reason}", key, reason);
    }
}

// Distributed cache with Redis
public class DistributedProductCache : IProductCache
{
    private readonly IDistributedCache _cache;
    private readonly ILogger<DistributedProductCache> _logger;
    
    public async Task<T?> GetAsync<T>(string key, CancellationToken cancellationToken = default)
    {
        try
        {
            var data = await _cache.GetAsync(key, cancellationToken);
            if (data == null) return default;
            
            return JsonSerializer.Deserialize<T>(data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving from cache: {Key}", key);
            return default;
        }
    }
    
    public async Task SetAsync<T>(
        string key, 
        T value, 
        TimeSpan? expiration = null,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var options = new DistributedCacheEntryOptions();
            
            if (expiration.HasValue)
                options.SetAbsoluteExpiration(expiration.Value);
            else
                options.SetSlidingExpiration(TimeSpan.FromMinutes(5));
                
            var data = JsonSerializer.SerializeToUtf8Bytes(value);
            await _cache.SetAsync(key, data, options, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error setting cache: {Key}", key);
            // Don't throw - caching should not break the application
        }
    }
}
```

### Database Performance
```csharp
// Efficient queries with projection
public async Task<PagedResult<OrderSummaryDto>> GetOrdersAsync(
    int pageNumber, 
    int pageSize,
    OrderStatus? status = null)
{
    var query = _context.Orders
        .AsNoTracking()
        .Include(o => o.Customer)
        .Where(o => status == null || o.Status == status);
        
    var totalCount = await query.CountAsync();
    
    var items = await query
        .OrderByDescending(o => o.CreatedAt)
        .Skip((pageNumber - 1) * pageSize)
        .Take(pageSize)
        .Select(o => new OrderSummaryDto
        {
            Id = o.Id,
            OrderNumber = o.OrderNumber,
            CustomerName = o.Customer.Name,
            TotalAmount = o.TotalAmount,
            Status = o.Status,
            CreatedAt = o.CreatedAt
        })
        .ToListAsync();
        
    return new PagedResult<OrderSummaryDto>(items, totalCount, pageNumber, pageSize);
}

// Bulk operations
public async Task UpdateProductPricesAsync(Dictionary<Guid, decimal> priceUpdates)
{
    // Use ExecuteUpdate for bulk updates (EF Core 7+)
    await _context.Products
        .Where(p => priceUpdates.Keys.Contains(p.Id))
        .ExecuteUpdateAsync(setters => setters
            .SetProperty(p => p.Price, p => priceUpdates[p.Id])
            .SetProperty(p => p.UpdatedAt, DateTime.UtcNow));
}

// Connection resiliency
services.AddDbContext<ApplicationDbContext>(options =>
{
    options.UseSqlServer(connectionString, sqlOptions =>
    {
        sqlOptions.EnableRetryOnFailure(
            maxRetryCount: 5,
            maxRetryDelay: TimeSpan.FromSeconds(30),
            errorNumbersToAdd: null);
            
        sqlOptions.CommandTimeout(30);
        
        // Enable query splitting for better performance with includes
        sqlOptions.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery);
    });
    
    // Enable sensitive data logging only in development
    if (environment.IsDevelopment())
    {
        options.EnableSensitiveDataLogging();
        options.EnableDetailedErrors();
    }
});
```

## 🤖 AI Integration Patterns

### Semantic Kernel Integration
```csharp
public interface IAIService
{
    Task<string> GenerateTextAsync(string prompt, CancellationToken cancellationToken = default);
    Task<ProductDescription> GenerateProductDescriptionAsync(Product product, CancellationToken cancellationToken = default);
    Task<CustomerSentiment> AnalyzeSentimentAsync(string text, CancellationToken cancellationToken = default);
}

public class SemanticKernelAIService : IAIService
{
    private readonly IKernel _kernel;
    private readonly ILogger<SemanticKernelAIService> _logger;
    
    public SemanticKernelAIService(IKernel kernel, ILogger<SemanticKernelAIService> logger)
    {
        _kernel = kernel;
        _logger = logger;
    }
    
    public async Task<ProductDescription> GenerateProductDescriptionAsync(
        Product product, 
        CancellationToken cancellationToken = default)
    {
        var function = _kernel.Functions.GetFunction("ProductPlugin", "GenerateDescription");
        
        var variables = new KernelArguments
        {
            ["productName"] = product.Name,
            ["category"] = product.Category.Name,
            ["features"] = string.Join(", ", product.Features),
            ["targetAudience"] = product.TargetAudience
        };
        
        try
        {
            var result = await _kernel.InvokeAsync(function, variables, cancellationToken);
            
            return new ProductDescription
            {
                ShortDescription = result.GetValue<string>("shortDescription"),
                LongDescription = result.GetValue<string>("longDescription"),
                SEOKeywords = result.GetValue<List<string>>("keywords"),
                GeneratedAt = DateTime.UtcNow
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to generate product description for {ProductId}", product.Id);
            throw;
        }
    }
}

// Semantic Kernel configuration
public static class SemanticKernelConfiguration
{
    public static IServiceCollection AddSemanticKernel(
        this IServiceCollection services, 
        IConfiguration configuration)
    {
        services.AddSingleton<IKernel>(sp =>
        {
            var builder = new KernelBuilder();
            
            // Add Azure OpenAI
            builder.WithAzureOpenAIChatCompletionService(
                deploymentName: configuration["AzureOpenAI:DeploymentName"],
                endpoint: configuration["AzureOpenAI:Endpoint"],
                apiKey: configuration["AzureOpenAI:ApiKey"]);
            
            // Add plugins
            builder.Plugins.AddFromType<ProductPlugin>();
            builder.Plugins.AddFromType<CustomerPlugin>();
            builder.Plugins.AddFromPromptDirectory("Prompts");
            
            // Add memory
            builder.WithMemoryStorage(new VolatileMemoryStore());
            
            return builder.Build();
        });
        
        services.AddScoped<IAIService, SemanticKernelAIService>();
        
        return services;
    }
}
```

### RAG Pattern Implementation
```csharp
public class RAGService : IRAGService
{
    private readonly IVectorStore _vectorStore;
    private readonly IEmbeddingService _embeddingService;
    private readonly IKernel _kernel;
    
    public async Task<string> QueryWithContextAsync(
        string query, 
        string collection,
        CancellationToken cancellationToken = default)
    {
        // Generate embedding for query
        var queryEmbedding = await _embeddingService.GenerateEmbeddingAsync(query, cancellationToken);
        
        // Search vector store
        var relevantDocuments = await _vectorStore.SearchAsync(
            collection,
            queryEmbedding,
            topK: 5,
            cancellationToken: cancellationToken);
            
        // Build context
        var context = string.Join("\n\n", relevantDocuments.Select(d => d.Content));
        
        // Generate response with context
        var prompt = $"""
        Answer the following question based on the provided context.
        If the answer cannot be found in the context, say "I don't have enough information to answer that."
        
        Context:
        {context}
        
        Question: {query}
        
        Answer:
        """;
        
        var response = await _kernel.InvokePromptAsync(prompt, cancellationToken: cancellationToken);
        
        return response.GetValue<string>();
    }
}
```

## 🧪 Testing Strategies

### Unit Testing
```csharp
public class OrderServiceTests
{
    private readonly Mock<IOrderRepository> _orderRepositoryMock;
    private readonly Mock<IUnitOfWork> _unitOfWorkMock;
    private readonly Mock<ILogger<OrderService>> _loggerMock;
    private readonly OrderService _sut; // System Under Test
    
    public OrderServiceTests()
    {
        _orderRepositoryMock = new Mock<IOrderRepository>();
        _unitOfWorkMock = new Mock<IUnitOfWork>();
        _loggerMock = new Mock<ILogger<OrderService>>();
        
        _sut = new OrderService(
            _orderRepositoryMock.Object,
            _unitOfWorkMock.Object,
            _loggerMock.Object);
    }
    
    [Fact]
    public async Task CreateOrder_WithValidData_ShouldCreateSuccessfully()
    {
        // Arrange
        var customerId = Guid.NewGuid();
        var items = new List<CreateOrderItemDto>
        {
            new(Guid.NewGuid(), 2),
            new(Guid.NewGuid(), 1)
        };
        
        _orderRepositoryMock
            .Setup(x => x.AddAsync(It.IsAny<Order>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);
            
        _unitOfWorkMock
            .Setup(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(1);
        
        // Act
        var result = await _sut.CreateOrderAsync(customerId, items);
        
        // Assert
        result.Should().NotBeNull();
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().NotBeNull();
        result.Value.CustomerId.Should().Be(customerId);
        result.Value.Items.Should().HaveCount(2);
        
        _orderRepositoryMock.Verify(
            x => x.AddAsync(It.IsAny<Order>(), It.IsAny<CancellationToken>()), 
            Times.Once);
            
        _unitOfWorkMock.Verify(
            x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), 
            Times.Once);
    }
    
    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    [InlineData(1001)]
    public async Task CreateOrder_WithInvalidQuantity_ShouldFail(int quantity)
    {
        // Arrange
        var customerId = Guid.NewGuid();
        var items = new List<CreateOrderItemDto>
        {
            new(Guid.NewGuid(), quantity)
        };
        
        // Act
        var result = await _sut.CreateOrderAsync(customerId, items);
        
        // Assert
        result.IsSuccess.Should().BeFalse();
        result.Error.Should().Contain("quantity");
        
        _orderRepositoryMock.Verify(
            x => x.AddAsync(It.IsAny<Order>(), It.IsAny<CancellationToken>()), 
            Times.Never);
    }
}
```

### Integration Testing
```csharp
public class OrderApiIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly HttpClient _client;
    
    public OrderApiIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                // Remove real database
                var descriptor = services.SingleOrDefault(
                    d => d.ServiceType == typeof(DbContextOptions<ApplicationDbContext>));
                    
                if (descriptor != null)
                    services.Remove(descriptor);
                
                // Add in-memory database
                services.AddDbContext<ApplicationDbContext>(options =>
                {
                    options.UseInMemoryDatabase("TestDb");
                });
                
                // Seed test data
                var sp = services.BuildServiceProvider();
                using var scope = sp.CreateScope();
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                
                db.Database.EnsureCreated();
                SeedTestData(db);
            });
        });
        
        _client = _factory.CreateClient();
    }
    
    [Fact]
    public async Task GetOrders_ShouldReturnPaginatedResults()
    {
        // Act
        var response = await _client.GetAsync("/api/v1/orders?pageSize=10");
        
        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        
        var content = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<PagedResult<OrderDto>>(content);
        
        result.Should().NotBeNull();
        result.Items.Should().HaveCount(10);
        result.TotalCount.Should().BeGreaterThan(10);
        
        // Check pagination headers
        response.Headers.Should().ContainKey("X-Total-Count");
        response.Headers.Should().ContainKey("X-Page-Number");
    }
}
```

### Architecture Testing
```csharp
public class ArchitectureTests
{
    private const string DomainNamespace = "Enterprise.Domain";
    private const string ApplicationNamespace = "Enterprise.Application";
    private const string InfrastructureNamespace = "Enterprise.Infrastructure";
    private const string ApiNamespace = "Enterprise.API";
    
    [Fact]
    public void Domain_Should_Not_HaveDependencyOnOtherProjects()
    {
        // Arrange
        var assembly = typeof(Order).Assembly;
        
        // Act
        var result = Types
            .InAssembly(assembly)
            .Should()
            .NotHaveDependencyOnAll(ApplicationNamespace, InfrastructureNamespace, ApiNamespace)
            .GetResult();
            
        // Assert
        result.IsSuccessful.Should().BeTrue();
    }
    
    [Fact]
    public void Application_Should_Not_HaveDependencyOnInfrastructure()
    {
        // Arrange
        var assembly = typeof(CreateOrderCommand).Assembly;
        
        // Act
        var result = Types
            .InAssembly(assembly)
            .Should()
            .NotHaveDependencyOn(InfrastructureNamespace)
            .GetResult();
            
        // Assert
        result.IsSuccessful.Should().BeTrue();
    }
    
    [Fact]
    public void Handlers_Should_BeSealed()
    {
        // Arrange
        var assembly = typeof(CreateOrderCommandHandler).Assembly;
        
        // Act
        var result = Types
            .InAssembly(assembly)
            .That()
            .ImplementInterface(typeof(IRequestHandler<,>))
            .Should()
            .BeSealed()
            .GetResult();
            
        // Assert
        result.IsSuccessful.Should().BeTrue();
    }
}
```

## 📊 Observability & Monitoring

### Structured Logging
```csharp
// Program.cs
builder.Host.UseSerilog((context, services, configuration) => configuration
    .ReadFrom.Configuration(context.Configuration)
    .ReadFrom.Services(services)
    .Enrich.FromLogContext()
    .Enrich.WithMachineName()
    .Enrich.WithEnvironmentName()
    .Enrich.WithProperty("ApplicationName", "Enterprise.API")
    .WriteTo.Console(new RenderedCompactJsonFormatter())
    .WriteTo.Seq(context.Configuration["Seq:ServerUrl"]));

// Usage in code
public class OrderService
{
    private readonly ILogger<OrderService> _logger;
    
    public async Task<Order> CreateOrderAsync(CreateOrderDto dto)
    {
        using var activity = Activity.StartActivity("CreateOrder");
        
        _logger.LogInformation(
            "Creating order for customer {CustomerId} with {ItemCount} items",
            dto.CustomerId,
            dto.Items.Count);
            
        try
        {
            var order = await CreateOrderInternalAsync(dto);
            
            _logger.LogInformation(
                "Order {OrderId} created successfully for customer {CustomerId}. Total: {TotalAmount:C}",
                order.Id,
                order.CustomerId,
                order.TotalAmount);
                
            return order;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Failed to create order for customer {CustomerId}",
                dto.CustomerId);
            throw;
        }
    }
}
```

### Health Checks
```csharp
// Configure health checks
builder.Services
    .AddHealthChecks()
    .AddSqlServer(
        connectionString,
        name: "database",
        tags: new[] { "db", "sql", "critical" })
    .AddRedis(
        redisConnectionString,
        name: "cache",
        tags: new[] { "cache", "redis" })
    .AddUrlGroup(
        new Uri("https://api.example.com/health"),
        name: "external-api",
        tags: new[] { "external" })
    .AddCheck<CustomHealthCheck>("custom", tags: new[] { "custom" });

// Custom health check
public class CustomHealthCheck : IHealthCheck
{
    private readonly IServiceProvider _serviceProvider;
    
    public CustomHealthCheck(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }
    
    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            // Check critical services
            using var scope = _serviceProvider.CreateScope();
            var criticalService = scope.ServiceProvider.GetRequiredService<ICriticalService>();
            
            var isHealthy = await criticalService.CheckHealthAsync(cancellationToken);
            
            if (isHealthy)
            {
                return HealthCheckResult.Healthy("Critical service is running");
            }
            
            return HealthCheckResult.Unhealthy("Critical service is not responding");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("Critical service check failed", ex);
        }
    }
}

// Map health check endpoints
app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("critical"),
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
});

app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = _ => false // Liveness probe - just return 200 OK
});
```

### Distributed Tracing
```csharp
// Configure OpenTelemetry
builder.Services.AddOpenTelemetry()
    .ConfigureResource(resource => resource
        .AddService(serviceName: "Enterprise.API")
        .AddAttributes(new Dictionary<string, object>
        {
            ["environment"] = builder.Environment.EnvironmentName,
            ["version"] = Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "unknown"
        }))
    .WithTracing(tracing => tracing
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddSqlClientInstrumentation()
        .AddSource("Enterprise.API")
        .AddOtlpExporter(options =>
        {
            options.Endpoint = new Uri(builder.Configuration["OpenTelemetry:Endpoint"]);
        }))
    .WithMetrics(metrics => metrics
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddRuntimeInstrumentation()
        .AddPrometheusExporter());

// Custom activity source
public static class Telemetry
{
    public static readonly ActivitySource ActivitySource = new("Enterprise.API");
    
    public static Activity? StartActivity(string name, ActivityKind kind = ActivityKind.Internal)
    {
        return ActivitySource.StartActivity(name, kind);
    }
}

// Usage
public async Task<Order> ProcessOrderAsync(Guid orderId)
{
    using var activity = Telemetry.StartActivity("ProcessOrder");
    activity?.SetTag("order.id", orderId);
    
    try
    {
        var order = await GetOrderAsync(orderId);
        activity?.SetTag("order.status", order.Status);
        
        // Process order...
        
        activity?.SetStatus(ActivityStatusCode.Ok);
        return order;
    }
    catch (Exception ex)
    {
        activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
        throw;
    }
}
```

## 🚀 Deployment & DevOps

### Docker Configuration
```dockerfile
# Use multi-stage build for smaller images
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY ["src/Enterprise.API/Enterprise.API.csproj", "Enterprise.API/"]
COPY ["src/Enterprise.Application/Enterprise.Application.csproj", "Enterprise.Application/"]
COPY ["src/Enterprise.Domain/Enterprise.Domain.csproj", "Enterprise.Domain/"]
COPY ["src/Enterprise.Infrastructure/Enterprise.Infrastructure.csproj", "Enterprise.Infrastructure/"]
RUN dotnet restore "Enterprise.API/Enterprise.API.csproj"

# Copy everything else and build
COPY src/ .
WORKDIR "/src/Enterprise.API"
RUN dotnet build "Enterprise.API.csproj" -c Release -o /app/build

# Publish
FROM build AS publish
RUN dotnet publish "Enterprise.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Final stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

# Create non-root user
RUN groupadd -g 1000 dotnet && \
    useradd -u 1000 -g dotnet -m -s /bin/bash dotnet

# Install health check dependencies
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

COPY --from=publish /app/publish .

# Change ownership
RUN chown -R dotnet:dotnet /app

USER dotnet

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health/live || exit 1

ENTRYPOINT ["dotnet", "Enterprise.API.dll"]
```

### GitHub Actions CI/CD
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  DOTNET_VERSION: '8.0.x'
  AZURE_WEBAPP_NAME: 'enterprise-api'
  AZURE_WEBAPP_PACKAGE_PATH: './publish'

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup .NET
      uses: actions/setup-dotnet@v4
      with:
        dotnet-version: ${{ env.DOTNET_VERSION }}
    
    - name: Restore dependencies
      run: dotnet restore
    
    - name: Build
      run: dotnet build --no-restore --configuration Release
    
    - name: Test
      run: dotnet test --no-build --configuration Release --verbosity normal --collect:"XPlat Code Coverage" --results-directory ./coverage
    
    - name: Code Coverage Report
      uses: irongut/CodeCoverageSummary@v1.3.0
      with:
        filename: coverage/**/coverage.cobertura.xml
        badge: true
        fail_below_min: true
        format: markdown
        hide_branch_rate: false
        hide_complexity: true
        indicators: true
        output: both
        thresholds: '60 80'
    
    - name: Run Architecture Tests
      run: dotnet test tests/Enterprise.ArchitectureTests --configuration Release
    
    - name: SonarCloud Scan
      uses: SonarSource/sonarcloud-github-action@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
    
    - name: Publish
      if: github.ref == 'refs/heads/main'
      run: dotnet publish ./src/Enterprise.API/Enterprise.API.csproj --configuration Release --output ${{ env.AZURE_WEBAPP_PACKAGE_PATH }}
    
    - name: Upload artifact
      if: github.ref == 'refs/heads/main'
      uses: actions/upload-artifact@v3
      with:
        name: webapp
        path: ${{ env.AZURE_WEBAPP_PACKAGE_PATH }}

  deploy:
    runs-on: ubuntu-latest
    needs: build-and-test
    if: github.ref == 'refs/heads/main'
    
    steps:
    - name: Download artifact
      uses: actions/download-artifact@v3
      with:
        name: webapp
        path: ${{ env.AZURE_WEBAPP_PACKAGE_PATH }}
    
    - name: Deploy to Azure Web App
      uses: azure/webapps-deploy@v2
      with:
        app-name: ${{ env.AZURE_WEBAPP_NAME }}
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
        package: ${{ env.AZURE_WEBAPP_PACKAGE_PATH }}
```

## ✅ Implementation Checklist

When implementing enterprise .NET applications:

- [ ] Follow Clean Architecture principles
- [ ] Implement proper separation of concerns
- [ ] Use dependency injection throughout
- [ ] Apply Domain-Driven Design where appropriate
- [ ] Implement comprehensive error handling
- [ ] Add proper logging and monitoring
- [ ] Include health checks
- [ ] Implement security best practices
- [ ] Add comprehensive testing
- [ ] Use async/await properly
- [ ] Implement caching strategies
- [ ] Configure CI/CD pipelines
- [ ] Document APIs with OpenAPI
- [ ] Use proper configuration management
- [ ] Implement proper validation

## 📚 Additional Resources

### Official Documentation
- [.NET Documentation](https://docs.microsoft.com/en-us/dotnet/)
- [ASP.NET Core Documentation](https://docs.microsoft.com/en-us/aspnet/core/)
- [Entity Framework Core](https://docs.microsoft.com/en-us/ef/core/)
- [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)

### Architecture & Patterns
- [Clean Architecture Template](https://github.com/jasontaylordev/CleanArchitecture)
- [eShopOnContainers](https://github.com/dotnet-architecture/eShopOnContainers)
- [DDD Sample](https://github.com/ddd-by-examples/library)

### Tools & Libraries
- [MediatR](https://github.com/jbogard/MediatR)
- [FluentValidation](https://fluentvalidation.net/)
- [Polly](https://github.com/App-vNext/Polly)
- [Serilog](https://serilog.net/)

---

**Remember**: These best practices are guidelines, not rigid rules. Always consider your specific context, team capabilities, and business requirements when making architectural decisions.