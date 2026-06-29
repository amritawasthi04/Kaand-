import { NextRequest } from 'next/server';
import { z } from 'zod';
import Parser from 'rss-parser';
import { handleOptions } from '../../../lib/utils/cors';
import { successResponse, errorResponse } from '../../../lib/utils/response';
import { getFeedCache, setFeedCache } from '../../../lib/firebase/firestore';
import { fetchRssFeedForCategory } from '../../../lib/rss';
import { Article } from '../../../lib/models/article';
import { md5 } from '../../../lib/utils/hash';

const QuerySchema = z.object({
  category: z.string().default('general'),
  search: z.string().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(20),
});

export async function OPTIONS() {
  return handleOptions();
}

export async function GET(request: NextRequest) {
  try {
    const url = new URL(request.url);
    const queryParams = Object.fromEntries(url.searchParams.entries());

    // Validate request query parameters via Zod
    const parsed = QuerySchema.safeParse(queryParams);
    if (!parsed.success) {
      const errors = parsed.error.errors.map(err => ({
        field: err.path.join('.'),
        message: err.message,
      }));
      return errorResponse('Invalid query parameters', 'INVALID_QUERY', 400, errors);
    }

    const { category, search, page, limit } = parsed.data;

    let articles: Article[] = [];

    // 1. If it's a dynamic search, query Google News Search RSS directly (uncached/short cache)
    if (search && search.trim().length > 0) {
      try {
        const parser = new Parser();
        const searchUrl = `https://news.google.com/rss/search?q=${encodeURIComponent(search)}&hl=en-IN&gl=IN&ceid=IN:en`;
        const feed = await parser.parseURL(searchUrl);
        
        articles = feed.items.map((item) => {
          const itemUrl = item.link || '';
          const rawTitle = item.title || 'No Title';
          
          let title = rawTitle;
          let source = 'Google News';
          const hyphen = rawTitle.lastIndexOf(' - ');
          if (hyphen !== -1) {
            source = rawTitle.substring(hyphen + 3).trim();
            title = rawTitle.substring(0, hyphen).trim();
          }

          return {
            id: md5(itemUrl),
            title,
            description: item.contentSnippet || item.content || '',
            summary: '',
            image: '',
            url: itemUrl,
            author: item.creator || item.author || 'Staff',
            source,
            publishedAt: item.isoDate || item.pubDate || new Date().toISOString(),
            category: 'search',
            content: '',
            readTime: 0,
            language: 'en'
          } as Article;
        });
      } catch (searchError) {
        console.error('Google News search feed fetch failed, falling back to empty list:', searchError);
        articles = [];
      }
    } else {
      // 2. Try loading category news from Firestore Cache
      const cached = await getFeedCache(category);
      if (cached) {
        articles = cached;
      } else {
        // Fetch fresh feeds from RSS sources in parallel
        articles = await fetchRssFeedForCategory(category);
        
        // Cache in Firestore if there are articles fetched
        if (articles.length > 0) {
          await setFeedCache(category, articles);
        }
      }
    }

    // 3. Paginate the list
    const total = articles.length;
    const startIndex = (page - 1) * limit;
    const paginatedArticles = articles.slice(startIndex, startIndex + limit);

    return successResponse({
      articles: paginatedArticles,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      }
    });
  } catch (error: any) {
    console.error('Error in GET /api/news:', error);
    return errorResponse(error.message || 'Failed to fetch news', 'NEWS_FETCH_ERROR');
  }
}
