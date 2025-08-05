import logging
import boto3
import ollama
from typing import Dict, Any, List, Optional
from django.conf import settings
from django.core.cache import cache

logger = logging.getLogger(__name__)


class BaseAIProvider:
    """Base class for AI providers."""
    
    def __init__(self, model_name: str = None, **kwargs):
        self.model_name = model_name
        self.kwargs = kwargs
    
    async def generate(self, prompt: str, **kwargs) -> str:
        """Generate text response."""
        raise NotImplementedError
    
    async def embed(self, text: str) -> List[float]:
        """Generate embeddings."""
        raise NotImplementedError
    
    async def search(self, query: str, candidates: List[Dict], **kwargs) -> List[Dict]:
        """Search candidates based on query."""
        raise NotImplementedError


class OllamaProvider(BaseAIProvider):
    """Ollama AI provider for local development."""
    
    def __init__(self, model_name: str = None, host: str = None):
        super().__init__(model_name or settings.OLLAMA_MODEL)
        self.host = host or settings.OLLAMA_HOST
        self.client = ollama.Client(host=self.host)
        
        # Check if model is available
        try:
            models = [model.name for model in self.client.list().models]
            if self.model_name not in models:
                logger.info(f"Pulling model {self.model_name}...")
                self.client.pull(self.model_name)
        except Exception as e:
            logger.error(f"Error initializing Ollama: {e}")
            raise
    
    async def generate(self, prompt: str, **kwargs) -> str:
        """Generate text response using Ollama."""
        try:
            response = self.client.generate(
                model=self.model_name,
                prompt=prompt,
                **kwargs
            )
            return response['response'].strip()
        except Exception as e:
            logger.error(f"Ollama generation error: {e}")
            raise
    
    async def embed(self, text: str) -> List[float]:
        """Generate embeddings using Ollama."""
        try:
            response = self.client.embed(
                model=self.model_name,
                prompt=text
            )
            return response['embedding']
        except Exception as e:
            logger.error(f"Ollama embedding error: {e}")
            raise
    
    async def search(self, query: str, candidates: List[Dict], **kwargs) -> List[Dict]:
        """Search candidates using Ollama."""
        try:
            # Generate query embedding
            query_embedding = await self.embed(query)
            
            # Calculate similarities
            results = []
            for candidate in candidates:
                if 'embedding' in candidate:
                    similarity = self._cosine_similarity(query_embedding, candidate['embedding'])
                    results.append({
                        **candidate,
                        'similarity_score': similarity
                    })
            
            # Sort by similarity
            results.sort(key=lambda x: x['similarity_score'], reverse=True)
            return results
        except Exception as e:
            logger.error(f"Ollama search error: {e}")
            raise
    
    def _cosine_similarity(self, vec1: List[float], vec2: List[float]) -> float:
        """Calculate cosine similarity between two vectors."""
        import numpy as np
        
        vec1 = np.array(vec1)
        vec2 = np.array(vec2)
        
        dot_product = np.dot(vec1, vec2)
        norm1 = np.linalg.norm(vec1)
        norm2 = np.linalg.norm(vec2)
        
        if norm1 == 0 or norm2 == 0:
            return 0.0
        
        return dot_product / (norm1 * norm2)


class BedrockProvider(BaseAIProvider):
    """AWS Bedrock provider for production."""
    
    def __init__(self, model_name: str = None, region: str = None):
        super().__init__(model_name or settings.AWS_BEDROCK_MODEL)
        self.region = region or settings.AWS_BEDROCK_REGION
        self.client = boto3.client(
            'bedrock-runtime',
            region_name=self.region,
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY
        )
    
    async def generate(self, prompt: str, **kwargs) -> str:
        """Generate text response using AWS Bedrock."""
        try:
            # Prepare request body based on model
            if 'claude' in self.model_name.lower():
                request_body = {
                    "anthropic_version": "bedrock-2023-05-31",
                    "max_tokens": kwargs.get('max_tokens', 4096),
                    "messages": [
                        {
                            "role": "user",
                            "content": prompt
                        }
                    ]
                }
            else:
                # Default to generic format
                request_body = {
                    "prompt": prompt,
                    "max_tokens": kwargs.get('max_tokens', 4096),
                    "temperature": kwargs.get('temperature', 0.7)
                }
            
            response = self.client.invoke_model(
                modelId=self.model_name,
                body=json.dumps(request_body)
            )
            
            response_body = json.loads(response['body'].read())
            
            # Extract response based on model
            if 'claude' in self.model_name.lower():
                return response_body['content'][0]['text'].strip()
            else:
                return response_body.get('completion', '').strip()
                
        except Exception as e:
            logger.error(f"Bedrock generation error: {e}")
            raise
    
    async def embed(self, text: str) -> List[float]:
        """Generate embeddings using AWS Bedrock."""
        try:
            # Use Titan embedding model
            embedding_model = "amazon.titan-embed-text-v1"
            
            request_body = {
                "inputText": text
            }
            
            response = self.client.invoke_model(
                modelId=embedding_model,
                body=json.dumps(request_body)
            )
            
            response_body = json.loads(response['body'].read())
            return response_body['embedding']
            
        except Exception as e:
            logger.error(f"Bedrock embedding error: {e}")
            raise
    
    async def search(self, query: str, candidates: List[Dict], **kwargs) -> List[Dict]:
        """Search candidates using AWS Bedrock."""
        try:
            # Generate query embedding
            query_embedding = await self.embed(query)
            
            # Calculate similarities
            results = []
            for candidate in candidates:
                if 'embedding' in candidate:
                    similarity = self._cosine_similarity(query_embedding, candidate['embedding'])
                    results.append({
                        **candidate,
                        'similarity_score': similarity
                    })
            
            # Sort by similarity
            results.sort(key=lambda x: x['similarity_score'], reverse=True)
            return results
        except Exception as e:
            logger.error(f"Bedrock search error: {e}")
            raise
    
    def _cosine_similarity(self, vec1: List[float], vec2: List[float]) -> float:
        """Calculate cosine similarity between two vectors."""
        import numpy as np
        
        vec1 = np.array(vec1)
        vec2 = np.array(vec2)
        
        dot_product = np.dot(vec1, vec2)
        norm1 = np.linalg.norm(vec1)
        norm2 = np.linalg.norm(vec2)
        
        if norm1 == 0 or norm2 == 0:
            return 0.0
        
        return dot_product / (norm1 * norm2)


class AIProviderFactory:
    """Factory for creating AI providers."""
    
    @staticmethod
    def get_provider(provider_type: str = None, **kwargs) -> BaseAIProvider:
        """Get AI provider based on type."""
        provider_type = provider_type or settings.AI_PROVIDER
        
        if provider_type == 'ollama':
            return OllamaProvider(**kwargs)
        elif provider_type == 'bedrock':
            return BedrockProvider(**kwargs)
        else:
            # Default to Ollama for development
            return OllamaProvider(**kwargs)


# Import json at the top level
import json 