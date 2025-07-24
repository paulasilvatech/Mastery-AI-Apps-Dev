---
id: coverage-guide
title: Code Coverage Guide
sidebar_label: Coverage Guide
---

# Code Coverage Guide

This guide provides comprehensive information about code coverage, including metrics, tools, strategies, and best practices for achieving meaningful test coverage in your projects.

## Overview

Code coverage is a metric that measures the percentage of code executed during automated tests. While high coverage doesn't guarantee bug-free code, it helps identify untested areas and improves confidence in code quality.

## Types of Code Coverage

### Statement Coverage

Measures the percentage of executable statements that have been executed.

```javascript
function calculateDiscount(price, customerType) {
  let discount = 0;
  
  if (customerType === 'premium') {    // Statement 1
    discount = 0.2;                     // Statement 2
  } else if (customerType === 'regular') { // Statement 3
    discount = 0.1;                     // Statement 4
  }
  
  return price * (1 - discount);        // Statement 5
}

// Test achieving 100% statement coverage
describe('calculateDiscount', () => {
  it('should apply premium discount', () => {
    expect(calculateDiscount(100, 'premium')).toBe(80);
  });
  
  it('should apply regular discount', () => {
    expect(calculateDiscount(100, 'regular')).toBe(90);
  });
  
  it('should apply no discount for unknown type', () => {
    expect(calculateDiscount(100, 'guest')).toBe(100);
  });
});
```

### Branch Coverage

Measures whether each branch (true/false) of control structures has been executed.

```javascript
function validateAge(age) {
  // Branch 1: age check
  if (age < 0) {
    return 'Invalid age';
  }
  
  // Branch 2: adult check
  if (age >= 18) {
    return 'Adult';
  }
  
  return 'Minor';
}

// Tests for 100% branch coverage
describe('validateAge', () => {
  it('should handle negative age', () => {
    expect(validateAge(-1)).toBe('Invalid age'); // Branch 1: true
  });
  
  it('should identify adult', () => {
    expect(validateAge(25)).toBe('Adult'); // Branch 1: false, Branch 2: true
  });
  
  it('should identify minor', () => {
    expect(validateAge(15)).toBe('Minor'); // Branch 1: false, Branch 2: false
  });
});
```

### Function Coverage

Measures the percentage of functions that have been called.

```javascript
class UserService {
  createUser(data) {
    // Function 1
    return this.validateData(data) && this.saveToDatabase(data);
  }
  
  validateData(data) {
    // Function 2
    return data.name && data.email;
  }
  
  saveToDatabase(data) {
    // Function 3
    // Database logic
    return true;
  }
  
  deleteUser(id) {
    // Function 4 - not covered in tests below
    // Delete logic
  }
}

// Tests achieving 75% function coverage (3/4 functions)
describe('UserService', () => {
  it('should create user', () => {
    const service = new UserService();
    const result = service.createUser({ name: 'John', email: 'john@example.com' });
    expect(result).toBe(true);
  });
});
```

### Line Coverage

Similar to statement coverage but counts physical lines of code.

```javascript
function processOrder(order) {
  const items = order.items;           // Line 1
  let total = 0;                       // Line 2
  
  for (const item of items) {          // Line 3
    total += item.price * item.quantity; // Line 4
  }
  
  if (order.coupon) {                  // Line 5
    total *= (1 - order.coupon.discount); // Line 6
  }
  
  return total;                        // Line 7
}
```

## Coverage Tools Configuration

### Jest Coverage Configuration

```javascript
// jest.config.js
module.exports = {
  collectCoverage: true,
  collectCoverageFrom: [
    'src/**/*.{js,jsx}',
    '!src/index.js',
    '!src/serviceWorker.js',
    '!src/**/*.test.{js,jsx}',
    '!src/**/*.spec.{js,jsx}',
    '!src/test/**/*'
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    },
    './src/components/': {
      branches: 90,
      functions: 90,
      lines: 90,
      statements: 90
    }
  },
  coverageReporters: [
    'text',
    'text-summary',
    'html',
    'lcov',
    'json'
  ],
  coverageDirectory: 'coverage',
  coveragePathIgnorePatterns: [
    '/node_modules/',
    '/build/',
    '/dist/'
  ]
};

// package.json scripts
{
  "scripts": {
    "test": "jest",
    "test:coverage": "jest --coverage",
    "test:coverage:watch": "jest --coverage --watch",
    "test:coverage:report": "jest --coverage && open coverage/index.html"
  }
}
```

### NYC (Istanbul) Configuration

```javascript
// .nycrc.json
{
  "all": true,
  "include": [
    "src/**/*.js"
  ],
  "exclude": [
    "**/*.test.js",
    "**/*.spec.js",
    "test/**/*",
    "coverage/**/*",
    "node_modules/**/*"
  ],
  "reporter": [
    "text",
    "text-summary",
    "html",
    "lcov"
  ],
  "check-coverage": true,
  "branches": 80,
  "lines": 80,
  "functions": 80,
  "statements": 80,
  "watermarks": {
    "lines": [80, 95],
    "functions": [80, 95],
    "branches": [80, 95],
    "statements": [80, 95]
  }
}
```

### Vitest Coverage Configuration

```javascript
// vite.config.js
import { defineConfig } from 'vite';

export default defineConfig({
  test: {
    coverage: {
      enabled: true,
      provider: 'v8', // or 'istanbul'
      reporter: ['text', 'json', 'html'],
      include: ['src/**/*.{js,ts,jsx,tsx}'],
      exclude: [
        'node_modules/',
        'src/**/*.test.{js,ts,jsx,tsx}',
        'src/**/*.spec.{js,ts,jsx,tsx}'
      ],
      lines: 80,
      functions: 80,
      branches: 80,
      statements: 80
    }
  }
});
```

## Strategies for Improving Coverage

### Identifying Uncovered Code

```javascript
// Example: Complex function with multiple paths
function processPayment(payment) {
  // Check payment method
  if (payment.method === 'credit_card') {
    if (!payment.cardNumber || !payment.cvv) {
      throw new Error('Invalid credit card data');
    }
    
    if (payment.amount > 10000) {
      // Requires additional verification
      return { status: 'pending_verification', amount: payment.amount };
    }
    
    return { status: 'processed', amount: payment.amount };
  } else if (payment.method === 'paypal') {
    if (!payment.email) {
      throw new Error('PayPal email required');
    }
    
    return { status: 'processed', amount: payment.amount };
  } else if (payment.method === 'bitcoin') {
    if (!payment.walletAddress) {
      throw new Error('Bitcoin wallet required');
    }
    
    return { status: 'pending_blockchain', amount: payment.amount };
  }
  
  throw new Error('Unsupported payment method');
}

// Comprehensive tests for full coverage
describe('processPayment', () => {
  describe('credit card payments', () => {
    it('should process valid credit card payment', () => {
      const payment = {
        method: 'credit_card',
        cardNumber: '1234567890123456',
        cvv: '123',
        amount: 100
      };
      
      expect(processPayment(payment)).toEqual({
        status: 'processed',
        amount: 100
      });
    });
    
    it('should require verification for large amounts', () => {
      const payment = {
        method: 'credit_card',
        cardNumber: '1234567890123456',
        cvv: '123',
        amount: 15000
      };
      
      expect(processPayment(payment)).toEqual({
        status: 'pending_verification',
        amount: 15000
      });
    });
    
    it('should throw error for missing card data', () => {
      const payment = {
        method: 'credit_card',
        amount: 100
      };
      
      expect(() => processPayment(payment)).toThrow('Invalid credit card data');
    });
  });
  
  describe('paypal payments', () => {
    it('should process valid paypal payment', () => {
      const payment = {
        method: 'paypal',
        email: 'user@example.com',
        amount: 50
      };
      
      expect(processPayment(payment)).toEqual({
        status: 'processed',
        amount: 50
      });
    });
    
    it('should throw error for missing email', () => {
      const payment = {
        method: 'paypal',
        amount: 50
      };
      
      expect(() => processPayment(payment)).toThrow('PayPal email required');
    });
  });
  
  describe('bitcoin payments', () => {
    it('should process bitcoin payment', () => {
      const payment = {
        method: 'bitcoin',
        walletAddress: '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
        amount: 200
      };
      
      expect(processPayment(payment)).toEqual({
        status: 'pending_blockchain',
        amount: 200
      });
    });
    
    it('should throw error for missing wallet', () => {
      const payment = {
        method: 'bitcoin',
        amount: 200
      };
      
      expect(() => processPayment(payment)).toThrow('Bitcoin wallet required');
    });
  });
  
  it('should throw error for unsupported method', () => {
    const payment = {
      method: 'cash',
      amount: 100
    };
    
    expect(() => processPayment(payment)).toThrow('Unsupported payment method');
  });
});
```

### Testing Edge Cases

```javascript
// Function with edge cases
function calculateStatistics(numbers) {
  if (!Array.isArray(numbers)) {
    throw new TypeError('Input must be an array');
  }
  
  if (numbers.length === 0) {
    return {
      mean: 0,
      median: 0,
      mode: null,
      range: 0
    };
  }
  
  // Calculate mean
  const sum = numbers.reduce((acc, num) => acc + num, 0);
  const mean = sum / numbers.length;
  
  // Calculate median
  const sorted = [...numbers].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  const median = sorted.length % 2 === 0
    ? (sorted[mid - 1] + sorted[mid]) / 2
    : sorted[mid];
  
  // Calculate mode
  const frequency = {};
  let maxFreq = 0;
  let mode = null;
  
  for (const num of numbers) {
    frequency[num] = (frequency[num] || 0) + 1;
    if (frequency[num] > maxFreq) {
      maxFreq = frequency[num];
      mode = num;
    }
  }
  
  // Calculate range
  const range = Math.max(...numbers) - Math.min(...numbers);
  
  return { mean, median, mode, range };
}

// Comprehensive edge case tests
describe('calculateStatistics edge cases', () => {
  it('should handle empty array', () => {
    expect(calculateStatistics([])).toEqual({
      mean: 0,
      median: 0,
      mode: null,
      range: 0
    });
  });
  
  it('should handle single element', () => {
    expect(calculateStatistics([5])).toEqual({
      mean: 5,
      median: 5,
      mode: 5,
      range: 0
    });
  });
  
  it('should handle negative numbers', () => {
    const result = calculateStatistics([-5, -2, -8, -1]);
    expect(result.mean).toBe(-4);
    expect(result.median).toBe(-3.5);
  });
  
  it('should handle decimal numbers', () => {
    const result = calculateStatistics([1.5, 2.7, 3.2]);
    expect(result.mean).toBeCloseTo(2.467, 3);
  });
  
  it('should handle duplicates for mode', () => {
    const result = calculateStatistics([1, 2, 2, 3, 3, 3, 4]);
    expect(result.mode).toBe(3);
  });
  
  it('should throw error for non-array input', () => {
    expect(() => calculateStatistics('not an array')).toThrow(TypeError);
    expect(() => calculateStatistics(123)).toThrow(TypeError);
    expect(() => calculateStatistics(null)).toThrow(TypeError);
  });
});
```

### Testing Error Paths

```javascript
// Service with multiple error scenarios
class DataService {
  constructor(api, cache, logger) {
    this.api = api;
    this.cache = cache;
    this.logger = logger;
  }
  
  async getData(id) {
    try {
      // Try cache first
      const cached = await this.cache.get(id);
      if (cached) {
        this.logger.log(`Cache hit for ${id}`);
        return cached;
      }
    } catch (cacheError) {
      this.logger.warn(`Cache error for ${id}:`, cacheError);
      // Continue to API call
    }
    
    try {
      // API call
      const data = await this.api.fetch(id);
      
      if (!data) {
        throw new Error(`No data found for ID: ${id}`);
      }
      
      // Try to cache
      try {
        await this.cache.set(id, data);
      } catch (cacheError) {
        this.logger.error('Failed to cache data:', cacheError);
        // Don't fail the request due to cache error
      }
      
      return data;
    } catch (apiError) {
      this.logger.error(`API error for ${id}:`, apiError);
      
      // Try fallback
      if (this.api.fallback) {
        try {
          return await this.api.fallback.fetch(id);
        } catch (fallbackError) {
          this.logger.error('Fallback also failed:', fallbackError);
        }
      }
      
      throw new Error(`Failed to retrieve data for ID: ${id}`);
    }
  }
}

// Tests covering all error paths
describe('DataService error handling', () => {
  let mockApi, mockCache, mockLogger, service;
  
  beforeEach(() => {
    mockApi = {
      fetch: jest.fn(),
      fallback: { fetch: jest.fn() }
    };
    mockCache = {
      get: jest.fn(),
      set: jest.fn()
    };
    mockLogger = {
      log: jest.fn(),
      warn: jest.fn(),
      error: jest.fn()
    };
    service = new DataService(mockApi, mockCache, mockLogger);
  });
  
  it('should handle cache error and continue to API', async () => {
    mockCache.get.mockRejectedValue(new Error('Cache unavailable'));
    mockApi.fetch.mockResolvedValue({ data: 'test' });
    
    const result = await service.getData('123');
    
    expect(result).toEqual({ data: 'test' });
    expect(mockLogger.warn).toHaveBeenCalledWith(
      'Cache error for 123:',
      expect.any(Error)
    );
  });
  
  it('should handle API error and use fallback', async () => {
    mockCache.get.mockResolvedValue(null);
    mockApi.fetch.mockRejectedValue(new Error('API down'));
    mockApi.fallback.fetch.mockResolvedValue({ data: 'fallback' });
    
    const result = await service.getData('123');
    
    expect(result).toEqual({ data: 'fallback' });
    expect(mockLogger.error).toHaveBeenCalledWith(
      'API error for 123:',
      expect.any(Error)
    );
  });
  
  it('should handle cache set error without failing request', async () => {
    mockCache.get.mockResolvedValue(null);
    mockApi.fetch.mockResolvedValue({ data: 'test' });
    mockCache.set.mockRejectedValue(new Error('Cache write failed'));
    
    const result = await service.getData('123');
    
    expect(result).toEqual({ data: 'test' });
    expect(mockLogger.error).toHaveBeenCalledWith(
      'Failed to cache data:',
      expect.any(Error)
    );
  });
  
  it('should throw when all methods fail', async () => {
    mockCache.get.mockResolvedValue(null);
    mockApi.fetch.mockRejectedValue(new Error('API down'));
    mockApi.fallback.fetch.mockRejectedValue(new Error('Fallback down'));
    
    await expect(service.getData('123')).rejects.toThrow(
      'Failed to retrieve data for ID: 123'
    );
    
    expect(mockLogger.error).toHaveBeenCalledWith(
      'Fallback also failed:',
      expect.any(Error)
    );
  });
});
```

## Coverage Reports and Analysis

### Understanding Coverage Reports

```javascript
// Sample coverage report output
/*
----------------------|---------|----------|---------|---------|-------------------
File                  | % Stmts | % Branch | % Funcs | % Lines | Uncovered Line #s
----------------------|---------|----------|---------|---------|-------------------
All files             |   85.71 |    83.33 |   88.89 |   85.19 |
 src                  |     100 |      100 |     100 |     100 |
  index.js            |     100 |      100 |     100 |     100 |
 src/components       |   83.33 |       75 |   85.71 |   82.76 |
  Button.js           |     100 |      100 |     100 |     100 |
  Form.js             |      75 |       50 |      80 |   73.68 | 23-25,45
  Modal.js            |   86.67 |    83.33 |   85.71 |   86.67 | 67,89
 src/services         |   84.62 |    83.33 |   87.50 |   84.62 |
  api.js              |   90.91 |      100 |     100 |   90.91 | 34
  auth.js             |      80 |       75 |      75 |      80 | 12-15,28
 src/utils            |   88.89 |    85.71 |     100 |   88.89 |
  helpers.js          |   88.89 |    85.71 |     100 |   88.89 | 56
----------------------|---------|----------|---------|---------|-------------------
*/

// Analyzing uncovered lines
// Form.js - Lines 23-25 (error handling)
try {
  const response = await submitForm(data);
  return response;
} catch (error) {
  // Lines 23-25 - Not covered
  console.error('Form submission failed:', error);
  setError(error.message);
  return null;
}

// Test to cover these lines
it('should handle form submission error', async () => {
  const mockSubmit = jest.fn().mockRejectedValue(new Error('Network error'));
  const { result } = renderHook(() => useForm({ onSubmit: mockSubmit }));
  
  await act(async () => {
    await result.current.handleSubmit({ name: 'test' });
  });
  
  expect(result.current.error).toBe('Network error');
});
```

### HTML Coverage Reports

```html
<!-- Example HTML coverage report structure -->
<!DOCTYPE html>
<html>
<head>
  <title>Code Coverage Report</title>
  <style>
    .coverage-summary { margin: 20px; }
    .high { background: #4CAF50; }
    .medium { background: #FFC107; }
    .low { background: #F44336; }
    .line-covered { background: #E8F5E9; }
    .line-uncovered { background: #FFEBEE; }
  </style>
</head>
<body>
  <div class="coverage-summary">
    <h1>Code Coverage Summary</h1>
    <table>
      <tr>
        <th>File</th>
        <th>Statements</th>
        <th>Branches</th>
        <th>Functions</th>
        <th>Lines</th>
      </tr>
      <tr>
        <td>components/Button.js</td>
        <td class="high">100%</td>
        <td class="high">100%</td>
        <td class="high">100%</td>
        <td class="high">100%</td>
      </tr>
      <tr>
        <td>services/api.js</td>
        <td class="medium">85%</td>
        <td class="medium">80%</td>
        <td class="high">90%</td>
        <td class="medium">85%</td>
      </tr>
    </table>
  </div>
</body>
</html>
```

### Coverage Badges

```javascript
// Generate coverage badges for README
// package.json
{
  "scripts": {
    "coverage:badge": "jest --coverage && jest-coverage-badges"
  }
}

// .github/workflows/coverage.yml
name: Coverage
on: [push, pull_request]

jobs:
  coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
      - run: npm ci
      - run: npm run test:coverage
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v2
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          
      - name: Generate coverage badges
        run: npm run coverage:badge
        
      - name: Commit badges
        uses: EndBug/add-and-commit@v7
        with:
          add: 'coverage/badges/*'
          message: 'Update coverage badges'
```

## Coverage Best Practices

### Meaningful Coverage Goals

```javascript
// Setting realistic coverage thresholds
module.exports = {
  coverageThreshold: {
    global: {
      // Aim for high but achievable goals
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    },
    // Higher standards for critical paths
    './src/auth/': {
      branches: 95,
      functions: 95,
      lines: 95,
      statements: 95
    },
    // Lower thresholds for UI components
    './src/components/': {
      branches: 70,
      functions: 70,
      lines: 70,
      statements: 70
    },
    // Exclude hard-to-test code
    './src/legacy/': {
      branches: 50,
      functions: 50,
      lines: 50,
      statements: 50
    }
  }
};
```

### Coverage-Driven Development

```javascript
// Write tests that drive meaningful coverage
describe('UserAuthentication', () => {
  // Don't just aim for coverage numbers
  it('should authenticate valid user', () => {
    // ❌ Bad: Testing for coverage
    const auth = new Auth();
    auth.login('user', 'pass');
    expect(auth.isAuthenticated).toBe(true);
  });
  
  // ✅ Good: Testing behavior thoroughly
  describe('login', () => {
    it('should authenticate with valid credentials', async () => {
      const auth = new Auth();
      const result = await auth.login('valid@email.com', 'correctPassword');
      
      expect(result).toEqual({
        success: true,
        user: expect.objectContaining({
          email: 'valid@email.com',
          token: expect.any(String)
        })
      });
      expect(auth.isAuthenticated()).toBe(true);
    });
    
    it('should reject invalid email format', async () => {
      const auth = new Auth();
      
      await expect(auth.login('invalid-email', 'password'))
        .rejects.toThrow('Invalid email format');
      expect(auth.isAuthenticated()).toBe(false);
    });
    
    it('should lock account after failed attempts', async () => {
      const auth = new Auth();
      const email = 'user@example.com';
      
      // Make multiple failed attempts
      for (let i = 0; i < 5; i++) {
        await expect(auth.login(email, 'wrongPassword'))
          .rejects.toThrow();
      }
      
      // Account should be locked
      await expect(auth.login(email, 'correctPassword'))
        .rejects.toThrow('Account locked due to multiple failed attempts');
    });
  });
});
```

### Excluding Code from Coverage

```javascript
// Legitimate reasons to exclude code from coverage

// 1. Development/Debug code
/* istanbul ignore next */
if (process.env.NODE_ENV === 'development') {
  console.log('Debug info:', data);
}

// 2. Platform-specific code that can't be tested in all environments
/* istanbul ignore else */
if (typeof window !== 'undefined') {
  window.debugData = data;
}

// 3. Defensive programming that shouldn't happen
function processData(data) {
  /* istanbul ignore if */
  if (!data) {
    // This should never happen due to validation upstream
    throw new Error('Data is required');
  }
  
  return transformData(data);
}

// 4. Third-party integration points
class PaymentGateway {
  async processPayment(payment) {
    try {
      return await this.gateway.process(payment);
    } catch (error) {
      /* istanbul ignore next */
      // Can't reliably test third-party failures
      this.logger.error('Payment gateway error:', error);
      throw new Error('Payment processing failed');
    }
  }
}
```

## Integration with CI/CD

### GitHub Actions Coverage Workflow

```yaml
name: Test Coverage

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  coverage:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run tests with coverage
      run: npm run test:coverage
    
    - name: Check coverage thresholds
      run: npm run coverage:check
    
    - name: Upload coverage reports
      uses: actions/upload-artifact@v3
      with:
        name: coverage-report
        path: coverage/
    
    - name: Comment PR with coverage
      if: github.event_name == 'pull_request'
      uses: romeovs/lcov-reporter-action@v0.3.1
      with:
        github-token: ${{ secrets.GITHUB_TOKEN }}
        lcov-file: ./coverage/lcov.info
    
    - name: Upload to Codecov
      uses: codecov/codecov-action@v3
      with:
        token: ${{ secrets.CODECOV_TOKEN }}
        file: ./coverage/lcov.info
        flags: unittests
        name: codecov-umbrella
```

### Coverage Enforcement

```javascript
// Pre-commit hook for coverage
// .husky/pre-commit
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

# Run tests with coverage for changed files
CHANGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(js|jsx|ts|tsx)$')

if [ -n "$CHANGED_FILES" ]; then
  echo "Running coverage check for changed files..."
  npm run test:coverage -- --findRelatedTests $CHANGED_FILES
  
  if [ $? -ne 0 ]; then
    echo "Coverage check failed. Please ensure adequate test coverage."
    exit 1
  fi
fi

// Pre-push hook for full coverage
// .husky/pre-push
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

echo "Running full test coverage check..."
npm run test:coverage

if [ $? -ne 0 ]; then
  echo "Coverage thresholds not met. Push aborted."
  echo "Run 'npm run test:coverage' to see detailed report."
  exit 1
fi
```

## Common Coverage Pitfalls

### Coverage vs Quality

```javascript
// ❌ Bad: High coverage but poor quality tests
describe('Calculator', () => {
  it('should work', () => {
    const calc = new Calculator();
    calc.add(2, 2);
    calc.subtract(5, 3);
    calc.multiply(4, 3);
    calc.divide(10, 2);
    // No assertions - just executing code for coverage!
  });
});

// ✅ Good: Meaningful tests with assertions
describe('Calculator', () => {
  describe('add', () => {
    it('should add positive numbers', () => {
      expect(calculator.add(2, 3)).toBe(5);
    });
    
    it('should add negative numbers', () => {
      expect(calculator.add(-2, -3)).toBe(-5);
    });
    
    it('should handle zero', () => {
      expect(calculator.add(5, 0)).toBe(5);
      expect(calculator.add(0, 0)).toBe(0);
    });
  });
});
```

### Over-Testing

```javascript
// ❌ Bad: Testing implementation details
class UserService {
  constructor() {
    this._cache = new Map(); // Private implementation detail
  }
  
  getUser(id) {
    if (this._cache.has(id)) {
      return this._cache.get(id);
    }
    // ... fetch user
  }
}

// Don't test private implementation
it('should use cache', () => {
  const service = new UserService();
  service.getUser(1);
  expect(service._cache.has(1)).toBe(true); // Testing internals!
});

// ✅ Good: Test behavior, not implementation
it('should return same user instance on repeated calls', () => {
  const service = new UserService();
  const user1 = service.getUser(1);
  const user2 = service.getUser(1);
  
  expect(user1).toBe(user2); // Same reference = cached
});
```

## Conclusion

Code coverage is a valuable metric when used correctly. Focus on:

1. **Quality over Quantity**: 80% coverage with meaningful tests is better than 100% with superficial tests
2. **Critical Path Coverage**: Ensure high coverage for business-critical code
3. **Continuous Improvement**: Use coverage reports to identify gaps and improve incrementally
4. **Team Standards**: Establish and maintain team-wide coverage goals
5. **Automation**: Integrate coverage into your CI/CD pipeline

Remember that coverage is a tool to help identify untested code, not a goal in itself. The ultimate objective is to have confidence in your code's correctness and reliability.