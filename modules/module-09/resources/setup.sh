#!/bin/bash

# Module 09: Database Design and Optimization - Setup Script
# This script sets up the complete environment for Module 09

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🚀 Setting up Module 09: Database Design and Optimization"
echo "========================================================"

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if running with appropriate permissions
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root!"
   exit 1
fi

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    DISTRO=$(lsb_release -si 2>/dev/null || echo "unknown")
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    OS="windows"
fi

echo "Detected OS: $OS"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install PostgreSQL
install_postgresql() {
    echo "📦 Installing PostgreSQL..."
    
    if [[ "$OS" == "macos" ]]; then
        if command_exists brew; then
            brew install postgresql@15
            brew services start postgresql@15
            print_status "PostgreSQL installed and started"
        else
            print_error "Homebrew not found. Please install Homebrew first."
            exit 1
        fi
    elif [[ "$OS" == "linux" ]]; then
        if [[ "$DISTRO" == "Ubuntu" || "$DISTRO" == "Debian" ]]; then
            sudo apt-get update
            sudo apt-get install -y postgresql postgresql-contrib
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
            print_status "PostgreSQL installed and started"
        else
            print_warning "Please install PostgreSQL manually for your distribution"
        fi
    else
        print_warning "Please install PostgreSQL manually for Windows"
    fi
}

# Function to install Redis
install_redis() {
    echo "📦 Installing Redis..."
    
    if [[ "$OS" == "macos" ]]; then
        if command_exists brew; then
            brew install redis
            brew services start redis
            print_status "Redis installed and started"
        else
            print_error "Homebrew not found. Please install Homebrew first."
            exit 1
        fi
    elif [[ "$OS" == "linux" ]]; then
        if [[ "$DISTRO" == "Ubuntu" || "$DISTRO" == "Debian" ]]; then
            sudo apt-get update
            sudo apt-get install -y redis-server
            sudo systemctl start redis-server
            sudo systemctl enable redis-server
            print_status "Redis installed and started"
        else
            print_warning "Please install Redis manually for your distribution"
        fi
    else
        print_warning "Please install Redis manually for Windows"
    fi
}

# Check Python version
echo "🐍 Checking Python installation..."
if command_exists python3; then
    PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    REQUIRED_VERSION="3.11"
    
    if (( $(echo "$PYTHON_VERSION < $REQUIRED_VERSION" | bc -l) )); then
        print_error "Python $REQUIRED_VERSION or higher is required (found $PYTHON_VERSION)"
        exit 1
    else
        print_status "Python $PYTHON_VERSION found"
    fi
else
    print_error "Python 3 not found. Please install Python 3.11 or higher."
    exit 1
fi

# Check and install PostgreSQL
echo "🐘 Checking PostgreSQL..."
if command_exists psql; then
    PG_VERSION=$(psql --version | awk '{print $3}' | cut -d. -f1)
    if [[ $PG_VERSION -ge 15 ]]; then
        print_status "PostgreSQL $PG_VERSION found"
    else
        print_warning "PostgreSQL 15+ recommended (found version $PG_VERSION)"
    fi
else
    install_postgresql
fi

# Check and install Redis
echo "🔴 Checking Redis..."
if command_exists redis-cli; then
    REDIS_VERSION=$(redis-cli --version | awk '{print $2}' | cut -d= -f2)
    print_status "Redis $REDIS_VERSION found"
else
    install_redis
fi

# Create Python virtual environment
echo "🐍 Creating Python virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    print_status "Virtual environment created"
else
    print_status "Virtual environment already exists"
fi

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
echo "📦 Upgrading pip..."
pip install --upgrade pip setuptools wheel

# Install Python dependencies
echo "📦 Installing Python dependencies..."
cat > requirements.txt << EOF
# Database
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
alembic==1.13.0
redis==5.0.1
asyncpg==0.29.0

# Azure (optional)
azure-cosmos==4.5.1
azure-search-documents==11.4.0

# Web framework
fastapi==0.104.1
uvicorn==0.24.0
websockets==12.0

# Data processing
pandas==2.1.4
numpy==1.26.2

# Vector search
pgvector==0.2.4
sentence-transformers==2.2.2
faiss-cpu==1.7.4

# Streaming (optional)
aiokafka==0.10.0

# Utilities
python-dotenv==1.0.0
pydantic==2.5.0
pydantic-settings==2.1.0

# Development
pytest==7.4.3
pytest-asyncio==0.21.1
black==23.11.0
mypy==1.7.0
locust==2.17.0

# Monitoring
prometheus-client==0.19.0
EOF

pip install -r requirements.txt
print_status "Python dependencies installed"

# Setup PostgreSQL databases
echo "🐘 Setting up PostgreSQL databases..."

# Function to setup PostgreSQL
setup_postgresql() {
    # Check if we can connect to PostgreSQL
    if sudo -u postgres psql -c '\q' 2>/dev/null; then
        # Create user and databases
        sudo -u postgres psql << EOF
-- Create workshop user if not exists
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'workshop_user') THEN
        CREATE USER workshop_user WITH PASSWORD 'workshop_pass';
    END IF;
END
\$\$;

-- Create databases
CREATE DATABASE IF NOT EXISTS workshop_db;
CREATE DATABASE IF NOT EXISTS ecommerce_db;
CREATE DATABASE IF NOT EXISTS ecommerce_test;
CREATE DATABASE IF NOT EXISTS analytics_db;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE workshop_db TO workshop_user;
GRANT ALL PRIVILEGES ON DATABASE ecommerce_db TO workshop_user;
GRANT ALL PRIVILEGES ON DATABASE ecommerce_test TO workshop_user;
GRANT ALL PRIVILEGES ON DATABASE analytics_db TO workshop_user;

-- Connect to each database and create extensions
\c workshop_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgvector";

\c ecommerce_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgvector";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

\c analytics_db
CREATE EXTENSION IF NOT EXISTS "timescaledb";
CREATE EXTENSION IF NOT EXISTS "pgvector";
EOF
        print_status "PostgreSQL databases and extensions created"
    else
        print_warning "Could not connect to PostgreSQL as postgres user"
        print_warning "Please run the following commands manually:"
        cat << EOF

sudo -u postgres psql
CREATE USER workshop_user WITH PASSWORD 'workshop_pass';
CREATE DATABASE workshop_db;
CREATE DATABASE ecommerce_db;
CREATE DATABASE ecommerce_test;
CREATE DATABASE analytics_db;
GRANT ALL PRIVILEGES ON DATABASE workshop_db TO workshop_user;
GRANT ALL PRIVILEGES ON DATABASE ecommerce_db TO workshop_user;
GRANT ALL PRIVILEGES ON DATABASE ecommerce_test TO workshop_user;
GRANT ALL PRIVILEGES ON DATABASE analytics_db TO workshop_user;

EOF
    fi
}

setup_postgresql

# Test PostgreSQL connection
echo "🧪 Testing PostgreSQL connection..."
if PGPASSWORD=workshop_pass psql -h localhost -U workshop_user -d workshop_db -c "SELECT version();" >/dev/null 2>&1; then
    print_status "PostgreSQL connection successful"
else
    print_error "Could not connect to PostgreSQL"
    print_warning "Please check your PostgreSQL installation and user setup"
fi

# Test Redis connection
echo "🧪 Testing Redis connection..."
if redis-cli ping | grep -q PONG; then
    print_status "Redis connection successful"
else
    print_error "Could not connect to Redis"
    print_warning "Please check your Redis installation"
fi

# Create .env file
echo "📝 Creating .env file..."
cat > .env << EOF
# PostgreSQL
DATABASE_URL=postgresql://workshop_user:workshop_pass@localhost/workshop_db
ECOMMERCE_DATABASE_URL=postgresql://workshop_user:workshop_pass@localhost/ecommerce_db
TEST_DATABASE_URL=postgresql://workshop_user:workshop_pass@localhost/ecommerce_test
ANALYTICS_DATABASE_URL=postgresql://workshop_user:workshop_pass@localhost/analytics_db

# Redis
REDIS_URL=redis://localhost:6379/0

# Azure (optional - update with your values)
AZURE_COSMOS_ENDPOINT=https://your-cosmos.documents.azure.com:443/
AZURE_COSMOS_KEY=your-key-here
AZURE_SEARCH_ENDPOINT=https://your-search.search.windows.net
AZURE_SEARCH_KEY=your-key-here

# Application
APP_ENV=development
LOG_LEVEL=INFO
SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(32))')

# GitHub (optional)
GITHUB_TOKEN=your-token-here
EOF

print_status ".env file created"

# Create project directories
echo "📁 Creating project directories..."
mkdir -p exercises/{exercise1-easy,exercise2-medium,exercise3-hard}/{starter,solution,tests}
mkdir -p scripts
mkdir -p resources
mkdir -p infrastructure/{docker,kubernetes}

print_status "Project directories created"

# Create Docker Compose file for easy setup
echo "🐳 Creating Docker Compose configuration..."
cat > docker-compose.yml << EOF
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: workshop_user
      POSTGRES_PASSWORD: workshop_pass
      POSTGRES_DB: workshop_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U workshop_user"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  pgadmin:
    image: dpage/pgadmin4:latest
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@workshop.local
      PGADMIN_DEFAULT_PASSWORD: admin
    ports:
      - "5050:80"
    depends_on:
      - postgres

volumes:
  postgres_data:
EOF

print_status "Docker Compose configuration created"

# Create database initialization script
echo "📝 Creating database initialization script..."
cat > scripts/init-db.sql << 'EOF'
-- Create additional databases
CREATE DATABASE IF NOT EXISTS ecommerce_db;
CREATE DATABASE IF NOT EXISTS ecommerce_test;
CREATE DATABASE IF NOT EXISTS analytics_db;

-- Create extensions in workshop_db
\c workshop_db;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgvector";

-- Create extensions in ecommerce_db
\c ecommerce_db;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgvector";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create extensions in analytics_db
\c analytics_db;
CREATE EXTENSION IF NOT EXISTS "timescaledb" CASCADE;
CREATE EXTENSION IF NOT EXISTS "pgvector";
EOF

print_status "Database initialization script created"

# Create validation script
echo "📝 Creating validation script..."
cat > scripts/validate_setup.py << 'EOF'
#!/usr/bin/env python3
"""Validate Module 09 setup"""

import sys
import os
import importlib
import subprocess
from pathlib import Path

def check_python_version():
    """Check Python version"""
    version = sys.version_info
    if version.major >= 3 and version.minor >= 11:
        print("✅ Python version: {}.{}".format(version.major, version.minor))
        return True
    else:
        print("❌ Python 3.11+ required, found: {}.{}".format(version.major, version.minor))
        return False

def check_package(package_name):
    """Check if a Python package is installed"""
    try:
        importlib.import_module(package_name.replace('-', '_'))
        print(f"✅ {package_name} installed")
        return True
    except ImportError:
        print(f"❌ {package_name} not installed")
        return False

def check_postgresql():
    """Check PostgreSQL connection"""
    try:
        import psycopg2
        conn = psycopg2.connect(os.getenv("DATABASE_URL"))
        cursor = conn.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        print(f"✅ PostgreSQL connected: {version.split(',')[0]}")
        
        # Check extensions
        cursor.execute("SELECT * FROM pg_extension WHERE extname IN ('uuid-ossp', 'pgvector');")
        extensions = cursor.fetchall()
        for ext in extensions:
            print(f"✅ Extension '{ext[1]}' installed")
        
        conn.close()
        return True
    except Exception as e:
        print(f"❌ PostgreSQL connection failed: {e}")
        return False

def check_redis():
    """Check Redis connection"""
    try:
        import redis
        r = redis.from_url(os.getenv("REDIS_URL", "redis://localhost:6379/0"))
        r.ping()
        print("✅ Redis connected")
        return True
    except Exception as e:
        print(f"❌ Redis connection failed: {e}")
        return False

def check_environment():
    """Check environment variables"""
    required_vars = ["DATABASE_URL", "REDIS_URL"]
    all_present = True
    
    for var in required_vars:
        if os.getenv(var):
            print(f"✅ Environment variable {var} set")
        else:
            print(f"❌ Environment variable {var} not set")
            all_present = False
    
    return all_present

def main():
    """Run all checks"""
    print("🔍 Validating Module 09 Setup\n")
    
    # Load .env file
    from dotenv import load_dotenv
    load_dotenv()
    
    checks = [
        ("Python Version", check_python_version),
        ("Environment Variables", check_environment),
        ("SQLAlchemy", lambda: check_package("sqlalchemy")),
        ("Redis-py", lambda: check_package("redis")),
        ("FastAPI", lambda: check_package("fastapi")),
        ("PostgreSQL Connection", check_postgresql),
        ("Redis Connection", check_redis),
    ]
    
    results = []
    for name, check_func in checks:
        print(f"\n📋 Checking {name}...")
        results.append(check_func())
    
    print("\n" + "="*50)
    if all(results):
        print("✅ All checks passed! Ready for Module 09")
        return 0
    else:
        print("❌ Some checks failed. Please fix the issues above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
EOF

chmod +x scripts/validate_setup.py
print_status "Validation script created"

# Run validation
echo "🔍 Running validation..."
python scripts/validate_setup.py

# Create sample data script
echo "📝 Creating sample data script..."
cat > scripts/create_sample_data.py << 'EOF'
#!/usr/bin/env python3
"""Create sample data for Module 09 exercises"""

import os
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from dotenv import load_dotenv
load_dotenv()

# Import from exercise solutions
from exercises.exercise1_easy.solution.models import create_database, create_sample_data

if __name__ == "__main__":
    print("Creating database schema...")
    create_database()
    print("Creating sample data...")
    create_sample_data()
    print("Done!")
EOF

chmod +x scripts/create_sample_data.py
print_status "Sample data script created"

# Final instructions
echo ""
echo "✅ Module 09 setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Activate the virtual environment:"
echo "   source venv/bin/activate"
echo ""
echo "2. Run the validation script:"
echo "   python scripts/validate_setup.py"
echo ""
echo "3. Start with Exercise 1:"
echo "   cd exercises/exercise1-easy"
echo "   code ."
echo ""
echo "💡 Tips:"
echo "- Use 'docker-compose up' for containerized PostgreSQL and Redis"
echo "- Access pgAdmin at http://localhost:5050 (admin@workshop.local/admin)"
echo "- Check the troubleshooting guide if you encounter issues"
echo ""
echo "Happy coding! 🚀"