"""
Business logic services layer.
Separates business logic from data access and presentation.
"""

from typing import List, Optional, Dict, Any, Tuple
from decimal import Decimal
from datetime import datetime
import logging

from .models import User, Product, Order, OrderItem, OrderStatus, ValidationError
from .repositories import UserRepository, ProductRepository, OrderRepository
from .utils import EmailService, generate_order_number
from .config import get_config

logger = logging.getLogger(__name__)


class UserService:
    """
    Service for user-related business operations.
    
    Handles user creation, validation, and management.
    """
    
    def __init__(
        self,
        user_repository: UserRepository,
        email_service: EmailService
    ):
        self.user_repository = user_repository
        self.email_service = email_service
    
    def create_user(self, name: str, email: str) -> User:
        """
        Create a new user with validation and welcome email.
        
        Args:
            name: User's full name
            email: User's email address
            
        Returns:
            Created user object
            
        Raises:
            ValidationError: If user data is invalid
            ValueError: If email already exists
        """
        # Check if email already exists
        existing_user = self.user_repository.get_by_email(email)
        if existing_user:
            raise ValueError(f"User with email {email} already exists")
        
        # Create and validate user
        user = User(name=name, email=email)
        
        # Save to database
        saved_user = self.user_repository.create(user)
        
        # Send welcome email
        self.email_service.send_welcome_email(saved_user)
        
        logger.info(f"Created new user: {saved_user.id}")
        return saved_user
    
    def get_user(self, user_id: int) -> Optional[User]:
        """Get user by ID."""
        return self.user_repository.get_by_id(user_id)
    
    def get_all_users(self) -> List[User]:
        """Get all users."""
        return self.user_repository.get_all()
    
    def update_user(self, user_id: int, name: Optional[str] = None, email: Optional[str] = None) -> User:
        """Update user information."""
        user = self.user_repository.get_by_id(user_id)
        if not user:
            raise ValueError(f"User {user_id} not found")
        
        if name:
            user.name = name
        if email:
            # Check if new email is already taken
            existing = self.user_repository.get_by_email(email)
            if existing and existing.id != user_id:
                raise ValueError(f"Email {email} is already taken")
            user.email = email
        
        user.validate()
        return self.user_repository.update(user)


class ProductService:
    """
    Service for product management and inventory control.
    """
    
    def __init__(self, product_repository: ProductRepository):
        self.product_repository = product_repository
    
    def create_product(
        self, 
        name: str, 
        price: Decimal, 
        stock: int = 0,
        description: str = ""
    ) -> Product:
        """Create a new product."""
        product = Product(
            name=name,
            price=price,
            stock=stock,
            description=description
        )
        
        return self.product_repository.create(product)
    
    def get_product(self, product_id: int) -> Optional[Product]:
        """Get product by ID."""
        return self.product_repository.get_by_id(product_id)
    
    def get_all_products(self, in_stock_only: bool = False) -> List[Product]:
        """Get all products, optionally filtering by stock."""
        products = self.product_repository.get_all()
        
        if in_stock_only:
            products = [p for p in products if p.stock > 0]
        
        return products
    
    def check_availability(self, product_id: int, quantity: int) -> Tuple[bool, Optional[str]]:
        """
        Check if product is available in requested quantity.
        
        Returns:
            Tuple of (is_available, error_message)
        """
        product = self.product_repository.get_by_id(product_id)
        
        if not product:
            return False, f"Product {product_id} not found"
        
        if not product.has_stock(quantity):
            return False, f"Insufficient stock for {product.name}. Available: {product.stock}"
        
        return True, None
    
    def update_stock(self, product_id: int, quantity_change: int) -> Product:
        """Update product stock (positive to add, negative to remove)."""
        product = self.product_repository.get_by_id(product_id)
        if not product:
            raise ValueError(f"Product {product_id} not found")
        
        if quantity_change > 0:
            product.add_stock(quantity_change)
        else:
            product.reduce_stock(abs(quantity_change))
        
        return self.product_repository.update(product)


class OrderService:
    """
    Service for order processing and management.
    
    Handles order creation, payment processing, and fulfillment.
    """
    
    def __init__(
        self,
        order_repository: OrderRepository,
        product_service: ProductService,
        user_service: UserService,
        email_service: EmailService
    ):
        self.order_repository = order_repository
        self.product_service = product_service
        self.user_service = user_service
        self.email_service = email_service
        self.config = get_config()
    
    def create_order(self, user_id: int, items: List[Dict[str, Any]]) -> Order:
        """
        Create a new order with validation and inventory check.
        
        Args:
            user_id: ID of user placing the order
            items: List of dicts with 'product_id' and 'quantity'
            
        Returns:
            Created order
            
        Raises:
            ValidationError: If order data is invalid
            ValueError: If user not found or products unavailable
        """
        # Validate user exists
        user = self.user_service.get_user(user_id)
        if not user:
            raise ValueError(f"User {user_id} not found")
        
        # Create order
        order = Order(user_id=user_id)
        
        # Validate and add items
        for item_data in items:
            product_id = item_data['product_id']
            quantity = item_data['quantity']
            
            # Check product availability
            available, error = self.product_service.check_availability(product_id, quantity)
            if not available:
                raise ValidationError(error)
            
            # Get product for pricing
            product = self.product_service.get_product(product_id)
            
            # Add item to order
            order.add_item(product_id, quantity, product.price)
        
        # Apply business rules
        self._apply_discounts(order)
        
        # Save order
        saved_order = self.order_repository.create(order)
        
        # Reserve inventory
        for item in saved_order.items:
            self.product_service.update_stock(item.product_id, -item.quantity)
        
        # Send order confirmation
        self.email_service.send_order_confirmation(user, saved_order)
        
        logger.info(f"Created order {saved_order.id} for user {user_id}")
        return saved_order
    
    def _apply_discounts(self, order: Order) -> None:
        """Apply business rules for discounts."""
        if order.total > self.config.business_rules.discount_threshold:
            discount = order.total * self.config.business_rules.discount_rate
            order.total -= discount
            logger.info(f"Applied discount of {discount} to order")
    
    def process_payment(self, order_id: int, payment_info: Dict[str, Any]) -> bool:
        """
        Process payment for an order.
        
        Args:
            order_id: ID of order to pay
            payment_info: Payment details
            
        Returns:
            True if payment successful
        """
        order = self.order_repository.get_by_id(order_id)
        if not order:
            raise ValueError(f"Order {order_id} not found")
        
        if order.status != OrderStatus.PENDING:
            raise ValidationError(f"Order {order_id} is not in pending status")
        
        # Here you would integrate with real payment gateway
        # For now, simulate payment processing
        payment_successful = self._process_payment_gateway(payment_info, order.total)
        
        if payment_successful:
            order.update_status(OrderStatus.PAID)
            self.order_repository.update(order)
            
            # Send payment confirmation
            user = self.user_service.get_user(order.user_id)
            self.email_service.send_payment_confirmation(user, order)
            
            logger.info(f"Payment processed for order {order_id}")
            return True
        
        return False
    
    def _process_payment_gateway(self, payment_info: Dict[str, Any], amount: Decimal) -> bool:
        """Simulate payment gateway interaction."""
        # In production, this would call actual payment API
        # For demo, accept specific test card numbers
        test_cards = ['4111111111111111', '5555555555554444']
        card_number = payment_info.get('card_number', '').replace(' ', '')
        
        return card_number in test_cards
    
    def ship_order(self, order_id: int, tracking_number: str) -> Order:
        """Mark order as shipped."""
        order = self.order_repository.get_by_id(order_id)
        if not order:
            raise ValueError(f"Order {order_id} not found")
        
        order.update_status(OrderStatus.SHIPPED)
        updated_order = self.order_repository.update(order)
        
        # Send shipping notification
        user = self.user_service.get_user(order.user_id)
        self.email_service.send_shipping_notification(user, order, tracking_number)
        
        return updated_order
    
    def get_user_orders(self, user_id: int) -> List[Order]:
        """Get all orders for a user."""
        return self.order_repository.get_by_user(user_id)
    
    def get_order(self, order_id: int) -> Optional[Order]:
        """Get order by ID."""
        return self.order_repository.get_by_id(order_id)


class ReportingService:
    """
    Service for generating business reports and analytics.
    """
    
    def __init__(
        self,
        order_repository: OrderRepository,
        product_repository: ProductRepository,
        user_repository: UserRepository
    ):
        self.order_repository = order_repository
        self.product_repository = product_repository
        self.user_repository = user_repository
    
    def generate_sales_report(self, start_date: datetime, end_date: datetime) -> Dict[str, Any]:
        """Generate comprehensive sales report for date range."""
        orders = self.order_repository.get_by_date_range(start_date, end_date)
        paid_orders = [o for o in orders if o.status in [OrderStatus.PAID, OrderStatus.SHIPPED, OrderStatus.COMPLETED]]
        
        total_sales = sum(order.total for order in paid_orders)
        total_orders = len(paid_orders)
        average_order_value = total_sales / total_orders if total_orders > 0 else Decimal('0')
        
        # Get top products
        product_sales = {}
        for order in paid_orders:
            for item in order.items:
                if item.product_id not in product_sales:
                    product_sales[item.product_id] = {
                        'quantity': 0,
                        'revenue': Decimal('0')
                    }
                product_sales[item.product_id]['quantity'] += item.quantity
                product_sales[item.product_id]['revenue'] += item.get_subtotal()
        
        # Sort by revenue
        top_products = sorted(
            product_sales.items(),
            key=lambda x: x[1]['revenue'],
            reverse=True
        )[:10]
        
        # Enhance with product names
        top_products_detailed = []
        for product_id, stats in top_products:
            product = self.product_repository.get_by_id(product_id)
            if product:
                top_products_detailed.append({
                    'product': product.to_dict(),
                    'quantity_sold': stats['quantity'],
                    'revenue': float(stats['revenue'])
                })
        
        return {
            'period': {
                'start': start_date.isoformat(),
                'end': end_date.isoformat()
            },
            'summary': {
                'total_sales': float(total_sales),
                'total_orders': total_orders,
                'average_order_value': float(average_order_value)
            },
            'top_products': top_products_detailed,
            'user_stats': {
                'total_users': len(self.user_repository.get_all()),
                'users_with_orders': len(set(order.user_id for order in paid_orders))
            }
        }