# Exercise 1: Semantic Search - Complete Solution
# search.py - Search engine implementation

import asyncio
from typing import List, Dict, Any, Optional, Tuple
import numpy as np
from datetime import datetime
import logging
import json

from embeddings import EmbeddingService
from vector_store import VectorStore
from config import Settings

logger = logging.getLogger(__name__)

class SearchEngine:
    """
    Advanced semantic search engine with multiple strategies.
    """
    
    def __init__(
        self,
        embedding_service: EmbeddingService,
        vector_store: VectorStore,
        settings: Settings
    ):
        self.embedding_service = embedding_service
        self.vector_store = vector_store
        self.settings = settings
        self.search_cache = {}
        
    async def search(
        self,
        query: str,
        top_k: int = 10,
        filters: Optional[Dict[str, Any]] = None,
        search_mode: str = "semantic"  # semantic, keyword, hybrid
    ) -> List[Dict[str, Any]]:
        """
        Perform search with specified mode.
        
        Args:
            query: Search query
            top_k: Number of results to return
            filters: Metadata filters
            search_mode: Search mode to use
            
        Returns:
            List of search results with scores
        """
        # Check cache
        cache_key = self._get_cache_key(query, filters, search_mode)
        if cache_key in self.search_cache:
            logger.info(f"Cache hit for query: {query[:50]}...")
            return self.search_cache[cache_key]
        
        # Perform search based on mode
        if search_mode == "semantic":
            results = await self._semantic_search(query, top_k, filters)
        elif search_mode == "keyword":
            results = await self._keyword_search(query, top_k, filters)
        elif search_mode == "hybrid":
            results = await self._hybrid_search(query, top_k, filters)
        else:
            raise ValueError(f"Unknown search mode: {search_mode}")
        
        # Cache results
        self.search_cache[cache_key] = results
        
        return results
    
    async def _semantic_search(
        self,
        query: str,
        top_k: int,
        filters: Optional[Dict[str, Any]] = None
    ) -> List[Dict[str, Any]]:
        """
        Perform semantic search using embeddings.
        """
        # Generate query embedding
        start_time = datetime.utcnow()
        query_embedding = await self.embedding_service.generate_embedding(
            query,
            model=self.settings.embedding_model
        )
        embedding_time = (datetime.utcnow() - start_time).total_seconds()
        
        # Search vector store
        search_start = datetime.utcnow()
        results = await self.vector_store.search(
            vector=query_embedding,
            top_k=top_k,
            filters=filters
        )
        search_time = (datetime.utcnow() - search_start).total_seconds()
        
        # Enhance results with explanations
        enhanced_results = []
        for result in results:
            enhanced_result = {
                **result,
                "search_mode": "semantic",
                "explanation": self._generate_explanation(query, result),
                "metadata": {
                    **result.get("metadata", {}),
                    "embedding_time_ms": int(embedding_time * 1000),
                    "search_time_ms": int(search_time * 1000)
                }
            }
            enhanced_results.append(enhanced_result)
        
        logger.info(
            f"Semantic search completed in {(embedding_time + search_time)*1000:.2f}ms"
        )
        
        return enhanced_results
    
    async def _keyword_search(
        self,
        query: str,
        top_k: int,
        filters: Optional[Dict[str, Any]] = None
    ) -> List[Dict[str, Any]]:
        """
        Perform keyword-based search.
        """
        # Extract keywords from query
        keywords = self._extract_keywords(query)
        
        # Search using keywords
        results = await self.vector_store.keyword_search(
            keywords=keywords,
            top_k=top_k,
            filters=filters
        )
        
        # Add search mode metadata
        for result in results:
            result["search_mode"] = "keyword"
            result["keywords_matched"] = keywords
        
        return results
    
    async def _hybrid_search(
        self,
        query: str,
        top_k: int,
        filters: Optional[Dict[str, Any]] = None
    ) -> List[Dict[str, Any]]:
        """
        Perform hybrid search combining semantic and keyword approaches.
        """
        # Run both searches in parallel
        semantic_task = asyncio.create_task(
            self._semantic_search(query, top_k * 2, filters)
        )
        keyword_task = asyncio.create_task(
            self._keyword_search(query, top_k * 2, filters)
        )
        
        semantic_results, keyword_results = await asyncio.gather(
            semantic_task,
            keyword_task
        )
        
        # Combine and re-rank results
        combined_results = self._combine_results(
            semantic_results,
            keyword_results,
            semantic_weight=0.7,
            keyword_weight=0.3
        )
        
        # Return top-k after re-ranking
        return combined_results[:top_k]
    
    def _combine_results(
        self,
        semantic_results: List[Dict[str, Any]],
        keyword_results: List[Dict[str, Any]],
        semantic_weight: float = 0.7,
        keyword_weight: float = 0.3
    ) -> List[Dict[str, Any]]:
        """
        Combine and re-rank results from different search methods.
        """
        # Create result lookup by ID
        result_scores = {}
        result_data = {}
        
        # Process semantic results
        for rank, result in enumerate(semantic_results):
            result_id = result.get("id", result.get("content", "")[:50])
            score = result["score"] * semantic_weight
            
            if result_id in result_scores:
                result_scores[result_id] += score
            else:
                result_scores[result_id] = score
                result_data[result_id] = result
        
        # Process keyword results
        for rank, result in enumerate(keyword_results):
            result_id = result.get("id", result.get("content", "")[:50])
            # Use reciprocal rank for keyword results
            score = (1 / (rank + 1)) * keyword_weight
            
            if result_id in result_scores:
                result_scores[result_id] += score
            else:
                result_scores[result_id] = score
                result_data[result_id] = result
        
        # Sort by combined score
        sorted_ids = sorted(
            result_scores.keys(),
            key=lambda x: result_scores[x],
            reverse=True
        )
        
        # Create final results
        combined_results = []
        for result_id in sorted_ids:
            result = result_data[result_id].copy()
            result["combined_score"] = result_scores[result_id]
            result["search_mode"] = "hybrid"
            combined_results.append(result)
        
        return combined_results
    
    def _extract_keywords(self, query: str) -> List[str]:
        """
        Extract keywords from query for keyword search.
        """
        # Simple keyword extraction (can be enhanced with NLP)
        # Remove common stop words
        stop_words = {
            "the", "is", "at", "which", "on", "a", "an", "and", "or",
            "but", "in", "with", "to", "for", "of", "as", "by", "that",
            "this", "it", "from", "be", "are", "was", "were", "been"
        }
        
        # Tokenize and filter
        words = query.lower().split()
        keywords = [
            word.strip(".,!?;:")
            for word in words
            if word.lower() not in stop_words and len(word) > 2
        ]
        
        return keywords
    
    def _generate_explanation(
        self,
        query: str,
        result: Dict[str, Any]
    ) -> str:
        """
        Generate explanation for why result matches query.
        """
        score = result.get("score", 0)
        
        if score > 0.9:
            return "Very high relevance - strong semantic match"
        elif score > 0.8:
            return "High relevance - good semantic similarity"
        elif score > 0.7:
            return "Moderate relevance - partial semantic match"
        else:
            return "Low relevance - weak semantic connection"
    
    def _get_cache_key(
        self,
        query: str,
        filters: Optional[Dict] = None,
        search_mode: str = "semantic"
    ) -> str:
        """
        Generate cache key for search results.
        """
        import hashlib
        
        key_parts = [query, search_mode]
        if filters:
            key_parts.append(json.dumps(sorted(filters.items())))
        
        key_string = "|".join(key_parts)
        return hashlib.sha256(key_string.encode()).hexdigest()
    
    async def get_similar_items(
        self,
        item_id: str,
        top_k: int = 5
    ) -> List[Dict[str, Any]]:
        """
        Find items similar to a given item.
        """
        # Get the item's embedding
        item = await self.vector_store.get_by_id(item_id)
        if not item or "vector" not in item:
            raise ValueError(f"Item {item_id} not found or has no embedding")
        
        # Search for similar items
        results = await self.vector_store.search(
            vector=item["vector"],
            top_k=top_k + 1,  # +1 to exclude the item itself
            filters={"id": {"$ne": item_id}}  # Exclude self
        )
        
        return results[:top_k]
    
    async def get_search_analytics(self) -> Dict[str, Any]:
        """
        Get search analytics and performance metrics.
        """
        # Calculate cache hit rate
        cache_entries = len(self.search_cache)
        
        # Get vector store statistics
        store_stats = await self.vector_store.get_statistics()
        
        return {
            "cache_entries": cache_entries,
            "cache_size_mb": self._estimate_cache_size() / (1024 * 1024),
            "vector_store_stats": store_stats,
            "search_modes_available": ["semantic", "keyword", "hybrid"]
        }
    
    def _estimate_cache_size(self) -> int:
        """
        Estimate cache size in bytes.
        """
        import sys
        total_size = 0
        
        for key, value in self.search_cache.items():
            total_size += sys.getsizeof(key)
            total_size += sys.getsizeof(json.dumps(value))
        
        return total_size