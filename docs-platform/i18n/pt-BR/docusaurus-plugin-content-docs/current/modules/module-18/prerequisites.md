---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 18"
---

# Módulo 18: Pré-requisitos and Setup

## 📋 Required Knowledge

Before starting Módulo 18, you should have completed:

### Anterior Módulos
- ✅ **Módulo 17**: GitHub Models and AI Integration
- ✅ **Módulo 15**: Performance and Scalability
- ✅ **Módulo 13**: Infrastructure as Code
- ✅ **Módulo 11**: Microservices Architecture

### Technical Concepts
You should be comfortable with:
- Distributed systems principles
- Message-based communication
- Database transactions and consistency
- Event-driven architectures
- Domain-Driven Design (DDD)
- Asynchronous programming patterns

## 🛠️ Software Requirements

### Local desenvolvimento ambiente

```bash
# Check Python version (3.11+ required)
python --version

# Check Docker
docker --version  # Should be 24+

# Check Azure CLI
az --version  # Should be 2.54+

# Check .NET SDK (for some examples)
dotnet --version  # Should be 8.0+

# Check Node.js (for monitoring tools)
node --version  # Should be 18+
```

### Required Python Packages

```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows
.\venv\Scripts\activate
# macOS/Linux
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install requirements
pip install -r requirements.txt
```

**requirements.txt**:
```txt
# Core messaging and events
azure-servicebus==7.11.4
azure-eventhub==5.11.5
azure-storage-queue==12.8.0
aiokafka==0.10.0
confluent-kafka==2.3.0

# Event sourcing and CQRS
eventsourcing==9.2.18
pydantic==2.5.0
sqlalchemy==2.0.23
alembic==1.13.0

# Distributed coordination
python-etcd3==0.12.0
kazoo==2.9.0
redis[hiredis]==5.0.1

# API and frameworks
fastapi==0.104.1
uvicorn[standard]==0.24.0
grpcio==1.60.0
grpcio-tools==1.60.0

# Azure integration
azure-functions==1.18.0
azure-cosmos==4.5.1
azure-monitor-opentelemetry==1.1.1
azure-identity==1.15.0

# Monitoring and tracing
opentelemetry-api==1.21.0
opentelemetry-sdk==1.21.0
opentelemetry-instrumentation-fastapi==0.42b0
prometheus-client==0.19.0
py-zipkin==1.2.8

# Utilities
python-dotenv==1.0.0
httpx==0.25.2
tenacity==8.2.3
structlog==23.2.0
python-json-logger==2.0.7

# Testing
pytest==7.4.3
pytest-asyncio==0.21.1
pytest-mock==3.12.0
testcontainers==3.7.1
faker==20.1.0
hypothesis==6.92.1

# Development tools
black==23.12.0
ruff==0.1.9
mypy==1.7.1
pre-commit==3.6.0
```

### VS Code Extensions
Ensure these extensions are instalado:
- GitHub Copilot
- Python
- Azure Functions
- Docker
- REST Client
- PlantUML (for sequence diagrams)
- Draw.io Integration

## 🔑 Azure Recursos Setup

### 1. Resource Group Creation

```bash
# Set variables
RESOURCE_GROUP="rg-workshop-module18"
LOCATION="eastus"
UNIQUE_ID=$RANDOM

# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION
```

### 2. Azure Service Bus Setup

```bash
# Create Service Bus namespace (Premium for transactions)
az servicebus namespace create \
  --name "sb-module18-$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Premium

# Create queues
az servicebus queue create \
  --name "commands" \
  --namespace-name "sb-module18-$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP \
  --enable-partitioning false \
  --enable-session true

az servicebus queue create \
  --name "events" \
  --namespace-name "sb-module18-$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP \
  --enable-partitioning true

# Create topics
az servicebus topic create \
  --name "integration-events" \
  --namespace-name "sb-module18-$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP \
  --enable-partitioning true

# Get connection string
az servicebus namespace authorization-rule keys list \
  --name RootManageSharedAccessKey \
  --namespace-name "sb-module18-$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP \
  --query primaryConnectionString -o tsv
```

### 3. Azure Event Hubs Setup

```bash
# Create Event Hubs namespace
az eventhubs namespace create \
  --name "eh-module18-$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard

# Create event hub for event sourcing
az eventhubs eventhub create \
  --name "event-store" \
  --namespace-name "eh-module18-$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP \
  --partition-count 4 \
  --retention-time 168

# Create consumer group
az eventhubs eventhub consumer-group create \
  --name "projections" \
  --eventhub-name "event-store" \
  --namespace-name "eh-module18-$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP
```

### 4. Cosmos DB Setup

```bash
# Create Cosmos DB account
az cosmosdb create \
  --name "cosmos-module18-$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP \
  --kind GlobalDocumentDB \
  --default-consistency-level "Session" \
  --enable-multiple-write-locations false \
  --enable-analytical-storage true

# Create database
az cosmosdb sql database create \
  --account-name "cosmos-module18-$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP \
  --name "EventStore"

# Create containers
# Event store container
az cosmosdb sql container create \
  --account-name "cosmos-module18-$UNIQUE_ID" \
  --database-name "EventStore" \
  --resource-group $RESOURCE_GROUP \
  --name "Events" \
  --partition-key-path "/aggregateId" \
  --throughput 400

# Projections container
az cosmosdb sql container create \
  --account-name "cosmos-module18-$UNIQUE_ID" \
  --database-name "EventStore" \
  --resource-group $RESOURCE_GROUP \
  --name "Projections" \
  --partition-key-path "/type" \
  --throughput 400

# Saga state container
az cosmosdb sql container create \
  --account-name "cosmos-module18-$UNIQUE_ID" \
  --database-name "EventStore" \
  --resource-group $RESOURCE_GROUP \
  --name "SagaState" \
  --partition-key-path "/sagaId" \
  --throughput 400
```

### 5. Azure Functions Setup

```bash
# Create storage account
az storage account create \
  --name "stmodule18$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS

# Create Function App
az functionapp create \
  --name "func-module18-$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP \
  --storage-account "stmodule18$UNIQUE_ID" \
  --runtime python \
  --runtime-version 3.11 \
  --functions-version 4 \
  --os-type Linux \
  --consumption-plan-location $LOCATION
```

### 6. Application Insights Setup

```bash
# Create Application Insights
az monitor app-insights component create \
  --app "ai-module18-$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --kind web

# Get instrumentation key
az monitor app-insights component show \
  --app "ai-module18-$UNIQUE_ID" \
  --resource-group $RESOURCE_GROUP \
  --query instrumentationKey -o tsv
```

## 🔧 ambiente Configuration

### Create .env file

```bash
# Copy template
cp .env.example .env
```

**.env.example**:
```env
# Azure Service Bus
SERVICEBUS_CONNECTION_STRING=your_connection_string_here
SERVICEBUS_COMMANDS_QUEUE=commands
SERVICEBUS_EVENTS_QUEUE=events
SERVICEBUS_TOPIC_NAME=integration-events

# Azure Event Hubs
EVENTHUB_CONNECTION_STRING=your_connection_string_here
EVENTHUB_NAME=event-store
EVENTHUB_CONSUMER_GROUP=projections

# Cosmos DB
COSMOS_CONNECTION_STRING=your_connection_string_here
COSMOS_DATABASE_NAME=EventStore
COSMOS_EVENTS_CONTAINER=Events
COSMOS_PROJECTIONS_CONTAINER=Projections
COSMOS_SAGA_CONTAINER=SagaState

# Azure Functions
FUNCTIONS_APP_NAME=func-module18-xxxxx
FUNCTIONS_STORAGE_CONNECTION=your_storage_connection_here

# Application Insights
APPLICATIONINSIGHTS_CONNECTION_STRING=your_connection_string_here
APPLICATIONINSIGHTS_INSTRUMENTATION_KEY=your_key_here

# Application Settings
ENVIRONMENT=development
LOG_LEVEL=INFO
ENABLE_TRACING=true
SAGA_TIMEOUT_SECONDS=300
EVENT_RETENTION_DAYS=7

# Redis (local)
REDIS_URL=redis://localhost:6379
REDIS_DB=0

# API Settings
API_HOST=0.0.0.0
API_PORT=8000
GRPC_PORT=50051
```

## 🐳 Docker Setup

### docker-compose.yml
```yaml
version: '3.8'

services:
  # Redis for caching and pub/sub
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  # PostgreSQL for read models
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: workshop
      POSTGRES_PASSWORD: workshop123
      POSTGRES_DB: readmodels
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  # Kafka for local event streaming
  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    ports:
      - "2181:2181"

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
      - "29092:29092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1

  # Kafka UI
  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    depends_on:
      - kafka
    ports:
      - "8080:8080"
    environment:
      KAFKA_CLUSTERS_0_NAME: local
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:29092

  # Jaeger for distributed tracing
  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "5775:5775/udp"
      - "6831:6831/udp"
      - "6832:6832/udp"
      - "5778:5778"
      - "16686:16686"
      - "14268:14268"
      - "14250:14250"
      - "9411:9411"
    environment:
      COLLECTOR_ZIPKIN_HOST_PORT: :9411

  # Prometheus
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus

  # Grafana
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
      - ./grafana/datasources:/etc/grafana/provisioning/datasources

volumes:
  redis_data:
  postgres_data:
  prometheus_data:
  grafana_data:
```

## 🔍 Verification Scripts

### setup-Módulo18.sh
```bash
#!/bin/bash

echo "🚀 Setting up Module 18 environment..."

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Check prerequisites
check_command() {
    if command -v $1 &&gt; /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is not installed"
        return 1
    fi
}

echo "Checking prerequisites..."
check_command python3
check_command pip
check_command docker
check_command az
check_command dotnet

# Create virtual environment
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install requirements
echo "Installing Python packages..."
pip install -r requirements.txt

# Create directories
mkdir -p data/events
mkdir -p data/snapshots
mkdir -p logs
mkdir -p config

# Start Docker services
echo "Starting Docker services..."
docker-compose up -d

# Wait for services
echo "Waiting for services to start..."
sleep 15

# Initialize Kafka topics
echo "Creating Kafka topics..."
docker exec -it $(docker ps -qf "name=kafka") kafka-topics --create \
  --topic events \
  --bootstrap-server localhost:9092 \
  --partitions 4 \
  --replication-factor 1

docker exec -it $(docker ps -qf "name=kafka") kafka-topics --create \
  --topic commands \
  --bootstrap-server localhost:9092 \
  --partitions 4 \
  --replication-factor 1

# Verify services
echo -e "\n${GREEN}Checking service health...${NC}"
curl -s http://localhost:6379/ping || echo "Redis not ready"
curl -s http://localhost:16686/ || echo "Jaeger not ready"
curl -s http://localhost:9090/ || echo "Prometheus not ready"

echo -e "\n${GREEN}✅ Setup complete!${NC}"
echo "Next steps:"
echo "1. Run './scripts/provision-azure.sh' to create Azure resources"
echo "2. Copy .env.example to .env and fill in your connection strings"
echo "3. Run 'python scripts/verify-setup.py' to verify everything"
echo "4. Start with Exercise 1"
```

### verify-setup.py
```python
#!/usr/bin/env python3
"""Verify Module 18 setup and prerequisites."""

import sys
import os
import asyncio
from typing import Tuple
from rich.console import Console
from rich.table import Table
from dotenv import load_dotenv
import httpx
from azure.servicebus import ServiceBusClient
from azure.cosmos import CosmosClient
from azure.eventhub import EventHubProducerClient
import redis

console = Console()
load_dotenv()

async def check_service_bus() -&gt; Tuple[bool, str]:
    """Check Azure Service Bus connectivity."""
    try:
        conn_str = os.getenv("SERVICEBUS_CONNECTION_STRING")
        if not conn_str:
            return False, "Not configured"
        
        client = ServiceBusClient.from_connection_string(conn_str)
        with client:
            # Try to get queue properties
            queue_name = os.getenv("SERVICEBUS_COMMANDS_QUEUE", "commands")
            queue_properties = client.get_queue(queue_name)
            return True, f"Connected ({queue_name} exists)"
    except Exception as e:
        return False, str(e)[:50]

async def check_cosmos_db() -&gt; Tuple[bool, str]:
    """Check Cosmos DB connectivity."""
    try:
        conn_str = os.getenv("COSMOS_CONNECTION_STRING")
        if not conn_str:
            return False, "Not configured"
        
        client = CosmosClient.from_connection_string(conn_str)
        database_name = os.getenv("COSMOS_DATABASE_NAME", "EventStore")
        database = client.get_database_client(database_name)
        
        # List containers to verify connection
        containers = list(database.list_containers())
        return True, f"{len(containers)} containers"
    except Exception as e:
        return False, str(e)[:50]

async def check_event_hub() -&gt; Tuple[bool, str]:
    """Check Event Hub connectivity."""
    try:
        conn_str = os.getenv("EVENTHUB_CONNECTION_STRING")
        if not conn_str:
            return False, "Not configured"
        
        event_hub_name = os.getenv("EVENTHUB_NAME", "event-store")
        producer = EventHubProducerClient.from_connection_string(
            conn_str, 
            eventhub_name=event_hub_name
        )
        
        # Get properties to verify connection
        async with producer:
            properties = await producer.get_eventhub_properties()
            return True, f"{properties.partition_ids} partitions"
    except Exception as e:
        return False, str(e)[:50]

def check_redis() -&gt; Tuple[bool, str]:
    """Check Redis connectivity."""
    try:
        r = redis.from_url(os.getenv("REDIS_URL", "redis://localhost:6379"))
        r.ping()
        return True, "connected"
    except Exception as e:
        return False, str(e)[:50]

async def check_kafka() -&gt; Tuple[bool, str]:
    """Check Kafka connectivity."""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get("http://localhost:8080/api/clusters")
            if response.status_code == 200:
                return True, "UI accessible"
            return False, f"Status {response.status_code}"
    except:
        return False, "not running"

async def check_monitoring() -&gt; Tuple[bool, str]:
    """Check monitoring services."""
    services = {
        "Jaeger": "http://localhost:16686",
        "Prometheus": "http://localhost:9090",
        "Grafana": "http://localhost:3000"
    }
    
    results = []
    async with httpx.AsyncClient() as client:
        for service, url in services.items():
            try:
                response = await client.get(url)
                if response.status_code &lt; 400:
                    results.append(f"{service}✓")
                else:
                    results.append(f"{service}✗")
            except:
                results.append(f"{service}✗")
    
    all_ok = all("✓" in r for r in results)
    return all_ok, " ".join(results)

async def main():
    """Run all verification checks."""
    console.print("\n[bold cyan]🔍 Verifying Module 18 Prerequisites[/bold cyan]\n")
    
    # Create results table
    table = Table(title="Setup Status")
    table.add_column("Component", style="cyan")
    table.add_column("Status", style="green")
    table.add_column("Details", style="yellow")
    
    # Check Azure services
    console.print("[bold]Checking Azure services...[/bold]")
    
    # Service Bus
    success, status = await check_service_bus()
    icon = "✅" if success else "❌"
    table.add_row("Azure Service Bus", icon, status)
    
    # Cosmos DB
    success, status = await check_cosmos_db()
    icon = "✅" if success else "❌"
    table.add_row("Azure Cosmos DB", icon, status)
    
    # Event Hub
    success, status = await check_event_hub()
    icon = "✅" if success else "❌"
    table.add_row("Azure Event Hub", icon, status)
    
    # Check local services
    console.print("\n[bold]Checking local services...[/bold]")
    
    # Redis
    success, status = check_redis()
    icon = "✅" if success else "❌"
    table.add_row("Redis", icon, status)
    
    # Kafka
    success, status = await check_kafka()
    icon = "✅" if success else "❌"
    table.add_row("Kafka", icon, status)
    
    # Monitoring
    success, status = await check_monitoring()
    icon = "✅" if success else "❌"
    table.add_row("Monitoring Stack", icon, status)
    
    # Display results
    console.print("\n")
    console.print(table)
    
    # Summary
    console.print("\n[bold]Summary:[/bold]")
    # Count successes
    success_count = sum(1 for row in table.rows if "✅" in row[1])
    total_count = len(table.rows)
    
    if success_count == total_count:
        console.print("✅ [green]All prerequisites satisfied! You're ready to start Module 18.[/green]")
    else:
        console.print(f"❌ [red]{total_count - success_count} prerequisites missing. Please check the setup guide.[/red]")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())
```

## 🚨 Common Setup Issues

### Issue: Service Bus Connection Failed
```bash
# Solution: Check connection string format
# Should look like: Endpoint=sb://xxx.servicebus.windows.net/;SharedAccessKeyName=xxx;SharedAccessKey=xxx

# Verify namespace exists
az servicebus namespace show \
  --name "sb-module18-xxxxx" \
  --resource-group "rg-workshop-module18"
```

### Issue: Cosmos DB Throughput Error
```bash
# Solution: Increase RU/s or use serverless
az cosmosdb sql container throughput update \
  --account-name "cosmos-module18-xxxxx" \
  --database-name "EventStore" \
  --name "Events" \
  --resource-group "rg-workshop-module18" \
  --throughput 1000
```

### Issue: Kafka Connection Refused
```bash
# Solution: Ensure Docker containers are running
docker-compose ps
docker-compose logs kafka

# Restart if needed
docker-compose restart kafka
```

### Issue: Application Insights Not Logging
```bash
# Solution: Verify instrumentation key
# Check if key is correct in .env
# Enable verbose logging
export APPLICATIONINSIGHTS_VERBOSITY_LEVEL=DEBUG
```

## ✅ Ready to Start?

Once all prerequisites are satisfied:

1. Ensure all services are running:
   ```bash
   docker-compose ps
   python scripts/verify-setup.py
   ```

2. Test message flow:
   ```bash
   # Send test message to Service Bus
   python scripts/test-servicebus.py

   # Test event publishing
   python scripts/test-eventhub.py
   ```

3. Access monitoring dashboards:
   - Jaeger UI: http://localhost:16686
   - Prometheus: http://localhost:9090
   - Grafana: http://localhost:3000 (admin/admin)
   - Kafka UI: http://localhost:8080

4. Comece com Exercício 1:
   ```bash
   cd exercises/exercise1-esb
   code .
   ```

Happy learning! 🚀