# KAAND Backend

Global news aggregation platform backend powering the Newstler Flutter app.

## Architecture

```
Flutter App → REST API (Next.js on Vercel) → RSS Feeds / Article Extraction
                                            ↕
                              Scrapy Crawler → Firestore Cache
```

## API Reference

All endpoints return `{ success, message, data, timestamp }`. Paginated endpoints include `data.pagination`.

| Endpoint | Method | Description |
|---|---|---|
| `/api/health` | GET | Service health, uptime, cache stats |
| `/api/news` | GET | News by category. Params: `category`, `search`, `page`, `limit` |
| `/api/article` | GET | Extract full article details. Params: `url` |
| `/api/search` | GET | Cross-category search. Params: `q` (required), `category`, `page`, `limit` |
| `/api/categories` | GET | List all available categories |
| `/api/category/:id` | GET | Articles for a specific category. Params: `page`, `limit` |
| `/api/publishers` | GET | List all recognized publishers |
| `/api/publisher/:id` | GET | Articles from a specific publisher. Params: `page`, `limit` |
| `/api/trending` | GET | Trending articles (general + tech + world). Params: `limit` |
| `/api/guardian` | GET | Guardian API proxy. Params: `section`, `q`, `page`, `limit` |

## Folder Structure

```
backend/
├── app/api/           # Next.js App Router API routes
│   ├── article/       # Article extraction endpoint
│   ├── categories/    # Category listing
│   ├── category/[id]/ # Category detail
│   ├── guardian/      # Guardian API proxy
│   ├── health/        # Health check
│   ├── news/          # News feed endpoint
│   ├── publisher/[id]/# Publisher detail
│   ├── publishers/    # Publisher listing
│   ├── search/        # Cross-category search
│   └── trending/      # Trending articles
├── lib/
│   ├── cache.ts       # In-memory TTL cache (node-cache)
│   ├── extractor.ts   # JSDOM + Readability article extraction
│   ├── feeds.ts       # RSS feed URLs, source mapping, publisher list
│   ├── rss.ts         # RSS parser, Google News URL resolver, deduplication
│   ├── ssrf.ts        # SSRF protection for article fetching
│   └── types.ts       # TypeScript interfaces (Article, ApiResponse)
├── package.json
├── tsconfig.json
└── vercel.json
```

## Running Locally

```bash
cd backend
npm install
npm run dev
# Server starts at http://localhost:3000
```

## Deployment (Vercel)

```bash
cd backend
npx vercel --prod
```

## Adding a New Publisher

1. Add the RSS feed URL to the appropriate category in `lib/feeds.ts`
2. Add a `[substring, DisplayName]` entry to `SOURCE_MAP` in `lib/feeds.ts`
3. Mirror the feed in `scraper/kaand/config.yaml`
4. Run `npm run dev` and verify with `/api/news?category=<cat>`

## Cache

- **Feed cache**: 15-minute TTL (in-memory via `node-cache`)
- **Article cache**: 24-hour TTL
- Cache stats visible at `/api/health`

## Environment Variables

See `.env.example` for all available configuration.

## Testing

```bash
# Backend API tests
dart test/validate_backend.dart

# Scraper unit tests
cd scraper && python -m pytest tests/ -v

# Flutter
flutter analyze
flutter test
```
