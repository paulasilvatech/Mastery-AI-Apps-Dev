# Real-Time Analytics Dashboard Architecture

## 🎯 System Overview

Build a production-ready real-time analytics dashboard that demonstrates mastery of GitHub Copilot's context-aware development features.

## 📋 Requirements

### Functional Requirements
1. **Real-time Data Processing**
   - Handle streaming data from multiple sources
   - Process 10,000+ events per second
   - Sub-100ms latency for real-time updates

2. **Analytics Engine**
   - Time-series analysis with multiple window sizes
   - Anomaly detection using statistical methods
   - Predictive modeling for trend forecasting
   - Custom metric calculations

3. **API Layer**
   - RESTful API for historical data
   - WebSocket for real-time updates
   - GraphQL for flexible queries
   - Rate limiting and authentication

4. **Performance**
   - Multi-level caching (memory, Redis, database)
   - Query optimization
   - Horizontal scaling support
   - Background job processing

### Non-Functional Requirements
- **Reliability**: 99.9% uptime
- **Security**: OAuth2 authentication, encrypted data
- **Scalability**: Handle 10x traffic spikes
- **Maintainability**: Clean architecture, comprehensive tests

## 🏗️ Architecture Design

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Data Sources  │────▶│ Ingestion Layer │────▶│ Processing Layer│
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                          │
                                                          ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   API Clients   │◀────│    API Layer    │◀────│  Analytics Core │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                          │
                                                          ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Cache (Redis)  │◀────│ Storage Layer   │────▶│   Time Series   │
└─────────────────┘     └─────────────────┘     │    Database     │
                                                 └─────────────────┘
```

## 🔧 Technology Stack

### Core Technologies
- **Language**: Python 3.11+
- **Web Framework**: FastAPI
- **WebSocket**: Python-socketio
- **Async**: asyncio, aiohttp
- **Caching**: Redis
- **Database**: PostgreSQL with TimescaleDB
- **Message Queue**: Redis Streams or Kafka

### Analytics Libraries
- **Time Series**: pandas, numpy
- **ML/Anomaly Detection**: scikit-learn, prophet
- **Visualization**: plotly (for API responses)

## 📁 Project Structure

```
analytics-dashboard/
├── .copilot/
│   └── instructions.md      # Custom Copilot instructions
├── src/
│   ├── ingestion/          # Data ingestion pipeline
│   │   ├── __init__.py
│   │   ├── stream_processor.py
│   │   ├── validators.py
│   │   └── batch_processor.py
│   ├── analytics/          # Analytics engine
│   │   ├── __init__.py
│   │   ├── engine.py
│   │   ├── metrics/
│   │   ├── anomaly/
│   │   └── predictions/
│   ├── api/               # API layer
│   │   ├── __init__.py
│   │   ├── rest/
│   │   ├── websocket/
│   │   └── graphql/
│   ├── cache/             # Caching layer
│   │   ├── __init__.py
│   │   ├── manager.py
│   │   └── strategies/
│   ├── storage/           # Data persistence
│   │   ├── __init__.py
│   │   ├── models.py
│   │   └── repositories/
│   └── utils/             # Utilities
│       ├── __init__.py
│       ├── config.py
│       └── monitoring.py
├── tests/                 # Test suite
├── docs/                  # Documentation
└── deployment/           # Deployment configs
```

## 🚀 Implementation Strategy

### Phase 1: Foundation (20 minutes)
1. Set up project structure
2. Configure Copilot custom instructions
3. Create base classes and protocols
4. Set up configuration management

### Phase 2: Core Implementation (40 minutes)
1. Build streaming data processor
2. Implement analytics engine
3. Create caching layer
4. Build API endpoints

### Phase 3: Integration (30 minutes)
1. Connect all components
2. Add WebSocket support
3. Implement GraphQL schema
4. Performance optimization

## 💡 Copilot Context Optimization Tips

### 1. Custom Instructions Template
```markdown
# Analytics Dashboard Project Context

## Architecture Patterns
- Event-driven architecture for real-time processing
- Repository pattern for data access
- Strategy pattern for analytics algorithms
- Circuit breaker for external services

## Performance Requirements
- Process 10,000 events/second
- Sub-100ms API response time
- Support 1,000 concurrent WebSocket connections
- Cache hit ratio > 80%

## Code Standards
- Type hints for all functions
- Comprehensive error handling
- Async/await for I/O operations
- Docstrings with examples
```

### 2. Context Priming Examples
```python
# Context: Building high-performance streaming processor
# Requirements: Handle backpressure, validate data, batch for efficiency
# Pattern: Producer-consumer with async generators
# Performance: Process 10k events/second with <100ms latency
```

### 3. Multi-File Context Strategy
- Keep these files open while developing:
  - `models.py` - Data structures
  - `protocols.py` - Interfaces
  - `config.py` - Configuration
  - Current implementation file

## 🎯 Success Metrics

Your implementation should achieve:
- [ ] 10,000+ events/second throughput
- [ ] <100ms p95 API latency
- [ ] 80%+ cache hit ratio
- [ ] 100% test coverage for core logic
- [ ] Clean architecture with clear separation
- [ ] Production-ready error handling
- [ ] Comprehensive monitoring/logging

## 🔍 Evaluation Criteria

1. **Architecture Quality**
   - Clean separation of concerns
   - Proper use of design patterns
   - Scalability considerations

2. **Code Quality**
   - Type safety throughout
   - Comprehensive error handling
   - Clear documentation

3. **Performance**
   - Efficient algorithms
   - Proper caching strategy
   - Async operations

4. **Copilot Usage**
   - Effective context optimization
   - Smart use of custom instructions
   - Leveraging multi-file awareness

## 📚 Resources

- [FastAPI Best Practices](https://fastapi.tiangolo.com/tutorial/best-practices/)
- [Async Python Patterns](https://docs.python.org/3/library/asyncio-task.html)
- [Redis Caching Strategies](https://redis.io/docs/manual/patterns/)
- [Time Series Analysis](https://pandas.pydata.org/docs/user_guide/timeseries.html)