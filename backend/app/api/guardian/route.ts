import { NextRequest, NextResponse } from 'next/server';
import { ApiResponse, Article } from '@/lib/types';
import { cache } from '@/lib/cache';

export const dynamic = 'force-dynamic';

const GUARDIAN_API_KEY = process.env.GUARDIAN_API_KEY;
const GUARDIAN_BASE_URL = 'https://content.guardianapis.com';

export async function GET(request: NextRequest) {
  try {
    if (!GUARDIAN_API_KEY) {
      return NextResponse.json({
        success: false,
        message: 'Guardian integration is not configured.',
        data: [],
        timestamp: new Date().toISOString()
      }, { status: 503 });
    }

    const { searchParams } = new URL(request.url);
    const section = searchParams.get('section') || 'world';
    const q = searchParams.get('q') || '';
    const requestedPage = parseInt(searchParams.get('page') || '1', 10);
    const requestedLimit = parseInt(searchParams.get('limit') || '20', 10);
    const page = Number.isFinite(requestedPage) ? Math.max(1, requestedPage) : 1;
    const limit = Number.isFinite(requestedLimit) ? Math.min(50, Math.max(1, requestedLimit)) : 20;

    const cacheKey = `guardian_${section}_${q}_${page}_${limit}`;
    let articles = cache.get<Article[]>(cacheKey);

    if (!articles) {
      let url = `${GUARDIAN_BASE_URL}/search?api-key=${GUARDIAN_API_KEY}&section=${section}&page=${page}&page-size=${limit}&show-fields=all`;
      if (q) {
        url += `&q=${encodeURIComponent(q)}`;
      }

      const response = await fetch(url, {
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'KAAND Backend Platform Service'
        }
      });

      if (!response.ok) {
        throw new Error(`The Guardian API responded with status: ${response.status}`);
      }

      const data = await response.json();
      const results = data.response?.results || [];

      articles = results.map((item: any) => {
        const fields = item.fields || {};
        return {
          title: item.webTitle || 'No Title',
          description: fields.trailText || fields.standfirst || '',
          url: item.webUrl || '',
          image: fields.thumbnail || '',
          author: fields.byline || 'The Guardian',
          source: 'The Guardian',
          publishedAt: item.webPublicationDate || new Date().toISOString(),
          category: item.sectionName || section,
          readTime: 1
        };
      });

      // Cache for 15 minutes
      cache.set(cacheKey, articles, 900);
    }

    const articlesList = articles || [];

    const response: ApiResponse<Article[]> = {
      success: true,
      message: `Successfully retrieved ${articlesList.length} articles from The Guardian.`,
      data: articlesList,
      timestamp: new Date().toISOString()
    };

    return NextResponse.json(response);
  } catch (err: any) {
    console.error('Error in /api/guardian proxy:', err);
    return NextResponse.json({
      success: false,
      message: err.message || 'Failed to fetch Guardian news',
      data: [],
      timestamp: new Date().toISOString()
    }, { status: 502 });
  }
}
