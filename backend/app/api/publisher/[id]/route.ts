import { NextRequest, NextResponse } from 'next/server';
import { fetchCategoryNews } from '@/lib/rss';
import { cache } from '@/lib/cache';
import { Article } from '@/lib/types';
import { categoryFeeds, publisherList } from '@/lib/feeds';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const publisherId = params.id.toLowerCase();
    const publisher = publisherList.find(p => p.id === publisherId);

    if (!publisher) {
      return NextResponse.json({
        success: false,
        message: `Unknown publisher: ${publisherId}`,
        data: null,
        timestamp: new Date().toISOString()
      }, { status: 404 });
    }

    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get('page') || '1', 10);
    const limit = parseInt(searchParams.get('limit') || '20', 10);

    // Fetch from all categories and filter by publisher source name
    const allArticles: Article[] = [];
    for (const cat of Object.keys(categoryFeeds)) {
      const cacheKey = `category_${cat}`;
      let articles = cache.get<Article[]>(cacheKey);
      if (!articles) {
        articles = await fetchCategoryNews(cat);
        cache.set(cacheKey, articles, 900);
      }
      allArticles.push(...articles);
    }

    const filtered = allArticles.filter(a =>
      a.source?.toLowerCase() === publisher.name.toLowerCase()
    );

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
      message: `${total} articles from ${publisher.name}.`,
      data: { articles: paginated, pagination: { page, limit, total, hasMore: startIndex + limit < total } },
      timestamp: new Date().toISOString()
    });
  } catch (err: any) {
    console.error(`Error in /api/publisher/${params.id}:`, err);
    return NextResponse.json({
      success: false,
      message: err.message || 'Failed to fetch publisher articles',
      data: null,
      timestamp: new Date().toISOString()
    }, { status: 500 });
  }
}
