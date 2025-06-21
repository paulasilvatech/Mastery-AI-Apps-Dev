# Exercise 1: Enterprise API Platform - Part 1: Initial Setup and Structure

## 🎯 Overview

In this first part, you'll set up the solution structure, configure the development environment, and implement the foundational multi-tenant architecture. This setup will serve as the base for all subsequent implementations.

## 📋 Part 1 Objectives

- Create a Clean Architecture solution structure
- Configure multi-tenant infrastructure
- Set up dependency injection and middleware pipeline
- Implement tenant resolution strategy
- Configure Entity Framework with tenant isolation

## 🏗️ Step 1: Create Solution Structure

### 1.1 Create the Solution

```bash
# Create solution directory
mkdir EnterpriseAPI
cd EnterpriseAPI

# Create solution file
dotnet new sln -n EnterpriseAPI

# Create project directories
mkdir -p src/{Core/Domain,Core/Application,Infrastructure,API}
mkdir -p tests/{UnitTests,IntegrationTests,ArchitectureTests}
```

### 1.2 Create Core Projects

```bash
# Domain project - Contains entities, value objects, and interfaces
cd src/Core/Domain
dotnet new classlib -n EnterpriseAPI.Domain
cd ../../..
dotnet sln add src/Core/Domain/EnterpriseAPI.Domain.csproj

# Application project - Contains business logic and use cases
cd src/Core/Application
dotnet new classlib -n EnterpriseAPI.Application
cd ../../..
dotnet sln add src/Core/Application/EnterpriseAPI.Application.csproj

# Add domain reference to application
cd src/Core/Application
dotnet add reference ../Domain/EnterpriseAPI.Domain.csproj
cd ../../..
```

### 1.3 Create Infrastructure Project

```bash
# Infrastructure project - External concerns implementation
cd src/Infrastructure
dotnet new classlib -n EnterpriseAPI.Infrastructure
cd ../..
dotnet sln add src/Infrastructure/EnterpriseAPI.Infrastructure.csproj

# Add references
cd src/Infrastructure
dotnet add reference ../Core/Application/EnterpriseAPI.Application.csproj
cd ../..
```

### 1.4 Create API Project

```bash
# Web API project
cd src/API
dotnet new webapi -n EnterpriseAPI.API --use-controllers
cd ../..
dotnet sln add src/API/EnterpriseAPI.API.csproj

# Add references
cd src/API
dotnet add reference ../Infrastructure/EnterpriseAPI.Infrastructure.csproj
cd ../..
```

## 🔧 Step 2: Configure Multi-Tenant Domain Model

### 2.1 Create Base Entities

Create `src/Core/Domain/Common/BaseEntity.cs`:

```csharp
namespace EnterpriseAPI.Domain.Common;

public abstract class BaseEntity
{
    public Guid Id { get; protected set; }
    public DateTime CreatedAt { get; protected set; }
    public DateTime? UpdatedAt { get; protected set; }
    public string CreatedBy { get; protected set; } = "system";
    public string? UpdatedBy { get; protected set; }
}

public abstract class TenantEntity : BaseEntity
{
    public Guid TenantId { get; protected set; }
}

public interface IAuditableEntity
{
    DateTime CreatedAt { get; }
    DateTime? UpdatedAt { get; }
    string CreatedBy { get; }
    string? UpdatedBy { get; }
}

public interface ITenantEntity
{
    Guid TenantId { get; }
}
```

### 2.2 Create Tenant Entity

Create `src/Core/Domain/Entities/Tenant.cs`:

```csharp
namespace EnterpriseAPI.Domain.Entities;

public class Tenant : BaseEntity
{
    private readonly List<TenantFeature> _features = new();
    private readonly List<TenantConfiguration> _configurations = new();

    public string Name { get; private set; } = null!;
    public string Identifier { get; private set; } = null!; // Subdomain or unique key
    public string? DisplayName { get; private set; }
    public TenantStatus Status { get; private set; }
    public TenantPlan Plan { get; private set; }
    public DateTime? SubscriptionEndDate { get; private set; }
    
    public IReadOnlyCollection<TenantFeature> Features => _features.AsReadOnly();
    public IReadOnlyCollection<TenantConfiguration> Configurations => _configurations.AsReadOnly();

    protected Tenant() { } // For EF

    public static Tenant Create(string name, string identifier, TenantPlan plan)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Tenant name is required", nameof(name));
            
        if (string.IsNullOrWhiteSpace(identifier))
            throw new ArgumentException("Tenant identifier is required", nameof(identifier));

        var tenant = new Tenant
        {
            Id = Guid.NewGuid(),
            Name = name,
            Identifier = identifier.ToLowerInvariant(),
            DisplayName = name,
            Status = TenantStatus.Active,
            Plan = plan,
            CreatedAt = DateTime.UtcNow
        };

        // Add default features based on plan
        tenant.AddDefaultFeatures();

        return tenant;
    }

    public void UpdatePlan(TenantPlan newPlan)
    {
        if (Plan == newPlan) return;
        
        Plan = newPlan;
        UpdatedAt = DateTime.UtcNow;
        
        // Update features based on new plan
        AddDefaultFeatures();
    }

    public void Activate()
    {
        if (Status == TenantStatus.Active) return;
        
        Status = TenantStatus.Active;
        UpdatedAt = DateTime.UtcNow;
    }

    public void Suspend(string reason)
    {
        Status = TenantStatus.Suspended;
        UpdatedAt = DateTime.UtcNow;
        
        _configurations.Add(new TenantConfiguration(
            "suspension_reason", 
            reason, 
            ConfigurationLevel.System));
    }

    private void AddDefaultFeatures()
    {
        _features.Clear();
        
        var planFeatures = Plan switch
        {
            TenantPlan.Free => new[] { "basic_api", "read_only_analytics" },
            TenantPlan.Standard => new[] { "basic_api", "full_analytics", "api_keys", "webhooks" },
            TenantPlan.Premium => new[] { "basic_api", "full_analytics", "api_keys", "webhooks", "ai_features", "custom_domain" },
            TenantPlan.Enterprise => new[] { "basic_api", "full_analytics", "api_keys", "webhooks", "ai_features", "custom_domain", "sso", "audit_logs" },
            _ => Array.Empty<string>()
        };

        foreach (var feature in planFeatures)
        {
            _features.Add(new TenantFeature(feature, true));
        }
    }
}

public enum TenantStatus
{
    Pending,
    Active,
    Suspended,
    Deleted
}

public enum TenantPlan
{
    Free,
    Standard,
    Premium,
    Enterprise
}

public class TenantFeature
{
    public string Name { get; private set; }
    public bool IsEnabled { get; private set; }
    public DateTime? ExpiresAt { get; private set; }

    public TenantFeature(string name, bool isEnabled, DateTime? expiresAt = null)
    {
        Name = name;
        IsEnabled = isEnabled;
        ExpiresAt = expiresAt;
    }
}

public class TenantConfiguration
{
    public string Key { get; private set; }
    public string Value { get; private set; }
    public ConfigurationLevel Level { get; private set; }

    public TenantConfiguration(string key, string value, ConfigurationLevel level = ConfigurationLevel.Tenant)
    {
        Key = key;
        Value = value;
        Level = level;
    }
}

public enum ConfigurationLevel
{
    System,
    Tenant,
    User
}
```

### 2.3 Create Core Business Entities

Create `src/Core/Domain/Entities/Product.cs`:

```csharp
namespace EnterpriseAPI.Domain.Entities;

public class Product : TenantEntity
{
    private readonly List<ProductFeature> _features = new();
    
    public string Name { get; private set; } = null!;
    public string? Description { get; private set; }
    public string SKU { get; private set; } = null!;
    public decimal Price { get; private set; }
    public string Currency { get; private set; } = "USD";
    public ProductStatus Status { get; private set; }
    public Guid CategoryId { get; private set; }
    public Category Category { get; private set; } = null!;
    
    public IReadOnlyCollection<ProductFeature> Features => _features.AsReadOnly();

    protected Product() { } // For EF

    public static Product Create(
        Guid tenantId,
        string name,
        string sku,
        decimal price,
        Guid categoryId)
    {
        if (tenantId == Guid.Empty)
            throw new ArgumentException("Tenant ID is required", nameof(tenantId));
            
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Product name is required", nameof(name));
            
        if (price < 0)
            throw new ArgumentException("Price cannot be negative", nameof(price));

        return new Product
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId,
            Name = name,
            SKU = sku.ToUpperInvariant(),
            Price = price,
            CategoryId = categoryId,
            Status = ProductStatus.Active,
            CreatedAt = DateTime.UtcNow
        };
    }

    public void UpdatePrice(decimal newPrice)
    {
        if (newPrice < 0)
            throw new ArgumentException("Price cannot be negative", nameof(newPrice));
            
        Price = newPrice;
        UpdatedAt = DateTime.UtcNow;
    }

    public void AddFeature(string name, string value)
    {
        if (_features.Any(f => f.Name.Equals(name, StringComparison.OrdinalIgnoreCase)))
            throw new InvalidOperationException($"Feature '{name}' already exists");
            
        _features.Add(new ProductFeature(name, value));
        UpdatedAt = DateTime.UtcNow;
    }

    public void Deactivate()
    {
        Status = ProductStatus.Inactive;
        UpdatedAt = DateTime.UtcNow;
    }
}

public enum ProductStatus
{
    Active,
    Inactive,
    Discontinued
}

public class ProductFeature
{
    public string Name { get; private set; }
    public string Value { get; private set; }

    public ProductFeature(string name, string value)
    {
        Name = name;
        Value = value;
    }
}
```

Create `src/Core/Domain/Entities/Category.cs`:

```csharp
namespace EnterpriseAPI.Domain.Entities;

public class Category : TenantEntity
{
    private readonly List<Product> _products = new();
    
    public string Name { get; private set; } = null!;
    public string? Description { get; private set; }
    public Guid? ParentCategoryId { get; private set; }
    public Category? ParentCategory { get; private set; }
    
    public IReadOnlyCollection<Product> Products => _products.AsReadOnly();

    protected Category() { } // For EF

    public static Category Create(Guid tenantId, string name, Guid? parentCategoryId = null)
    {
        if (tenantId == Guid.Empty)
            throw new ArgumentException("Tenant ID is required", nameof(tenantId));
            
        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Category name is required", nameof(name));

        return new Category
        {
            Id = Guid.NewGuid(),
            TenantId = tenantId,
            Name = name,
            ParentCategoryId = parentCategoryId,
            CreatedAt = DateTime.UtcNow
        };
    }
}
```

## 🔌 Step 3: Configure Dependency Injection

### 3.1 Create Tenant Context

Create `src/Core/Application/Common/Interfaces/ITenantContext.cs`:

```csharp
namespace EnterpriseAPI.Application.Common.Interfaces;

public interface ITenantContext
{
    Guid? TenantId { get; }
    string? TenantIdentifier { get; }
    TenantInfo? Tenant { get; }
    bool IsHost { get; } // For cross-tenant admin operations
}

public class TenantInfo
{
    public Guid Id { get; init; }
    public string Name { get; init; } = null!;
    public string Identifier { get; init; } = null!;
    public TenantPlan Plan { get; init; }
    public Dictionary<string, bool> Features { get; init; } = new();
}
```

### 3.2 Create Tenant Service Interface

Create `src/Core/Application/Common/Interfaces/ITenantService.cs`:

```csharp
namespace EnterpriseAPI.Application.Common.Interfaces;

public interface ITenantService
{
    Task<TenantInfo?> GetTenantAsync(string identifier, CancellationToken cancellationToken = default);
    Task<TenantInfo?> GetTenantAsync(Guid tenantId, CancellationToken cancellationToken = default);
    Task<bool> ValidateTenantAsync(Guid tenantId, CancellationToken cancellationToken = default);
}
```

### 3.3 Create Repository Interfaces

Create `src/Core/Application/Common/Interfaces/IRepository.cs`:

```csharp
namespace EnterpriseAPI.Application.Common.Interfaces;

public interface IRepository<T> where T : BaseEntity
{
    Task<T?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IEnumerable<T>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<T> AddAsync(T entity, CancellationToken cancellationToken = default);
    Task UpdateAsync(T entity, CancellationToken cancellationToken = default);
    Task DeleteAsync(T entity, CancellationToken cancellationToken = default);
}

public interface ITenantRepository<T> : IRepository<T> where T : TenantEntity
{
    Task<T?> GetByIdAsync(Guid tenantId, Guid id, CancellationToken cancellationToken = default);
    Task<IEnumerable<T>> GetAllAsync(Guid tenantId, CancellationToken cancellationToken = default);
}
```

## 🏗️ Step 4: Implement Infrastructure Layer

### 4.1 Install Required Packages

```bash
# Infrastructure project packages
cd src/Infrastructure

# Entity Framework
dotnet add package Microsoft.EntityFrameworkCore
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.EntityFrameworkCore.Tools

# Caching
dotnet add package Microsoft.Extensions.Caching.StackExchangeRedis

# AI/Semantic Kernel
dotnet add package Microsoft.SemanticKernel
dotnet add package Azure.AI.OpenAI

# Monitoring
dotnet add package OpenTelemetry.Instrumentation.EntityFrameworkCore

cd ../..
```

### 4.2 Create Database Context

Create `src/Infrastructure/Persistence/ApplicationDbContext.cs`:

```csharp
namespace EnterpriseAPI.Infrastructure.Persistence;

public class ApplicationDbContext : DbContext
{
    private readonly ITenantContext _tenantContext;
    private readonly ICurrentUserService _currentUserService;

    public ApplicationDbContext(
        DbContextOptions<ApplicationDbContext> options,
        ITenantContext tenantContext,
        ICurrentUserService currentUserService) : base(options)
    {
        _tenantContext = tenantContext;
        _currentUserService = currentUserService;
    }

    public DbSet<Tenant> Tenants => Set<Tenant>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<Category> Categories => Set<Category>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Apply configurations
        modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());

        // Global query filters for multi-tenancy
        modelBuilder.Entity<Product>().HasQueryFilter(e => e.TenantId == _tenantContext.TenantId);
        modelBuilder.Entity<Category>().HasQueryFilter(e => e.TenantId == _tenantContext.TenantId);

        // Add indexes for performance
        modelBuilder.Entity<Product>()
            .HasIndex(p => new { p.TenantId, p.SKU })
            .IsUnique();

        modelBuilder.Entity<Category>()
            .HasIndex(c => new { c.TenantId, c.Name });
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        // Audit fields
        foreach (var entry in ChangeTracker.Entries<BaseEntity>())
        {
            switch (entry.State)
            {
                case EntityState.Added:
                    entry.Entity.CreatedAt = DateTime.UtcNow;
                    entry.Entity.CreatedBy = _currentUserService.UserId ?? "system";
                    break;
                case EntityState.Modified:
                    entry.Entity.UpdatedAt = DateTime.UtcNow;
                    entry.Entity.UpdatedBy = _currentUserService.UserId ?? "system";
                    break;
            }
        }

        // Ensure tenant context for new entities
        foreach (var entry in ChangeTracker.Entries<TenantEntity>()
            .Where(e => e.State == EntityState.Added))
        {
            if (entry.Entity.TenantId == Guid.Empty && _tenantContext.TenantId.HasValue)
            {
                entry.Entity.TenantId = _tenantContext.TenantId.Value;
            }
        }

        return base.SaveChangesAsync(cancellationToken);
    }
}
```

### 4.3 Create Entity Configurations

Create `src/Infrastructure/Persistence/Configurations/TenantConfiguration.cs`:

```csharp
namespace EnterpriseAPI.Infrastructure.Persistence.Configurations;

public class TenantConfiguration : IEntityTypeConfiguration<Tenant>
{
    public void Configure(EntityTypeBuilder<Tenant> builder)
    {
        builder.ToTable("Tenants");

        builder.HasKey(t => t.Id);

        builder.Property(t => t.Name)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(t => t.Identifier)
            .IsRequired()
            .HasMaxLength(50);

        builder.HasIndex(t => t.Identifier)
            .IsUnique();

        builder.Property(t => t.DisplayName)
            .HasMaxLength(200);

        builder.Property(t => t.Status)
            .HasConversion<string>()
            .HasMaxLength(20);

        builder.Property(t => t.Plan)
            .HasConversion<string>()
            .HasMaxLength(20);

        // Complex types
        builder.OwnsMany(t => t.Features, features =>
        {
            features.ToTable("TenantFeatures");
            features.WithOwner().HasForeignKey("TenantId");
            features.HasKey("TenantId", "Name");
            
            features.Property(f => f.Name).HasMaxLength(100);
        });

        builder.OwnsMany(t => t.Configurations, configs =>
        {
            configs.ToTable("TenantConfigurations");
            configs.WithOwner().HasForeignKey("TenantId");
            configs.HasKey("TenantId", "Key");
            
            configs.Property(c => c.Key).HasMaxLength(100);
            configs.Property(c => c.Value).HasMaxLength(1000);
        });
    }
}
```

## 💡 Copilot Prompt Suggestions

Use these prompts to get help from GitHub Copilot:

**For Entity Creation:**
```
Create a Customer entity that extends TenantEntity with:
- Email (unique per tenant)
- Name fields (First, Last)
- Address as value object
- Orders collection
Include factory method and business logic
```

**For Repository Implementation:**
```
Implement a generic repository for TenantEntity with:
- Automatic tenant filtering
- Bulk operations support
- Specification pattern
- Async methods with cancellation
Include caching decorator pattern
```

**For Configuration:**
```
Create EF Core configuration for Order entity with:
- Composite key (TenantId, OrderNumber)
- Money value object conversion
- Owned entity for shipping address
- Shadow properties for audit
Configure for optimal query performance
```

## ✅ Part 1 Checklist

Before moving to Part 2, ensure you have:

- [ ] Created the solution structure with Clean Architecture
- [ ] Implemented multi-tenant domain model
- [ ] Created core business entities (Product, Category)
- [ ] Set up Entity Framework with tenant isolation
- [ ] Configured dependency injection interfaces
- [ ] Added global query filters for multi-tenancy
- [ ] Implemented audit fields automatically
- [ ] Created entity configurations

## 🎯 Part 1 Summary

You've successfully:
- Set up a professional enterprise solution structure
- Implemented multi-tenant architecture at the domain level
- Created a foundation for secure data isolation
- Prepared the infrastructure for AI integration

## ⏭️ Next Steps

Continue to [Part 2: Core Implementation](part2-implementation.md) where you'll:
- Implement the API controllers
- Add business logic with MediatR
- Integrate Semantic Kernel for AI features
- Configure authentication and authorization
- Set up caching and performance optimizations

---

**🏆 Achievement**: You've built the foundation of an enterprise-grade multi-tenant platform! This architecture can scale to support thousands of tenants with millions of users.