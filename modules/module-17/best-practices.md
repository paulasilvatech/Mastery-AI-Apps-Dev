# Module 17: AI Integration Best Practices

## 🎯 Overview

This guide provides production-tested best practices for integrating AI models into enterprise applications using GitHub Models and Azure OpenAI. These patterns have been proven in systems processing millions of AI requests daily.

## 🔑 API Key Management

### Security Best Practices

**❌ Don't:**
```python
# Never hardcode API keys
api_key = "sk-proj-abcd1234..."
client = OpenAI(api_key=api_key)
```

**✅ Do:**
```python
# Use environment variables or secure vaults
import os
from azure.keyvault.secrets import SecretClient
from azure.identity import DefaultAzureCredential

class SecureAPIClient:
    def __init__(self):
        # Option 1: Environment variables
        self.github_token = os.getenv("GITHUB_TOKEN")
        
        # Option 2: Azure Key Vault
        credential = DefaultAzureCredential()
        vault_url = os.getenv("AZURE_KEY_VAULT_URL")
        client = SecretClient(vault_url=vault_url, credential=credential)
        self.azure_api_key = client.get_secret("azure-openai-key").value
        
    def rotate_keys(self):
        """Implement key rotation strategy."""
        # Rotate keys every 90 days
        # Keep previous key active for 24 hours
        pass
```

### API Key Rotation Strategy
```python
class APIKeyManager:
    """Manage API keys with rotation support."""
    
    def __init__(self, vault_client):
        self.vault_client = vault_client
        self.key_cache = {}
        self.key_expiry = {}
        
    async def get_active_key(self, service: str) -> str:
        """Get active API key with automatic rotation check."""
        if self._is_key_expired(service):
            await self._rotate_key(service)
        
        return self.key_cache.get(service)
    
    def _is_key_expired(self, service: str) -> bool:
        """Check if key needs rotation."""
        expiry = self.key_expiry.get(service)
        if not expiry:
            return True
        
        return datetime.utcnow() > expiry
```

## 🏗️ Architecture Patterns

### 1. Gateway Pattern for AI Services

```python
from abc import ABC, abstractmethod
from typing import Any, Dict, Optional
import httpx
from tenacity import retry, stop_after_attempt, wait_exponential

class AIGateway:
    """Unified gateway for all AI services."""
    
    def __init__(self):
        self.providers = {
            "github": GitHubModelsProvider(),
            "azure": AzureOpenAIProvider(),
            "anthropic": AnthropicProvider()
        }
        self.circuit_breakers = {}
        self.metrics_collector = MetricsCollector()
        
    async def complete(
        self,
        prompt: str,
        provider: Optional[str] = None,
        **kwargs
    ) -> Dict[str, Any]:
        """Route completion request to appropriate provider."""
        # Select provider based on request characteristics
        if not provider:
            provider = self._select_provider(prompt, kwargs)
        
        # Check circuit breaker
        if self._is_circuit_open(provider):
            provider = self._get_fallback_provider(provider)
        
        # Execute request with monitoring
        start_time = time.time()
        try:
            result = await self.providers[provider].complete(prompt, **kwargs)
            self._record_success(provider, time.time() - start_time)
            return result
        except Exception as e:
            self._record_failure(provider, e)
            raise
```

### 2. Embedding Cache Pattern

```python
class EmbeddingCache:
    """Intelligent caching for embeddings."""
    
    def __init__(self, redis_client, ttl_hours: int = 24):
        self.redis = redis_client
        self.ttl = ttl_hours * 3600
        self.bloom_filter = BloomFilter(capacity=1000000)
        
    async def get_or_generate(
        self,
        text: str,
        generator_func,
        model: str = "text-embedding-ada-002"
    ) -> List[float]:
        """Get embedding from cache or generate new one."""
        # Normalize text for consistent caching
        normalized = self._normalize_text(text)
        cache_key = self._generate_key(normalized, model)
        
        # Quick existence check with Bloom filter
        if cache_key not in self.bloom_filter:
            embedding = await generator_func(text, model)
            await self._cache_embedding(cache_key, embedding)
            self.bloom_filter.add(cache_key)
            return embedding
        
        # Try cache
        cached = await self.redis.get(cache_key)
        if cached:
            return json.loads(cached)
        
        # Generate and cache
        embedding = await generator_func(text, model)
        await self._cache_embedding(cache_key, embedding)
        return embedding
    
    def _normalize_text(self, text: str) -> str:
        """Normalize text for consistent caching."""
        # Remove extra whitespace
        text = " ".join(text.split())
        # Lowercase for case-insensitive caching
        return text.lower().strip()
```

### 3. RAG Pipeline Best Practices

```python
class ProductionRAG:
    """Production-ready RAG implementation."""
    
    def __init__(self, config: RAGConfig):
        self.config = config
        self.chunker = AdaptiveChunker()
        self.embedder = EmbeddingService()
        self.retriever = HybridRetriever()
        self.generator = ResponseGenerator()
        self.evaluator = RAGEvaluator()
        
    async def query(
        self,
        question: str,
        context: Optional[Dict] = None
    ) -> RAGResponse:
        """Execute RAG pipeline with production safeguards."""
        
        # 1. Query understanding and expansion
        analyzed_query = await self._analyze_query(question)
        
        # 2. Retrieve with fallback strategies
        chunks = await self._retrieve_with_fallback(
            analyzed_query,
            strategies=["vector", "keyword", "semantic"]
        )
        
        # 3. Re-rank and filter
        relevant_chunks = await self._rerank_chunks(
            question,
            chunks,
            threshold=self.config.relevance_threshold
        )
        
        # 4. Generate with citation tracking
        response = await self._generate_response(
            question,
            relevant_chunks,
            include_citations=True
        )
        
        # 5. Post-process and validate
        validated_response = await self._validate_response(
            response,
            relevant_chunks
        )
        
        # 6. Async evaluation for continuous improvement
        asyncio.create_task(
            self.evaluator.evaluate(question, validated_response)
        )
        
        return validated_response
    
    async def _retrieve_with_fallback(
        self,
        query: AnalyzedQuery,
        strategies: List[str]
    ) -> List[Chunk]:
        """Retrieve with multiple strategies and fallback."""
        chunks = []
        
        for strategy in strategies:
            try:
                if strategy == "vector":
                    chunks = await self.retriever.vector_search(
                        query.embedding,
                        top_k=self.config.initial_retrieval_count
                    )
                elif strategy == "keyword":
                    chunks = await self.retriever.keyword_search(
                        query.keywords,
                        top_k=self.config.initial_retrieval_count
                    )
                elif strategy == "semantic":
                    chunks = await self.retriever.semantic_search(
                        query.intent,
                        top_k=self.config.initial_retrieval_count
                    )
                
                if len(chunks) >= self.config.min_chunks_required:
                    break
                    
            except Exception as e:
                logger.error(f"Retrieval strategy {strategy} failed: {e}")
                continue
        
        return chunks
```

## 💰 Cost Optimization

### 1. Token Usage Optimization

```python
class TokenOptimizer:
    """Optimize token usage across requests."""
    
    def __init__(self):
        self.tokenizer = tiktoken.get_encoding("cl100k_base")
        
    def optimize_prompt(
        self,
        prompt: str,
        max_tokens: int,
        preserve_sections: List[str] = None
    ) -> str:
        """Optimize prompt to fit within token limits."""
        tokens = self.tokenizer.encode(prompt)
        
        if len(tokens) <= max_tokens:
            return prompt
        
        # Smart truncation preserving important sections
        sections = self._parse_sections(prompt)
        optimized = self._smart_truncate(
            sections,
            max_tokens,
            preserve_sections or []
        )
        
        return optimized
    
    def batch_requests(
        self,
        requests: List[str],
        max_batch_tokens: int = 8000
    ) -> List[List[str]]:
        """Batch multiple requests efficiently."""
        batches = []
        current_batch = []
        current_tokens = 0
        
        for request in requests:
            request_tokens = len(self.tokenizer.encode(request))
            
            if current_tokens + request_tokens > max_batch_tokens:
                if current_batch:
                    batches.append(current_batch)
                current_batch = [request]
                current_tokens = request_tokens
            else:
                current_batch.append(request)
                current_tokens += request_tokens
        
        if current_batch:
            batches.append(current_batch)
        
        return batches
```

### 2. Model Selection Strategy

```python
class CostAwareModelSelector:
    """Select models based on cost-quality tradeoffs."""
    
    def __init__(self, model_registry: ModelRegistry):
        self.registry = model_registry
        self.performance_history = defaultdict(list)
        
    def select_model(
        self,
        task: str,
        quality_requirement: float = 0.8,
        budget_constraint: Optional[float] = None
    ) -> str:
        """Select optimal model for task."""
        candidates = self.registry.get_models_for_task(task)
        
        # Filter by quality requirement
        quality_models = [
            m for m in candidates
            if m.quality_score >= quality_requirement
        ]
        
        if not quality_models:
            # Relax quality requirement if needed
            quality_models = candidates[:3]  # Top 3 by quality
        
        # Apply budget constraint
        if budget_constraint:
            quality_models = [
                m for m in quality_models
                if m.cost_per_1k_input <= budget_constraint
            ]
        
        # Select based on cost-effectiveness
        if quality_models:
            return min(
                quality_models,
                key=lambda m: m.cost_per_1k_input / m.quality_score
            ).name
        
        # Fallback to cheapest available
        return min(candidates, key=lambda m: m.cost_per_1k_input).name
```

### 3. Response Caching Strategy

```python
class SemanticCache:
    """Cache responses based on semantic similarity."""
    
    def __init__(self, vector_store, similarity_threshold: float = 0.95):
        self.vector_store = vector_store
        self.threshold = similarity_threshold
        self.cache_hits = 0
        self.cache_misses = 0
        
    async def get_or_generate(
        self,
        query: str,
        generator_func,
        max_cache_age_hours: int = 24
    ) -> str:
        """Get cached response or generate new one."""
        # Generate query embedding
        query_embedding = await self._get_embedding(query)
        
        # Search for similar cached queries
        similar = await self.vector_store.search(
            vector=query_embedding,
            top_k=1,
            filters={"timestamp": {"$gte": time.time() - max_cache_age_hours * 3600}}
        )
        
        if similar and similar[0]["score"] >= self.threshold:
            self.cache_hits += 1
            logger.info(f"Cache hit with similarity {similar[0]['score']:.3f}")
            return similar[0]["response"]
        
        # Generate new response
        self.cache_misses += 1
        response = await generator_func(query)
        
        # Cache for future use
        await self._cache_response(query, query_embedding, response)
        
        return response
```

## 🔍 Monitoring and Observability

### 1. Comprehensive Metrics Collection

```python
from prometheus_client import Counter, Histogram, Gauge
import opentelemetry.trace as trace

class AIMetrics:
    """Comprehensive metrics for AI operations."""
    
    def __init__(self):
        # Request metrics
        self.request_count = Counter(
            'ai_requests_total',
            'Total AI requests',
            ['provider', 'model', 'task_type']
        )
        
        self.request_duration = Histogram(
            'ai_request_duration_seconds',
            'Request duration',
            ['provider', 'model'],
            buckets=[0.1, 0.5, 1.0, 2.0, 5.0, 10.0]
        )
        
        # Token metrics
        self.tokens_used = Counter(
            'ai_tokens_total',
            'Total tokens used',
            ['provider', 'model', 'token_type']
        )
        
        # Cost metrics
        self.cost_total = Counter(
            'ai_cost_dollars_total',
            'Total cost in dollars',
            ['provider', 'model']
        )
        
        # Quality metrics
        self.response_quality = Histogram(
            'ai_response_quality_score',
            'Response quality scores',
            ['model', 'task_type'],
            buckets=[0.1, 0.3, 0.5, 0.7, 0.9, 1.0]
        )
        
        # Cache metrics
        self.cache_hit_rate = Gauge(
            'ai_cache_hit_rate',
            'Cache hit rate',
            ['cache_type']
        )
        
        self.tracer = trace.get_tracer(__name__)
    
    def record_request(
        self,
        provider: str,
        model: str,
        task_type: str,
        duration: float,
        tokens: Dict[str, int],
        cost: float
    ):
        """Record comprehensive request metrics."""
        # Update counters
        self.request_count.labels(provider, model, task_type).inc()
        self.request_duration.labels(provider, model).observe(duration)
        
        # Token tracking
        for token_type, count in tokens.items():
            self.tokens_used.labels(provider, model, token_type).inc(count)
        
        # Cost tracking
        self.cost_total.labels(provider, model).inc(cost)
    
    @contextmanager
    def trace_operation(self, operation_name: str, attributes: Dict = None):
        """Trace AI operations with OpenTelemetry."""
        with self.tracer.start_as_current_span(operation_name) as span:
            if attributes:
                for key, value in attributes.items():
                    span.set_attribute(key, value)
            
            try:
                yield span
            except Exception as e:
                span.record_exception(e)
                span.set_status(trace.Status(trace.StatusCode.ERROR))
                raise
```

### 2. Request Tracing

```python
class RequestTracer:
    """Trace AI requests for debugging and optimization."""
    
    def __init__(self):
        self.traces = {}
        
    async def trace_request(self, request_id: str, func, *args, **kwargs):
        """Trace a complete request lifecycle."""
        trace = {
            "request_id": request_id,
            "start_time": time.time(),
            "steps": []
        }
        
        # Set trace context
        self._set_trace_context(request_id)
        
        try:
            # Execute with tracing
            result = await func(*args, **kwargs)
            
            trace["end_time"] = time.time()
            trace["duration"] = trace["end_time"] - trace["start_time"]
            trace["status"] = "success"
            trace["result"] = self._summarize_result(result)
            
        except Exception as e:
            trace["end_time"] = time.time()
            trace["duration"] = trace["end_time"] - trace["start_time"]
            trace["status"] = "error"
            trace["error"] = str(e)
            raise
        
        finally:
            self.traces[request_id] = trace
            await self._export_trace(trace)
    
    def add_trace_step(self, request_id: str, step_name: str, data: Dict):
        """Add a step to ongoing trace."""
        if request_id in self.traces:
            self.traces[request_id]["steps"].append({
                "name": step_name,
                "timestamp": time.time(),
                "data": data
            })
```

## 🚨 Error Handling and Resilience

### 1. Retry Strategy with Exponential Backoff

```python
from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type,
    before_retry
)

class ResilientAIClient:
    """AI client with comprehensive error handling."""
    
    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=4, max=60),
        retry=retry_if_exception_type((
            httpx.TimeoutException,
            httpx.ConnectError,
            RateLimitError
        )),
        before=before_retry(log_retry_attempt)
    )
    async def complete(self, prompt: str, **kwargs) -> str:
        """Complete with automatic retry on transient errors."""
        try:
            response = await self._make_request(prompt, **kwargs)
            return self._validate_response(response)
            
        except RateLimitError as e:
            # Handle rate limits gracefully
            wait_time = self._parse_retry_after(e.headers)
            logger.warning(f"Rate limited, waiting {wait_time}s")
            await asyncio.sleep(wait_time)
            raise
            
        except TokenLimitError as e:
            # Handle token limits by chunking
            logger.info("Token limit exceeded, chunking request")
            return await self._complete_chunked(prompt, **kwargs)
```

### 2. Circuit Breaker Implementation

```python
class CircuitBreaker:
    """Circuit breaker for AI services."""
    
    def __init__(
        self,
        failure_threshold: int = 5,
        recovery_timeout: int = 60,
        expected_exception: type = Exception
    ):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.expected_exception = expected_exception
        self.failure_count = 0
        self.last_failure_time = None
        self.state = "CLOSED"  # CLOSED, OPEN, HALF_OPEN
        
    async def call(self, func, *args, **kwargs):
        """Execute function with circuit breaker protection."""
        if self.state == "OPEN":
            if self._should_attempt_reset():
                self.state = "HALF_OPEN"
            else:
                raise CircuitOpenError("Circuit breaker is OPEN")
        
        try:
            result = await func(*args, **kwargs)
            self._on_success()
            return result
            
        except self.expected_exception as e:
            self._on_failure()
            raise
```

## 🎯 Production Checklist

Before deploying AI features to production:

### Security
- [ ] API keys stored in secure vault
- [ ] Key rotation implemented
- [ ] Request authentication in place
- [ ] PII detection and masking
- [ ] Audit logging enabled

### Performance
- [ ] Response caching implemented
- [ ] Token usage optimized
- [ ] Batch processing where applicable
- [ ] Connection pooling configured
- [ ] Circuit breakers in place

### Monitoring
- [ ] Metrics collection active
- [ ] Distributed tracing enabled
- [ ] Error tracking configured
- [ ] Cost monitoring alerts set
- [ ] Quality metrics tracked

### Reliability
- [ ] Retry logic implemented
- [ ] Fallback models configured
- [ ] Timeout handling in place
- [ ] Graceful degradation tested
- [ ] Load testing completed

### Compliance
- [ ] Data residency verified
- [ ] Consent mechanisms in place
- [ ] Data retention policies set
- [ ] Privacy impact assessment done
- [ ] Terms of service reviewed

## 📚 Additional Resources

- [OpenAI Production Best Practices](https://platform.openai.com/docs/guides/production-best-practices)
- [Azure OpenAI Responsible AI](https://learn.microsoft.com/azure/ai-services/openai/concepts/responsible-ai)
- [LangChain Production Guide](https://python.langchain.com/docs/guides/productionization)
- [Semantic Kernel Patterns](https://learn.microsoft.com/semantic-kernel/concepts/patterns)

---

Remember: **AI integration is not just about making API calls—it's about building reliable, scalable, and cost-effective systems that deliver value to users while maintaining security and compliance.**