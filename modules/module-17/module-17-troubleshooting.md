# Module 17: Troubleshooting Guide

## 🔍 Common Issues and Solutions

This guide helps you diagnose and resolve common issues encountered when working with GitHub Models and AI integration in Module 17.

## 🚨 API Connection Issues

### 1. GitHub Models Authentication Failed

**Symptoms:**
- 401 Unauthorized errors
- "Invalid token" messages
- Cannot access GitHub Models API

**Diagnosis Steps:**

```bash
# Check GitHub token
echo $GITHUB_TOKEN | cut -c1-10  # Should show first 10 chars

# Test GitHub API access
curl -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/user

# Test GitHub Models access
curl -X POST https://models.inference.ai.azure.com/chat/completions \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Hello"}],"model":"gpt-4"}'
```

**Solutions:**

1. **Regenerate GitHub Token:**
   ```bash
   # Generate new token with correct scopes
   gh auth refresh -s read:packages,read:org
   
   # Update environment variable
   export GITHUB_TOKEN=$(gh auth token)
   ```

2. **Check Token Permissions:**
   - Ensure token has `read:packages` scope
   - Verify you have access to GitHub Models (check waitlist status)

3. **Use Personal Access Token:**
   ```bash
   # If gh CLI doesn't work, create PAT manually
   # Go to GitHub Settings > Developer settings > Personal access tokens
   # Create token with required scopes
   ```

### 2. Azure OpenAI Connection Issues

**Symptoms:**
- Connection timeouts
- 404 Resource not found
- API version mismatch errors

**Diagnosis:**

```python
# Test Azure OpenAI connection
import httpx
import os

endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
api_key = os.getenv("AZURE_OPENAI_API_KEY")

# Test endpoint
response = httpx.get(
    f"{endpoint}/openai/models?api-version=2023-12-01-preview",
    headers={"api-key": api_key}
)
print(f"Status: {response.status_code}")
print(f"Models: {response.json()}")
```

**Solutions:**

1. **Verify Endpoint Format:**
   ```bash
   # Correct format (no trailing slash)
   export AZURE_OPENAI_ENDPOINT="https://your-resource.openai.azure.com"
   
   # Not this
   export AZURE_OPENAI_ENDPOINT="https://your-resource.openai.azure.com/"
   ```

2. **Check Deployment Names:**
   ```bash
   # List deployments
   az cognitiveservices account deployment list \
     --resource-group "rg-workshop-module17" \
     --name "your-openai-resource"
   ```

3. **Update API Version:**
   ```python
   # Use latest stable API version
   api_version = "2023-12-01-preview"  # or "2024-02-15-preview"
   ```

## 🧮 Embedding Issues

### 1. Embedding Dimension Mismatch

**Symptoms:**
- Vector database insertion fails
- "Dimension mismatch" errors
- Search returns no results

**Diagnosis:**

```python
# Check embedding dimensions
import numpy as np

def check_embedding_dimensions(embeddings):
    """Verify embedding dimensions."""
    for i, emb in enumerate(embeddings):
        print(f"Embedding {i}: {len(emb)} dimensions")
    
    # Check consistency
    dimensions = [len(emb) for emb in embeddings]
    if len(set(dimensions)) > 1:
        print("WARNING: Inconsistent dimensions detected!")
```

**Solutions:**

1. **Verify Model Configuration:**
   ```python
   # Ensure consistent model usage
   EMBEDDING_MODELS = {
       "text-embedding-ada-002": 1536,
       "text-embedding-3-small": 1536,
       "text-embedding-3-large": 3072
   }
   
   def validate_embedding(embedding, model):
       expected_dim = EMBEDDING_MODELS.get(model)
       if len(embedding) != expected_dim:
           raise ValueError(f"Expected {expected_dim} dimensions, got {len(embedding)}")
   ```

2. **Normalize Embeddings:**
   ```python
   def normalize_embedding(embedding):
       """Normalize embedding to unit length."""
       norm = np.linalg.norm(embedding)
       if norm > 0:
           return (embedding / norm).tolist()
       return embedding
   ```

### 2. Slow Embedding Generation

**Symptoms:**
- Embedding generation takes >1 second per text
- Timeouts on batch processing
- High API costs

**Solutions:**

1. **Implement Batching:**
   ```python
   async def generate_embeddings_batch(texts, batch_size=100):
       """Generate embeddings in batches."""
       embeddings = []
       
       for i in range(0, len(texts), batch_size):
           batch = texts[i:i + batch_size]
           batch_embeddings = await embedding_service.create_embeddings(
               input=batch,
               model="text-embedding-ada-002"
           )
           embeddings.extend(batch_embeddings)
           
           # Rate limiting
           if i + batch_size < len(texts):
               await asyncio.sleep(0.1)
       
       return embeddings
   ```

2. **Use Caching Aggressively:**
   ```python
   class CachedEmbeddingService:
       def __init__(self, cache_client, embedding_service):
           self.cache = cache_client
           self.service = embedding_service
           
       async def get_embedding(self, text):
           # Check cache first
           cache_key = hashlib.sha256(text.encode()).hexdigest()
           cached = await self.cache.get(cache_key)
           
           if cached:
               return json.loads(cached)
           
           # Generate and cache
           embedding = await self.service.create_embedding(text)
           await self.cache.setex(
               cache_key,
               86400,  # 24 hour TTL
               json.dumps(embedding)
           )
           
           return embedding
   ```

## 🔍 Vector Search Issues

### 1. Poor Search Results

**Symptoms:**
- Irrelevant results returned
- Low similarity scores
- Missing expected results

**Diagnosis:**

```python
# Debug search quality
async def debug_search(query, vector_store):
    """Debug search results."""
    # Get query embedding
    query_embedding = await get_embedding(query)
    
    # Search with different parameters
    results = await vector_store.search(
        vector=query_embedding,
        top_k=20,  # Get more results for analysis
        include_metadata=True
    )
    
    # Analyze results
    for i, result in enumerate(results):
        print(f"\n--- Result {i+1} ---")
        print(f"Score: {result['score']:.4f}")
        print(f"Content: {result['content'][:200]}...")
        print(f"Metadata: {result['metadata']}")
```

**Solutions:**

1. **Adjust Similarity Threshold:**
   ```python
   # Experiment with different thresholds
   SIMILARITY_THRESHOLDS = {
       "high_precision": 0.85,  # Fewer, more relevant results
       "balanced": 0.75,        # Default
       "high_recall": 0.65      # More results, possibly less relevant
   }
   ```

2. **Implement Hybrid Search:**
   ```python
   class HybridSearch:
       async def search(self, query, top_k=10):
           # Vector search
           vector_results = await self.vector_search(query, top_k * 2)
           
           # Keyword search
           keyword_results = await self.keyword_search(query, top_k * 2)
           
           # Combine and re-rank
           combined = self.combine_results(vector_results, keyword_results)
           return combined[:top_k]
   ```

### 2. Vector Database Performance

**Symptoms:**
- Slow search queries (>500ms)
- High memory usage
- Database connection errors

**Solutions:**

1. **Optimize Index Configuration:**
   ```python
   # Qdrant optimization
   from qdrant_client.models import Distance, VectorParams, OptimizersConfig
   
   collection_config = {
       "vectors": VectorParams(
           size=1536,
           distance=Distance.COSINE
       ),
       "optimizers_config": OptimizersConfig(
           deleted_threshold=0.2,
           vacuum_min_vector_number=1000,
           default_segment_number=4
       )
   }
   ```

2. **Implement Connection Pooling:**
   ```python
   class VectorDBPool:
       def __init__(self, url, pool_size=10):
           self.pool = asyncio.Queue(maxsize=pool_size)
           for _ in range(pool_size):
               client = QdrantClient(url)
               self.pool.put_nowait(client)
       
       @asynccontextmanager
       async def get_client(self):
           client = await self.pool.get()
           try:
               yield client
           finally:
               await self.pool.put(client)
   ```

## 🤖 RAG Issues

### 1. Context Window Exceeded

**Symptoms:**
- "Context length exceeded" errors
- Truncated responses
- Missing information in answers

**Solutions:**

1. **Smart Context Selection:**
   ```python
   def select_context_chunks(chunks, max_tokens=3000):
       """Select most relevant chunks within token limit."""
       selected = []
       current_tokens = 0
       
       # Sort by relevance score
       sorted_chunks = sorted(chunks, key=lambda x: x['score'], reverse=True)
       
       for chunk in sorted_chunks:
           chunk_tokens = count_tokens(chunk['content'])
           if current_tokens + chunk_tokens <= max_tokens:
               selected.append(chunk)
               current_tokens += chunk_tokens
           else:
               # Try to fit partial chunk
               remaining = max_tokens - current_tokens
               if remaining > 100:  # Minimum useful chunk size
                   truncated = truncate_to_tokens(chunk['content'], remaining)
                   selected.append({**chunk, 'content': truncated})
               break
       
       return selected
   ```

2. **Implement Summarization:**
   ```python
   async def summarize_context(chunks, max_tokens=1000):
       """Summarize chunks that don't fit in context."""
       overflow_chunks = chunks[max_chunks:]
       
       if not overflow_chunks:
           return None
       
       summary_prompt = f"""
       Summarize these text chunks in {max_tokens} tokens:
       {format_chunks(overflow_chunks)}
       """
       
       summary = await generate_completion(summary_prompt)
       return summary
   ```

### 2. Hallucination in Responses

**Symptoms:**
- AI provides information not in context
- Fabricated citations
- Inconsistent answers

**Solutions:**

1. **Strict Prompt Engineering:**
   ```python
   STRICT_RAG_PROMPT = """
   You are a helpful AI assistant. Answer the question based ONLY on the provided context.
   
   Rules:
   1. Only use information explicitly stated in the context
   2. If the context doesn't contain the answer, say "I don't have enough information"
   3. Always cite the source section when making claims
   4. Do not add information from your training data
   
   Context:
   {context}
   
   Question: {question}
   
   Answer with citations:
   """
   ```

2. **Response Validation:**
   ```python
   class ResponseValidator:
       async def validate_response(self, response, context_chunks):
           """Validate response against context."""
           # Extract claims from response
           claims = self.extract_claims(response)
           
           # Verify each claim
           validation_results = []
           for claim in claims:
               is_supported = await self.verify_claim(claim, context_chunks)
               validation_results.append({
                   "claim": claim,
                   "supported": is_supported
               })
           
           # Calculate confidence score
           supported_claims = sum(1 for r in validation_results if r["supported"])
           confidence = supported_claims / len(claims) if claims else 1.0
           
           return {
               "response": response,
               "confidence": confidence,
               "validation": validation_results
           }
   ```

## 💰 Cost Issues

### 1. Unexpected High Costs

**Symptoms:**
- API bills higher than expected
- Rapid token consumption
- Budget alerts triggered

**Diagnosis:**

```python
# Token usage analyzer
class TokenUsageAnalyzer:
    def __init__(self):
        self.usage_log = []
    
    def analyze_usage(self, days=7):
        """Analyze token usage patterns."""
        # Group by model
        by_model = defaultdict(int)
        by_operation = defaultdict(int)
        
        for entry in self.usage_log:
            by_model[entry['model']] += entry['tokens']
            by_operation[entry['operation']] += entry['tokens']
        
        # Find outliers
        avg_tokens = statistics.mean(e['tokens'] for e in self.usage_log)
        outliers = [e for e in self.usage_log if e['tokens'] > avg_tokens * 3]
        
        return {
            "by_model": dict(by_model),
            "by_operation": dict(by_operation),
            "outliers": outliers,
            "total_tokens": sum(e['tokens'] for e in self.usage_log)
        }
```

**Solutions:**

1. **Implement Budget Controls:**
   ```python
   class BudgetController:
       def __init__(self, daily_limit=100.0):
           self.daily_limit = daily_limit
           self.daily_spent = 0.0
           self.reset_time = datetime.now()
       
       async def check_budget(self, estimated_cost):
           """Check if request fits in budget."""
           # Reset daily counter
           if datetime.now().date() > self.reset_time.date():
               self.daily_spent = 0.0
               self.reset_time = datetime.now()
           
           if self.daily_spent + estimated_cost > self.daily_limit:
               raise BudgetExceededError(
                   f"Daily budget of ${self.daily_limit} would be exceeded"
               )
           
           return True
       
       def record_usage(self, actual_cost):
           """Record actual usage."""
           self.daily_spent += actual_cost
   ```

2. **Use Cheaper Models When Appropriate:**
   ```python
   def select_model_by_complexity(prompt):
       """Select model based on task complexity."""
       # Simple queries
       if len(prompt.split()) < 50 and "?" in prompt:
           return "gpt-3.5-turbo"
       
       # Code generation
       if any(keyword in prompt.lower() for keyword in ["code", "function", "implement"]):
           return "gpt-4"
       
       # Complex reasoning
       if any(keyword in prompt.lower() for keyword in ["analyze", "compare", "evaluate"]):
           return "gpt-4"
       
       # Default to cheaper model
       return "gpt-3.5-turbo"
   ```

## 🔧 Performance Issues

### 1. Slow Response Times

**Symptoms:**
- API responses take >5 seconds
- Timeouts in production
- Poor user experience

**Solutions:**

1. **Implement Streaming:**
   ```python
   async def stream_completion(prompt):
       """Stream response for better UX."""
       async with httpx.AsyncClient() as client:
           async with client.stream(
               "POST",
               "https://api.openai.com/v1/chat/completions",
               json={
                   "model": "gpt-4",
                   "messages": [{"role": "user", "content": prompt}],
                   "stream": True
               },
               headers={"Authorization": f"Bearer {api_key}"}
           ) as response:
               async for line in response.aiter_lines():
                   if line.startswith("data: "):
                       yield line[6:]  # Remove "data: " prefix
   ```

2. **Parallel Processing:**
   ```python
   async def process_multiple_queries(queries):
       """Process multiple queries in parallel."""
       # Limit concurrency to avoid rate limits
       semaphore = asyncio.Semaphore(5)
       
       async def process_with_limit(query):
           async with semaphore:
               return await process_query(query)
       
       tasks = [process_with_limit(q) for q in queries]
       results = await asyncio.gather(*tasks, return_exceptions=True)
       
       return results
   ```

## 📊 Monitoring and Debugging

### Enable Detailed Logging

```python
import logging
import sys

# Configure comprehensive logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('ai_integration.log'),
        logging.StreamHandler(sys.stdout)
    ]
)

# Add request/response logging
class LoggingMiddleware:
    async def __call__(self, request, call_next):
        # Log request
        logger.info(f"Request: {request.method} {request.url}")
        logger.debug(f"Headers: {request.headers}")
        
        # Process request
        response = await call_next(request)
        
        # Log response
        logger.info(f"Response: {response.status_code}")
        
        return response
```

### Debug Mode for Development

```python
class DebugMode:
    """Enable debug mode for detailed diagnostics."""
    
    def __init__(self):
        self.enabled = os.getenv("DEBUG_MODE", "false").lower() == "true"
    
    def log_embedding_generation(self, text, embedding, duration):
        if not self.enabled:
            return
        
        print(f"\n{'='*50}")
        print(f"EMBEDDING GENERATION DEBUG")
        print(f"Text: {text[:100]}...")
        print(f"Embedding dims: {len(embedding)}")
        print(f"Embedding sample: {embedding[:5]}")
        print(f"Duration: {duration:.3f}s")
        print(f"{'='*50}\n")
    
    def log_search_results(self, query, results, duration):
        if not self.enabled:
            return
        
        print(f"\n{'='*50}")
        print(f"SEARCH DEBUG")
        print(f"Query: {query}")
        print(f"Results found: {len(results)}")
        print(f"Top score: {results[0]['score'] if results else 'N/A'}")
        print(f"Duration: {duration:.3f}s")
        print(f"{'='*50}\n")
```

## 🚑 Emergency Procedures

### Service Completely Down

1. **Check Service Health:**
   ```bash
   # Check all services
   curl http://localhost:8000/health
   docker-compose ps
   ```

2. **Restart Services:**
   ```bash
   # Restart specific service
   docker-compose restart orchestrator
   
   # Full restart
   docker-compose down
   docker-compose up -d
   ```

3. **Check Logs:**
   ```bash
   # Application logs
   docker-compose logs -f orchestrator
   
   # Error grep
   docker-compose logs | grep ERROR
   ```

### Data Recovery

```python
# Backup critical data
async def backup_vectors():
    """Backup vector database."""
    vectors = await vector_store.get_all()
    
    with open(f"backup_{datetime.now().isoformat()}.json", "w") as f:
        json.dump(vectors, f)
    
    print(f"Backed up {len(vectors)} vectors")

# Restore from backup
async def restore_vectors(backup_file):
    """Restore vector database from backup."""
    with open(backup_file, "r") as f:
        vectors = json.load(f)
    
    for vector in vectors:
        await vector_store.add_vector(**vector)
    
    print(f"Restored {len(vectors)} vectors")
```

## 🎯 Quick Reference

| Issue | Quick Check | Quick Fix |
|-------|-------------|-----------|
| Auth fails | `echo $GITHUB_TOKEN` | Regenerate token |
| No embeddings | Check dimensions | Verify model name |
| Slow search | Check index size | Optimize parameters |
| High costs | Check token usage | Use cheaper models |
| Timeouts | Check API status | Implement retry |

Remember: **When debugging AI integration issues, always check logs, verify API credentials, and test with minimal examples first!**