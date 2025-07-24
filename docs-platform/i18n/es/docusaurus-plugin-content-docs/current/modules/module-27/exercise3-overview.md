---
sidebar_position: 2
title: "Exercise 3: Overview"
description: "## 🎯 Objective"
---

# Ejercicio 3: Hybrid Banking System (⭐⭐⭐ Difícil - 90 minutos)

## 🎯 Objective
Create a producción-ready hybrid banking system where legacy COBOL core banking functions work seamlessly with modern AI services, implementing the strangler fig pattern for gradual migration.

## 🧠 Lo Que Aprenderás
- Strangler fig pattern implementation
- COBOL-to-microservices integration
- Real-time data synchronization
- Event-driven architecture
- AI enhancement of legacy functions
- Gradual migration strategies
- Production despliegue patterns

## 📋 Prerrequisitos
- Completard Ejercicios 1 and 2
- COBOL and Python ambientes ready
- Docker and Docker Compose instalado
- PostgreSQL and Redis running
- Understanding of microservices architecture

## 📚 Atrásground

The strangler fig pattern allows gradual migration by:
- **Wrapping**: Legacy system remains operational
- **Intercepting**: New system handles specific functions
- **Replacing**: Gradually move functionality
- **Retiring**: Eventually decommission legacy partes

For a banking system, this means:
- Core COBOL handles critical transactions
- Modern services add AI capabilities
- Gradual migration of functions
- Zero downtime during transition
- Full audit trail maintained

## 🏗️ Hybrid Architecture

```mermaid
graph TB
    subgraph "Client Layer"
        WEB[Web Banking]
        MOB[Mobile App]
        API[Open Banking API]
    end
    
    subgraph "API Gateway"
        GW[Kong/Nginx]
        AUTH[Authentication]
        ROUTE[Smart Router]
    end
    
    subgraph "Modern Services"
        FRAUD[AI Fraud Detection]
        CHAT[AI Assistant]
        ANAL[Analytics Service]
        NOTIF[Notification Service]
    end
    
    subgraph "Integration Layer"
        ADAPT[COBOL Adapter]
        SYNC[Data Sync]
        EVENT[Event Bus]
        CACHE[Redis Cache]
    end
    
    subgraph "Legacy Core"
        COBOL[COBOL Banking Core]
        CICS[CICS]
        DB2[(DB2)]
        VSAM[(VSAM)]
    end
    
    subgraph "Modern Data"
        PG[(PostgreSQL)]
        MONGO[(MongoDB)]
        KAFKA[Kafka]
    end
    
    WEB --&gt; GW
    MOB --&gt; GW
    API --&gt; GW
    
    GW --&gt; AUTH
    AUTH --&gt; ROUTE
    
    ROUTE --&gt;|New Functions| FRAUD
    ROUTE --&gt;|New Functions| CHAT
    ROUTE --&gt;|Legacy Functions| ADAPT
    
    FRAUD --&gt; EVENT
    CHAT --&gt; EVENT
    ADAPT --&gt; COBOL
    
    COBOL --&gt; CICS
    CICS --&gt; DB2
    CICS --&gt; VSAM
    
    EVENT --&gt; KAFKA
    SYNC --&gt; DB2
    SYNC --&gt; PG
    
    ANAL --&gt; PG
    NOTIF --&gt; KAFKA
    
    style COBOL fill:#1E3A8A
    style FRAUD fill:#10B981
    style ADAPT fill:#F59E0B
    style EVENT fill:#EF4444
```

## 🛠️ Step-by-Step Instructions

### Step 1: Create COBOL Banking Core

**Copilot Prompt Suggestion:**
```cobol
* Create a COBOL banking core that includes:
* - Account management (create, update, close)
* - Transaction processing (deposit, withdraw, transfer)
* - Balance inquiries
* - Interest calculation
* - Transaction history
* Use proper file handling and CICS transactions
```

Create `cobol-core/BANKCORE.cbl`:
```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANKCORE.
       AUTHOR. HYBRID-BANKING-SYSTEM.
       
      ******************************************************************
      * CORE BANKING SYSTEM - HANDLES CRITICAL TRANSACTIONS
      ******************************************************************
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-MASTER ASSIGN TO "ACCOUNTS.DAT"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS ACCT-NUMBER
               FILE STATUS IS WS-FILE-STATUS.
               
           SELECT TRANSACTION-LOG ASSIGN TO "TRANSLOG.DAT"
               ORGANIZATION IS SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-TRANS-STATUS.
       
       DATA DIVISION.
       FILE SECTION.
       FD  ACCOUNT-MASTER.
       01  ACCOUNT-RECORD.
           05  ACCT-NUMBER         PIC X(10).
           05  ACCT-TYPE           PIC X.
               88  CHECKING        VALUE 'C'.
               88  SAVINGS         VALUE 'S'.
               88  LOAN            VALUE 'L'.
           05  CUSTOMER-ID         PIC X(10).
           05  BALANCE             PIC S9(9)V99 COMP-3.
           05  AVAILABLE-BALANCE   PIC S9(9)V99 COMP-3.
           05  HOLD-AMOUNT         PIC S9(9)V99 COMP-3.
           05  INTEREST-RATE       PIC 99V999.
           05  OPENED-DATE         PIC 9(8).
           05  LAST-ACTIVITY       PIC 9(8).
           05  ACCOUNT-STATUS      PIC X.
               88  ACTIVE          VALUE 'A'.
               88  INACTIVE        VALUE 'I'.
               88  CLOSED          VALUE 'C'.
               88  FROZEN          VALUE 'F'.
           05  DAILY-LIMIT         PIC 9(7)V99.
           05  DAILY-WITHDRAWN     PIC 9(7)V99.
       
       FD  TRANSACTION-LOG.
       01  TRANSACTION-RECORD.
           05  TRANS-ID            PIC X(20).
           05  TRANS-DATE          PIC 9(8).
           05  TRANS-TIME          PIC 9(6).
           05  TRANS-TYPE          PIC X(3).
           05  FROM-ACCOUNT        PIC X(10).
           05  TO-ACCOUNT          PIC X(10).
           05  AMOUNT              PIC S9(9)V99.
           05  BALANCE-AFTER       PIC S9(9)V99.
           05  DESCRIPTION         PIC X(50).
           05  CHANNEL             PIC X(10).
           05  STATUS              PIC X.
       
       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS          PIC XX.
       01  WS-TRANS-STATUS         PIC XX.
       01  WS-CURRENT-DATE         PIC 9(8).
       01  WS-CURRENT-TIME         PIC 9(6).
       01  WS-TRANS-COUNTER        PIC 9(10) VALUE ZERO.
       
       01  WS-REQUEST-TYPE         PIC X(10).
           88  CREATE-ACCOUNT      VALUE "CREATE".
           88  DEPOSIT             VALUE "DEPOSIT".
           88  WITHDRAW            VALUE "WITHDRAW".
           88  TRANSFER            VALUE "TRANSFER".
           88  BALANCE-INQ         VALUE "BALANCE".
           88  CLOSE-ACCOUNT       VALUE "CLOSE".
       
       01  WS-RESPONSE.
           05  RESPONSE-CODE       PIC X(3).
           05  RESPONSE-MESSAGE    PIC X(100).
           05  RESPONSE-DATA.
               10  OUT-BALANCE     PIC S9(9)V99.
               10  OUT-AVAILABLE   PIC S9(9)V99.
               10  OUT-TRANS-ID    PIC X(20).
       
       01  WS-ERROR-CODES.
           05  SUCCESS             PIC X(3) VALUE "000".
           05  INSUFFICIENT-FUNDS  PIC X(3) VALUE "001".
           05  ACCOUNT-NOT-FOUND   PIC X(3) VALUE "002".
           05  INVALID-AMOUNT      PIC X(3) VALUE "003".
           05  DAILY-LIMIT-EXCEED  PIC X(3) VALUE "004".
           05  ACCOUNT-FROZEN      PIC X(3) VALUE "005".
           05  SYSTEM-ERROR        PIC X(3) VALUE "999".
       
      * Interface for modern system integration
       01  WS-INTEGRATION-DATA.
           05  INT-MESSAGE-TYPE    PIC X(20).
           05  INT-CORRELATION-ID  PIC X(36).
           05  INT-TIMESTAMP       PIC X(26).
           05  INT-PAYLOAD         PIC X(1000).
       
       LINKAGE SECTION.
       01  LS-REQUEST.
           05  REQ-TYPE            PIC X(10).
           05  REQ-ACCOUNT         PIC X(10).
           05  REQ-ACCOUNT-2       PIC X(10).
           05  REQ-AMOUNT          PIC S9(9)V99.
           05  REQ-CUSTOMER-ID     PIC X(10).
           05  REQ-CHANNEL         PIC X(10).
       
       01  LS-RESPONSE.
           05  RESP-CODE           PIC X(3).
           05  RESP-MESSAGE        PIC X(100).
           05  RESP-BALANCE        PIC S9(9)V99.
           05  RESP-AVAILABLE      PIC S9(9)V99.
           05  RESP-TRANS-ID       PIC X(20).
       
       PROCEDURE DIVISION USING LS-REQUEST LS-RESPONSE.
       
       MAIN-PROCESS.
           PERFORM INITIALIZE-PROCESS
           
           EVALUATE REQ-TYPE
               WHEN "CREATE"
                   PERFORM CREATE-ACCOUNT-PROCESS
               WHEN "DEPOSIT"
                   PERFORM DEPOSIT-PROCESS
               WHEN "WITHDRAW"
                   PERFORM WITHDRAW-PROCESS
               WHEN "TRANSFER"
                   PERFORM TRANSFER-PROCESS
               WHEN "BALANCE"
                   PERFORM BALANCE-INQUIRY-PROCESS
               WHEN "CLOSE"
                   PERFORM CLOSE-ACCOUNT-PROCESS
               WHEN OTHER
                   MOVE SYSTEM-ERROR TO RESP-CODE
                   MOVE "Invalid request type" TO RESP-MESSAGE
           END-EVALUATE
           
           PERFORM PUBLISH-EVENT
           GOBACK.
       
       INITIALIZE-PROCESS.
           OPEN I-O ACCOUNT-MASTER
           OPEN EXTEND TRANSACTION-LOG
           
           ACCEPT WS-CURRENT-DATE FROM DATE YYYYMMDD
           ACCEPT WS-CURRENT-TIME FROM TIME
           
           IF WS-FILE-STATUS NOT = "00"
               MOVE SYSTEM-ERROR TO RESP-CODE
               MOVE "Cannot open account file" TO RESP-MESSAGE
               GOBACK
           END-IF.
       
       CREATE-ACCOUNT-PROCESS.
           MOVE REQ-ACCOUNT TO ACCT-NUMBER
           
           READ ACCOUNT-MASTER
               INVALID KEY
                   PERFORM CREATE-NEW-ACCOUNT
               NOT INVALID KEY
                   MOVE "002" TO RESP-CODE
                   MOVE "Account already exists" TO RESP-MESSAGE
           END-READ.
       
       CREATE-NEW-ACCOUNT.
           INITIALIZE ACCOUNT-RECORD
           MOVE REQ-ACCOUNT TO ACCT-NUMBER
           MOVE REQ-CUSTOMER-ID TO CUSTOMER-ID
           MOVE ZEROS TO BALANCE
           MOVE ZEROS TO AVAILABLE-BALANCE
           MOVE ZEROS TO HOLD-AMOUNT
           MOVE 'C' TO ACCT-TYPE
           MOVE 'A' TO ACCOUNT-STATUS
           MOVE WS-CURRENT-DATE TO OPENED-DATE
           MOVE WS-CURRENT-DATE TO LAST-ACTIVITY
           MOVE 5000.00 TO DAILY-LIMIT
           MOVE ZEROS TO DAILY-WITHDRAWN
           
           WRITE ACCOUNT-RECORD
               INVALID KEY
                   MOVE SYSTEM-ERROR TO RESP-CODE
                   MOVE "Cannot create account" TO RESP-MESSAGE
               NOT INVALID KEY
                   MOVE SUCCESS TO RESP-CODE
                   MOVE "Account created successfully" TO RESP-MESSAGE
                   PERFORM LOG-TRANSACTION
           END-WRITE.
       
       DEPOSIT-PROCESS.
           MOVE REQ-ACCOUNT TO ACCT-NUMBER
           
           READ ACCOUNT-MASTER
               INVALID KEY
                   MOVE ACCOUNT-NOT-FOUND TO RESP-CODE
                   MOVE "Account not found" TO RESP-MESSAGE
               NOT INVALID KEY
                   IF ACTIVE
                       PERFORM PROCESS-DEPOSIT
                   ELSE
                       MOVE ACCOUNT-FROZEN TO RESP-CODE
                       MOVE "Account is not active" TO RESP-MESSAGE
                   END-IF
           END-READ.
       
       PROCESS-DEPOSIT.
           IF REQ-AMOUNT &lt;= ZERO
               MOVE INVALID-AMOUNT TO RESP-CODE
               MOVE "Invalid deposit amount" TO RESP-MESSAGE
           ELSE
               ADD REQ-AMOUNT TO BALANCE
               ADD REQ-AMOUNT TO AVAILABLE-BALANCE
               MOVE WS-CURRENT-DATE TO LAST-ACTIVITY
               
               REWRITE ACCOUNT-RECORD
                   INVALID KEY
                       MOVE SYSTEM-ERROR TO RESP-CODE
                       MOVE "Cannot update account" TO RESP-MESSAGE
                   NOT INVALID KEY
                       MOVE SUCCESS TO RESP-CODE
                       MOVE "Deposit successful" TO RESP-MESSAGE
                       MOVE BALANCE TO RESP-BALANCE
                       MOVE AVAILABLE-BALANCE TO RESP-AVAILABLE
                       PERFORM LOG-TRANSACTION
               END-REWRITE
           END-IF.
       
       WITHDRAW-PROCESS.
           MOVE REQ-ACCOUNT TO ACCT-NUMBER
           
           READ ACCOUNT-MASTER
               INVALID KEY
                   MOVE ACCOUNT-NOT-FOUND TO RESP-CODE
                   MOVE "Account not found" TO RESP-MESSAGE
               NOT INVALID KEY
                   IF ACTIVE
                       PERFORM PROCESS-WITHDRAWAL
                   ELSE
                       MOVE ACCOUNT-FROZEN TO RESP-CODE
                       MOVE "Account is not active" TO RESP-MESSAGE
                   END-IF
           END-READ.
       
       PROCESS-WITHDRAWAL.
           IF REQ-AMOUNT &lt;= ZERO
               MOVE INVALID-AMOUNT TO RESP-CODE
               MOVE "Invalid withdrawal amount" TO RESP-MESSAGE
           ELSE IF REQ-AMOUNT &gt; AVAILABLE-BALANCE
               MOVE INSUFFICIENT-FUNDS TO RESP-CODE
               MOVE "Insufficient funds" TO RESP-MESSAGE
           ELSE IF (DAILY-WITHDRAWN + REQ-AMOUNT) &gt; DAILY-LIMIT
               MOVE DAILY-LIMIT-EXCEED TO RESP-CODE
               MOVE "Daily withdrawal limit exceeded" TO RESP-MESSAGE
           ELSE
               SUBTRACT REQ-AMOUNT FROM BALANCE
               SUBTRACT REQ-AMOUNT FROM AVAILABLE-BALANCE
               ADD REQ-AMOUNT TO DAILY-WITHDRAWN
               MOVE WS-CURRENT-DATE TO LAST-ACTIVITY
               
               REWRITE ACCOUNT-RECORD
                   INVALID KEY
                       MOVE SYSTEM-ERROR TO RESP-CODE
                       MOVE "Cannot update account" TO RESP-MESSAGE
                   NOT INVALID KEY
                       MOVE SUCCESS TO RESP-CODE
                       MOVE "Withdrawal successful" TO RESP-MESSAGE
                       MOVE BALANCE TO RESP-BALANCE
                       MOVE AVAILABLE-BALANCE TO RESP-AVAILABLE
                       PERFORM LOG-TRANSACTION
               END-REWRITE
           END-IF.
       
       TRANSFER-PROCESS.
           * First check source account
           MOVE REQ-ACCOUNT TO ACCT-NUMBER
           READ ACCOUNT-MASTER
               INVALID KEY
                   MOVE ACCOUNT-NOT-FOUND TO RESP-CODE
                   MOVE "Source account not found" TO RESP-MESSAGE
                   GOBACK
           END-READ
           
           IF NOT ACTIVE
               MOVE ACCOUNT-FROZEN TO RESP-CODE
               MOVE "Source account is not active" TO RESP-MESSAGE
               GOBACK
           END-IF
           
           IF REQ-AMOUNT &gt; AVAILABLE-BALANCE
               MOVE INSUFFICIENT-FUNDS TO RESP-CODE
               MOVE "Insufficient funds in source account" TO RESP-MESSAGE
               GOBACK
           END-IF
           
           * Store source account data
           MOVE ACCOUNT-RECORD TO WS-SOURCE-ACCOUNT
           
           * Check destination account
           MOVE REQ-ACCOUNT-2 TO ACCT-NUMBER
           READ ACCOUNT-MASTER
               INVALID KEY
                   MOVE ACCOUNT-NOT-FOUND TO RESP-CODE
                   MOVE "Destination account not found" TO RESP-MESSAGE
                   GOBACK
           END-READ
           
           IF NOT ACTIVE
               MOVE ACCOUNT-FROZEN TO RESP-CODE
               MOVE "Destination account is not active" TO RESP-MESSAGE
               GOBACK
           END-IF
           
           * Process transfer
           PERFORM EXECUTE-TRANSFER.
       
       EXECUTE-TRANSFER.
           * Debit source account
           MOVE WS-SOURCE-ACCOUNT TO ACCOUNT-RECORD
           MOVE REQ-ACCOUNT TO ACCT-NUMBER
           READ ACCOUNT-MASTER WITH LOCK
           
           SUBTRACT REQ-AMOUNT FROM BALANCE
           SUBTRACT REQ-AMOUNT FROM AVAILABLE-BALANCE
           ADD REQ-AMOUNT TO DAILY-WITHDRAWN
           MOVE WS-CURRENT-DATE TO LAST-ACTIVITY
           
           REWRITE ACCOUNT-RECORD
           
           * Credit destination account
           MOVE REQ-ACCOUNT-2 TO ACCT-NUMBER
           READ ACCOUNT-MASTER WITH LOCK
           
           ADD REQ-AMOUNT TO BALANCE
           ADD REQ-AMOUNT TO AVAILABLE-BALANCE
           MOVE WS-CURRENT-DATE TO LAST-ACTIVITY
           
           REWRITE ACCOUNT-RECORD
           
           MOVE SUCCESS TO RESP-CODE
           MOVE "Transfer successful" TO RESP-MESSAGE
           PERFORM LOG-TRANSFER-TRANSACTION.
       
       BALANCE-INQUIRY-PROCESS.
           MOVE REQ-ACCOUNT TO ACCT-NUMBER
           
           READ ACCOUNT-MASTER
               INVALID KEY
                   MOVE ACCOUNT-NOT-FOUND TO RESP-CODE
                   MOVE "Account not found" TO RESP-MESSAGE
               NOT INVALID KEY
                   MOVE SUCCESS TO RESP-CODE
                   MOVE "Balance inquiry successful" TO RESP-MESSAGE
                   MOVE BALANCE TO RESP-BALANCE
                   MOVE AVAILABLE-BALANCE TO RESP-AVAILABLE
           END-READ.
       
       LOG-TRANSACTION.
           ADD 1 TO WS-TRANS-COUNTER
           STRING "TXN" WS-CURRENT-DATE WS-CURRENT-TIME 
                  WS-TRANS-COUNTER DELIMITED BY SIZE
                  INTO TRANS-ID
           
           MOVE TRANS-ID TO RESP-TRANS-ID
           MOVE WS-CURRENT-DATE TO TRANS-DATE
           MOVE WS-CURRENT-TIME TO TRANS-TIME
           MOVE REQ-TYPE TO TRANS-TYPE
           MOVE REQ-ACCOUNT TO FROM-ACCOUNT
           MOVE SPACES TO TO-ACCOUNT
           MOVE REQ-AMOUNT TO AMOUNT
           MOVE BALANCE TO BALANCE-AFTER
           MOVE REQ-CHANNEL TO CHANNEL
           MOVE 'S' TO STATUS
           
           WRITE TRANSACTION-RECORD.
       
       LOG-TRANSFER-TRANSACTION.
           * Log debit transaction
           ADD 1 TO WS-TRANS-COUNTER
           STRING "TXN" WS-CURRENT-DATE WS-CURRENT-TIME 
                  WS-TRANS-COUNTER DELIMITED BY SIZE
                  INTO TRANS-ID
           
           MOVE TRANS-ID TO RESP-TRANS-ID
           MOVE WS-CURRENT-DATE TO TRANS-DATE
           MOVE WS-CURRENT-TIME TO TRANS-TIME
           MOVE "TRF" TO TRANS-TYPE
           MOVE REQ-ACCOUNT TO FROM-ACCOUNT
           MOVE REQ-ACCOUNT-2 TO TO-ACCOUNT
           COMPUTE AMOUNT = REQ-AMOUNT * -1
           MOVE WS-SOURCE-BALANCE TO BALANCE-AFTER
           MOVE REQ-CHANNEL TO CHANNEL
           MOVE 'S' TO STATUS
           
           WRITE TRANSACTION-RECORD
           
           * Log credit transaction
           ADD 1 TO WS-TRANS-COUNTER
           STRING "TXN" WS-CURRENT-DATE WS-CURRENT-TIME 
                  WS-TRANS-COUNTER DELIMITED BY SIZE
                  INTO TRANS-ID
           
           MOVE REQ-AMOUNT TO AMOUNT
           MOVE REQ-ACCOUNT-2 TO FROM-ACCOUNT
           MOVE REQ-ACCOUNT TO TO-ACCOUNT
           
           WRITE TRANSACTION-RECORD.
       
       PUBLISH-EVENT.
           * Prepare event for modern system
           MOVE REQ-TYPE TO INT-MESSAGE-TYPE
           MOVE RESP-TRANS-ID TO INT-CORRELATION-ID
           
           STRING WS-CURRENT-DATE "-" WS-CURRENT-TIME 
                  DELIMITED BY SIZE INTO INT-TIMESTAMP
           
           STRING '{"account":"' REQ-ACCOUNT 
                  '","amount":' REQ-AMOUNT
                  ',"balance":' BALANCE
                  ',"status":"' RESP-CODE '"}' 
                  DELIMITED BY SIZE INTO INT-PAYLOAD
           
           * In real implementation, this would publish to message queue
           DISPLAY "EVENT: " INT-PAYLOAD.
       
       CLOSE-FILES.
           CLOSE ACCOUNT-MASTER
           CLOSE TRANSACTION-LOG.
```

### Step 2: Create COBOL Adapter Service

Create `adapters/cobol_adapter.py`:
```python
import subprocess
import json
import os
from typing import Dict, Any, Optional
from dataclasses import dataclass
from datetime import datetime
import asyncio
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import redis
import psycopg2
from psycopg2.extras import RealDictCursor
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class TransactionRequest:
    request_type: str
    account: str
    account_2: Optional[str] = None
    amount: float = 0.0
    customer_id: Optional[str] = None
    channel: str = "API"

class COBOLAdapter:
    """Adapter to interface with COBOL banking core"""
    
    def __init__(self, cobol_program_path: str):
        self.cobol_program = cobol_program_path
        self.redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)
        self.setup_database()
    
    def setup_database(self):
        """Setup PostgreSQL connection for modern data"""
        self.db_conn = psycopg2.connect(
            host="localhost",
            database="modern_banking",
            user="postgres",
            password="password"
        )
    
    async def execute_transaction(self, request: TransactionRequest) -&gt; Dict[str, Any]:
        """Execute transaction through COBOL core"""
        
        # Generate correlation ID
        correlation_id = f"TXN-{datetime.now().strftime('%Y%m%d%H%M%S')}-{os.urandom(4).hex()}"
        
        # Log request
        logger.info(f"Processing {request.request_type} for account {request.account}")
        
        # Prepare COBOL input
        cobol_input = self._prepare_cobol_input(request)
        
        # Call COBOL program
        start_time = datetime.now()
        result = await self._call_cobol_program(cobol_input)
        execution_time = (datetime.now() - start_time).total_seconds()
        
        # Parse COBOL output
        response = self._parse_cobol_output(result)
        
        # Cache result
        cache_key = f"account:{request.account}:balance"
        if response['code'] == '000':
            self.redis_client.setex(
                cache_key,
                300,  # 5 minutes TTL
                json.dumps({
                    'balance': response.get('balance', 0),
                    'available': response.get('available_balance', 0),
                    'updated': datetime.now().isoformat()
                })
            )
        
        # Store in modern database
        await self._sync_to_modern_db(request, response, correlation_id)
        
        # Publish event
        await self._publish_event(request, response, correlation_id)
        
        return {
            'correlation_id': correlation_id,
            'request': request.__dict__,
            'response': response,
            'execution_time': execution_time
        }
    
    def _prepare_cobol_input(self, request: TransactionRequest) -&gt; str:
        """Prepare input string for COBOL program"""
        # COBOL expects fixed-length fields
        input_parts = [
            request.request_type.ljust(10),
            request.account.ljust(10),
            (request.account_2 or '').ljust(10),
            f"{request.amount:012.2f}",
            (request.customer_id or '').ljust(10),
            request.channel.ljust(10)
        ]
        
        return ''.join(input_parts)
    
    async def _call_cobol_program(self, input_data: str) -&gt; str:
        """Call COBOL program and get output"""
        # In production, this would use CICS or similar
        # For demo, using subprocess
        
        try:
            process = await asyncio.create_subprocess_exec(
                self.cobol_program,
                stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await process.communicate(input_data.encode())
            
            if process.returncode != 0:
                raise Exception(f"COBOL execution failed: {stderr.decode()}")
            
            return stdout.decode()
            
        except Exception as e:
            logger.error(f"COBOL execution error: {e}")
            # Return error response
            return "999System error                 00000000000000000000000000"
    
    def _parse_cobol_output(self, output: str) -&gt; Dict[str, Any]:
        """Parse COBOL program output"""
        # Expected output format:
        # Positions 1-3: Response code
        # Positions 4-103: Response message (100 chars)
        # Positions 104-115: Balance (12 digits with 2 decimals)
        # Positions 116-127: Available balance
        # Positions 128-147: Transaction ID
        
        try:
            response = {
                'code': output[0:3].strip(),
                'message': output[3:103].strip(),
                'balance': float(output[103:115]) / 100,
                'available_balance': float(output[115:127]) / 100,
                'transaction_id': output[127:147].strip()
            }
        except:
            response = {
                'code': '999',
                'message': 'Failed to parse COBOL response',
                'balance': 0,
                'available_balance': 0,
                'transaction_id': ''
            }
        
        return response
    
    async def _sync_to_modern_db(self, request: TransactionRequest, 
                                response: Dict[str, Any], 
                                correlation_id: str):
        """Sync transaction to modern PostgreSQL database"""
        
        try:
            with self.db_conn.cursor() as cursor:
                # Insert transaction record
                cursor.execute("""
                    INSERT INTO transactions (
                        correlation_id,
                        transaction_type,
                        account_number,
                        amount,
                        status,
                        response_code,
                        response_message,
                        balance_after,
                        channel,
                        created_at
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (
                    correlation_id,
                    request.request_type,
                    request.account,
                    request.amount,
                    'SUCCESS' if response['code'] == '000' else 'FAILED',
                    response['code'],
                    response['message'],
                    response.get('balance', 0),
                    request.channel,
                    datetime.now()
                ))
                
                # Update account snapshot
                if response['code'] == '000':
                    cursor.execute("""
                        INSERT INTO account_snapshots (
                            account_number,
                            balance,
                            available_balance,
                            last_transaction_id,
                            updated_at
                        ) VALUES (%s, %s, %s, %s, %s)
                        ON CONFLICT (account_number) 
                        DO UPDATE SET
                            balance = EXCLUDED.balance,
                            available_balance = EXCLUDED.available_balance,
                            last_transaction_id = EXCLUDED.last_transaction_id,
                            updated_at = EXCLUDED.updated_at
                    """, (
                        request.account,
                        response['balance'],
                        response['available_balance'],
                        response['transaction_id'],
                        datetime.now()
                    ))
                
                self.db_conn.commit()
                
        except Exception as e:
            logger.error(f"Database sync error: {e}")
            self.db_conn.rollback()
    
    async def _publish_event(self, request: TransactionRequest, 
                           response: Dict[str, Any], 
                           correlation_id: str):
        """Publish transaction event to event bus"""
        
        event = {
            'event_type': f'transaction.{{request.request_type.lower()}}',
            'correlation_id': correlation_id,
            'timestamp': datetime.now().isoformat(),
            'data': {
                'account': request.account,
                'amount': request.amount,
                'status': 'success' if response['code'] == '000' else 'failed',
                'response_code': response['code'],
                'balance_after': response.get('balance', 0)
            }
        }
        
        # Publish to Redis pub/sub (in production, use Kafka)
        self.redis_client.publish('banking_events', json.dumps(event))
        
        logger.info(f"Published event: {event['event_type']} for {correlation_id}")

# FastAPI application
app = FastAPI(title="COBOL Banking Adapter", version="1.0.0")
adapter = COBOLAdapter("/path/to/cobol/bankcore")

class TransactionRequestModel(BaseModel):
    request_type: str
    account: str
    account_2: Optional[str] = None
    amount: float = 0.0
    customer_id: Optional[str] = None
    channel: str = "API"

@app.post("/api/v1/transaction")
async def process_transaction(request: TransactionRequestModel):
    """Process banking transaction through COBOL core"""
    
    try:
        # Check cache first for balance inquiries
        if request.request_type == "BALANCE":
            cached = adapter.redis_client.get(f"account:{request.account}:balance")
            if cached:
                cached_data = json.loads(cached)
                return {
                    'source': 'cache',
                    'data': cached_data,
                    'cached_at': cached_data['updated']
                }
        
        # Process through COBOL
        tx_request = TransactionRequest(**request.dict())
        result = await adapter.execute_transaction(tx_request)
        
        if result['response']['code'] != '000':
            raise HTTPException(
                status_code=400,
                detail=result['response']['message']
            )
        
        return result
        
    except Exception as e:
        logger.error(f"Transaction processing error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/account/{account_number}/balance")
async def get_balance(account_number: str):
    """Get account balance"""
    
    request = TransactionRequest(
        request_type="BALANCE",
        account=account_number
    )
    
    result = await adapter.execute_transaction(request)
    
    if result['response']['code'] != '000':
        raise HTTPException(
            status_code=404,
            detail="Account not found"
        )
    
    return {
        'account': account_number,
        'balance': result['response']['balance'],
        'available_balance': result['response']['available_balance'],
        'as_of': datetime.now().isoformat()
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'services': {
            'redis': adapter.redis_client.ping(),
            'postgres': adapter.db_conn.status == psycopg2.extensions.STATUS_READY
        }
    }
```

### Step 3: Create AI Fraud Detection Service

Create `services/fraud_detection_service.py`:
```python
import numpy as np
import pandas as pd
from typing import Dict, List, Tuple, Optional
from datetime import datetime, timedelta
import joblib
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler
import asyncio
import aioredis
import json
import openai
from dataclasses import dataclass
import logging

logger = logging.getLogger(__name__)

@dataclass
class Transaction:
    account_number: str
    amount: float
    transaction_type: str
    channel: str
    timestamp: datetime
    location: Optional[str] = None
    merchant: Optional[str] = None

@dataclass
class FraudCheckResult:
    is_fraudulent: bool
    risk_score: float
    reasons: List[str]
    recommended_action: str
    ai_explanation: Optional[str] = None

class AIFraudDetectionService:
    """AI-powered fraud detection service"""
    
    def __init__(self, model_path: Optional[str] = None):
        self.model = self._load_or_create_model(model_path)
        self.scaler = StandardScaler()
        self.setup_connections()
        
    def setup_connections(self):
        """Setup Redis and other connections"""
        self.redis = aioredis.create_redis_pool('redis://localhost')
        openai.api_key = os.getenv("OPENAI_API_KEY")
    
    def _load_or_create_model(self, model_path: Optional[str]) -&gt; IsolationForest:
        """Load existing model or create new one"""
        if model_path and os.path.exists(model_path):
            return joblib.load(model_path)
        
        # Create new Isolation Forest model
        return IsolationForest(
            contamination=0.1,  # Expected fraud rate
            random_state=42,
            n_estimators=100
        )
    
    async def check_transaction(self, transaction: Transaction) -&gt; FraudCheckResult:
        """Check if transaction is fraudulent"""
        
        # Extract features
        features = await self._extract_features(transaction)
        
        # Get risk score from ML model
        risk_score = self._calculate_risk_score(features)
        
        # Apply business rules
        rule_violations = self._check_business_rules(transaction, features)
        
        # Determine if fraudulent
        is_fraudulent = risk_score &gt; 0.7 or len(rule_violations) &gt; 2
        
        # Get AI explanation if high risk
        ai_explanation = None
        if risk_score &gt; 0.5:
            ai_explanation = await self._get_ai_explanation(
                transaction, features, rule_violations
            )
        
        # Determine recommended action
        if is_fraudulent:
            recommended_action = "BLOCK"
        elif risk_score &gt; 0.5:
            recommended_action = "REVIEW"
        else:
            recommended_action = "ALLOW"
        
        result = FraudCheckResult(
            is_fraudulent=is_fraudulent,
            risk_score=risk_score,
            reasons=rule_violations,
            recommended_action=recommended_action,
            ai_explanation=ai_explanation
        )
        
        # Log result
        await self._log_fraud_check(transaction, result)
        
        return result
    
    async def _extract_features(self, transaction: Transaction) -&gt; Dict[str, float]:
        """Extract features for fraud detection"""
        
        features = {
            'amount': transaction.amount,
            'hour': transaction.timestamp.hour,
            'day_of_week': transaction.timestamp.weekday(),
            'is_weekend': 1 if transaction.timestamp.weekday() &gt;= 5 else 0,
        }
        
        # Get historical features from Redis
        history_key = f"account_history:{transaction.account_number}"
        history = await self.redis.get(history_key)
        
        if history:
            history_data = json.loads(history)
            
            # Calculate velocity features
            features['daily_transaction_count'] = history_data.get('daily_count', 0)
            features['daily_total_amount'] = history_data.get('daily_total', 0)
            features['avg_transaction_amount'] = history_data.get('avg_amount', 0)
            
            # Calculate anomaly scores
            if features['avg_transaction_amount'] &gt; 0:
                features['amount_deviation'] = abs(
                    transaction.amount - features['avg_transaction_amount']
                ) / features['avg_transaction_amount']
            else:
                features['amount_deviation'] = 0
            
            # Time-based features
            last_transaction_time = datetime.fromisoformat(
                history_data.get('last_transaction_time', transaction.timestamp.isoformat())
            )
            features['time_since_last_transaction'] = (
                transaction.timestamp - last_transaction_time
            ).total_seconds() / 3600  # Hours
            
        else:
            # First transaction
            features['daily_transaction_count'] = 0
            features['daily_total_amount'] = 0
            features['avg_transaction_amount'] = 0
            features['amount_deviation'] = 0
            features['time_since_last_transaction'] = 24
        
        # Channel risk scores
        channel_risk = {
            'ATM': 0.3,
            'ONLINE': 0.5,
            'MOBILE': 0.4,
            'BRANCH': 0.1,
            'API': 0.6
        }
        features['channel_risk'] = channel_risk.get(transaction.channel, 0.5)
        
        # Transaction type risk
        type_risk = {
            'WITHDRAW': 0.4,
            'TRANSFER': 0.6,
            'DEPOSIT': 0.1,
            'PAYMENT': 0.5
        }
        features['type_risk'] = type_risk.get(transaction.transaction_type, 0.5)
        
        return features
    
    def _calculate_risk_score(self, features: Dict[str, float]) -&gt; float:
        """Calculate fraud risk score using ML model"""
        
        # Prepare features for model
        feature_vector = np.array([
            features['amount'],
            features['hour'],
            features['day_of_week'],
            features['is_weekend'],
            features['daily_transaction_count'],
            features['amount_deviation'],
            features['time_since_last_transaction'],
            features['channel_risk'],
            features['type_risk']
        ]).reshape(1, -1)
        
        # Scale features
        feature_vector_scaled = self.scaler.fit_transform(feature_vector)
        
        # Get anomaly score (-1 for anomaly, 1 for normal)
        anomaly_score = self.model.decision_function(feature_vector_scaled)[0]
        
        # Convert to risk score (0-1)
        # More negative scores indicate higher risk
        risk_score = 1 / (1 + np.exp(anomaly_score))
        
        # Adjust based on amount
        if features['amount'] &gt; 10000:
            risk_score = min(risk_score * 1.5, 1.0)
        
        return risk_score
    
    def _check_business_rules(self, transaction: Transaction, 
                            features: Dict[str, float]) -&gt; List[str]:
        """Check business rules for fraud detection"""
        
        violations = []
        
        # Rule 1: High amount transaction
        if transaction.amount &gt; 5000:
            violations.append("High value transaction")
        
        # Rule 2: Unusual time
        if features['hour'] &lt; 6 or features['hour'] &gt; 22:
            violations.append("Transaction outside business hours")
        
        # Rule 3: Rapid transactions
        if features['time_since_last_transaction'] &lt; 0.1:  # Less than 6 minutes
            violations.append("Rapid successive transactions")
        
        # Rule 4: Daily limit exceeded
        if features['daily_total_amount'] + transaction.amount &gt; 10000:
            violations.append("Daily transaction limit exceeded")
        
        # Rule 5: Unusual amount for account
        if features['amount_deviation'] &gt; 3:  # 3x standard deviation
            violations.append("Amount significantly deviates from normal")
        
        # Rule 6: High-risk channel with high amount
        if features['channel_risk'] &gt; 0.5 and transaction.amount &gt; 1000:
            violations.append("High amount on risky channel")
        
        # Rule 7: Multiple transactions in short time
        if features['daily_transaction_count'] &gt; 10:
            violations.append("Excessive daily transactions")
        
        return violations
    
    async def _get_ai_explanation(self, transaction: Transaction,
                                features: Dict[str, float],
                                violations: List[str]) -&gt; str:
        """Get AI explanation for fraud risk"""
        
        prompt = f"""
        Analyze this banking transaction for fraud risk:
        
        Transaction Details:
        - Amount: ${transaction.amount}
        - Type: {transaction.transaction_type}
        - Channel: {transaction.channel}
        - Time: {transaction.timestamp}
        
        Risk Indicators:
        - Risk Score: {features.get('risk_score', 0):.2f}
        - Daily Transactions: {features['daily_transaction_count']}
        - Amount Deviation: {features['amount_deviation']:.2f}x normal
        
        Rule Violations:
        {chr(10).join(f"- {v}" for v in violations)}
        
        Provide a brief, clear explanation of the fraud risk and recommendation.
        """
        
        try:
            response = openai.ChatCompletion.create(
                model="gpt-4",
                messages=[
                    {
                        "role": "system",
                        "content": "You are a fraud detection expert analyzing banking transactions."
                    },
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                temperature=0.3,
                max_tokens=200
            )
            
            return response.choices[0].message.content
            
        except Exception as e:
            logger.error(f"AI explanation error: {e}")
            return "Unable to generate AI explanation"
    
    async def _log_fraud_check(self, transaction: Transaction, 
                             result: FraudCheckResult):
        """Log fraud check result"""
        
        log_entry = {
            'timestamp': datetime.now().isoformat(),
            'account': transaction.account_number,
            'amount': transaction.amount,
            'type': transaction.transaction_type,
            'risk_score': result.risk_score,
            'is_fraudulent': result.is_fraudulent,
            'action': result.recommended_action,
            'reasons': result.reasons
        }
        
        # Store in Redis for real-time monitoring
        await self.redis.lpush('fraud_checks', json.dumps(log_entry))
        await self.redis.ltrim('fraud_checks', 0, 9999)  # Keep last 10k
        
        # Update account history
        await self._update_account_history(transaction)
    
    async def _update_account_history(self, transaction: Transaction):
        """Update account transaction history"""
        
        history_key = f"account_history:{transaction.account_number}"
        
        # Get current history
        history = await self.redis.get(history_key)
        if history:
            history_data = json.loads(history)
        else:
            history_data = {
                'daily_count': 0,
                'daily_total': 0,
                'total_count': 0,
                'total_amount': 0,
                'last_reset': datetime.now().date().isoformat()
            }
        
        # Check if we need to reset daily counters
        last_reset = datetime.fromisoformat(history_data['last_reset']).date()
        if last_reset &lt; datetime.now().date():
            history_data['daily_count'] = 0
            history_data['daily_total'] = 0
            history_data['last_reset'] = datetime.now().date().isoformat()
        
        # Update counters
        history_data['daily_count'] += 1
        history_data['daily_total'] += transaction.amount
        history_data['total_count'] += 1
        history_data['total_amount'] += transaction.amount
        history_data['avg_amount'] = history_data['total_amount'] / history_data['total_count']
        history_data['last_transaction_time'] = transaction.timestamp.isoformat()
        
        # Save updated history
        await self.redis.setex(
            history_key,
            86400,  # 24 hours TTL
            json.dumps(history_data)
        )
    
    async def train_model(self, training_data: pd.DataFrame):
        """Train fraud detection model with new data"""
        
        # Prepare features
        features = training_data[[
            'amount', 'hour', 'day_of_week', 'is_weekend',
            'daily_transaction_count', 'amount_deviation',
            'time_since_last_transaction', 'channel_risk', 'type_risk'
        ]].values
        
        # Scale features
        features_scaled = self.scaler.fit_transform(features)
        
        # Train model
        self.model.fit(features_scaled)
        
        # Save model
        joblib.dump(self.model, 'fraud_detection_model.pkl')
        joblib.dump(self.scaler, 'fraud_detection_scaler.pkl')
        
        logger.info("Fraud detection model trained and saved")
```

### Step 4: Create Event-Driven Synchronization

Create `services/event_processor.py`:
```python
import asyncio
import json
from typing import Dict, Any
import aioredis
import aiokafka
from datetime import datetime
import logging
import psycopg2
from psycopg2.extras import RealDictCursor

logger = logging.getLogger(__name__)

class EventProcessor:
    """Process events from legacy and modern systems"""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.handlers = {
            'transaction.deposit': self.handle_deposit,
            'transaction.withdraw': self.handle_withdrawal,
            'transaction.transfer': self.handle_transfer,
            'fraud.alert': self.handle_fraud_alert,
            'account.created': self.handle_account_created,
            'cobol.event': self.handle_cobol_event
        }
    
    async def start(self):
        """Start event processing"""
        # Setup connections
        self.redis = await aioredis.create_redis_pool('redis://localhost')
        self.kafka_consumer = aiokafka.AIOKafkaConsumer(
            'banking_events',
            bootstrap_servers='localhost:9092',
            group_id='event_processor',
            value_deserializer=lambda m: json.loads(m.decode('utf-8'))
        )
        
        await self.kafka_consumer.start()
        
        # Setup database
        self.db_conn = psycopg2.connect(
            host="localhost",
            database="modern_banking",
            user="postgres",
            password="password"
        )
        
        # Start processing
        await asyncio.gather(
            self.process_kafka_events(),
            self.process_redis_events()
        )
    
    async def process_kafka_events(self):
        """Process events from Kafka"""
        try:
            async for msg in self.kafka_consumer:
                event = msg.value
                await self.process_event(event)
        except Exception as e:
            logger.error(f"Kafka processing error: {e}")
    
    async def process_redis_events(self):
        """Process events from Redis pub/sub"""
        pubsub = self.redis.pubsub()
        await pubsub.subscribe('banking_events')
        
        try:
            async for message in pubsub.listen():
                if message['type'] == 'message':
                    event = json.loads(message['data'])
                    await self.process_event(event)
        except Exception as e:
            logger.error(f"Redis processing error: {e}")
    
    async def process_event(self, event: Dict[str, Any]):
        """Process individual event"""
        event_type = event.get('event_type')
        
        if event_type in self.handlers:
            try:
                await self.handlers[event_type](event)
                await self.record_event(event)
            except Exception as e:
                logger.error(f"Error processing {event_type}: {e}")
                await self.handle_error(event, e)
        else:
            logger.warning(f"Unknown event type: {event_type}")
    
    async def handle_deposit(self, event: Dict[str, Any]):
        """Handle deposit event"""
        data = event['data']
        
        # Update analytics
        await self.update_analytics('deposit', data)
        
        # Check for patterns
        if data['amount'] &gt; 10000:
            await self.trigger_alert('large_deposit', data)
        
        # Update customer profile
        await self.update_customer_profile(data['account'], {
            'last_deposit': event['timestamp'],
            'total_deposits': data.get('total_deposits', 0) + data['amount']
        })
    
    async def handle_withdrawal(self, event: Dict[str, Any]):
        """Handle withdrawal event"""
        data = event['data']
        
        # Update analytics
        await self.update_analytics('withdrawal', data)
        
        # Check fraud score
        if 'fraud_score' in data and data['fraud_score'] &gt; 0.5:
            await self.escalate_for_review(event)
    
    async def handle_transfer(self, event: Dict[str, Any]):
        """Handle transfer event"""
        data = event['data']
        
        # Update both accounts
        await self.update_analytics('transfer_out', {
            'account': data['from_account'],
            'amount': data['amount']
        })
        
        await self.update_analytics('transfer_in', {
            'account': data['to_account'],
            'amount': data['amount']
        })
        
        # Check for suspicious patterns
        await self.check_transfer_patterns(data)
    
    async def handle_fraud_alert(self, event: Dict[str, Any]):
        """Handle fraud alert"""
        data = event['data']
        
        # Freeze account if high risk
        if data['risk_score'] &gt; 0.8:
            await self.freeze_account(data['account'])
        
        # Notify security team
        await self.send_notification('security', {
            'type': 'fraud_alert',
            'account': data['account'],
            'risk_score': data['risk_score'],
            'reasons': data['reasons']
        })
        
        # Update fraud tracking
        with self.db_conn.cursor() as cursor:
            cursor.execute("""
                INSERT INTO fraud_alerts (
                    account_number,
                    risk_score,
                    reasons,
                    action_taken,
                    created_at
                ) VALUES (%s, %s, %s, %s, %s)
            """, (
                data['account'],
                data['risk_score'],
                json.dumps(data['reasons']),
                data.get('action', 'REVIEW'),
                datetime.now()
            ))
            self.db_conn.commit()
    
    async def handle_account_created(self, event: Dict[str, Any]):
        """Handle new account creation"""
        data = event['data']
        
        # Initialize account in modern system
        with self.db_conn.cursor() as cursor:
            cursor.execute("""
                INSERT INTO account_profiles (
                    account_number,
                    customer_id,
                    created_at,
                    risk_profile,
                    preferences
                ) VALUES (%s, %s, %s, %s, %s)
            """, (
                data['account_number'],
                data['customer_id'],
                datetime.now(),
                'LOW',  # Default risk profile
                json.dumps({
                    'notifications': True,
                    'paperless': True
                })
            ))
            self.db_conn.commit()
        
        # Send welcome notification
        await self.send_notification('customer', {
            'type': 'welcome',
            'account': data['account_number'],
            'customer_id': data['customer_id']
        })
    
    async def handle_cobol_event(self, event: Dict[str, Any]):
        """Handle events from COBOL system"""
        # Parse COBOL event format
        payload = event.get('payload', '')
        
        try:
            # Extract data from fixed-format COBOL output
            event_data = self.parse_cobol_event(payload)
            
            # Convert to modern event
            modern_event = {
                'event_type': f"transaction.{{event_data['type'].lower()}}",
                'timestamp': datetime.now().isoformat(),
                'data': event_data
            }
            
            # Reprocess as modern event
            await self.process_event(modern_event)
            
        except Exception as e:
            logger.error(f"Error parsing COBOL event: {e}")
    
    def parse_cobol_event(self, payload: str) -&gt; Dict[str, Any]:
        """Parse COBOL event payload"""
        # Example COBOL format parsing
        # Assuming fixed positions for different fields
        
        return {
            'type': payload[0:10].strip(),
            'account': payload[10:20].strip(),
            'amount': float(payload[20:32]) / 100,
            'status': payload[32:35].strip(),
            'timestamp': payload[35:49].strip()
        }
    
    async def update_analytics(self, metric_type: str, data: Dict[str, Any]):
        """Update real-time analytics"""
        
        # Increment counters in Redis
        today = datetime.now().strftime('%Y%m%d')
        
        # Daily metrics
        await self.redis.hincrby(f"metrics:{today}", metric_type, 1)
        await self.redis.hincrbyfloat(f"metrics:{today}:amount", metric_type, data['amount'])
        
        # Account metrics
        account_key = f"account_metrics:{data['account']}"
        await self.redis.hincrby(account_key, f"{metric_type}_count", 1)
        await self.redis.hincrbyfloat(account_key, f"{metric_type}_total", data['amount'])
        
        # Set expiration
        await self.redis.expire(f"metrics:{today}", 86400 * 7)  # 7 days
    
    async def check_transfer_patterns(self, data: Dict[str, Any]):
        """Check for suspicious transfer patterns"""
        
        # Get recent transfers
        recent_key = f"recent_transfers:{data['from_account']}"
        await self.redis.lpush(recent_key, json.dumps({
            'to': data['to_account'],
            'amount': data['amount'],
            'time': datetime.now().isoformat()
        }))
        await self.redis.ltrim(recent_key, 0, 99)  # Keep last 100
        await self.redis.expire(recent_key, 3600)  # 1 hour
        
        # Check patterns
        transfers = await self.redis.lrange(recent_key, 0, -1)
        
        # Rapid transfers to multiple accounts
        unique_destinations = set()
        total_amount = 0
        
        for transfer in transfers:
            t = json.loads(transfer)
            unique_destinations.add(t['to'])
            total_amount += t['amount']
        
        if len(unique_destinations) &gt; 5 and total_amount &gt; 10000:
            await self.trigger_alert('suspicious_transfer_pattern', {
                'account': data['from_account'],
                'destinations': list(unique_destinations),
                'total_amount': total_amount
            })
    
    async def freeze_account(self, account_number: str):
        """Freeze account due to fraud"""
        
        # Update account status in cache
        await self.redis.set(f"account_status:{account_number}", "FROZEN", ex=3600)
        
        # Call COBOL adapter to freeze in core system
        # This would make an API call to the adapter service
        
        logger.warning(f"Account {account_number} frozen due to fraud alert")
    
    async def send_notification(self, channel: str, data: Dict[str, Any]):
        """Send notification through appropriate channel"""
        
        notification = {
            'channel': channel,
            'timestamp': datetime.now().isoformat(),
            'data': data
        }
        
        # Push to notification queue
        await self.redis.lpush('notifications', json.dumps(notification))
    
    async def trigger_alert(self, alert_type: str, data: Dict[str, Any]):
        """Trigger alert for monitoring"""
        
        alert = {
            'type': alert_type,
            'severity': self.get_alert_severity(alert_type),
            'timestamp': datetime.now().isoformat(),
            'data': data
        }
        
        # Send to monitoring system
        await self.redis.publish('alerts', json.dumps(alert))
        
        # Store for dashboard
        await self.redis.zadd(
            'active_alerts',
            {json.dumps(alert): datetime.now().timestamp()}
        )
    
    def get_alert_severity(self, alert_type: str) -&gt; str:
        """Determine alert severity"""
        
        severity_map = {
            'large_deposit': 'INFO',
            'suspicious_transfer_pattern': 'WARNING',
            'fraud_detected': 'HIGH',
            'system_error': 'CRITICAL'
        }
        
        return severity_map.get(alert_type, 'INFO')
    
    async def record_event(self, event: Dict[str, Any]):
        """Record event for audit trail"""
        
        with self.db_conn.cursor() as cursor:
            cursor.execute("""
                INSERT INTO event_log (
                    event_type,
                    correlation_id,
                    timestamp,
                    data
                ) VALUES (%s, %s, %s, %s)
            """, (
                event['event_type'],
                event.get('correlation_id', ''),
                event['timestamp'],
                json.dumps(event['data'])
            ))
            self.db_conn.commit()
    
    async def handle_error(self, event: Dict[str, Any], error: Exception):
        """Handle processing errors"""
        
        error_record = {
            'event': event,
            'error': str(error),
            'timestamp': datetime.now().isoformat()
        }
        
        # Store in error queue for retry
        await self.redis.lpush('error_queue', json.dumps(error_record))
        
        # Alert if critical
        if event.get('event_type') in ['transaction.transfer', 'fraud.alert']:
            await self.trigger_alert('system_error', {
                'event_type': event['event_type'],
                'error': str(error)
            })
    
    async def escalate_for_review(self, event: Dict[str, Any]):
        """Escalate transaction for manual review"""
        
        review_item = {
            'id': event.get('correlation_id'),
            'type': event['event_type'],
            'data': event['data'],
            'created_at': datetime.now().isoformat(),
            'status': 'PENDING'
        }
        
        # Add to review queue
        await self.redis.lpush('review_queue', json.dumps(review_item))
        
        # Notify operations team
        await self.send_notification('operations', {
            'type': 'manual_review_required',
            'transaction': review_item
        })
    
    async def update_customer_profile(self, account_number: str, updates: Dict[str, Any]):
        """Update customer profile with new information"""
        
        profile_key = f"customer_profile:{account_number}"
        
        # Get existing profile
        profile = await self.redis.get(profile_key)
        if profile:
            profile_data = json.loads(profile)
        else:
            profile_data = {}
        
        # Update profile
        profile_data.update(updates)
        profile_data['last_updated'] = datetime.now().isoformat()
        
        # Save updated profile
        await self.redis.set(profile_key, json.dumps(profile_data))
```

### Step 5: Create API Gateway and Router

Create `gateway/smart_router.py`:
```python
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
import httpx
import json
from typing import Dict, Any, Optional
import logging
from datetime import datetime
import asyncio

logger = logging.getLogger(__name__)

class SmartRouter:
    """Intelligent routing between legacy and modern systems"""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.cobol_adapter_url = config['cobol_adapter_url']
        self.modern_services = config['modern_services']
        self.routing_rules = self._load_routing_rules()
        self.migration_state = self._load_migration_state()
    
    def _load_routing_rules(self) -&gt; Dict[str, Any]:
        """Load routing rules for gradual migration"""
        return {
            # Core banking operations still on COBOL
            'deposit': {{'target': 'cobol', 'percentage': 100}},
            'withdraw': {{'target': 'cobol', 'percentage': 100}},
            'transfer': {{'target': 'cobol', 'percentage': 100}},
            'balance': {{'target': 'cobol', 'percentage': 100}},
            
            # New features on modern system
            'fraud_check': {{'target': 'modern', 'service': 'fraud_detection'}},
            'analytics': {{'target': 'modern', 'service': 'analytics'}},
            'notifications': {{'target': 'modern', 'service': 'notification'}},
            
            # Gradually migrating features
            'account_summary': {{'target': 'both', 'percentage': 20}},  # 20% to modern
            'transaction_history': {{'target': 'both', 'percentage': 50}},  # 50% to modern
        }
    
    def _load_migration_state(self) -&gt; Dict[str, Any]:
        """Load current migration state"""
        # In production, this would come from a database
        return {
            'phase': 'strangler_fig',
            'migrated_features': [],
            'in_progress': ['account_summary', 'transaction_history'],
            'rollback_enabled': True
        }
    
    async def route_request(self, operation: str, request_data: Dict[str, Any]) -&gt; Dict[str, Any]:
        """Route request to appropriate system"""
        
        routing_rule = self.routing_rules.get(operation, {{'target': 'cobol'}})
        
        # Determine target based on routing rules
        target = self._determine_target(operation, routing_rule, request_data)
        
        # Add correlation ID
        correlation_id = f"{operation}-{datetime.now().strftime('%Y%m%d%H%M%S')}-{hash(str(request_data))}"
        request_data['correlation_id'] = correlation_id
        
        # Log routing decision
        logger.info(f"Routing {operation} to {target} (correlation_id: {correlation_id})")
        
        # Execute request
        if target == 'cobol':
            response = await self._call_cobol_system(operation, request_data)
        elif target == 'modern':
            response = await self._call_modern_service(routing_rule['service'], operation, request_data)
        else:  # both
            response = await self._call_both_systems(operation, request_data, routing_rule)
        
        # Add routing metadata
        response['_routing'] = {
            'target': target,
            'correlation_id': correlation_id,
            'timestamp': datetime.now().isoformat()
        }
        
        return response
    
    def _determine_target(self, operation: str, routing_rule: Dict[str, Any], 
                         request_data: Dict[str, Any]) -&gt; str:
        """Determine target system based on rules and data"""
        
        target = routing_rule['target']
        
        # Check if operation is being migrated
        if target == 'both':
            # Use percentage-based routing
            import random
            if random.randint(1, 100) &lt;= routing_rule.get('percentage', 0):
                target = 'modern'
            else:
                target = 'cobol'
        
        # Check for feature flags
        if 'feature_flags' in request_data:
            flags = request_data['feature_flags']
            if f'force_{operation}_modern' in flags:
                target = 'modern'
            elif f'force_{operation}_legacy' in flags:
                target = 'cobol'
        
        # Check rollback state
        if self.migration_state['rollback_enabled'] and operation in self.migration_state['in_progress']:
            # During rollback, route to COBOL
            target = 'cobol'
        
        return target
    
    async def _call_cobol_system(self, operation: str, request_data: Dict[str, Any]) -&gt; Dict[str, Any]:
        """Call COBOL system through adapter"""
        
        async with httpx.AsyncClient() as client:
            try:
                # Map operation to COBOL request type
                cobol_request = self._map_to_cobol_request(operation, request_data)
                
                response = await client.post(
                    f"{self.cobol_adapter_url}/api/v1/transaction",
                    json=cobol_request,
                    timeout=30.0
                )
                
                response.raise_for_status()
                return response.json()
                
            except httpx.TimeoutException:
                logger.error(f"COBOL system timeout for {operation}")
                raise HTTPException(status_code=504, detail="Legacy system timeout")
            except Exception as e:
                logger.error(f"COBOL system error: {e}")
                raise HTTPException(status_code=500, detail="Legacy system error")
    
    async def _call_modern_service(self, service: str, operation: str, 
                                 request_data: Dict[str, Any]) -&gt; Dict[str, Any]:
        """Call modern microservice"""
        
        service_url = self.modern_services.get(service)
        if not service_url:
            raise HTTPException(status_code=500, detail=f"Unknown service: {service}")
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    f"{service_url}/api/v1/{operation}",
                    json=request_data,
                    timeout=10.0
                )
                
                response.raise_for_status()
                return response.json()
                
            except Exception as e:
                logger.error(f"Modern service error: {e}")
                raise HTTPException(status_code=500, detail="Service error")
    
    async def _call_both_systems(self, operation: str, request_data: Dict[str, Any],
                               routing_rule: Dict[str, Any]) -&gt; Dict[str, Any]:
        """Call both systems for comparison/migration"""
        
        # Call both systems in parallel
        cobol_task = asyncio.create_task(
            self._call_cobol_system(operation, request_data)
        )
        modern_task = asyncio.create_task(
            self._call_modern_service(routing_rule['service'], operation, request_data)
        )
        
        # Wait for both
        cobol_response, modern_response = await asyncio.gather(
            cobol_task, modern_task, return_exceptions=True
        )
        
        # Handle errors
        if isinstance(cobol_response, Exception):
            logger.error(f"COBOL error during dual call: {cobol_response}")
            if isinstance(modern_response, Exception):
                raise HTTPException(status_code=500, detail="Both systems failed")
            return modern_response
        
        if isinstance(modern_response, Exception):
            logger.error(f"Modern error during dual call: {modern_response}")
            return cobol_response
        
        # Compare results
        comparison = self._compare_responses(cobol_response, modern_response)
        
        # Log discrepancies
        if not comparison['match']:
            logger.warning(f"Response mismatch for {operation}: {comparison['differences']}")
            await self._log_discrepancy(operation, request_data, comparison)
        
        # Return based on routing percentage
        # During migration, we trust COBOL but log differences
        response = cobol_response
        response['_comparison'] = comparison
        
        return response
    
    def _map_to_cobol_request(self, operation: str, request_data: Dict[str, Any]) -&gt; Dict[str, Any]:
        """Map modern request to COBOL format"""
        
        operation_map = {
            'deposit': 'DEPOSIT',
            'withdraw': 'WITHDRAW',
            'transfer': 'TRANSFER',
            'balance': 'BALANCE',
            'account_summary': 'BALANCE'
        }
        
        return {
            'request_type': operation_map.get(operation, operation.upper()),
            'account': request_data.get('account_number'),
            'account_2': request_data.get('destination_account'),
            'amount': request_data.get('amount', 0),
            'channel': request_data.get('channel', 'API')
        }
    
    def _compare_responses(self, cobol_response: Dict[str, Any], 
                         modern_response: Dict[str, Any]) -&gt; Dict[str, Any]:
        """Compare responses from both systems"""
        
        differences = []
        
        # Compare key fields
        fields_to_compare = ['balance', 'available_balance', 'status']
        
        for field in fields_to_compare:
            cobol_value = cobol_response.get('response', {}).get(field)
            modern_value = modern_response.get(field)
            
            if cobol_value != modern_value:
                differences.append({
                    'field': field,
                    'cobol': cobol_value,
                    'modern': modern_value
                })
        
        return {
            'match': len(differences) == 0,
            'differences': differences,
            'timestamp': datetime.now().isoformat()
        }
    
    async def _log_discrepancy(self, operation: str, request_data: Dict[str, Any],
                             comparison: Dict[str, Any]):
        """Log discrepancy for investigation"""
        
        discrepancy = {
            'operation': operation,
            'request': request_data,
            'comparison': comparison,
            'timestamp': datetime.now().isoformat()
        }
        
        # In production, this would go to a database or monitoring system
        logger.error(f"DISCREPANCY: {json.dumps(discrepancy)}")

# FastAPI application
app = FastAPI(title="Banking API Gateway", version="1.0.0")

router = SmartRouter({
    'cobol_adapter_url': 'http://localhost:8001',
    'modern_services': {
        'fraud_detection': 'http://localhost:8002',
        'analytics': 'http://localhost:8003',
        'notification': 'http://localhost:8004'
    }
})

@app.post("/api/v1/{operation}")
async def handle_request(operation: str, request: Request):
    """Handle banking operation request"""
    
    try:
        request_data = await request.json()
        response = await router.route_request(operation, request_data)
        return JSONResponse(content=response)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/api/v1/migration/status")
async def get_migration_status():
    """Get current migration status"""
    
    return {
        'status': router.migration_state,
        'routing_rules': router.routing_rules,
        'timestamp': datetime.now().isoformat()
    }

@app.post("/api/v1/migration/rollback")
async def trigger_rollback():
    """Trigger rollback to COBOL for all operations"""
    
    router.migration_state['rollback_enabled'] = True
    
    return {
        'status': 'Rollback enabled',
        'affected_operations': router.migration_state['in_progress']
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### Step 6: Create Monitoring Panel

Create `monitoring/dashboard.py`:
```python
from flask import Flask, render_template, jsonify
import redis
import json
from datetime import datetime, timedelta
import pandas as pd
import plotly.graph_objs as go
import plotly.utils

app = Flask(__name__)
redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)

@app.route('/')
def dashboard():
    """Main dashboard view"""
    return render_template('dashboard.html')

@app.route('/api/metrics/realtime')
def realtime_metrics():
    """Get real-time metrics"""
    
    today = datetime.now().strftime('%Y%m%d')
    
    # Get transaction counts
    metrics = redis_client.hgetall(f"metrics:{today}")
    amounts = redis_client.hgetall(f"metrics:{today}:amount")
    
    # Get active alerts
    alerts = redis_client.zrevrange('active_alerts', 0, 9, withscores=True)
    active_alerts = []
    for alert_json, score in alerts:
        alert = json.loads(alert_json)
        active_alerts.append(alert)
    
    # Get system status
    cobol_status = redis_client.get('system_status:cobol') or 'unknown'
    modern_status = redis_client.get('system_status:modern') or 'unknown'
    
    return jsonify({
        'transactions': {
            'deposit': int(metrics.get('deposit', 0)),
            'withdraw': int(metrics.get('withdrawal', 0)),
            'transfer': int(metrics.get('transfer', 0))
        },
        'amounts': {
            'deposit': float(amounts.get('deposit', 0)),
            'withdraw': float(amounts.get('withdrawal', 0)),
            'transfer': float(amounts.get('transfer', 0))
        },
        'alerts': active_alerts[:5],
        'system_status': {
            'cobol': cobol_status,
            'modern': modern_status
        },
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/metrics/fraud')
def fraud_metrics():
    """Get fraud detection metrics"""
    
    # Get recent fraud checks
    fraud_checks = redis_client.lrange('fraud_checks', 0, 99)
    
    checks_data = []
    for check_json in fraud_checks:
        check = json.loads(check_json)
        checks_data.append(check)
    
    if checks_data:
        df = pd.DataFrame(checks_data)
        
        # Create risk score distribution
        risk_dist = go.Histogram(
            x=df['risk_score'],
            nbinsx=20,
            name='Risk Score Distribution'
        )
        
        # Fraud detection over time
        df['hour'] = pd.to_datetime(df['timestamp']).dt.hour
        hourly_fraud = df.groupby(['hour', 'is_fraudulent']).size().unstack(fill_value=0)
        
        fraud_timeline = []
        for fraud_status in [True, False]:
            if fraud_status in hourly_fraud.columns:
                fraud_timeline.append(go.Scatter(
                    x=hourly_fraud.index,
                    y=hourly_fraud[fraud_status],
                    name='Fraudulent' if fraud_status else 'Legitimate',
                    mode='lines+markers'
                ))
        
        return jsonify({
            'risk_distribution': json.loads(
                plotly.utils.PlotlyJSONEncoder().encode(risk_dist)
            ),
            'fraud_timeline': json.loads(
                plotly.utils.PlotlyJSONEncoder().encode(fraud_timeline)
            ),
            'total_checks': len(checks_data),
            'fraud_detected': sum(1 for c in checks_data if c['is_fraudulent']),
            'average_risk_score': df['risk_score'].mean() if len(df) &gt; 0 else 0
        })
    
    return jsonify({
        'risk_distribution': {{}},
        'fraud_timeline': [],
        'total_checks': 0,
        'fraud_detected': 0,
        'average_risk_score': 0
    })

@app.route('/api/metrics/performance')
def performance_metrics():
    """Get system performance metrics"""
    
    # Get performance data from Redis
    perf_keys = redis_client.keys('performance:*')
    
    performance_data = {
        'cobol_response_times': [],
        'modern_response_times': [],
        'throughput': []
    }
    
    for key in perf_keys:
        data = redis_client.get(key)
        if data:
            perf = json.loads(data)
            if 'cobol' in key:
                performance_data['cobol_response_times'].append(perf['response_time'])
            elif 'modern' in key:
                performance_data['modern_response_times'].append(perf['response_time'])
    
    return jsonify({
        'avg_cobol_response': sum(performance_data['cobol_response_times']) / 
                             len(performance_data['cobol_response_times']) 
                             if performance_data['cobol_response_times'] else 0,
        'avg_modern_response': sum(performance_data['modern_response_times']) / 
                              len(performance_data['modern_response_times']) 
                              if performance_data['modern_response_times'] else 0,
        'total_transactions': len(perf_keys)
    })

@app.route('/api/migration/progress')
def migration_progress():
    """Get migration progress"""
    
    # This would come from a database in production
    progress = {
        'features': [
            {{'name': 'Core Transactions', 'status': 'legacy', 'progress': 0}},
            {{'name': 'Balance Inquiry', 'status': 'legacy', 'progress': 0}},
            {{'name': 'Fraud Detection', 'status': 'modern', 'progress': 100}},
            {{'name': 'Analytics', 'status': 'modern', 'progress': 100}},
            {{'name': 'Account Summary', 'status': 'migrating', 'progress': 20}},
            {{'name': 'Transaction History', 'status': 'migrating', 'progress': 50}}
        ],
        'overall_progress': 28,  # Calculated based on features
        'phase': 'Strangler Fig Pattern Implementation',
        'estimated_completion': '2024-12-31'
    }
    
    return jsonify(progress)

if __name__ == '__main__':
    app.run(debug=True, port=5000)
```

## 🏃 Running the Ejercicio

1. **Compile and run COBOL banking core:**
```bash
# Compile COBOL program
cobc -x -o bankcore cobol-core/BANKCORE.cbl

# Create test data files
touch ACCOUNTS.DAT TRANSLOG.DAT
```

2. **Start the infrastructure:**
```bash
# Start PostgreSQL
docker run -d --name postgres -e POSTGRES_PASSWORD=password -p 5432:5432 postgres:15

# Start Redis
docker run -d --name redis -p 6379:6379 redis:alpine

# Start Kafka
docker-compose -f kafka-compose.yml up -d
```

3. **Create database schemas:**
```sql
-- Create modern banking database
CREATE DATABASE modern_banking;

\c modern_banking;

-- Transactions table
CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    correlation_id VARCHAR(50) UNIQUE,
    transaction_type VARCHAR(20),
    account_number VARCHAR(10),
    amount DECIMAL(12,2),
    status VARCHAR(20),
    response_code VARCHAR(3),
    response_message VARCHAR(200),
    balance_after DECIMAL(12,2),
    channel VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Account snapshots
CREATE TABLE account_snapshots (
    account_number VARCHAR(10) PRIMARY KEY,
    balance DECIMAL(12,2),
    available_balance DECIMAL(12,2),
    last_transaction_id VARCHAR(20),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Event log
CREATE TABLE event_log (
    id SERIAL PRIMARY KEY,
    event_type VARCHAR(50),
    correlation_id VARCHAR(50),
    timestamp TIMESTAMP,
    data JSONB
);

-- Fraud alerts
CREATE TABLE fraud_alerts (
    id SERIAL PRIMARY KEY,
    account_number VARCHAR(10),
    risk_score FLOAT,
    reasons JSONB,
    action_taken VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Migration tracking
CREATE TABLE migration_status (
    feature VARCHAR(50) PRIMARY KEY,
    status VARCHAR(20),
    progress INTEGER,
    started_at TIMESTAMP,
    completed_at TIMESTAMP
);
```

4. **Start all services:**
```bash
# Terminal 1: COBOL Adapter
cd adapters
python -m uvicorn cobol_adapter:app --port 8001

# Terminal 2: Fraud Detection Service
cd services
python fraud_detection_service.py

# Terminal 3: Event Processor
python event_processor.py

# Terminal 4: API Gateway
cd gateway
python smart_router.py

# Terminal 5: Monitoring Dashboard
cd monitoring
python dashboard.py
```

5. **Test the hybrid system:**
```bash
# Create account through modern API
curl -X POST http://localhost:8000/api/v1/create \
  -H "Content-Type: application/json" \
  -d '{
    "account_number": "1234567890",
    "customer_id": "CUST001",
    "initial_deposit": 1000
  }'

# Make deposit (goes to COBOL)
curl -X POST http://localhost:8000/api/v1/deposit \
  -H "Content-Type: application/json" \
  -d '{
    "account_number": "1234567890",
    "amount": 5000
  }'

# Check balance with caching
curl http://localhost:8000/api/v1/balance?account_number=1234567890

# Test fraud detection
curl -X POST http://localhost:8000/api/v1/withdraw \
  -H "Content-Type: application/json" \
  -d '{
    "account_number": "1234567890",
    "amount": 15000,
    "channel": "ONLINE"
  }'

# View migration status
curl http://localhost:8000/api/v1/migration/status
```

6. **Monitor the system:**
   - Abrir http://localhost:5000 for the monitoring dashboard
   - Verificar real-time metrics
   - View fraud detection statistics
   - Monitor migration progress

## 🎯 Validation

Your hybrid banking system should now:
- ✅ Process transactions through COBOL core
- ✅ Add AI fraud detection to legacy transactions
- ✅ Cache frequently accessed data
- ✅ Sync data between legacy and modern systems
- ✅ Route requests intelligently
- ✅ Monitor all operations in real-time
- ✅ Support gradual migration
- ✅ Enable rollback if needed

## 🚀 Bonus Challenges

1. **Avanzado Migration Features:**
   - Implement shadow mode (run both, compare results)
   - Add feature flags for granular control
   - Create automated migration validation
   - Build confidence scoring for migration

2. **Enhanced AI Capabilities:**
   - Add customer behavior prediction
   - Implement anomaly detection for system health
   - Create intelligent transaction routing
   - Build recommendation engine

3. **Production Readiness:**
   - Add circuit breakers
   - Implement distributed tracing
   - Create disaster recovery procedures
   - Build automated testing suite

4. **Avanzado Monitoring:**
   - Create SLA dashboards
   - Implement predictive alerts
   - Build migration analytics
   - Add business KPI tracking

## 📚 Additional Recursos

- [Strangler Fig Pattern](https://martinfowler.com/bliki/StranglerFigApplication.html)
- [Event-Driven Architecture](https://martinfowler.com/articles/201701-event-driven.html)
- [CICS Web Services](https://www.ibm.com/docs/en/cics-ts)
- [Legacy Modernization Mejores Prácticas](https://www.redhat.com/en/topics/cloud-native-apps/legacy-modernization)

## 🎉 Congratulations!

You've successfully built a producción-ready hybrid banking system that:
- Maintains critical COBOL operations
- Adds modern AI capabilities
- Enables gradual migration
- Provides full observability
- Ensures zero downtime

This is how real banks modernize their systems - gradually, safely, and with full control!

## ⏭️ Módulo Completar!

You've mastered COBOL modernization with AI! Key achievements:
- ✅ Analyzed COBOL with AI
- ✅ Extracted business rules
- ✅ Built hybrid architecture
- ✅ Implemented strangler fig pattern

Ready for Módulo 28: Avanzado DevOps & Security!