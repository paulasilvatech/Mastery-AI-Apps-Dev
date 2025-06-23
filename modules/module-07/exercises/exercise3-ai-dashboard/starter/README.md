# AI Analytics Dashboard - Starter Code

## Overview

Build a real-time AI-powered analytics dashboard that visualizes data insights, generates reports, and provides intelligent recommendations.

## Project Structure

```
starter/
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── models.py       # TODO: Define data models
│   │   ├── analytics.py    # TODO: Analytics engine
│   │   ├── ai_insights.py  # TODO: AI integration
│   │   ├── websocket.py    # TODO: Real-time updates
│   │   └── main.py         # TODO: API endpoints
│   └── requirements.txt
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── Dashboard/   # TODO: Main dashboard
│   │   │   ├── Charts/      # TODO: Data visualizations
│   │   │   └── AIInsights/  # TODO: AI recommendations
│   │   ├── hooks/          # TODO: Custom React hooks
│   │   ├── services/       # TODO: API & WebSocket
│   │   └── App.tsx         # TODO: Main application
│   ├── package.json
│   └── tsconfig.json
└── docker-compose.yml
```

## Your Mission

Create a comprehensive AI analytics dashboard with:

### Core Features
1. **Real-time Data Visualization**
   - Line charts for trends
   - Bar charts for comparisons
   - Pie charts for distributions
   - Heat maps for correlations

2. **AI-Powered Insights**
   - Anomaly detection
   - Trend predictions
   - Natural language summaries
   - Actionable recommendations

3. **Interactive Dashboard**
   - Drag-and-drop widgets
   - Customizable layouts
   - Filter and drill-down
   - Export capabilities

4. **Real-time Updates**
   - WebSocket connections
   - Live data streaming
   - Notification system
   - Performance metrics

## Implementation Steps

### Step 1: Backend Foundation
```python
# Copilot Prompt:
# Create FastAPI app with:
# - WebSocket support for real-time data
# - Background tasks for data processing
# - Caching layer for performance
# - AI integration endpoints
```

### Step 2: Data Models
```python
# Copilot Prompt:
# Design models for:
# - Metrics (time-series data)
# - Dashboards (user configurations)
# - Insights (AI-generated)
# - Alerts (threshold-based)
```

### Step 3: Analytics Engine
```python
# Copilot Prompt:
# Build analytics engine that:
# - Aggregates data by time periods
# - Calculates statistical metrics
# - Detects anomalies
# - Generates forecasts
```

### Step 4: AI Integration
```python
# Copilot Prompt:
# Integrate OpenAI for:
# - Natural language insights
# - Pattern recognition
# - Predictive analytics
# - Report generation
```

### Step 5: Frontend Dashboard
```typescript
// Copilot Prompt:
// Create React dashboard with:
// - Responsive grid layout
// - Chart.js visualizations
// - Real-time WebSocket updates
// - Dark/light theme toggle
```

## Technologies

### Backend
- FastAPI (async web framework)
- SQLAlchemy (ORM)
- Redis (caching & pub/sub)
- Celery (background tasks)
- Pandas (data analysis)
- Scikit-learn (ML models)
- OpenAI API (AI insights)

### Frontend
- React 18 with TypeScript
- Chart.js / Recharts (visualizations)
- Socket.io-client (WebSocket)
- React Query (data fetching)
- Tailwind CSS (styling)
- React Grid Layout (drag-drop)

## Getting Started

1. **Setup Backend**:
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Setup Frontend**:
   ```bash
   cd frontend
   npm install
   ```

3. **Start Services**:
   ```bash
   docker-compose up -d redis postgres
   # Terminal 1
   cd backend && python -m app.main
   # Terminal 2
   cd frontend && npm run dev
   ```

## Copilot Best Practices

1. **Describe Intent Clearly**:
   ```python
   # Create a function that detects anomalies in time-series data
   # using statistical methods (z-score, IQR) and returns
   # anomaly points with confidence scores
   ```

2. **Use Type Hints**:
   ```python
   def analyze_trends(data: List[MetricPoint]) -> TrendAnalysis:
       # Copilot will understand the expected types
   ```

3. **Provide Examples**:
   ```python
   # Example input: [{"timestamp": "2024-01-01", "value": 100}, ...]
   # Example output: {"trend": "increasing", "slope": 0.5, ...}
   ```

## Challenges

### 🌟 Performance
- Handle 1M+ data points efficiently
- Sub-second response times
- Smooth real-time updates

### 🤖 AI Accuracy
- Meaningful insights generation
- Accurate predictions
- Contextual recommendations

### 🎨 User Experience
- Intuitive interface
- Responsive design
- Accessibility (WCAG 2.1)

## Resources

- [FastAPI WebSocket Guide](https://fastapi.tiangolo.com/advanced/websockets/)
- [Chart.js Documentation](https://www.chartjs.org/docs/)
- [React Grid Layout](https://github.com/react-grid-layout/react-grid-layout)
- [Time Series Analysis](https://otexts.com/fpp3/)
- [OpenAI Cookbook](https://cookbook.openai.com/)

Start building your AI-powered analytics dashboard!