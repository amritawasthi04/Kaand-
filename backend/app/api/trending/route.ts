import { NextRequest, NextResponse } from 'next/server';
import { fetchCategoryNews } from '@/lib/rss';
import { cache } from '@/lib/cache';
import { Article } from '@/lib/types';

export const dynamic = 'force-dynamic';

const TRENDING_CATEGORIES = ['general', 'technology', 'world'];

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const limit = parseInt(searchParams.get('limit') || '20', 10);

    const allArticles: Article[] = [];

    for (const cat of TRENDING_CATEGORIES) {
      const cacheKey = `category_${cat}`;
      let articles = cache.get<Article[]>(cacheKey);
      if (!articles) {
        articles = await fetchCategoryNews(cat);
        cache.set(cacheKey, articles, 900);
      }
      allArticles.push(...articles);
    }

    // Deduplicate by URL
    const seen = new Set<string>();
    const deduped = allArticles.filter(a => {
      if (seen.has(a.url)) return false;
      seen.add(a.url);
      return true;
    });

    // Sort by date descending, take top N
    deduped.sort((a, b) => {
      const ta = a.publishedAt ? new Date(a.publishedAt).getTime() : 0;
      const tb = b.publishedAt ? new Date(b.publishedAt).getTime() : 0;
      return tb - ta;
    });

    const trending = deduped.slice(0, limit);

    return NextResponse.json({
      success: true,
      message: `${trending.length} trending articles.`,
      data: trending,
      timestamp: new Date().toISOString()
    });
  } catch (err: any) {
    console.error('Error in /api/trending:', err);
    return NextResponse.json({
      success: false,
      message: err.message || 'Failed to fetch trending articles',
      data: [],
      timestamp: new Date().toISOString()
    }, { status: 500 });
  }
}
