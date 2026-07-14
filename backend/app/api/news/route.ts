import { NextRequest, NextResponse } from 'next/server';
import { fetchCategoryNews } from '@/lib/rss';
import { cache } from '@/lib/cache';
import { Article, ApiResponse } from '@/lib/types';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const category = searchParams.get('category') || 'general';
    const search = searchParams.get('search')?.trim().toLowerCase() || '';
    const page = parseInt(searchParams.get('page') || '1', 10);
    const limit = parseInt(searchParams.get('limit') || '20', 10);

    const cacheKey = `category_${category}`;
    let articles = cache.get<Article[]>(cacheKey);

    if (!articles) {
      articles = await fetchCategoryNews(category);
      // Cache for 15 minutes (900 seconds)
      cache.set(cacheKey, articles, 900);
    }

    // Apply search filter if provided
    let filtered = articles;
    if (search) {
      filtered = articles.filter(art => {
        const titleMatch = art.title.toLowerCase().includes(search);
        const descMatch = art.description?.toLowerCase().includes(search) || false;
        const srcMatch = art.source?.toLowerCase().includes(search) || false;
        return titleMatch || descMatch || srcMatch;
      });
    }

    // Pagination
    const total = filtered.length;
    const startIndex = (page - 1) * limit;
    const paginated = filtered.slice(startIndex, startIndex + limit);
    const hasMore = startIndex + limit < total;

    const response: ApiResponse<Article[]> = {
      success: true,
      message: `Successfully retrieved ${paginated.length} articles.`,
      data: paginated,
      pagination: {
        page,
        limit,
        total,
        hasMore
      },
      timestamp: new Date().toISOString()
    };

    return NextResponse.json(response);
  } catch (err: any) {
    console.error('Error in /api/news:', err);
    return NextResponse.json({
      success: false,
      message: err.message || 'Internal Server Error',
      data: [],
      timestamp: new Date().toISOString()
    }, { status: 500 });
  }
}
