---
sidebar_position: 3
title: "Exercise 2: Part 2"
description: "## 🎯 Part 2 Overview"
---

# Ejercicio 2: Empresarial RAG System - Partee 2 (⭐⭐ Application)

## 🎯 Partee 2 Resumen

**Duración**: 35 minutos  
**Focus**: Query processing, context retrieval, and response generation

In Partee 2, you'll complete the RAG system by implementing the query pipeline that retrieves relevant context and generates accurate, grounded responses.

## 🎓 Objetivos de Aprendizaje - Partee 2

By completing Partee 2, you will:
- Implement advanced query processing
- Build context retrieval with re-ranking
- Create prompt templates for generation
- Add citation support to responses
- Implement conversation memory
- Evaluate RAG performance

## 🚀 Partee 2: Query Processing and Generation

### Step 9: Query Engine Implementation

Create `query_engine.py`:

**🤖 Copilot Prompt Suggestion #6:**
```python
# Build a query engine that:
# - Processes and expands user queries
# - Implements hybrid search (vector + keyword)
# - Re-ranks results using cross-encoder
# - Handles query decomposition for complex questions
# - Supports filtering by metadata
# - Implements query caching
# - Tracks query analytics
# Include relevance scoring and explanation
```

**Expected Implementation:**
```python
import asyncio
from typing import List, Dict, Any, Optional, Tuple
import logging
from dataclasses import dataclass
import numpy as np

logger = logging.getLogger(__name__)

@dataclass
class RetrievedContext:
    """Represents retrieved context for a query."""
    chunks: List[Dict[str, Any]]
    scores: List[float]
    total_tokens: int
    metadata: Dict[str, Any]

class QueryEngine:
    """Advanced query processing and retrieval engine."""
    
    def __init__(self, embedding_service, vector_store, settings):
        self.embedding_service = embedding_service
        self.vector_store = vector_store
        self.settings = settings
        self.query_cache = {}
        
    async def retrieve_context(
        self,
        query: str,
        top_k: int = 5,
        filters: Optional[Dict[str, Any]] = None,
        use_reranking: bool = True
    ) -&gt; RetrievedContext:
        """
        Retrieve relevant context for a query.
        
        Args:
            query: User query
            top_k: Number of chunks to retrieve
            filters: Metadata filters
            use_reranking: Whether to re-rank results
            
        Returns:
            Retrieved context with chunks and scores
        """
        # Check cache
        cache_key = self._get_cache_key(query, filters)
        if cache_key in self.query_cache:
            logger.info(f"Cache hit for query: {query[:50]}...")
            return self.query_cache[cache_key]
        
        # Expand query for better recall
        expanded_queries = await self._expand_query(query)
        
        # Perform vector search
        all_results = []
        for q in expanded_queries:
            embedding = await self.embedding_service.generate_embedding(q)
            results = await self.vector_store.search(
                vector=embedding,
                top_k=top_k * 2,  # Get more for re-ranking
                filters=filters
            )
            all_results.extend(results)
        
        # Deduplicate and merge results
        unique_results = self._deduplicate_results(all_results)
        
        # Re-rank if enabled
        if use_reranking:
            ranked_results = await self._rerank_results(query, unique_results)
        else:
            ranked_results = sorted(unique_results, key=lambda x: x['score'], reverse=True)
        
        # Select top-k after re-ranking
        final_results = ranked_results[:top_k]
        
        # Calculate total tokens
        total_tokens = sum(len(r['content'].split()) for r in final_results)
        
        # Create context object
        context = RetrievedContext(
            chunks=final_results,
            scores=[r['score'] for r in final_results],
            total_tokens=total_tokens,
            metadata={
                "query": query,
                "expanded_queries": expanded_queries,
                "filters": filters
            }
        )
        
        # Cache results
        self.query_cache[cache_key] = context
        
        return context
    
    async def _expand_query(self, query: str) -&gt; List[str]:
        """Expand query with synonyms and related terms."""
        # TODO: Implement query expansion
        # Copilot Prompt: Use GPT to generate query variations
        # Consider synonyms, related concepts, and rephrasings
        return [query]  # Placeholder
    
    async def _rerank_results(
        self,
        query: str,
        results: List[Dict[str, Any]]
    ) -&gt; List[Dict[str, Any]]:
        """Re-rank results using cross-encoder or LLM."""
        # TODO: Implement re-ranking
        # Copilot Prompt: Score each result's relevance to query
        # Use a smaller model for efficiency
        return results  # Placeholder
    
    def _deduplicate_results(
        self,
        results: List[Dict[str, Any]]
    ) -&gt; List[Dict[str, Any]]:
        """Remove duplicate chunks from results."""
        seen = set()
        unique = []
        
        for result in results:
            chunk_id = result.get('id', result.get('content')[:100])
            if chunk_id not in seen:
                seen.add(chunk_id)
                unique.append(result)
        
        return unique
    
    def _get_cache_key(self, query: str, filters: Optional[Dict] = None) -&gt; str:
        """Generate cache key for query."""
        import hashlib
        key_parts = [query]
        if filters:
            key_parts.append(str(sorted(filters.items())))
        
        key_string = "|".join(key_parts)
        return hashlib.sha256(key_string.encode()).hexdigest()
```

### Step 10: Response Generator

Create `generator.py`:

**🤖 Copilot Prompt Suggestion #7:**
```python
# Create a response generator that:
# - Uses retrieved context to generate responses
# - Implements prompt templates for consistency
# - Adds citations to source documents
# - Handles conversation history
# - Implements streaming responses
# - Falls back gracefully on errors
# - Tracks token usage and costs
# Support both GitHub Models and Azure OpenAI
```

**Expected Implementation Pattern:**
```python
from typing import List, Dict, Any, Optional, AsyncGenerator
import logging
from string import Template
import json

logger = logging.getLogger(__name__)

class ResponseGenerator:
    """Generate responses using retrieved context."""
    
    def __init__(self, settings):
        self.settings = settings
        self.conversation_history = []
        self._load_prompts()
        
    def _load_prompts(self):
        """Load prompt templates."""
        # System prompt
        with open(self.settings.system_prompt_path, 'r') as f:
            self.system_prompt = f.read()
        
        # User prompt template
        with open(self.settings.user_prompt_template, 'r') as f:
            self.user_prompt_template = Template(f.read())
    
    async def generate_response(
        self,
        query: str,
        context: 'RetrievedContext',
        stream: bool = False,
        include_citations: bool = True
    ) -&gt; Dict[str, Any]:
        """
        Generate response using retrieved context.
        
        Args:
            query: User query
            context: Retrieved context
            stream: Whether to stream response
            include_citations: Whether to include source citations
            
        Returns:
            Generated response with metadata
        """
        # Prepare context for prompt
        context_text = self._format_context(context.chunks)
        
        # Create user prompt
        user_prompt = self.user_prompt_template.substitute(
            query=query,
            context=context_text,
            instructions="Provide a comprehensive answer based on the context."
        )
        
        # Generate response
        if stream:
            return await self._generate_streaming(user_prompt)
        else:
            response = await self._generate_complete(user_prompt)
            
            # Add citations if requested
            if include_citations:
                response = self._add_citations(response, context.chunks)
            
            # Update conversation history
            self.conversation_history.append({
                "query": query,
                "response": response,
                "context_chunks": len(context.chunks)
            })
            
            return {
                "response": response,
                "sources": self._extract_sources(context.chunks),
                "metadata": {
                    "model": self.settings.generation_model,
                    "chunks_used": len(context.chunks),
                    "total_tokens": context.total_tokens
                }
            }
    
    def _format_context(self, chunks: List[Dict[str, Any]]) -&gt; str:
        """Format context chunks for prompt."""
        formatted_chunks = []
        
        for i, chunk in enumerate(chunks):
            source = chunk.get('metadata', {}).get('source', 'Unknown')
            content = chunk['content']
            formatted_chunks.append(
                f"[Source {i+1}: {source}]\n{content}\n"
            )
        
        return "\n---\n".join(formatted_chunks)
    
    async def _generate_complete(self, prompt: str) -&gt; str:
        """Generate complete response."""
        # TODO: Implement API call to GPT
        # Copilot Prompt: Call OpenAI API with retry logic
        # Handle both GitHub Models and Azure endpoints
        pass
    
    async def _generate_streaming(
        self,
        prompt: str
    ) -&gt; AsyncGenerator[str, None]:
        """Generate streaming response."""
        # TODO: Implement streaming generation
        # Copilot Prompt: Stream tokens from API
        # Yield chunks as they arrive
        pass
    
    def _add_citations(
        self,
        response: str,
        chunks: List[Dict[str, Any]]
    ) -&gt; str:
        """Add citations to response."""
        # TODO: Add inline citations
        # Copilot Prompt: Parse response and add [1], [2] citations
        # Match claims to source chunks
        return response
    
    def _extract_sources(
        self,
        chunks: List[Dict[str, Any]]
    ) -&gt; List[Dict[str, str]]:
        """Extract unique sources from chunks."""
        sources = []
        seen = set()
        
        for chunk in chunks:
            source = chunk.get('metadata', {}).get('source', 'Unknown')
            if source not in seen:
                seen.add(source)
                sources.append({
                    "document": source,
                    "relevance_score": chunk.get('score', 0.0)
                })
        
        return sources
```

### Step 11: Completar RAG System

Create `rag_system.py`:

**🤖 Copilot Prompt Suggestion #8:**
```python
# Build the complete RAG system that:
# - Orchestrates query engine and generator
# - Implements conversation management
# - Adds fallback strategies
# - Provides different response modes (concise, detailed, technical)
# - Includes confidence scoring
# - Supports multi-turn conversations
# - Implements feedback collection
# Make it production-ready with monitoring
```

### Step 12: Create Prompt Templates

Create `prompts/system.txt`:

```
You are an AI assistant that provides accurate, helpful responses based on the provided context. Your responses should be:

1. Grounded in the provided context
2. Clear and well-structured
3. Honest about limitations or missing information
4. Professional and informative

Always cite your sources when making specific claims. If the context doesn't contain enough information to fully answer the question, acknowledge this and provide what information is available.
```

Create `prompts/user_template.txt`:

```
Context:
$context

Question: $query

Instructions: $instructions

Please provide a comprehensive answer based on the context above. If the context doesn't fully address the question, acknowledge what information is missing.
```

### Step 13: FastAPI Application

Create `app.py`:

```python
from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import Optional, Dict, Any
import logging

from config import RAGSettings
from rag_system import RAGSystem

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize RAG system
settings = RAGSettings()
rag_system = RAGSystem(settings)

app = FastAPI(
    title="Enterprise RAG API",
    description="Production-ready Retrieval-Augmented Generation system",
    version="1.0.0"
)

class QueryRequest(BaseModel):
    query: str
    mode: Optional[str] = "balanced"  # concise, balanced, detailed
    stream: Optional[bool] = False
    include_sources: Optional[bool] = True
    filters: Optional[Dict[str, Any]] = {}

class QueryResponse(BaseModel):
    response: str
    sources: list
    confidence: float
    metadata: Dict[str, Any]

@app.on_event("startup")
async def startup():
    """Initialize services on startup."""
    await rag_system.initialize()
    logger.info("RAG system initialized")

@app.post("/query", response_model=QueryResponse)
async def query_rag(request: QueryRequest):
    """Query the RAG system."""
    try:
        result = await rag_system.query(
            query=request.query,
            mode=request.mode,
            filters=request.filters,
            include_sources=request.include_sources
        )
        
        return QueryResponse(**result)
        
    except Exception as e:
        logger.error(f"Query error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/query/stream")
async def query_rag_stream(request: QueryRequest):
    """Stream RAG response."""
    async def generate():
        async for chunk in rag_system.query_stream(
            query=request.query,
            mode=request.mode,
            filters=request.filters
        ):
            yield chunk
    
    return StreamingResponse(generate(), media_type="text/plain")

@app.get("/health")
async def health_check():
    """Check system health."""
    return await rag_system.health_check()

@app.post("/feedback")
async def submit_feedback(
    query_id: str,
    rating: int,
    comment: Optional[str] = None
):
    """Submit feedback for a query."""
    await rag_system.record_feedback(query_id, rating, comment)
    return {{"status": "feedback recorded"}}
```

### Step 14: Testing the Completar System

Create `tests/test_rag.py`:

**🤖 Copilot Prompt Suggestion #9:**
```python
# Create end-to-end tests for RAG system:
# - Test document indexing pipeline
# - Test query processing accuracy
# - Test response generation quality
# - Test citation accuracy
# - Test conversation continuity
# - Test error handling and fallbacks
# - Measure performance metrics
# Include test data and expected outputs
```

## 📊 Completar System Testing

### Run the RAG System

```bash
# Start the API
uvicorn app:app --reload --port 8000

# Test query
curl -X POST "http://localhost:8000/query" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What are the best practices for AI model deployment?",
    "mode": "detailed",
    "include_sources": true
  }'

# Test streaming
curl -X POST "http://localhost:8000/query/stream" \
  -H "Content-Type: application/json" \
  -d '{"query": "Explain feature engineering techniques", "stream": true}'
```

### Evaluation Script

Create `evaluate_rag.py`:

```python
import asyncio
from rag_system import RAGSystem
from evaluation import RAGEvaluator

async def evaluate():
    # Test questions
    test_queries = [
        "What is feature engineering in AI?",
        "How do you monitor model performance?",
        "What are the deployment considerations for AI models?",
        "Explain the importance of data quality in AI."
    ]
    
    rag_system = RAGSystem()
    evaluator = RAGEvaluator()
    
    results = []
    for query in test_queries:
        response = await rag_system.query(query)
        
        # Evaluate response
        eval_result = await evaluator.evaluate(
            query=query,
            response=response['response'],
            context=response['sources']
        )
        
        results.append({
            "query": query,
            "relevance_score": eval_result['relevance'],
            "coherence_score": eval_result['coherence'],
            "factuality_score": eval_result['factuality']
        })
    
    # Print results
    for result in results:
        print(f"\nQuery: {result['query']}")
        print(f"Relevance: {result['relevance_score']:.2f}")
        print(f"Coherence: {result['coherence_score']:.2f}")
        print(f"Factuality: {result['factuality_score']:.2f}")

asyncio.run(evaluate())
```

## ✅ Ejercicio 2 Success Criteria

Your RAG system is complete when:

1. **Indexing**: Documents processed and indexed successfully
2. **Retrieval**: Relevant chunks retrieved for queries
3. **Generation**: Coherent responses with citations
4. **Performance**: Response time &lt; 2 seconds
5. **Accuracy**: Relevance score &gt; 0.8
6. **Robustness**: Handles edge cases gracefully

## 🏆 Extension Challenges

1. **Multi-language Support**: Add support for non-English documents
2. **Hybrid Buscar**: Combine vector and keyword search
3. **Query Understanding**: Implement intent classification
4. **Adaptive Chunking**: Adjust chunk size based on content

## 💡 Key Takeaways

- RAG combines retrieval and generation strengths
- Context quality determines response quality
- Prompt engineering is crucial for RAG
- Evaluation helps improve the system
- Production RAG needs robust error handling

## 📚 Additional Recursos

- [LangChain RAG Tutorial](https://python.langchain.com/docs/use_cases/question_answering/)
- [AbrirAI RAG Mejores Prácticas](https://platform.openai.com/docs/guides/rag)
- [Evaluation Metrics for RAG](https://arxiv.org/abs/2309.01431)

## Próximos Pasos

Congratulations on building a producción-ready RAG system! Continuar to Ejercicio 3 where you'll create a multi-model orchestration platform.

[Continuar to Ejercicio 3 →](../exercise3-mastery/instructions.md)