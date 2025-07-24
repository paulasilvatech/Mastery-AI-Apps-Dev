---
id: debugging-guide
title: Debugging Guide for AI-Assisted Development
sidebar_label: Debugging Guide
---

# Debugging Guía for AI-Assisted desarrollo

This comprehensive guide covers debugging techniques, tools, and strategies for effectively troubleshooting issues in AI-assisted desarrollo ambientes.

## Resumen

Debugging is an essential skill that becomes even more important when working with AI-generated code. This guide provides systematic approaches to identify, isolate, and fix bugs efficiently.

## Debugging Fundamentos

### The Debugging Process

1. **Reproduce the Issue**
   - Identify exact steps to reproduce
   - Document ambiente conditions
   - Note any error messages

2. **Isolate the Problem**
   - Narrow down the scope
   - Identify the failing component
   - Create minimal test case

3. **Analyze Root Cause**
   - Examine the code flow
   - Verificar assumptions
   - Revisar recent changes

4. **Fix and Verify**
   - Implement the solution
   - Test the fix thoroughly
   - Prevent regression

## Browser Debugging Techniques

### Using Chrome DevTools

#### Console Debugging

```javascript
// Basic console methods
console.log('Basic output');
console.error('Error message');
console.warn('Warning message');
console.info('Information');

// Advanced console techniques
console.group('User Details');
console.log('Name:', user.name);
console.log('Email:', user.email);
console.groupEnd();

// Console timing
console.time('Operation');
performExpensiveOperation();
console.timeEnd('Operation');

// Console table for arrays/objects
console.table([
  { name: 'John', age: 30 },
  { name: 'Jane', age: 25 }
]);

// Conditional logging
console.assert(user.age > 0, 'Age must be positive');

// Stack traces
console.trace('Execution path');
```

#### Breakpoint Debugging

```javascript
// Programmatic breakpoint
function processData(data) {
  // Debugger statement - execution pauses here
  debugger;
  
  const result = transformData(data);
  return result;
}

// Conditional breakpoints in code
function calculate(value) {
  if (value < 0) {
    debugger; // Only breaks for negative values
  }
  return value * 2;
}
```

#### Network Debugging

```javascript
// Debugging API calls
async function fetchData() {
  console.log('Starting API call...');
  
  try {
    const response = await fetch('/api/data');
    console.log('Response status:', response.status);
    console.log('Response headers:', response.headers);
    
    const data = await response.json();
    console.log('Received data:', data);
    
    return data;
  } catch (error) {
    console.error('API call failed:', error);
    console.error('Stack trace:', error.stack);
    throw error;
  }
}

// Request/Response interceptor for debugging
const debugFetch = async (url, options = {}) => {
  console.group(`Fetch: ${url}`);
  console.log('Request options:', options);
  
  const startTime = performance.now();
  
  try {
    const response = await fetch(url, options);
    const duration = performance.now() - startTime;
    
    console.log('Response time:', `${duration.toFixed(2)}ms`);
    console.log('Status:', response.status);
    
    return response;
  } catch (error) {
    console.error('Request failed:', error);
    throw error;
  } finally {
    console.groupEnd();
  }
};
```

### React Developer Tools

```javascript
// Debugging React components
import { useEffect, useDebugValue } from 'react';

// Custom hook with debug information
function useUserData(userId) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  
  // Show debug value in React DevTools
  useDebugValue(user ? `User: ${user.name}` : 'Loading...');
  
  useEffect(() => {
    console.log(`Fetching user data for ID: ${userId}`);
    
    fetchUser(userId)
      .then(data => {
        console.log('User data received:', data);
        setUser(data);
      })
      .catch(error => {
        console.error('Failed to fetch user:', error);
      })
      .finally(() => setLoading(false));
  }, [userId]);
  
  return { user, loading };
}

// Component with performance debugging
const UserProfile = React.memo(({ userId }) => {
  console.log(`UserProfile rendering for user: ${userId}`);
  
  const { user, loading } = useUserData(userId);
  
  // Log render reasons
  useEffect(() => {
    console.log('UserProfile mounted/updated', { userId, user });
  });
  
  if (loading) return <div>Loading...</div>;
  if (!user) return <div>User not found</div>;
  
  return <div>{user.name}</div>;
});

// Add display name for better debugging
UserProfile.displayName = 'UserProfile';
```

## Node.js Debugging

### Using the Node.js Debugger

```javascript
// Launch with inspector
// node --inspect index.js
// node --inspect-brk index.js (breaks on first line)

// Debugging with console
const util = require('util');

// Deep object inspection
const complexObject = { /* ... */ };
console.log(util.inspect(complexObject, {
  showHidden: true,
  depth: null,
  colors: true
}));

// Debug module for conditional logging
const debug = require('debug')('app:server');

debug('Server starting on port %d', port);
debug('Database connection: %O', dbConfig);

// Memory usage debugging
console.log('Memory Usage:', process.memoryUsage());

// Event loop debugging
setImmediate(() => {
  console.log('Event loop - Immediate');
});

process.nextTick(() => {
  console.log('Event loop - Next tick');
});
```

### Async/Await Debugging

```javascript
// Debugging promises and async code
async function complexAsyncOperation() {
  console.log('Starting async operation');
  
  try {
    // Add logging between async calls
    console.log('Step 1: Fetching user');
    const user = await fetchUser();
    console.log('User fetched:', user.id);
    
    console.log('Step 2: Fetching user posts');
    const posts = await fetchUserPosts(user.id);
    console.log(`Found ${posts.length} posts`);
    
    console.log('Step 3: Processing posts');
    const processed = await processPosts(posts);
    
    return processed;
  } catch (error) {
    console.error('Async operation failed at:', error.message);
    console.error('Stack:', error.stack);
    
    // Re-throw with additional context
    throw new Error(`Complex operation failed: ${error.message}`);
  }
}

// Promise debugging helper
function debugPromise(promise, label) {
  console.log(`${label}: Starting`);
  
  return promise
    .then(result => {
      console.log(`${label}: Success`, result);
      return result;
    })
    .catch(error => {
      console.error(`${label}: Failed`, error);
      throw error;
    });
}
```

## VS Code Debugging

### Launch Configuration

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Debug Node.js",
      "skipFiles": ["<node_internals>/**"],
      "program": "${workspaceFolder}/index.js",
      "envFile": "${workspaceFolder}/.env.debug",
      "console": "integratedTerminal",
      "outputCapture": "std"
    },
    {
      "type": "chrome",
      "request": "launch",
      "name": "Debug React App",
      "url": "http://localhost:3000",
      "webRoot": "${workspaceFolder}/src",
      "sourceMaps": true,
      "sourceMapPathOverrides": {
        "webpack:///src/*": "${webRoot}/*"
      }
    },
    {
      "type": "node",
      "request": "attach",
      "name": "Attach to Process",
      "processId": "${command:PickProcess}",
      "restart": true,
      "protocol": "inspector"
    }
  ]
}
```

### Debugging with Breakpoints

```javascript
// Conditional breakpoints example
function processItems(items) {
  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    
    // Set conditional breakpoint here: item.status === 'error'
    if (item.status === 'error') {
      handleError(item);
    } else {
      processItem(item);
    }
  }
}

// Logpoints for non-breaking debugging
function calculateTotal(items) {
  let total = 0;
  
  items.forEach(item => {
    // Logpoint: "Processing item {item.id} with value {item.value}"
    total += item.value;
  });
  
  return total;
}
```

## Common Debugging Patterns

### Error Boundary Pattern

```javascript
// React error boundary for debugging
class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null, errorInfo: null };
  }
  
  static getDerivedStateFromError(error) {
    return { hasError: true };
  }
  
  componentDidCatch(error, errorInfo) {
    console.error('Error caught by boundary:', error);
    console.error('Error info:', errorInfo);
    console.error('Component stack:', errorInfo.componentStack);
    
    // Log to error reporting service
    if (window.errorReporter) {
      window.errorReporter.log({
        error: error.toString(),
        errorInfo: errorInfo,
        timestamp: new Date().toISOString()
      });
    }
    
    this.setState({
      error,
      errorInfo
    });
  }
  
  render() {
    if (this.state.hasError) {
      return (
        <div className="error-boundary">
          <h2>Something went wrong</h2>
          {process.env.NODE_ENV === 'development' && (
            <details style={{ whiteSpace: 'pre-wrap' }}>
              <summary>Error details</summary>
              {this.state.error && this.state.error.toString()}
              <br />
              {this.state.errorInfo.componentStack}
            </details>
          )}
        </div>
      );
    }
    
    return this.props.children;
  }
}
```

### Debugging Ayudaers

```javascript
// Debug utility functions
const Debug = {
  // Type checking helper
  logType(label, value) {
    console.log(`${label}:`, {
      value,
      type: typeof value,
      constructor: value?.constructor?.name,
      isArray: Array.isArray(value),
      isNull: value === null,
      isUndefined: value === undefined
    });
  },
  
  // Function execution tracker
  trace(fn, fnName) {
    return function(...args) {
      console.group(`${fnName} called`);
      console.log('Arguments:', args);
      console.time('Execution time');
      
      try {
        const result = fn.apply(this, args);
        
        if (result instanceof Promise) {
          return result
            .then(value => {
              console.log('Resolved:', value);
              console.timeEnd('Execution time');
              console.groupEnd();
              return value;
            })
            .catch(error => {
              console.error('Rejected:', error);
              console.timeEnd('Execution time');
              console.groupEnd();
              throw error;
            });
        }
        
        console.log('Returned:', result);
        console.timeEnd('Execution time');
        console.groupEnd();
        return result;
      } catch (error) {
        console.error('Threw:', error);
        console.timeEnd('Execution time');
        console.groupEnd();
        throw error;
      }
    };
  },
  
  // State change tracker
  watchObject(obj, name) {
    const handler = {
      get(target, property) {
        console.log(`${name}.${property} accessed`);
        return target[property];
      },
      set(target, property, value) {
        console.log(`${name}.${property} changed from`, target[property], 'to', value);
        target[property] = value;
        return true;
      }
    };
    
    return new Proxy(obj, handler);
  }
};

// Usage examples
Debug.logType('User data', userData);

const tracedFunction = Debug.trace(originalFunction, 'originalFunction');

const watchedState = Debug.watchObject(state, 'appState');
```

## Memory Debugging

### Memory Leak Detection

```javascript
// Memory leak detection patterns
class MemoryLeakDetector {
  constructor() {
    this.snapshots = [];
  }
  
  takeSnapshot(label) {
    if (typeof process !== 'undefined' && process.memoryUsage) {
      const usage = process.memoryUsage();
      this.snapshots.push({
        label,
        timestamp: Date.now(),
        heapUsed: usage.heapUsed,
        heapTotal: usage.heapTotal,
        external: usage.external,
        rss: usage.rss
      });
      
      console.log(`Memory snapshot - ${label}:`, {
        heapUsed: `${(usage.heapUsed / 1024 / 1024).toFixed(2)} MB`,
        heapTotal: `${(usage.heapTotal / 1024 / 1024).toFixed(2)} MB`
      });
    }
  }
  
  compareSnapshots(label1, label2) {
    const snapshot1 = this.snapshots.find(s => s.label === label1);
    const snapshot2 = this.snapshots.find(s => s.label === label2);
    
    if (!snapshot1 || !snapshot2) {
      console.error('Snapshots not found');
      return;
    }
    
    const heapDiff = snapshot2.heapUsed - snapshot1.heapUsed;
    const timeDiff = snapshot2.timestamp - snapshot1.timestamp;
    
    console.log(`Memory comparison ${label1} -> ${label2}:`, {
      heapIncrease: `${(heapDiff / 1024 / 1024).toFixed(2)} MB`,
      timeElapsed: `${timeDiff}ms`,
      heapGrowthRate: `${(heapDiff / timeDiff).toFixed(2)} bytes/ms`
    });
  }
}

// Usage
const memDetector = new MemoryLeakDetector();
memDetector.takeSnapshot('before-operation');
performExpensiveOperation();
memDetector.takeSnapshot('after-operation');
memDetector.compareSnapshots('before-operation', 'after-operation');
```

## Performance Debugging

### Performance Profiling

```javascript
// Performance measurement utilities
class PerformanceProfiler {
  constructor() {
    this.measurements = new Map();
  }
  
  start(label) {
    this.measurements.set(label, {
      start: performance.now(),
      marks: []
    });
  }
  
  mark(label, markName) {
    const measurement = this.measurements.get(label);
    if (measurement) {
      measurement.marks.push({
        name: markName,
        time: performance.now() - measurement.start
      });
    }
  }
  
  end(label) {
    const measurement = this.measurements.get(label);
    if (measurement) {
      const duration = performance.now() - measurement.start;
      
      console.group(`Performance: ${label}`);
      console.log(`Total duration: ${duration.toFixed(2)}ms`);
      
      if (measurement.marks.length > 0) {
        console.log('Marks:');
        measurement.marks.forEach((mark, index) => {
          const prevTime = index > 0 ? measurement.marks[index - 1].time : 0;
          console.log(`  ${mark.name}: ${mark.time.toFixed(2)}ms (+${(mark.time - prevTime).toFixed(2)}ms)`);
        });
      }
      
      console.groupEnd();
      
      this.measurements.delete(label);
      return duration;
    }
  }
}

// Usage
const profiler = new PerformanceProfiler();

profiler.start('data-processing');
const data = fetchData();
profiler.mark('data-processing', 'data-fetched');

const processed = processData(data);
profiler.mark('data-processing', 'data-processed');

const saved = saveData(processed);
profiler.mark('data-processing', 'data-saved');

profiler.end('data-processing');
```

## Debugging Strategies

### Binary Buscar Debugging

```javascript
// Binary search for bug isolation
function binarySearchDebug(items, testFunction) {
  console.log(`Starting binary search debug with ${items.length} items`);
  
  function search(start, end) {
    if (start > end) return -1;
    
    const mid = Math.floor((start + end) / 2);
    console.log(`Testing range [${start}, ${end}], midpoint: ${mid}`);
    
    // Test if bug exists in first half
    const firstHalf = items.slice(0, mid + 1);
    if (testFunction(firstHalf)) {
      console.log('Bug found in first half');
      return search(start, mid - 1);
    }
    
    // Test second half
    const secondHalf = items.slice(mid + 1);
    if (testFunction(secondHalf)) {
      console.log('Bug found in second half');
      return search(mid + 1, end);
    }
    
    // Bug is at the boundary
    console.log(`Bug isolated to item at index ${mid}`);
    return mid;
  }
  
  return search(0, items.length - 1);
}
```

### Rubber Duck Debugging

```javascript
// Structured rubber duck debugging
class RubberDuckDebugger {
  constructor() {
    this.session = {
      problem: '',
      assumptions: [],
      steps: [],
      observations: [],
      hypothesis: ''
    };
  }
  
  describeProblem(problem) {
    this.session.problem = problem;
    console.log('🦆 Problem:', problem);
  }
  
  addAssumption(assumption) {
    this.session.assumptions.push(assumption);
    console.log('🦆 Assumption:', assumption);
  }
  
  explainStep(step) {
    this.session.steps.push(step);
    console.log(`🦆 Step ${this.session.steps.length}:`, step);
  }
  
  noteObservation(observation) {
    this.session.observations.push(observation);
    console.log('🦆 Observed:', observation);
  }
  
  formHypothesis(hypothesis) {
    this.session.hypothesis = hypothesis;
    console.log('🦆 Hypothesis:', hypothesis);
  }
  
  summarize() {
    console.group('🦆 Debugging Session Summary');
    console.log('Problem:', this.session.problem);
    console.log('Assumptions:', this.session.assumptions);
    console.log('Steps taken:', this.session.steps);
    console.log('Observations:', this.session.observations);
    console.log('Hypothesis:', this.session.hypothesis);
    console.groupEnd();
  }
}
```

## Debugging Tools Integration

### Custom Debug Panel

```javascript
// In-app debug panel
class DebugPanel {
  constructor() {
    this.logs = [];
    this.isVisible = false;
    this.createPanel();
  }
  
  createPanel() {
    const panel = document.createElement('div');
    panel.id = 'debug-panel';
    panel.innerHTML = `
      <div class="debug-header">
        <h3>Debug Panel</h3>
        <button onclick="debugPanel.toggle()">Toggle</button>
        <button onclick="debugPanel.clear()">Clear</button>
      </div>
      <div class="debug-content">
        <div id="debug-logs"></div>
      </div>
    `;
    
    // Add styles
    const style = document.createElement('style');
    style.textContent = `
      #debug-panel {
        position: fixed;
        bottom: 0;
        right: 0;
        width: 400px;
        height: 300px;
        background: #1e1e1e;
        color: #fff;
        border: 1px solid #444;
        font-family: monospace;
        font-size: 12px;
        z-index: 9999;
        display: none;
      }
      #debug-panel.visible { display: block; }
      .debug-header {
        padding: 10px;
        background: #2d2d2d;
        border-bottom: 1px solid #444;
      }
      .debug-content {
        padding: 10px;
        height: calc(100% - 50px);
        overflow-y: auto;
      }
      .debug-log {
        margin-bottom: 5px;
        padding: 5px;
        border-left: 3px solid #666;
      }
      .debug-log.error { border-color: #f44336; color: #ff6b6b; }
      .debug-log.warn { border-color: #ff9800; color: #ffa726; }
      .debug-log.info { border-color: #2196f3; color: #42a5f5; }
    `;
    
    document.head.appendChild(style);
    document.body.appendChild(panel);
  }
  
  log(message, type = 'info') {
    const timestamp = new Date().toLocaleTimeString();
    this.logs.push({ timestamp, message, type });
    this.updateDisplay();
  }
  
  updateDisplay() {
    const logsContainer = document.getElementById('debug-logs');
    if (logsContainer) {
      logsContainer.innerHTML = this.logs
        .map(log => `
          <div class="debug-log ${log.type}">
            <span>${log.timestamp}</span> - ${log.message}
          </div>
        `)
        .join('');
    }
  }
  
  toggle() {
    this.isVisible = !this.isVisible;
    const panel = document.getElementById('debug-panel');
    if (panel) {
      panel.classList.toggle('visible', this.isVisible);
    }
  }
  
  clear() {
    this.logs = [];
    this.updateDisplay();
  }
}

// Initialize debug panel
const debugPanel = new DebugPanel();

// Override console methods to capture logs
const originalLog = console.log;
console.log = function(...args) {
  originalLog.apply(console, args);
  debugPanel.log(args.join(' '), 'info');
};
```

## Mejores Prácticas

### Debugging Verificarlist

1. **Before Debugging**
   - Can you reproduce the issue consistently?
   - Have you checked the error messages carefully?
   - Is this a new issue or regression?
   - Have you checked recent changes?

2. **During Debugging**
   - Comience con the simplest explanation
   - Verify your assumptions
   - Isolate the problem systematically
   - Keep notes of what you've tried

3. **After Debugging**
   - Document the root cause
   - Add tests to prevent regression
   - Consider if similar bugs might exist elsewhere
   - Actualizar documentation if needed

### Common Pitfalls to Avoid

1. **Assumption-Based Debugging**: Always verify your assumptions
2. **Shotgun Debugging**: Making random changes hoping something works
3. **Ignoring Error Mensajes**: Read them carefully, they often contain the solution
4. **Not Using Versión Control**: Use git bisect to find when bugs were introduced
5. **Debugging in Production**: Always reproduce in desarrollo first
6. **Not Taking Breaks**: Fresh eyes often spot issues quickly

## Conclusión

Effective debugging is a combination of systematic thinking, proper tooling, and experience. The techniques and patterns in this guide provide a foundation for efficiently identifying and resolving issues in your code. Remember that debugging is a skill that improves with practice, and maintaining a methodical approach will help you solve even the most complex problems.