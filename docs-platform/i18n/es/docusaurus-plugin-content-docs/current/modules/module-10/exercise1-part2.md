---
sidebar_position: 9
title: "Exercise 1: Part 2"
description: "### Step 5: Create JavaScript Client"
---

# Ejercicio 1: Real-time WebSocket Chat Application (Partee 2)

### Step 5: Create JavaScript Client

**Copilot Prompt Suggestion:**
```javascript
// Create a WebSocket chat client that:
// - Connects to WebSocket server with username
// - Handles connection lifecycle (open, close, error)
// - Sends and receives JSON messages
// - Updates UI based on message types
// - Shows connection status with visual indicators
// - Auto-reconnects on disconnection
// Include error handling and user feedback
```

**Expected Output:**
```javascript
// static/chat.js
let ws = null;
let username = null;
let reconnectInterval = null;

// UI Elements
const statusDot = document.getElementById('status-dot');
const statusText = document.getElementById('status-text');
const usernameInput = document.getElementById('username');
const connectBtn = document.getElementById('connect-btn');
const usernameSection = document.getElementById('username-section');
const chatSection = document.getElementById('chat-section');
const messagesDiv = document.getElementById('messages');
const messageInput = document.getElementById('messageInput');
const sendBtn = document.getElementById('send-btn');

// Update connection status UI
function updateStatus(connected) {
    if (connected) {
        statusDot.className = 'w-2 h-2 rounded-full mr-2 bg-green-500';
        statusText.textContent = 'Connected';
        statusText.parentElement.className = 'inline-flex items-center px-3 py-1 rounded-full text-sm bg-green-100 text-green-800';
    } else {
        statusDot.className = 'w-2 h-2 rounded-full mr-2 bg-red-500';
        statusText.textContent = 'Disconnected';
        statusText.parentElement.className = 'inline-flex items-center px-3 py-1 rounded-full text-sm bg-red-100 text-red-800';
    }
}

// Connect to WebSocket server
function connect() {
    username = usernameInput.value.trim();
    
    if (!username) {
        alert('Please enter a username');
        return;
    }
    
    // Create WebSocket connection
    ws = new WebSocket(`ws://localhost:8000/ws/${username}`);
    
    ws.onopen = function(event) {
        console.log('Connected to WebSocket');
        updateStatus(true);
        
        // Update UI
        usernameSection.classList.add('hidden');
        chatSection.classList.remove('hidden');
        messageInput.disabled = false;
        sendBtn.disabled = false;
        messageInput.focus();
        
        // Clear any reconnect interval
        if (reconnectInterval) {
            clearInterval(reconnectInterval);
            reconnectInterval = null;
        }
    };
    
    ws.onmessage = function(event) {
        const data = JSON.parse(event.data);
        displayMessage(data);
    };
    
    ws.onerror = function(error) {
        console.error('WebSocket error:', error);
        addSystemMessage('Connection error occurred', 'error');
    };
    
    ws.onclose = function(event) {
        console.log('Disconnected from WebSocket');
        updateStatus(false);
        
        // Reset UI
        messageInput.disabled = true;
        sendBtn.disabled = true;
        
        // Attempt to reconnect
        if (!reconnectInterval) {
            addSystemMessage('Connection lost. Attempting to reconnect...', 'warning');
            reconnectInterval = setInterval(() =&gt; {
                if (ws.readyState === WebSocket.CLOSED) {
                    connect();
                }
            }, 3000);
        }
    };
}

// Send message
function sendMessage() {
    const message = messageInput.value.trim();
    
    if (message && ws && ws.readyState === WebSocket.OPEN) {
        ws.send(message);
        messageInput.value = '';
        messageInput.focus();
    }
}

// Handle Enter key press
function handleKeyPress(event) {
    if (event.key === 'Enter') {
        sendMessage();
    }
}

// Display message in chat
function displayMessage(data) {
    const messageDiv = document.createElement('div');
    const time = new Date(data.timestamp).toLocaleTimeString();
    
    switch (data.type) {
        case 'connection':
            messageDiv.className = 'text-center text-green-600 text-sm italic';
            messageDiv.textContent = `${data.message} (${time})`;
            break;
            
        case 'disconnection':
            messageDiv.className = 'text-center text-red-600 text-sm italic';
            messageDiv.textContent = `${data.message} (${time})`;
            break;
            
        case 'message':
            const isOwnMessage = data.client_id === username;
            messageDiv.className = `flex ${isOwnMessage ? 'justify-end' : 'justify-start'}`;
            
            const bubble = document.createElement('div');
            bubble.className = `max-w-xs px-4 py-2 rounded-lg ${
                isOwnMessage 
                    ? 'bg-blue-500 text-white' 
                    : 'bg-gray-200 text-gray-800'
            }`;
            
            const header = document.createElement('div');
            header.className = 'text-xs opacity-75 mb-1';
            header.textContent = `${data.client_id} • ${time}`;
            
            const text = document.createElement('div');
            text.textContent = data.message;
            
            bubble.appendChild(header);
            bubble.appendChild(text);
            messageDiv.appendChild(bubble);
            break;
    }
    
    messagesDiv.appendChild(messageDiv);
    messagesDiv.scrollTop = messagesDiv.scrollHeight;
}

// Add system message
function addSystemMessage(message, type) {
    const messageDiv = document.createElement('div');
    messageDiv.className = `text-center text-sm italic ${
        type === 'error' ? 'text-red-600' : 'text-yellow-600'
    }`;
    messageDiv.textContent = message;
    messagesDiv.appendChild(messageDiv);
    messagesDiv.scrollTop = messagesDiv.scrollHeight;
}

// Handle page unload
window.addEventListener('beforeunload', () =&gt; {
    if (ws) {
        ws.close();
    }
});

// Enable Enter key for username input
usernameInput.addEventListener('keypress', (event) =&gt; {
    if (event.key === 'Enter') {
        connect();
    }
});
```

### Step 6: Testing the Application

1. **Start the server:**
```bash
uvicorn main:app --reload
```

2. **Abrir multiple browser windows:**
   - Navigate to http://localhost:8000
   - Use different usernames in each window
   - Test sending messages between clients

### Step 7: Validation Tests

Create `test_chat.py`:

**Copilot Prompt Suggestion:**
```python
# Create pytest tests for WebSocket chat that:
# - Test WebSocket connection acceptance
# - Test message broadcasting to multiple clients
# - Test connection/disconnection notifications
# - Test invalid connection attempts
# - Use pytest-asyncio for async testing
# Include fixtures for test client setup
```

**Expected Output:**
```python
# test_chat.py
import pytest
import json
from fastapi.testclient import TestClient
from main import app

@pytest.fixture
def client():
    return TestClient(app)

def test_homepage(client):
    """Test that homepage serves HTML"""
    response = client.get("/")
    assert response.status_code == 200
    assert "WebSocket Chat" in response.text

def test_websocket_connection():
    """Test WebSocket connection and messaging"""
    client = TestClient(app)
    
    with client.websocket_connect("/ws/testuser") as websocket:
        # Test connection notification
        data = websocket.receive_text()
        message = json.loads(data)
        assert message["type"] == "connection"
        assert "testuser" in message["message"]
        
        # Test sending message
        websocket.send_text("Hello, World!")
        data = websocket.receive_text()
        message = json.loads(data)
        assert message["type"] == "message"
        assert message["message"] == "Hello, World!"
        assert message["client_id"] == "testuser"

def test_multiple_clients():
    """Test broadcasting between multiple clients"""
    client = TestClient(app)
    
    with client.websocket_connect("/ws/user1") as ws1:
        with client.websocket_connect("/ws/user2") as ws2:
            # Clear connection messages
            ws1.receive_text()  # user1 connection
            ws1.receive_text()  # user2 connection
            ws2.receive_text()  # user1 connection
            ws2.receive_text()  # user2 connection
            
            # User1 sends message
            ws1.send_text("Hello from user1")
            
            # Both should receive it
            msg1 = json.loads(ws1.receive_text())
            msg2 = json.loads(ws2.receive_text())
            
            assert msg1["message"] == "Hello from user1"
            assert msg2["message"] == "Hello from user1"
            assert msg1["client_id"] == "user1"
            assert msg2["client_id"] == "user1"
```

Run tests:
```bash
pytest test_chat.py -v
```

## 🏆 Success Criteria

Your implementation should:
- ✅ Accept multiple WebSocket connections
- ✅ Broadcast messages to all connected clients
- ✅ Show connection/disconnection notifications
- ✅ Display messages with timestamps and usernames
- ✅ Handle disconnections gracefully
- ✅ Pass all validation tests

## 🔧 Troubleshooting

### Common Issues:

1. **WebSocket connection fails:**
   - Verificar server is running on correct port
   - Verify no firewall blocking WebSocket
   - Verificar browser console for errors

2. **Mensajes not broadcasting:**
   - Verify connection manager maintains connections
   - Verificar broadcast method error handling
   - Use browser dev tools to monitor WebSocket

3. **UI not updating:**
   - Verificar JavaScript console for errors
   - Verify DOM element IDs match
   - Ensure message format matches expected JSON

## 🚀 Enhancement Challenges

Once basic chat works, try these enhancements:

1. **Add typing indicators:**
   - Show when users are typing
   - Clear after timeout

2. **Implement private messages:**
   - Add @username syntax
   - Route to specific client

3. **Add message history:**
   - Store last 50 messages
   - Send to new connections

4. **Create chat rooms:**
   - Multiple room support
   - Room switching UI

## 📊 Performance Considerations

- Connection manager uses O(n) for broadcasts
- Consider using Redis for multi-server scaling
- Implement connection limits for producción
- Add rate limiting for messages

## 🎯 Key Takeaways

1. WebSocket provides full-duplex communication
2. Connection management is critical for real-time apps
3. Proper error handling prevents cascade failures
4. JSON message format enables rich communication
5. Client-side reconnection improves reliability

## 📚 Additional Recursos

- [WebSocket Protocol RFC](https://datatracker.ietf.org/doc/html/rfc6455)
- [FastAPI WebSocket Guía](https://fastapi.tiangolo.com/advanced/websockets/)
- [JavaScript WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket)

---

Congratulations! You've built a real-time chat application. Ready for [Exercise 2: Event-Driven Order System](../exercise2-event-system/README.md)?