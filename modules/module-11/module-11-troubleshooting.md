# Module 11: Microservices Architecture - Troubleshooting Guide

## 🔧 Common Issues and Solutions

### 🐳 Docker & Container Issues

#### Problem: "Cannot connect to Docker daemon"
**Symptoms:**
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Solutions:**
1. **Ensure Docker Desktop is running**
   ```bash
   # Check Docker status
   docker info
   
   # On Linux, start Docker service
   sudo systemctl start docker
   
   # Add user to docker group (Linux)
   sudo usermod -aG docker $USER
   # Log out and back in for changes to take effect
   ```

2. **Windows WSL2 Issues**
   - Open Docker Desktop settings
   - Resources → WSL Integration
   - Enable integration with your distro
   - Restart Docker Desktop

#### Problem: "Port already in use"
**Symptoms:**
```
Error: bind: address already in use
```

**Solutions:**
```bash
# Find process using the port
# Linux/macOS
lsof -i :8000
sudo kill -9 <PID>

# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Alternative: Change port in docker-compose.yml
ports:
  - "8001:8000"  # Change external port
```

### 🔗 Service Communication Issues

#### Problem: "Service unavailable" or connection refused
**Symptoms:**
- 503 Service Unavailable
- Connection refused errors
- Timeouts between services

**Solutions:**
1. **Check service health**
   ```bash
   # Check all services are running
   docker compose ps
   
   # Check service logs
   docker compose logs user-service
   
   # Test service directly
   curl http://localhost:8001/health
   ```

2. **Verify network connectivity**
   ```bash
   # Inspect Docker network
   docker network inspect microservices-network
   
   # Test connectivity between containers
   docker exec -it order-service ping user-service
   
   # Check service DNS resolution
   docker exec -it order-service nslookup user-service
   ```

3. **Check environment variables**
   ```bash
   # Verify service URLs
   docker exec -it order-service env | grep SERVICE_URL
   
   # Update docker-compose.yml if needed
   environment:
     - USER_SERVICE_URL=http://user-service:8000
   ```

#### Problem: "Circuit breaker is OPEN"
**Symptoms:**
- Repeated failures trigger circuit breaker
- Services stop attempting connections

**Solutions:**
```python
# Temporarily increase thresholds for debugging
circuit_breaker = CircuitBreaker(
    failure_threshold=10,  # Increase from 5
    recovery_timeout=10    # Decrease from 30
)

# Check circuit breaker metrics
GET /metrics/circuit-breakers

# Manual circuit reset (development only)
circuit_breaker.reset()
```

### 📨 Message Queue Issues

#### Problem: RabbitMQ connection failed
**Symptoms:**
```
pika.exceptions.AMQPConnectionError
```

**Solutions:**
1. **Verify RabbitMQ is running**
   ```bash
   # Check container status
   docker compose ps rabbitmq
   
   # Access management UI
   open http://localhost:15672
   # Default: admin/admin123
   ```

2. **Check credentials and URL**
   ```python
   # Verify connection string
   AMQP_URL = "amqp://admin:admin123@rabbitmq:5672/"
   
   # Test connection
   import aio_pika
   connection = await aio_pika.connect_robust(AMQP_URL)
   ```

3. **Queue/Exchange not found**
   ```bash
   # Create missing exchanges/queues via management UI
   # Or programmatically:
   channel = await connection.channel()
   exchange = await channel.declare_exchange(
       "events", 
       aio_pika.ExchangeType.TOPIC,
       durable=True
   )
   ```

### 💾 Redis Cache Issues

#### Problem: Redis connection timeout
**Symptoms:**
- Cache operations fail
- Increased latency

**Solutions:**
```bash
# Check Redis is running
docker compose ps redis

# Test Redis connection
docker exec -it redis redis-cli ping
# Should return: PONG

# Check Redis memory
docker exec -it redis redis-cli info memory

# Clear cache if needed
docker exec -it redis redis-cli FLUSHALL
```

### 🔍 Service Discovery Issues

#### Problem: Service not discovered
**Symptoms:**
- "Service not found" errors
- Load balancing not working

**Solutions:**
```python
# Manual service registration
await service_discovery.register_service(
    name="user-service",
    host="user-service",  # Use Docker service name
    port=8000,
    health_check_path="/health"
)

# Check registered services
services = await service_discovery.get_all_services("user-service")
print(f"Found {len(services)} instances")

# Verify health checks
for service in services:
    print(f"{service.name}: {service.is_healthy}")
```

### 📊 Performance Issues

#### Problem: High latency between services
**Symptoms:**
- Slow API responses
- Timeouts under load

**Solutions:**
1. **Enable caching**
   ```python
   @cached(ttl=300)
   async def get_user(user_id: str):
       # Expensive operation
       pass
   ```

2. **Optimize database queries**
   ```python
   # Add indexes
   CREATE INDEX idx_user_email ON users(email);
   
   # Use connection pooling
   pool = await asyncpg.create_pool(
       DATABASE_URL,
       min_size=10,
       max_size=20
   )
   ```

3. **Implement batch operations**
   ```python
   # Instead of N queries
   for user_id in user_ids:
       user = await get_user(user_id)
   
   # Use batch query
   users = await get_users_batch(user_ids)
   ```

#### Problem: Memory leaks
**Symptoms:**
- Increasing memory usage over time
- Container restarts

**Solutions:**
```bash
# Monitor memory usage
docker stats

# Set memory limits in docker-compose.yml
deploy:
  resources:
    limits:
      memory: 512M

# Profile Python memory
pip install memory_profiler
python -m memory_profiler app.py
```

### 🔐 Security Issues

#### Problem: Authentication failures
**Symptoms:**
- 401 Unauthorized errors
- Token validation failures

**Solutions:**
```python
# Verify JWT secret is consistent
JWT_SECRET = os.getenv("JWT_SECRET")
if not JWT_SECRET:
    raise ValueError("JWT_SECRET not configured")

# Check token expiration
payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
if payload["exp"] < time.time():
    raise ValueError("Token expired")

# Synchronize service clocks
docker exec -it <container> date
# If times differ, sync with NTP
```

### 📈 Monitoring Issues

#### Problem: Metrics not appearing in Prometheus
**Symptoms:**
- Empty Grafana dashboards
- No metrics in Prometheus

**Solutions:**
1. **Verify metrics endpoint**
   ```bash
   # Test metrics endpoint
   curl http://localhost:8000/metrics
   
   # Check Prometheus targets
   open http://localhost:9090/targets
   ```

2. **Update Prometheus configuration**
   ```yaml
   # prometheus.yml
   scrape_configs:
     - job_name: 'microservices'
       static_configs:
         - targets:
           - 'user-service:8000'
           - 'product-service:8000'
           - 'order-service:8000'
   ```

3. **Restart Prometheus**
   ```bash
   docker compose restart prometheus
   ```

### 🐛 Debugging Tips

#### Enable Debug Logging
```python
# In your service
import logging
logging.basicConfig(level=logging.DEBUG)

# Or via environment variable
LOG_LEVEL=DEBUG
```

#### Use Docker Compose Logs
```bash
# Follow all logs
docker compose logs -f

# Specific service with timestamps
docker compose logs -f --timestamps user-service

# Last 100 lines
docker compose logs --tail=100 order-service
```

#### Interactive Debugging
```bash
# Enter container shell
docker exec -it user-service /bin/sh

# Run Python debugger
docker exec -it user-service python -m pdb app.py

# Attach to running process
docker exec -it user-service python -m debugpy --listen 0.0.0.0:5678 app.py
```

#### Network Debugging
```bash
# Capture traffic between services
docker run --rm -it --net container:user-service \
  nicolaka/netshoot tcpdump -i eth0 port 8000

# Test with curl from within network
docker run --rm -it --network microservices-network \
  curlimages/curl curl http://user-service:8000/health
```

### 🚨 Emergency Procedures

#### Service Won't Start
1. Check logs: `docker compose logs <service>`
2. Verify Dockerfile: `docker build -t test ./service-dir`
3. Run interactively: `docker run -it test /bin/sh`
4. Check dependencies are installed

#### Complete System Reset
```bash
# Stop all services
docker compose down -v

# Remove all containers and images
docker system prune -a

# Rebuild everything
docker compose build --no-cache
docker compose up -d
```

#### Data Recovery
```bash
# Backup Redis data
docker exec -it redis redis-cli BGSAVE

# Export PostgreSQL data
docker exec -it postgres pg_dump -U user dbname > backup.sql

# Restore from backup
docker exec -i postgres psql -U user dbname < backup.sql
```

## 📞 Getting Help

1. **Check Exercise Solutions**: Review the complete working solutions
2. **GitHub Discussions**: Post questions with full error messages
3. **Module Resources**: Check architecture diagrams and documentation
4. **Community Discord**: Real-time help from other learners

Remember: Most issues are related to networking, environment variables, or service dependencies. Always check these first!