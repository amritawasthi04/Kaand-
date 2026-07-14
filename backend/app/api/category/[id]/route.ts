import { NextRequest, NextResponse } from 'next/server';
import { fetchCategoryNews } from '@/lib/rss';
import { cache } from '@/lib/cache';
import { Article } from '@/lib/types';
import { categoryFeeds } from '@/lib/feeds';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const category = params.id.toLowerCase();

    if (!categoryFeeds[category]) {
      return NextResponse.json({
        success: false,
        message: `Unknown category: ${category}`,
        data: null,
        timestamp: new Date().toISOString()
      }, { status: 404 });
    }

    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get('page') || '1', 10);
    const limit = parseInt(searchParams.get('limit') || '20', 10);

    const cacheKey = `category_${category}`;
    let articles = cache.get<Article[]>(cacheKey);
    if (!articles) {
      articles = await fetchCategoryNews(category);
      cache.set(cacheKey, articles, 900);
    }

    const total = articles.length;
    const startIndex = (page - 1) * limit;
    const paginated = articles.slice(startIndex, startIndex + limit);

    return NextResponse.json({
      success: true,
      message: `${paginated.length} articles in ${category}.`,
      data: { articles: paginated, pagination: { page, limit, total, hasMore: startIndex + limit < total } },
      timestamp: new Date().toISOString()
    });
  } catch (err: any) {
    console.error(`Error in /api/category/${params.id}:`, err);
    return NextResponse.json({
      success: false,
      message: err.message || 'Failed to fetch category',
      data: null,
      timestamp: new Date().toISOString()
    }, { status: 500 });
  }
}
