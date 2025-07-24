---
sidebar_position: 4
title: "Exercise 3: Part 1"
description: "## Overview"
---

# Exercise 3: Event-Driven Serverless System ⭐⭐⭐

## Overview

In this advanced exercise, you'll build a production-ready event processing system that combines AKS-hosted microservices with Azure Functions, implementing complex event-driven patterns, durable workflows, and real-time processing at scale. This represents a real-world hybrid cloud-native architecture.

**Duration**: 60-90 minutes  
**Difficulty**: Hard (⭐⭐⭐)  
**Success Rate**: 60%

## 🎯 Learning Objectives

By completing this exercise, you will:

1. Design event-driven architectures with multiple event sources
2. Implement Azure Functions with Python for serverless processing
3. Create Durable Functions for complex orchestration
4. Integrate Event Grid, Service Bus, and Event Hubs
5. Build real-time data pipelines with stream processing
6. Implement distributed tracing across services

## 📋 Prerequisites

- Completed Exercises 1 & 2
- Azure Functions Core Tools installed
- Azure CLI with Functions extension
- Python 3.11 with Azure Functions SDK
- Running AKS cluster from Exercise 2

## 🏗️ Architecture

```mermaid
graph TB
    subgraph "Event Sources"
        API[Product API<br/>on AKS]
        IOT[IoT Devices]
        WEB[Web Events]
        MOB[Mobile Apps]
    end
    
    subgraph "Event Routing"
        EG[Event Grid]
        SB[Service Bus]
        EH[Event Hub]
    end
    
    subgraph "Azure Functions"
        FN1[Order Processor]
        FN2[Inventory Updater]
        FN3[Analytics Engine]
        DF[Durable Function<br/>Orchestrator]
    end
    
    subgraph "Storage & Analytics"
        COSMOS[Cosmos DB]
        BLOB[Blob Storage]
        ADX[Azure Data Explorer]
        AI[Azure AI Services]
    end
    
    subgraph "Real-time Processing"
        ASA[Azure Stream Analytics]
        DASH[Real-time Dashboard]
    end
    
    API --&gt; EG
    IOT --&gt; EH
    WEB --&gt; EG
    MOB --&gt; SB
    
    EG --&gt; FN1
    EG --&gt; FN2
    SB --&gt; DF
    EH --&gt; ASA
    
    FN1 --&gt; COSMOS
    FN2 --&gt; COSMOS
    FN3 --&gt; AI
    DF --&gt; BLOB
    
    ASA --&gt; ADX
    ADX --&gt; DASH
    
    style EG fill:#ff9,stroke:#333,stroke-width:2px
    style DF fill:#9ff,stroke:#333,stroke-width:2px
    style ASA fill:#f9f,stroke:#333,stroke-width:2px
```

## 📝 Scenario

Your product catalog system needs to handle:
- **Order Processing**: 100,000+ orders per hour
- **Inventory Updates**: Real-time stock tracking
- **Analytics**: ML-based demand forecasting
- **IoT Integration**: Warehouse sensor data
- **Event Sourcing**: Complete audit trail
- **Complex Workflows**: Multi-step order fulfillment

## 🚀 Part 1: Azure Functions Setup

### Step 1: Create Function App Project

**Copilot Prompt Suggestion:**
```bash
# Create a Python Azure Functions project structure with:
# - Multiple function endpoints
# - Shared code modules
# - Dependency management
# - Local settings for development
# - Unit test structure
# File: scripts/create-functions-project.sh
```

**Expected Output:**
```bash
#!/bin/bash
set -euo pipefail

PROJECT_NAME="product-events-processor"
PYTHON_VERSION="3.11"

echo "Creating Azure Functions project: $PROJECT_NAME"

# Create project directory
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# Initialize Python virtual environment
python -m venv .venv
source .venv/bin/activate

# Install Azure Functions Core Tools
pip install azure-functions azure-storage-blob azure-servicebus azure-eventgrid azure-cosmos

# Create function app
func init --python

# Create project structure
mkdir -p shared tests

# Create requirements.txt
cat &gt; requirements.txt &lt;<EOF
azure-functions==1.17.0
azure-storage-blob==12.19.0
azure-servicebus==7.11.4
azure-eventgrid==4.16.0
azure-cosmos==4.5.1
azure-eventhub==5.11.5
azure-identity==1.15.0
azure-monitor-opentelemetry==1.2.0
pydantic==2.5.3
httpx==0.26.0
redis==5.0.1
prometheus-client==0.19.0
opencensus-ext-azure==1.1.13
pytest==7.4.4
pytest-asyncio==0.23.3
pytest-mock==3.12.0
EOF

# Create local.settings.json
cat &gt; local.settings.json &lt;<EOF
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "FUNCTIONS_EXTENSION_VERSION": "~4",
    "COSMOS_CONNECTION_STRING": "",
    "SERVICE_BUS_CONNECTION_STRING": "",
    "EVENT_GRID_TOPIC_ENDPOINT": "",
    "EVENT_GRID_TOPIC_KEY": "",
    "REDIS_CONNECTION_STRING": "",
    "APPLICATION_INSIGHTS_KEY": ""
  }
}
EOF

# Create shared modules
cat &gt; shared/__init__.py &lt;<EOF
"""Shared modules for Azure Functions"""
from .event_models import *
from .cosmos_client import CosmosClient
from .service_bus_client import ServiceBusClient
from .telemetry import setup_telemetry
EOF

echo "✓ Azure Functions project created!"
echo "Next steps:"
echo "1. Activate virtual environment: source .venv/bin/activate"
echo "2. Create your functions"
echo "3. Update local.settings.json with connection strings"
```

### Step 2: Create Event Models

**Copilot Prompt Suggestion:**
```python
# Create shared/event_models.py with Pydantic models for:
# - Order events (created, updated, cancelled)
# - Inventory events (stock update, low stock alert)
# - Analytics events (view, purchase, recommendation)
# - Include event metadata and versioning
# - Add validation and serialization methods
```

**Expected Output:**
```python
from datetime import datetime
from typing import Optional, Dict, Any, List
from enum import Enum
from pydantic import BaseModel, Field, validator
import json
from uuid import uuid4

class EventType(str, Enum):
    # Order Events
    ORDER_CREATED = "order.created"
    ORDER_UPDATED = "order.updated"
    ORDER_CANCELLED = "order.cancelled"
    ORDER_COMPLETED = "order.completed"
    
    # Inventory Events
    INVENTORY_UPDATED = "inventory.updated"
    INVENTORY_LOW_STOCK = "inventory.low_stock"
    INVENTORY_OUT_OF_STOCK = "inventory.out_of_stock"
    
    # Analytics Events
    PRODUCT_VIEWED = "analytics.product_viewed"
    PRODUCT_PURCHASED = "analytics.product_purchased"
    RECOMMENDATION_GENERATED = "analytics.recommendation_generated"
    
    # System Events
    HEALTH_CHECK = "system.health_check"
    ERROR_OCCURRED = "system.error"

class EventMetadata(BaseModel):
    event_id: str = Field(default_factory=lambda: str(uuid4()))
    event_type: EventType
    event_version: str = "1.0"
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    source: str
    correlation_id: Optional[str] = None
    causation_id: Optional[str] = None
    user_id: Optional[str] = None
    
    class Config:
        use_enum_values = True

class OrderItem(BaseModel):
    product_id: str
    quantity: int = Field(gt=0)
    price: float = Field(gt=0)
    name: str
    
class OrderEvent(BaseModel):
    metadata: EventMetadata
    order_id: str
    customer_id: str
    items: List[OrderItem]
    total_amount: float = Field(gt=0)
    status: str
    shipping_address: Dict[str, str]
    
    @validator('total_amount')
    def validate_total(cls, v, values):
        if 'items' in values:
            calculated_total = sum(item.price * item.quantity for item in values['items'])
            if abs(v - calculated_total) &gt; 0.01:
                raise ValueError(f"Total amount {v} doesn't match items sum {calculated_total}")
        return v

class InventoryEvent(BaseModel):
    metadata: EventMetadata
    product_id: str
    sku: str
    current_stock: int
    previous_stock: int
    change_amount: int
    warehouse_id: str
    threshold_level: Optional[int] = None
    reorder_point: Optional[int] = None
    
    @validator('change_amount')
    def validate_change(cls, v, values):
        if all(k in values for k in ['current_stock', 'previous_stock']):
            expected_change = values['current_stock'] - values['previous_stock']
            if v != expected_change:
                raise ValueError(f"Change amount {v} doesn't match stock difference")
        return v

class AnalyticsEvent(BaseModel):
    metadata: EventMetadata
    session_id: str
    product_id: Optional[str] = None
    category: Optional[str] = None
    action: str
    value: Optional[float] = None
    properties: Dict[str, Any] = Field(default_factory=dict)

class RecommendationEvent(BaseModel):
    metadata: EventMetadata
    user_id: str
    recommendations: List[Dict[str, Any]]
    algorithm: str
    confidence_scores: List[float]
    context: Dict[str, Any]

class ErrorEvent(BaseModel):
    metadata: EventMetadata
    error_code: str
    error_message: str
    stack_trace: Optional[str] = None
    severity: str = Field(pattern="^(low|medium|high|critical)$")
    affected_resources: List[str] = Field(default_factory=list)
    recovery_action: Optional[str] = None

# Event Factory
class EventFactory:
    @staticmethod
    def create_order_event(
        order_id: str,
        customer_id: str,
        items: List[Dict],
        total_amount: float,
        status: str,
        shipping_address: Dict[str, str],
        source: str = "product-api"
    ) -&gt; OrderEvent:
        return OrderEvent(
            metadata=EventMetadata(
                event_type=EventType.ORDER_CREATED,
                source=source
            ),
            order_id=order_id,
            customer_id=customer_id,
            items=[OrderItem(**item) for item in items],
            total_amount=total_amount,
            status=status,
            shipping_address=shipping_address
        )
    
    @staticmethod
    def create_inventory_event(
        product_id: str,
        sku: str,
        current_stock: int,
        previous_stock: int,
        warehouse_id: str,
        source: str = "inventory-service"
    ) -&gt; InventoryEvent:
        change_amount = current_stock - previous_stock
        event_type = EventType.INVENTORY_UPDATED
        
        if current_stock == 0:
            event_type = EventType.INVENTORY_OUT_OF_STOCK
        elif current_stock &lt; 10:  # Configurable threshold
            event_type = EventType.INVENTORY_LOW_STOCK
            
        return InventoryEvent(
            metadata=EventMetadata(
                event_type=event_type,
                source=source
            ),
            product_id=product_id,
            sku=sku,
            current_stock=current_stock,
            previous_stock=previous_stock,
            change_amount=change_amount,
            warehouse_id=warehouse_id,
            threshold_level=10,
            reorder_point=50
        )

# Serialization helpers
def serialize_event(event: BaseModel) -&gt; str:
    """Serialize event to JSON string"""
    return event.model_dump_json()

def deserialize_event(event_data: str, event_type: EventType) -&gt; BaseModel:
    """Deserialize JSON string to appropriate event model"""
    event_map = {
        EventType.ORDER_CREATED: OrderEvent,
        EventType.ORDER_UPDATED: OrderEvent,
        EventType.INVENTORY_UPDATED: InventoryEvent,
        EventType.INVENTORY_LOW_STOCK: InventoryEvent,
        EventType.PRODUCT_VIEWED: AnalyticsEvent,
        EventType.RECOMMENDATION_GENERATED: RecommendationEvent,
        EventType.ERROR_OCCURRED: ErrorEvent
    }
    
    model_class = event_map.get(event_type)
    if not model_class:
        raise ValueError(f"Unknown event type: {event_type}")
    
    return model_class.model_validate_json(event_data)
```

### Step 3: Create Order Processing Function

**Copilot Prompt Suggestion:**
```python
# Create OrderProcessor/__init__.py Azure Function that:
# - Triggers on Event Grid events
# - Validates order data
# - Updates inventory via service call
# - Saves to Cosmos DB
# - Publishes to Service Bus for fulfillment
# - Implements retry logic and error handling
# - Includes distributed tracing
```

**Expected Output:**
```python
import logging
import json
import os
from typing import Dict, Any
import azure.functions as func
from azure.cosmos import CosmosClient, PartitionKey
from azure.servicebus import ServiceBusClient, ServiceBusMessage
from azure.identity import DefaultAzureCredential
from opencensus.ext.azure.log_exporter import AzureLogHandler
from opencensus.ext.azure.trace_exporter import AzureExporter
from opencensus.trace import tracer as tracer_module
from opencensus.trace.samplers import ProbabilitySampler
import httpx

# Configure logging and tracing
logger = logging.getLogger(__name__)
logger.addHandler(AzureLogHandler(
    connection_string=os.environ.get('APPLICATION_INSIGHTS_KEY')
))

tracer = tracer_module.Tracer(
    exporter=AzureExporter(
        connection_string=os.environ.get('APPLICATION_INSIGHTS_KEY')
    ),
    sampler=ProbabilitySampler(1.0)
)

# Initialize clients
cosmos_client = CosmosClient.from_connection_string(
    os.environ['COSMOS_CONNECTION_STRING']
)
database = cosmos_client.get_database_client('OrdersDB')
container = database.get_container_client('Orders')

servicebus_client = ServiceBusClient.from_connection_string(
    os.environ['SERVICE_BUS_CONNECTION_STRING']
)

async def main(event: func.EventGridEvent) -&gt; None:
    """Process order events from Event Grid"""
    
    with tracer.span(name='OrderProcessor') as span:
        span.add_attribute('event.id', event.id)
        span.add_attribute('event.type', event.event_type)
        
        try:
            # Parse event data
            order_data = event.get_json()
            logger.info(f"Processing order: {order_data.get('order_id')}")
            
            # Validate order
            if not validate_order(order_data):
                raise ValueError("Invalid order data")
            
            # Check inventory availability
            with tracer.span(name='CheckInventory'):
                inventory_available = await check_inventory(order_data['items'])
                if not inventory_available:
                    await handle_insufficient_inventory(order_data)
                    return
            
            # Update inventory
            with tracer.span(name='UpdateInventory'):
                await update_inventory(order_data['items'])
            
            # Save order to Cosmos DB
            with tracer.span(name='SaveOrder'):
                order_data['id'] = order_data['order_id']
                order_data['partition_key'] = order_data['customer_id']
                order_data['status'] = 'confirmed'
                order_data['processed_at'] = datetime.utcnow().isoformat()
                
                container.create_item(body=order_data)
                logger.info(f"Order saved: {order_data['order_id']}")
            
            # Send to fulfillment queue
            with tracer.span(name='QueueFulfillment'):
                await queue_for_fulfillment(order_data)
            
            # Send confirmation event
            await send_confirmation_event(order_data)
            
        except Exception as e:
            logger.error(f"Error processing order: {str(e)}", exc_info=True)
            span.add_attribute('error', True)
            span.add_attribute('error.message', str(e))
            
            # Send to dead letter queue
            await send_to_dead_letter(event, str(e))
            raise

def validate_order(order_data: Dict[str, Any]) -&gt; bool:
    """Validate order data structure and business rules"""
    required_fields = ['order_id', 'customer_id', 'items', 'total_amount']
    
    # Check required fields
    for field in required_fields:
        if field not in order_data:
            logger.error(f"Missing required field: {field}")
            return False
    
    # Validate items
    if not order_data['items'] or len(order_data['items']) == 0:
        logger.error("Order has no items")
        return False
    
    # Validate total amount
    calculated_total = sum(
        item['price'] * item['quantity'] 
        for item in order_data['items']
    )
    if abs(calculated_total - order_data['total_amount']) &gt; 0.01:
        logger.error("Total amount mismatch")
        return False
    
    return True

async def check_inventory(items: list) -&gt; bool:
    """Check inventory availability for all items"""
    inventory_api = os.environ.get('INVENTORY_API_URL', 'http://product-catalog-service')
    
    async with httpx.AsyncClient() as client:
        for item in items:
            response = await client.get(
                f"{inventory_api}/products/{item['product_id']}"
            )
            if response.status_code != 200:
                return False
            
            product = response.json()
            if product['stock'] &lt; item['quantity']:
                logger.warning(
                    f"Insufficient stock for {item['product_id']}: "
                    f"requested {item['quantity']}, available {product['stock']}"
                )
                return False
    
    return True

async def update_inventory(items: list) -&gt; None:
    """Update inventory levels for ordered items"""
    inventory_api = os.environ.get('INVENTORY_API_URL', 'http://product-catalog-service')
    
    async with httpx.AsyncClient() as client:
        for item in items:
            # Decrease stock
            update_data = {
                'product_id': item['product_id'],
                'quantity_change': -item['quantity'],
                'reason': 'order_placed'
            }
            
            response = await client.post(
                f"{inventory_api}/inventory/update",
                json=update_data
            )
            
            if response.status_code != 200:
                raise Exception(f"Failed to update inventory for {item['product_id']}")
            
            logger.info(f"Updated inventory for {item['product_id']}")

async def queue_for_fulfillment(order_data: Dict[str, Any]) -&gt; None:
    """Send order to fulfillment queue"""
    queue_sender = servicebus_client.get_queue_sender(
        queue_name="order-fulfillment"
    )
    
    message = ServiceBusMessage(
        body=json.dumps(order_data),
        content_type="application/json",
        session_id=order_data['customer_id'],  # Group by customer
        application_properties={
            'order_id': order_data['order_id'],
            'priority': determine_priority(order_data)
        }
    )
    
    await queue_sender.send_messages(message)
    logger.info(f"Order queued for fulfillment: {order_data['order_id']}")

def determine_priority(order_data: Dict[str, Any]) -&gt; str:
    """Determine order priority based on business rules"""
    total_amount = order_data['total_amount']
    
    if total_amount &gt; 1000:
        return 'high'
    elif total_amount &gt; 500:
        return 'medium'
    else:
        return 'normal'

async def handle_insufficient_inventory(order_data: Dict[str, Any]) -&gt; None:
    """Handle orders with insufficient inventory"""
    # Update order status
    order_data['status'] = 'pending_inventory'
    
    # Save to pending orders
    pending_container = database.get_container_client('PendingOrders')
    order_data['id'] = order_data['order_id']
    order_data['partition_key'] = 'pending'
    pending_container.create_item(body=order_data)
    
    # Send notification
    await send_inventory_alert(order_data)

async def send_confirmation_event(order_data: Dict[str, Any]) -&gt; None:
    """Send order confirmation event"""
    # Implementation for sending confirmation via Event Grid
    pass

async def send_to_dead_letter(event: func.EventGridEvent, error: str) -&gt; None:
    """Send failed events to dead letter queue"""
    dlq_sender = servicebus_client.get_queue_sender(
        queue_name="order-processing-dlq"
    )
    
    message = ServiceBusMessage(
        body=event.get_json(),
        content_type="application/json",
        application_properties={
            'error': error,
            'event_id': event.id,
            'retry_count': '0'
        }
    )
    
    await dlq_sender.send_messages(message)

async def send_inventory_alert(order_data: Dict[str, Any]) -&gt; None:
    """Send alert for insufficient inventory"""
    # Implementation for inventory alerts
    pass
```

---

**Continue to Part 2** for Durable Functions, Event Hub processing, and complete system integration...