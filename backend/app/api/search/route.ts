import { NextRequest, NextResponse } from 'next/server';
import { fetchCategoryNews } from '@/lib/rss';
import { cache } from '@/lib/cache';
import { Article } from '@/lib/types';
import { categoryFeeds } from '@/lib/feeds';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const q = searchParams.get('q')?.trim().toLowerCase();
    const category = searchParams.get('category')?.trim().toLowerCase() || '';
    const page = parseInt(searchParams.get('page') || '1', 10);
    const limit = parseInt(searchParams.get('limit') || '20', 10);

    if (!q) {
      return NextResponse.json({
        success: false,
        message: 'Missing required query parameter: q',
        data: null,
        timestamp: new Date().toISOString()
      }, { status: 400 });
    }

    // Search across specified category or all categories
    const cats = category ? [category] : Object.keys(categoryFeeds);
    const allArticles: Article[] = [];

    for (const cat of cats) {
      const cacheKey = `category_${cat}`;
      let articles = cache.get<Article[]>(cacheKey);
      if (!articles) {
        articles = await fetchCategoryNews(cat);
        cache.set(cacheKey, articles, 900);
      }
      allArticles.push(...articles);
    }

    // Filter by search term
    const filtered = allArticles.filter(art => {
      const titleMatch = art.title.toLowerCase().includes(q);
      const descMatch = art.description?.toLowerCase().includes(q) || false;
      const srcMatch = art.source?.toLowerCase().includes(q) || false;
      return titleMatch || descMatch || srcMatch;
    });

    // Deduplicate by URL
    const seen = new Set<string>();
    const deduped = filtered.filter(a => {
      if (seen.has(a.url)) return false;
      seen.add(a.url);
      return true;
    });

    const total = deduped.length;
    const startIndex = (page - 1) * limit;
    const paginated = deduped.slice(startIndex, startIndex + limit);

    return NextResponse.json({
      success: true,
      message: `Found ${total} results for "${q}".`,
      data: { articles: paginated, pagination: { page, limit, total, hasMore: startIndex + limit < total } },
      timestamp: new Date().toISOString()
    });
  } catch (err: any) {
    console.error('Error in /api/search:', err);
    return NextResponse.json({
      success: false,
      message: err.message || 'Search failed',
      data: null,
      timestamp: new Date().toISOString()
    }, { status: 500 });
  }
}
