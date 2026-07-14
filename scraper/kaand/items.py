import hashlib
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field, model_validator


class ArticleItem(BaseModel):
    id: Optional[str] = None
    title: str = Field(..., min_length=1)
    description: Optional[str] = ""
    url: str = Field(..., min_length=1)
    canonical_url: Optional[str] = ""
    source: Optional[str] = "News"
    author: Optional[str] = "Staff"
    published_at: Optional[str] = None
    category: Optional[str] = "general"
    language: Optional[str] = "en"
    hero_image: Optional[str] = ""
    content: Optional[str] = ""
    summary: Optional[str] = ""
    reading_time: Optional[int] = 1
    tags: Optional[List[str]] = Field(default_factory=list)
    metadata: Optional[Dict[str, Any]] = Field(default_factory=dict)

    @model_validator(mode='before')
    @classmethod
    def generate_fields(cls, data):
        if isinstance(data, dict):
            url = data.get('url', '')
            if url and not data.get('id'):
                data['id'] = hashlib.sha256(url.encode('utf-8')).hexdigest()

            # Use canonical_url for ID if available
            canonical = data.get('canonical_url', '')
            if canonical and canonical != url:
                data['id'] = hashlib.sha256(canonical.encode('utf-8')).hexdigest()

            content = data.get('content', '')
            if content and not data.get('reading_time'):
                words = len(content.split())
                data['reading_time'] = max(1, (words + 199) // 200)
        return data
