"""Tests for KAAND scraper components."""
import pytest
from kaand.items import ArticleItem
from kaand.pipelines import DeduplicatePipeline, ValidationPipeline


# --- ArticleItem Tests ---

def test_article_item_generates_id():
    item = ArticleItem(title="Test", url="https://example.com/article-1")
    assert item.id is not None
    assert len(item.id) == 64  # SHA256 hex digest

def test_article_item_deterministic_id():
    a = ArticleItem(title="A", url="https://example.com/same")
    b = ArticleItem(title="B", url="https://example.com/same")
    assert a.id == b.id

def test_article_item_canonical_url_changes_id():
    a = ArticleItem(title="A", url="https://example.com/redirected", canonical_url="https://example.com/canonical")
    b = ArticleItem(title="B", url="https://example.com/canonical")
    assert a.id == b.id  # canonical wins

def test_article_item_reading_time():
    content = " ".join(["word"] * 600)
    item = ArticleItem(title="Test", url="https://example.com/x", content=content)
    assert item.reading_time == 3  # 600 words / 200 wpm

def test_article_item_validation_fails_empty_title():
    with pytest.raises(Exception):
        ArticleItem(title="", url="https://example.com")

def test_article_item_validation_fails_empty_url():
    with pytest.raises(Exception):
        ArticleItem(title="Test", url="")

def test_article_item_metadata_field():
    item = ArticleItem(title="T", url="https://x.com", metadata={"og": {"og:title": "T"}})
    assert item.metadata["og"]["og:title"] == "T"


# --- Pipeline Tests ---

class FakeSpider:
    pass

def test_dedup_pipeline_passes_first():
    pipe = DeduplicatePipeline()
    result = pipe.process_item({"url": "https://a.com/1", "title": "A"}, FakeSpider())
    assert result["url"] == "https://a.com/1"

def test_dedup_pipeline_drops_duplicate():
    from scrapy.exceptions import DropItem
    pipe = DeduplicatePipeline()
    pipe.process_item({"url": "https://a.com/1", "title": "A"}, FakeSpider())
    with pytest.raises(DropItem):
        pipe.process_item({"url": "https://a.com/1", "title": "A again"}, FakeSpider())

def test_validation_pipeline_passes_valid():
    pipe = ValidationPipeline()
    result = pipe.process_item({"title": "Valid", "url": "https://x.com"}, FakeSpider())
    assert result["title"] == "Valid"
    assert "id" in result

def test_validation_pipeline_drops_invalid():
    from scrapy.exceptions import DropItem
    pipe = ValidationPipeline()
    with pytest.raises(DropItem):
        pipe.process_item({"title": "", "url": ""}, FakeSpider())


# --- Google News URL Resolver ---

def test_google_news_resolver_passthrough():
    from kaand.spiders.universal import UniversalSpider
    spider = UniversalSpider.__new__(UniversalSpider)
    assert spider.resolve_google_news_url("https://example.com/article") == "https://example.com/article"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
