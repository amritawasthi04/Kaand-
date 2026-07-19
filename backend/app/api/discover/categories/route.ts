import { NextRequest, NextResponse } from 'next/server';
import { getAllDiscoverArticles, createDiscoverResponse } from '@/lib/discover';
import { categoryFeeds } from '@/lib/feeds';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get('page') || '1', 10);
    const limit = parseInt(searchParams.get('limit') || '20', 10);

    const all = await getAllDiscoverArticles();
    const categories = Object.keys(categoryFeeds);

    const categoriesData = categories.map((cat) => {
      const matchingArticles = all.filter(
        (art) => art.category?.toLowerCase() === cat.toLowerCase()
      );

      const count = matchingArticles.length;
      const latestArticle = matchingArticles[0];

      return {
        name: cat.toUpperCase(),
        code: cat,
        articleCount: count,
        lastUpdated: latestArticle?.publishedAt || new Date().toISOString(),
        imageUrl: latestArticle?.image || 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?auto=format&fit=crop&w=1200&q=80',
      };
    });

    return createDiscoverResponse(categoriesData, { page, limit });
  } catch (err: any) {
    console.error('Error in /api/discover/categories:', err);
    return NextResponse.json({
      success: false,
      message: err.message || 'Failed to load categories',
      data: []
    }, { status: 500 });
  }
}
