# Exercise 3: Event-Driven Serverless System ⭐⭐⭐ (Part 2)

## 🔄 Part 2: Durable Functions Orchestration

### Step 4: Create Durable Function for Order Fulfillment

**Copilot Prompt Suggestion:**
```python
# Create FulfillmentOrchestrator/__init__.py Durable Function that:
# - Orchestrates multi-step order fulfillment
# - Implements saga pattern for distributed transactions
# - Handles compensation logic for failures
# - Manages long-running workflows
# - Includes human approval steps
# - Implements timeout and retry policies
```

**Expected Output:**
```python
import logging
import json
from datetime import datetime, timedelta
from typing import Dict, Any, List
import azure.functions as func
import azure.durable_functions as df

def orchestrator_function(context: df.DurableOrchestrationContext):
    """
    Orchestrate order fulfillment workflow with saga pattern
    """
    order_data = context.get_input()
    logger = context.create_replay_safe_logger(logging.INFO)
    
    logger.info(f"Starting fulfillment for order: {order_data['order_id']}")
    
    # Initialize saga state
    saga_state = {
        'order_id': order_data['order_id'],
        'completed_steps': [],
        'compensation_needed': False
    }
    
    try:
        # Step 1: Validate payment
        payment_result = yield context.call_activity(
            'ValidatePayment',
            order_data
        )
        saga_state['completed_steps'].append('payment_validated')
        
        if not payment_result['success']:
            raise Exception("Payment validation failed")
        
        # Step 2: Reserve inventory with timeout
        inventory_timeout = 300  # 5 minutes
        inventory_task = context.call_activity(
            'ReserveInventory',
            order_data['items']
        )
        
        inventory_result = yield context.create_timer(
            context.current_utc_datetime + timedelta(seconds=inventory_timeout)
        ).add(inventory_task)
        
        if inventory_result == inventory_task:
            saga_state['completed_steps'].append('inventory_reserved')
        else:
            raise Exception("Inventory reservation timeout")
        
        # Step 3: Check for high-value orders requiring approval
        if order_data['total_amount'] > 5000:
            # Wait for human approval
            approval_event = yield context.wait_for_external_event(
                'ApprovalEvent',
                timeout=timedelta(hours=24)
            )
            
            if not approval_event or not approval_event.get('approved'):
                raise Exception("Order approval denied or timeout")
        
        # Step 4: Process shipment
        shipment_result = yield context.call_activity(
            'ProcessShipment',
            {
                'order_id': order_data['order_id'],
                'items': order_data['items'],
                'shipping_address': order_data['shipping_address']
            }
        )
        saga_state['completed_steps'].append('shipment_processed')
        
        # Step 5: Send notifications in parallel
        notification_tasks = []
        
        # Email notification
        notification_tasks.append(
            context.call_activity(
                'SendEmailNotification',
                {
                    'customer_id': order_data['customer_id'],
                    'order_id': order_data['order_id'],
                    'tracking_number': shipment_result['tracking_number']
                }
            )
        )
        
        # SMS notification
        notification_tasks.append(
            context.call_activity(
                'SendSMSNotification',
                {
                    'customer_id': order_data['customer_id'],
                    'order_id': order_data['order_id'],
                    'status': 'shipped'
                }
            )
        )
        
        # Push notification
        notification_tasks.append(
            context.call_activity(
                'SendPushNotification',
                {
                    'customer_id': order_data['customer_id'],
                    'order_id': order_data['order_id'],
                    'message': 'Your order has been shipped!'
                }
            )
        )
        
        # Wait for all notifications
        yield context.task_all(notification_tasks)
        saga_state['completed_steps'].append('notifications_sent')
        
        # Step 6: Update order status
        yield context.call_activity(
            'UpdateOrderStatus',
            {
                'order_id': order_data['order_id'],
                'status': 'fulfilled',
                'tracking_number': shipment_result['tracking_number']
            }
        )
        
        # Success - return fulfillment details
        return {
            'success': True,
            'order_id': order_data['order_id'],
            'tracking_number': shipment_result['tracking_number'],
            'estimated_delivery': shipment_result['estimated_delivery'],
            'completed_at': context.current_utc_datetime.isoformat()
        }
        
    except Exception as e:
        logger.error(f"Fulfillment failed: {str(e)}")
        saga_state['compensation_needed'] = True
        
        # Execute compensation logic
        yield context.call_sub_orchestrator(
            'CompensationOrchestrator',
            saga_state
        )
        
        # Update order status to failed
        yield context.call_activity(
            'UpdateOrderStatus',
            {
                'order_id': order_data['order_id'],
                'status': 'fulfillment_failed',
                'error': str(e)
            }
        )
        
        return {
            'success': False,
            'order_id': order_data['order_id'],
            'error': str(e),
            'compensated': True
        }

# Activity Functions
async def validate_payment(order_data: Dict[str, Any]) -> Dict[str, Any]:
    """Validate payment for the order"""
    # Simulate payment validation
    return {
        'success': True,
        'transaction_id': f"TXN-{order_data['order_id']}",
        'amount_charged': order_data['total_amount']
    }

async def reserve_inventory(items: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Reserve inventory for order items"""
    reserved_items = []
    
    for item in items:
        # Call inventory service to reserve
        reserved = {
            'product_id': item['product_id'],
            'quantity': item['quantity'],
            'reservation_id': f"RES-{item['product_id']}-{datetime.utcnow().timestamp()}"
        }
        reserved_items.append(reserved)
    
    return {
        'success': True,
        'reservations': reserved_items
    }

async def process_shipment(shipment_data: Dict[str, Any]) -> Dict[str, Any]:
    """Process shipment with carrier"""
    # Simulate shipment processing
    import random
    
    carriers = ['FedEx', 'UPS', 'DHL', 'USPS']
    selected_carrier = random.choice(carriers)
    
    return {
        'success': True,
        'carrier': selected_carrier,
        'tracking_number': f"{selected_carrier}-{shipment_data['order_id']}-{random.randint(10000, 99999)}",
        'estimated_delivery': (datetime.utcnow() + timedelta(days=3)).isoformat(),
        'shipment_cost': random.uniform(5.99, 29.99)
    }

# Compensation Orchestrator
def compensation_orchestrator_function(context: df.DurableOrchestrationContext):
    """Handle compensation for failed transactions"""
    saga_state = context.get_input()
    completed_steps = saga_state['completed_steps']
    
    compensation_tasks = []
    
    # Compensate in reverse order
    if 'shipment_processed' in completed_steps:
        compensation_tasks.append(
            context.call_activity('CancelShipment', saga_state['order_id'])
        )
    
    if 'inventory_reserved' in completed_steps:
        compensation_tasks.append(
            context.call_activity('ReleaseInventory', saga_state['order_id'])
        )
    
    if 'payment_validated' in completed_steps:
        compensation_tasks.append(
            context.call_activity('RefundPayment', saga_state['order_id'])
        )
    
    # Execute all compensation tasks
    if compensation_tasks:
        yield context.task_all(compensation_tasks)
    
    return {'compensation_completed': True}

# Register functions
main = df.Orchestrator.create(orchestrator_function)
compensation_main = df.Orchestrator.create(compensation_orchestrator_function)
```

### Step 5: Create Event Hub Processor for Real-time Analytics

**Copilot Prompt Suggestion:**
```python
# Create AnalyticsProcessor/__init__.py that:
# - Processes events from Event Hub
# - Implements batch processing
# - Calculates real-time metrics
# - Detects anomalies
# - Sends data to Azure Data Explorer
# - Implements checkpointing
```

**Expected Output:**
```python
import os
import json
import logging
from typing import List
from datetime import datetime
import azure.functions as func
from azure.eventhub import EventData
from azure.kusto.data import KustoClient, KustoConnectionStringBuilder
from azure.kusto.ingest import QueuedIngestClient, IngestionProperties
from azure.identity import DefaultAzureCredential
import numpy as np
from collections import defaultdict

logger = logging.getLogger(__name__)

# Initialize Kusto client
kusto_cluster = os.environ['KUSTO_CLUSTER_URL']
kusto_database = os.environ['KUSTO_DATABASE']
kusto_connection = KustoConnectionStringBuilder.with_aad_managed_service_identity_authentication(
    kusto_cluster
)
kusto_ingest_client = QueuedIngestClient(kusto_connection)

# Metrics aggregator
class MetricsAggregator:
    def __init__(self):
        self.metrics = defaultdict(lambda: {
            'count': 0,
            'sum': 0,
            'min': float('inf'),
            'max': float('-inf'),
            'values': []
        })
    
    def add_metric(self, name: str, value: float, timestamp: datetime):
        metric = self.metrics[name]
        metric['count'] += 1
        metric['sum'] += value
        metric['min'] = min(metric['min'], value)
        metric['max'] = max(metric['max'], value)
        metric['values'].append(value)
        metric['last_updated'] = timestamp
    
    def get_statistics(self, name: str) -> dict:
        if name not in self.metrics:
            return None
        
        metric = self.metrics[name]
        values = np.array(metric['values'])
        
        return {
            'name': name,
            'count': metric['count'],
            'sum': metric['sum'],
            'mean': np.mean(values),
            'median': np.median(values),
            'std': np.std(values),
            'min': metric['min'],
            'max': metric['max'],
            'p95': np.percentile(values, 95),
            'p99': np.percentile(values, 99)
        }

aggregator = MetricsAggregator()

async def main(events: List[EventData]) -> None:
    """Process analytics events from Event Hub"""
    
    logger.info(f"Processing batch of {len(events)} events")
    
    processed_events = []
    anomalies = []
    
    for event in events:
        try:
            # Parse event data
            event_body = event.body_as_json()
            event_type = event_body.get('event_type')
            timestamp = datetime.fromisoformat(event_body.get('timestamp'))
            
            # Process based on event type
            if event_type == 'analytics.product_viewed':
                process_view_event(event_body, timestamp)
            
            elif event_type == 'analytics.product_purchased':
                process_purchase_event(event_body, timestamp)
                
            elif event_type == 'analytics.recommendation_generated':
                process_recommendation_event(event_body, timestamp)
            
            # Detect anomalies
            anomaly = detect_anomalies(event_body, event_type)
            if anomaly:
                anomalies.append(anomaly)
            
            # Prepare for ingestion
            processed_event = {
                'EventId': event_body.get('event_id'),
                'EventType': event_type,
                'Timestamp': timestamp,
                'UserId': event_body.get('user_id'),
                'SessionId': event_body.get('session_id'),
                'ProductId': event_body.get('product_id'),
                'Value': event_body.get('value', 0),
                'Properties': json.dumps(event_body.get('properties', {})),
                'ProcessedAt': datetime.utcnow()
            }
            processed_events.append(processed_event)
            
        except Exception as e:
            logger.error(f"Error processing event: {str(e)}", exc_info=True)
    
    # Batch ingest to Kusto
    if processed_events:
        await ingest_to_kusto(processed_events, 'AnalyticsEvents')
    
    # Process anomalies
    if anomalies:
        await process_anomalies(anomalies)
    
    # Calculate and store real-time metrics
    await calculate_realtime_metrics()

def process_view_event(event_data: dict, timestamp: datetime):
    """Process product view events"""
    product_id = event_data.get('product_id')
    
    # Track view metrics
    aggregator.add_metric(f'views_{product_id}', 1, timestamp)
    aggregator.add_metric('total_views', 1, timestamp)
    
    # Track session metrics
    session_id = event_data.get('session_id')
    aggregator.add_metric(f'session_{session_id}_views', 1, timestamp)

def process_purchase_event(event_data: dict, timestamp: datetime):
    """Process purchase events"""
    product_id = event_data.get('product_id')
    value = event_data.get('value', 0)
    
    # Track purchase metrics
    aggregator.add_metric(f'purchases_{product_id}', 1, timestamp)
    aggregator.add_metric(f'revenue_{product_id}', value, timestamp)
    aggregator.add_metric('total_purchases', 1, timestamp)
    aggregator.add_metric('total_revenue', value, timestamp)
    
    # Calculate conversion rate
    views = aggregator.get_statistics(f'views_{product_id}')
    purchases = aggregator.get_statistics(f'purchases_{product_id}')
    
    if views and purchases:
        conversion_rate = purchases['count'] / views['count']
        aggregator.add_metric(f'conversion_rate_{product_id}', conversion_rate, timestamp)

def process_recommendation_event(event_data: dict, timestamp: datetime):
    """Process recommendation events"""
    algorithm = event_data.get('algorithm')
    confidence_scores = event_data.get('confidence_scores', [])
    
    if confidence_scores:
        avg_confidence = np.mean(confidence_scores)
        aggregator.add_metric(f'recommendation_confidence_{algorithm}', avg_confidence, timestamp)

def detect_anomalies(event_data: dict, event_type: str) -> dict:
    """Detect anomalies in event data"""
    anomaly = None
    
    # Example: Detect unusual purchase amounts
    if event_type == 'analytics.product_purchased':
        value = event_data.get('value', 0)
        product_id = event_data.get('product_id')
        
        # Get historical statistics
        stats = aggregator.get_statistics(f'revenue_{product_id}')
        
        if stats and stats['count'] > 10:
            # Check if value is > 3 standard deviations from mean
            z_score = (value - stats['mean']) / (stats['std'] + 1e-10)
            
            if abs(z_score) > 3:
                anomaly = {
                    'type': 'unusual_purchase_amount',
                    'product_id': product_id,
                    'value': value,
                    'z_score': z_score,
                    'mean': stats['mean'],
                    'std': stats['std'],
                    'timestamp': event_data.get('timestamp')
                }
    
    # Example: Detect rapid view spikes
    elif event_type == 'analytics.product_viewed':
        product_id = event_data.get('product_id')
        current_time = datetime.fromisoformat(event_data.get('timestamp'))
        
        # Check view rate in last minute
        recent_views = aggregator.get_statistics(f'views_{product_id}')
        if recent_views and recent_views['count'] > 100:  # Spike threshold
            anomaly = {
                'type': 'view_spike',
                'product_id': product_id,
                'view_count': recent_views['count'],
                'timestamp': current_time.isoformat()
            }
    
    return anomaly

async def ingest_to_kusto(data: List[dict], table_name: str):
    """Ingest data to Azure Data Explorer"""
    try:
        # Convert to CSV format for ingestion
        import csv
        import io
        
        output = io.StringIO()
        if data:
            writer = csv.DictWriter(output, fieldnames=data[0].keys())
            writer.writeheader()
            writer.writerows(data)
        
        # Set up ingestion properties
        ingestion_props = IngestionProperties(
            database=kusto_database,
            table=table_name,
            data_format='csv',
            report_level='FailuresAndSuccesses'
        )
        
        # Ingest data
        kusto_ingest_client.ingest_from_stream(
            io.BytesIO(output.getvalue().encode('utf-8')),
            ingestion_properties=ingestion_props
        )
        
        logger.info(f"Ingested {len(data)} records to {table_name}")
        
    except Exception as e:
        logger.error(f"Failed to ingest to Kusto: {str(e)}", exc_info=True)

async def process_anomalies(anomalies: List[dict]):
    """Process detected anomalies"""
    # Send to alert system
    for anomaly in anomalies:
        logger.warning(f"Anomaly detected: {anomaly}")
        
        # Could send to Service Bus, Event Grid, or other alerting system
        # await send_alert(anomaly)

async def calculate_realtime_metrics():
    """Calculate and store real-time metrics"""
    metrics_to_store = []
    
    # Get all current metrics
    for metric_name in list(aggregator.metrics.keys()):
        stats = aggregator.get_statistics(metric_name)
        if stats:
            metric_record = {
                'MetricName': metric_name,
                'Timestamp': datetime.utcnow(),
                'Count': stats['count'],
                'Sum': stats['sum'],
                'Mean': stats['mean'],
                'Median': stats['median'],
                'Min': stats['min'],
                'Max': stats['max'],
                'StdDev': stats['std'],
                'P95': stats['p95'],
                'P99': stats['p99']
            }
            metrics_to_store.append(metric_record)
    
    # Store metrics
    if metrics_to_store:
        await ingest_to_kusto(metrics_to_store, 'RealtimeMetrics')
    
    # Clear old data to prevent memory growth
    # In production, implement sliding window
    aggregator.metrics.clear()
```

## 🔗 Part 3: System Integration

### Step 6: Create Event Grid Integration

**Copilot Prompt Suggestion:**
```python
# Create shared/event_publisher.py that:
# - Publishes events to Event Grid
# - Implements retry logic with exponential backoff
# - Batches events for efficiency
# - Handles different event types
# - Includes telemetry
```

**Expected Output:**
```python
import os
import json
import logging
from typing import List, Dict, Any
from datetime import datetime
import asyncio
from azure.eventgrid import EventGridPublisherClient, EventGridEvent
from azure.core.credentials import AzureKeyCredential
from azure.core.exceptions import AzureError
import backoff

logger = logging.getLogger(__name__)

class EventPublisher:
    def __init__(self):
        self.topic_endpoint = os.environ['EVENT_GRID_TOPIC_ENDPOINT']
        self.topic_key = os.environ['EVENT_GRID_TOPIC_KEY']
        self.client = EventGridPublisherClient(
            self.topic_endpoint,
            AzureKeyCredential(self.topic_key)
        )
        self.event_buffer = []
        self.buffer_size = 100
        self.flush_interval = 5  # seconds
        self._start_background_flush()
    
    def _start_background_flush(self):
        """Start background task to flush events periodically"""
        asyncio.create_task(self._periodic_flush())
    
    async def _periodic_flush(self):
        """Periodically flush event buffer"""
        while True:
            await asyncio.sleep(self.flush_interval)
            if self.event_buffer:
                await self.flush()
    
    @backoff.on_exception(
        backoff.expo,
        AzureError,
        max_tries=3,
        max_time=30
    )
    async def publish_event(
        self,
        event_type: str,
        subject: str,
        data: Dict[str, Any],
        data_version: str = "1.0"
    ) -> None:
        """Publish a single event to Event Grid"""
        event = EventGridEvent(
            event_type=event_type,
            subject=subject,
            data=data,
            data_version=data_version
        )
        
        # Add to buffer
        self.event_buffer.append(event)
        
        # Flush if buffer is full
        if len(self.event_buffer) >= self.buffer_size:
            await self.flush()
    
    async def publish_batch(
        self,
        events: List[Dict[str, Any]]
    ) -> None:
        """Publish multiple events as a batch"""
        event_objects = []
        
        for event_data in events:
            event = EventGridEvent(
                event_type=event_data['event_type'],
                subject=event_data['subject'],
                data=event_data['data'],
                data_version=event_data.get('data_version', '1.0')
            )
            event_objects.append(event)
        
        # Send batch
        try:
            await self.client.send(event_objects)
            logger.info(f"Published batch of {len(event_objects)} events")
        except AzureError as e:
            logger.error(f"Failed to publish events: {str(e)}")
            raise
    
    async def flush(self) -> None:
        """Flush event buffer"""
        if not self.event_buffer:
            return
        
        events_to_send = self.event_buffer.copy()
        self.event_buffer.clear()
        
        try:
            await self.client.send(events_to_send)
            logger.info(f"Flushed {len(events_to_send)} events")
        except AzureError as e:
            # Re-add events to buffer on failure
            self.event_buffer.extend(events_to_send)
            logger.error(f"Failed to flush events: {str(e)}")
            raise

# Event type constants
class EventTypes:
    # Order events
    ORDER_CREATED = "Order.Created"
    ORDER_UPDATED = "Order.Updated"
    ORDER_CANCELLED = "Order.Cancelled"
    ORDER_FULFILLED = "Order.Fulfilled"
    
    # Inventory events
    INVENTORY_UPDATED = "Inventory.Updated"
    INVENTORY_LOW = "Inventory.LowStock"
    INVENTORY_DEPLETED = "Inventory.Depleted"
    
    # Customer events
    CUSTOMER_REGISTERED = "Customer.Registered"
    CUSTOMER_UPDATED = "Customer.Updated"
    
    # System events
    HEALTH_CHECK = "System.HealthCheck"
    ERROR_OCCURRED = "System.Error"

# Event factory functions
def create_order_event(order_data: Dict[str, Any]) -> Dict[str, Any]:
    """Create order event"""
    return {
        'event_type': EventTypes.ORDER_CREATED,
        'subject': f"orders/{order_data['order_id']}",
        'data': {
            'order_id': order_data['order_id'],
            'customer_id': order_data['customer_id'],
            'total_amount': order_data['total_amount'],
            'items': order_data['items'],
            'created_at': datetime.utcnow().isoformat()
        }
    }

def create_inventory_event(
    product_id: str,
    current_stock: int,
    previous_stock: int
) -> Dict[str, Any]:
    """Create inventory event"""
    event_type = EventTypes.INVENTORY_UPDATED
    
    if current_stock == 0:
        event_type = EventTypes.INVENTORY_DEPLETED
    elif current_stock < 10:
        event_type = EventTypes.INVENTORY_LOW
    
    return {
        'event_type': event_type,
        'subject': f"inventory/{product_id}",
        'data': {
            'product_id': product_id,
            'current_stock': current_stock,
            'previous_stock': previous_stock,
            'change': current_stock - previous_stock,
            'timestamp': datetime.utcnow().isoformat()
        }
    }

# Singleton instance
event_publisher = EventPublisher()
```

### Step 7: Deploy Complete System

**Copilot Prompt Suggestion:**
```bash
# Create deployment script that:
# - Creates all Azure resources (Event Grid, Service Bus, etc.)
# - Deploys Azure Functions
# - Configures event routing
# - Sets up monitoring
# - Validates the deployment
# File: scripts/deploy-event-system.sh
```

**Expected Output:**
```bash
#!/bin/bash
set -euo pipefail

# Configuration
RESOURCE_GROUP="rg-workshop-module12"
LOCATION="eastus2"
FUNCTION_APP_NAME="func-product-events-${RANDOM}"
STORAGE_ACCOUNT="stprodevevents${RANDOM}"
APP_INSIGHTS_NAME="appi-product-events"
EVENT_GRID_TOPIC="evgt-product-events"
SERVICE_BUS_NAMESPACE="sb-product-events-${RANDOM}"
EVENT_HUB_NAMESPACE="evh-product-events-${RANDOM}"
COSMOS_ACCOUNT="cosmos-product-events-${RANDOM}"

echo "Deploying Event-Driven System..."

# Create Storage Account
echo "Creating Storage Account..."
az storage account create \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --sku Standard_LRS

# Create Application Insights
echo "Creating Application Insights..."
az monitor app-insights component create \
    --app "$APP_INSIGHTS_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION"

APP_INSIGHTS_KEY=$(az monitor app-insights component show \
    --app "$APP_INSIGHTS_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query instrumentationKey -o tsv)

# Create Function App
echo "Creating Function App..."
az functionapp create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$FUNCTION_APP_NAME" \
    --storage-account "$STORAGE_ACCOUNT" \
    --consumption-plan-location "$LOCATION" \
    --runtime python \
    --runtime-version 3.11 \
    --functions-version 4 \
    --app-insights "$APP_INSIGHTS_NAME"

# Create Event Grid Topic
echo "Creating Event Grid Topic..."
az eventgrid topic create \
    --name "$EVENT_GRID_TOPIC" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION"

EVENT_GRID_ENDPOINT=$(az eventgrid topic show \
    --name "$EVENT_GRID_TOPIC" \
    --resource-group "$RESOURCE_GROUP" \
    --query endpoint -o tsv)

EVENT_GRID_KEY=$(az eventgrid topic key list \
    --name "$EVENT_GRID_TOPIC" \
    --resource-group "$RESOURCE_GROUP" \
    --query key1 -o tsv)

# Create Service Bus
echo "Creating Service Bus..."
az servicebus namespace create \
    --name "$SERVICE_BUS_NAMESPACE" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --sku Standard

# Create queues
az servicebus queue create \
    --name "order-fulfillment" \
    --namespace-name "$SERVICE_BUS_NAMESPACE" \
    --resource-group "$RESOURCE_GROUP" \
    --enable-session true \
    --default-message-time-to-live P7D

az servicebus queue create \
    --name "order-processing-dlq" \
    --namespace-name "$SERVICE_BUS_NAMESPACE" \
    --resource-group "$RESOURCE_GROUP"

SERVICE_BUS_CONNECTION=$(az servicebus namespace authorization-rule keys list \
    --name RootManageSharedAccessKey \
    --namespace-name "$SERVICE_BUS_NAMESPACE" \
    --resource-group "$RESOURCE_GROUP" \
    --query primaryConnectionString -o tsv)

# Create Event Hub
echo "Creating Event Hub..."
az eventhubs namespace create \
    --name "$EVENT_HUB_NAMESPACE" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --sku Standard

az eventhubs eventhub create \
    --name "analytics-events" \
    --namespace-name "$EVENT_HUB_NAMESPACE" \
    --resource-group "$RESOURCE_GROUP" \
    --partition-count 4 \
    --retention-time 7

EVENT_HUB_CONNECTION=$(az eventhubs namespace authorization-rule keys list \
    --name RootManageSharedAccessKey \
    --namespace-name "$EVENT_HUB_NAMESPACE" \
    --resource-group "$RESOURCE_GROUP" \
    --query primaryConnectionString -o tsv)

# Create Cosmos DB
echo "Creating Cosmos DB..."
az cosmosdb create \
    --name "$COSMOS_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --locations regionName="$LOCATION" \
    --default-consistency-level Session

# Create database and containers
az cosmosdb sql database create \
    --account-name "$COSMOS_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --name "OrdersDB"

az cosmosdb sql container create \
    --account-name "$COSMOS_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --database-name "OrdersDB" \
    --name "Orders" \
    --partition-key-path "/customerId" \
    --throughput 400

COSMOS_CONNECTION=$(az cosmosdb keys list \
    --name "$COSMOS_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --type connection-strings \
    --query connectionStrings[0].connectionString -o tsv)

# Configure Function App settings
echo "Configuring Function App..."
az functionapp config appsettings set \
    --name "$FUNCTION_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --settings \
    "COSMOS_CONNECTION_STRING=$COSMOS_CONNECTION" \
    "SERVICE_BUS_CONNECTION_STRING=$SERVICE_BUS_CONNECTION" \
    "EVENT_GRID_TOPIC_ENDPOINT=$EVENT_GRID_ENDPOINT" \
    "EVENT_GRID_TOPIC_KEY=$EVENT_GRID_KEY" \
    "EVENT_HUB_CONNECTION_STRING=$EVENT_HUB_CONNECTION" \
    "APPLICATION_INSIGHTS_KEY=$APP_INSIGHTS_KEY" \
    "INVENTORY_API_URL=http://product-catalog-service.production"

# Deploy Function App
echo "Deploying Function App code..."
cd ../product-events-processor
func azure functionapp publish "$FUNCTION_APP_NAME" --python

# Create Event Grid Subscriptions
echo "Creating Event Grid subscriptions..."

# Order processor subscription
FUNCTION_URL="https://${FUNCTION_APP_NAME}.azurewebsites.net/runtime/webhooks/EventGrid?functionName=OrderProcessor"
FUNCTION_KEY=$(az functionapp keys list \
    --name "$FUNCTION_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query systemKeys.eventgrid_extension -o tsv)

az eventgrid event-subscription create \
    --name "order-processor-sub" \
    --source-resource-id "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.EventGrid/topics/$EVENT_GRID_TOPIC" \
    --endpoint "$FUNCTION_URL?code=$FUNCTION_KEY" \
    --included-event-types "Order.Created" "Order.Updated"

# Analytics processor subscription for Event Hub
az eventgrid event-subscription create \
    --name "analytics-eventhub-sub" \
    --source-resource-id "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.EventGrid/topics/$EVENT_GRID_TOPIC" \
    --endpoint-type eventhub \
    --endpoint "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.EventHub/namespaces/$EVENT_HUB_NAMESPACE/eventhubs/analytics-events" \
    --included-event-types "Analytics.*"

echo "✓ Event-Driven System deployed successfully!"
echo ""
echo "Resources created:"
echo "- Function App: $FUNCTION_APP_NAME"
echo "- Event Grid Topic: $EVENT_GRID_TOPIC"
echo "- Service Bus: $SERVICE_BUS_NAMESPACE"
echo "- Event Hub: $EVENT_HUB_NAMESPACE"
echo "- Cosmos DB: $COSMOS_ACCOUNT"
```

## 🧪 Part 4: Testing and Validation

### Step 8: Create End-to-End Tests

**Copilot Prompt Suggestion:**
```python
# Create tests/test_event_system.py that:
# - Tests complete order flow from API to fulfillment
# - Validates event routing
# - Tests error scenarios and compensation
# - Measures latency and throughput
# - Validates data consistency
```

**Expected Output:**
```python
import pytest
import asyncio
import json
import time
from datetime import datetime
from typing import Dict, Any, List
import httpx
from azure.eventgrid import EventGridPublisherClient, EventGridEvent
from azure.core.credentials import AzureKeyCredential
from azure.servicebus import ServiceBusClient
from azure.cosmos import CosmosClient
import os

class TestEventDrivenSystem:
    
    @pytest.fixture(scope="class")
    def event_grid_client(self):
        return EventGridPublisherClient(
            os.environ['EVENT_GRID_TOPIC_ENDPOINT'],
            AzureKeyCredential(os.environ['EVENT_GRID_TOPIC_KEY'])
        )
    
    @pytest.fixture(scope="class")
    def service_bus_client(self):
        return ServiceBusClient.from_connection_string(
            os.environ['SERVICE_BUS_CONNECTION_STRING']
        )
    
    @pytest.fixture(scope="class")
    def cosmos_client(self):
        return CosmosClient.from_connection_string(
            os.environ['COSMOS_CONNECTION_STRING']
        )
    
    @pytest.mark.asyncio
    async def test_order_flow_success(self, event_grid_client, cosmos_client):
        """Test successful order processing flow"""
        
        # Create test order
        order_data = {
            'order_id': f'TEST-{int(time.time())}',
            'customer_id': 'CUST-123',
            'items': [
                {
                    'product_id': 'PROD-001',
                    'name': 'Test Product',
                    'quantity': 2,
                    'price': 49.99
                }
            ],
            'total_amount': 99.98,
            'shipping_address': {
                'street': '123 Test St',
                'city': 'Test City',
                'state': 'TS',
                'zip': '12345'
            }
        }
        
        # Publish order created event
        event = EventGridEvent(
            event_type='Order.Created',
            subject=f"orders/{order_data['order_id']}",
            data=order_data,
            data_version='1.0'
        )
        
        await event_grid_client.send(event)
        
        # Wait for processing
        await asyncio.sleep(10)
        
        # Verify order in Cosmos DB
        database = cosmos_client.get_database_client('OrdersDB')
        container = database.get_container_client('Orders')
        
        order = container.read_item(
            item=order_data['order_id'],
            partition_key=order_data['customer_id']
        )
        
        assert order['status'] == 'confirmed'
        assert order['id'] == order_data['order_id']
        assert 'processed_at' in order
    
    @pytest.mark.asyncio
    async def test_inventory_event_flow(self, event_grid_client):
        """Test inventory update event flow"""
        
        # Create inventory event
        inventory_event = EventGridEvent(
            event_type='Inventory.LowStock',
            subject='inventory/PROD-001',
            data={
                'product_id': 'PROD-001',
                'current_stock': 5,
                'previous_stock': 50,
                'warehouse_id': 'WH-001',
                'timestamp': datetime.utcnow().isoformat()
            },
            data_version='1.0'
        )
        
        await event_grid_client.send(inventory_event)
        
        # In real test, would verify alert was sent
        await asyncio.sleep(5)
        
        # Could check Service Bus for alert message
        # or verify notification was sent
    
    @pytest.mark.asyncio
    async def test_fulfillment_orchestration(self, service_bus_client):
        """Test durable function orchestration"""
        
        # Send message to fulfillment queue
        sender = service_bus_client.get_queue_sender('order-fulfillment')
        
        test_order = {
            'order_id': f'ORCH-TEST-{int(time.time())}',
            'customer_id': 'CUST-456',
            'items': [
                {
                    'product_id': 'PROD-002',
                    'name': 'Orchestration Test',
                    'quantity': 1,
                    'price': 299.99
                }
            ],
            'total_amount': 299.99,
            'shipping_address': {
                'street': '456 Orch Ave',
                'city': 'Test City',
                'state': 'TS',
                'zip': '54321'
            }
        }
        
        await sender.send_messages(
            ServiceBusMessage(
                body=json.dumps(test_order),
                session_id=test_order['customer_id']
            )
        )
        
        # Wait for orchestration to complete
        await asyncio.sleep(30)
        
        # Verify fulfillment completed
        # In real scenario, would check:
        # - Order status updated
        # - Shipment created
        # - Notifications sent
    
    @pytest.mark.asyncio
    async def test_analytics_processing(self):
        """Test analytics event processing"""
        
        # Simulate multiple view events
        async with httpx.AsyncClient() as client:
            base_url = os.environ.get('API_BASE_URL', 'http://localhost:8000')
            
            # Generate view events
            for i in range(100):
                view_event = {
                    'event_type': 'analytics.product_viewed',
                    'timestamp': datetime.utcnow().isoformat(),
                    'user_id': f'USER-{i % 10}',
                    'session_id': f'SESSION-{i % 20}',
                    'product_id': f'PROD-{i % 5}',
                    'properties': {
                        'source': 'test',
                        'device': 'desktop'
                    }
                }
                
                # Send to analytics endpoint
                response = await client.post(
                    f"{base_url}/analytics/event",
                    json=view_event
                )
                
                assert response.status_code == 202
        
        # Verify metrics calculated
        # Would check Azure Data Explorer or metrics store
    
    @pytest.mark.asyncio
    async def test_error_handling_and_compensation(self, event_grid_client):
        """Test error scenarios and compensation logic"""
        
        # Create order that will fail (invalid product)
        failing_order = {
            'order_id': f'FAIL-TEST-{int(time.time())}',
            'customer_id': 'CUST-789',
            'items': [
                {
                    'product_id': 'INVALID-PRODUCT',
                    'name': 'Non-existent Product',
                    'quantity': 1,
                    'price': 99.99
                }
            ],
            'total_amount': 99.99,
            'shipping_address': {
                'street': '789 Error St',
                'city': 'Fail City',
                'state': 'ER',
                'zip': '00000'
            }
        }
        
        event = EventGridEvent(
            event_type='Order.Created',
            subject=f"orders/{failing_order['order_id']}",
            data=failing_order,
            data_version='1.0'
        )
        
        await event_grid_client.send(event)
        
        # Wait for processing and compensation
        await asyncio.sleep(15)
        
        # Verify order marked as failed
        # Verify compensation executed (inventory released, payment refunded)
    
    @pytest.mark.asyncio
    async def test_performance_and_scale(self, event_grid_client):
        """Test system performance under load"""
        
        start_time = time.time()
        events_sent = 0
        
        # Send batch of events
        batch_size = 100
        events = []
        
        for i in range(batch_size):
            event = EventGridEvent(
                event_type='Analytics.ProductViewed',
                subject=f'analytics/view/{i}',
                data={
                    'product_id': f'PROD-{i % 10}',
                    'user_id': f'USER-{i % 50}',
                    'timestamp': datetime.utcnow().isoformat()
                },
                data_version='1.0'
            )
            events.append(event)
        
        # Send in batches of 10
        for i in range(0, len(events), 10):
            batch = events[i:i+10]
            await event_grid_client.send(batch)
            events_sent += len(batch)
        
        elapsed_time = time.time() - start_time
        throughput = events_sent / elapsed_time
        
        print(f"Sent {events_sent} events in {elapsed_time:.2f} seconds")
        print(f"Throughput: {throughput:.2f} events/second")
        
        assert throughput > 50  # Minimum expected throughput
    
    @pytest.mark.asyncio
    async def test_data_consistency(self, cosmos_client, service_bus_client):
        """Test data consistency across services"""
        
        # Create multiple related events
        customer_id = f'CONSISTENCY-TEST-{int(time.time())}'
        order_ids = []
        
        # Create multiple orders for same customer
        for i in range(5):
            order_id = f'ORDER-{customer_id}-{i}'
            order_ids.append(order_id)
            
            # Process order through system
            # ...
        
        # Verify all orders are consistent
        database = cosmos_client.get_database_client('OrdersDB')
        container = database.get_container_client('Orders')
        
        # Query all orders for customer
        query = f"SELECT * FROM c WHERE c.customerId = '{customer_id}'"
        orders = list(container.query_items(query, enable_cross_partition_query=True))
        
        assert len(orders) == 5
        for order in orders:
            assert order['customerId'] == customer_id
            assert order['id'] in order_ids
```

## ✅ Validation and Monitoring

### Final System Validation

```bash
# 1. Check Function App status
az functionapp show --name "$FUNCTION_APP_NAME" --resource-group "$RESOURCE_GROUP" --query state

# 2. Monitor Event Grid metrics
az monitor metrics list \
    --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.EventGrid/topics/$EVENT_GRID_TOPIC" \
    --metric "PublishSuccessCount,PublishFailCount" \
    --interval PT1M

# 3. Check Service Bus queues
az servicebus queue show \
    --name "order-fulfillment" \
    --namespace-name "$SERVICE_BUS_NAMESPACE" \
    --resource-group "$RESOURCE_GROUP" \
    --query "messageCount"

# 4. Query Cosmos DB
az cosmosdb sql container query \
    --account-name "$COSMOS_ACCOUNT" \
    --database-name "OrdersDB" \
    --container-name "Orders" \
    --resource-group "$RESOURCE_GROUP" \
    --query-text "SELECT COUNT(1) as orderCount FROM c"

# 5. Monitor Function executions
func azure functionapp logstream "$FUNCTION_APP_NAME"
```

## 🎯 Success Criteria

Your event-driven system is complete when:

- [ ] Azure Functions deploy successfully
- [ ] Event Grid routes events correctly
- [ ] Order processing flow works end-to-end
- [ ] Durable Functions orchestrate fulfillment
- [ ] Analytics events process in real-time
- [ ] Error handling and compensation work
- [ ] System handles 1000+ events/minute
- [ ] Monitoring dashboards show metrics
- [ ] All integration tests pass

## 🚀 Extension Challenges

1. **Multi-Region Deployment**: Deploy to multiple regions with geo-replication
2. **Advanced Analytics**: Implement ML-based anomaly detection
3. **GraphQL Subscriptions**: Add real-time GraphQL API
4. **Blockchain Integration**: Add immutable audit trail
5. **IoT Integration**: Process millions of device events

## 📚 Additional Resources

- [Azure Functions Best Practices](https://learn.microsoft.com/azure/azure-functions/functions-best-practices)
- [Event-Driven Architecture](https://learn.microsoft.com/azure/architecture/guide/architecture-styles/event-driven)
- [Durable Functions Patterns](https://learn.microsoft.com/azure/azure-functions/durable/durable-functions-overview)
- [Azure Event Grid](https://learn.microsoft.com/azure/event-grid/)

---

Congratulations! 🎉 You've built a complete event-driven serverless system combining the best of container orchestration and serverless computing. This architecture can scale to handle millions of events while maintaining reliability and performance. You're now ready to tackle Module 13 - Infrastructure as Code!