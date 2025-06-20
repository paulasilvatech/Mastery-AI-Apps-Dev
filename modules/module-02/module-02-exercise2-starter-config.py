# Configuration - needs proper structure
# Everything hardcoded, no environment support

DATABASE = 'ecommerce.db'
DEBUG = True
SECRET_KEY = 'not-very-secret-key'

# Email settings
EMAIL_HOST = 'localhost'
EMAIL_PORT = 1025
EMAIL_FROM = 'noreply@example.com'

# Business rules hardcoded
DISCOUNT_THRESHOLD = 100
DISCOUNT_RATE = 0.1
TAX_RATE = 0.08

# Pagination
DEFAULT_PAGE_SIZE = 10
MAX_PAGE_SIZE = 100

# Shipping rates
SHIPPING_BASE_RATE = 5.0
SHIPPING_WEIGHT_MULTIPLIER = 0.5
SHIPPING_DISTANCE_MULTIPLIER = 0.1

# No environment variable support
# No validation
# No different configs for dev/prod
# Secrets exposed in code