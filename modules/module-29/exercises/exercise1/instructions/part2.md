# Exercise 1: Enterprise API Platform - Part 2: Core Implementation

## 🎯 Overview

In this part, you'll implement the core functionality of the enterprise API platform, including business logic, API controllers, AI integration with Semantic Kernel, and security features.

## 📋 Part 2 Objectives

- Implement CQRS pattern with MediatR
- Create RESTful API controllers
- Integrate Semantic Kernel for AI features
- Add authentication and authorization
- Implement caching strategies
- Configure middleware pipeline

## 🔧 Step 1: Configure Application Layer

### 1.1 Install Application Layer Packages

```bash
cd src/Core/Application

# CQRS and Validation
dotnet add package MediatR
dotnet add package FluentValidation
dotnet add package FluentValidation.DependencyInjectionExtensions
dotnet add package AutoMapper
dotnet add package AutoMapper.Extensions.Microsoft.DependencyInjection

# Cross-cutting concerns
dotnet add package Microsoft.Extensions.Logging.Abstractions
dotnet add package Polly

cd ../../..
```

### 1.2 Create Application Service Configuration

Create `src/Core/Application/DependencyInjection.cs`:

```csharp
namespace EnterpriseAPI.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddMediatR(cfg =>
        {
            cfg.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly());
            cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(LoggingBehavior<,>));
            cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));
            cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(PerformanceBehavior<,>));
            cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(TenantValidationBehavior<,>));
        });

        services.AddValidatorsFromAssembly(Assembly.GetExecutingAssembly());
        services.AddAutoMapper(Assembly.GetExecutingAssembly());

        return services;
    }
}
```

### 1.3 Create Pipeline Behaviors

Create `src/Core/Application/Common/Behaviors/LoggingBehavior.cs`:

```csharp
namespace EnterpriseAPI.Application.Common.Behaviors;

public class LoggingBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly ILogger<LoggingBehavior<TRequest, TResponse>> _logger;
    private readonly ICurrentUserService _currentUserService;
    private readonly ITenantContext _tenantContext;

    public LoggingBehavior(
        ILogger<LoggingBehavior<TRequest, TResponse>> logger,
        ICurrentUserService currentUserService,
        ITenantContext tenantContext)
    {
        _logger = logger;
        _currentUserService = currentUserService;
        _tenantContext = tenantContext;
    }

    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken cancellationToken)
    {
        var requestName = typeof(TRequest).Name;
        var userId = _currentUserService.UserId ?? "Anonymous";
        var tenantId = _tenantContext.TenantId?.ToString() ?? "No Tenant";

        _logger.LogInformation(
            "Handling {RequestName} for User: {UserId}, Tenant: {TenantId}",
            requestName, userId, tenantId);

        try
        {
            return await next();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Error handling {RequestName} for User: {UserId}, Tenant: {TenantId}",
                requestName, userId, tenantId);
            throw;
        }
    }
}
```

Create `src/Core/Application/Common/Behaviors/ValidationBehavior.cs`:

```csharp
namespace EnterpriseAPI.Application.Common.Behaviors;

public class ValidationBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly IEnumerable<IValidator<TRequest>> _validators;

    public ValidationBehavior(IEnumerable<IValidator<TRequest>> validators)
    {
        _validators = validators;
    }

    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken cancellationToken)
    {
        if (!_validators.Any())
            return await next();

        var context = new ValidationContext<TRequest>(request);

        var validationResults = await Task.WhenAll(
            _validators.Select(v => v.ValidateAsync(context, cancellationToken)));

        var failures = validationResults
            .SelectMany(r => r.Errors)
            .Where(f => f != null)
            .ToList();

        if (failures.Count != 0)
            throw new ValidationException(failures);

        return await next();
    }
}
```

## 🏛️ Step 2: Implement Business Logic

### 2.1 Create Product Commands

Create `src/Core/Application/Products/Commands/CreateProduct/CreateProductCommand.cs`:

```csharp
namespace EnterpriseAPI.Application.Products.Commands.CreateProduct;

public record CreateProductCommand : IRequest<Result<ProductDto>>
{
    public string Name { get; init; } = null!;
    public string? Description { get; init; }
    public string SKU { get; init; } = null!;
    public decimal Price { get; init; }
    public Guid CategoryId { get; init; }
    public bool GenerateAIDescription { get; init; }
}

public class CreateProductCommandValidator : AbstractValidator<CreateProductCommand>
{
    public CreateProductCommandValidator()
    {
        RuleFor(v => v.Name)
            .NotEmpty().WithMessage("Product name is required")
            .MaximumLength(200).WithMessage("Product name must not exceed 200 characters");

        RuleFor(v => v.SKU)
            .NotEmpty().WithMessage("SKU is required")
            .MaximumLength(50).WithMessage("SKU must not exceed 50 characters")
            .Matches(@"^[A-Z0-9\-]+$").WithMessage("SKU must contain only uppercase letters, numbers, and hyphens");

        RuleFor(v => v.Price)
            .GreaterThanOrEqualTo(0).WithMessage("Price must be greater than or equal to 0")
            .LessThanOrEqualTo(999999.99m).WithMessage("Price must not exceed 999,999.99");

        RuleFor(v => v.CategoryId)
            .NotEmpty().WithMessage("Category is required");
    }
}

public class CreateProductCommandHandler : IRequestHandler<CreateProductCommand, Result<ProductDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly ITenantContext _tenantContext;
    private readonly IMapper _mapper;
    private readonly IAIService _aiService;
    private readonly ILogger<CreateProductCommandHandler> _logger;

    public CreateProductCommandHandler(
        IApplicationDbContext context,
        ITenantContext tenantContext,
        IMapper mapper,
        IAIService aiService,
        ILogger<CreateProductCommandHandler> logger)
    {
        _context = context;
        _tenantContext = tenantContext;
        _mapper = mapper;
        _aiService = aiService;
        _logger = logger;
    }

    public async Task<Result<ProductDto>> Handle(
        CreateProductCommand request,
        CancellationToken cancellationToken)
    {
        if (!_tenantContext.TenantId.HasValue)
            return Result<ProductDto>.Failure("Tenant context is required");

        // Validate category exists
        var categoryExists = await _context.Categories
            .AnyAsync(c => c.Id == request.CategoryId, cancellationToken);

        if (!categoryExists)
            return Result<ProductDto>.Failure("Category not found");

        // Check for duplicate SKU
        var skuExists = await _context.Products
            .AnyAsync(p => p.SKU == request.SKU.ToUpperInvariant(), cancellationToken);

        if (skuExists)
            return Result<ProductDto>.Failure($"Product with SKU '{request.SKU}' already exists");

        // Create product
        var product = Product.Create(
            _tenantContext.TenantId.Value,
            request.Name,
            request.SKU,
            request.Price,
            request.CategoryId);

        // Generate AI description if requested
        if (request.GenerateAIDescription)
        {
            try
            {
                var description = await _aiService.GenerateProductDescriptionAsync(
                    request.Name,
                    request.CategoryId,
                    cancellationToken);

                product.Description = description;
                _logger.LogInformation("AI description generated for product {ProductName}", request.Name);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to generate AI description for product {ProductName}", request.Name);
                // Continue without AI description
            }
        }
        else if (!string.IsNullOrWhiteSpace(request.Description))
        {
            product.Description = request.Description;
        }

        _context.Products.Add(product);
        await _context.SaveChangesAsync(cancellationToken);

        var dto = _mapper.Map<ProductDto>(product);
        return Result<ProductDto>.Success(dto);
    }
}
```

### 2.2 Create Product Queries

Create `src/Core/Application/Products/Queries/GetProducts/GetProductsQuery.cs`:

```csharp
namespace EnterpriseAPI.Application.Products.Queries.GetProducts;

public record GetProductsQuery : IRequest<PagedResult<ProductDto>>
{
    public int PageNumber { get; init; } = 1;
    public int PageSize { get; init; } = 20;
    public string? SearchTerm { get; init; }
    public Guid? CategoryId { get; init; }
    public decimal? MinPrice { get; init; }
    public decimal? MaxPrice { get; init; }
    public ProductStatus? Status { get; init; }
    public string SortBy { get; init; } = "Name";
    public bool SortDescending { get; init; }
}

public class GetProductsQueryHandler : IRequestHandler<GetProductsQuery, PagedResult<ProductDto>>
{
    private readonly IApplicationDbContext _context;
    private readonly IMapper _mapper;
    private readonly IMemoryCache _cache;
    private readonly ITenantContext _tenantContext;

    public GetProductsQueryHandler(
        IApplicationDbContext context,
        IMapper mapper,
        IMemoryCache cache,
        ITenantContext tenantContext)
    {
        _context = context;
        _mapper = mapper;
        _cache = cache;
        _tenantContext = tenantContext;
    }

    public async Task<PagedResult<ProductDto>> Handle(
        GetProductsQuery request,
        CancellationToken cancellationToken)
    {
        // Build cache key including tenant
        var cacheKey = $"products_{_tenantContext.TenantId}_{request.GetHashCode()}";

        // Try to get from cache
        if (_cache.TryGetValue<PagedResult<ProductDto>>(cacheKey, out var cachedResult))
        {
            return cachedResult!;
        }

        // Build query
        var query = _context.Products
            .Include(p => p.Category)
            .AsNoTracking();

        // Apply filters
        if (!string.IsNullOrWhiteSpace(request.SearchTerm))
        {
            query = query.Where(p =>
                p.Name.Contains(request.SearchTerm) ||
                p.Description!.Contains(request.SearchTerm) ||
                p.SKU.Contains(request.SearchTerm));
        }

        if (request.CategoryId.HasValue)
        {
            query = query.Where(p => p.CategoryId == request.CategoryId.Value);
        }

        if (request.MinPrice.HasValue)
        {
            query = query.Where(p => p.Price >= request.MinPrice.Value);
        }

        if (request.MaxPrice.HasValue)
        {
            query = query.Where(p => p.Price <= request.MaxPrice.Value);
        }

        if (request.Status.HasValue)
        {
            query = query.Where(p => p.Status == request.Status.Value);
        }

        // Apply sorting
        query = request.SortBy?.ToLower() switch
        {
            "price" => request.SortDescending
                ? query.OrderByDescending(p => p.Price)
                : query.OrderBy(p => p.Price),
            "created" => request.SortDescending
                ? query.OrderByDescending(p => p.CreatedAt)
                : query.OrderBy(p => p.CreatedAt),
            _ => request.SortDescending
                ? query.OrderByDescending(p => p.Name)
                : query.OrderBy(p => p.Name)
        };

        // Get total count
        var totalCount = await query.CountAsync(cancellationToken);

        // Apply pagination
        var items = await query
            .Skip((request.PageNumber - 1) * request.PageSize)
            .Take(request.PageSize)
            .Select(p => new ProductDto
            {
                Id = p.Id,
                Name = p.Name,
                Description = p.Description,
                SKU = p.SKU,
                Price = p.Price,
                Currency = p.Currency,
                Status = p.Status,
                CategoryId = p.CategoryId,
                CategoryName = p.Category.Name,
                CreatedAt = p.CreatedAt,
                UpdatedAt = p.UpdatedAt
            })
            .ToListAsync(cancellationToken);

        var result = new PagedResult<ProductDto>(
            items,
            totalCount,
            request.PageNumber,
            request.PageSize);

        // Cache the result
        _cache.Set(cacheKey, result, TimeSpan.FromMinutes(5));

        return result;
    }
}
```

### 2.3 Create DTOs and Mappings

Create `src/Core/Application/Products/ProductDto.cs`:

```csharp
namespace EnterpriseAPI.Application.Products;

public class ProductDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    public string SKU { get; set; } = null!;
    public decimal Price { get; set; }
    public string Currency { get; set; } = null!;
    public ProductStatus Status { get; set; }
    public Guid CategoryId { get; set; }
    public string? CategoryName { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

public class ProductMappingProfile : Profile
{
    public ProductMappingProfile()
    {
        CreateMap<Product, ProductDto>()
            .ForMember(d => d.CategoryName, opt => opt.MapFrom(s => s.Category.Name));
    }
}
```

## 🤖 Step 3: Integrate Semantic Kernel

### 3.1 Create AI Service Interface

Create `src/Core/Application/Common/Interfaces/IAIService.cs`:

```csharp
namespace EnterpriseAPI.Application.Common.Interfaces;

public interface IAIService
{
    Task<string> GenerateProductDescriptionAsync(
        string productName,
        Guid categoryId,
        CancellationToken cancellationToken = default);
        
    Task<ProductRecommendation[]> GetProductRecommendationsAsync(
        Guid customerId,
        int count = 5,
        CancellationToken cancellationToken = default);
        
    Task<SentimentAnalysis> AnalyzeSentimentAsync(
        string text,
        CancellationToken cancellationToken = default);
        
    Task<DemandForecast> ForecastDemandAsync(
        Guid productId,
        int daysAhead = 30,
        CancellationToken cancellationToken = default);
}

public record ProductRecommendation(Guid ProductId, string Reason, double Score);
public record SentimentAnalysis(double Score, string Sentiment, string[] Keywords);
public record DemandForecast(Dictionary<DateTime, int> Predictions, double Confidence);
```

### 3.2 Implement Semantic Kernel Service

Create `src/Infrastructure/AI/SemanticKernelService.cs`:

```csharp
namespace EnterpriseAPI.Infrastructure.AI;

public class SemanticKernelService : IAIService
{
    private readonly IKernel _kernel;
    private readonly ITenantContext _tenantContext;
    private readonly IApplicationDbContext _context;
    private readonly ILogger<SemanticKernelService> _logger;
    private readonly IMemoryCache _cache;

    public SemanticKernelService(
        IConfiguration configuration,
        ITenantContext tenantContext,
        IApplicationDbContext context,
        ILogger<SemanticKernelService> logger,
        IMemoryCache cache)
    {
        _tenantContext = tenantContext;
        _context = context;
        _logger = logger;
        _cache = cache;

        // Initialize Semantic Kernel
        var builder = Kernel.CreateBuilder();
        
        builder.AddAzureOpenAIChatCompletion(
            deploymentName: configuration["AzureOpenAI:DeploymentName"],
            endpoint: configuration["AzureOpenAI:Endpoint"],
            apiKey: configuration["AzureOpenAI:ApiKey"]);

        _kernel = builder.Build();
        
        // Load plugins
        LoadPlugins();
    }

    private void LoadPlugins()
    {
        // Create product description plugin
        var productPlugin = _kernel.CreateFunctionFromPrompt(
            @"Generate a compelling product description for an e-commerce platform.
            Product Name: {{$productName}}
            Category: {{$categoryName}}
            
            Requirements:
            - 2-3 sentences
            - Highlight key benefits
            - Use persuasive but honest language
            - SEO-friendly
            - Professional tone
            
            Description:",
            functionName: "GenerateProductDescription",
            description: "Generate product descriptions");

        _kernel.Plugins.Add("ProductPlugin", new[] { productPlugin });
    }

    public async Task<string> GenerateProductDescriptionAsync(
        string productName,
        Guid categoryId,
        CancellationToken cancellationToken = default)
    {
        try
        {
            // Get category name
            var category = await _context.Categories
                .Where(c => c.Id == categoryId)
                .Select(c => c.Name)
                .FirstOrDefaultAsync(cancellationToken);

            if (category == null)
                throw new InvalidOperationException($"Category {categoryId} not found");

            // Check tenant's AI feature access
            if (_tenantContext.Tenant?.Features.TryGetValue("ai_features", out var aiEnabled) == true && !aiEnabled)
            {
                throw new UnauthorizedAccessException("AI features are not enabled for this tenant");
            }

            // Create context variables
            var variables = new KernelArguments
            {
                ["productName"] = productName,
                ["categoryName"] = category
            };

            // Get the function
            var function = _kernel.Plugins.GetFunction("ProductPlugin", "GenerateProductDescription");

            // Invoke the function
            var result = await _kernel.InvokeAsync(function, variables, cancellationToken);

            var description = result.GetValue<string>() ?? string.Empty;
            
            _logger.LogInformation(
                "Generated AI description for product {ProductName} in tenant {TenantId}",
                productName,
                _tenantContext.TenantId);

            return description.Trim();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "Failed to generate AI description for product {ProductName}",
                productName);
            throw;
        }
    }

    public async Task<ProductRecommendation[]> GetProductRecommendationsAsync(
        Guid customerId,
        int count = 5,
        CancellationToken cancellationToken = default)
    {
        // Cache key with tenant context
        var cacheKey = $"recommendations_{_tenantContext.TenantId}_{customerId}";
        
        if (_cache.TryGetValue<ProductRecommendation[]>(cacheKey, out var cached))
        {
            return cached!;
        }

        // Get customer purchase history
        var purchaseHistory = await _context.Orders
            .Where(o => o.CustomerId == customerId)
            .SelectMany(o => o.Items)
            .Select(i => new { i.ProductId, i.Product.CategoryId, i.Product.Name })
            .Distinct()
            .ToListAsync(cancellationToken);

        if (!purchaseHistory.Any())
        {
            // Return popular products for new customers
            var popularProducts = await _context.Products
                .OrderByDescending(p => p.OrderItems.Count())
                .Take(count)
                .Select(p => new ProductRecommendation(p.Id, "Popular item", 0.8))
                .ToListAsync(cancellationToken);

            return popularProducts.ToArray();
        }

        // Use AI to generate recommendations based on history
        var prompt = $@"Based on the customer's purchase history, recommend {count} products.
        
        Purchase History:
        {string.Join("\n", purchaseHistory.Select(h => $"- {h.Name}"))}
        
        Available Products to Recommend:
        {{$availableProducts}}
        
        Return recommendations in JSON format:
        [
            {{""productId"": ""guid"", ""reason"": ""why recommended"", ""score"": 0.0-1.0}},
            ...
        ]";

        var availableProducts = await _context.Products
            .Where(p => !purchaseHistory.Select(h => h.ProductId).Contains(p.Id))
            .Select(p => new { p.Id, p.Name, p.CategoryId })
            .ToListAsync(cancellationToken);

        // Implementation would continue with AI call...
        // For now, return simple category-based recommendations
        var recommendations = availableProducts
            .Where(p => purchaseHistory.Any(h => h.CategoryId == p.CategoryId))
            .Take(count)
            .Select(p => new ProductRecommendation(
                p.Id,
                "Based on your previous purchases",
                0.75))
            .ToArray();

        _cache.Set(cacheKey, recommendations, TimeSpan.FromHours(1));
        
        return recommendations;
    }

    public async Task<SentimentAnalysis> AnalyzeSentimentAsync(
        string text,
        CancellationToken cancellationToken = default)
    {
        var function = _kernel.CreateFunctionFromPrompt(
            @"Analyze the sentiment of the following text and return a JSON response.
            
            Text: {{$text}}
            
            Return format:
            {
                ""score"": -1.0 to 1.0 (negative to positive),
                ""sentiment"": ""positive"" | ""negative"" | ""neutral"",
                ""keywords"": [""keyword1"", ""keyword2"", ...]
            }",
            functionName: "AnalyzeSentiment");

        var result = await _kernel.InvokeAsync(
            function,
            new() { ["text"] = text },
            cancellationToken);

        // Parse the JSON response
        // For simplicity, returning a basic analysis
        var score = text.Contains("good") || text.Contains("great") ? 0.8 : 
                   text.Contains("bad") || text.Contains("terrible") ? -0.8 : 0.0;
                   
        var sentiment = score > 0.3 ? "positive" : score < -0.3 ? "negative" : "neutral";
        var keywords = text.Split(' ').Where(w => w.Length > 4).Take(5).ToArray();

        return new SentimentAnalysis(score, sentiment, keywords);
    }

    public async Task<DemandForecast> ForecastDemandAsync(
        Guid productId,
        int daysAhead = 30,
        CancellationToken cancellationToken = default)
    {
        // Get historical sales data
        var historicalSales = await _context.OrderItems
            .Where(oi => oi.ProductId == productId)
            .GroupBy(oi => oi.Order.CreatedAt.Date)
            .Select(g => new { Date = g.Key, Quantity = g.Sum(oi => oi.Quantity) })
            .OrderBy(s => s.Date)
            .ToListAsync(cancellationToken);

        if (!historicalSales.Any())
        {
            // No historical data
            var emptyForecast = Enumerable.Range(1, daysAhead)
                .ToDictionary(
                    day => DateTime.UtcNow.Date.AddDays(day),
                    _ => 0);
                    
            return new DemandForecast(emptyForecast, 0.0);
        }

        // Simple moving average forecast (in production, use ML.NET or more sophisticated methods)
        var avgDailySales = historicalSales.Average(s => s.Quantity);
        var variance = historicalSales.Select(s => Math.Pow(s.Quantity - avgDailySales, 2)).Average();
        var stdDev = Math.Sqrt(variance);

        var predictions = new Dictionary<DateTime, int>();
        var random = new Random();

        for (int day = 1; day <= daysAhead; day++)
        {
            var date = DateTime.UtcNow.Date.AddDays(day);
            var dayOfWeek = date.DayOfWeek;
            
            // Adjust for day of week patterns
            var weekdayMultiplier = dayOfWeek switch
            {
                DayOfWeek.Saturday or DayOfWeek.Sunday => 1.2,
                DayOfWeek.Friday => 1.1,
                _ => 1.0
            };

            var predictedQuantity = (int)(avgDailySales * weekdayMultiplier + 
                                         random.NextDouble() * stdDev - stdDev / 2);
                                         
            predictions[date] = Math.Max(0, predictedQuantity);
        }

        var confidence = Math.Max(0.0, Math.Min(1.0, 1.0 - (stdDev / avgDailySales)));

        return new DemandForecast(predictions, confidence);
    }
}
```

## 🌐 Step 4: Create API Controllers

### 4.1 Create Base Controller

Create `src/API/Controllers/ApiControllerBase.cs`:

```csharp
namespace EnterpriseAPI.API.Controllers;

[ApiController]
[Route("api/v{version:apiVersion}/[controller]")]
[Produces("application/json")]
public abstract class ApiControllerBase : ControllerBase
{
    private ISender? _mediator;
    protected ISender Mediator => _mediator ??= HttpContext.RequestServices.GetRequiredService<ISender>();
}
```

### 4.2 Create Products Controller

Create `src/API/Controllers/ProductsController.cs`:

```csharp
namespace EnterpriseAPI.API.Controllers;

[ApiVersion("1.0")]
[Authorize]
public class ProductsController : ApiControllerBase
{
    /// <summary>
    /// Get products with pagination and filtering
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(PagedResult<ProductDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetProducts([FromQuery] GetProductsQuery query)
    {
        var result = await Mediator.Send(query);
        
        // Add pagination headers
        Response.Headers.Add("X-Page-Number", result.PageNumber.ToString());
        Response.Headers.Add("X-Page-Size", result.PageSize.ToString());
        Response.Headers.Add("X-Total-Count", result.TotalCount.ToString());
        Response.Headers.Add("X-Total-Pages", result.TotalPages.ToString());
        
        return Ok(result);
    }

    /// <summary>
    /// Get product by ID
    /// </summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ProductDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetProduct(Guid id)
    {
        var query = new GetProductByIdQuery { Id = id };
        var result = await Mediator.Send(query);
        
        return result.Match<IActionResult>(
            product => Ok(product),
            notFound => NotFound(new ProblemDetails
            {
                Title = "Product not found",
                Detail = $"Product with ID {id} was not found",
                Status = StatusCodes.Status404NotFound
            }));
    }

    /// <summary>
    /// Create a new product
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(ProductDto), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateProduct([FromBody] CreateProductCommand command)
    {
        var result = await Mediator.Send(command);
        
        return result.Match<IActionResult>(
            product => CreatedAtAction(nameof(GetProduct), new { id = product.Id }, product),
            failure => BadRequest(new ProblemDetails
            {
                Title = "Product creation failed",
                Detail = failure.Error,
                Status = StatusCodes.Status400BadRequest
            }));
    }

    /// <summary>
    /// Update an existing product
    /// </summary>
    [HttpPut("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ValidationProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateProduct(Guid id, [FromBody] UpdateProductCommand command)
    {
        if (id != command.Id)
            return BadRequest(new ProblemDetails
            {
                Title = "ID mismatch",
                Detail = "The ID in the URL does not match the ID in the request body",
                Status = StatusCodes.Status400BadRequest
            });

        var result = await Mediator.Send(command);
        
        return result.Match<IActionResult>(
            _ => NoContent(),
            notFound => NotFound(new ProblemDetails
            {
                Title = "Product not found",
                Detail = $"Product with ID {id} was not found",
                Status = StatusCodes.Status404NotFound
            }));
    }

    /// <summary>
    /// Delete a product
    /// </summary>
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [Authorize(Policy = "RequireManagerRole")]
    public async Task<IActionResult> DeleteProduct(Guid id)
    {
        var command = new DeleteProductCommand { Id = id };
        var result = await Mediator.Send(command);
        
        return result.Match<IActionResult>(
            _ => NoContent(),
            notFound => NotFound());
    }

    /// <summary>
    /// Get AI-generated product recommendations
    /// </summary>
    [HttpGet("{id:guid}/recommendations")]
    [ProducesResponseType(typeof(ProductRecommendation[]), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetRecommendations(Guid id, [FromQuery] int count = 5)
    {
        var query = new GetProductRecommendationsQuery { ProductId = id, Count = count };
        var result = await Mediator.Send(query);
        
        return Ok(result);
    }

    /// <summary>
    /// Get demand forecast for a product
    /// </summary>
    [HttpGet("{id:guid}/forecast")]
    [ProducesResponseType(typeof(DemandForecast), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [Authorize(Policy = "RequireAnalyticsAccess")]
    public async Task<IActionResult> GetDemandForecast(Guid id, [FromQuery] int daysAhead = 30)
    {
        var query = new GetDemandForecastQuery { ProductId = id, DaysAhead = daysAhead };
        var result = await Mediator.Send(query);
        
        return Ok(result);
    }
}
```

## 🔒 Step 5: Configure Authentication & Authorization

### 5.1 Configure JWT Authentication

Update `src/API/Program.cs`:

```csharp
var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add API versioning
builder.Services.AddApiVersioning(options =>
{
    options.DefaultApiVersion = new ApiVersion(1, 0);
    options.AssumeDefaultVersionWhenUnspecified = true;
    options.ReportApiVersions = true;
});

// Add authentication
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = builder.Configuration["Auth:Authority"];
        options.Audience = builder.Configuration["Auth:Audience"];
        options.RequireHttpsMetadata = !builder.Environment.IsDevelopment();
        
        options.Events = new JwtBearerEvents
        {
            OnTokenValidated = async context =>
            {
                // Extract tenant from token
                var tenantClaim = context.Principal?.FindFirst("tenant_id") ??
                                 context.Principal?.FindFirst("tid");
                                 
                if (tenantClaim != null && Guid.TryParse(tenantClaim.Value, out var tenantId))
                {
                    var tenantService = context.HttpContext.RequestServices
                        .GetRequiredService<ITenantService>();
                        
                    var tenantInfo = await tenantService.GetTenantAsync(tenantId);
                    
                    if (tenantInfo == null || tenantInfo.Status != TenantStatus.Active)
                    {
                        context.Fail("Invalid or inactive tenant");
                        return;
                    }
                }
            }
        };
    });

// Add authorization policies
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("RequireAuthenticatedUser", policy =>
        policy.RequireAuthenticatedUser());
        
    options.AddPolicy("RequireManagerRole", policy =>
        policy.RequireRole("Manager", "Admin"));
        
    options.AddPolicy("RequireAnalyticsAccess", policy =>
        policy.RequireAssertion(context =>
        {
            var tenantContext = context.Resource as HttpContext;
            var tenant = tenantContext?.RequestServices
                .GetRequiredService<ITenantContext>().Tenant;
                
            return tenant?.Features.TryGetValue("full_analytics", out var enabled) == true && enabled;
        }));
});

// Add application services
builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);

// Add caching
builder.Services.AddMemoryCache();
builder.Services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = builder.Configuration.GetConnectionString("Redis");
    options.InstanceName = "EnterpriseAPI";
});

// Add health checks
builder.Services.AddHealthChecks()
    .AddSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        name: "database")
    .AddRedis(
        builder.Configuration.GetConnectionString("Redis"),
        name: "redis");

var app = builder.Build();

// Configure middleware pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// Add tenant middleware
app.UseMiddleware<TenantResolutionMiddleware>();

app.UseAuthentication();
app.UseAuthorization();

// Add performance middleware
app.UseMiddleware<PerformanceLoggingMiddleware>();

app.MapControllers();
app.MapHealthChecks("/health");

app.Run();
```

### 5.2 Create Tenant Resolution Middleware

Create `src/API/Middleware/TenantResolutionMiddleware.cs`:

```csharp
namespace EnterpriseAPI.API.Middleware;

public class TenantResolutionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<TenantResolutionMiddleware> _logger;

    public TenantResolutionMiddleware(
        RequestDelegate next,
        ILogger<TenantResolutionMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var tenantService = context.RequestServices.GetRequiredService<ITenantService>();
        var tenantContext = context.RequestServices.GetRequiredService<ITenantContext>() as TenantContext;

        if (tenantContext == null)
        {
            await _next(context);
            return;
        }

        // Strategy 1: From subdomain (e.g., acme.api.example.com)
        var host = context.Request.Host.Host;
        var subdomain = host.Split('.').FirstOrDefault();
        
        if (!string.IsNullOrEmpty(subdomain) && subdomain != "api" && subdomain != "www")
        {
            var tenant = await tenantService.GetTenantAsync(subdomain);
            if (tenant != null)
            {
                tenantContext.SetTenant(tenant);
                _logger.LogInformation("Tenant resolved from subdomain: {TenantId}", tenant.Id);
            }
        }

        // Strategy 2: From header (X-Tenant-ID)
        if (tenantContext.TenantId == null)
        {
            var tenantHeader = context.Request.Headers["X-Tenant-ID"].FirstOrDefault();
            if (!string.IsNullOrEmpty(tenantHeader))
            {
                if (Guid.TryParse(tenantHeader, out var tenantId))
                {
                    var tenant = await tenantService.GetTenantAsync(tenantId);
                    if (tenant != null)
                    {
                        tenantContext.SetTenant(tenant);
                        _logger.LogInformation("Tenant resolved from header: {TenantId}", tenant.Id);
                    }
                }
            }
        }

        // Strategy 3: From JWT token (already handled in authentication)
        if (tenantContext.TenantId == null && context.User.Identity?.IsAuthenticated == true)
        {
            var tenantClaim = context.User.FindFirst("tenant_id") ?? 
                             context.User.FindFirst("tid");
                             
            if (tenantClaim != null && Guid.TryParse(tenantClaim.Value, out var tenantId))
            {
                var tenant = await tenantService.GetTenantAsync(tenantId);
                if (tenant != null)
                {
                    tenantContext.SetTenant(tenant);
                    _logger.LogInformation("Tenant resolved from token: {TenantId}", tenant.Id);
                }
            }
        }

        // Check if tenant is required for this endpoint
        var endpoint = context.GetEndpoint();
        var requiresTenant = endpoint?.Metadata.GetMetadata<RequiresTenantAttribute>() != null;

        if (requiresTenant && tenantContext.TenantId == null)
        {
            context.Response.StatusCode = StatusCodes.Status400BadRequest;
            await context.Response.WriteAsJsonAsync(new ProblemDetails
            {
                Title = "Tenant Required",
                Detail = "A valid tenant context is required for this operation",
                Status = StatusCodes.Status400BadRequest
            });
            return;
        }

        await _next(context);
    }
}
```

## 💡 Copilot Prompt Suggestions

**For Command Implementation:**
```
Create an UpdateProductCommand handler that:
- Validates the product exists
- Checks tenant ownership
- Updates only changed fields
- Logs the changes for audit
- Invalidates relevant caches
Include proper error handling and validation
```

**For AI Integration:**
```
Implement a Semantic Kernel plugin for:
- Analyzing customer reviews sentiment
- Extracting key product features mentioned
- Generating summary insights
Use Azure OpenAI with retry logic and error handling
```

**For Performance Optimization:**
```
Add Redis caching to GetProductsQuery with:
- Tenant-aware cache keys
- Sliding expiration
- Cache invalidation on updates
- Compression for large result sets
Include metrics for cache hit ratio
```

## ✅ Part 2 Checklist

Before moving to Part 3, ensure you have:

- [ ] Implemented CQRS with MediatR
- [ ] Created pipeline behaviors for cross-cutting concerns
- [ ] Built product commands and queries
- [ ] Integrated Semantic Kernel for AI features
- [ ] Created RESTful API controllers
- [ ] Configured JWT authentication
- [ ] Implemented tenant resolution middleware
- [ ] Added caching strategies
- [ ] Set up authorization policies

## 🎯 Part 2 Summary

You've successfully:
- Built a complete business logic layer with CQRS
- Integrated AI capabilities using Semantic Kernel
- Created secure, multi-tenant APIs
- Implemented caching for performance
- Added comprehensive authentication and authorization

## ⏭️ Next Steps

Continue to [Part 3: Testing and Validation](part3-testing.md) where you'll:
- Write comprehensive unit tests
- Create integration tests
- Add performance tests
- Validate security implementation
- Complete the production deployment

---

**🏆 Achievement**: You've built the core of an enterprise API platform with AI integration! The patterns implemented here are used by major SaaS providers serving millions of users.