---
sidebar_position: 20
title: "Prerequisites"
description: "Requirements and setup for Module 27"
---

# Prerequisites for Module 27: COBOL to Modern AI Migration

## 🎯 Required Knowledge

Before starting this module, ensure you have:

### From Previous Modules
- ✅ **Module 26**: Enterprise .NET AI development skills
- ✅ **Modules 21-25**: AI agent fundamentals and MCP
- ✅ **Enterprise Architecture**: Understanding of large-scale systems
- ✅ **API Development**: RESTful services and microservices

### COBOL & Mainframe Concepts
- ✅ **Basic Programming**: Understanding of procedural programming
- ✅ **Data Structures**: Files, records, and hierarchical data
- ✅ **Batch Processing**: Job scheduling and execution concepts
- ✅ **Transaction Processing**: ACID properties and consistency

### Modern Development Skills
- ✅ **Python or Java**: Proficiency in at least one
- ✅ **SQL**: Database queries and migrations
- ✅ **REST APIs**: Design and implementation
- ✅ **Containerization**: Docker basics
- ✅ **Version Control**: Git proficiency

## 🛠️ Required Software

### COBOL Development Environment

#### Option 1: GnuCOBOL (Recommended - Free)
```bash
# Windows (using Chocolatey)
choco install gnucobol

# macOS (using Homebrew)
brew install gnucobol

# Linux (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install gnucobol

# Verify installation
cobc --version
```

#### Option 2: Micro Focus Visual COBOL (Trial)
- Download from [Micro Focus website](https://www.microfocus.com/products/visual-cobol/)
- 30-day trial available
- Better IDE integration

#### Option 3: IBM COBOL for Linux (Free for Learning)
```bash
# Download IBM COBOL for Linux
wget https://public.dhe.ibm.com/ibmdl/export/pub/software/htp/zos/tools/cobol60.linux.tar.gz
tar -xzf cobol60.linux.tar.gz
./install.sh
```

### COBOL IDE Extensions

#### VS Code Extensions
```bash
# Install COBOL support
code --install-extension bitlang.cobol
code --install-extension broadcommfd.cobol-language-support
code --install-extension rechinformatica.rech-cobol-debugger

# Install supporting tools
code --install-extension mhutchie.git-graph
code --install-extension hediet.vscode-drawio
code --install-extension shd101wyy.markdown-preview-enhanced
```

### Modern Development Stack

#### Python Environment
```bash
# Create virtual environment
python -m venv cobol-migration-env

# Activate environment
# Windows
.\cobol-migration-env\Scripts\activate
# macOS/Linux
source cobol-migration-env/bin/activate

# Install required packages
pip install --upgrade pip
pip install -r requirements.txt
```

Create `requirements.txt`:
```txt
# COBOL Parsing and Analysis
ply==3.11                    # Lexer/Parser generator
antlr4-python3-runtime==4.13 # ANTLR runtime for parsing
pyparsing==3.1.1            # Grammar parsing

# AI and Machine Learning
openai==1.6.1               # OpenAI API
transformers==4.36.2        # Hugging Face transformers
torch==2.1.2                # PyTorch for ML models
pandas==2.1.4               # Data manipulation
numpy==1.26.2               # Numerical operations

# Code Analysis
ast-grep-py==0.12.1         # AST-based code search
tree-sitter==0.20.4         # Code parsing
radon==6.0.1                # Code metrics
pygments==2.17.2            # Syntax highlighting

# Visualization
matplotlib==3.8.2           # Plotting
networkx==3.2.1             # Graph analysis
graphviz==0.20.1           # Graph visualization
plotly==5.18.0             # Interactive plots

# Database
psycopg2-binary==2.9.9     # PostgreSQL adapter
sqlalchemy==2.0.23         # SQL toolkit
alembic==1.13.1            # Database migrations

# API Development
fastapi==0.108.0           # Modern web API
uvicorn==0.25.0            # ASGI server
pydantic==2.5.3            # Data validation

# Testing
pytest==7.4.3              # Testing framework
pytest-cov==4.1.0          # Coverage reports
pytest-asyncio==0.23.2     # Async testing

# Utilities
python-dotenv==1.0.0       # Environment variables
click==8.1.7               # CLI framework
rich==13.7.0               # Terminal formatting
tqdm==4.66.1               # Progress bars
```

#### Java Environment (Alternative)
```bash
# Install Java 17 (LTS)
# Windows
winget install Microsoft.OpenJDK.17

# macOS
brew install openjdk@17

# Linux
sudo apt install openjdk-17-jdk

# Verify installation
java -version
javac -version

# Install Maven
# Windows
winget install Apache.Maven

# macOS
brew install maven

# Linux
sudo apt install maven
```

### Database Setup

#### PostgreSQL Installation
```bash
# Windows
winget install PostgreSQL.PostgreSQL

# macOS
brew install postgresql@15
brew services start postgresql@15

# Linux
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql

# Create migration database
createdb cobol_migration
createdb cobol_legacy
```

#### MongoDB (for modern document storage)
```bash
# Using Docker
docker run -d --name mongodb \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=password \
  mongo:7

# Or install locally
# Windows
winget install MongoDB.Server

# macOS
brew tap mongodb/brew
brew install mongodb-community

# Linux
sudo apt install mongodb
```

### Message Queue Setup

#### Apache Kafka
```bash
# Using Docker Compose
cat &gt; docker-compose.yml &lt;&lt; EOF
version: '3'
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
EOF

docker-compose up -d
```

### Analysis Tools

#### SonarQube for Code Quality
```bash
# Using Docker
docker run -d --name sonarqube \
  -p 9000:9000 \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_logs:/opt/sonarqube/logs \
  -v sonarqube_extensions:/opt/sonarqube/extensions \
  sonarqube:lts-community
```

#### COBOL Code Analysis Tools
```bash
# Install COBOL metrics tool
pip install cobol-metrics

# Install COBOL documentation generator
npm install -g cobol-doc-gen

# Install COBOL to JSON converter
pip install cobol2json
```

## 🏗️ Project Setup

### 1. Create Project Structure
```bash
# Create main project directory
mkdir cobol-ai-migration
cd cobol-ai-migration

# Create directory structure
mkdir -p {cobol-samples/{programs,copybooks,data},modern-code/{analyzers,services,models},migration-tools/{parser,transformer,validator},tests/{cobol,modern,integration},docs,scripts}

# Initialize Git repository
git init
echo "# COBOL to AI Migration Project" &gt; README.md
git add README.md
git commit -m "Initial commit"
```

### 2. Set Up COBOL Sample Environment
```bash
# Create sample COBOL program
cat &gt; cobol-samples/programs/HELLO.cob &lt;&lt; 'EOF'
       IDENTIFICATION DIVISION.
       PROGRAM-ID. HELLO.
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       PROCEDURE DIVISION.
           DISPLAY "HELLO FROM COBOL!".
           STOP RUN.
EOF

# Compile and test
cobc -x cobol-samples/programs/HELLO.cob -o hello
./hello
```

### 3. Configure Modern Development Environment
```bash
# Create Python package structure
touch modern-code/__init__.py
touch modern-code/analyzers/__init__.py
touch modern-code/services/__init__.py

# Create configuration file
cat &gt; .env &lt;&lt; EOF
# COBOL Environment
COBOL_SOURCE_DIR=./cobol-samples/programs
COBOL_COPYBOOK_DIR=./cobol-samples/copybooks
COBOL_DATA_DIR=./cobol-samples/data

# Database Configuration
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=cobol_migration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password

MONGO_URI=mongodb://admin:password@localhost:27017/
MONGO_DB=modern_services

# AI Services
OPENAI_API_KEY=your-api-key-here
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_KEY=your-key-here

# Kafka Configuration
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
KAFKA_TOPIC_PREFIX=cobol-migration

# Monitoring
SONARQUBE_URL=http://localhost:9000
SONARQUBE_TOKEN=your-token-here
EOF

# Add .env to .gitignore
echo ".env" &gt;&gt; .gitignore
```

### 4. Install COBOL Analysis Tools

Create `scripts/setup-cobol-tools.sh`:
```bash
#!/bin/bash

echo "🔧 Setting up COBOL analysis tools..."

# Create Python-based COBOL parser
cat &gt; migration-tools/parser/cobol_parser.py &lt;&lt; 'EOF'
import re
from typing import Dict, List, Tuple

class COBOLParser:
    """Basic COBOL parser for analysis"""
    
    def __init__(self):
        self.divisions = {}
        self.procedures = []
        self.data_items = []
        self.copybooks = []
        
    def parse_file(self, filepath: str) -&gt; Dict:
        """Parse a COBOL file and extract structure"""
        with open(filepath, 'r') as f:
            content = f.read()
            
        # Extract divisions
        self._parse_divisions(content)
        
        # Extract procedures
        self._parse_procedures(content)
        
        # Extract data definitions
        self._parse_data_division(content)
        
        return {
            'divisions': self.divisions,
            'procedures': self.procedures,
            'data_items': self.data_items,
            'copybooks': self.copybooks
        }
    
    def _parse_divisions(self, content: str):
        """Extract COBOL divisions"""
        division_pattern = r'(\w+)\s+DIVISION\.'
        divisions = re.findall(division_pattern, content)
        for division in divisions:
            self.divisions[division] = True
            
    def _parse_procedures(self, content: str):
        """Extract procedure names"""
        proc_pattern = r'^\s*(\w+)\s*\.\s*$'
        procedures = re.findall(proc_pattern, content, re.MULTILINE)
        self.procedures = [p for p in procedures if p.isupper()]
        
    def _parse_data_division(self, content: str):
        """Extract data definitions"""
        data_pattern = r'^\s*(\d{\`2\`})\s+(\w+).*PIC\s+([^\.\s]+)'
        data_items = re.findall(data_pattern, content, re.MULTILINE)
        self.data_items = [
            {'level': level, 'name': name, 'picture': pic}
            for level, name, pic in data_items
        ]

if __name__ == "__main__":
    parser = COBOLParser()
    result = parser.parse_file("cobol-samples/programs/HELLO.cob")
    print(f"Parsed COBOL structure: {result}")
EOF

chmod +x migration-tools/parser/cobol_parser.py
```

## 🔧 Environment Configuration

### 1. COBOL Compiler Configuration
```bash
# Create COBOL configuration file
cat &gt; cobol.conf &lt;&lt; EOF
# GnuCOBOL Configuration
COB_CONFIG_DIR=/usr/local/share/gnucobol/config
COB_LIBRARY_PATH=./lib:$COB_LIBRARY_PATH
COB_PRE_LOAD=
COB_SCREEN_EXCEPTIONS=Y
COB_SCREEN_ESC=Y

# Compiler flags
COB_CFLAGS=-pipe -Wall
COB_LDFLAGS=
EOF

# Export environment variables
export COBCPY=./cobol-samples/copybooks
export COB_CONFIG_DIR=/usr/local/share/gnucobol/config
```

### 2. Database Schema Setup
```sql
-- Create legacy data schema
CREATE SCHEMA IF NOT EXISTS legacy;

-- Example COBOL-style table
CREATE TABLE legacy.customer_master (
    customer_id     CHAR(10) PRIMARY KEY,
    customer_name   CHAR(30),
    address_line_1  CHAR(30),
    address_line_2  CHAR(30),
    city            CHAR(20),
    state           CHAR(2),
    zip_code        CHAR(9),
    phone_number    CHAR(10),
    credit_limit    DECIMAL(9,2),
    balance         DECIMAL(9,2),
    last_payment    DATE,
    status_code     CHAR(1)
);

-- Create modern schema
CREATE SCHEMA IF NOT EXISTS modern;

-- Modern customer table with JSON support
CREATE TABLE modern.customers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    legacy_id       VARCHAR(10) UNIQUE,
    profile         JSONB NOT NULL,
    metadata        JSONB DEFAULT '{}',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    version         INTEGER DEFAULT 1
);

-- Migration tracking
CREATE TABLE modern.migration_log (
    id              SERIAL PRIMARY KEY,
    source_system   VARCHAR(50),
    source_table    VARCHAR(50),
    target_table    VARCHAR(50),
    records_count   INTEGER,
    status          VARCHAR(20),
    started_at      TIMESTAMP,
    completed_at    TIMESTAMP,
    error_details   TEXT
);
```

## 🧪 Validation Script

Create `scripts/validate-prerequisites.sh`:
```bash
#!/bin/bash

echo "🔍 Validating Module 27 Prerequisites..."

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check COBOL compiler
echo -e "\n📦 Checking COBOL Compiler..."
if command -v cobc &&gt; /dev/null; then
    COBOL_VERSION=$(cobc --version | head -n1)
    echo -e "${GREEN}✅ COBOL Compiler: $COBOL_VERSION${NC}"
else
    echo -e "${RED}❌ COBOL compiler not found. Please install GnuCOBOL${NC}"
fi

# Check Python
echo -e "\n🐍 Checking Python..."
if command -v python3 &&gt; /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✅ $PYTHON_VERSION${NC}"
    
    # Check key Python packages
    echo "Checking Python packages..."
    python3 -c "import ply" 2>/dev/null && echo -e "${GREEN}✅ PLY (Parser)${NC}" || echo -e "${YELLOW}⚠️ PLY not installed${NC}"
    python3 -c "import pandas" 2>/dev/null && echo -e "${GREEN}✅ Pandas${NC}" || echo -e "${YELLOW}⚠️ Pandas not installed${NC}"
    python3 -c "import openai" 2>/dev/null && echo -e "${GREEN}✅ OpenAI${NC}" || echo -e "${YELLOW}⚠️ OpenAI not installed${NC}"
else
    echo -e "${RED}❌ Python 3 not found${NC}"
fi

# Check Java (optional)
echo -e "\n☕ Checking Java (optional)..."
if command -v java &&gt; /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n1)
    echo -e "${GREEN}✅ Java installed: $JAVA_VERSION${NC}"
else
    echo -e "${YELLOW}⚠️ Java not found (optional for this module)${NC}"
fi

# Check PostgreSQL
echo -e "\n🐘 Checking PostgreSQL..."
if command -v psql &&gt; /dev/null; then
    PSQL_VERSION=$(psql --version)
    echo -e "${GREEN}✅ $PSQL_VERSION${NC}"
else
    echo -e "${RED}❌ PostgreSQL not found${NC}"
fi

# Check Docker
echo -e "\n🐳 Checking Docker..."
if command -v docker &&gt; /dev/null; then
    if docker ps &&gt; /dev/null; then
        echo -e "${GREEN}✅ Docker is running${NC}"
    else
        echo -e "${YELLOW}⚠️ Docker installed but not running${NC}"
    fi
else
    echo -e "${RED}❌ Docker not found${NC}"
fi

# Check VS Code extensions
echo -e "\n📝 Checking VS Code..."
if command -v code &&gt; /dev/null; then
    echo -e "${GREEN}✅ VS Code installed${NC}"
    echo "Recommended extensions:"
    echo "  - COBOL Language Support"
    echo "  - Python Extension"
    echo "  - Docker Extension"
else
    echo -e "${YELLOW}⚠️ VS Code not found${NC}"
fi

# Test COBOL compilation
echo -e "\n🧪 Testing COBOL compilation..."
if command -v cobc &&gt; /dev/null; then
    cat &gt; test_cobol.cob &lt;&lt; 'EOF'
       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST.
       PROCEDURE DIVISION.
           DISPLAY "COBOL TEST SUCCESSFUL".
           STOP RUN.
EOF
    
    if cobc -x test_cobol.cob -o test_cobol 2>/dev/null; then
        OUTPUT=$(./test_cobol 2>&1)
        if [[ "$OUTPUT" == "COBOL TEST SUCCESSFUL" ]]; then
            echo -e "${GREEN}✅ COBOL compilation working${NC}"
        else
            echo -e "${RED}❌ COBOL execution failed${NC}"
        fi
        rm -f test_cobol test_cobol.cob
    else
        echo -e "${RED}❌ COBOL compilation failed${NC}"
    fi
fi

echo -e "\n✅ Prerequisites check complete!"
```

Make the script executable:
```bash
chmod +x scripts/validate-prerequisites.sh
./scripts/validate-prerequisites.sh
```

## 📊 Resource Requirements

### Minimum System Requirements
- **CPU**: 4 cores (8 recommended)
- **RAM**: 8GB (16GB recommended)
- **Storage**: 10GB free space
- **OS**: Windows 10/11, macOS 12+, or Linux

### Sample COBOL Programs
Download sample COBOL programs:
```bash
# Clone sample repository
git clone https://github.com/openmainframeproject/cobol-programming-course.git samples/cobol-course

# Download additional samples
wget https://raw.githubusercontent.com/openmainframeproject/cobol-samples/main/src/PAYROLL.cbl -P cobol-samples/programs/
wget https://raw.githubusercontent.com/openmainframeproject/cobol-samples/main/src/CUSTOMER.cbl -P cobol-samples/programs/
```

## 🚨 Common Setup Issues

### Issue: COBOL Compiler Not Found
```bash
# Linux alternative installation
sudo add-apt-repository ppa:gnucobol/stable
sudo apt-get update
sudo apt-get install gnucobol

# Build from source if needed
wget https://sourceforge.net/projects/gnucobol/files/gnucobol/3.2/gnucobol-3.2.tar.gz
tar xzf gnucobol-3.2.tar.gz
cd gnucobol-3.2
./configure
make
sudo make install
```

### Issue: Python Package Installation Fails
```bash
# Use conda instead
conda create -n cobol-migration python=3.11
conda activate cobol-migration
conda install pandas numpy matplotlib
pip install openai ply
```

### Issue: PostgreSQL Connection Failed
```bash
# Check PostgreSQL service
sudo systemctl status postgresql

# Create user and database
sudo -u postgres psql
CREATE USER migration_user WITH PASSWORD 'password';
CREATE DATABASE cobol_migration OWNER migration_user;
\q
```

## 📚 Pre-Module Learning

Before starting, review:

1. **COBOL Basics**
   - [COBOL Tutorial](https://www.tutorialspoint.com/cobol/index.htm)
   - [IBM COBOL Documentation](https://www.ibm.com/docs/en/cobol-compiler)
   - [GnuCOBOL Programmer's Guide](https://gnucobol.sourceforge.io/)

2. **Modernization Concepts**
   - [Strangler Fig Pattern](https://martinfowler.com/bliki/StranglerFigApplication.html)
   - [Legacy System Modernization](https://www.redhat.com/en/topics/cloud-native-apps/legacy-modernization)

3. **Enterprise Integration**
   - [Enterprise Integration Patterns](https://www.enterpriseintegrationpatterns.com/)
   - [Microservices Patterns](https://microservices.io/patterns/)

## ✅ Pre-Module Checklist

Before starting the exercises:

- [ ] COBOL compiler installed and working
- [ ] Python/Java environment set up
- [ ] PostgreSQL and MongoDB running
- [ ] Sample COBOL programs available
- [ ] VS Code with COBOL extensions
- [ ] Docker containers running
- [ ] Validation script passes

## 🎯 Ready to Start?

Once all prerequisites are met:

1. Review the [COBOL Language Basics](/docs/resources/cobol-reference)
2. Understand mainframe concepts
3. Start with [Exercise 1: AI-Powered COBOL Analyzer](./exercise1-overview)
4. Join the module discussion for help

---

**Need Help?** Check the [Module 27 Troubleshooting Guide](/docs/guias/troubleshooting) or post in the module discussions.