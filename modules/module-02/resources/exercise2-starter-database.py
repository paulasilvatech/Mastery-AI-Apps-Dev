# Database operations - needs major refactoring
# Duplicate connection logic, no connection pooling, no proper error handling

import sqlite3

def create_tables():
    # Hardcoded connection string
    conn = sqlite3.connect('ecommerce.db')
    cursor = conn.cursor()
    
    # Users table
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL
    )
    ''')
    
    # Products table
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER DEFAULT 0
    )
    ''')
    
    # Orders table
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY,
        user_id INTEGER,
        total REAL,
        status TEXT DEFAULT 'pending',
        created_at TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
    )
    ''')
    
    # Order items table
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS order_items (
        id INTEGER PRIMARY KEY,
        order_id INTEGER,
        product_id INTEGER,
        quantity INTEGER,
        FOREIGN KEY (order_id) REFERENCES orders (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
    )
    ''')
    
    conn.commit()
    conn.close()

def get_connection():
    # No connection pooling
    return sqlite3.connect('ecommerce.db')

def execute_query(query, params=None):
    # Basic wrapper - still not great
    conn = get_connection()
    cursor = conn.cursor()
    
    if params:
        cursor.execute(query, params)
    else:
        cursor.execute(query)
    
    result = cursor.fetchall()
    conn.commit()
    conn.close()
    
    return result

# Seed data function
def seed_data():
    conn = get_connection()
    cursor = conn.cursor()
    
    # Add sample users
    users = [
        ('John Doe', 'john@example.com'),
        ('Jane Smith', 'jane@example.com'),
        ('Bob Johnson', 'bob@example.com')
    ]
    
    cursor.executemany(
        "INSERT OR IGNORE INTO users (name, email) VALUES (?, ?)",
        users
    )
    
    # Add sample products
    products = [
        ('Laptop', 999.99, 10),
        ('Mouse', 29.99, 50),
        ('Keyboard', 79.99, 30),
        ('Monitor', 299.99, 15)
    ]
    
    cursor.executemany(
        "INSERT OR IGNORE INTO products (name, price, stock) VALUES (?, ?, ?)",
        products
    )
    
    conn.commit()
    conn.close()

# No transaction support
# No connection context manager
# No proper error handling
# No query builder or ORM