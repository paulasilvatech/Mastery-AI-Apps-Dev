---
id: test-patterns
title: Test Patterns and Best Practices
sidebar_label: Test Patterns
---

# Test Patterns and Mejores Prácticas

This guide covers essential test patterns and best practices for writing effective tests with GitHub Copilot and AI-assisted desarrollo.

## Resumen

Effective testing is crucial for maintaining code quality and reliability. This guide presents proven patterns and strategies for writing comprehensive tests.

## Unit Testing Patterns

### Arrange-Act-Assert (AAA) Pattern

The AAA pattern provides a clear structure for unit tests:

```javascript
describe('Calculator', () => {
  it('should add two numbers correctly', () => {
    // Arrange
    const calculator = new Calculator();
    const a = 5;
    const b = 3;
    
    // Act
    const result = calculator.add(a, b);
    
    // Assert
    expect(result).toBe(8);
  });
});
```

### Given-When-Then Pattern

Similar to AAA but more behavior-focused:

```javascript
describe('User Authentication', () => {
  it('should authenticate valid user', () => {
    // Given a user with valid credentials
    const user = { username: 'testuser', password: 'validpass' };
    
    // When the user attempts to login
    const result = authService.login(user);
    
    // Then the authentication should succeed
    expect(result.success).toBe(true);
    expect(result.token).toBeDefined();
  });
});
```

## Test Data Patterns

### Builder Pattern for Test Data

Create flexible test data builders:

```javascript
class UserBuilder {
  constructor() {
    this.user = {
      id: 1,
      name: 'Default User',
      email: 'user@example.com',
      role: 'user'
    };
  }
  
  withName(name) {
    this.user.name = name;
    return this;
  }
  
  withEmail(email) {
    this.user.email = email;
    return this;
  }
  
  withRole(role) {
    this.user.role = role;
    return this;
  }
  
  build() {
    return this.user;
  }
}

// Usage in tests
const adminUser = new UserBuilder()
  .withRole('admin')
  .withEmail('admin@example.com')
  .build();
```

### Object Mother Pattern

Centralize test object creation:

```javascript
class TestDataMother {
  static createValidUser() {
    return {
      id: 1,
      name: 'John Doe',
      email: 'john@example.com',
      age: 30
    };
  }
  
  static createInvalidUser() {
    return {
      id: null,
      name: '',
      email: 'invalid-email',
      age: -1
    };
  }
  
  static createUserWithoutEmail() {
    const user = this.createValidUser();
    delete user.email;
    return user;
  }
}
```

## Mocking Patterns

### Dependency Injection for Testability

```javascript
// Service with injected dependencies
class UserService {
  constructor(database, emailService) {
    this.database = database;
    this.emailService = emailService;
  }
  
  async createUser(userData) {
    const user = await this.database.save(userData);
    await this.emailService.sendWelcomeEmail(user.email);
    return user;
  }
}

// Test with mocks
describe('UserService', () => {
  it('should create user and send email', async () => {
    // Create mocks
    const mockDatabase = {
      save: jest.fn().mockResolvedValue({ id: 1, ...userData })
    };
    const mockEmailService = {
      sendWelcomeEmail: jest.fn().mockResolvedValue(true)
    };
    
    // Inject mocks
    const userService = new UserService(mockDatabase, mockEmailService);
    
    // Test
    const result = await userService.createUser(userData);
    
    // Verify
    expect(mockDatabase.save).toHaveBeenCalledWith(userData);
    expect(mockEmailService.sendWelcomeEmail).toHaveBeenCalledWith(userData.email);
  });
});
```

### Stub Pattern for External Services

```javascript
// Stub external API calls
class WeatherAPIStub {
  constructor(responseData) {
    this.responseData = responseData;
  }
  
  async getWeather(city) {
    return this.responseData[city] || { 
      temperature: 20, 
      condition: 'sunny' 
    };
  }
}

// Use in tests
const weatherStub = new WeatherAPIStub({
  'London': { temperature: 15, condition: 'rainy' },
  'Paris': { temperature: 25, condition: 'sunny' }
});
```

## Integration Testing Patterns

### Test Containers Pattern

```javascript
describe('Database Integration Tests', () => {
  let container;
  let database;
  
  beforeAll(async () => {
    // Start test container
    container = await new PostgreSQLContainer()
      .withDatabase('testdb')
      .withUsername('testuser')
      .withPassword('testpass')
      .start();
    
    // Connect to test database
    database = new Database({
      host: container.getHost(),
      port: container.getPort(),
      database: 'testdb',
      user: 'testuser',
      password: 'testpass'
    });
  });
  
  afterAll(async () => {
    await database.close();
    await container.stop();
  });
  
  it('should perform database operations', async () => {
    // Test with real database
    const result = await database.query('SELECT 1');
    expect(result.rows[0]).toEqual({ '?column?': 1 });
  });
});
```

### API Testing Pattern

```javascript
describe('API Integration Tests', () => {
  let app;
  let server;
  
  beforeAll(async () => {
    app = createApp();
    server = app.listen(0); // Random port
  });
  
  afterAll(async () => {
    await server.close();
  });
  
  it('should handle GET request', async () => {
    const response = await request(app)
      .get('/api/users')
      .expect(200);
    
    expect(response.body).toHaveProperty('users');
    expect(Array.isArray(response.body.users)).toBe(true);
  });
  
  it('should handle POST request with validation', async () => {
    const newUser = { name: 'Test User', email: 'test@example.com' };
    
    const response = await request(app)
      .post('/api/users')
      .send(newUser)
      .expect(201);
    
    expect(response.body).toMatchObject({
      id: expect.any(Number),
      ...newUser
    });
  });
});
```

## Async Testing Patterns

### Promise Testing

```javascript
// Testing resolved promises
it('should resolve with user data', () => {
  const promise = userService.getUser(1);
  
  return expect(promise).resolves.toEqual({
    id: 1,
    name: 'John Doe'
  });
});

// Testing rejected promises
it('should reject when user not found', () => {
  const promise = userService.getUser(999);
  
  return expect(promise).rejects.toThrow('User not found');
});
```

### Async/Await Testing

```javascript
it('should handle async operations', async () => {
  // Setup
  const mockData = { id: 1, status: 'active' };
  apiService.fetchData = jest.fn().mockResolvedValue(mockData);
  
  // Execute
  const result = await dataProcessor.process();
  
  // Verify
  expect(result).toEqual(expect.objectContaining({
    processedAt: expect.any(Date),
    data: mockData
  }));
});
```

## Error Testing Patterns

### Exception Testing

```javascript
describe('Error Handling', () => {
  it('should throw error for invalid input', () => {
    expect(() => {
      calculator.divide(10, 0);
    }).toThrow('Division by zero');
  });
  
  it('should handle async errors', async () => {
    await expect(async () => {
      await service.performRiskyOperation();
    }).rejects.toThrow('Operation failed');
  });
});
```

### Error Boundary Testing

```javascript
it('should handle errors gracefully', async () => {
  // Simulate error
  const error = new Error('Network error');
  fetchService.getData = jest.fn().mockRejectedValue(error);
  
  // Execute with error handling
  const result = await dataService.getDataSafely();
  
  // Verify fallback behavior
  expect(result).toEqual({
    data: null,
    error: 'Failed to fetch data',
    fallback: true
  });
});
```

## Performance Testing Patterns

### Benchmark Pattern

```javascript
describe('Performance Tests', () => {
  it('should complete within time limit', async () => {
    const startTime = Date.now();
    
    // Execute operation
    await heavyComputation(largeDataSet);
    
    const duration = Date.now() - startTime;
    expect(duration).toBeLessThan(1000); // Less than 1 second
  });
  
  it('should handle concurrent requests', async () => {
    const requests = Array(100).fill(null).map((_, i) => 
      apiService.processRequest(i)
    );
    
    const start = Date.now();
    await Promise.all(requests);
    const duration = Date.now() - start;
    
    expect(duration).toBeLessThan(5000); // All requests within 5 seconds
  });
});
```

## Test Organization Patterns

### Nested Describe Blocks

```javascript
describe('UserService', () => {
  describe('Authentication', () => {
    describe('with valid credentials', () => {
      it('should return auth token', () => {
        // Test implementation
      });
      
      it('should set user session', () => {
        // Test implementation
      });
    });
    
    describe('with invalid credentials', () => {
      it('should throw authentication error', () => {
        // Test implementation
      });
      
      it('should not create session', () => {
        // Test implementation
      });
    });
  });
  
  describe('Authorization', () => {
    // Authorization tests
  });
});
```

### ComParteird Test Behaviors

```javascript
// Shared test behavior
function shouldBehaveLikeAuthenticatedEndpoint(endpoint) {
  it('should require authentication', async () => {
    const response = await request(app)
      .get(endpoint)
      .expect(401);
    
    expect(response.body).toEqual({
      error: 'Authentication required'
    });
  });
  
  it('should accept valid token', async () => {
    const token = generateValidToken();
    
    const response = await request(app)
      .get(endpoint)
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
  });
}

// Use shared behavior
describe('Protected Endpoints', () => {
  describe('/api/profile', () => {
    shouldBehaveLikeAuthenticatedEndpoint('/api/profile');
  });
  
  describe('/api/settings', () => {
    shouldBehaveLikeAuthenticatedEndpoint('/api/settings');
  });
});
```

## Mejores Prácticas Resumen

1. **Keep Tests Independent**: Each test should be able to run in isolation
2. **Use Descriptive Names**: Test names should clearly describe what is being tested
3. **Seguir DRY Principle**: Extract common setup and utilities
4. **Test One Thing**: Each test should verify a single behavior
5. **Use Appropriate Assertions**: Choose the most specific assertion for clarity
6. **Mock External Dependencies**: Isolate the unit under test
7. **Clean Up After Tests**: Ensure proper teardown of resources
8. **Maintain Test Data**: Keep test data relevant and minimal

## Common Anti-Patterns to Avoid

1. **Testing Implementation Details**: Enfóquese en behavior, not internals
2. **Excessive Mocking**: Don't mock everything, find the right balance
3. **Ignored or Skipped Tests**: Fix or remove, don't leave commented out
4. **Non-Deterministic Tests**: Avoid tests that sometimes pass/fail
5. **Overly Complex Tests**: If a test is hard to understand, simplify it
6. **Testing Framework Code**: Don't test third-party libraries
7. **Compartird Mutable State**: Avoid tests that depend on execution order

## Conclusión

These patterns provide a foundation for writing effective tests. Remember that the goal is to create tests that are:
- Reliable and deterministic
- Fácil to understand and maintain
- Fast to execute
- Valuable for catching bugs

Use these patterns as guidelines, adapting them to your specific needs and context.