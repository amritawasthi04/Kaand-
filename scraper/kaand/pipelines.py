from scrapy.exceptions import DropItem
from kaand.items import ArticleItem

class DeduplicatePipeline:
  def __init__(self):
    self.urls_seen = set()

  def process_item(self, item, spider):
    url = item.get("url")
    if url in self.urls_seen:
      raise DropItem(f"Duplicate item found: {url}")
    self.urls_seen.add(url)
    return item

class ValidationPipeline:
  def process_item(self, item, spider):
    try:
      # Pydantic validation
      validated_item = ArticleItem(**item)
      return validated_item.model_dump()
    except Exception as e:
      raise DropItem(f"Item validation failed: {e}")
