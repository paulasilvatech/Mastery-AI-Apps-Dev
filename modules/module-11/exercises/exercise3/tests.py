# Exercise 3: Mastery - Production-Ready Financial Platform
# Test script for Saga Pattern and Distributed Transactions

import asyncio
import httpx
from typing import Dict, Any, List
import json
from uuid import uuid4
from decimal import Decimal
import time
from datetime import datetime

# ANSI color codes
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
CYAN = '\033[96m'
RESET = '\033[0m'

class SagaTestRunner:
    def __init__(self, base_url: str = "http://localhost:8000"):
        self.base_url = base_url
        self.results = []
        self.accounts = {}
        self.transactions = []
    
    def print_header(self, text: str):
        print(f"\n{BLUE}{'=' * 60}{RESET}")
        print(f"{BLUE}{text.center(60)}{RESET}")
        print(f"{BLUE}{'=' * 60}{RESET}")
    
    def print_test(self, name: str, status: str, message: str = ""):
        if status == "PASS":
            print(f"{GREEN}✓ {name}{RESET}")
        elif status == "FAIL":
            print(f"{RED}✗ {name}: {message}{RESET}")
        elif status == "INFO":
            print(f"{CYAN}ℹ {name}: {message}{RESET}")
        else:
            print(f"{YELLOW}⚠ {name}: {message}{RESET}")
    
    async def setup_test_accounts(self):
        """Create test accounts for saga testing"""
        self.print_header("Setting Up Test Accounts")
        
        async with httpx.AsyncClient() as client:
            # Create sender account with initial balance
            sender_data = {
                "account_type": "checking",
                "currency": "USD",
                "owner_id": str(uuid4()),
                "initial_deposit": 10000.00
            }
            
            response = await client.post(
                f"{self.base_url}/api/accounts",
                json=sender_data
            )
            
            if response.status_code == 201:
                self.accounts["sender"] = response.json()
                self.print_test(
                    "Create Sender Account",
                    "PASS",
                    f"Balance: ${sender_data['initial_deposit']}"
                )
            else:
                self.print_test(
                    "Create Sender Account",
                    "FAIL",
                    f"Status: {response.status_code}"
                )
                return False
            
            # Create receiver account
            receiver_data = {
                "account_type": "checking",
                "currency": "USD",
                "owner_id": str(uuid4()),
                "initial_deposit": 1000.00
            }
            
            response = await client.post(
                f"{self.base_url}/api/accounts",
                json=receiver_data
            )
            
            if response.status_code == 201:
                self.accounts["receiver"] = response.json()
                self.print_test(
                    "Create Receiver Account",
                    "PASS",
                    f"Balance: ${receiver_data['initial_deposit']}"
                )
            else:
                self.print_test(
                    "Create Receiver Account",
                    "FAIL",
                    f"Status: {response.status_code}"
                )
                return False
            
            # Create high-risk account (for testing saga compensation)
            risk_data = {
                "account_type": "checking",
                "currency": "USD",
                "owner_id": str(uuid4()),
                "initial_deposit": 50000.00,
                "metadata": {"risk_level": "high"}
            }
            
            response = await client.post(
                f"{self.base_url}/api/accounts",
                json=risk_data
            )
            
            if response.status_code == 201:
                self.accounts["high_risk"] = response.json()
                self.print_test(
                    "Create High-Risk Account",
                    "PASS",
                    "For compensation testing"
                )
            
            return True
    
    async def test_successful_payment_saga(self):
        """Test successful payment transfer saga"""
        self.print_header("Test 1: Successful Payment Transfer")
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            # Start payment saga
            payment_data = {
                "sender_account_id": self.accounts["sender"]["id"],
                "receiver_account_id": self.accounts["receiver"]["id"],
                "amount": 500.00,
                "currency": "USD",
                "description": "Test payment transfer"
            }
            
            start_time = time.time()
            response = await client.post(
                f"{self.base_url}/api/saga/payment-transfer",
                json=payment_data
            )
            
            if response.status_code == 202:
                saga = response.json()
                saga_id = saga["saga_id"]
                self.print_test(
                    "Start Payment Saga",
                    "PASS",
                    f"Saga ID: {saga_id}"
                )
                
                # Poll for saga completion
                completed = await self.wait_for_saga_completion(client, saga_id)
                
                if completed and completed["state"] == "completed":
                    duration = time.time() - start_time
                    self.print_test(
                        "Saga Execution",
                        "PASS",
                        f"Completed in {duration:.2f}s"
                    )
                    
                    # Verify account balances
                    await self.verify_account_balances(
                        client,
                        expected_sender_balance=9500.00,
                        expected_receiver_balance=1500.00
                    )
                    
                    # Check transaction history
                    await self.verify_transaction_history(client, saga_id)
                    
                else:
                    self.print_test(
                        "Saga Execution",
                        "FAIL",
                        f"State: {completed.get('state', 'unknown')}"
                    )
            else:
                self.print_test(
                    "Start Payment Saga",
                    "FAIL",
                    f"Status: {response.status_code}"
                )
    
    async def test_saga_compensation(self):
        """Test saga compensation on risk check failure"""
        self.print_header("Test 2: Saga Compensation (Risk Check Failure)")
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            # Attempt payment from high-risk account
            payment_data = {
                "sender_account_id": self.accounts["high_risk"]["id"],
                "receiver_account_id": self.accounts["receiver"]["id"],
                "amount": 25000.00,  # Large amount triggers risk check
                "currency": "USD",
                "description": "High-risk payment"
            }
            
            response = await client.post(
                f"{self.base_url}/api/saga/payment-transfer",
                json=payment_data
            )
            
            if response.status_code == 202:
                saga = response.json()
                saga_id = saga["saga_id"]
                self.print_test(
                    "Start High-Risk Saga",
                    "PASS",
                    f"Saga ID: {saga_id}"
                )
                
                # Wait for saga to fail and compensate
                completed = await self.wait_for_saga_completion(
                    client,
                    saga_id,
                    expected_state="compensated"
                )
                
                if completed and completed["state"] == "compensated":
                    self.print_test(
                        "Saga Compensation",
                        "PASS",
                        "Transaction rolled back"
                    )
                    
                    # Verify balance unchanged
                    account = await self.get_account_balance(
                        client,
                        self.accounts["high_risk"]["id"]
                    )
                    
                    if account and float(account["balance"]) == 50000.00:
                        self.print_test(
                            "Balance Verification",
                            "PASS",
                            "Funds restored after compensation"
                        )
                    else:
                        self.print_test(
                            "Balance Verification",
                            "FAIL",
                            f"Expected: $50000, Got: ${account.get('balance', 0)}"
                        )
                    
                    # Check compensation events
                    await self.verify_compensation_events(client, saga_id)
                    
                else:
                    self.print_test(
                        "Saga Compensation",
                        "FAIL",
                        f"State: {completed.get('state', 'unknown')}"
                    )
    
    async def test_concurrent_sagas(self):
        """Test multiple concurrent payment sagas"""
        self.print_header("Test 3: Concurrent Payment Sagas")
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            # Start multiple payments concurrently
            saga_tasks = []
            num_payments = 5
            
            for i in range(num_payments):
                payment_data = {
                    "sender_account_id": self.accounts["sender"]["id"],
                    "receiver_account_id": self.accounts["receiver"]["id"],
                    "amount": 100.00,
                    "currency": "USD",
                    "description": f"Concurrent payment {i+1}"
                }
                
                task = client.post(
                    f"{self.base_url}/api/saga/payment-transfer",
                    json=payment_data
                )
                saga_tasks.append(task)
            
            # Execute all requests concurrently
            responses = await asyncio.gather(*saga_tasks, return_exceptions=True)
            
            saga_ids = []
            for i, response in enumerate(responses):
                if not isinstance(response, Exception) and response.status_code == 202:
                    saga_ids.append(response.json()["saga_id"])
                    self.print_test(
                        f"Start Saga {i+1}",
                        "PASS",
                        f"ID: {response.json()['saga_id'][:8]}..."
                    )
                else:
                    self.print_test(
                        f"Start Saga {i+1}",
                        "FAIL",
                        str(response)
                    )
            
            # Wait for all sagas to complete
            completion_tasks = [
                self.wait_for_saga_completion(client, saga_id)
                for saga_id in saga_ids
            ]
            
            completions = await asyncio.gather(*completion_tasks)
            
            # Verify all completed successfully
            successful = sum(
                1 for c in completions
                if c and c["state"] == "completed"
            )
            
            self.print_test(
                "Concurrent Execution",
                "PASS" if successful == len(saga_ids) else "WARN",
                f"{successful}/{len(saga_ids)} completed successfully"
            )
            
            # Verify final balances
            await self.verify_final_balances(client, num_payments)
    
    async def test_saga_timeout(self):
        """Test saga timeout handling"""
        self.print_header("Test 4: Saga Timeout Handling")
        
        async with httpx.AsyncClient(timeout=60.0) as client:
            # Create a payment that will timeout
            payment_data = {
                "sender_account_id": self.accounts["sender"]["id"],
                "receiver_account_id": self.accounts["receiver"]["id"],
                "amount": 1000.00,
                "currency": "USD",
                "description": "Timeout test payment",
                "simulate_timeout": True  # Special flag for testing
            }
            
            response = await client.post(
                f"{self.base_url}/api/saga/payment-transfer",
                json=payment_data
            )
            
            if response.status_code == 202:
                saga_id = response.json()["saga_id"]
                self.print_test(
                    "Start Timeout Saga",
                    "PASS",
                    f"Saga ID: {saga_id}"
                )
                
                # Wait for timeout and compensation
                completed = await self.wait_for_saga_completion(
                    client,
                    saga_id,
                    expected_state="compensated",
                    timeout=120
                )
                
                if completed and completed["state"] == "compensated":
                    self.print_test(
                        "Timeout Handling",
                        "PASS",
                        "Saga compensated after timeout"
                    )
                else:
                    self.print_test(
                        "Timeout Handling",
                        "FAIL",
                        f"Unexpected state: {completed.get('state', 'unknown')}"
                    )
    
    async def wait_for_saga_completion(
        self,
        client: httpx.AsyncClient,
        saga_id: str,
        expected_state: str = "completed",
        timeout: int = 30
    ) -> Dict[str, Any]:
        """Poll for saga completion"""
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            response = await client.get(f"{self.base_url}/api/saga/{saga_id}")
            
            if response.status_code == 200:
                saga = response.json()
                if saga["state"] in ["completed", "compensated", "failed"]:
                    return saga
            
            await asyncio.sleep(1)
        
        return None
    
    async def verify_account_balances(
        self,
        client: httpx.AsyncClient,
        expected_sender_balance: float,
        expected_receiver_balance: float
    ):
        """Verify account balances after transaction"""
        sender = await self.get_account_balance(
            client,
            self.accounts["sender"]["id"]
        )
        receiver = await self.get_account_balance(
            client,
            self.accounts["receiver"]["id"]
        )
        
        sender_balance = float(sender["balance"])
        receiver_balance = float(receiver["balance"])
        
        if abs(sender_balance - expected_sender_balance) < 0.01:
            self.print_test(
                "Sender Balance",
                "PASS",
                f"${sender_balance:.2f}"
            )
        else:
            self.print_test(
                "Sender Balance",
                "FAIL",
                f"Expected: ${expected_sender_balance}, Got: ${sender_balance}"
            )
        
        if abs(receiver_balance - expected_receiver_balance) < 0.01:
            self.print_test(
                "Receiver Balance",
                "PASS",
                f"${receiver_balance:.2f}"
            )
        else:
            self.print_test(
                "Receiver Balance",
                "FAIL",
                f"Expected: ${expected_receiver_balance}, Got: ${receiver_balance}"
            )
    
    async def get_account_balance(
        self,
        client: httpx.AsyncClient,
        account_id: str
    ) -> Dict[str, Any]:
        """Get current account balance"""
        response = await client.get(f"{self.base_url}/api/accounts/{account_id}")
        return response.json() if response.status_code == 200 else None
    
    async def verify_transaction_history(
        self,
        client: httpx.AsyncClient,
        saga_id: str
    ):
        """Verify transaction history contains saga events"""
        response = await client.get(
            f"{self.base_url}/api/transactions",
            params={"saga_id": saga_id}
        )
        
        if response.status_code == 200:
            transactions = response.json()
            if len(transactions) >= 2:  # Debit and credit
                self.print_test(
                    "Transaction History",
                    "PASS",
                    f"{len(transactions)} transactions recorded"
                )
            else:
                self.print_test(
                    "Transaction History",
                    "FAIL",
                    f"Expected 2+ transactions, got {len(transactions)}"
                )
    
    async def verify_compensation_events(
        self,
        client: httpx.AsyncClient,
        saga_id: str
    ):
        """Verify compensation events were recorded"""
        response = await client.get(
            f"{self.base_url}/api/events",
            params={"saga_id": saga_id, "event_type": "compensation"}
        )
        
        if response.status_code == 200:
            events = response.json()
            if events:
                self.print_test(
                    "Compensation Events",
                    "PASS",
                    f"{len(events)} compensation events recorded"
                )
            else:
                self.print_test(
                    "Compensation Events",
                    "FAIL",
                    "No compensation events found"
                )
    
    async def verify_final_balances(
        self,
        client: httpx.AsyncClient,
        num_payments: int
    ):
        """Verify final balances after concurrent payments"""
        sender = await self.get_account_balance(
            client,
            self.accounts["sender"]["id"]
        )
        receiver = await self.get_account_balance(
            client,
            self.accounts["receiver"]["id"]
        )
        
        # Initial: Sender=9500, Receiver=1500 (after first test)
        # After concurrent: 5 * 100 = 500 transferred
        expected_sender = 9500 - (num_payments * 100)
        expected_receiver = 1500 + (num_payments * 100)
        
        sender_balance = float(sender["balance"])
        receiver_balance = float(receiver["balance"])
        
        if abs(sender_balance - expected_sender) < 0.01:
            self.print_test(
                "Final Sender Balance",
                "PASS",
                f"${sender_balance:.2f}"
            )
        else:
            self.print_test(
                "Final Sender Balance",
                "FAIL",
                f"Expected: ${expected_sender}, Got: ${sender_balance}"
            )
    
    async def run_all_tests(self):
        """Run all saga tests"""
        self.print_header("Exercise 3: Saga Pattern Test Suite")
        print(f"{CYAN}Testing distributed transactions and compensations{RESET}")
        
        # Setup
        if not await self.setup_test_accounts():
            print(f"{RED}Failed to setup test accounts. Exiting.{RESET}")
            return
        
        # Run tests
        await self.test_successful_payment_saga()
        await self.test_saga_compensation()
        await self.test_concurrent_sagas()
        await self.test_saga_timeout()
        
        # Summary
        self.print_header("Test Summary")
        print(f"{GREEN}All saga pattern tests completed!{RESET}")
        print(f"\n{CYAN}Key validations performed:{RESET}")
        print("- ✓ Successful distributed transactions")
        print("- ✓ Compensation on failure")
        print("- ✓ Concurrent saga execution")
        print("- ✓ Timeout handling")
        print("- ✓ Event sourcing verification")
        print("- ✓ Balance consistency")

async def main():
    runner = SagaTestRunner()
    await runner.run_all_tests()

if __name__ == "__main__":
    asyncio.run(main())