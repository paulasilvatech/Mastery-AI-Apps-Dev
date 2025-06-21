# Messy e-commerce application - needs refactoring!
# This file has multiple issues: no type hints, poor error handling,
# mixed responsibilities, and duplicated database logic

import sqlite3
from datetime import datetime
import json

# Global database connection - not good!
conn = sqlite3.connect('ecommerce.db')

def get_all_users():
    # No error handling, no type hints
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users")
    users = cursor.fetchall()
    cursor.close()
    return users

def get_user(id):
    # SQL injection vulnerable!
    cursor = conn.cursor()
    query = f"SELECT * FROM users WHERE id = {id}"
    cursor.execute(query)
    user = cursor.fetchone()
    cursor.close()
    return user

def create_order(user_id, items):
    # Everything in one function - violates single responsibility
    try:
        cursor = conn.cursor()
        
        # Check if user exists
        cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
        user = cursor.fetchone()
        if not user:
            return "User not found"
        
        # Calculate total - business logic mixed with data access
        total = 0
        for item in items:
            cursor.execute(f"SELECT price FROM products WHERE id = {item['product_id']}")
            product = cursor.fetchone()
            if product:
                total += product[0] * item['quantity']
        
        # Apply discount - more business logic
        if total > 100:
            total = total * 0.9  # 10% discount
        
        # Create order
        cursor.execute(
            "INSERT INTO orders (user_id, total, created_at) VALUES (?, ?, ?)",
            (user_id, total, datetime.now())
        )
        order_id = cursor.lastrowid
        
        # Add order items
        for item in items:
            cursor.execute(
                "INSERT INTO order_items (order_id, product_id, quantity) VALUES (?, ?, ?)",
                (order_id, item['product_id'], item['quantity'])
            )
        
        conn.commit()
        cursor.close()
        
        return order_id
        
    except Exception as e:
        # Generic exception handling
        print(f"Error: {e}")
        return None

def get_user_orders(user_id):
    # More duplicate database code
    cursor = conn.cursor()
    cursor.execute(f"SELECT * FROM orders WHERE user_id = {user_id}")
    orders = cursor.fetchall()
    cursor.close()
    return orders

def update_inventory(product_id, quantity):
    # No validation, no error handling
    cursor = conn.cursor()
    cursor.execute(
        f"UPDATE products SET stock = stock - {quantity} WHERE id = {product_id}"
    )
    conn.commit()
    cursor.close()

def process_payment(order_id, payment_info):
    # Fake payment processing - everything hardcoded
    if payment_info['card_number'] == '4111111111111111':
        cursor = conn.cursor()
        cursor.execute(
            f"UPDATE orders SET status = 'paid' WHERE id = {order_id}"
        )
        conn.commit()
        cursor.close()
        return True
    return False

# API routes mixed with business logic
def handle_create_user(name, email):
    # No input validation
    cursor = conn.cursor()
    cursor.execute(
        "INSERT INTO users (name, email) VALUES (?, ?)",
        (name, email)
    )
    conn.commit()
    user_id = cursor.lastrowid
    cursor.close()
    return user_id

def handle_get_products():
    # Another duplicate pattern
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM products")
    products = cursor.fetchall()
    cursor.close()
    return products

def generate_report():
    # Complex logic all in one place
    cursor = conn.cursor()
    
    # Get total sales
    cursor.execute("SELECT SUM(total) FROM orders WHERE status = 'paid'")
    total_sales = cursor.fetchone()[0] or 0
    
    # Get top products
    cursor.execute("""
        SELECT p.name, SUM(oi.quantity) as total_sold
        FROM products p
        JOIN order_items oi ON p.id = oi.product_id
        JOIN orders o ON oi.order_id = o.id
        WHERE o.status = 'paid'
        GROUP BY p.id
        ORDER BY total_sold DESC
        LIMIT 10
    """)
    top_products = cursor.fetchall()
    
    # Get user stats
    cursor.execute("SELECT COUNT(*) FROM users")
    total_users = cursor.fetchone()[0]
    
    cursor.close()
    
    # Format report - presentation logic mixed in
    report = f"""
    Sales Report
    ============
    Total Sales: ${total_sales}
    Total Users: {total_users}
    
    Top Products:
    """
    for product in top_products:
        report += f"- {product[0]}: {product[1]} sold\n"
    
    return report

# Utility functions that don't belong here
def send_email(to, subject, body):
    # Fake email sending
    print(f"Sending email to {to}: {subject}")
    return True

def validate_email(email):
    # Basic validation
    return "@" in email and "." in email

def format_currency(amount):
    return f"${amount:.2f}"

# Main execution
if __name__ == "__main__":
    # Test code mixed with implementation
    print("E-commerce System")
    users = get_all_users()
    print(f"Total users: {len(users)}")
    
    # Create a test order
    items = [
        {"product_id": 1, "quantity": 2},
        {"product_id": 2, "quantity": 1}
    ]
    order_id = create_order(1, items)
    print(f"Created order: {order_id}")
    
    # Close connection - but what if error happens before?
    conn.close()