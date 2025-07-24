---
id: refactoring-guide
title: Refactoring Guide for AI-Assisted Development
sidebar_label: Refactoring Guide
---

# Refactoring Guía for AI-Assisted desarrollo

This comprehensive guide covers refactoring techniques, patterns, and best practices specifically tailored for AI-assisted desarrollo ambientes.

## Resumen

Refactoring is the process of restructuring existing code without changing its external behavior. With AI assistance, refactoring becomes more efficient and systematic. This guide shows how to leverage AI tools effectively during refactoring.

## Refactoring Fundamentos

### When to Refactor

Identify code that needs refactoring:

```javascript
// Code Smells - Signs that refactoring is needed

// 1. Long Method
// ❌ Bad: Method doing too many things
function processOrder(order) {
  // Validate order
  if (!order.items || order.items.length === 0) {
    throw new Error('Order must have items');
  }
  if (!order.customer) {
    throw new Error('Order must have customer');
  }
  
  // Calculate totals
  let subtotal = 0;
  let tax = 0;
  for (const item of order.items) {
    subtotal += item.price * item.quantity;
  }
  tax = subtotal * 0.08;
  
  // Apply discounts
  let discount = 0;
  if (order.coupon) {
    if (order.coupon.type === 'percentage') {
      discount = subtotal * order.coupon.value;
    } else {
      discount = order.coupon.value;
    }
  }
  
  // Send notifications
  emailService.send(order.customer.email, 'Order confirmed');
  smsService.send(order.customer.phone, 'Order confirmed');
  
  // Save to database
  const total = subtotal + tax - discount;
  database.save({
    ...order,
    subtotal,
    tax,
    discount,
    total,
    status: 'confirmed'
  });
  
  return { orderId: order.id, total };
}

// ✅ Good: Refactored into smaller, focused methods
class OrderProcessor {
  processOrder(order) {
    this.validateOrder(order);
    const pricing = this.calculatePricing(order);
    this.notifyCustomer(order.customer);
    const savedOrder = this.saveOrder(order, pricing);
    
    return {
      orderId: savedOrder.id,
      total: pricing.total
    };
  }
  
  validateOrder(order) {
    if (!order.items?.length) {
      throw new Error('Order must have items');
    }
    if (!order.customer) {
      throw new Error('Order must have customer');
    }
  }
  
  calculatePricing(order) {
    const subtotal = this.calculateSubtotal(order.items);
    const tax = this.calculateTax(subtotal);
    const discount = this.calculateDiscount(order.coupon, subtotal);
    
    return {
      subtotal,
      tax,
      discount,
      total: subtotal + tax - discount
    };
  }
  
  calculateSubtotal(items) {
    return items.reduce((sum, item) => 
      sum + (item.price * item.quantity), 0
    );
  }
  
  calculateTax(subtotal) {
    return subtotal * this.getTaxRate();
  }
  
  calculateDiscount(coupon, subtotal) {
    if (!coupon) return 0;
    
    return coupon.type === 'percentage'
      ? subtotal * coupon.value
      : coupon.value;
  }
  
  notifyCustomer(customer) {
    this.emailService.send(customer.email, 'Order confirmed');
    this.smsService.send(customer.phone, 'Order confirmed');
  }
  
  saveOrder(order, pricing) {
    return this.database.save({
      ...order,
      ...pricing,
      status: 'confirmed'
    });
  }
}
```

### Refactoring Catalog

Common refactoring techniques with examples:

```javascript
// 1. Extract Variable
// Before:
function calculatePrice(order) {
  return order.quantity * order.itemPrice * (1 - order.discount) * (1 + 0.08);
}

// After:
function calculatePrice(order) {
  const basePrice = order.quantity * order.itemPrice;
  const discountMultiplier = 1 - order.discount;
  const taxMultiplier = 1 + 0.08;
  
  return basePrice * discountMultiplier * taxMultiplier;
}

// 2. Extract Function
// Before:
function printOwing(invoice) {
  let outstanding = 0;
  
  console.log('***********************');
  console.log('**** Customer Owes ****');
  console.log('***********************');
  
  for (const order of invoice.orders) {
    outstanding += order.amount;
  }
  
  console.log(`name: ${invoice.customer}`);
  console.log(`amount: ${outstanding}`);
}

// After:
function printOwing(invoice) {
  printBanner();
  const outstanding = calculateOutstanding(invoice);
  printDetails(invoice, outstanding);
}

function printBanner() {
  console.log('***********************');
  console.log('**** Customer Owes ****');
  console.log('***********************');
}

function calculateOutstanding(invoice) {
  return invoice.orders.reduce((sum, order) => sum + order.amount, 0);
}

function printDetails(invoice, outstanding) {
  console.log(`name: ${invoice.customer}`);
  console.log(`amount: ${outstanding}`);
}

// 3. Inline Variable
// Before:
function isExpensive(price) {
  const basePrice = price > 1000;
  return basePrice;
}

// After:
function isExpensive(price) {
  return price > 1000;
}
```

## Object-Oriented Refactoring

### Extract Class

Split large classes into smaller, focused ones:

```javascript
// Before: Single class with too many responsibilities
class User {
  constructor(data) {
    this.id = data.id;
    this.name = data.name;
    this.email = data.email;
    
    // Authentication data
    this.password = data.password;
    this.lastLogin = data.lastLogin;
    this.loginAttempts = data.loginAttempts;
    
    // Profile data
    this.bio = data.bio;
    this.avatar = data.avatar;
    this.preferences = data.preferences;
    
    // Address data
    this.street = data.street;
    this.city = data.city;
    this.country = data.country;
    this.postalCode = data.postalCode;
  }
  
  // Authentication methods
  authenticate(password) {
    return this.password === this.hashPassword(password);
  }
  
  updateLoginInfo() {
    this.lastLogin = new Date();
    this.loginAttempts = 0;
  }
  
  // Profile methods
  updateProfile(profileData) {
    this.bio = profileData.bio;
    this.avatar = profileData.avatar;
  }
  
  // Address methods
  formatAddress() {
    return `${this.street}\n${this.city}, ${this.postalCode}\n${this.country}`;
  }
  
  validateAddress() {
    return this.street && this.city && this.country && this.postalCode;
  }
}

// After: Separated into focused classes
class User {
  constructor(data) {
    this.id = data.id;
    this.name = data.name;
    this.email = data.email;
    
    this.auth = new UserAuth(data);
    this.profile = new UserProfile(data);
    this.address = new Address(data);
  }
  
  getDisplayName() {
    return this.profile.displayName || this.name;
  }
}

class UserAuth {
  constructor(data) {
    this.passwordHash = data.password;
    this.lastLogin = data.lastLogin;
    this.loginAttempts = data.loginAttempts;
  }
  
  authenticate(password) {
    return this.passwordHash === this.hashPassword(password);
  }
  
  recordLogin() {
    this.lastLogin = new Date();
    this.loginAttempts = 0;
  }
  
  recordFailedAttempt() {
    this.loginAttempts++;
    if (this.loginAttempts >= 3) {
      throw new Error('Account locked due to too many failed attempts');
    }
  }
  
  private hashPassword(password) {
    // Hashing implementation
  }
}

class UserProfile {
  constructor(data) {
    this.bio = data.bio;
    this.avatar = data.avatar;
    this.preferences = data.preferences || {};
    this.displayName = data.displayName;
  }
  
  update(profileData) {
    Object.assign(this, profileData);
  }
  
  getPreference(key, defaultValue = null) {
    return this.preferences[key] ?? defaultValue;
  }
  
  setPreference(key, value) {
    this.preferences[key] = value;
  }
}

class Address {
  constructor(data) {
    this.street = data.street;
    this.city = data.city;
    this.state = data.state;
    this.country = data.country;
    this.postalCode = data.postalCode;
  }
  
  format() {
    const lines = [
      this.street,
      `${this.city}, ${this.state} ${this.postalCode}`,
      this.country
    ].filter(Boolean);
    
    return lines.join('\n');
  }
  
  validate() {
    const required = ['street', 'city', 'country', 'postalCode'];
    return required.every(field => this[field]);
  }
  
  equals(otherAddress) {
    return this.street === otherAddress.street &&
           this.city === otherAddress.city &&
           this.postalCode === otherAddress.postalCode;
  }
}
```

### Replace Conditional with Polymorphism

Transform complex conditionals into polymorphic objects:

```javascript
// Before: Complex conditional logic
class PaymentProcessor {
  processPayment(payment) {
    let result;
    
    switch (payment.type) {
      case 'credit_card':
        // Validate card number
        if (!this.isValidCardNumber(payment.cardNumber)) {
          throw new Error('Invalid card number');
        }
        
        // Check CVV
        if (!payment.cvv || payment.cvv.length !== 3) {
          throw new Error('Invalid CVV');
        }
        
        // Process credit card
        result = this.processCreditCard(payment);
        break;
        
      case 'paypal':
        // Validate PayPal email
        if (!this.isValidEmail(payment.email)) {
          throw new Error('Invalid PayPal email');
        }
        
        // Process PayPal
        result = this.processPayPal(payment);
        break;
        
      case 'bank_transfer':
        // Validate bank details
        if (!payment.accountNumber || !payment.routingNumber) {
          throw new Error('Invalid bank details');
        }
        
        // Process bank transfer
        result = this.processBankTransfer(payment);
        break;
        
      default:
        throw new Error(`Unsupported payment type: ${payment.type}`);
    }
    
    // Common post-processing
    this.logTransaction(result);
    this.sendConfirmation(result);
    
    return result;
  }
}

// After: Polymorphic payment handlers
class PaymentProcessor {
  constructor() {
    this.handlers = {
      credit_card: new CreditCardHandler(),
      paypal: new PayPalHandler(),
      bank_transfer: new BankTransferHandler()
    };
  }
  
  processPayment(payment) {
    const handler = this.handlers[payment.type];
    
    if (!handler) {
      throw new Error(`Unsupported payment type: ${payment.type}`);
    }
    
    const result = handler.process(payment);
    this.postProcess(result);
    
    return result;
  }
  
  postProcess(result) {
    this.logTransaction(result);
    this.sendConfirmation(result);
  }
}

// Abstract base class
class PaymentHandler {
  process(payment) {
    this.validate(payment);
    return this.execute(payment);
  }
  
  validate(payment) {
    throw new Error('validate() must be implemented');
  }
  
  execute(payment) {
    throw new Error('execute() must be implemented');
  }
}

class CreditCardHandler extends PaymentHandler {
  validate(payment) {
    if (!this.isValidCardNumber(payment.cardNumber)) {
      throw new Error('Invalid card number');
    }
    
    if (!payment.cvv || payment.cvv.length !== 3) {
      throw new Error('Invalid CVV');
    }
  }
  
  execute(payment) {
    // Credit card specific processing
    return {
      type: 'credit_card',
      transactionId: this.generateTransactionId(),
      amount: payment.amount,
      last4: payment.cardNumber.slice(-4)
    };
  }
  
  isValidCardNumber(number) {
    // Luhn algorithm validation
    return /^\d{16}$/.test(number);
  }
}

class PayPalHandler extends PaymentHandler {
  validate(payment) {
    if (!this.isValidEmail(payment.email)) {
      throw new Error('Invalid PayPal email');
    }
  }
  
  execute(payment) {
    // PayPal specific processing
    return {
      type: 'paypal',
      transactionId: this.generateTransactionId(),
      amount: payment.amount,
      email: payment.email
    };
  }
  
  isValidEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  }
}

class BankTransferHandler extends PaymentHandler {
  validate(payment) {
    if (!payment.accountNumber || !payment.routingNumber) {
      throw new Error('Invalid bank details');
    }
  }
  
  execute(payment) {
    // Bank transfer specific processing
    return {
      type: 'bank_transfer',
      transactionId: this.generateTransactionId(),
      amount: payment.amount,
      accountLast4: payment.accountNumber.slice(-4)
    };
  }
}
```

## Functional Refactoring

### Replace Loops with Pipeline

Transform imperative loops into functional pipelines:

```javascript
// Before: Imperative style with loops
function processTransactions(transactions) {
  // Filter valid transactions
  const valid = [];
  for (const transaction of transactions) {
    if (transaction.amount > 0 && transaction.status === 'completed') {
      valid.push(transaction);
    }
  }
  
  // Group by category
  const grouped = {};
  for (const transaction of valid) {
    if (!grouped[transaction.category]) {
      grouped[transaction.category] = [];
    }
    grouped[transaction.category].push(transaction);
  }
  
  // Calculate totals per category
  const totals = {};
  for (const category in grouped) {
    let sum = 0;
    for (const transaction of grouped[category]) {
      sum += transaction.amount;
    }
    totals[category] = sum;
  }
  
  // Find top categories
  const categoryArray = [];
  for (const category in totals) {
    categoryArray.push({
      category,
      total: totals[category]
    });
  }
  
  categoryArray.sort((a, b) => b.total - a.total);
  
  return categoryArray.slice(0, 5);
}

// After: Functional pipeline
function processTransactions(transactions) {
  return transactions
    .filter(t => t.amount > 0 && t.status === 'completed')
    .reduce((groups, transaction) => {
      const { category } = transaction;
      groups[category] = groups[category] || [];
      groups[category].push(transaction);
      return groups;
    }, {})
    |> Object.entries
    |> (entries => entries.map(([category, transactions]) => ({
      category,
      total: transactions.reduce((sum, t) => sum + t.amount, 0)
    })))
    |> (categories => categories.sort((a, b) => b.total - a.total))
    |> (sorted => sorted.slice(0, 5));
}

// Alternative without pipeline operator
function processTransactions(transactions) {
  const pipe = (...fns) => x => fns.reduce((v, f) => f(v), x);
  
  const filterValid = transactions => 
    transactions.filter(t => t.amount > 0 && t.status === 'completed');
  
  const groupByCategory = transactions =>
    transactions.reduce((groups, transaction) => ({
      ...groups,
      [transaction.category]: [...(groups[transaction.category] || []), transaction]
    }), {});
  
  const calculateTotals = groups =>
    Object.entries(groups).map(([category, transactions]) => ({
      category,
      total: transactions.reduce((sum, t) => sum + t.amount, 0)
    }));
  
  const sortByTotal = categories =>
    categories.sort((a, b) => b.total - a.total);
  
  const takeTop = n => categories =>
    categories.slice(0, n);
  
  return pipe(
    filterValid,
    groupByCategory,
    calculateTotals,
    sortByTotal,
    takeTop(5)
  )(transactions);
}
```

### Extract Pure Functions

Separate pure logic from side effects:

```javascript
// Before: Mixed concerns
class OrderService {
  async createOrder(orderData) {
    // Validation mixed with side effects
    if (!orderData.items || orderData.items.length === 0) {
      logger.error('Order validation failed: no items');
      throw new Error('Order must have items');
    }
    
    // Calculation mixed with database access
    let total = 0;
    for (const item of orderData.items) {
      const product = await this.productDb.findById(item.productId);
      if (!product) {
        logger.error(`Product not found: ${item.productId}`);
        throw new Error(`Product ${item.productId} not found`);
      }
      total += product.price * item.quantity;
    }
    
    // Business logic mixed with external service calls
    if (orderData.couponCode) {
      const discount = await this.couponService.calculateDiscount(
        orderData.couponCode,
        total
      );
      total -= discount;
    }
    
    // Save and notify
    const order = await this.orderDb.save({
      ...orderData,
      total,
      createdAt: new Date()
    });
    
    await this.emailService.sendOrderConfirmation(order);
    
    return order;
  }
}

// After: Pure functions extracted
// Pure validation functions
const validateOrder = (orderData) => {
  const errors = [];
  
  if (!orderData.items || orderData.items.length === 0) {
    errors.push('Order must have items');
  }
  
  if (!orderData.customerId) {
    errors.push('Customer ID is required');
  }
  
  orderData.items.forEach((item, index) => {
    if (!item.productId) {
      errors.push(`Item ${index}: Product ID is required`);
    }
    if (!item.quantity || item.quantity < 1) {
      errors.push(`Item ${index}: Invalid quantity`);
    }
  });
  
  return errors.length > 0 ? { valid: false, errors } : { valid: true };
};

// Pure calculation functions
const calculateOrderTotal = (items, products) => {
  return items.reduce((total, item) => {
    const product = products.find(p => p.id === item.productId);
    if (!product) {
      throw new Error(`Product ${item.productId} not found`);
    }
    return total + (product.price * item.quantity);
  }, 0);
};

const applyDiscount = (total, discountPercentage) => {
  return total * (1 - discountPercentage / 100);
};

// Refactored service with separated concerns
class OrderService {
  async createOrder(orderData) {
    // Validate using pure function
    const validation = validateOrder(orderData);
    if (!validation.valid) {
      logger.error('Order validation failed:', validation.errors);
      throw new Error(validation.errors.join('; '));
    }
    
    // Fetch required data
    const products = await this.fetchProducts(orderData.items);
    
    // Calculate using pure functions
    let total = calculateOrderTotal(orderData.items, products);
    
    if (orderData.couponCode) {
      const coupon = await this.couponService.getCoupon(orderData.couponCode);
      total = applyDiscount(total, coupon.discountPercentage);
    }
    
    // Persist and notify
    const order = await this.persistOrder({
      ...orderData,
      total,
      createdAt: new Date()
    });
    
    await this.notifyOrderCreated(order);
    
    return order;
  }
  
  async fetchProducts(items) {
    const productIds = [...new Set(items.map(item => item.productId))];
    return Promise.all(
      productIds.map(id => this.productDb.findById(id))
    );
  }
  
  async persistOrder(orderData) {
    return this.orderDb.save(orderData);
  }
  
  async notifyOrderCreated(order) {
    await this.emailService.sendOrderConfirmation(order);
  }
}
```

## Async Code Refactoring

### Promise Chain to Async/Await

Modernize promise-based code:

```javascript
// Before: Promise chains
function processUserData(userId) {
  return fetchUser(userId)
    .then(user => {
      if (!user) {
        throw new Error('User not found');
      }
      return fetchUserPosts(user.id);
    })
    .then(posts => {
      return Promise.all(
        posts.map(post => enrichPostData(post))
      );
    })
    .then(enrichedPosts => {
      return {
        posts: enrichedPosts,
        count: enrichedPosts.length
      };
    })
    .catch(error => {
      logger.error('Failed to process user data:', error);
      return {
        posts: [],
        count: 0,
        error: error.message
      };
    });
}

// After: Async/await
async function processUserData(userId) {
  try {
    const user = await fetchUser(userId);
    
    if (!user) {
      throw new Error('User not found');
    }
    
    const posts = await fetchUserPosts(user.id);
    const enrichedPosts = await Promise.all(
      posts.map(post => enrichPostData(post))
    );
    
    return {
      posts: enrichedPosts,
      count: enrichedPosts.length
    };
  } catch (error) {
    logger.error('Failed to process user data:', error);
    return {
      posts: [],
      count: 0,
      error: error.message
    };
  }
}

// Advanced: With better error handling
async function processUserData(userId) {
  const result = {
    posts: [],
    count: 0,
    error: null
  };
  
  try {
    const user = await fetchUser(userId);
    
    if (!user) {
      result.error = 'User not found';
      return result;
    }
    
    const posts = await fetchUserPosts(user.id);
    
    // Process posts with individual error handling
    const enrichmentResults = await Promise.allSettled(
      posts.map(post => enrichPostData(post))
    );
    
    result.posts = enrichmentResults
      .filter(r => r.status === 'fulfilled')
      .map(r => r.value);
    
    const failedCount = enrichmentResults.filter(
      r => r.status === 'rejected'
    ).length;
    
    if (failedCount > 0) {
      logger.warn(`Failed to enrich ${failedCount} posts`);
    }
    
    result.count = result.posts.length;
  } catch (error) {
    logger.error('Failed to process user data:', error);
    result.error = error.message;
  }
  
  return result;
}
```

### CallAtrás to Promise

Convert callback-based APIs to promises:

```javascript
// Before: Callback-based code
function loadUserData(userId, callback) {
  db.query('SELECT * FROM users WHERE id = ?', [userId], (err, users) => {
    if (err) {
      return callback(err);
    }
    
    if (users.length === 0) {
      return callback(new Error('User not found'));
    }
    
    const user = users[0];
    
    db.query('SELECT * FROM posts WHERE user_id = ?', [userId], (err, posts) => {
      if (err) {
        return callback(err);
      }
      
      user.posts = posts;
      
      db.query('SELECT * FROM comments WHERE user_id = ?', [userId], (err, comments) => {
        if (err) {
          return callback(err);
        }
        
        user.comments = comments;
        callback(null, user);
      });
    });
  });
}

// After: Promise-based with async/await
const promisify = (fn) => {
  return (...args) => {
    return new Promise((resolve, reject) => {
      fn(...args, (err, result) => {
        if (err) reject(err);
        else resolve(result);
      });
    });
  };
};

const dbQuery = promisify(db.query.bind(db));

async function loadUserData(userId) {
  const users = await dbQuery('SELECT * FROM users WHERE id = ?', [userId]);
  
  if (users.length === 0) {
    throw new Error('User not found');
  }
  
  const user = users[0];
  
  // Parallel queries for better performance
  const [posts, comments] = await Promise.all([
    dbQuery('SELECT * FROM posts WHERE user_id = ?', [userId]),
    dbQuery('SELECT * FROM comments WHERE user_id = ?', [userId])
  ]);
  
  return {
    ...user,
    posts,
    comments
  };
}

// Alternative: Using util.promisify
const util = require('util');
const dbQueryAsync = util.promisify(db.query).bind(db);

async function loadUserData(userId) {
  try {
    const users = await dbQueryAsync(
      'SELECT * FROM users WHERE id = ?', 
      [userId]
    );
    
    if (!users.length) {
      throw new Error('User not found');
    }
    
    const [posts, comments] = await Promise.all([
      dbQueryAsync('SELECT * FROM posts WHERE user_id = ?', [userId]),
      dbQueryAsync('SELECT * FROM comments WHERE user_id = ?', [userId])
    ]);
    
    return { ...users[0], posts, comments };
  } catch (error) {
    logger.error(`Failed to load user data for ${userId}:`, error);
    throw error;
  }
}
```

## Performance Refactoring

### Optimize Algorithms

Replace inefficient algorithms with better ones:

```javascript
// Before: O(n²) complexity
function findDuplicates(array) {
  const duplicates = [];
  
  for (let i = 0; i < array.length; i++) {
    for (let j = i + 1; j < array.length; j++) {
      if (array[i] === array[j] && !duplicates.includes(array[i])) {
        duplicates.push(array[i]);
      }
    }
  }
  
  return duplicates;
}

// After: O(n) complexity
function findDuplicates(array) {
  const seen = new Set();
  const duplicates = new Set();
  
  for (const item of array) {
    if (seen.has(item)) {
      duplicates.add(item);
    } else {
      seen.add(item);
    }
  }
  
  return Array.from(duplicates);
}

// More complex example: Optimizing data processing
// Before: Multiple passes through data
function processLargeDataset(data) {
  // First pass: filter
  const filtered = data.filter(item => item.active);
  
  // Second pass: transform
  const transformed = filtered.map(item => ({
    id: item.id,
    name: item.name.toUpperCase(),
    value: item.value * 1.1
  }));
  
  // Third pass: group
  const grouped = {};
  transformed.forEach(item => {
    if (!grouped[item.category]) {
      grouped[item.category] = [];
    }
    grouped[item.category].push(item);
  });
  
  // Fourth pass: aggregate
  const result = {};
  Object.entries(grouped).forEach(([category, items]) => {
    result[category] = {
      count: items.length,
      total: items.reduce((sum, item) => sum + item.value, 0),
      average: items.reduce((sum, item) => sum + item.value, 0) / items.length
    };
  });
  
  return result;
}

// After: Single pass with transducers
function processLargeDataset(data) {
  return data.reduce((result, item) => {
    // Skip inactive items
    if (!item.active) return result;
    
    // Transform inline
    const transformed = {
      id: item.id,
      name: item.name.toUpperCase(),
      value: item.value * 1.1
    };
    
    // Initialize category if needed
    const category = item.category;
    if (!result[category]) {
      result[category] = {
        count: 0,
        total: 0,
        items: []
      };
    }
    
    // Update aggregations
    result[category].count++;
    result[category].total += transformed.value;
    result[category].items.push(transformed);
    
    return result;
  }, {});
}

// Post-process for averages
function finalizeResults(grouped) {
  return Object.entries(grouped).reduce((final, [category, data]) => {
    final[category] = {
      count: data.count,
      total: data.total,
      average: data.total / data.count
    };
    return final;
  }, {});
}
```

### Memoization

Add caching for expensive computations:

```javascript
// Before: Recalculating expensive operations
class FibonacciCalculator {
  calculate(n) {
    if (n <= 1) return n;
    return this.calculate(n - 1) + this.calculate(n - 2);
  }
}

// After: With memoization
class FibonacciCalculator {
  constructor() {
    this.cache = new Map();
  }
  
  calculate(n) {
    if (n <= 1) return n;
    
    if (this.cache.has(n)) {
      return this.cache.get(n);
    }
    
    const result = this.calculate(n - 1) + this.calculate(n - 2);
    this.cache.set(n, result);
    
    return result;
  }
}

// Generic memoization decorator
function memoize(fn, options = {}) {
  const cache = new Map();
  const maxSize = options.maxSize || Infinity;
  const ttl = options.ttl || Infinity;
  
  return function memoized(...args) {
    const key = options.keyFn ? options.keyFn(...args) : JSON.stringify(args);
    
    if (cache.has(key)) {
      const cached = cache.get(key);
      if (Date.now() - cached.timestamp < ttl) {
        return cached.value;
      }
      cache.delete(key);
    }
    
    const result = fn.apply(this, args);
    
    // Implement LRU if cache is full
    if (cache.size >= maxSize) {
      const firstKey = cache.keys().next().value;
      cache.delete(firstKey);
    }
    
    cache.set(key, {
      value: result,
      timestamp: Date.now()
    });
    
    return result;
  };
}

// Usage
const expensiveOperation = memoize(
  async (userId) => {
    // Expensive database query or API call
    const user = await db.query('SELECT * FROM users WHERE id = ?', [userId]);
    const permissions = await fetchUserPermissions(userId);
    const preferences = await fetchUserPreferences(userId);
    
    return { user, permissions, preferences };
  },
  {
    maxSize: 100,
    ttl: 5 * 60 * 1000, // 5 minutes
    keyFn: (userId) => `user:${userId}`
  }
);
```

## Testing Refactored Code

### Parallel Testing Strategy

Test before and after refactoring:

```javascript
// Strategy: Run both versions and compare results
class RefactoringTester {
  constructor(originalFn, refactoredFn) {
    this.original = originalFn;
    this.refactored = refactoredFn;
  }
  
  async compareResults(...args) {
    const [originalResult, refactoredResult] = await Promise.all([
      this.runSafely(this.original, args),
      this.runSafely(this.refactored, args)
    ]);
    
    return {
      match: this.deepEqual(originalResult.value, refactoredResult.value),
      original: originalResult,
      refactored: refactoredResult,
      performance: {
        original: originalResult.duration,
        refactored: refactoredResult.duration,
        improvement: originalResult.duration / refactoredResult.duration
      }
    };
  }
  
  async runSafely(fn, args) {
    const start = performance.now();
    
    try {
      const value = await fn(...args);
      return {
        success: true,
        value,
        duration: performance.now() - start
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        duration: performance.now() - start
      };
    }
  }
  
  deepEqual(a, b) {
    return JSON.stringify(a) === JSON.stringify(b);
  }
}

// Usage in tests
describe('Refactoring validation', () => {
  const tester = new RefactoringTester(
    originalImplementation,
    refactoredImplementation
  );
  
  it('should produce identical results', async () => {
    const testCases = [
      { input: [1, 2, 3], expected: 6 },
      { input: [], expected: 0 },
      { input: [-1, -2, -3], expected: -6 }
    ];
    
    for (const testCase of testCases) {
      const comparison = await tester.compareResults(testCase.input);
      
      expect(comparison.match).toBe(true);
      expect(comparison.refactored.value).toBe(testCase.expected);
      
      // Optionally check performance improvement
      expect(comparison.performance.improvement).toBeGreaterThan(1);
    }
  });
});
```

### Characterization Tests

Create tests that capture current behavior:

```javascript
// Create tests that document existing behavior
describe('Legacy code characterization', () => {
  const legacyFunction = require('./legacy-code');
  
  // Capture current behavior
  it('should handle normal cases', () => {
    expect(legacyFunction('hello')).toBe('HELLO');
    expect(legacyFunction('world')).toBe('WORLD');
  });
  
  it('should handle edge cases', () => {
    expect(legacyFunction('')).toBe('');
    expect(legacyFunction(null)).toBe('');
    expect(legacyFunction(undefined)).toBe('');
  });
  
  it('should handle special characters', () => {
    expect(legacyFunction('hello@world.com')).toBe('HELLO@WORLD.COM');
    expect(legacyFunction('123')).toBe('123');
  });
  
  // Document quirks
  it('should exhibit known quirks', () => {
    // Document unexpected behavior
    expect(legacyFunction(123)).toBe('123'); // Coerces numbers to strings
    expect(legacyFunction(['a', 'b'])).toBe('A,B'); // Joins arrays
  });
});

// Now refactor with confidence
function refactoredFunction(input) {
  // Maintain the same behavior, including quirks
  if (input == null) return '';
  
  // Handle arrays like the original
  if (Array.isArray(input)) {
    return input.join(',').toUpperCase();
  }
  
  // Coerce to string and uppercase
  return String(input).toUpperCase();
}
```

## Refactoring Tools and Automation

### Automated Refactoring Scripts

Create tools to assist with refactoring:

```javascript
// AST-based refactoring tool
const parser = require('@babel/parser');
const traverse = require('@babel/traverse').default;
const generate = require('@babel/generator').default;
const t = require('@babel/types');

// Convert callbacks to async/await
function callbackToAsync(code) {
  const ast = parser.parse(code, {
    sourceType: 'module',
    plugins: ['jsx', 'typescript']
  });
  
  traverse(ast, {
    CallExpression(path) {
      // Look for callback patterns
      const { callee, arguments: args } = path.node;
      
      // Check if last argument is a function (callback)
      const lastArg = args[args.length - 1];
      if (!t.isFunction(lastArg)) return;
      
      // Check if callback has (err, result) signature
      const params = lastArg.params;
      if (params.length !== 2) return;
      
      // Transform to async/await
      const asyncVersion = t.awaitExpression(
        t.callExpression(
          t.memberExpression(callee, t.identifier('promise')),
          args.slice(0, -1)
        )
      );
      
      path.replaceWith(asyncVersion);
    }
  });
  
  return generate(ast).code;
}

// Batch rename variables
function renameVariables(code, mappings) {
  const ast = parser.parse(code);
  
  traverse(ast, {
    Identifier(path) {
      if (mappings[path.node.name]) {
        path.node.name = mappings[path.node.name];
      }
    }
  });
  
  return generate(ast).code;
}

// Extract magic numbers
function extractMagicNumbers(code) {
  const ast = parser.parse(code);
  const constants = new Map();
  
  traverse(ast, {
    NumericLiteral(path) {
      const value = path.node.value;
      
      // Skip common numbers
      if ([0, 1, -1, 2, 10, 100].includes(value)) return;
      
      // Generate constant name
      const name = `CONSTANT_${value}`.replace('.', '_');
      constants.set(value, name);
      
      // Replace with identifier
      path.replaceWith(t.identifier(name));
    }
  });
  
  // Add constants declaration
  const declarations = Array.from(constants.entries()).map(([value, name]) =>
    t.variableDeclaration('const', [
      t.variableDeclarator(t.identifier(name), t.numericLiteral(value))
    ])
  );
  
  ast.program.body.unshift(...declarations);
  
  return generate(ast).code;
}
```

## Mejores Prácticas

### Refactoring Verificarlist

Before refactoring:
- [ ] Ensure comprehensive test coverage exists
- [ ] Commit current working code
- [ ] Understand the code's purpose and behavior
- [ ] Identify specific code smells to address
- [ ] Plan refactoring approach

During refactoring:
- [ ] Make small, incremental changes
- [ ] Run tests after each change
- [ ] Keep refactoring separate from feature changes
- [ ] Maintain backwards compatibility when needed
- [ ] Document significant structural changes

After refactoring:
- [ ] Verify all tests pass
- [ ] Verificar performance hasn't degraded
- [ ] Revisar code with team
- [ ] Actualizar documentation
- [ ] Monitor for issues in producción

### Common Pitfalls

1. **Over-engineering**: Don't add unnecessary abstraction
2. **Breaking changes**: Maintain API compatibility
3. **Performance regression**: Always benchmark critical paths
4. **Lost domain knowledge**: Preserve important comments
5. **Incomplete refactoring**: Finish what you start

## Conclusión

Effective refactoring with AI assistance requires:
- Clear understanding of code smells and solutions
- Systematic approach to code transformation
- Comprehensive testing throughout the process
- Leveraging AI to suggest and implement improvements
- Continuous learning from refactoring patterns

Remember: Refactoring is about making code better without changing what it does. The goal is cleaner, more maintainable code that's easier to understand and modify.