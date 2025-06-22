# Module 04: Independent Project - Test-Driven Banking System

## 🎯 Project Overview

Build a **Digital Banking System** using Test-Driven Development (TDD) with comprehensive testing, debugging capabilities, and production-ready error handling. This project combines all the skills from Module 04 into a real-world application.

**Duration**: 2-3 hours  
**Difficulty**: ⭐⭐⭐ (Challenging)

## 🏗️ What You'll Build

A banking system with the following features:

### Core Features
1. **Account Management**
   - Create checking/savings accounts
   - Account details and balance inquiry
   - Account closure with validation

2. **Transaction Processing**
   - Deposits and withdrawals
   - Transfer between accounts
   - Transaction history with filtering

3. **Interest Calculation**
   - Daily interest for savings accounts
   - Compound interest calculation
   - Interest payment scheduling

4. **Security Features**
   - Transaction limits
   - Fraud detection (unusual activity)
   - Audit logging

5. **Reporting**
   - Monthly statements
   - Transaction analytics
   - Tax reporting (1099-INT)

## 📋 Project Requirements

### Technical Requirements

1. **Test Coverage**: Minimum 90% coverage
2. **TDD Approach**: Write tests first for all features
3. **Error Handling**: Comprehensive exception handling
4. **Performance**: Handle 1000+ accounts efficiently
5. **Concurrency**: Thread-safe operations
6. **Data Persistence**: SQLite with proper migrations

### Testing Requirements

1. **Unit Tests**: All business logic
2. **Integration Tests**: Database operations
3. **Edge Cases**: Boundary conditions, negative amounts
4. **Performance Tests**: Load testing with many accounts
5. **Security Tests**: SQL injection, validation

## 🚀 Getting Started

### Step 1: Project Structure

Create this directory structure:

```
banking-system/
├── src/
│   ├── __init__.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── account.py        # Account model
│   │   ├── transaction.py    # Transaction model
│   │   └── customer.py       # Customer model
│   ├── services/
│   │   ├── __init__.py
│   │   ├── account_service.py
│   │   ├── transaction_service.py
│   │   └── interest_service.py
│   ├── utils/
│   │   ├── __init__.py
│   │   ├── validators.py
│   │   └── money.py          # Decimal money handling
│   └── exceptions.py         # Custom exceptions
├── tests/
│   ├── __init__.py
│   ├── conftest.py          # Pytest fixtures
│   ├── unit/
│   │   ├── test_account.py
│   │   ├── test_transaction.py
│   │   └── test_interest.py
│   ├── integration/
│   │   ├── test_account_service.py
│   │   └── test_transaction_flow.py
│   └── performance/
│       └── test_load.py
├── requirements.txt
├── pytest.ini
└── README.md
```

### Step 2: Start with Tests (TDD)

Begin by writing tests for the Account model:

```python
# tests/unit/test_account.py
import pytest
from decimal import Decimal
from datetime import datetime
from src.models.account import Account, AccountType
from src.exceptions import InsufficientFundsError, InvalidAccountError

class TestAccount:
    """Test Account model using TDD approach."""
    
    def test_create_checking_account(self):
        """Test creating a checking account."""
        account = Account(
            account_number="CHK001",
            customer_id="CUST001",
            account_type=AccountType.CHECKING,
            initial_balance=Decimal("1000.00")
        )
        
        assert account.account_number == "CHK001"
        assert account.balance == Decimal("1000.00")
        assert account.account_type == AccountType.CHECKING
        assert account.is_active is True
        assert isinstance(account.created_at, datetime)
    
    def test_deposit_valid_amount(self):
        """Test depositing money into account."""
        account = Account("CHK001", "CUST001", AccountType.CHECKING)
        
        new_balance = account.deposit(Decimal("500.00"))
        
        assert new_balance == Decimal("500.00")
        assert account.balance == Decimal("500.00")
    
    def test_deposit_invalid_amount_raises_error(self):
        """Test that depositing negative amount raises error."""
        account = Account("CHK001", "CUST001", AccountType.CHECKING)
        
        with pytest.raises(ValueError) as exc_info:
            account.deposit(Decimal("-50.00"))
        
        assert "Amount must be positive" in str(exc_info.value)
    
    def test_withdraw_with_sufficient_funds(self):
        """Test withdrawing with sufficient balance."""
        account = Account(
            "CHK001", 
            "CUST001", 
            AccountType.CHECKING,
            initial_balance=Decimal("1000.00")
        )
        
        new_balance = account.withdraw(Decimal("300.00"))
        
        assert new_balance == Decimal("700.00")
        assert account.balance == Decimal("700.00")
    
    def test_withdraw_insufficient_funds_raises_error(self):
        """Test withdrawing more than balance raises error."""
        account = Account(
            "CHK001",
            "CUST001", 
            AccountType.CHECKING,
            initial_balance=Decimal("100.00")
        )
        
        with pytest.raises(InsufficientFundsError) as exc_info:
            account.withdraw(Decimal("150.00"))
        
        assert exc_info.value.requested_amount == Decimal("150.00")
        assert exc_info.value.available_balance == Decimal("100.00")
```

### Step 3: Implement Account Model

Now implement the Account model to pass the tests:

```python
# src/models/account.py
from enum import Enum
from decimal import Decimal
from datetime import datetime
from dataclasses import dataclass
from typing import Optional

# Use Copilot to generate the implementation that passes all tests
# Include proper validation, error handling, and business logic
```

**🤖 Copilot Prompt Suggestion:**
"Create Account class with AccountType enum (CHECKING, SAVINGS), balance as Decimal, deposit/withdraw methods with validation, raise InsufficientFundsError for overdrafts"

### Step 4: Test Transaction Service

Write tests for transaction processing:

```python
# tests/integration/test_transaction_service.py
import pytest
from decimal import Decimal
from src.services.transaction_service import TransactionService
from src.models.account import Account, AccountType
from src.models.transaction import Transaction, TransactionType

class TestTransactionService:
    """Test transaction processing service."""
    
    @pytest.fixture
    def transaction_service(self, db_session):
        """Provide transaction service with test database."""
        return TransactionService(db_session)
    
    @pytest.fixture
    def sample_accounts(self, db_session):
        """Create sample accounts for testing."""
        checking = Account("CHK001", "CUST001", AccountType.CHECKING, Decimal("1000"))
        savings = Account("SAV001", "CUST001", AccountType.SAVINGS, Decimal("5000"))
        
        db_session.add_all([checking, savings])
        db_session.commit()
        
        return checking, savings
    
    def test_transfer_between_accounts(self, transaction_service, sample_accounts):
        """Test transferring money between accounts."""
        checking, savings = sample_accounts
        
        transaction = transaction_service.transfer(
            from_account_id=checking.id,
            to_account_id=savings.id,
            amount=Decimal("250.00"),
            description="Transfer to savings"
        )
        
        assert transaction.amount == Decimal("250.00")
        assert transaction.transaction_type == TransactionType.TRANSFER
        assert checking.balance == Decimal("750.00")
        assert savings.balance == Decimal("5250.00")
    
    def test_concurrent_transactions(self, transaction_service, sample_accounts):
        """Test handling concurrent transactions safely."""
        # Implement test for race conditions
        pass
```

### Step 5: Add Interest Calculation

Test interest calculation for savings accounts:

```python
# tests/unit/test_interest.py
import pytest
from decimal import Decimal
from datetime import date, timedelta
from src.services.interest_service import InterestService
from src.models.account import Account, AccountType

class TestInterestCalculation:
    """Test interest calculation service."""
    
    def test_calculate_daily_interest(self):
        """Test daily interest calculation."""
        service = InterestService(annual_rate=Decimal("0.02"))  # 2% APY
        
        daily_interest = service.calculate_daily_interest(
            principal=Decimal("10000.00")
        )
        
        # 10000 * 0.02 / 365 ≈ 0.55
        assert daily_interest == Decimal("0.55")
    
    def test_compound_interest_monthly(self):
        """Test monthly compound interest."""
        service = InterestService(annual_rate=Decimal("0.02"))
        
        final_amount = service.calculate_compound_interest(
            principal=Decimal("10000.00"),
            days=30
        )
        
        # Should be slightly more than simple interest due to compounding
        assert final_amount > Decimal("10016.44")
        assert final_amount < Decimal("10017.00")
```

## 🎯 Implementation Checklist

### Models
- [ ] Account model with validation
- [ ] Transaction model with types
- [ ] Customer model with KYC fields
- [ ] Custom exceptions

### Services
- [ ] Account creation/closure
- [ ] Transaction processing
- [ ] Interest calculation
- [ ] Fraud detection
- [ ] Report generation

### Testing
- [ ] Unit tests for all models
- [ ] Integration tests for services
- [ ] Performance tests
- [ ] Security tests
- [ ] Edge case tests

### Advanced Features
- [ ] Database migrations
- [ ] Audit logging
- [ ] Rate limiting
- [ ] API documentation
- [ ] Monitoring metrics

## 📊 Sample Test Scenarios

### 1. Edge Cases to Test

```python
# Test boundary conditions
def test_maximum_daily_withdrawal_limit():
    """Test enforcement of daily withdrawal limits."""
    pass

def test_minimum_balance_requirement():
    """Test minimum balance for savings accounts."""
    pass

def test_decimal_precision_in_calculations():
    """Test that money calculations maintain precision."""
    pass
```

### 2. Security Tests

```python
# Test security measures
def test_sql_injection_prevention():
    """Test that SQL injection attempts are blocked."""
    pass

def test_concurrent_transfer_race_condition():
    """Test that concurrent transfers don't cause inconsistencies."""
    pass

def test_audit_log_creation():
    """Test that all transactions are logged for audit."""
    pass
```

### 3. Performance Tests

```python
# Test system performance
def test_bulk_transaction_processing():
    """Test processing 1000 transactions efficiently."""
    pass

def test_interest_calculation_for_many_accounts():
    """Test nightly interest calculation scales well."""
    pass
```

## 🏁 Submission Requirements

Your completed project should include:

1. **Source Code**
   - All models, services, and utilities
   - Clean, well-documented code
   - Type hints throughout

2. **Test Suite**
   - 90%+ test coverage
   - All tests passing
   - Performance benchmarks

3. **Documentation**
   - README with setup instructions
   - API documentation
   - Architecture decisions

4. **Deployment**
   - Docker configuration
   - Database migrations
   - Environment configuration

## 💡 Tips for Success

1. **Start Small**: Begin with Account model tests
2. **One Feature at a Time**: Complete each feature with tests
3. **Use Copilot Effectively**: Provide clear context in comments
4. **Refactor Regularly**: Keep code clean as you go
5. **Think Security**: Consider attack vectors in tests

## 🎯 Evaluation Criteria

Your project will be evaluated on:

- **Test Coverage** (25%): Comprehensive test suite
- **TDD Practice** (25%): Tests written before code
- **Code Quality** (20%): Clean, maintainable code
- **Error Handling** (15%): Robust error management
- **Performance** (15%): Efficient implementation

## 🚀 Extension Challenges

If you complete the base requirements, try these:

1. **Add Cryptocurrency Support**
   - Bitcoin/Ethereum wallets
   - Real-time conversion rates
   - Transaction fees

2. **Implement Loans Module**
   - Loan applications
   - Interest calculation
   - Payment schedules

3. **Mobile API**
   - REST API with Flask/FastAPI
   - JWT authentication
   - Rate limiting

4. **Machine Learning Fraud Detection**
   - Anomaly detection
   - Transaction pattern analysis
   - Risk scoring

---

## 📚 Resources

- [Python Decimal Documentation](https://docs.python.org/3/library/decimal.html)
- [pytest-mock Documentation](https://pytest-mock.readthedocs.io/)
- [TDD Best Practices](https://testdriven.io/blog/modern-tdd/)
- [Banking Domain Concepts](https://www.investopedia.com/terms/b/bank.asp)

---

🎉 **Good luck!** This project will demonstrate your mastery of AI-assisted testing and debugging!