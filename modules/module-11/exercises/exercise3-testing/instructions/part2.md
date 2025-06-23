# Exercise 3: Mastery - Production-Ready Financial Platform (Part 2) ⭐⭐⭐

## Step 3: Implement Security Layer (Continued)

### 3.2 Create Account Service with CQRS

Create `services/account-service/domain/aggregates/account.py`:

**Copilot Prompt Suggestion:**
```python
# Create an Account aggregate that:
# - Implements event sourcing
# - Validates all business rules
# - Emits domain events
# - Supports multiple currencies
# - Tracks transaction history
# - Implements overdraft protection
# - Handles concurrent modifications
```

**Expected Output:**
```python
from typing import List, Optional, Dict
from decimal import Decimal
from datetime import datetime
from uuid import UUID, uuid4
from dataclasses import dataclass, field
from enum import Enum

class AccountType(Enum):
    CHECKING = "checking"
    SAVINGS = "savings"
    CREDIT = "credit"

class AccountStatus(Enum):
    ACTIVE = "active"
    FROZEN = "frozen"
    CLOSED = "closed"

@dataclass
class Money:
    amount: Decimal
    currency: str
    
    def __post_init__(self):
        if self.amount < 0:
            raise ValueError("Money amount cannot be negative")
        if len(self.currency) != 3:
            raise ValueError("Currency must be 3-letter ISO code")
    
    def __add__(self, other: 'Money') -> 'Money':
        if self.currency != other.currency:
            raise ValueError("Cannot add different currencies")
        return Money(self.amount + other.amount, self.currency)
    
    def __sub__(self, other: 'Money') -> 'Money':
        if self.currency != other.currency:
            raise ValueError("Cannot subtract different currencies")
        return Money(self.amount - other.amount, self.currency)

# Domain Events
@dataclass
class DomainEvent:
    aggregate_id: UUID
    event_id: UUID = field(default_factory=uuid4)
    occurred_at: datetime = field(default_factory=datetime.utcnow)

@dataclass
class AccountOpened(DomainEvent):
    account_type: AccountType
    currency: str
    owner_id: UUID
    initial_balance: Decimal = Decimal("0")

@dataclass
class MoneyDeposited(DomainEvent):
    amount: Decimal
    currency: str
    transaction_id: UUID
    description: str

@dataclass
class MoneyWithdrawn(DomainEvent):
    amount: Decimal
    currency: str
    transaction_id: UUID
    description: str

@dataclass
class AccountFrozen(DomainEvent):
    reason: str
    frozen_by: str

@dataclass
class AccountUnfrozen(DomainEvent):
    unfrozen_by: str

class InsufficientFundsError(Exception):
    pass

class AccountFrozenError(Exception):
    pass

class Account:
    """Account aggregate root using event sourcing"""
    
    def __init__(self, account_id: UUID = None):
        self.id = account_id or uuid4()
        self.version = 0
        self.balance = Money(Decimal("0"), "USD")
        self.account_type = None
        self.status = None
        self.owner_id = None
        self.pending_events: List[DomainEvent] = []
        self.daily_withdrawal_limit = Decimal("5000")
        self.daily_withdrawn = Decimal("0")
        self.last_withdrawal_date = None
        self.overdraft_limit = Decimal("0")
    
    @classmethod
    def open_account(
        cls,
        account_type: AccountType,
        currency: str,
        owner_id: UUID,
        initial_deposit: Optional[Decimal] = None
    ) -> 'Account':
        """Factory method to open a new account"""
        account = cls()
        
        # Apply business rules
        if account_type == AccountType.SAVINGS and initial_deposit and initial_deposit < 100:
            raise ValueError("Savings account requires minimum $100 deposit")
        
        # Emit event
        event = AccountOpened(
            aggregate_id=account.id,
            account_type=account_type,
            currency=currency,
            owner_id=owner_id,
            initial_balance=initial_deposit or Decimal("0")
        )
        
        account._apply_event(event)
        account.pending_events.append(event)
        
        return account
    
    def deposit(
        self,
        amount: Decimal,
        currency: str,
        transaction_id: UUID,
        description: str
    ):
        """Deposit money into account"""
        if self.status == AccountStatus.CLOSED:
            raise ValueError("Cannot deposit to closed account")
        
        if amount <= 0:
            raise ValueError("Deposit amount must be positive")
        
        # For different currencies, would need exchange rate service
        if currency != self.balance.currency:
            raise ValueError(f"Account only accepts {self.balance.currency}")
        
        event = MoneyDeposited(
            aggregate_id=self.id,
            amount=amount,
            currency=currency,
            transaction_id=transaction_id,
            description=description
        )
        
        self._apply_event(event)
        self.pending_events.append(event)
    
    def withdraw(
        self,
        amount: Decimal,
        currency: str,
        transaction_id: UUID,
        description: str
    ):
        """Withdraw money from account"""
        if self.status == AccountStatus.FROZEN:
            raise AccountFrozenError("Account is frozen")
        
        if self.status == AccountStatus.CLOSED:
            raise ValueError("Cannot withdraw from closed account")
        
        if amount <= 0:
            raise ValueError("Withdrawal amount must be positive")
        
        if currency != self.balance.currency:
            raise ValueError(f"Account only supports {self.balance.currency}")
        
        # Check daily limit
        today = datetime.utcnow().date()
        if self.last_withdrawal_date != today:
            self.daily_withdrawn = Decimal("0")
            self.last_withdrawal_date = today
        
        if self.daily_withdrawn + amount > self.daily_withdrawal_limit:
            raise ValueError("Daily withdrawal limit exceeded")
        
        # Check available balance (including overdraft)
        available_balance = self.balance.amount + self.overdraft_limit
        if amount > available_balance:
            raise InsufficientFundsError(
                f"Insufficient funds. Available: {available_balance}"
            )
        
        event = MoneyWithdrawn(
            aggregate_id=self.id,
            amount=amount,
            currency=currency,
            transaction_id=transaction_id,
            description=description
        )
        
        self._apply_event(event)
        self.pending_events.append(event)
    
    def freeze(self, reason: str, frozen_by: str):
        """Freeze account"""
        if self.status == AccountStatus.FROZEN:
            raise ValueError("Account already frozen")
        
        if self.status == AccountStatus.CLOSED:
            raise ValueError("Cannot freeze closed account")
        
        event = AccountFrozen(
            aggregate_id=self.id,
            reason=reason,
            frozen_by=frozen_by
        )
        
        self._apply_event(event)
        self.pending_events.append(event)
    
    def unfreeze(self, unfrozen_by: str):
        """Unfreeze account"""
        if self.status != AccountStatus.FROZEN:
            raise ValueError("Account is not frozen")
        
        event = AccountUnfrozen(
            aggregate_id=self.id,
            unfrozen_by=unfrozen_by
        )
        
        self._apply_event(event)
        self.pending_events.append(event)
    
    def _apply_event(self, event: DomainEvent):
        """Apply event to update aggregate state"""
        if isinstance(event, AccountOpened):
            self.account_type = event.account_type
            self.status = AccountStatus.ACTIVE
            self.owner_id = event.owner_id
            self.balance = Money(event.initial_balance, event.currency)
            
            # Set overdraft based on account type
            if event.account_type == AccountType.CHECKING:
                self.overdraft_limit = Decimal("500")
        
        elif isinstance(event, MoneyDeposited):
            self.balance = Money(
                self.balance.amount + event.amount,
                self.balance.currency
            )
        
        elif isinstance(event, MoneyWithdrawn):
            self.balance = Money(
                self.balance.amount - event.amount,
                self.balance.currency
            )
            self.daily_withdrawn += event.amount
        
        elif isinstance(event, AccountFrozen):
            self.status = AccountStatus.FROZEN
        
        elif isinstance(event, AccountUnfrozen):
            self.status = AccountStatus.ACTIVE
        
        self.version += 1
    
    def get_pending_events(self) -> List[DomainEvent]:
        """Get and clear pending events"""
        events = self.pending_events[:]
        self.pending_events.clear()
        return events
    
    @classmethod
    def from_events(cls, events: List[DomainEvent]) -> 'Account':
        """Reconstitute aggregate from events"""
        if not events:
            raise ValueError("Cannot create account from empty events")
        
        account = cls(account_id=events[0].aggregate_id)
        for event in events:
            account._apply_event(event)
        
        return account
```

### 3.3 Create Account Repository with Event Store

Create `services/account-service/infrastructure/repositories/account_repository.py`:

**Copilot Prompt Suggestion:**
```python
# Create account repository that:
# - Loads aggregates from event store
# - Saves aggregate events
# - Implements snapshot optimization
# - Handles concurrent modifications
# - Provides query methods via projections
```

### Step 4: Implement Resilience Patterns

#### 4.1 Advanced Circuit Breaker

Create `shared/resilience/circuit_breaker.py`:

**Copilot Prompt Suggestion:**
```python
# Create an advanced circuit breaker with:
# - Multiple failure thresholds
# - Gradual recovery (half-open state)
# - Per-endpoint configuration
# - Metrics collection
# - Event emission on state changes
# - Bulkhead integration
```

**Expected Output:**
```python
import asyncio
from datetime import datetime, timedelta
from typing import Callable, Dict, Optional, Any
from enum import Enum
import logging
from dataclasses import dataclass, field
from collections import deque
import time

logger = logging.getLogger(__name__)

class CircuitState(Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"

@dataclass
class CircuitBreakerConfig:
    failure_threshold: int = 5
    success_threshold: int = 2
    timeout: timedelta = timedelta(seconds=30)
    half_open_requests: int = 3
    time_window: timedelta = timedelta(seconds=60)
    excluded_exceptions: tuple = ()
    
@dataclass
class CircuitBreakerMetrics:
    total_requests: int = 0
    successful_requests: int = 0
    failed_requests: int = 0
    rejected_requests: int = 0
    state_changes: List[Dict[str, Any]] = field(default_factory=list)
    response_times: deque = field(default_factory=lambda: deque(maxlen=100))

class CircuitBreaker:
    def __init__(self, name: str, config: CircuitBreakerConfig = None):
        self.name = name
        self.config = config or CircuitBreakerConfig()
        self.state = CircuitState.CLOSED
        self.failure_count = 0
        self.success_count = 0
        self.last_failure_time: Optional[datetime] = None
        self.half_open_requests = 0
        self.metrics = CircuitBreakerMetrics()
        self._lock = asyncio.Lock()
        self._state_change_handlers: List[Callable] = []
        
        # Sliding window for failure rate calculation
        self.request_window = deque(maxlen=100)
    
    def add_state_change_handler(self, handler: Callable):
        """Add handler for state change events"""
        self._state_change_handlers.append(handler)
    
    async def __aenter__(self):
        async with self._lock:
            if not await self._can_execute():
                self.metrics.rejected_requests += 1
                raise CircuitOpenError(f"Circuit {self.name} is open")
            
            if self.state == CircuitState.HALF_OPEN:
                self.half_open_requests += 1
        
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        async with self._lock:
            self.metrics.total_requests += 1
            
            if exc_type is None:
                await self._on_success()
            elif not isinstance(exc_val, self.config.excluded_exceptions):
                await self._on_failure()
            
            # Calculate failure rate
            self._update_failure_rate()
    
    async def _can_execute(self) -> bool:
        """Check if request can be executed"""
        if self.state == CircuitState.CLOSED:
            return True
        
        if self.state == CircuitState.OPEN:
            if self._should_attempt_reset():
                await self._transition_to(CircuitState.HALF_OPEN)
                return True
            return False
        
        # HALF_OPEN state
        return self.half_open_requests < self.config.half_open_requests
    
    def _should_attempt_reset(self) -> bool:
        """Check if circuit should attempt reset"""
        return (
            self.last_failure_time and
            datetime.utcnow() - self.last_failure_time > self.config.timeout
        )
    
    async def _on_success(self):
        """Handle successful request"""
        self.metrics.successful_requests += 1
        self.request_window.append((datetime.utcnow(), True))
        
        if self.state == CircuitState.HALF_OPEN:
            self.success_count += 1
            if self.success_count >= self.config.success_threshold:
                await self._transition_to(CircuitState.CLOSED)
        elif self.state == CircuitState.CLOSED:
            self.failure_count = 0
    
    async def _on_failure(self):
        """Handle failed request"""
        self.metrics.failed_requests += 1
        self.request_window.append((datetime.utcnow(), False))
        self.last_failure_time = datetime.utcnow()
        
        if self.state == CircuitState.CLOSED:
            self.failure_count += 1
            if self.failure_count >= self.config.failure_threshold:
                await self._transition_to(CircuitState.OPEN)
        elif self.state == CircuitState.HALF_OPEN:
            await self._transition_to(CircuitState.OPEN)
    
    async def _transition_to(self, new_state: CircuitState):
        """Transition to new state"""
        old_state = self.state
        self.state = new_state
        
        # Reset counters
        if new_state == CircuitState.CLOSED:
            self.failure_count = 0
            self.success_count = 0
        elif new_state == CircuitState.HALF_OPEN:
            self.half_open_requests = 0
            self.success_count = 0
        
        # Record state change
        state_change = {
            "timestamp": datetime.utcnow().isoformat(),
            "from_state": old_state.value,
            "to_state": new_state.value,
            "failure_count": self.failure_count
        }
        self.metrics.state_changes.append(state_change)
        
        # Notify handlers
        for handler in self._state_change_handlers:
            asyncio.create_task(handler(self.name, old_state, new_state))
        
        logger.info(f"Circuit {self.name}: {old_state.value} -> {new_state.value}")
    
    def _update_failure_rate(self):
        """Update sliding window failure rate"""
        # Remove old entries
        cutoff_time = datetime.utcnow() - self.config.time_window
        while self.request_window and self.request_window[0][0] < cutoff_time:
            self.request_window.popleft()
    
    def get_metrics(self) -> Dict[str, Any]:
        """Get circuit breaker metrics"""
        failure_rate = 0
        if self.request_window:
            failures = sum(1 for _, success in self.request_window if not success)
            failure_rate = failures / len(self.request_window)
        
        return {
            "name": self.name,
            "state": self.state.value,
            "failure_rate": failure_rate,
            "metrics": {
                "total_requests": self.metrics.total_requests,
                "successful_requests": self.metrics.successful_requests,
                "failed_requests": self.metrics.failed_requests,
                "rejected_requests": self.metrics.rejected_requests
            },
            "last_state_change": (
                self.metrics.state_changes[-1] 
                if self.metrics.state_changes else None
            )
        }

class CircuitOpenError(Exception):
    """Raised when circuit is open"""
    pass

# Circuit breaker decorator
def circuit_breaker(
    name: str = None,
    config: CircuitBreakerConfig = None
):
    """Decorator for applying circuit breaker to functions"""
    def decorator(func):
        breaker_name = name or f"{func.__module__}.{func.__name__}"
        breaker = CircuitBreaker(breaker_name, config)
        
        async def wrapper(*args, **kwargs):
            start_time = time.time()
            
            async with breaker:
                try:
                    result = await func(*args, **kwargs)
                    response_time = time.time() - start_time
                    breaker.metrics.response_times.append(response_time)
                    return result
                except Exception as e:
                    response_time = time.time() - start_time
                    breaker.metrics.response_times.append(response_time)
                    raise
        
        wrapper.circuit_breaker = breaker
        return wrapper
    
    return decorator
```

### Step 5: Implement Distributed Tracing

#### 5.1 OpenTelemetry Integration

Create `shared/tracing/setup.py`:

**Copilot Prompt Suggestion:**
```python
# Set up OpenTelemetry with:
# - Automatic instrumentation for FastAPI
# - Context propagation across services
# - Custom span attributes
# - Sampling configuration
# - Multiple exporters (Jaeger, Zipkin)
# - Performance metrics correlation
```

### Step 6: Create Kubernetes Manifests

#### 6.1 Service Deployment

Create `infrastructure/kubernetes/deployments/account-service.yaml`:

**Copilot Prompt Suggestion:**
```yaml
# Create Kubernetes deployment for account service with:
# - Multiple replicas with pod anti-affinity
# - Resource limits and requests
# - Liveness and readiness probes
# - Security context (non-root user)
# - Config and secret management
# - Horizontal pod autoscaling
# - Pod disruption budget
# - Network policies
```

**Expected Output:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: account-service
  namespace: financial-platform
  labels:
    app: account-service
    version: v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: account-service
  template:
    metadata:
      labels:
        app: account-service
        version: v1
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: account-service
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - account-service
            topologyKey: kubernetes.io/hostname
      
      containers:
      - name: account-service
        image: financial-platform/account-service:latest
        imagePullPolicy: Always
        
        ports:
        - name: http
          containerPort: 8000
          protocol: TCP
        - name: metrics
          containerPort: 8080
          protocol: TCP
        
        env:
        - name: SERVICE_NAME
          value: "account-service"
        - name: ENVIRONMENT
          value: "production"
        - name: LOG_LEVEL
          value: "INFO"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: account-service-secrets
              key: database-url
        - name: EVENT_STORE_URL
          valueFrom:
            secretKeyRef:
              name: shared-secrets
              key: event-store-url
        - name: JAEGER_AGENT_HOST
          valueFrom:
            fieldRef:
              fieldPath: status.hostIP
        
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
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /health/ready
            port: http
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        
        volumeMounts:
        - name: tls-certs
          mountPath: /etc/tls
          readOnly: true
        - name: config
          mountPath: /etc/config
          readOnly: true
      
      volumes:
      - name: tls-certs
        secret:
          secretName: account-service-tls
      - name: config
        configMap:
          name: account-service-config

---
apiVersion: v1
kind: Service
metadata:
  name: account-service
  namespace: financial-platform
  labels:
    app: account-service
spec:
  type: ClusterIP
  ports:
  - name: http
    port: 80
    targetPort: http
  - name: metrics
    port: 8080
    targetPort: metrics
  selector:
    app: account-service

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: account-service-hpa
  namespace: financial-platform
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: account-service
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
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60

---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: account-service-pdb
  namespace: financial-platform
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: account-service
```

### Step 7: Implement Chaos Engineering

#### 7.1 Chaos Experiments

Create `chaos/experiments/network-latency.yaml`:

**Copilot Prompt Suggestion:**
```yaml
# Create Litmus chaos experiment that:
# - Injects network latency between services
# - Targets specific pods with labels
# - Configurable latency and jitter
# - Runs for specified duration
# - Includes steady-state hypothesis
```

### Step 8: Create Integration Tests

Create `tests/integration/test_payment_saga.py`:

**Copilot Prompt Suggestion:**
```python
# Create integration tests for payment saga that:
# - Tests successful payment flow
# - Tests compensation on failure
# - Tests timeout scenarios
# - Tests concurrent payments
# - Validates event store consistency
# - Checks idempotency
```

**Expected Output:**
```python
import pytest
import asyncio
from uuid import uuid4
from decimal import Decimal
from services.saga_orchestrator.app.orchestrator import SagaOrchestrator
from services.saga_orchestrator.app.sagas.payment_transfer import create_payment_transfer_saga

@pytest.mark.asyncio
async def test_successful_payment_transfer(
    saga_orchestrator: SagaOrchestrator,
    account_service,
    payment_service
):
    """Test successful payment transfer saga"""
    # Setup test accounts
    sender_id = await account_service.create_account(
        account_type="checking",
        initial_balance=Decimal("1000")
    )
    receiver_id = await account_service.create_account(
        account_type="checking",
        initial_balance=Decimal("0")
    )
    
    # Register saga
    saga_orchestrator.register_saga(create_payment_transfer_saga())
    
    # Start payment transfer
    saga_id = await saga_orchestrator.start_saga(
        "payment_transfer",
        {
            "sender_account_id": sender_id,
            "receiver_account_id": receiver_id,
            "amount": Decimal("100"),
            "currency": "USD",
            "description": "Test payment"
        }
    )
    
    # Wait for saga completion
    await asyncio.sleep(2)
    
    # Verify saga completed
    status = saga_orchestrator.get_saga_status(saga_id)
    assert status["state"] == "completed"
    
    # Verify account balances
    sender_balance = await account_service.get_balance(sender_id)
    assert sender_balance == Decimal("900")
    
    receiver_balance = await account_service.get_balance(receiver_id)
    assert receiver_balance == Decimal("100")
    
    # Verify events were emitted
    events = await event_store.get_events_by_type("PaymentCompleted")
    assert len(events) == 1
    assert events[0].data["amount"] == "100"

@pytest.mark.asyncio
async def test_payment_compensation_on_risk_failure(
    saga_orchestrator: SagaOrchestrator,
    account_service,
    risk_service
):
    """Test saga compensation when risk check fails"""
    # Setup suspicious account
    sender_id = await account_service.create_account(
        account_type="checking",
        initial_balance=Decimal("10000")
    )
    
    # Flag account as high risk
    await risk_service.flag_account(sender_id, "suspicious_activity")
    
    # Attempt large payment
    saga_id = await saga_orchestrator.start_saga(
        "payment_transfer",
        {
            "sender_account_id": sender_id,
            "receiver_account_id": uuid4(),
            "amount": Decimal("5000"),
            "currency": "USD"
        }
    )
    
    # Wait for saga
    await asyncio.sleep(3)
    
    # Verify saga was compensated
    status = saga_orchestrator.get_saga_status(saga_id)
    assert status["state"] == "compensated"
    
    # Verify balance was restored
    balance = await account_service.get_balance(sender_id)
    assert balance == Decimal("10000")
    
    # Verify compensation events
    events = await event_store.get_events_by_type("PaymentRejected")
    assert len(events) == 1
    assert "risk_check_failed" in events[0].data["reason"]
```

## 📝 Testing and Validation

### Load Testing Script

Create `tests/performance/load_test.py`:

**Copilot Prompt Suggestion:**
```python
# Create load test that:
# - Simulates 1000 concurrent users
# - Tests payment transfers under load
# - Measures response times and error rates
# - Tests circuit breaker behavior
# - Validates data consistency
# - Generates performance report
```

## 🎯 Success Criteria

You have successfully completed this exercise when:

1. **Saga Pattern Works**
   - Payment transfers complete successfully
   - Failed transactions are properly compensated
   - State is consistent across all services

2. **Security is Implemented**
   - mTLS between all services
   - JWT authentication for external APIs
   - Secrets managed via Vault

3. **Resilience Patterns Function**
   - Circuit breakers prevent cascade failures
   - Services recover from failures
   - System remains available under stress

4. **Observability is Complete**
   - Distributed traces show full request flow
   - Metrics are collected and visualized
   - Logs are centralized and searchable
   - Alerts fire on anomalies

5. **Performance Meets SLAs**
   - 99.9% availability
   - p99 latency < 500ms
   - Handles 1000 TPS
   - Zero data loss

## 📊 Monitoring Dashboard

Access your monitoring stack:
- Grafana: http://localhost:3000 (admin/admin123)
- Prometheus: http://localhost:9090
- Jaeger: http://localhost:16686
- RabbitMQ: http://localhost:15672 (admin/admin123)

## 🎉 Congratulations!

You've built a production-ready financial platform with:
- ✅ Event Sourcing and CQRS
- ✅ Distributed Transactions with Sagas
- ✅ Comprehensive Security
- ✅ Advanced Resilience Patterns
- ✅ Complete Observability
- ✅ Chaos Engineering Ready
- ✅ Enterprise-Grade Architecture

You are now ready to build and operate complex microservices systems in production!

## 🚀 Next Steps

1. **Module 12**: Cloud-Native Development - Deploy this to Kubernetes
2. **Module 13**: Infrastructure as Code - Automate everything
3. **Module 14**: CI/CD Pipelines - Continuous deployment

## 📚 Additional Resources

- [Microservices Patterns](https://microservices.io/patterns/)
- [Event Sourcing](https://martinfowler.com/eaaDev/EventSourcing.html)
- [Saga Pattern](https://microservices.io/patterns/data/saga.html)
- [Circuit Breaker](https://martinfowler.com/bliki/CircuitBreaker.html)
- [CQRS](https://martinfowler.com/bliki/CQRS.html)
---

## 🔗 Navigation

[← Previous: Part 1](part1.md) | [🏠 Module Home](../../../../README.md) | [Back to Module →](../../../../README.md)

## 📚 Quick Links

- [Prerequisites](../../../../prerequisites.md)
- [Module Resources](../../../../README.md#resources)
- [Troubleshooting Guide](../../../../troubleshooting.md)
- [Solution Code](../solution/)
