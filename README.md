# KAAND Backend API (Next.js + Vercel + Firestore Cache)

A production-ready serverless backend for **KAAND**, an AI-powered news aggregation platform. It consolidates news from multiple RSS feeds, deduplicates titles using a Jaccard-like index, crawls full pages using Mozilla Readability & Cheerio, and integrates with the Google Gemini Flash API to generate AI bullet points and summaries.

---

## 1. Project Overview & Architecture

### Technology Stack
- **Framework**: Next.js 14 (App Router)
- **Language**: TypeScript
- **Hosting**: Vercel Serverless
- **Database / Cache**: Firebase Firestore (Admin SDK)
- **Scraper / Parsers**: Cheerio, Mozilla Readability, JSDOM, RSS-Parser
- **AI Engine**: Google Gemini 1.5 Flash API (`@google/generative-ai`)
- **Validation**: Zod Schemas

### Architecture Flow
```
  [Flutter Client]
         │
         ▼
  [Vercel Serverless API]
         │
         ├─── (Read/Write) ───► [Firestore DB Cache] (feed_cache, article_cache, guardian_cache)
         │
         ├─── (Category Aggregation) ───► [RSS Feeds] (BBC, TechCrunch, ESPN, etc.)
         │
         ├─── (On-Demand Scrape) ───► [Cheerio / Mozilla Readability crawler]
         │
         └─── (AI summaries) ───► [Google Gemini 1.5 Flash API]
```

---

## 2. Directory Layout

```text
newstler/
├── app/
│   └── api/
│       ├── health/
│       │   └── route.ts        # Health check route
│       ├── news/
│       │   └── route.ts        # News categories feed with search & pagination
│       ├── article/
│       │   └── route.ts        # Scraper and Gemini AI summarizer route
│       └── guardian/
│           └── route.ts        # The Guardian proxy client route
├── lib/
│   ├── ai/
│   │   └── gemini.ts           # Gemini Flash summary model pipeline
│   ├── constants/
│   │   └── index.ts            # RSS source maps, cache timings (TTLs)
│   ├── firebase/
│   │   ├── config.ts           # Firestore service account initialization
│   │   └── firestore.ts        # Read/Write caches for feed, article, and guardian collections
│   ├── models/
│   │   └── article.ts          # Unified Article typescript interface
│   ├── rss/
│   │   └── index.ts            # Parallel RSS parsing and title similarity deduplication
│   ├── scraper/
│   │   └── index.ts            # Cheerio tag extraction + Mozilla Readability engine
│   └── utils/
│       ├── cors.ts             # Shared CORS headers and preflight handling
│       ├── hash.ts             # MD5 crypto string hashing
│       └── response.ts         # Standard success and error JSON envelopes
├── package.json                # Dependencies and next.js scripts
├── tsconfig.json               # TypeScript configurations
├── vercel.json                 # Vercel function routing overrides
└── README.md                   # Complete developer guide (this file)
```

---

## 3. Environment Setup

Create a `.env` or `.env.local` file at the root.

```bash
# 1. Google Gemini Key
GEMINI_API_KEY=your_gemini_api_key_here

# 2. Firebase Admin SDK service account key configuration
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_CLIENT_EMAIL=your_firebase_client_email
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n"

# 3. Third-party proxy credentials (default fallback: 'test')
GUARDIAN_API_KEY=your_guardian_developer_api_key
```

---

## 4. Firestore Cache Schema

Firestore database operates as a distributed key-value cache with Time-To-Live (TTL) timestamps checked by routes before returning results.

### Collection: `feed_cache`
- **Document ID**: `<category>` (e.g., `technology`, `business`, `sports`, `health`, `science`, `world`, `india`, `entertainment`).
- **TTL**: 15 Minutes.
- **Document Structure**:
  ```json
  {
    "updatedAt": "2026-06-30T00:00:00.000Z",
    "expiresAt": "2026-06-30T00:15:00.000Z",
    "articles": [ ... ] // Array of Unified Article Objects
  }
  ```

### Collection: `article_cache`
- **Document ID**: `md5(url)` (Cryptographic MD5 hash of target URL).
- **TTL**: 24 Hours.
- **Document Structure**:
  ```json
  {
    "id": "md5_url_hash",
    "title": "Article Title",
    "description": "Short metadata paragraph summary...",
    "summary": "AI Generated Overview\n\nKey Highlights:\n• Point 1\n• Point 2...",
    "image": "https://source.com/cover.jpg",
    "url": "https://source.com/article",
    "author": "Author Name",
    "source": "source.com",
    "publishedAt": "2026-06-30T00:00:00.000Z",
    "category": "scraped",
    "content": "Full article main content extracted by Readability...",
    "readTime": 4, // Minutes computed via word counts
    "language": "en",
    "cachedAt": "2026-06-30T00:00:00.000Z",
    "expiresAt": "2026-07-01T00:00:00.000Z"
  }
  ```

### Collection: `guardian_cache`
- **Document ID**: `section_<section_name>` or `search_<section_name>_<md5(q)>`.
- **TTL**: 15 Minutes.
- **Document Structure**: Identical to `feed_cache`.

---

## 5. API Reference

All responses return in a standard JSON wrapper:
```json
{
  "success": true, // false if error
  "message": "Success",
  "code": "SUCCESS",
  "data": { ... } // Payload
}
```

### 1. `GET /api/health`
- **Description**: Inspect server health status.
- **Success Output**:
  ```json
  {
    "success": true,
    "message": "Success",
    "code": "SUCCESS",
    "data": {
      "status": "ok",
      "timestamp": "2026-06-30T00:00:00.000Z"
    }
  }
  ```

### 2. `GET /api/news`
- **Description**: Returns categorized and deduplicated headlines.
- **Query Params**:
  - `category` (optional, default: `general`)
  - `search` (optional keyword - pulls direct uncached search feed from Google News if active)
  - `page` (optional page index, default: `1`)
  - `limit` (optional page size, default: `20`, max: `50`)
- **Success Output**:
  ```json
  {
    "success": true,
    "message": "Success",
    "code": "SUCCESS",
    "data": {
      "articles": [
        {
          "id": "e9c1c5a968600cd9c841865a7e6bdf25",
          "title": "Tech Giant Releases New AI Tool",
          "description": "The tool aims to speed up software engineering tasks...",
          "summary": "",
          "image": "",
          "url": "https://techcrunch.com/xxxx",
          "author": "Staff writer",
          "source": "TechCrunch",
          "publishedAt": "2026-06-30T00:00:00.000Z",
          "category": "technology",
          "content": "",
          "readTime": 0,
          "language": "en"
        }
      ],
      "pagination": {
        "page": 1,
        "limit": 1,
        "total": 45,
        "totalPages": 45
      }
    }
  }
  ```

### 3. `GET /api/article`
- **Description**: Crawls and parses target page contents, and generates Gemini summary.
- **Query Params**:
  - `url` (Required, URL-encoded string)
- **Success Output**:
  ```json
  {
    "success": true,
    "message": "Success",
    "code": "SUCCESS",
    "data": {
      "id": "e9c1c5a968600cd9c841865a7e6bdf25",
      "title": "Tech Giant Releases New AI Tool",
      "description": "The tool aims to speed up software engineering tasks...",
      "summary": "Tech Giant has released an innovative AI tool to streamline programming.\n\nKey Highlights:\n• Speeds up debugging by 40%.\n• Supports Node.js and Python.\n• Fully integrated with VS Code.\n• Free tier available for small dev groups.\n• Enterprise rollouts start immediately.",
      "image": "https://techcrunch.com/cover.jpg",
      "url": "https://techcrunch.com/xxxx",
      "author": "John Doe",
      "source": "techcrunch.com",
      "publishedAt": "2026-06-30T00:00:00.000Z",
      "category": "scraped",
      "content": "Full parsed article body text...",
      "readTime": 3,
      "language": "en"
    }
  }
  ```

### 4. `GET /api/guardian`
- **Description**: Proxies queries to The Guardian content platform.
- **Query Params**:
  - `section` (optional, default: `world`)
  - `q` (optional search query)
  - `page` (default: `1`)
  - `limit` (default: `20`)
- **Success Output**: Similar structure to `GET /api/news`.

---

## 6. Local Development Guide

### Prerequisites
Make sure [Node.js (v18+)](https://nodejs.org/) is installed.

### Steps
1. Install node dependencies:
   ```bash
   npm install
   ```
2. Run the developer compilation server locally:
   ```bash
   npm run dev
   ```
3. Test endpoints by querying:
   - `http://localhost:3000/api/health`
   - `http://localhost:3000/api/news?category=technology`

---

## 7. Deployment Guide (Vercel)

1. Commit your codebase to a GitHub, GitLab, or Bitbucket repository.
2. Log into the [Vercel Dashboard](https://vercel.com) and click **Add New Project**.
3. Select your repository. Vercel will automatically configure the builder configuration since Next.js is detected.
4. Expand **Environment Variables** and add:
   - `GEMINI_API_KEY`
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_CLIENT_EMAIL`
   - `FIREBASE_PRIVATE_KEY` (Ensure private key formatting uses literal quotes and formats newlines `\n` correctly)
   - `GUARDIAN_API_KEY`
5. Click **Deploy**. Vercel will build and host your routes globally.

---

## 8. Example Flutter Client Integration (Dart)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendService {
  static const String baseUrl = 'https://your-vercel-domain.vercel.app/api';

  // 1. Fetch Headlines
  Future<Map<String, dynamic>> fetchCategorizedNews(String category, {int page = 1, int limit = 20}) async {
    final uri = Uri.parse('$baseUrl/news?category=$category&page=$page&limit=$limit');
    final response = await http.get(uri);
    
    if (response.statusCode != 200) {
      throw Exception('API error: status ${response.statusCode}');
    }
    
    final payload = json.decode(response.body);
    if (payload['success'] == false) {
      throw Exception('API failed: ${payload['message']}');
    }
    return payload['data'];
  }

  // 2. Fetch Scraped Details & Gemini Summary
  Future<Map<String, dynamic>> fetchArticleDetails(String articleUrl) async {
    final uri = Uri.parse('$baseUrl/article?url=${Uri.encodeComponent(articleUrl)}');
    final response = await http.get(uri);
    
    if (response.statusCode != 200) {
      throw Exception('API error: status ${response.statusCode}');
    }
    
    final payload = json.decode(response.body);
    if (payload['success'] == false) {
      throw Exception('API failed: ${payload['message']}');
    }
    return payload['data'];
  }
}
```
