# GraphQL Patterns and Best Practices

## 🎯 Schema Design Principles

### 1. Think in Graphs
```graphql
# ✅ Good - Natural relationships
type User {
  id: ID!
  posts: [Post!]!
  followers: [User!]!
  following: [User!]!
}

type Post {
  id: ID!
  author: User!
  comments: [Comment!]!
  likes: [Like!]!
}

# ❌ Bad - Flat structure with IDs
type User {
  id: ID!
  postIds: [ID!]!
  followerIds: [ID!]!
}
```

### 2. Use Clear, Consistent Naming
```graphql
# ✅ Good - Consistent naming
type User {
  id: ID!
  firstName: String!
  lastName: String!
  emailAddress: String!
  createdAt: DateTime!
  updatedAt: DateTime!
}

# ❌ Bad - Inconsistent naming
type User {
  user_id: ID!
  fname: String!
  last_name: String!
  email: String!
  created: DateTime!
  modified_date: DateTime!
}
```

### 3. Design for the Client's Needs
```graphql
# ✅ Good - Client-focused fields
type Post {
  id: ID!
  title: String!
  content: String!
  
  # Computed fields for UI
  excerpt: String!
  readingTime: Int!
  isLikedByViewer: Boolean!
  viewerCanEdit: Boolean!
}

# ❌ Bad - Database-centric design
type Post {
  post_id: ID!
  post_title: String!
  post_content: String!
  user_id: ID!
  created_timestamp: Int!
}
```

## 🚀 Performance Optimization

### 1. DataLoader Pattern
```python
from aiodataloader import DataLoader

class UserLoader(DataLoader):
    async def batch_load_fn(self, user_ids: List[UUID]) -> List[User]:
        # Single query for all users
        users = await db.fetch_users_by_ids(user_ids)
        
        # Return in same order as requested
        user_map = {user.id: user for user in users}
        return [user_map.get(user_id) for user_id in user_ids]

# In resolver
@strawberry.field
async def author(self, info: Info) -> User:
    # Batches requests automatically
    return await info.context["loaders"]["user"].load(self.author_id)
```

### 2. Query Complexity Analysis
```python
from strawberry.extensions import QueryDepthLimiter, MaxTokensLimiter

schema = strawberry.Schema(
    query=Query,
    extensions=[
        QueryDepthLimiter(max_depth=10),
        MaxTokensLimiter(max_tokens=1000)
    ]
)

# Custom complexity calculation
def calculate_complexity(query_ast):
    complexity = 0
    
    for field in walk_query(query_ast):
        # Base cost
        complexity += 1
        
        # List fields cost more
        if field.return_type.is_list:
            limit = field.arguments.get("limit", 10)
            complexity += limit
    
    return complexity
```

### 3. Field-Level Caching
```python
from functools import lru_cache
from strawberry.types import Info
import hashlib

class CachedField:
    def __init__(self, ttl: int = 300):
        self.ttl = ttl
        self.cache = {}
    
    def __call__(self, resolver):
        async def wrapped(root, info: Info, **kwargs):
            # Create cache key
            cache_key = self._create_key(root, kwargs)
            
            # Check cache
            if cache_key in self.cache:
                result, timestamp = self.cache[cache_key]
                if time.time() - timestamp < self.ttl:
                    return result
            
            # Call resolver
            result = await resolver(root, info, **kwargs)
            
            # Cache result
            self.cache[cache_key] = (result, time.time())
            return result
        
        return wrapped

# Usage
@strawberry.type
class Query:
    @strawberry.field
    @CachedField(ttl=300)  # Cache for 5 minutes
    async def popular_posts(self, limit: int = 10) -> List[Post]:
        return await fetch_popular_posts(limit)
```

## 🔒 Security Patterns

### 1. Authentication & Authorization
```python
from functools import wraps

def requires_auth(resolver):
    @wraps(resolver)
    async def wrapped(root, info: Info, **kwargs):
        if not info.context.get("user"):
            raise Exception("Authentication required")
        return await resolver(root, info, **kwargs)
    return wrapped

def requires_role(role: str):
    def decorator(resolver):
        @wraps(resolver)
        async def wrapped(root, info: Info, **kwargs):
            user = info.context.get("user")
            if not user or role not in user.get("roles", []):
                raise Exception(f"Requires {role} role")
            return await resolver(root, info, **kwargs)
        return wrapped
    return decorator

# Usage
@strawberry.type
class Mutation:
    @strawberry.mutation
    @requires_auth
    async def create_post(self, input: CreatePostInput) -> Post:
        # User is guaranteed to be authenticated
        user = info.context["user"]
        return await create_post_for_user(user.id, input)
    
    @strawberry.mutation
    @requires_role("admin")
    async def delete_user(self, user_id: ID) -> bool:
        # Only admins can access this
        return await delete_user_by_id(user_id)
```

### 2. Input Validation
```python
@strawberry.input
class CreateUserInput:
    username: str
    email: str
    password: str
    
    @validator("username")
    def validate_username(self, username: str) -> str:
        if len(username) < 3:
            raise ValueError("Username must be at least 3 characters")
        if not username.isalnum():
            raise ValueError("Username must be alphanumeric")
        return username
    
    @validator("email")
    def validate_email(self, email: str) -> str:
        if "@" not in email:
            raise ValueError("Invalid email format")
        return email.lower()
    
    @validator("password")
    def validate_password(self, password: str) -> str:
        if len(password) < 8:
            raise ValueError("Password must be at least 8 characters")
        return password
```

### 3. Rate Limiting
```python
from typing import Dict
import time

class RateLimiter:
    def __init__(self, requests_per_minute: int = 60):
        self.requests_per_minute = requests_per_minute
        self.requests: Dict[str, List[float]] = {}
    
    def check_rate_limit(self, user_id: str) -> bool:
        now = time.time()
        minute_ago = now - 60
        
        # Get user's requests
        user_requests = self.requests.get(user_id, [])
        
        # Remove old requests
        user_requests = [t for t in user_requests if t > minute_ago]
        
        # Check limit
        if len(user_requests) >= self.requests_per_minute:
            return False
        
        # Add current request
        user_requests.append(now)
        self.requests[user_id] = user_requests
        
        return True

rate_limiter = RateLimiter()

@strawberry.type
class Query:
    @strawberry.field
    async def expensive_query(self, info: Info) -> List[Post]:
        user_id = info.context.get("user", {}).get("id", "anonymous")
        
        if not rate_limiter.check_rate_limit(user_id):
            raise Exception("Rate limit exceeded")
        
        return await perform_expensive_query()
```

## 📊 Error Handling

### 1. Custom Error Types
```python
@strawberry.type
class UserError:
    field: str
    message: str

@strawberry.type
class CreateUserPayload:
    user: Optional[User] = None
    errors: List[UserError] = strawberry.field(default_factory=list)

@strawberry.type
class Mutation:
    @strawberry.mutation
    async def create_user(self, input: CreateUserInput) -> CreateUserPayload:
        errors = []
        
        # Validate username uniqueness
        if await username_exists(input.username):
            errors.append(UserError(
                field="username",
                message="Username already taken"
            ))
        
        # Validate email
        if await email_exists(input.email):
            errors.append(UserError(
                field="email",
                message="Email already registered"
            ))
        
        if errors:
            return CreateUserPayload(errors=errors)
        
        # Create user
        user = await create_user_in_db(input)
        return CreateUserPayload(user=user)
```

### 2. Global Error Handling
```python
from graphql import GraphQLError

class CustomGraphQLError(GraphQLError):
    def __init__(self, message: str, code: str, **kwargs):
        super().__init__(message)
        self.extensions = {"code": code, **kwargs}

# Error handler
async def error_handler(error: Exception, execution_context):
    if isinstance(error, ValidationError):
        return CustomGraphQLError(
            "Validation failed",
            code="VALIDATION_ERROR",
            details=error.errors()
        )
    elif isinstance(error, AuthenticationError):
        return CustomGraphQLError(
            "Authentication required",
            code="UNAUTHENTICATED"
        )
    elif isinstance(error, PermissionError):
        return CustomGraphQLError(
            "Permission denied",
            code="FORBIDDEN"
        )
    else:
        # Log unexpected errors
        logger.error(f"Unexpected error: {error}", exc_info=True)
        return CustomGraphQLError(
            "Internal server error",
            code="INTERNAL_ERROR"
        )
```

## 🔄 Real-time Subscriptions

### 1. Basic Subscription Pattern
```python
@strawberry.type
class Subscription:
    @strawberry.subscription
    async def message_added(self, channel_id: ID) -> AsyncGenerator[Message, None]:
        # Subscribe to channel
        async for message in pubsub.subscribe(f"channel:{channel_id}"):
            yield message

# Publishing events
async def send_message(channel_id: str, content: str, user_id: str):
    message = await create_message(channel_id, content, user_id)
    
    # Publish to subscribers
    await pubsub.publish(f"channel:{channel_id}", message)
    
    return message
```

### 2. Filtered Subscriptions
```python
@strawberry.type
class Subscription:
    @strawberry.subscription
    async def post_updated(
        self,
        info: Info,
        author_id: Optional[ID] = None,
        tags: Optional[List[str]] = None
    ) -> AsyncGenerator[Post, None]:
        # Subscribe to all post updates
        async for post in pubsub.subscribe("posts:updated"):
            # Apply filters
            if author_id and post.author_id != author_id:
                continue
            
            if tags and not any(tag in post.tags for tag in tags):
                continue
            
            # Check permissions
            if not await user_can_view_post(info.context["user"], post):
                continue
            
            yield post
```

## 🎨 Query Patterns

### 1. Pagination
```graphql
# Cursor-based pagination (recommended)
type PostConnection {
  edges: [PostEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type PostEdge {
  node: Post!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}

type Query {
  posts(
    first: Int
    after: String
    last: Int
    before: String
    orderBy: PostOrderBy
  ): PostConnection!
}
```

### 2. Filtering and Sorting
```python
@strawberry.input
class PostFilter:
    author_id: Optional[ID] = None
    status: Optional[PostStatus] = None
    created_after: Optional[DateTime] = None
    created_before: Optional[DateTime] = None
    tags: Optional[List[str]] = None

@strawberry.enum
class PostOrderBy(Enum):
    CREATED_AT_ASC = "created_at_asc"
    CREATED_AT_DESC = "created_at_desc"
    POPULARITY = "popularity"

@strawberry.type
class Query:
    @strawberry.field
    async def posts(
        self,
        filter: Optional[PostFilter] = None,
        order_by: PostOrderBy = PostOrderBy.CREATED_AT_DESC,
        limit: int = 20,
        offset: int = 0
    ) -> List[Post]:
        query = build_post_query(filter, order_by)
        return await execute_query(query, limit, offset)
```

### 3. Mutations with Side Effects
```python
@strawberry.type
class Mutation:
    @strawberry.mutation
    async def publish_post(self, post_id: ID) -> Post:
        # Update post status
        post = await update_post_status(post_id, "published")
        
        # Side effects
        await asyncio.gather(
            # Send notifications
            notify_followers(post.author_id, post),
            
            # Update search index
            update_search_index(post),
            
            # Trigger webhooks
            trigger_webhooks("post.published", post),
            
            # Update analytics
            track_event("post_published", {
                "post_id": post.id,
                "author_id": post.author_id
            })
        )
        
        return post
```

## 🏆 Best Practices Summary

1. **Schema Design**
   - Design for clients, not databases
   - Use consistent naming conventions
   - Make nullable only when necessary
   - Version your schema carefully

2. **Performance**
   - Always use DataLoader for relationships
   - Implement query complexity limits
   - Cache expensive computations
   - Use database query optimization

3. **Security**
   - Authenticate at the gateway level
   - Authorize at the field level
   - Validate all inputs
   - Implement rate limiting

4. **Error Handling**
   - Use typed errors when possible
   - Provide helpful error messages
   - Log errors appropriately
   - Don't expose internal details

5. **Real-time**
   - Use subscriptions sparingly
   - Filter events server-side
   - Implement connection management
   - Handle reconnection gracefully

## 🔗 Resources

- [GraphQL Best Practices](https://graphql.org/learn/best-practices/)
- [Principled GraphQL](https://principledgraphql.com/)
- [GraphQL Security](https://www.howtographql.com/advanced/4-security/)
- [DataLoader Pattern](https://github.com/graphql/dataloader)