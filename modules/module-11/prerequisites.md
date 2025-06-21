# Prerequisites for Module 11: Microservices Architecture

## 🎓 Required Knowledge

### From Previous Modules
- ✅ **Module 6**: Multi-file project management
- ✅ **Module 7**: Web application development
- ✅ **Module 8**: API development and REST principles
- ✅ **Module 9**: Database design and SQL
- ✅ **Module 10**: Async programming and event handling

### Programming Concepts
- Object-oriented programming principles
- Asynchronous programming (async/await)
- RESTful API design
- Basic networking concepts (HTTP, TCP/IP)
- JSON data manipulation

## 🛠️ Technical Requirements

### Software Installation

```bash
# Check all requirements
./scripts/check-prerequisites.sh
```

#### Required Software
1. **Docker Desktop** (v24.0+)
   ```bash
   docker --version
   # Expected: Docker version 24.0.0 or higher
   ```

2. **Docker Compose** (v2.20+)
   ```bash
   docker compose version
   # Expected: Docker Compose version v2.20.0 or higher
   ```

3. **Python** (3.11+)
   ```bash
   python --version
   # Expected: Python 3.11.0 or higher
   ```

4. **Node.js** (18+)
   ```bash
   node --version
   # Expected: v18.0.0 or higher
   ```

5. **Git** (2.38+)
   ```bash
   git --version
   # Expected: git version 2.38.0 or higher
   ```

### Python Packages
```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: .\venv\Scripts\activate

# Install required packages
pip install -r requirements.txt
```

Required packages:
- fastapi==0.104.1
- uvicorn==0.24.0
- httpx==0.25.1
- pydantic==2.5.0
- redis==5.0.1
- aio-pika==9.3.0
- prometheus-client==0.19.0
- opentelemetry-api==1.21.0
- opentelemetry-sdk==1.21.0
- opentelemetry-instrumentation-fastapi==0.42b0
- pytest==7.4.3
- pytest-asyncio==0.21.1

### Node.js Packages
```bash
# For gRPC exercises
npm install -g @grpc/grpc-js @grpc/proto-loader
```

### VS Code Extensions
Ensure these extensions are installed and configured:
- ✅ GitHub Copilot
- ✅ Python
- ✅ Docker
- ✅ REST Client
- ✅ YAML
- ✅ Remote - Containers (optional but recommended)

## 📊 System Requirements

### Minimum Hardware
- **CPU**: 4 cores (8 threads recommended)
- **RAM**: 16GB (32GB recommended for running all services)
- **Storage**: 20GB free space
- **Network**: Stable internet connection

### Operating System
- Windows 11 with WSL2 enabled
- macOS 12+ (Intel or Apple Silicon)
- Ubuntu 20.04+ or similar Linux distribution

## ☁️ Cloud Accounts

### Azure Account (Free Tier Acceptable)
- Azure subscription with the following resource providers:
  - Microsoft.ContainerRegistry
  - Microsoft.ContainerService
  - Microsoft.ServiceBus
  - Microsoft.Cache

### GitHub Account
- GitHub account with Copilot enabled
- Access to create repositories
- GitHub Container Registry access

## 📚 Recommended Preparation

### Concepts to Review
1. **Distributed Systems Basics**
   - CAP theorem
   - Network partitions
   - Eventual consistency

2. **API Design**
   - REST principles
   - HTTP status codes
   - API versioning

3. **Container Basics**
   - Docker fundamentals
   - Container networking
   - Volume management

### Helpful Resources
- [Docker Getting Started](https://docs.docker.com/get-started/)
- [FastAPI Tutorial](https://fastapi.tiangolo.com/tutorial/)
- [Microservices.io](https://microservices.io/)
- [12 Factor App](https://12factor.net/)

## 🔍 Pre-Module Checklist

Run this checklist before starting:

```bash
# 1. Docker is running
docker ps

# 2. Python environment is ready
python -c "import fastapi; print(f'FastAPI {fastapi.__version__} installed')"

# 3. Network connectivity
curl -I https://api.github.com

# 4. Disk space
df -h | grep -E "/$|/home|/Users"

# 5. GitHub Copilot is active
code --list-extensions | grep GitHub.copilot
```

## ⚠️ Common Setup Issues

### Docker Desktop Not Starting
- **Windows**: Enable virtualization in BIOS, ensure WSL2 is updated
- **macOS**: Check for sufficient resources in Docker preferences
- **Linux**: Ensure user is in docker group: `sudo usermod -aG docker $USER`

### Port Conflicts
Default ports used in exercises:
- 8000-8005: Microservices
- 5672: RabbitMQ
- 6379: Redis
- 9090: Prometheus
- 3000: Grafana

Check for conflicts:
```bash
# Linux/macOS
lsof -i :8000

# Windows
netstat -an | findstr :8000
```

### Python Virtual Environment Issues
```bash
# If venv fails, try:
python -m pip install --upgrade pip
python -m venv venv --clear
```

## 🎯 Ready to Start?

Once all prerequisites are met:
1. Clone the workshop repository
2. Navigate to `modules/microservices-architecture`
3. Run `./scripts/setup-module-11.sh`
4. Open the folder in VS Code
5. Start with Exercise 1!

**Note**: This module involves running multiple services simultaneously. Ensure your system has sufficient resources before starting.