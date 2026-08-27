# KAAND Backend API Reference

**Production base URL:** `https://kaand-cyan.vercel.app/api`

All current endpoints are `GET` endpoints and return JSON. No authentication is required by the current implementation.

> Important: this API reads live RSS feeds (and, for Discover/Home, Firestore first when configured). The deployed `/article` endpoint uses the Next.js HTML extractor. It does **not** invoke the Python Scrapy crawler automatically.

## Response conventions

Most endpoints return this envelope:

```json
{
  "success": true,
  "message": "Optional human-readable message",
  "data": {},
  "timestamp": "2026-08-20T12:00:00.000Z"
}
```

Article-list endpoints normally use one of these pagination shapes:

```json
{
  "page": 1,
  "limit": 20,
  "total": 120,
  "hasMore": true
}
```

```json
{
  "page": 1,
  "limit": 20,
  "hasNext": true,
  "nextPage": 2
}
```

An article has this normalized shape (some optional fields may be absent):

```json
{
  "title": "Headline",
  "description": "Short RSS or extracted description",
  "summary": "Optional summary",
  "image": "https://...",
  "url": "https://publisher.example/article",
  "canonical_url": "https://...",
  "author": "Author name",
  "publishedAt": "2026-08-20T10:00:00.000Z",
  "source": "BBC",
  "content": "Full article text when extracted",
  "category": "world",
  "readTime": 3,
  "language": "en",
  "tags": ["news"],
  "metadata": {}
}
```

## Data sources and caching

- Category RSS results are cached in the running API instance for **15 minutes**.
- Discover data reads the Firestore `articles` collection first (up to 200 newest records). If unavailable or empty, it falls back to RSS. The merged Discover result is cached for **5 minutes**.
- Article extraction is cached for **24 hours**.
- The cache is in memory, so it is not a durable cross-instance cache on Vercel.
- Category feed IDs: `general`, `technology`, `business`, `sports`, `health`, `science`, `world`, `india`, `entertainment`. The `/news` endpoint also accepts `nation` as an alias for `india`.

## Health and catalog endpoints

| Endpoint | Query parameters | What it does |
|---|---|---|
| `GET /health` | None | Service health, runtime uptime, environment, version and in-memory cache statistics. |
| `GET /categories` | None | Lists configured RSS categories: `{ id, name, feedCount }`. |
| `GET /publishers` | None | Lists recognized publishers: `{ id, name }`. IDs are used by `/publisher/:id`. |

Examples:

```text
GET /health
GET /categories
GET /publishers
```

## Core news endpoints

| Endpoint | Query parameters | What it does |
|---|---|---|
| `GET /news` | `category` default `general`; `search`; `page` default `1`; `limit` default `20`, range `1-50` | Fetches one RSS category, optionally filters title/description/source, and returns `{ data: { articles, pagination } }`. |
| `GET /category/:id` | `page` default `1`; `limit` default `20` | Same category-style result, but validates `:id` against the configured category list. Unknown category returns `404`. |
| `GET /search` | **`q` required**; optional `category`; `page` default `1`; `limit` default `20`, range `1-50` | Searches title/description/source across every category, or one category, then de-duplicates by article URL. Missing `q` returns `400`. |
| `GET /trending` | `limit` default `20` | Combines `general`, `technology`, and `world`; de-duplicates by URL; sorts newest first; returns the first `limit` results. |
| `GET /publisher/:id` | `page` default `1`; `limit` default `20` | Validates publisher ID, loads all categories, filters by normalized source name, and de-duplicates by URL. Unknown publisher returns `404`. |
| `GET /guardian` | `section` default `world`; `q`; `page` default `1`; `limit` default `20`, range `1-50` | Proxies the Guardian Content API and normalizes its articles. Requires server-side `GUARDIAN_API_KEY`; otherwise returns `503`. |
| `GET /article` | **`url` required** | Extracts full article details from a public article URL. Rejects private/loopback URLs (`SSRF_BLOCKED`) and caches success for 24h. |

Examples:

```text
GET /news?category=technology&page=1&limit=20
GET /news?category=nation
GET /search?q=artificial%20intelligence&page=1&limit=20
GET /search?q=cricket&category=sports
GET /category/world?page=2&limit=20
GET /publisher/bbc?page=1&limit=20
GET /trending?limit=10
GET /guardian?section=world&q=climate&limit=10
GET /article?url=https%3A%2F%2Fwww.bbc.com%2Fnews%2Fexample
```

### Core endpoint result shapes

`/news`, `/search`, `/category/:id`, and `/publisher/:id`:

```json
{
  "success": true,
  "data": {
    "articles": [],
    "pagination": { "page": 1, "limit": 20, "total": 0, "hasMore": false }
  },
  "timestamp": "..."
}
```

`/trending`, `/guardian`, and `/article` return articles directly in `data` (`/article` returns one object, not an array).

## Home feed endpoints

Home routes build a presentation-ready homepage from the same globally deduplicated Discover dataset. On the first request they return fixed homepage sections. For infinite scrolling, use the cursor API.

| Endpoint | Query parameters | What it does |
|---|---|---|
| `GET /home` | `limit` default `10`; optional `cursor` | Without `cursor`, returns the complete homepage sections plus the first continuous feed page. With `cursor`, returns only the next feed page in `data`. |
| `GET /home/feed` | optional `cursor`; `limit` default `10` | Feed-only cursor pagination. Without a cursor it starts at index 15, avoiding the items already used in top sections. |
| `GET /home/hero` | None | One hero story: prefers secure-image, long-description articles from reputable publishers. |
| `GET /home/breaking` | None | Up to three articles selected by breaking-news keywords. |
| `GET /home/trending` | None | Five recent stories with a simple publisher-coverage count. |
| `GET /home/latest` | `page` default `1`; `limit` default `20` | Page-number-based list of newest deduplicated articles. |
| `GET /home/categories` | None | Highlights for Technology, Business, Sports and Science. |
| `GET /home/editors-highlights` | None | Up to eight items, preferring coverage across different categories. |

Initial home response:

```json
{
  "success": true,
  "sections": {
    "breaking": [],
    "hero": {},
    "highlights": [],
    "trending": [],
    "latest": [],
    "categories": [],
    "feed": []
  },
  "pagination": { "cursor": "25", "hasNext": true },
  "cache": { "cached": true, "expiresAt": "..." }
}
```

Infinite-scroll example:

```text
GET /home?limit=10
# Read pagination.cursor from the response, then:
GET /home/feed?cursor=25&limit=10
# Or equivalently:
GET /home?cursor=25&limit=10
```

Cursor responses contain:

```json
{
  "success": true,
  "data": [],
  "pagination": { "cursor": "35", "hasNext": true }
}
```

## Discover endpoints

Discover routes return Firestore/RSS-backed browsing data. Standard list routes share this shape:

```json
{
  "success": true,
  "data": [],
  "pagination": { "page": 1, "limit": 20, "hasNext": true, "nextPage": 2 },
  "metadata": { "lastUpdated": "...", "totalItems": 120 },
  "cache": { "cached": true, "expiresAt": "..." }
}
```

| Endpoint | Query parameters | What it does |
|---|---|---|
| `GET /discover` | `page` default `1`; `limit` default `20` | Globally sorted, de-duplicated article list. |
| `GET /discover/recent` | `page`; `limit` | Same current newest article list for the Recent surface. |
| `GET /discover/categories` | `page`; `limit` | Category cards with article count, last update and image. |
| `GET /discover/publishers` | `page`; `limit` | Publisher cards sorted by current article count. |
| `GET /discover/topics` | `page`; `limit` | Topic cards (Technology, Space, Cricket, Business, Politics, Science, Health, Entertainment, Startups), matched by keywords. |
| `GET /discover/trending` | `page`; `limit` | Topic cards scored by article volume, publisher breadth and recency. |
| `GET /discover/regions` | `page`; `limit` | Region cards (India, World, North America, Europe, Asia), matched from title/description keywords. |
| `GET /discover/editors-picks` | `page`; `limit` default `5` | Up to ten curated/fallback high-quality articles, then paginated. |
| `GET /discover/search` | `q` optional; `category`; `publisher`; `page`; `limit`; `suggestions=true` | Standard search matches title, description, source, category and tags. Suggestion mode returns matching topics/publishers/categories/titles instead of article results. |

Examples:

```text
GET /discover?page=1&limit=20
GET /discover/topics?limit=9
GET /discover/trending?limit=5
GET /discover/search?q=ISRO&category=science&page=1&limit=20
GET /discover/search?q=tech&suggestions=true
```

Suggestion-mode response:

```json
{
  "success": true,
  "data": {
    "topics": ["Technology"],
    "publishers": ["TechCrunch"],
    "categories": ["technology"],
    "titles": ["..."],
    "popular": ["#SensexRecord", "#ISRO", "#CricketChampionship", "#StartupsFunding"]
  }
}
```

## Error handling

| Status | Meaning |
|---:|---|
| `400` | Required input missing, invalid request, or `/article` SSRF protection blocked a private URL. |
| `404` | Unknown category or publisher ID. |
| `502` | Guardian upstream request failed. |
| `503` | Guardian API key is not configured. |
| `500` | Internal feed, extraction, aggregation, or server error. |

Client rule: check `success` before consuming `data`. Some Home/Discover failure responses omit the standard `message` and/or `timestamp`, so clients should treat them as optional.

## Backend implementation notes / next required work

1. **Protect public routes.** There is no auth, rate limiting, API-key validation, or distributed cache yet. Add these before opening a public mobile release.
2. **Validate all pagination.** `/news`, `/search`, and `/guardian` clamp pages and limits. Several Home/Discover/dynamic routes currently parse query values without bounds checks; normalize them consistently.
3. **Scraper integration is not automatic yet.** The Python Scrapy project should run as a scheduled Cloud Run Job to refresh Firestore. For article-on-open scraping, add a protected Cloud Run Service/queue worker and have `/article` enqueue it when the Firestore record is missing or stale.
4. **Use Firestore for durable data.** The live deployment can fall back to RSS, but that makes feed quality and latency dependent on external publishers. Configure Firebase Admin credentials/server identity and keep the scraper writing the `articles` collection.
5. **Do not expose server secrets.** `GUARDIAN_API_KEY`, Firebase credentials, task-queue secrets, and Cloud Run identity must remain in server-side environment variables or workload identity only.

