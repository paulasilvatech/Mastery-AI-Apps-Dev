from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Todo API", version="1.0.0")

# TODO: Configure CORS middleware for React frontend
# Allow origins: ["http://localhost:5173"]
# Allow credentials, all methods and headers

# TODO: Import models and schemas

@app.get("/")
def read_root():
    return {"message": "Todo API is running!"}

# TODO: Add CRUD endpoints for todos:
# - GET /todos - list all todos with optional completed filter
# - POST /todos - create new todo
# - GET /todos/{id} - get single todo
# - PUT /todos/{id} - update todo
# - DELETE /todos/{id} - delete todo
# - GET /todos/suggest/next - AI suggestion endpoint