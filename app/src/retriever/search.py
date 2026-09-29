"""Azure AI Search retriever.

v0 runs hybrid search (vector plus keyword) against the corpus index with no
ACL filter, so any caller retrieves any document. Lab 05 adds per-user ACL
filtering and lab 08 tightens the vector scoring.
"""

from __future__ import annotations

import os

from azure.core.credentials import AzureKeyCredential
from azure.identity import DefaultAzureCredential
from azure.search.documents import SearchClient
from azure.search.documents.models import VectorizedQuery


def _client() -> SearchClient:
    endpoint = os.getenv("AZURE_SEARCH_ENDPOINT")
    index = os.getenv("AZURE_SEARCH_INDEX")
    if not endpoint or not index:
        raise RuntimeError(
            "AZURE_SEARCH_ENDPOINT and AZURE_SEARCH_INDEX must be set"
        )
    key = os.getenv("AZURE_SEARCH_KEY")
    credential = AzureKeyCredential(key) if key else DefaultAzureCredential()
    return SearchClient(endpoint=endpoint, index_name=index, credential=credential)


def _embed_query(query: str) -> list[float]:
    """Embed the query for vector search.

    v0 returns a placeholder zero vector so the scaffold runs without an
    embeddings deployment. Lab 02 replaces this with a real
    text-embedding-3-small call against Azure OpenAI.
    """
    # text-embedding-3-small outputs 1536 dimensions.
    return [0.0] * 1536


def retrieve(query: str, top: int = 5) -> list[dict]:
    """Run hybrid search and return the top chunks with their source names.

    v0 applies no ACL filter. The caller's scope is neither passed nor used,
    which is the insecure baseline.
    """
    client = _client()
    vector = VectorizedQuery(
        vector=_embed_query(query),
        k_nearest_neighbors=top,
        fields="content_vector",
    )
    results = client.search(search_text=query, vector_queries=[vector], top=top)

    chunks = []
    for result in results:
        chunks.append(
            {
                "content": result.get("content", ""),
                "source": result.get("source", ""),
                "score": result.get("@search.score", 0.0),
            }
        )
    return chunks
