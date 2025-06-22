# tests/test_rest_api.py
import pytest
from httpx import AsyncClient
from app.main import app

@pytest.fixture
async def client():
    """Create test client"""
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

@pytest.mark.asyncio
async def test_create_task(client):
    """Test creating a new task"""
    task_data = {
        "title": "Test Task",
        "description": "Test Description",
        "priority": "high"
    }
    
    response = await client.post("/api/v1/tasks", json=task_data)
    assert response.status_code == 201
    
    data = response.json()
    assert data["title"] == task_data["title"]
    assert "id" in data

@pytest.mark.asyncio
async def test_list_tasks_with_pagination(client):
    """Test listing tasks with pagination"""
    # Create multiple tasks first
    for i in range(15):
        await client.post("/api/v1/tasks", json={"title": f"Task {i}"})
    
    # Test pagination
    response = await client.get("/api/v1/tasks?page=1&size=10")
    assert response.status_code == 200
    
    data = response.json()
    assert len(data["items"]) == 10
    assert data["total"] == 15
    assert data["pages"] == 2

# tests/test_graphql_api.py
import pytest
from httpx import AsyncClient
from app.graphql.app import app

CREATE_USER_MUTATION = """
mutation CreateUser($input: CreateUserInput!) {
    createUser(input: $input) {
        id
        username
        email
    }
}
"""

GET_USER_QUERY = """
query GetUser($username: String!) {
    user(username: $username) {
        id
        username
        email
        posts(limit: 5) {
            id
            content
            createdAt
        }
    }
}
"""

@pytest.mark.asyncio
async def test_create_user_graphql(client):
    """Test creating user via GraphQL"""
    variables = {
        "input": {
            "username": "testuser",
            "email": "test@example.com"
        }
    }
    
    response = await client.post(
        "/graphql",
        json={"query": CREATE_USER_MUTATION, "variables": variables}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["data"]["createUser"]["username"] == "testuser"

# tests/test_api_gateway.py
import pytest
from httpx import AsyncClient
from gateway.main import app

@pytest.fixture
async def auth_headers():
    """Get authentication headers for tests"""
    # Create test token
    token = create_test_token(user_id="test-user", roles=["user"])
    return {"Authorization": f"Bearer {token}"}

@pytest.mark.asyncio
async def test_gateway_routing(client, auth_headers):
    """Test gateway routes requests correctly"""
    response = await client.get("/api/v1/users/me", headers=auth_headers)
    assert response.status_code == 200

@pytest.mark.asyncio
async def test_rate_limiting(client, auth_headers):
    """Test rate limiting works"""
    # Make requests up to limit
    for i in range(60):
        response = await client.get("/api/v1/tasks", headers=auth_headers)
        assert response.status_code == 200
    
    # Next request should be rate limited
    response = await client.get("/api/v1/tasks", headers=auth_headers)
    assert response.status_code == 429
    assert "X-RateLimit-Reset" in response.headers

@pytest.mark.asyncio
async def test_circuit_breaker(client, auth_headers, mock_service_failure):
    """Test circuit breaker opens on failures"""
    # Simulate service failures
    for i in range(5):
        response = await client.get("/api/v1/failing-service", headers=auth_headers)
        assert response.status_code == 503
    
    # Circuit should be open now
    response = await client.get("/api/v1/failing-service", headers=auth_headers)
    assert response.status_code == 503
    assert "temporarily unavailable" in response.json()["detail"]

# tests/conftest.py
import pytest
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from app.models.task import Base
from app.database import get_db
from app.main import app

@pytest.fixture(scope="session")
def event_loop():
    """Create event loop for async tests"""
    import asyncio
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture
async def test_db():
    """Create test database"""
    TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"
    
    engine = create_async_engine(TEST_DATABASE_URL, echo=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )
    
    async def override_get_db():
        async with async_session() as session:
            yield session
    
    app.dependency_overrides[get_db] = override_get_db
    yield
    app.dependency_overrides.clear()

# tests/performance/load_test.py
import asyncio
import httpx
import time
from statistics import mean, stdev

async def make_request(client, url):
    """Make a single request and measure time"""
    start = time.time()
    response = await client.get(url)
    duration = time.time() - start
    return response.status_code, duration

async def load_test(url, num_requests=1000, concurrency=10):
    """Run load test against endpoint"""
    async with httpx.AsyncClient() as client:
        tasks = []
        
        for i in range(num_requests):
            if len(tasks) >= concurrency:
                # Wait for some tasks to complete
                done, tasks = await asyncio.wait(
                    tasks, return_when=asyncio.FIRST_COMPLETED
                )
            
            task = asyncio.create_task(make_request(client, url))
            tasks.append(task)
        
        # Wait for all remaining tasks
        results = await asyncio.gather(*tasks)
    
    # Analyze results
    status_codes = [r[0] for r in results]
    durations = [r[1] for r in results]
    
    print(f"Total requests: {num_requests}")
    print(f"Successful: {status_codes.count(200)}")
    print(f"Failed: {len(status_codes) - status_codes.count(200)}")
    print(f"Average response time: {mean(durations):.3f}s")
    print(f"Std deviation: {stdev(durations):.3f}s")
    print(f"Min response time: {min(durations):.3f}s")
    print(f"Max response time: {max(durations):.3f}s")

if __name__ == "__main__":
    # Run load test
    asyncio.run(load_test("http://localhost:8000/api/v1/tasks", 1000, 50))