import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'
import './index.css'

// TODO: Setup React Query provider with:
// - Default stale time of 5 minutes
// - Retry 3 times on failure  
// - Show React Query devtools in development

// Wrap your App with QueryClientProvider

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)