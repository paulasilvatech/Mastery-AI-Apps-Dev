# Exercise 1: Enterprise API Platform - Part 3: Testing and Validation

## 🎯 Overview

In this final part, you'll complete the enterprise API platform by adding comprehensive testing, performance validation, and production deployment configurations. You'll ensure your platform meets enterprise standards for quality, security, and performance.

## 📋 Part 3 Objectives

- Write comprehensive unit tests
- Create integration tests for API endpoints
- Implement architecture tests
- Add performance and load testing
- Validate security implementation
- Configure production deployment

## 🧪 Step 1: Unit Testing

### 1.1 Create Test Project Structure

```bash
# Create test projects
cd tests

# Unit tests project
dotnet new xunit -n EnterpriseAPI.UnitTests
cd ..
dotnet sln add tests/EnterpriseAPI.UnitTests/EnterpriseAPI.UnitTests.csproj

# Add references
cd tests/EnterpriseAPI.UnitTests
dotnet add reference ../../src/Core/Application/EnterpriseAPI.Application.csproj
dotnet add reference ../../src/Core/Domain/EnterpriseAPI.Domain.csproj

# Add test packages
dotnet add package Microsoft.NET.Test.Sdk
dotnet add package xunit
dotnet add package xunit.runner.visualstudio
dotnet add package Moq
dotnet add package FluentAssertions
dotnet add package AutoFixture
dotnet add package AutoFixture.Xunit2

cd ../..
```

### 1.2 Test Domain Entities

Create `tests/EnterpriseAPI.UnitTests/Domain/Entities/ProductTests.cs`:

```csharp
namespace EnterpriseAPI.UnitTests.Domain.Entities;

public class ProductTests
{
    private readonly IFixture _fixture;

    public ProductTests()
    {
        _fixture = new Fixture();
    }

    [Fact]
    public void Create_WithValidData_ShouldCreateProduct()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var name = "Test Product";
        var sku = "TEST-001";
        var price = 99.99m;
        var categoryId = Guid.NewGuid();

        // Act
        var product = Product.Create(tenantId, name, sku, price, categoryId);

        // Assert
        product.Should().NotBeNull();
        product.Id.Should().NotBeEmpty();
        product.TenantId.Should().Be(tenantId);
        product.Name.Should().Be(name);
        product.SKU.Should().Be("TEST-001");
        product.Price.Should().Be(price);
        product.CategoryId.Should().Be(categoryId);
        product.Status.Should().Be(ProductStatus.Active);
        product.CreatedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(1));
    }

    [Theory]
    [InlineData("")]
    [InlineData(" ")]
    [InlineData(null)]
    public void Create_WithInvalidName_ShouldThrowException(string invalidName)
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var price = 99.99m;
        var categoryId = Guid.NewGuid();

        // Act & Assert
        var action = () => Product.Create(tenantId, invalidName, "SKU", price, categoryId);
        action.Should().Throw<ArgumentException>()
            .WithMessage("*name*");
    }

    [Theory]
    [InlineData(-1)]
    [InlineData(-99.99)]
    public void Create_WithNegativePrice_ShouldThrowException(decimal negativePrice)
    {
        // Act & Assert
        var action = () => Product.Create(
            Guid.NewGuid(), 
            "Product", 
            "SKU", 
            negativePrice, 
            Guid.NewGuid());
            
        action.Should().Throw<ArgumentException>()
            .WithMessage("*Price cannot be negative*");
    }

    [Fact]
    public void UpdatePrice_WithValidPrice_ShouldUpdatePrice()
    {
        // Arrange
        var product = CreateValidProduct();
        var newPrice = 149.99m;

        // Act
        product.UpdatePrice(newPrice);

        // Assert
        product.Price.Should().Be(newPrice);
        product.UpdatedAt.Should().NotBeNull();
        product.UpdatedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(1));
    }

    [Fact]
    public void AddFeature_WithNewFeature_ShouldAddFeature()
    {
        // Arrange
        var product = CreateValidProduct();
        var featureName = "Color";
        var featureValue = "Blue";

        // Act
        product.AddFeature(featureName, featureValue);

        // Assert
        product.Features.Should().HaveCount(1);
        product.Features.Should().Contain(f => 
            f.Name == featureName && f.Value == featureValue);
    }

    [Fact]
    public void AddFeature_WithDuplicateFeature_ShouldThrowException()
    {
        // Arrange
        var product = CreateValidProduct();
        product.AddFeature("Color", "Blue");

        // Act & Assert
        var action = () => product.AddFeature("Color", "Red");
        action.Should().Throw<InvalidOperationException>()
            .WithMessage("*Feature 'Color' already exists*");
    }

    private Product CreateValidProduct()
    {
        return Product.Create(
            Guid.NewGuid(),
            _fixture.Create<string>(),
            _fixture.Create<string>(),
            _fixture.Create<decimal>(),
            Guid.NewGuid());
    }
}
```

### 1.3 Test Application Commands

Create `tests/EnterpriseAPI.UnitTests/Application/Products/Commands/CreateProductCommandHandlerTests.cs`:

```csharp
namespace EnterpriseAPI.UnitTests.Application.Products.Commands;

public class CreateProductCommandHandlerTests
{
    private readonly Mock<IApplicationDbContext> _contextMock;
    private readonly Mock<ITenantContext> _tenantContextMock;
    private readonly Mock<IMapper> _mapperMock;
    private readonly Mock<IAIService> _aiServiceMock;
    private readonly Mock<ILogger<CreateProductCommandHandler>> _loggerMock;
    private readonly CreateProductCommandHandler _handler;
    private readonly IFixture _fixture;

    public CreateProductCommandHandlerTests()
    {
        _contextMock = new Mock<IApplicationDbContext>();
        _tenantContextMock = new Mock<ITenantContext>();
        _mapperMock = new Mock<IMapper>();
        _aiServiceMock = new Mock<IAIService>();
        _loggerMock = new Mock<ILogger<CreateProductCommandHandler>>();
        _fixture = new Fixture();

        _handler = new CreateProductCommandHandler(
            _contextMock.Object,
            _tenantContextMock.Object,
            _mapperMock.Object,
            _aiServiceMock.Object,
            _loggerMock.Object);
    }

    [Fact]
    public async Task Handle_WithValidCommand_ShouldCreateProduct()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var command = new CreateProductCommand
        {
            Name = "Test Product",
            SKU = "TEST-001",
            Price = 99.99m,
            CategoryId = Guid.NewGuid(),
            GenerateAIDescription = false
        };

        var expectedDto = new ProductDto
        {
            Id = Guid.NewGuid(),
            Name = command.Name,
            SKU = command.SKU,
            Price = command.Price
        };

        _tenantContextMock.Setup(x => x.TenantId).Returns(tenantId);
        
        var categoriesDbSet = CreateMockDbSet(new List<Category>
        {
            new Category { Id = command.CategoryId, Name = "Test Category" }
        });
        _contextMock.Setup(x => x.Categories).Returns(categoriesDbSet.Object);

        var productsDbSet = CreateMockDbSet(new List<Product>());
        _contextMock.Setup(x => x.Products).Returns(productsDbSet.Object);

        _contextMock.Setup(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(1);

        _mapperMock.Setup(x => x.Map<ProductDto>(It.IsAny<Product>()))
            .Returns(expectedDto);

        // Act
        var result = await _handler.Handle(command, CancellationToken.None);

        // Assert
        result.Should().NotBeNull();
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().BeEquivalentTo(expectedDto);

        _contextMock.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
        productsDbSet.Verify(x => x.Add(It.IsAny<Product>()), Times.Once);
    }

    [Fact]
    public async Task Handle_WithAIDescription_ShouldGenerateDescription()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var command = new CreateProductCommand
        {
            Name = "AI Product",
            SKU = "AI-001",
            Price = 199.99m,
            CategoryId = Guid.NewGuid(),
            GenerateAIDescription = true
        };

        var aiGeneratedDescription = "This is an AI-generated description";

        _tenantContextMock.Setup(x => x.TenantId).Returns(tenantId);
        _tenantContextMock.Setup(x => x.Tenant).Returns(new TenantInfo
        {
            Features = new Dictionary<string, bool> { ["ai_features"] = true }
        });

        _aiServiceMock.Setup(x => x.GenerateProductDescriptionAsync(
            command.Name,
            command.CategoryId,
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(aiGeneratedDescription);

        SetupMocksForValidCommand(command);

        // Act
        var result = await _handler.Handle(command, CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeTrue();
        _aiServiceMock.Verify(x => x.GenerateProductDescriptionAsync(
            command.Name,
            command.CategoryId,
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task Handle_WithoutTenantContext_ShouldReturnFailure()
    {
        // Arrange
        var command = _fixture.Create<CreateProductCommand>();
        _tenantContextMock.Setup(x => x.TenantId).Returns((Guid?)null);

        // Act
        var result = await _handler.Handle(command, CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeFalse();
        result.Error.Should().Be("Tenant context is required");
    }

    [Fact]
    public async Task Handle_WithDuplicateSKU_ShouldReturnFailure()
    {
        // Arrange
        var tenantId = Guid.NewGuid();
        var command = new CreateProductCommand
        {
            Name = "Test Product",
            SKU = "DUPLICATE-001",
            Price = 99.99m,
            CategoryId = Guid.NewGuid()
        };

        _tenantContextMock.Setup(x => x.TenantId).Returns(tenantId);

        var existingProduct = new Product { SKU = command.SKU.ToUpperInvariant() };
        var productsDbSet = CreateMockDbSet(new List<Product> { existingProduct });
        _contextMock.Setup(x => x.Products).Returns(productsDbSet.Object);

        // Act
        var result = await _handler.Handle(command, CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeFalse();
        result.Error.Should().Contain($"Product with SKU '{command.SKU}' already exists");
    }

    private void SetupMocksForValidCommand(CreateProductCommand command)
    {
        var categoriesDbSet = CreateMockDbSet(new List<Category>
        {
            new Category { Id = command.CategoryId, Name = "Test Category" }
        });
        _contextMock.Setup(x => x.Categories).Returns(categoriesDbSet.Object);

        var productsDbSet = CreateMockDbSet(new List<Product>());
        _contextMock.Setup(x => x.Products).Returns(productsDbSet.Object);

        _contextMock.Setup(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(1);

        _mapperMock.Setup(x => x.Map<ProductDto>(It.IsAny<Product>()))
            .Returns(new ProductDto());
    }

    private Mock<DbSet<T>> CreateMockDbSet<T>(List<T> data) where T : class
    {
        var queryable = data.AsQueryable();
        var dbSetMock = new Mock<DbSet<T>>();

        dbSetMock.As<IQueryable<T>>().Setup(m => m.Provider).Returns(queryable.Provider);
        dbSetMock.As<IQueryable<T>>().Setup(m => m.Expression).Returns(queryable.Expression);
        dbSetMock.As<IQueryable<T>>().Setup(m => m.ElementType).Returns(queryable.ElementType);
        dbSetMock.As<IQueryable<T>>().Setup(m => m.GetEnumerator()).Returns(queryable.GetEnumerator());

        dbSetMock.As<IAsyncEnumerable<T>>()
            .Setup(m => m.GetAsyncEnumerator(It.IsAny<CancellationToken>()))
            .Returns(new TestAsyncEnumerator<T>(data.GetEnumerator()));

        return dbSetMock;
    }
}
```

## 🔌 Step 2: Integration Testing

### 2.1 Create Integration Test Project

```bash
# Integration tests project
cd tests
dotnet new xunit -n EnterpriseAPI.IntegrationTests
cd ..
dotnet sln add tests/EnterpriseAPI.IntegrationTests/EnterpriseAPI.IntegrationTests.csproj

# Add references and packages
cd tests/EnterpriseAPI.IntegrationTests
dotnet add reference ../../src/API/EnterpriseAPI.API.csproj

dotnet add package Microsoft.AspNetCore.Mvc.Testing
dotnet add package Testcontainers
dotnet add package Testcontainers.MsSql
dotnet add package Respawn
dotnet add package WireMock.Net

cd ../..
```

### 2.2 Create Test Web Application Factory

Create `tests/EnterpriseAPI.IntegrationTests/TestWebApplicationFactory.cs`:

```csharp
namespace EnterpriseAPI.IntegrationTests;

public class TestWebApplicationFactory : WebApplicationFactory<Program>
{
    private readonly MsSqlContainer _sqlContainer;
    private readonly IContainer _redisContainer;
    private readonly WireMockServer _wireMockServer;

    public TestWebApplicationFactory()
    {
        // Setup SQL Server container
        _sqlContainer = new MsSqlBuilder()
            .WithImage("mcr.microsoft.com/mssql/server:2022-latest")
            .WithPassword("Test@123")
            .Build();

        // Setup Redis container
        _redisContainer = new ContainerBuilder()
            .WithImage("redis:alpine")
            .WithPortBinding(6379, true)
            .Build();

        // Setup WireMock for external API mocking
        _wireMockServer = WireMockServer.Start();
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureServices(services =>
        {
            // Remove existing database configuration
            RemoveService<DbContextOptions<ApplicationDbContext>>(services);
            RemoveService<ApplicationDbContext>(services);

            // Add test database
            services.AddDbContext<ApplicationDbContext>(options =>
            {
                options.UseSqlServer(_sqlContainer.GetConnectionString());
            });

            // Remove existing Redis configuration
            RemoveService<IDistributedCache>(services);

            // Add test Redis
            services.AddStackExchangeRedisCache(options =>
            {
                options.Configuration = $"localhost:{_redisContainer.GetMappedPublicPort(6379)}";
            });

            // Override AI service with mock
            RemoveService<IAIService>(services);
            services.AddSingleton<IAIService>(new MockAIService(_wireMockServer));

            // Add test authentication
            services.AddAuthentication("Test")
                .AddScheme<TestAuthenticationSchemeOptions, TestAuthenticationHandler>(
                    "Test", options => { });

            // Override with test scheme
            services.AddAuthorization(options =>
            {
                options.DefaultPolicy = new AuthorizationPolicyBuilder("Test")
                    .RequireAuthenticatedUser()
                    .Build();
            });
        });

        builder.UseEnvironment("Testing");
    }

    public async Task InitializeAsync()
    {
        await _sqlContainer.StartAsync();
        await _redisContainer.StartAsync();

        // Run migrations
        using var scope = Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        await dbContext.Database.MigrateAsync();

        // Seed test data
        await SeedTestDataAsync(dbContext);
    }

    public new async Task DisposeAsync()
    {
        await _sqlContainer.DisposeAsync();
        await _redisContainer.DisposeAsync();
        _wireMockServer.Stop();
        await base.DisposeAsync();
    }

    private static void RemoveService<T>(IServiceCollection services)
    {
        var descriptor = services.SingleOrDefault(d => d.ServiceType == typeof(T));
        if (descriptor != null)
            services.Remove(descriptor);
    }

    private async Task SeedTestDataAsync(ApplicationDbContext context)
    {
        // Seed test tenant
        var testTenant = Tenant.Create("Test Company", "test", TenantPlan.Premium);
        context.Tenants.Add(testTenant);

        // Seed test categories
        var category = Category.Create(testTenant.Id, "Electronics");
        context.Categories.Add(category);

        // Seed test products
        var product1 = Product.Create(testTenant.Id, "Laptop", "LAPTOP-001", 999.99m, category.Id);
        var product2 = Product.Create(testTenant.Id, "Mouse", "MOUSE-001", 29.99m, category.Id);
        
        context.Products.AddRange(product1, product2);
        
        await context.SaveChangesAsync();
    }
}
```

### 2.3 Create API Integration Tests

Create `tests/EnterpriseAPI.IntegrationTests/Controllers/ProductsControllerTests.cs`:

```csharp
namespace EnterpriseAPI.IntegrationTests.Controllers;

[Collection("Integration")]
public class ProductsControllerTests : IClassFixture<TestWebApplicationFactory>, IAsyncLifetime
{
    private readonly TestWebApplicationFactory _factory;
    private readonly HttpClient _client;
    private Respawner _respawner = null!;
    private string _connectionString = null!;

    public ProductsControllerTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _client = _factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                // Configure test-specific services
            });
        }).CreateClient();

        // Set default headers
        _client.DefaultRequestHeaders.Add("X-Tenant-ID", "test-tenant-id");
        _client.DefaultRequestHeaders.Authorization = 
            new AuthenticationHeaderValue("Test", "test-user");
    }

    public async Task InitializeAsync()
    {
        await _factory.InitializeAsync();
        
        // Get connection string from factory
        using var scope = _factory.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        _connectionString = context.Database.GetConnectionString()!;

        // Configure Respawner for database cleanup
        _respawner = await Respawner.CreateAsync(_connectionString, new RespawnerOptions
        {
            TablesToIgnore = new[] { "__EFMigrationsHistory" }
        });
    }

    public Task DisposeAsync() => Task.CompletedTask;

    [Fact]
    public async Task GetProducts_ShouldReturnPaginatedResults()
    {
        // Act
        var response = await _client.GetAsync("/api/v1/products?pageSize=10");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        
        var content = await response.Content.ReadAsStringAsync();
        var result = JsonSerializer.Deserialize<PagedResult<ProductDto>>(content, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });

        result.Should().NotBeNull();
        result!.Items.Should().NotBeEmpty();
        result.PageSize.Should().Be(10);
        
        // Check pagination headers
        response.Headers.Should().ContainKey("X-Total-Count");
        response.Headers.Should().ContainKey("X-Page-Number");
    }

    [Fact]
    public async Task CreateProduct_WithValidData_ShouldCreateProduct()
    {
        // Arrange
        var command = new CreateProductCommand
        {
            Name = "Integration Test Product",
            SKU = "INT-TEST-001",
            Price = 149.99m,
            CategoryId = await GetTestCategoryId(),
            GenerateAIDescription = true
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/v1/products", command);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        response.Headers.Location.Should().NotBeNull();

        var content = await response.Content.ReadAsStringAsync();
        var createdProduct = JsonSerializer.Deserialize<ProductDto>(content, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });

        createdProduct.Should().NotBeNull();
        createdProduct!.Name.Should().Be(command.Name);
        createdProduct.SKU.Should().Be(command.SKU);
        createdProduct.Price.Should().Be(command.Price);
        createdProduct.Description.Should().NotBeNullOrEmpty(); // AI generated
    }

    [Fact]
    public async Task CreateProduct_WithDuplicateSKU_ShouldReturnBadRequest()
    {
        // Arrange
        var categoryId = await GetTestCategoryId();
        var existingSku = "EXISTING-SKU";
        
        // Create first product
        await _client.PostAsJsonAsync("/api/v1/products", new CreateProductCommand
        {
            Name = "First Product",
            SKU = existingSku,
            Price = 99.99m,
            CategoryId = categoryId
        });

        // Try to create duplicate
        var duplicateCommand = new CreateProductCommand
        {
            Name = "Duplicate Product",
            SKU = existingSku,
            Price = 149.99m,
            CategoryId = categoryId
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/v1/products", duplicateCommand);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        
        var problemDetails = await response.Content.ReadFromJsonAsync<ProblemDetails>();
        problemDetails.Should().NotBeNull();
        problemDetails!.Detail.Should().Contain("already exists");
    }

    [Fact]
    public async Task GetProduct_WithInvalidId_ShouldReturnNotFound()
    {
        // Arrange
        var nonExistentId = Guid.NewGuid();

        // Act
        var response = await _client.GetAsync($"/api/v1/products/{nonExistentId}");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task UpdateProduct_WithValidData_ShouldUpdateProduct()
    {
        // Arrange
        var product = await CreateTestProduct();
        var updateCommand = new UpdateProductCommand
        {
            Id = product.Id,
            Name = "Updated Product Name",
            Price = 199.99m
        };

        // Act
        var response = await _client.PutAsJsonAsync($"/api/v1/products/{product.Id}", updateCommand);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.NoContent);

        // Verify update
        var getResponse = await _client.GetAsync($"/api/v1/products/{product.Id}");
        var updatedProduct = await getResponse.Content.ReadFromJsonAsync<ProductDto>();
        
        updatedProduct.Should().NotBeNull();
        updatedProduct!.Name.Should().Be(updateCommand.Name);
        updatedProduct.Price.Should().Be(updateCommand.Price);
    }

    [Fact]
    public async Task GetRecommendations_ShouldReturnRecommendations()
    {
        // Arrange
        var product = await CreateTestProduct();

        // Act
        var response = await _client.GetAsync($"/api/v1/products/{product.Id}/recommendations?count=5");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        
        var recommendations = await response.Content.ReadFromJsonAsync<ProductRecommendation[]>();
        recommendations.Should().NotBeNull();
        recommendations!.Length.Should().BeLessThanOrEqualTo(5);
    }

    private async Task<Guid> GetTestCategoryId()
    {
        using var scope = _factory.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        
        var category = await context.Categories.FirstAsync();
        return category.Id;
    }

    private async Task<ProductDto> CreateTestProduct()
    {
        var command = new CreateProductCommand
        {
            Name = $"Test Product {Guid.NewGuid()}",
            SKU = $"TEST-{Guid.NewGuid().ToString()[..8]}",
            Price = 99.99m,
            CategoryId = await GetTestCategoryId()
        };

        var response = await _client.PostAsJsonAsync("/api/v1/products", command);
        response.EnsureSuccessStatusCode();
        
        return (await response.Content.ReadFromJsonAsync<ProductDto>())!;
    }
}
```

## 🏛️ Step 3: Architecture Testing

### 3.1 Create Architecture Test Project

```bash
cd tests
dotnet new xunit -n EnterpriseAPI.ArchitectureTests
cd ..
dotnet sln add tests/EnterpriseAPI.ArchitectureTests/EnterpriseAPI.ArchitectureTests.csproj

cd tests/EnterpriseAPI.ArchitectureTests
dotnet add package NetArchTest.Rules
cd ../..
```

### 3.2 Create Architecture Tests

Create `tests/EnterpriseAPI.ArchitectureTests/ArchitectureTests.cs`:

```csharp
namespace EnterpriseAPI.ArchitectureTests;

public class ArchitectureTests
{
    private const string DomainNamespace = "EnterpriseAPI.Domain";
    private const string ApplicationNamespace = "EnterpriseAPI.Application";
    private const string InfrastructureNamespace = "EnterpriseAPI.Infrastructure";
    private const string ApiNamespace = "EnterpriseAPI.API";
    
    [Fact]
    public void Domain_Should_Not_HaveDependencyOnOtherProjects()
    {
        // Arrange
        var assembly = typeof(Product).Assembly;

        // Act
        var result = Types
            .InAssembly(assembly)
            .Should()
            .NotHaveDependencyOnAll(ApplicationNamespace, InfrastructureNamespace, ApiNamespace)
            .GetResult();

        // Assert
        result.IsSuccessful.Should().BeTrue($"Domain should not depend on other layers: {GetFailingTypes(result)}");
    }

    [Fact]
    public void Application_Should_Not_HaveDependencyOnInfrastructure()
    {
        // Arrange
        var assembly = typeof(CreateProductCommand).Assembly;

        // Act
        var result = Types
            .InAssembly(assembly)
            .Should()
            .NotHaveDependencyOn(InfrastructureNamespace)
            .GetResult();

        // Assert
        result.IsSuccessful.Should().BeTrue($"Application should not depend on Infrastructure: {GetFailingTypes(result)}");
    }

    [Fact]
    public void Handlers_Should_BeSealed()
    {
        // Arrange
        var assembly = typeof(CreateProductCommandHandler).Assembly;

        // Act
        var result = Types
            .InAssembly(assembly)
            .That()
            .ImplementInterface(typeof(IRequestHandler<,>))
            .Or()
            .ImplementInterface(typeof(IRequestHandler<>))
            .Should()
            .BeSealed()
            .GetResult();

        // Assert
        result.IsSuccessful.Should().BeTrue($"Handlers should be sealed: {GetFailingTypes(result)}");
    }

    [Fact]
    public void Entities_Should_HavePrivateParameterlessConstructor()
    {
        // Arrange
        var assembly = typeof(Product).Assembly;

        // Act
        var types = Types
            .InAssembly(assembly)
            .That()
            .Inherit(typeof(BaseEntity))
            .GetTypes();

        // Assert
        foreach (var type in types)
        {
            var hasPrivateConstructor = type
                .GetConstructors(BindingFlags.NonPublic | BindingFlags.Instance)
                .Any(c => c.IsPrivate && c.GetParameters().Length == 0);

            hasPrivateConstructor.Should().BeTrue(
                $"{type.Name} should have a private parameterless constructor for EF Core");
        }
    }

    [Fact]
    public void ValueObjects_Should_BeImmutable()
    {
        // Arrange
        var assembly = typeof(Money).Assembly;

        // Act
        var types = Types
            .InAssembly(assembly)
            .That()
            .AreClasses()
            .And()
            .ImplementInterface(typeof(IValueObject))
            .GetTypes();

        // Assert
        foreach (var type in types)
        {
            var properties = type.GetProperties(BindingFlags.Public | BindingFlags.Instance);
            
            foreach (var property in properties)
            {
                property.CanWrite.Should().BeFalse(
                    $"Property {property.Name} in value object {type.Name} should be read-only");
            }
        }
    }

    [Fact]
    public void Controllers_Should_HaveApiControllerAttribute()
    {
        // Arrange
        var assembly = typeof(ProductsController).Assembly;

        // Act
        var result = Types
            .InAssembly(assembly)
            .That()
            .Inherit(typeof(ControllerBase))
            .Should()
            .HaveCustomAttribute(typeof(ApiControllerAttribute))
            .GetResult();

        // Assert
        result.IsSuccessful.Should().BeTrue($"All controllers should have [ApiController]: {GetFailingTypes(result)}");
    }

    [Fact]
    public void Interfaces_Should_StartWithI()
    {
        // Arrange
        var assemblies = new[]
        {
            typeof(Product).Assembly,
            typeof(CreateProductCommand).Assembly
        };

        // Act & Assert
        foreach (var assembly in assemblies)
        {
            var result = Types
                .InAssembly(assembly)
                .That()
                .AreInterfaces()
                .Should()
                .HaveNameStartingWith("I")
                .GetResult();

            result.IsSuccessful.Should().BeTrue(
                $"Interfaces should start with 'I': {GetFailingTypes(result)}");
        }
    }

    private static string GetFailingTypes(TestResult result)
    {
        return result.FailingTypeNames != null 
            ? string.Join(", ", result.FailingTypeNames) 
            : "No failing types";
    }
}
```

## 🚀 Step 4: Performance Testing

### 4.1 Create Performance Tests

Create `tests/EnterpriseAPI.IntegrationTests/Performance/LoadTests.cs`:

```csharp
namespace EnterpriseAPI.IntegrationTests.Performance;

public class LoadTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;
    private readonly HttpClient _client;

    public LoadTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _client = _factory.CreateClient();
        _client.DefaultRequestHeaders.Add("X-Tenant-ID", "perf-test-tenant");
    }

    [Fact]
    public async Task GetProducts_ShouldHandleLoad()
    {
        // Arrange
        const int concurrentRequests = 100;
        const int expectedMaxResponseTime = 100; // milliseconds
        var tasks = new List<Task<(HttpResponseMessage response, long elapsedMs)>>();

        // Act
        for (int i = 0; i < concurrentRequests; i++)
        {
            tasks.Add(MeasureRequestTime(() => _client.GetAsync("/api/v1/products?pageSize=20")));
        }

        var results = await Task.WhenAll(tasks);

        // Assert
        var successfulRequests = results.Where(r => r.response.IsSuccessStatusCode).ToList();
        var avgResponseTime = successfulRequests.Average(r => r.elapsedMs);
        var maxResponseTime = successfulRequests.Max(r => r.elapsedMs);
        var p95ResponseTime = successfulRequests
            .OrderBy(r => r.elapsedMs)
            .Skip((int)(successfulRequests.Count * 0.95))
            .First()
            .elapsedMs;

        // All requests should succeed
        successfulRequests.Count.Should().Be(concurrentRequests);
        
        // Performance assertions
        avgResponseTime.Should().BeLessThan(expectedMaxResponseTime);
        p95ResponseTime.Should().BeLessThan(expectedMaxResponseTime * 2);
        
        _testOutputHelper.WriteLine($"Average response time: {avgResponseTime}ms");
        _testOutputHelper.WriteLine($"P95 response time: {p95ResponseTime}ms");
        _testOutputHelper.WriteLine($"Max response time: {maxResponseTime}ms");
    }

    [Fact]
    public async Task CreateProduct_ShouldHandleBurst()
    {
        // Arrange
        const int burstSize = 50;
        var categoryId = await GetTestCategoryId();
        var tasks = new List<Task<HttpResponseMessage>>();

        // Act
        for (int i = 0; i < burstSize; i++)
        {
            var command = new CreateProductCommand
            {
                Name = $"Burst Test Product {i}",
                SKU = $"BURST-{Guid.NewGuid().ToString()[..8]}",
                Price = 99.99m,
                CategoryId = categoryId
            };

            tasks.Add(_client.PostAsJsonAsync("/api/v1/products", command));
        }

        var responses = await Task.WhenAll(tasks);

        // Assert
        var successCount = responses.Count(r => r.StatusCode == HttpStatusCode.Created);
        successCount.Should().Be(burstSize);
    }

    private async Task<(HttpResponseMessage response, long elapsedMs)> MeasureRequestTime(
        Func<Task<HttpResponseMessage>> request)
    {
        var stopwatch = Stopwatch.StartNew();
        var response = await request();
        stopwatch.Stop();
        
        return (response, stopwatch.ElapsedMilliseconds);
    }

    private async Task<Guid> GetTestCategoryId()
    {
        using var scope = _factory.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        return (await context.Categories.FirstAsync()).Id;
    }
}
```

### 4.2 Create k6 Load Test Script

Create `tests/performance/load-test.js`:

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

// Test configuration
export const options = {
    stages: [
        { duration: '30s', target: 10 },   // Ramp up to 10 users
        { duration: '1m', target: 50 },    // Ramp up to 50 users
        { duration: '2m', target: 100 },   // Stay at 100 users
        { duration: '1m', target: 50 },    // Ramp down to 50 users
        { duration: '30s', target: 0 },    // Ramp down to 0 users
    ],
    thresholds: {
        http_req_duration: ['p(95)<200'], // 95% of requests must complete below 200ms
        errors: ['rate<0.1'],             // Error rate must be below 10%
    },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:5000';
const TENANT_ID = __ENV.TENANT_ID || 'load-test-tenant';

export function setup() {
    // Setup code - create test data if needed
    console.log('Setting up load test...');
}

export default function () {
    // Test scenario
    const params = {
        headers: {
            'Content-Type': 'application/json',
            'X-Tenant-ID': TENANT_ID,
            'Authorization': 'Bearer test-token',
        },
    };

    // Scenario 1: Browse products
    let response = http.get(`${BASE_URL}/api/v1/products?pageSize=20`, params);
    check(response, {
        'products list status is 200': (r) => r.status === 200,
        'products list response time < 200ms': (r) => r.timings.duration < 200,
    });
    errorRate.add(response.status !== 200);

    sleep(1);

    // Scenario 2: View product details
    const products = response.json('items');
    if (products && products.length > 0) {
        const productId = products[Math.floor(Math.random() * products.length)].id;
        response = http.get(`${BASE_URL}/api/v1/products/${productId}`, params);
        
        check(response, {
            'product details status is 200': (r) => r.status === 200,
            'product details response time < 100ms': (r) => r.timings.duration < 100,
        });
        errorRate.add(response.status !== 200);
    }

    sleep(2);

    // Scenario 3: Create a product (less frequent)
    if (Math.random() < 0.1) { // 10% of users create products
        const payload = JSON.stringify({
            name: `Load Test Product ${Date.now()}`,
            sku: `LT-${Date.now()}`,
            price: Math.random() * 1000,
            categoryId: 'test-category-id',
        });

        response = http.post(`${BASE_URL}/api/v1/products`, payload, params);
        
        check(response, {
            'create product status is 201': (r) => r.status === 201,
            'create product response time < 500ms': (r) => r.timings.duration < 500,
        });
        errorRate.add(response.status !== 201);
    }

    sleep(1);
}

export function teardown(data) {
    // Cleanup code
    console.log('Load test completed');
}
```

## 🔒 Step 5: Security Testing

### 5.1 Create Security Tests

Create `tests/EnterpriseAPI.IntegrationTests/Security/SecurityTests.cs`:

```csharp
namespace EnterpriseAPI.IntegrationTests.Security;

public class SecurityTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;
    private readonly HttpClient _client;

    public SecurityTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _client = _factory.CreateClient();
    }

    [Fact]
    public async Task Api_ShouldRequireAuthentication()
    {
        // Arrange - No authentication headers

        // Act
        var response = await _client.GetAsync("/api/v1/products");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Api_ShouldRequireTenantContext()
    {
        // Arrange - Authentication but no tenant
        _client.DefaultRequestHeaders.Authorization = 
            new AuthenticationHeaderValue("Test", "test-user");

        // Act
        var response = await _client.GetAsync("/api/v1/products");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        
        var problemDetails = await response.Content.ReadFromJsonAsync<ProblemDetails>();
        problemDetails!.Detail.Should().Contain("tenant");
    }

    [Fact]
    public async Task Api_ShouldPreventCrossTenantAccess()
    {
        // Arrange
        var tenant1Id = Guid.NewGuid();
        var tenant2Id = Guid.NewGuid();
        
        // Create product in tenant 1
        _client.DefaultRequestHeaders.Add("X-Tenant-ID", tenant1Id.ToString());
        var product = await CreateTestProduct();

        // Switch to tenant 2
        _client.DefaultRequestHeaders.Remove("X-Tenant-ID");
        _client.DefaultRequestHeaders.Add("X-Tenant-ID", tenant2Id.ToString());

        // Act - Try to access tenant 1's product
        var response = await _client.GetAsync($"/api/v1/products/{product.Id}");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task Api_ShouldHaveSecurityHeaders()
    {
        // Arrange
        _client.DefaultRequestHeaders.Add("X-Tenant-ID", "test-tenant");
        _client.DefaultRequestHeaders.Authorization = 
            new AuthenticationHeaderValue("Test", "test-user");

        // Act
        var response = await _client.GetAsync("/api/v1/products");

        // Assert
        response.Headers.Should().ContainKey("X-Content-Type-Options");
        response.Headers.GetValues("X-Content-Type-Options").Should().Contain("nosniff");
        
        response.Headers.Should().ContainKey("X-Frame-Options");
        response.Headers.GetValues("X-Frame-Options").Should().Contain("DENY");
        
        response.Headers.Should().ContainKey("X-XSS-Protection");
        response.Headers.GetValues("X-XSS-Protection").Should().Contain("1; mode=block");
    }

    [Fact]
    public async Task Api_ShouldValidateInput()
    {
        // Arrange
        _client.DefaultRequestHeaders.Add("X-Tenant-ID", "test-tenant");
        _client.DefaultRequestHeaders.Authorization = 
            new AuthenticationHeaderValue("Test", "test-user");

        var invalidCommand = new CreateProductCommand
        {
            Name = new string('A', 201), // Exceeds max length
            SKU = "INVALID SKU!@#", // Invalid characters
            Price = -100, // Negative price
            CategoryId = Guid.Empty // Empty GUID
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/v1/products", invalidCommand);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        
        var validationProblem = await response.Content.ReadFromJsonAsync<ValidationProblemDetails>();
        validationProblem!.Errors.Should().ContainKey("Name");
        validationProblem.Errors.Should().ContainKey("SKU");
        validationProblem.Errors.Should().ContainKey("Price");
    }

    [Fact]
    public async Task Api_ShouldPreventSqlInjection()
    {
        // Arrange
        _client.DefaultRequestHeaders.Add("X-Tenant-ID", "test-tenant");
        _client.DefaultRequestHeaders.Authorization = 
            new AuthenticationHeaderValue("Test", "test-user");

        var maliciousSearchTerm = "'; DROP TABLE Products; --";

        // Act
        var response = await _client.GetAsync(
            $"/api/v1/products?searchTerm={Uri.EscapeDataString(maliciousSearchTerm)}");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        // The request should complete successfully without executing the SQL injection
        
        // Verify table still exists
        using var scope = _factory.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var tableExists = await context.Products.AnyAsync();
        tableExists.Should().BeTrue();
    }

    private async Task<ProductDto> CreateTestProduct()
    {
        var command = new CreateProductCommand
        {
            Name = "Security Test Product",
            SKU = $"SEC-{Guid.NewGuid().ToString()[..8]}",
            Price = 99.99m,
            CategoryId = Guid.NewGuid()
        };

        var response = await _client.PostAsJsonAsync("/api/v1/products", command);
        response.EnsureSuccessStatusCode();
        
        return (await response.Content.ReadFromJsonAsync<ProductDto>())!;
    }
}
```

## 🚀 Step 6: Production Deployment

### 6.1 Create Docker Configuration

Create `Dockerfile` in the API project:

```dockerfile
# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy solution and project files
COPY ["EnterpriseAPI.sln", "./"]
COPY ["src/Core/Domain/EnterpriseAPI.Domain.csproj", "src/Core/Domain/"]
COPY ["src/Core/Application/EnterpriseAPI.Application.csproj", "src/Core/Application/"]
COPY ["src/Infrastructure/EnterpriseAPI.Infrastructure.csproj", "src/Infrastructure/"]
COPY ["src/API/EnterpriseAPI.API.csproj", "src/API/"]

# Restore dependencies
RUN dotnet restore

# Copy source code
COPY . .

# Build
WORKDIR "/src/src/API"
RUN dotnet build "EnterpriseAPI.API.csproj" -c Release -o /app/build

# Publish
FROM build AS publish
RUN dotnet publish "EnterpriseAPI.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

# Install culture data
RUN apt-get update && apt-get install -y locales

# Create non-root user
RUN groupadd -g 1000 dotnet && \
    useradd -u 1000 -g dotnet -s /bin/bash -m dotnet

# Copy published app
COPY --from=publish /app/publish .
RUN chown -R dotnet:dotnet /app

# Switch to non-root user
USER dotnet

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Configure Kestrel
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

EXPOSE 8080
ENTRYPOINT ["dotnet", "EnterpriseAPI.API.dll"]
```

### 6.2 Create Kubernetes Deployment

Create `k8s/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: enterprise-api
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: enterprise-api
  template:
    metadata:
      labels:
        app: enterprise-api
    spec:
      containers:
      - name: api
        image: enterpriseapi.azurecr.io/enterprise-api:latest
        ports:
        - containerPort: 8080
        env:
        - name: ASPNETCORE_ENVIRONMENT
          value: "Production"
        - name: ConnectionStrings__DefaultConnection
          valueFrom:
            secretKeyRef:
              name: api-secrets
              key: connection-string
        - name: AzureOpenAI__ApiKey
          valueFrom:
            secretKeyRef:
              name: api-secrets
              key: openai-api-key
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
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: enterprise-api-service
  namespace: production
spec:
  selector:
    app: enterprise-api
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: enterprise-api-ingress
  namespace: production
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rate-limit: "100"
spec:
  tls:
  - hosts:
    - api.enterprise.com
    secretName: api-tls
  rules:
  - host: api.enterprise.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: enterprise-api-service
            port:
              number: 80
```

## 💡 Copilot Prompt Suggestions

**For Test Creation:**
```
Create a unit test for the TenantResolutionMiddleware that:
- Tests subdomain resolution
- Tests header resolution
- Tests token resolution
- Tests fallback behavior
- Tests invalid tenant handling
Use Moq and FluentAssertions
```

**For Performance Testing:**
```
Create a BenchmarkDotNet test that:
- Compares EF Core query strategies
- Measures caching impact
- Tests concurrent operations
- Includes memory diagnostics
Show before/after optimization results
```

**For Security Testing:**
```
Create security tests for:
- JWT token validation
- Rate limiting enforcement
- Input sanitization
- CORS policy validation
- SQL injection prevention
Include OWASP Top 10 scenarios
```

## ✅ Part 3 Checklist

Ensure you have:

- [ ] Created comprehensive unit tests
- [ ] Implemented integration tests with TestContainers
- [ ] Added architecture tests
- [ ] Created performance tests
- [ ] Implemented security tests
- [ ] Configured Docker deployment
- [ ] Created Kubernetes manifests
- [ ] Set up CI/CD pipeline
- [ ] Validated production readiness

## 🎯 Exercise Summary

Congratulations! You've successfully built a production-ready enterprise API platform with:

- **Multi-tenant architecture** with complete data isolation
- **Clean Architecture** implementation
- **AI integration** using Semantic Kernel
- **Comprehensive testing** at all levels
- **Security best practices** throughout
- **Production deployment** configuration

## 🏆 Key Achievements

1. **Architecture Excellence**
   - Clean separation of concerns
   - Domain-driven design
   - CQRS implementation
   - Dependency injection

2. **Enterprise Features**
   - Multi-tenancy with data isolation
   - AI-powered capabilities
   - Caching strategies
   - Performance optimization

3. **Quality Assurance**
   - 80%+ test coverage
   - Architecture validation
   - Performance benchmarks
   - Security verification

4. **Production Readiness**
   - Container deployment
   - Kubernetes orchestration
   - Health checks and monitoring
   - Secure configuration

## 📊 Performance Metrics

Your implementation should achieve:
- ✅ <100ms API response time (p95)
- ✅ 1000+ requests per second
- ✅ <0.1% error rate
- ✅ 99.9% availability
- ✅ A+ security score

## 🎉 Completion

You've completed Exercise 1! This enterprise API platform serves as a template for building real-world SaaS applications that can scale to millions of users.

## ⏭️ Next Steps

1. Review the complete solution in the `solution/` folder
2. Try the bonus challenges:
   - Add GraphQL endpoint
   - Implement event sourcing
   - Add real-time notifications with SignalR
3. Move on to [Exercise 2: Event-Driven Microservices](../exercise2-event-driven/)

---

**🌟 Outstanding Work!** You've mastered enterprise API development with .NET 8, implementing patterns used by industry leaders. This foundation will serve you well in building world-class software systems!