"""
Refactored data models with type safety, validation, and business logic.
Uses dataclasses, protocols, and proper separation of concerns.
"""

from dataclasses import dataclass, field
from datetime import datetime
from decimal import Decimal
from typing import List, Optional, Dict, Any, Protocol
from enum import Enum
import re


class OrderStatus(Enum):
    """Order status enumeration for type safety."""
    PENDING = "pending"
    PAID = "paid"
    SHIPPED = "shipped"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class ValidationError(Exception):
    """Custom exception for validation errors."""
    pass


class Model(Protocol):
    """Protocol for all models to ensure consistent interface."""
    id: Optional[int]
    
    def validate(self) -> None:
        """Validate the model's data."""
        ...
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert model to dictionary."""
        ...


@dataclass
class User:
    """
    User model with validation and business logic.
    
    Attributes:
        id: Unique identifier (None for new users)
        name: User's full name
        email: Valid email address
        created_at: Timestamp of creation
        updated_at: Timestamp of last update
    """
    name: str
    email: str
    id: Optional[int] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    def __post_init__(self):
        """Validate data after initialization."""
        self.validate()
    
    def validate(self) -> None:
        """Validate user data."""
        if not self.name or not self.name.strip():
            raise ValidationError("Name cannot be empty")
        
        if len(self.name) > 100:
            raise ValidationError("Name too long (max 100 characters)")
        
        if not self._is_valid_email(self.email):
            raise ValidationError(f"Invalid email address: {self.email}")
    
    @staticmethod
    def _is_valid_email(email: str) -> bool:
        """Validate email format using regex."""
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return bool(re.match(pattern, email))
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert user to dictionary representation."""
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'User':
        """Create User instance from dictionary."""
        return cls(
            id=data.get('id'),
            name=data['name'],
            email=data['email'],
            created_at=datetime.fromisoformat(data['created_at']) if data.get('created_at') else None,
            updated_at=datetime.fromisoformat(data['updated_at']) if data.get('updated_at') else None
        )


@dataclass
class Product:
    """
    Product model with inventory management.
    
    Attributes:
        id: Unique identifier
        name: Product name
        description: Product description
        price: Product price (using Decimal for precision)
        stock: Available inventory
    """
    name: str
    price: Decimal
    stock: int = 0
    description: str = ""
    id: Optional[int] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    def __post_init__(self):
        """Ensure price is Decimal and validate."""
        if not isinstance(self.price, Decimal):
            self.price = Decimal(str(self.price))
        self.validate()
    
    def validate(self) -> None:
        """Validate product data."""
        if not self.name or not self.name.strip():
            raise ValidationError("Product name cannot be empty")
        
        if self.price < 0:
            raise ValidationError("Price cannot be negative")
        
        if self.stock < 0:
            raise ValidationError("Stock cannot be negative")
    
    def has_stock(self, quantity: int) -> bool:
        """Check if sufficient stock is available."""
        return self.stock >= quantity
    
    def reduce_stock(self, quantity: int) -> None:
        """Reduce stock by specified quantity."""
        if not self.has_stock(quantity):
            raise ValidationError(f"Insufficient stock. Available: {self.stock}, Requested: {quantity}")
        self.stock -= quantity
    
    def add_stock(self, quantity: int) -> None:
        """Add stock quantity."""
        if quantity < 0:
            raise ValidationError("Cannot add negative stock quantity")
        self.stock += quantity
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert product to dictionary."""
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'price': float(self.price),
            'stock': self.stock,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }


@dataclass
class OrderItem:
    """
    Order item representing a product in an order.
    
    Attributes:
        product_id: Reference to product
        quantity: Quantity ordered
        price: Price at time of order (may differ from current product price)
    """
    product_id: int
    quantity: int
    price: Decimal
    id: Optional[int] = None
    order_id: Optional[int] = None
    created_at: Optional[datetime] = None
    
    def __post_init__(self):
        """Ensure price is Decimal and validate."""
        if not isinstance(self.price, Decimal):
            self.price = Decimal(str(self.price))
        self.validate()
    
    def validate(self) -> None:
        """Validate order item data."""
        if self.quantity <= 0:
            raise ValidationError("Quantity must be positive")
        
        if self.price < 0:
            raise ValidationError("Price cannot be negative")
    
    def get_subtotal(self) -> Decimal:
        """Calculate subtotal for this item."""
        return self.price * self.quantity
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert order item to dictionary."""
        return {
            'id': self.id,
            'order_id': self.order_id,
            'product_id': self.product_id,
            'quantity': self.quantity,
            'price': float(self.price),
            'subtotal': float(self.get_subtotal()),
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


@dataclass
class Order:
    """
    Order model with business logic and state management.
    
    Attributes:
        user_id: Reference to user who placed the order
        status: Current order status
        items: List of order items
        total: Order total (calculated from items)
    """
    user_id: int
    status: OrderStatus = OrderStatus.PENDING
    items: List[OrderItem] = field(default_factory=list)
    total: Decimal = Decimal('0')
    id: Optional[int] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    def __post_init__(self):
        """Initialize order with proper status."""
        if isinstance(self.status, str):
            self.status = OrderStatus(self.status)
        if not isinstance(self.total, Decimal):
            self.total = Decimal(str(self.total))
    
    def add_item(self, product_id: int, quantity: int, price: Decimal) -> None:
        """Add an item to the order."""
        item = OrderItem(
            product_id=product_id,
            quantity=quantity,
            price=price,
            order_id=self.id
        )
        self.items.append(item)
        self.calculate_total()
    
    def calculate_total(self) -> Decimal:
        """Calculate order total from items."""
        self.total = sum(item.get_subtotal() for item in self.items)
        return self.total
    
    def can_transition_to(self, new_status: OrderStatus) -> bool:
        """Check if status transition is valid."""
        valid_transitions = {
            OrderStatus.PENDING: [OrderStatus.PAID, OrderStatus.CANCELLED],
            OrderStatus.PAID: [OrderStatus.SHIPPED, OrderStatus.CANCELLED],
            OrderStatus.SHIPPED: [OrderStatus.COMPLETED],
            OrderStatus.COMPLETED: [],
            OrderStatus.CANCELLED: []
        }
        
        return new_status in valid_transitions.get(self.status, [])
    
    def update_status(self, new_status: OrderStatus) -> None:
        """Update order status with validation."""
        if not self.can_transition_to(new_status):
            raise ValidationError(
                f"Cannot transition from {self.status.value} to {new_status.value}"
            )
        
        self.status = new_status
        self.updated_at = datetime.now()
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert order to dictionary."""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'status': self.status.value,
            'total': float(self.total),
            'items': [item.to_dict() for item in self.items],
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }


# Type aliases for clarity
UserId = int
ProductId = int
OrderId = int