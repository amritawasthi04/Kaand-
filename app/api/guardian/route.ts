import { NextRequest } from 'next/server';
import { z } from 'zod';
import axios from 'axios';
import { handleOptions } from '../../../lib/utils/cors';
import { successResponse, errorResponse } from '../../../lib/utils/response';
import { getGuardianCache, setGuardianCache } from '../../../lib/firebase/firestore';
import { Article } from '../../../lib/models/article';
import { md5 } from '../../../lib/utils/hash';

const QuerySchema = z.object({
  section: z.string().default('world'),
  q: z.string().optional(),
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

    // Validate parameters via Zod
    const parsed = QuerySchema.safeParse(queryParams);
    if (!parsed.success) {
      return errorResponse('Invalid query parameters', 'INVALID_QUERY', 400);
    }

    const { section, q, page, limit } = parsed.data;

    // Form cache key based on query filters
    const cacheKey = q 
      ? `search_${section}_${md5(q.trim().toLowerCase())}`
      : `section_${section}`;

    let articles: Article[] = [];

    // 1. Try reading from Firestore cache
    const cached = await getGuardianCache(cacheKey);
    if (cached) {
      console.log(`Cache HIT for Guardian: ${cacheKey}`);
      articles = cached;
    } else {
      console.log(`Cache MISS for Guardian: ${cacheKey}`);
      
      const apiKey = process.env.GUARDIAN_API_KEY || 'test';
      let apiUrl = '';

      if (q && q.trim().length > 0) {
        apiUrl = `https://content.guardianapis.com/search?q=${encodeURIComponent(q)}&show-fields=headline,trailText,thumbnail,byline,bodyText&order-by=relevance&page-size=50&api-key=${apiKey}`;
      } else {
        apiUrl = `https://content.guardianapis.com/search?section=${encodeURIComponent(section)}&show-fields=headline,trailText,thumbnail,byline,bodyText&order-by=newest&page-size=50&api-key=${apiKey}`;
      }

      const response = await axios.get(apiUrl, { timeout: 6000 });
      if (response.status !== 200) {
        return errorResponse('Guardian API query failed', 'GUARDIAN_API_ERROR', 502);
      }

      const results = response.data?.response?.results || [];

      articles = results.map((item: any) => {
        const fields = item.fields || {};
        const contentText = fields.bodyText || '';
        const wordCount = contentText.trim().split(/\s+/).filter(Boolean).length;
        const readTime = Math.max(1, Math.ceil(wordCount / 200));

        return {
          id: md5(item.webUrl || ''),
          title: fields.headline || item.webTitle || 'No Title',
          description: fields.trailText || '',
          summary: fields.trailText || '',
          image: fields.thumbnail || '',
          url: item.webUrl || '',
          author: fields.byline || 'The Guardian',
          source: 'The Guardian',
          publishedAt: item.webPublicationDate || new Date().toISOString(),
          category: section,
          content: contentText,
          readTime,
          language: 'en',
        } as Article;
      });

      // Write results to cache if any articles were fetched successfully
      if (articles.length > 0) {
        await setGuardianCache(cacheKey, articles);
      }
    }

    // 2. Perform server-side pagination
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
    console.error('Error in GET /api/guardian:', error);
    return errorResponse(error.message || 'Failed to fetch Guardian news', 'GUARDIAN_FETCH_ERROR');
  }
}
