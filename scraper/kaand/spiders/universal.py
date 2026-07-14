import base64
import json
import os
import re
import urllib.parse
import yaml
import scrapy
import requests
from readability import Document
from scrapy.selector import Selector
from bs4 import BeautifulSoup
from kaand.items import ArticleItem

# Specialized adapter selectors for popular publishers
PUBLISHER_ADAPTERS = {
    "techcrunch": {
        "content_selectors": [".article-content p", ".entry-content p", ".article__content-wrap p"],
        "author_selectors": [".article__author-name", ".author-name"]
    },
    "bbc": {
        "content_selectors": ["article p", ".story-body__inner p", ".story-body p"],
        "author_selectors": [".reporter-name", ".author-unit", ".byline__name"]
    },
    "theguardian": {
        "content_selectors": [".article-body-commercial-selector p", ".content__article-body p", "#maincontent p"],
        "author_selectors": ["address a[rel='author']", ".byline"]
    },
    "nytimes": {
        "content_selectors": ["section[name='articleBody'] p", ".StoryBodyCompanionColumn p", "article p"],
        "author_selectors": [".g-author", ".byline"]
    }
}

def clean_html_text(text: str) -> str:
    if not text:
        return ""
    text = re.sub(r'<(script|style|iframe|form|noscript)[^>]*>[\s\S]*?<\/\1>', '', text, flags=re.I)
    text = re.sub(r'<[^>]+>', ' ', text)
    entities = {
        "&amp;": "&", "&quot;": "\"", "&apos;": "'", "&lt;": "<", "&gt;": ">",
        "&nbsp;": " ", "&#8217;": "'", "&#8220;": "\"", "&#8221;": "\"",
        "&#8212;": "—", "&#8216;": "'", "&mdash;": "—", "&ndash;": "–",
        "&rsquo;": "'", "&lsquo;": "'", "&ldquo;": "\"", "&rdquo;": "\""
    }
    for ent, val in entities.items():
        text = text.replace(ent, val)
    text = re.sub(r'[ \t]+', ' ', text)
    lines = [line.strip() for line in text.splitlines()]
    return "\n\n".join([line for line in lines if line]).strip()

def validate_image_url(url: str) -> bool:
    if not url or not url.startswith("https://"):
        return False
    lower = url.toLowerCase() if hasattr(url, 'toLowerCase') else url.lower()
    exclusions = ["favicon", "logo", "sprite", "placeholder", "avatar", "tracker", "pixel", "icon", "ad-", "ads-"]
    if any(ex in lower for ex in exclusions):
        return False
    try:
        res = requests.head(url, timeout=2)
        if res.status_code == 200:
            content_type = res.headers.get("content-type", "")
            if content_type.startswith("image/"):
                content_length = int(res.headers.get("content-length", 0))
                if content_length > 1000:
                    return True
    except Exception:
        try:
            res = requests.get(url, timeout=2, stream=True)
            if res.status_code == 200:
                content_type = res.headers.get("content-type", "")
                if content_type.startswith("image/"):
                    return True
        except Exception:
            pass
    return False

class UniversalSpider(scrapy.Spider):
    name = "universal"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        config_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "config.yaml")
        with open(config_path, "r", encoding="utf-8") as f:
            self.config = yaml.safe_load(f)

        self.start_urls = []
        self.feed_to_category = {}

        categories = self.config.get("categories", {})
        for category, feeds in categories.items():
            for feed_url in feeds:
                self.start_urls.append(feed_url)
                self.feed_to_category[feed_url] = category

    def parse(self, response):
        category = self.feed_to_category.get(response.url, "general")
        self.logger.info(f"Parsing RSS feed: {response.url} for category: {category}")

        selector = Selector(response, type="xml")
        items = selector.xpath("//item")

        for item in items:
            raw_title = item.xpath("title/text()").get() or "No Title"
            link = item.xpath("link/text()").get() or ""
            if not link:
                continue

            link = link.strip()

            image = item.xpath("enclosure/@url").get()
            if not image:
                image = item.xpath("*[local-name()='content']/@url").get()

            published_at = item.xpath("pubDate/text()").get()

            title = raw_title
            source = "News"
            hyphen_index = raw_title.rfind(" - ")
            if hyphen_index != -1:
                title = raw_title[:hyphen_index].strip()
                source = raw_title[hyphen_index + 3:].strip()

            resolved_link = self.resolve_google_news_url(link)

            yield scrapy.Request(
                url=resolved_link,
                callback=self.parse_article,
                errback=self.handle_error,
                cb_kwargs={
                    "category": category,
                    "title": title,
                    "source": source,
                    "published_at": published_at,
                    "fallback_image": image or ""
                }
            )

    def parse_article(self, response, category, title, source, published_at, fallback_image):
        html = response.text
        soup = BeautifulSoup(html, "html.parser")

        for tag in soup(["script", "style", "nav", "footer", "form", "iframe", "aside", "header"]):
            tag.decompose()

        def get_meta(properties):
            for prop in properties:
                meta = soup.find("meta", {"property": prop}) or \
                       soup.find("meta", {"name": prop}) or \
                       soup.find("meta", {"itemprop": prop})
                if meta and meta.get("content"):
                    return meta.get("content").strip()
            return ""

        meta_title = clean_html_text(get_meta(["og:title", "twitter:title"]))
        description = clean_html_text(get_meta(["og:description", "description", "twitter:description"]))

        # --- Gather Image Candidates ---
        candidates = []

        # P1: og:image
        opengraph_image = get_meta(["og:image"])
        if opengraph_image:
            candidates.append(opengraph_image)

        # P2: twitter:image
        twitter_image = get_meta(["twitter:image"])
        if twitter_image:
            candidates.append(twitter_image)

        # P3: JSON-LD image
        for script in soup.find_all("script", type="application/ld+json"):
            try:
                data = json.loads(script.get_text() or "")
                items = data if isinstance(data, list) else [data]
                for item in items:
                    if item.get("@type") in ("NewsArticle", "Article"):
                        img = item.get("image")
                        if isinstance(img, str):
                            candidates.append(img)
                        elif isinstance(img, dict) and img.get("url"):
                            candidates.append(img.get("url"))
            except Exception:
                pass

        # P4: link[rel="image_src"]
        link_img = soup.find("link", rel="image_src")
        if link_img and link_img.get("href"):
            candidates.append(link_img.get("href"))

        # P5: Fallback RSS
        if fallback_image:
            candidates.append(fallback_image)

        # P6: Body images
        main_img = soup.find("main") or soup.find("article") or soup
        for img in main_img.find_all("img"):
            src = img.get("src") or img.get("data-src")
            if src:
                candidates.append(src)

        # Resolve relative candidate paths
        resolved_candidates = []
        for c in candidates:
            try:
                resolved_candidates.append(urllib.parse.urljoin(response.url, c))
            except Exception:
                pass

        # Validate and select top candidate
        hero_image = ""
        extraction_method = "Default Fallback"
        for candidate in resolved_candidates:
            if validate_image_url(candidate):
                hero_image = candidate
                if candidate == opengraph_image:
                    extraction_method = "og:image (P1)"
                elif candidate == twitter_image:
                    extraction_method = "twitter:image (P2)"
                elif fallback_image and candidate == fallback_image:
                    extraction_method = "RSS Enclosure (P5)"
                else:
                    extraction_method = "Article Body (P6)"
                break

        if not hero_image:
            hero_image = "https://images.unsplash.com/photo-1504711434969-e33886168f5c?auto=format&fit=crop&w=1200&q=80"
            extraction_method = "Default Fallback Placeholder"

        # Author and Date
        author = get_meta(["og:author", "author", "article:author", "twitter:creator"])
        date = get_meta(["article:published_time", "pubdate", "datePublished"]) or published_at

        tags_raw = get_meta(["keywords", "news_keywords", "article:tag"])
        tags = [clean_html_text(t) for t in tags_raw.split(",") if t.strip()] if tags_raw else []

        canonical_url = get_meta(["og:url"]) or response.css('link[rel="canonical"]::attr(href)').get() or response.url
        language = (soup.find("html").get("lang") if soup.find("html") else "en") or "en"
        language = language.split("-")[0].lower()

        # Try publisher adapters
        content = ""
        domain = urllib.parse.urlparse(response.url).hostname.toLowerCase()
        matched_adapter = next((k for k in PUBLISHER_ADAPTERS if k in domain), None)

        if matched_adapter:
            adapter = PUBLISHER_ADAPTERS[matched_adapter]
            if not author and "author_selectors" in adapter:
                for sel in adapter["author_selectors"]:
                    found = soup.select_one(sel)
                    if found:
                        author = found.get_text().strip()
                        break
            if "content_selectors" in adapter:
                paras = []
                for sel in adapter["content_selectors"]:
                    for p in soup.select(sel):
                        p_text = clean_html_text(p.get_text())
                        if len(p_text) > 20:
                            paras.append(p_text)
                if paras:
                    content = "\n\n".join(paras)

        # Fallback to Readability
        if not content:
            try:
                doc = Document(html)
                clean_title = doc.title() or title
                summary_html = doc.summary()
                sub_soup = BeautifulSoup(summary_html, "html.parser")
                content = clean_html_text(sub_soup.get_text())
            except Exception as e:
                self.logger.warning(f"Readability extraction failed for {response.url}: {e}")
                paras = [clean_html_text(p.get_text()) for p in soup.find_all("p")]
                content = "\n\n".join([p for p in paras if len(p) > 20])

        final_content = content or description or "No content extracted."

        yield ArticleItem(
            title=meta_title or title,
            description=description,
            url=response.url,
            canonical_url=canonical_url,
            source=source,
            author=author or "Staff",
            published_at=date,
            category=category,
            language=language,
            hero_image=hero_image,
            content=final_content,
            summary=description,
            tags=tags,
            metadata={
                "og": {"og:image": opengraph_image} if opengraph_image else {},
                "twitter": {"twitter:image": twitter_image} if twitter_image else {},
                "schema": {"extraction_method": extraction_method}
            }
        ).model_dump()

    def handle_error(self, failure):
        self.logger.error(f"Error scraping page: {failure.value}")

    def resolve_google_news_url(self, link: str) -> str:
        if "news.google.com/rss/articles/" not in link:
            return link

        try:
            parsed = urllib.parse.urlparse(link)
            segments = [s for s in parsed.path.split("/") if s]
            if len(segments) < 3:
                return link

            b64 = segments[2]

            normalized = b64.replace("-", "+").replace("_", "/")
            while len(normalized) % 4 != 0:
                normalized += "="

            decoded = base64.b64decode(normalized).decode("utf-8", errors="ignore")

            match = re.search(r"https?://[^\s\x00-\x1F\x7F-\x9F\u00A0-\uFFFF]+", decoded)
            if match:
                url_str = match.group(0)
                while len(url_str) > 0 and ord(url_str[-1]) > 126:
                    url_str = url_str[:-1]
                return url_str
        except Exception as e:
            self.logger.warning(f"Failed decoding base64 Google News redirect: {e}")

        return link
