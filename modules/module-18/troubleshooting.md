# Module 18: Enterprise Integration Troubleshooting Guide

## 🔍 Common Issues and Solutions

This guide helps diagnose and resolve common issues when implementing enterprise integration patterns in Module 18.

## 🚨 ESB (Enterprise Service Bus) Issues

### 1. Messages Not Being Routed

**Symptoms:**
- Messages sent to ESB but not reaching destinations
- No errors in logs
- Message count not increasing in queues

**Diagnosis Steps:**

```bash
# Check Service Bus namespace connectivity
az servicebus namespace show \
  --name "sb-module18-xxxxx" \
  --resource-group "rg-workshop-module18"

# List queues and check message counts
az servicebus queue list \
  --namespace-name "sb-module18-xxxxx" \
  --resource-group "rg-workshop-module18"

# Check specific queue details
az servicebus queue show \
  --name "order-processing" \
  --namespace-name "sb-module18-xxxxx" \
  --resource-group "rg-workshop-module18"
```

**Solutions:**

1. **Verify Routing Rules:**
   ```python
   # Debug routing decisions
   async def debug_routing(message: Message):
       router = MessageRouter(settings)
       
       # Enable debug logging
       logging.getLogger("esb.router").setLevel(logging.DEBUG)
       
       # Test routing
       decision = await router.route_message(message)
       
       print(f"Message type: {message.message_type}")
       print(f"Matched route: {decision.route_name}")
       print(f"Destinations: {decision.destinations}")
       
       # Check each condition
       for rule in router.routing_rules:
           print(f"\nRule: {rule['name']}")
           for condition in rule['conditions']:
               field_value = router._get_field_value(message, condition['field'])
               matches = router._evaluate_condition(
                   field_value, 
                   condition['operator'], 
                   condition['value']
               )
               print(f"  {condition['field']} = {field_value} -> {matches}")
   ```

2. **Check Connection String Format:**
   ```python
   # Validate connection string
   import re
   
   def validate_connection_string(conn_str):
       pattern = r"Endpoint=sb://([^.]+)\.servicebus\.windows\.net/;SharedAccessKeyName=([^;]+);SharedAccessKey=(.+)"
       match = re.match(pattern, conn_str)
       
       if not match:
           print("Invalid connection string format")
           return False
       
       namespace, key_name, key = match.groups()
       print(f"Namespace: {namespace}")
       print(f"Key Name: {key_name}")
       print(f"Key Length: {len(key)}")
       
       return True
   ```

3. **Enable Service Bus Diagnostics:**
   ```python
   # Add logging to Service Bus client
   import logging
   
   logging.basicConfig(level=logging.DEBUG)
   logging.getLogger("azure.servicebus").setLevel(logging.DEBUG)
   logging.getLogger("uamqp").setLevel(logging.DEBUG)
   ```

### 2. Message Transformation Failures

**Symptoms:**
- Transformation errors in logs
- Messages stuck in processing
- Incorrect message formats at destination

**Diagnosis:**

```python
# Test transformation pipeline
async def test_transformation():
    transformer = MessageTransformer(settings)
    
    # Test message
    test_message = Message(
        id="test-001",
        message_type=MessageType.ORDER,
        payload={
            "order_id": "ORD-123",
            "items": [{"id": "PROD-1", "qty": 2}]
        },
        headers={"format": "json"}
    )
    
    try:
        # Test JSON to XML
        xml_message = await transformer.transform(test_message, "xml")
        print("XML Output:")
        print(xml_message.payload)
        
        # Test XML to JSON
        json_message = await transformer.transform(xml_message, "json")
        print("\nJSON Output:")
        print(json.dumps(json_message.payload, indent=2))
        
    except Exception as e:
        print(f"Transformation failed: {str(e)}")
        import traceback
        traceback.print_exc()
```

**Solutions:**

1. **Add Schema Validation:**
   ```python
   class SchemaValidator:
       def __init__(self):
           self.schemas = {
               "order": {
                   "type": "object",
                   "required": ["order_id", "items"],
                   "properties": {
                       "order_id": {"type": "string"},
                       "items": {
                           "type": "array",
                           "items": {
                               "type": "object",
                               "required": ["id", "qty"],
                               "properties": {
                                   "id": {"type": "string"},
                                   "qty": {"type": "integer", "minimum": 1}
                               }
                           }
                       }
                   }
               }
           }
       
       def validate(self, message_type: str, payload: dict) -> bool:
           schema = self.schemas.get(message_type)
           if not schema:
               return True  # No schema defined
           
           try:
               jsonschema.validate(payload, schema)
               return True
           except jsonschema.ValidationError as e:
               logger.error(f"Schema validation failed: {e.message}")
               return False
   ```

2. **Implement Transformation Error Recovery:**
   ```python
   async def transform_with_fallback(self, message: Message, target_format: str):
       try:
           return await self.transform(message, target_format)
       except TransformationError:
           # Try simpler transformation
           if target_format == "xml":
               return self._basic_json_to_xml(message)
           elif target_format == "json":
               return self._basic_xml_to_json(message)
           else:
               # Return original message
               logger.warning(f"Transformation failed, returning original")
               return message
   ```

### 3. Dead Letter Queue Overflow

**Symptoms:**
- DLQ message count increasing
- Repeated processing failures
- High retry counts

**Diagnosis:**

```bash
# Check DLQ status
az servicebus queue show \
  --name "order-processing/$DeadLetterQueue" \
  --namespace-name "sb-module18-xxxxx" \
  --resource-group "rg-workshop-module18" \
  --query "countDetails"
```

**Solutions:**

1. **Implement DLQ Processor:**
   ```python
   class DeadLetterProcessor:
       async def process_dlq(self):
           """Process dead letter queue messages."""
           async with ServiceBusClient.from_connection_string(
               self.connection_string
           ) as client:
               
               dlq_receiver = client.get_queue_receiver(
                   queue_name="order-processing",
                   sub_queue=ServiceBusSubQueue.DEAD_LETTER
               )
               
               async with dlq_receiver:
                   messages = await dlq_receiver.receive_messages(
                       max_message_count=10,
                       max_wait_time=5
                   )
                   
                   for message in messages:
                       # Analyze failure
                       reason = message.dead_letter_reason
                       description = message.dead_letter_error_description
                       delivery_count = message.delivery_count
                       
                       print(f"\nDead Letter Message:")
                       print(f"ID: {message.message_id}")
                       print(f"Reason: {reason}")
                       print(f"Description: {description}")
                       print(f"Delivery Count: {delivery_count}")
                       
                       # Decide action
                       if self._is_recoverable(reason):
                           await self._requeue_message(message)
                       else:
                           await self._archive_message(message)
                       
                       await dlq_receiver.complete_message(message)
   ```

## 📊 CQRS/Event Sourcing Issues

### 1. Event Store Concurrency Conflicts

**Symptoms:**
- ConcurrencyException when saving events
- "Precondition Failed" errors from Cosmos DB
- Lost updates

**Diagnosis:**

```python
# Test concurrent operations
async def test_concurrent_writes():
    event_store = EventStore(connection_string, database_name)
    
    # Simulate concurrent updates
    tasks = []
    for i in range(5):
        task = update_order_concurrently(event_store, "ORDER-001", i)
        tasks.append(task)
    
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    # Check results
    successes = sum(1 for r in results if not isinstance(r, Exception))
    failures = sum(1 for r in results if isinstance(r, Exception))
    
    print(f"Successes: {successes}, Failures: {failures}")
    
    # Print failure details
    for i, result in enumerate(results):
        if isinstance(result, Exception):
            print(f"Task {i} failed: {type(result).__name__}: {str(result)}")
```

**Solutions:**

1. **Implement Optimistic Concurrency with Retry:**
   ```python
   async def save_events_with_retry(
       self,
       aggregate_id: str,
       events: List[DomainEvent],
       expected_version: int,
       max_retries: int = 3
   ):
       """Save events with automatic retry on conflicts."""
       for attempt in range(max_retries):
           try:
               # Get current version
               current_version = await self._get_aggregate_version(aggregate_id)
               
               if current_version != expected_version:
                   # Someone else updated, reload and retry
                   logger.info(
                       f"Version mismatch: expected {expected_version}, "
                       f"got {current_version}. Retrying..."
                   )
                   expected_version = current_version
                   continue
               
               # Try to save
               await self.save_events(aggregate_id, events, expected_version)
               return  # Success
               
           except ConcurrencyException as e:
               if attempt == max_retries - 1:
                   raise  # Final attempt failed
               
               # Wait before retry
               await asyncio.sleep(0.1 * (2 ** attempt))
       
       raise ConcurrencyException(f"Failed after {max_retries} attempts")
   ```

2. **Use ETags for Cosmos DB:**
   ```python
   async def save_with_etag(self, item: dict, etag: str = None):
       """Save with ETag for concurrency control."""
       options = {}
       if etag:
           options["if_match"] = etag
       
       try:
           response = await self.container.upsert_item(
               body=item,
               partition_key=item["partitionKey"],
               **options
           )
           return response
       except CosmosHttpResponseError as e:
           if e.status_code == 412:  # Precondition Failed
               raise ConcurrencyException("ETag mismatch")
           raise
   ```

### 2. Projection Lag

**Symptoms:**
- Query results showing old data
- Projections behind event stream
- Increasing checkpoint lag

**Diagnosis:**

```python
# Monitor projection lag
async def check_projection_lag():
    # Get latest event position
    latest_event = await event_store.get_latest_event()
    latest_position = latest_event.metadata.sequence_number
    
    # Get projection checkpoints
    checkpoints = await checkpoint_store.get_all_checkpoints()
    
    for checkpoint in checkpoints:
        lag = latest_position - checkpoint.position
        lag_time = datetime.utcnow() - checkpoint.timestamp
        
        print(f"\nProjection: {checkpoint.projection_name}")
        print(f"Position: {checkpoint.position}")
        print(f"Events behind: {lag}")
        print(f"Time behind: {lag_time}")
        
        if lag > 1000:
            print("⚠️  HIGH LAG DETECTED")
```

**Solutions:**

1. **Optimize Projection Processing:**
   ```python
   class OptimizedProjection(Projection):
       async def _process_events_batch(self, events: List[DomainEvent]):
           """Process events in batch for efficiency."""
           # Group events by aggregate
           events_by_aggregate = defaultdict(list)
           for event in events:
               events_by_aggregate[event.metadata.aggregate_id].append(event)
           
           # Process in parallel
           tasks = []
           for aggregate_id, aggregate_events in events_by_aggregate.items():
               task = self._process_aggregate_events(aggregate_id, aggregate_events)
               tasks.append(task)
           
           # Limit concurrency
           semaphore = asyncio.Semaphore(10)
           
           async def process_with_limit(task):
               async with semaphore:
                   return await task
           
           await asyncio.gather(*[process_with_limit(t) for t in tasks])
   ```

2. **Add Projection Scaling:**
   ```python
   class ScalableProjectionManager:
       def __init__(self, num_workers: int = 4):
           self.num_workers = num_workers
           self.workers = []
           
       async def start(self):
           """Start multiple projection workers."""
           # Partition event stream
           partitions = self._calculate_partitions()
           
           for i in range(self.num_workers):
               worker = ProjectionWorker(
                   worker_id=i,
                   partitions=partitions[i],
                   event_store=self.event_store
               )
               self.workers.append(worker)
               asyncio.create_task(worker.start())
       
       def _calculate_partitions(self):
           """Distribute aggregates across workers."""
           # Hash-based partitioning
           partitions = [[] for _ in range(self.num_workers)]
           
           # This would query all aggregate IDs
           aggregate_ids = self.get_all_aggregate_ids()
           
           for agg_id in aggregate_ids:
               partition = hash(agg_id) % self.num_workers
               partitions[partition].append(agg_id)
           
           return partitions
   ```

### 3. Event Deserialization Errors

**Symptoms:**
- "Unknown event type" errors
- Failed to deserialize event data
- Missing event handlers

**Solutions:**

1. **Implement Event Registry:**
   ```python
   class EventRegistry:
       """Central registry for all event types."""
       
       def __init__(self):
           self._event_types: Dict[str, Type[DomainEvent]] = {}
           self._register_all_events()
       
       def _register_all_events(self):
           """Register all known event types."""
           # Auto-discover events
           import inspect
           import domain.events
           
           for name, obj in inspect.getmembers(domain.events):
               if (inspect.isclass(obj) and 
                   issubclass(obj, DomainEvent) and 
                   obj != DomainEvent):
                   self._event_types[name] = obj
       
       def get_event_class(self, event_type: str) -> Type[DomainEvent]:
           """Get event class by name."""
           if event_type not in self._event_types:
               raise UnknownEventTypeError(f"Unknown event type: {event_type}")
           
           return self._event_types[event_type]
       
       def deserialize_event(self, event_data: dict) -> DomainEvent:
           """Deserialize event from dictionary."""
           event_type = event_data["metadata"]["event_type"]
           event_class = self.get_event_class(event_type)
           
           try:
               return event_class.from_dict(event_data)
           except Exception as e:
               logger.error(f"Failed to deserialize {event_type}: {str(e)}")
               raise EventDeserializationError(
                   f"Cannot deserialize {event_type}: {str(e)}"
               )
   ```

## 🔄 Saga Pattern Issues

### 1. Saga Timeout and Stuck Sagas

**Symptoms:**
- Sagas not completing
- Steps timing out repeatedly
- Saga status stuck in "RUNNING"

**Diagnosis:**

```python
# Find stuck sagas
async def find_stuck_sagas():
    persistence = SagaPersistence(connection_string)
    
    # Get all running sagas
    running_sagas = await persistence.list_sagas(status="RUNNING")
    
    stuck_sagas = []
    for saga in running_sagas:
        # Check if saga exceeded timeout
        elapsed = datetime.utcnow() - saga.created_at
        if elapsed.total_seconds() > saga.timeout_seconds:
            stuck_sagas.append({
                "saga_id": saga.saga_id,
                "type": saga.saga_type,
                "current_step": saga.current_step,
                "elapsed_minutes": elapsed.total_seconds() / 60,
                "created_at": saga.created_at
            })
    
    print(f"Found {len(stuck_sagas)} stuck sagas:")
    for saga in stuck_sagas:
        print(f"\nSaga ID: {saga['saga_id']}")
        print(f"Type: {saga['type']}")
        print(f"Stuck at: {saga['current_step']}")
        print(f"Running for: {saga['elapsed_minutes']:.1f} minutes")
```

**Solutions:**

1. **Implement Saga Timeout Handler:**
   ```python
   class SagaTimeoutHandler:
       async def handle_timeouts(self):
           """Check and handle saga timeouts."""
           while True:
               try:
                   stuck_sagas = await self.find_stuck_sagas()
                   
                   for saga in stuck_sagas:
                       logger.warning(f"Handling timeout for saga {saga.saga_id}")
                       
                       # Mark as failed
                       saga.status = "TIMEOUT"
                       saga.error = f"Saga timed out at step {saga.current_step}"
                       await self.persistence.save_saga(saga)
                       
                       # Start compensation
                       await self.orchestrator.compensate_saga(saga)
                   
                   await asyncio.sleep(60)  # Check every minute
                   
               except Exception as e:
                   logger.error(f"Error in timeout handler: {str(e)}")
                   await asyncio.sleep(60)
   ```

2. **Add Step-Level Health Checks:**
   ```python
   async def check_participant_health(self, participant: str) -> bool:
       """Check if participant service is healthy."""
       health_endpoints = {
           "OrderService": "http://order-service:8000/health",
           "PaymentService": "http://payment-service:8000/health",
           "InventoryService": "http://inventory-service:8000/health"
       }
       
       endpoint = health_endpoints.get(participant)
       if not endpoint:
           return True  # Unknown participant, assume healthy
       
       try:
           async with httpx.AsyncClient() as client:
               response = await client.get(endpoint, timeout=5.0)
               return response.status_code == 200
       except:
           return False
   ```

### 2. Compensation Failures

**Symptoms:**
- Compensation steps failing
- Inconsistent system state
- "COMPENSATING" status stuck

**Solutions:**

1. **Implement Compensation Retry with Backoff:**
   ```python
   class CompensationManager:
       async def execute_compensation_with_retry(
           self,
           saga: SagaInstance,
           compensation_step: SagaStep
       ):
           """Execute compensation with advanced retry logic."""
           max_attempts = 5
           base_delay = 1
           
           for attempt in range(max_attempts):
               try:
                   # Check if already compensated (idempotency)
                   if await self._is_already_compensated(saga, compensation_step):
                       logger.info(f"Step {compensation_step.name} already compensated")
                       return True
                   
                   # Execute compensation
                   result = await self._execute_compensation(saga, compensation_step)
                   
                   if result.success:
                       await self._mark_compensated(saga, compensation_step)
                       return True
                   
                   # Check if error is permanent
                   if self._is_permanent_error(result.error):
                       logger.error(
                           f"Permanent error in compensation: {result.error}"
                       )
                       await self._escalate_to_manual_intervention(
                           saga, 
                           compensation_step, 
                           result.error
                       )
                       return False
                   
               except Exception as e:
                   logger.error(f"Compensation attempt {attempt + 1} failed: {str(e)}")
               
               # Exponential backoff with jitter
               delay = base_delay * (2 ** attempt) + random.uniform(0, 1)
               await asyncio.sleep(delay)
           
           # All attempts failed
           await self._escalate_to_manual_intervention(
               saga,
               compensation_step,
               "Max retry attempts exceeded"
           )
           return False
   ```

### 3. Distributed Tracing Issues

**Symptoms:**
- Cannot trace saga execution flow
- Missing correlation between services
- Incomplete traces in Jaeger

**Solutions:**

1. **Implement Proper Trace Propagation:**
   ```python
   class TracingMiddleware:
       def __init__(self):
           self.tracer = trace.get_tracer(__name__)
       
       async def __call__(self, request: Request, call_next):
           # Extract trace context from headers
           trace_parent = request.headers.get("traceparent")
           
           # Create or continue span
           if trace_parent:
               ctx = TraceContextTextMapPropagator().extract(
                   carrier={"traceparent": trace_parent}
               )
               with self.tracer.start_as_current_span(
                   f"{request.method} {request.url.path}",
                   context=ctx
               ) as span:
                   # Add attributes
                   span.set_attribute("http.method", request.method)
                   span.set_attribute("http.url", str(request.url))
                   
                   # Process request
                   response = await call_next(request)
                   
                   # Add response attributes
                   span.set_attribute("http.status_code", response.status_code)
                   
                   return response
           else:
               # Start new trace
               with self.tracer.start_as_current_span(
                   f"{request.method} {request.url.path}"
               ) as span:
                   response = await call_next(request)
                   return response
   ```

## 🔧 Performance Issues

### 1. High Message Processing Latency

**Symptoms:**
- Slow message processing
- Queue depth increasing
- Timeout errors

**Diagnosis:**

```python
# Profile message processing
import cProfile
import pstats

async def profile_message_processing():
    profiler = cProfile.Profile()
    
    # Profile 100 messages
    profiler.enable()
    
    for i in range(100):
        message = create_test_message(i)
        await process_message(message)
    
    profiler.disable()
    
    # Print statistics
    stats = pstats.Stats(profiler)
    stats.sort_stats('cumulative')
    stats.print_stats(20)  # Top 20 functions
```

**Solutions:**

1. **Implement Connection Pooling:**
   ```python
   class ConnectionPool:
       def __init__(self, create_connection, max_size=10):
           self._create_connection = create_connection
           self._pool = asyncio.Queue(maxsize=max_size)
           self._size = 0
           self._max_size = max_size
       
       async def acquire(self):
           """Acquire connection from pool."""
           try:
               # Try to get from pool
               conn = self._pool.get_nowait()
           except asyncio.QueueEmpty:
               # Create new if under limit
               if self._size < self._max_size:
                   conn = await self._create_connection()
                   self._size += 1
               else:
                   # Wait for available connection
                   conn = await self._pool.get()
           
           # Verify connection is healthy
           if not await self._is_healthy(conn):
               await self._close_connection(conn)
               conn = await self._create_connection()
           
           return conn
       
       async def release(self, conn):
           """Return connection to pool."""
           try:
               self._pool.put_nowait(conn)
           except asyncio.QueueFull:
               # Pool full, close connection
               await self._close_connection(conn)
               self._size -= 1
   ```

## 📊 Monitoring and Debugging

### Enable Detailed Logging

```python
# Configure comprehensive logging
import logging
import sys

# Set up structured logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('integration.log'),
        logging.StreamHandler(sys.stdout)
    ]
)

# Enable specific loggers
logging.getLogger('azure.servicebus').setLevel(logging.DEBUG)
logging.getLogger('azure.cosmos').setLevel(logging.INFO)
logging.getLogger('esb').setLevel(logging.DEBUG)
logging.getLogger('saga').setLevel(logging.DEBUG)
```

### Debug Mode for Development

```python
class DebugMode:
    """Enable debug mode for detailed diagnostics."""
    
    def __init__(self):
        self.enabled = os.getenv("DEBUG_MODE", "false").lower() == "true"
    
    def log_message_flow(self, message: Message, stage: str):
        if not self.enabled:
            return
        
        print(f"\n{'='*50}")
        print(f"MESSAGE FLOW DEBUG - {stage}")
        print(f"Message ID: {message.id}")
        print(f"Type: {message.message_type}")
        print(f"Correlation ID: {message.correlation_id}")
        print(f"Payload: {json.dumps(message.payload, indent=2)}")
        print(f"Headers: {json.dumps(message.headers, indent=2)}")
        print(f"{'='*50}\n")
    
    def log_saga_transition(self, saga: SagaInstance, from_step: str, to_step: str):
        if not self.enabled:
            return
        
        print(f"\n{'='*50}")
        print(f"SAGA TRANSITION DEBUG")
        print(f"Saga ID: {saga.saga_id}")
        print(f"From: {from_step} -> To: {to_step}")
        print(f"Current Status: {saga.status}")
        print(f"Data: {json.dumps(saga.data, indent=2)}")
        print(f"{'='*50}\n")
```

## 🚑 Emergency Procedures

### Service Completely Down

1. **Check Service Health:**
   ```bash
   # Check all containers
   docker-compose ps
   
   # Check specific service logs
   docker-compose logs -f saga-orchestrator
   docker-compose logs -f order-service
   ```

2. **Restart Services:**
   ```bash
   # Restart specific service
   docker-compose restart saga-orchestrator
   
   # Full restart
   docker-compose down
   docker-compose up -d
   ```

3. **Emergency Circuit Breaker:**
   ```python
   # Disable problematic route temporarily
   async def emergency_disable_route(route_name: str):
       settings.routing_rules = [
           r for r in settings.routing_rules 
           if r['name'] != route_name
       ]
       
       logger.warning(f"Emergency: Disabled route {route_name}")
   ```

## 🎯 Quick Reference

| Issue | Quick Check | Quick Fix |
|-------|-------------|-----------|
| Messages not routing | Check routing rules | Verify message format |
| Event store conflicts | Check version numbers | Implement retry logic |
| Projection lag | Check checkpoint position | Scale projection workers |
| Saga timeout | Check participant health | Increase timeout/retry |
| High latency | Profile code | Add connection pooling |
| Compensation fails | Check idempotency | Add manual intervention |

Remember: **When debugging distributed systems, always check logs across all services, verify network connectivity, and ensure proper error propagation!**