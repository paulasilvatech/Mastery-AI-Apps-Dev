"""
Repository pattern implementation for data access.
Separates data access logic from business logic.
"""

from typing import List, Optional, Dict, Any, Protocol
from datetime import datetime
from decimal import Decimal
import logging

from .models import User, Product, Order, OrderItem, OrderStatus
from .database import DatabaseManager, get_db_manager

logger = logging.getLogger(__name__)


class Repository(Protocol):
    """Base repository protocol for consistent interface."""
    
    def get_by_id(self, id: int) -> Optional[Any]:
        """Get entity by ID."""
        ...
    
    def get_all(self) -> List[Any]:
        """Get all entities."""
        ...
    
    def create(self, entity: Any) -> Any:
        """Create new entity."""
        ...
    
    def update(self, entity: Any) -> Any:
        """Update existing entity."""
        ...
    
    def delete(self, id: int) -> bool:
        """Delete entity by ID."""
        ...


class UserRepository:
    """Repository for user data access."""
    
    def __init__(self, db_manager: Optional[DatabaseManager] = None):
        self.db_manager = db_manager or get_db_manager()
    
    def get_by_id(self, user_id: int) -> Optional[User]:
        """Get user by ID."""
        query = "SELECT * FROM users WHERE id = ?"
        results = self.db_manager.execute_query(query, (user_id,))
        
        if results:
            return self._row_to_user(results[0])
        return None
    
    def get_by_email(self, email: str) -> Optional[User]:
        """Get user by email address."""
        query = "SELECT * FROM users WHERE email = ?"
        results = self.db_manager.execute_query(query, (email,))
        
        if results:
            return self._row_to_user(results[0])
        return None
    
    def get_all(self) -> List[User]:
        """Get all users."""
        query = "SELECT * FROM users ORDER BY created_at DESC"
        results = self.db_manager.execute_query(query)
        
        return [self._row_to_user(row) for row in results]
    
    def create(self, user: User) -> User:
        """Create a new user."""
        query = """
            INSERT INTO users (name, email, created_at, updated_at)
            VALUES (?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        """
        
        with self.db_manager.transaction() as conn:
            cursor = conn.cursor()
            cursor.execute(query, (user.name, user.email))
            user.id = cursor.lastrowid
            
            # Fetch created timestamps
            cursor.execute("SELECT created_at, updated_at FROM users WHERE id = ?", (user.id,))
            row = cursor.fetchone()
            user.created_at = datetime.fromisoformat(row[0])
            user.updated_at = datetime.fromisoformat(row[1])
        
        logger.info(f"Created user {user.id}")
        return user
    
    def update(self, user: User) -> User:
        """Update an existing user."""
        query = """
            UPDATE users 
            SET name = ?, email = ?, updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        """
        
        affected = self.db_manager.execute_update(query, (user.name, user.email, user.id))
        
        if affected == 0:
            raise ValueError(f"User {user.id} not found")
        
        # Fetch updated timestamp
        updated_user = self.get_by_id(user.id)
        user.updated_at = updated_user.updated_at
        
        logger.info(f"Updated user {user.id}")
        return user
    
    def delete(self, user_id: int) -> bool:
        """Delete a user."""
        query = "DELETE FROM users WHERE id = ?"
        affected = self.db_manager.execute_update(query, (user_id,))
        
        logger.info(f"Deleted user {user_id}")
        return affected > 0
    
    def _row_to_user(self, row: sqlite3.Row) -> User:
        """Convert database row to User object."""
        return User(
            id=row['id'],
            name=row['name'],
            email=row['email'],
            created_at=datetime.fromisoformat(row['created_at']) if row['created_at'] else None,
            updated_at=datetime.fromisoformat(row['updated_at']) if row['updated_at'] else None
        )


class ProductRepository:
    """Repository for product data access."""
    
    def __init__(self, db_manager: Optional[DatabaseManager] = None):
        self.db_manager = db_manager or get_db_manager()
    
    def get_by_id(self, product_id: int) -> Optional[Product]:
        """Get product by ID."""
        query = "SELECT * FROM products WHERE id = ?"
        results = self.db_manager.execute_query(query, (product_id,))
        
        if results:
            return self._row_to_product(results[0])
        return None
    
    def get_all(self) -> List[Product]:
        """Get all products."""
        query = "SELECT * FROM products ORDER BY name"
        results = self.db_manager.execute_query(query)
        
        return [self._row_to_product(row) for row in results]
    
    def get_by_category(self, category: str) -> List[Product]:
        """Get products by category (if category field exists)."""
        # This is a placeholder - add category support if needed
        return self.get_all()
    
    def create(self, product: Product) -> Product:
        """Create a new product."""
        query = """
            INSERT INTO products (name, description, price, stock, created_at, updated_at)
            VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        """
        
        with self.db_manager.transaction() as conn:
            cursor = conn.cursor()
            cursor.execute(query, (
                product.name,
                product.description,
                float(product.price),
                product.stock
            ))
            product.id = cursor.lastrowid
            
            # Fetch timestamps
            cursor.execute("SELECT created_at, updated_at FROM products WHERE id = ?", (product.id,))
            row = cursor.fetchone()
            product.created_at = datetime.fromisoformat(row[0])
            product.updated_at = datetime.fromisoformat(row[1])
        
        logger.info(f"Created product {product.id}")
        return product
    
    def update(self, product: Product) -> Product:
        """Update an existing product."""
        query = """
            UPDATE products 
            SET name = ?, description = ?, price = ?, stock = ?, updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        """
        
        affected = self.db_manager.execute_update(query, (
            product.name,
            product.description,
            float(product.price),
            product.stock,
            product.id
        ))
        
        if affected == 0:
            raise ValueError(f"Product {product.id} not found")
        
        # Fetch updated timestamp
        updated_product = self.get_by_id(product.id)
        product.updated_at = updated_product.updated_at
        
        logger.info(f"Updated product {product.id}")
        return product
    
    def delete(self, product_id: int) -> bool:
        """Delete a product."""
        query = "DELETE FROM products WHERE id = ?"
        affected = self.db_manager.execute_update(query, (product_id,))
        
        logger.info(f"Deleted product {product_id}")
        return affected > 0
    
    def _row_to_product(self, row: sqlite3.Row) -> Product:
        """Convert database row to Product object."""
        return Product(
            id=row['id'],
            name=row['name'],
            description=row['description'] or "",
            price=Decimal(str(row['price'])),
            stock=row['stock'],
            created_at=datetime.fromisoformat(row['created_at']) if row['created_at'] else None,
            updated_at=datetime.fromisoformat(row['updated_at']) if row['updated_at'] else None
        )


class OrderRepository:
    """Repository for order data access with related items."""
    
    def __init__(self, db_manager: Optional[DatabaseManager] = None):
        self.db_manager = db_manager or get_db_manager()
    
    def get_by_id(self, order_id: int) -> Optional[Order]:
        """Get order by ID with items."""
        query = "SELECT * FROM orders WHERE id = ?"
        results = self.db_manager.execute_query(query, (order_id,))
        
        if results:
            order = self._row_to_order(results[0])
            order.items = self._get_order_items(order_id)
            return order
        return None
    
    def get_by_user(self, user_id: int) -> List[Order]:
        """Get all orders for a user."""
        query = "SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC"
        results = self.db_manager.execute_query(query, (user_id,))
        
        orders = []
        for row in results:
            order = self._row_to_order(row)
            order.items = self._get_order_items(order.id)
            orders.append(order)
        
        return orders
    
    def get_by_status(self, status: OrderStatus) -> List[Order]:
        """Get orders by status."""
        query = "SELECT * FROM orders WHERE status = ? ORDER BY created_at DESC"
        results = self.db_manager.execute_query(query, (status.value,))
        
        orders = []
        for row in results:
            order = self._row_to_order(row)
            order.items = self._get_order_items(order.id)
            orders.append(order)
        
        return orders
    
    def get_by_date_range(self, start_date: datetime, end_date: datetime) -> List[Order]:
        """Get orders within date range."""
        query = """
            SELECT * FROM orders 
            WHERE created_at >= ? AND created_at <= ?
            ORDER BY created_at DESC
        """
        results = self.db_manager.execute_query(query, (
            start_date.isoformat(),
            end_date.isoformat()
        ))
        
        orders = []
        for row in results:
            order = self._row_to_order(row)
            order.items = self._get_order_items(order.id)
            orders.append(order)
        
        return orders
    
    def create(self, order: Order) -> Order:
        """Create a new order with items."""
        with self.db_manager.transaction() as conn:
            cursor = conn.cursor()
            
            # Create order
            query = """
                INSERT INTO orders (user_id, total, status, created_at, updated_at)
                VALUES (?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            """
            cursor.execute(query, (
                order.user_id,
                float(order.total),
                order.status.value
            ))
            order.id = cursor.lastrowid
            
            # Create order items
            for item in order.items:
                item_query = """
                    INSERT INTO order_items (order_id, product_id, quantity, price, created_at)
                    VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
                """
                cursor.execute(item_query, (
                    order.id,
                    item.product_id,
                    item.quantity,
                    float(item.price)
                ))
                item.id = cursor.lastrowid
                item.order_id = order.id
            
            # Fetch timestamps
            cursor.execute("SELECT created_at, updated_at FROM orders WHERE id = ?", (order.id,))
            row = cursor.fetchone()
            order.created_at = datetime.fromisoformat(row[0])
            order.updated_at = datetime.fromisoformat(row[1])
        
        logger.info(f"Created order {order.id} with {len(order.items)} items")
        return order
    
    def update(self, order: Order) -> Order:
        """Update an existing order (status and total only)."""
        query = """
            UPDATE orders 
            SET total = ?, status = ?, updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        """
        
        affected = self.db_manager.execute_update(query, (
            float(order.total),
            order.status.value,
            order.id
        ))
        
        if affected == 0:
            raise ValueError(f"Order {order.id} not found")
        
        # Fetch updated timestamp
        updated_order = self.get_by_id(order.id)
        order.updated_at = updated_order.updated_at
        
        logger.info(f"Updated order {order.id}")
        return order
    
    def _get_order_items(self, order_id: int) -> List[OrderItem]:
        """Get all items for an order."""
        query = "SELECT * FROM order_items WHERE order_id = ?"
        results = self.db_manager.execute_query(query, (order_id,))
        
        return [self._row_to_order_item(row) for row in results]
    
    def _row_to_order(self, row: sqlite3.Row) -> Order:
        """Convert database row to Order object."""
        return Order(
            id=row['id'],
            user_id=row['user_id'],
            total=Decimal(str(row['total'])),
            status=OrderStatus(row['status']),
            created_at=datetime.fromisoformat(row['created_at']) if row['created_at'] else None,
            updated_at=datetime.fromisoformat(row['updated_at']) if row['updated_at'] else None
        )
    
    def _row_to_order_item(self, row: sqlite3.Row) -> OrderItem:
        """Convert database row to OrderItem object."""
        return OrderItem(
            id=row['id'],
            order_id=row['order_id'],
            product_id=row['product_id'],
            quantity=row['quantity'],
            price=Decimal(str(row['price'])),
            created_at=datetime.fromisoformat(row['created_at']) if row['created_at'] else None
        )