# COBOL Modernization Troubleshooting Guide

## 🔍 Overview

This guide helps diagnose and resolve common issues encountered during COBOL modernization projects. Each issue includes symptoms, root causes, diagnostic steps, and solutions.

## 📋 Quick Diagnostics

### System Health Check Script
```bash
#!/bin/bash
# COBOL Modernization Health Check

echo "🔍 Running COBOL Modernization Diagnostics..."

# Check COBOL compiler
echo -e "\n📦 COBOL Environment:"
cobc --version 2>/dev/null || echo "❌ COBOL compiler not found"

# Check Python environment
echo -e "\n🐍 Python Environment:"
python --version
pip list | grep -E "ply|pandas|openai" || echo "⚠️ Missing Python packages"

# Check services
echo -e "\n🔌 Service Status:"
curl -s http://localhost:8001/health || echo "❌ COBOL Adapter not responding"
curl -s http://localhost:8000/health || echo "❌ API Gateway not responding"

# Check databases
echo -e "\n💾 Database Status:"
psql -h localhost -U postgres -c "SELECT 1" 2>/dev/null || echo "❌ PostgreSQL not accessible"
redis-cli ping 2>/dev/null || echo "❌ Redis not accessible"

# Check file permissions
echo -e "\n📁 File Permissions:"
ls -la *.DAT 2>/dev/null || echo "⚠️ No COBOL data files found"

echo -e "\n✅ Diagnostics complete!"
```

## 🚨 Common Issues and Solutions

### 1. COBOL Compilation Errors

#### Issue: "Undefined reference" during compilation
**Symptoms:**
```
BANKCORE.cbl:150: Error: 'WS-SOURCE-ACCOUNT' is not defined
```

**Diagnosis:**
```bash
# Check for missing COPY statements
grep -n "COPY" *.cbl

# Verify copybook locations
echo $COBCPY
ls -la $COBCPY/*.cpy
```

**Solution:**
```bash
# Set copybook path
export COBCPY=/path/to/copybooks:$COBCPY

# Create missing working storage
cat >> missing-vars.cpy << 'EOF'
       01  WS-SOURCE-ACCOUNT.
           05  WS-SOURCE-BALANCE    PIC S9(9)V99.
           05  WS-SOURCE-STATUS     PIC X.
EOF

# Include in program
# Add after WORKING-STORAGE SECTION:
#     COPY missing-vars.
```

#### Issue: "File status 35" - File not found
**Symptoms:**
```
File status 35 on OPEN ACCOUNT-MASTER
```

**Solution:**
```bash
# Create required files
touch ACCOUNTS.DAT TRANSLOG.DAT

# Set proper permissions
chmod 666 *.DAT

# Initialize indexed file
cat > init-files.cbl << 'EOF'
       IDENTIFICATION DIVISION.
       PROGRAM-ID. INIT-FILES.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-MASTER ASSIGN TO "ACCOUNTS.DAT"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS ACCT-NUMBER.
       DATA DIVISION.
       FILE SECTION.
       FD  ACCOUNT-MASTER.
       01  ACCOUNT-RECORD.
           05  ACCT-NUMBER    PIC X(10).
           05  FILLER         PIC X(190).
       PROCEDURE DIVISION.
           OPEN OUTPUT ACCOUNT-MASTER
           CLOSE ACCOUNT-MASTER
           STOP RUN.
EOF

cobc -x init-files.cbl
./init-files
```

### 2. Parser and Analysis Errors

#### Issue: Python parser fails on COBOL syntax
**Symptoms:**
```python
ParseError: Unexpected token 'EXEC' at line 150
```

**Diagnosis:**
```python
# Test parser on specific section
from cobol_parser import COBOLParser

parser = COBOLParser()
with open('problem.cbl', 'r') as f:
    content = f.read()
    
# Find problematic line
lines = content.split('\n')
for i, line in enumerate(lines[145:155], 145):
    print(f"{i}: {line}")
```

**Solution:**
```python
# Update parser to handle EXEC blocks
def _preprocess_lines(self, lines):
    """Enhanced preprocessing for EXEC blocks"""
    processed = []
    in_exec_block = False
    
    for line in lines:
        # Skip EXEC SQL blocks
        if 'EXEC SQL' in line:
            in_exec_block = True
            continue
        elif 'END-EXEC' in line:
            in_exec_block = False
            continue
        
        if not in_exec_block:
            processed.append(line)
    
    return processed
```

#### Issue: AI analysis returns empty results
**Symptoms:**
```
AI analysis failed: OpenAI API key not set
```

**Solution:**
```bash
# Set API key
export OPENAI_API_KEY="your-key-here"

# Or use .env file
echo "OPENAI_API_KEY=your-key-here" >> .env

# Test API connection
python -c "
import openai
openai.api_key = 'your-key'
response = openai.ChatCompletion.create(
    model='gpt-4',
    messages=[{'role': 'user', 'content': 'Test'}],
    max_tokens=10
)
print('API working:', response.choices[0].message.content)
"
```

### 3. Data Conversion Issues

#### Issue: EBCDIC to ASCII conversion errors
**Symptoms:**
```
UnicodeDecodeError: 'cp037' codec can't decode byte 0x00
```

**Solution:**
```python
def safe_ebcdic_convert(data):
    """Safely convert EBCDIC with error handling"""
    try:
        # Try standard EBCDIC
        return data.decode('cp037')
    except UnicodeDecodeError:
        # Try with error handling
        return data.decode('cp037', errors='replace')
    except Exception as e:
        # Fallback to hex representation
        return data.hex()

# For binary/packed fields
def convert_mixed_record(record_bytes, layout):
    """Convert record with mixed text/binary fields"""
    result = {}
    offset = 0
    
    for field_name, field_def in layout.items():
        field_len = field_def['length']
        field_type = field_def['type']
        field_data = record_bytes[offset:offset + field_len]
        
        if field_type == 'CHAR':
            result[field_name] = safe_ebcdic_convert(field_data).strip()
        elif field_type == 'PACKED':
            result[field_name] = unpack_decimal(field_data, field_def['scale'])
        elif field_type == 'BINARY':
            result[field_name] = int.from_bytes(field_data, 'big')
        
        offset += field_len
    
    return result
```

#### Issue: Packed decimal conversion incorrect
**Symptoms:**
```
Expected: 12345.67, Got: -8765.43
```

**Solution:**
```python
def unpack_decimal_fixed(packed_bytes, scale=2):
    """Fixed packed decimal conversion"""
    # Handle sign nibble correctly
    digits = []
    
    # Process all bytes except last
    for byte in packed_bytes[:-1]:
        digits.append((byte >> 4) & 0x0F)
        digits.append(byte & 0x0F)
    
    # Last byte special handling
    last_byte = packed_bytes[-1]
    digits.append((last_byte >> 4) & 0x0F)
    
    # Sign nibble: C=+, D=-, F=unsigned
    sign_nibble = last_byte & 0x0F
    is_negative = sign_nibble == 0x0D
    
    # Convert to number
    value = 0
    for digit in digits:
        value = value * 10 + digit
    
    # Apply sign and scale
    if is_negative:
        value = -value
    
    return value / (10 ** scale)

# Test the conversion
test_data = bytes([0x12, 0x34, 0x5C])  # 12345+
result = unpack_decimal_fixed(test_data, 2)
print(f"Result: {result}")  # Should print 123.45
```

### 4. Integration Issues

#### Issue: COBOL adapter timeout
**Symptoms:**
```
TimeoutError: COBOL program execution exceeded 30 seconds
```

**Diagnosis:**
```python
# Check COBOL program for infinite loops
import time

def diagnose_cobol_performance(program_path, test_input):
    """Diagnose COBOL performance issues"""
    
    start = time.time()
    
    # Run with timeout
    try:
        result = subprocess.run(
            [program_path],
            input=test_input.encode(),
            capture_output=True,
            timeout=5  # 5 second timeout for diagnosis
        )
        
        elapsed = time.time() - start
        print(f"Execution time: {elapsed:.2f}s")
        
        if elapsed > 3:
            print("⚠️ Warning: Slow execution detected")
            print("Check for:")
            print("- Large file operations")
            print("- Inefficient searches")
            print("- Nested PERFORM loops")
            
    except subprocess.TimeoutExpired:
        print("❌ Program timeout - likely infinite loop")
        print("Add diagnostic DISPLAY statements to trace execution")
```

**Solution:**
```cobol
* Add diagnostic displays
PROCEDURE DIVISION.
    DISPLAY "DEBUG: Starting main process"
    
    PERFORM INIT-PROCESS
    DISPLAY "DEBUG: Initialization complete"
    
    PERFORM PROCESS-TRANSACTIONS
        UNTIL END-OF-FILE
    DISPLAY "DEBUG: Transaction processing complete"
    
    PERFORM CLEANUP-PROCESS
    DISPLAY "DEBUG: Cleanup complete"
    
    STOP RUN.

* Add loop counters to prevent infinite loops
01  WS-LOOP-COUNTER    PIC 9(6) VALUE ZERO.
01  WS-MAX-ITERATIONS  PIC 9(6) VALUE 100000.

PROCESS-LOOP.
    ADD 1 TO WS-LOOP-COUNTER
    
    IF WS-LOOP-COUNTER > WS-MAX-ITERATIONS
        DISPLAY "ERROR: Loop limit exceeded"
        MOVE "Y" TO WS-ERROR-FLAG
        EXIT PARAGRAPH
    END-IF.
```

### 5. Event Processing Issues

#### Issue: Events not being processed
**Symptoms:**
```
Events published but not received by modern system
```

**Diagnosis:**
```python
# Check Redis pub/sub
import redis

r = redis.Redis()
pubsub = r.pubsub()
pubsub.subscribe('banking_events')

print("Listening for events...")
for message in pubsub.listen():
    if message['type'] == 'message':
        print(f"Received: {message['data']}")
```

**Solution:**
```python
# Ensure event publisher is working
class RobustEventPublisher:
    def __init__(self):
        self.redis = redis.Redis(
            host='localhost',
            port=6379,
            decode_responses=True,
            retry_on_timeout=True,
            socket_keepalive=True
        )
        self.fallback_queue = []
    
    def publish_event(self, event):
        """Publish with fallback"""
        try:
            # Try Redis first
            subscribers = self.redis.publish('banking_events', json.dumps(event))
            
            if subscribers == 0:
                print("⚠️ No subscribers - queuing event")
                self.fallback_queue.append(event)
                
        except redis.ConnectionError:
            print("❌ Redis connection failed - using fallback")
            self.fallback_queue.append(event)
            
        except Exception as e:
            print(f"❌ Publish failed: {e}")
            # Log to file as last resort
            with open('failed_events.log', 'a') as f:
                f.write(f"{json.dumps(event)}\n")
```

### 6. Data Synchronization Issues

#### Issue: Data mismatch between COBOL and modern systems
**Symptoms:**
```
Balance in COBOL: 1500.00
Balance in PostgreSQL: 1499.99
```

**Diagnosis:**
```sql
-- Check for precision issues
SELECT 
    account_number,
    cobol_balance,
    modern_balance,
    ABS(cobol_balance - modern_balance) as difference
FROM 
    balance_comparison
WHERE 
    ABS(cobol_balance - modern_balance) > 0.01
ORDER BY 
    difference DESC;
```

**Solution:**
```python
from decimal import Decimal, ROUND_HALF_UP

class FinancialDataSync:
    """Ensure financial data consistency"""
    
    @staticmethod
    def normalize_amount(amount):
        """Normalize financial amounts"""
        # Convert to Decimal for precision
        if isinstance(amount, float):
            # Convert float to string first to avoid precision issues
            amount = Decimal(str(amount))
        elif isinstance(amount, str):
            amount = Decimal(amount)
        
        # Round to 2 decimal places using banker's rounding
        return amount.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
    
    def sync_account_balance(self, account_id, cobol_balance, modern_balance):
        """Sync with validation"""
        # Normalize both values
        cobol_norm = self.normalize_amount(cobol_balance)
        modern_norm = self.normalize_amount(modern_balance)
        
        if cobol_norm != modern_norm:
            # Log discrepancy
            self.log_discrepancy({
                'account': account_id,
                'cobol': str(cobol_norm),
                'modern': str(modern_norm),
                'difference': str(cobol_norm - modern_norm)
            })
            
            # COBOL is source of truth during migration
            return cobol_norm
        
        return modern_norm
```

### 7. Performance Issues

#### Issue: Slow response times after modernization
**Symptoms:**
```
COBOL: 50ms average response
Modern: 200ms average response
```

**Diagnosis:**
```python
import cProfile
import pstats

def profile_modern_transaction(account_id, amount):
    """Profile modern system performance"""
    
    profiler = cProfile.Profile()
    profiler.enable()
    
    # Run transaction
    result = process_transaction(account_id, amount)
    
    profiler.disable()
    
    # Analyze results
    stats = pstats.Stats(profiler)
    stats.sort_stats('cumulative')
    stats.print_stats(20)  # Top 20 functions
    
    return result
```

**Solution:**
```python
# Optimize database queries
class OptimizedRepository:
    def __init__(self):
        # Use connection pooling
        self.pool = psycopg2.pool.SimpleConnectionPool(
            1, 20,
            host="localhost",
            database="modern_banking"
        )
        
        # Prepare statements
        self.prepared_statements = {}
    
    def get_account_optimized(self, account_id):
        """Optimized account retrieval"""
        conn = self.pool.getconn()
        try:
            # Use prepared statement
            if 'get_account' not in self.prepared_statements:
                cur = conn.cursor()
                cur.execute(
                    "PREPARE get_account AS "
                    "SELECT * FROM accounts WHERE account_id = $1"
                )
                self.prepared_statements['get_account'] = True
            
            cur = conn.cursor(cursor_factory=RealDictCursor)
            cur.execute("EXECUTE get_account (%s)", (account_id,))
            
            return cur.fetchone()
            
        finally:
            self.pool.putconn(conn)

# Add caching layer
@lru_cache(maxsize=1000)
def get_cached_balance(account_id):
    """Cache frequently accessed data"""
    return get_account_balance(account_id)
```

### 8. Migration Rollback Issues

#### Issue: Unable to rollback after partial migration
**Symptoms:**
```
Some accounts on modern system, others on COBOL
Inconsistent routing causing errors
```

**Solution:**
```python
class MigrationRollbackManager:
    """Handle migration rollbacks safely"""
    
    def __init__(self):
        self.migration_state = self.load_migration_state()
    
    def execute_rollback(self, feature):
        """Rollback specific feature"""
        
        print(f"🔄 Starting rollback for {feature}")
        
        # 1. Stop new migrations
        self.pause_migration(feature)
        
        # 2. Identify affected accounts
        affected = self.get_migrated_accounts(feature)
        print(f"Found {len(affected)} affected accounts")
        
        # 3. Update routing rules
        self.update_routing_rules(feature, target='cobol')
        
        # 4. Sync data back to COBOL
        for account in affected:
            try:
                self.sync_to_cobol(account)
                print(f"✅ Rolled back account {account}")
            except Exception as e:
                print(f"❌ Failed to rollback {account}: {e}")
                # Mark for manual intervention
                self.mark_for_manual_review(account, str(e))
        
        # 5. Verify rollback
        if self.verify_rollback(feature):
            print(f"✅ Rollback complete for {feature}")
            self.update_migration_state(feature, 'rolled_back')
        else:
            print(f"⚠️ Rollback incomplete - manual intervention required")
    
    def sync_to_cobol(self, account_id):
        """Sync modern data back to COBOL"""
        # Get latest data from modern system
        modern_data = self.get_modern_account_data(account_id)
        
        # Convert to COBOL format
        cobol_record = self.convert_to_cobol_format(modern_data)
        
        # Update COBOL file
        self.update_cobol_record(account_id, cobol_record)
        
        # Verify update
        cobol_data = self.read_cobol_record(account_id)
        if not self.verify_data_match(modern_data, cobol_data):
            raise Exception("Data verification failed after sync")
```

## 🛠️ Diagnostic Tools

### COBOL Data File Inspector
```python
#!/usr/bin/env python3
"""Inspect COBOL data files"""

import struct
import sys

def inspect_indexed_file(filename):
    """Inspect COBOL indexed file structure"""
    
    try:
        with open(filename, 'rb') as f:
            # Read header (implementation specific)
            header = f.read(512)
            
            print(f"File: {filename}")
            print(f"Size: {os.path.getsize(filename)} bytes")
            print(f"Header (first 64 bytes): {header[:64].hex()}")
            
            # Try to identify file type
            if header.startswith(b'ISAM'):
                print("Type: ISAM indexed file")
            elif header.startswith(b'\x00\x00'):
                print("Type: Possible VSAM or custom format")
            else:
                print("Type: Unknown format")
            
            # Read some records
            print("\nFirst few records:")
            f.seek(512)  # Skip header
            
            for i in range(5):
                record = f.read(200)  # Assuming 200 byte records
                if not record:
                    break
                    
                # Try to decode
                try:
                    text = record.decode('cp037')
                    print(f"Record {i+1}: {text[:50]}...")
                except:
                    print(f"Record {i+1}: {record[:50].hex()}...")
                    
    except Exception as e:
        print(f"Error reading file: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: inspect_cobol_file.py <filename>")
        sys.exit(1)
    
    inspect_indexed_file(sys.argv[1])
```

### Event Flow Tracer
```python
class EventFlowTracer:
    """Trace events through the system"""
    
    def __init__(self):
        self.traces = {}
    
    def trace_transaction(self, transaction_id):
        """Trace a transaction through all systems"""
        
        print(f"🔍 Tracing transaction: {transaction_id}")
        
        trace = {
            'id': transaction_id,
            'events': [],
            'systems': set(),
            'timeline': []
        }
        
        # Check COBOL logs
        cobol_events = self.search_cobol_logs(transaction_id)
        for event in cobol_events:
            trace['events'].append({
                'system': 'COBOL',
                'time': event['timestamp'],
                'action': event['action'],
                'data': event['data']
            })
            trace['systems'].add('COBOL')
        
        # Check modern database
        modern_events = self.search_modern_db(transaction_id)
        for event in modern_events:
            trace['events'].append({
                'system': 'Modern',
                'time': event['timestamp'],
                'action': event['action'],
                'data': event['data']
            })
            trace['systems'].add('Modern')
        
        # Check event bus
        bus_events = self.search_event_bus(transaction_id)
        for event in bus_events:
            trace['events'].append({
                'system': 'EventBus',
                'time': event['timestamp'],
                'action': event['type'],
                'data': event['payload']
            })
            trace['systems'].add('EventBus')
        
        # Sort by time
        trace['events'].sort(key=lambda x: x['time'])
        
        # Generate timeline
        self.print_timeline(trace)
        
        return trace
    
    def print_timeline(self, trace):
        """Print visual timeline"""
        
        print("\n📊 Transaction Timeline:")
        print("=" * 80)
        
        for event in trace['events']:
            time_str = event['time'].strftime('%H:%M:%S.%f')[:-3]
            system = event['system'].ljust(10)
            action = event['action'].ljust(20)
            
            # Visual indicator
            if event['system'] == 'COBOL':
                indicator = '🟦'
            elif event['system'] == 'Modern':
                indicator = '🟩'
            else:
                indicator = '🟨'
            
            print(f"{time_str} {indicator} {system} | {action} | {event['data']}")
        
        print("=" * 80)
        print(f"Systems involved: {', '.join(trace['systems'])}")
        print(f"Total events: {len(trace['events'])}")
```

## 📊 Performance Monitoring

### Real-time Metrics Dashboard
```python
import psutil
import time

class SystemMonitor:
    """Monitor system resources during migration"""
    
    def monitor_resources(self, duration=60):
        """Monitor system resources"""
        
        print("📊 System Resource Monitor")
        print("Press Ctrl+C to stop\n")
        
        try:
            while duration > 0:
                # CPU usage
                cpu_percent = psutil.cpu_percent(interval=1)
                
                # Memory usage
                memory = psutil.virtual_memory()
                
                # Disk I/O
                disk_io = psutil.disk_io_counters()
                
                # Network I/O
                net_io = psutil.net_io_counters()
                
                # Clear and print
                print("\033[2J\033[H")  # Clear screen
                print(f"⏱️  Time remaining: {duration}s\n")
                
                print(f"🖥️  CPU Usage: {cpu_percent}%")
                print(f"    {'█' * int(cpu_percent/5)}{'░' * (20-int(cpu_percent/5))}")
                
                print(f"\n💾 Memory Usage: {memory.percent}%")
                print(f"    Used: {memory.used/1024/1024/1024:.2f} GB")
                print(f"    Available: {memory.available/1024/1024/1024:.2f} GB")
                
                print(f"\n💿 Disk I/O:")
                print(f"    Read: {disk_io.read_bytes/1024/1024:.2f} MB")
                print(f"    Write: {disk_io.write_bytes/1024/1024:.2f} MB")
                
                print(f"\n🌐 Network I/O:")
                print(f"    Sent: {net_io.bytes_sent/1024/1024:.2f} MB")
                print(f"    Received: {net_io.bytes_recv/1024/1024:.2f} MB")
                
                # Check for issues
                if cpu_percent > 80:
                    print("\n⚠️  WARNING: High CPU usage!")
                if memory.percent > 85:
                    print("\n⚠️  WARNING: High memory usage!")
                
                duration -= 1
                
        except KeyboardInterrupt:
            print("\n\nMonitoring stopped.")
```

## 🆘 Emergency Procedures

### 1. Complete System Rollback
```bash
#!/bin/bash
# Emergency rollback script

echo "🚨 EMERGENCY ROLLBACK PROCEDURE"
echo "This will route ALL traffic back to COBOL"
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Rollback cancelled"
    exit 1
fi

# 1. Update routing rules
curl -X POST http://localhost:8000/api/v1/migration/rollback

# 2. Clear modern system cache
redis-cli FLUSHDB

# 3. Stop modern services
systemctl stop modern-banking-service

# 4. Update load balancer
# (Implementation specific)

# 5. Notify team
echo "Rollback complete. Sending notifications..."
# Send alerts

echo "✅ Emergency rollback complete"
```

### 2. Data Recovery
```python
class DataRecoveryManager:
    """Recover from data corruption"""
    
    def recover_from_backup(self, backup_date):
        """Restore COBOL files from backup"""
        
        print(f"🔄 Starting recovery from {backup_date}")
        
        # 1. Stop all processing
        self.stop_all_services()
        
        # 2. Backup current files
        self.backup_current_state()
        
        # 3. Restore COBOL files
        backup_files = [
            'ACCOUNTS.DAT',
            'TRANSLOG.DAT',
            'ACCOUNTS.IDX'
        ]
        
        for file in backup_files:
            backup_path = f"/backups/{backup_date}/{file}"
            if os.path.exists(backup_path):
                shutil.copy2(backup_path, file)
                print(f"✅ Restored {file}")
            else:
                print(f"❌ Backup not found: {file}")
        
        # 4. Rebuild indexes if needed
        self.rebuild_indexes()
        
        # 5. Verify integrity
        if self.verify_file_integrity():
            print("✅ Recovery successful")
            self.start_services()
        else:
            print("❌ Recovery failed - manual intervention required")
```

## 📚 Additional Resources

### Debug Flags
```bash
# Enable COBOL debugging
export COB_SET_DEBUG=Y
export COB_TRACE_FILE=cobol_trace.log

# Enable Python debugging
export PYTHONDEBUG=1
export PYTHONASYNCIODEBUG=1

# Enable SQL logging
export POSTGRES_LOG_STATEMENT=all
```

### Useful Commands
```bash
# Check COBOL file structure
od -c ACCOUNTS.DAT | head -20

# Monitor file access
lsof | grep -E "ACCOUNTS|TRANSLOG"

# Check process status
ps aux | grep -E "cobol|python|java"

# Network connections
netstat -tuln | grep -E "8000|8001|5432|6379"

# Disk space
df -h | grep -E "/$|/data"
```

## ✅ Troubleshooting Checklist

When issues occur:

- [ ] Check all service health endpoints
- [ ] Verify database connectivity
- [ ] Check file permissions and disk space
- [ ] Review recent changes
- [ ] Check system resources (CPU, memory)
- [ ] Look for error patterns in logs
- [ ] Test with minimal example
- [ ] Try rollback if necessary
- [ ] Document issue and resolution

---

**Remember**: During modernization, always prioritize data integrity over performance. When in doubt, fall back to the COBOL system.