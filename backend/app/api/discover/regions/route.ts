import { NextRequest, NextResponse } from 'next/server';
import { getAllDiscoverArticles, createDiscoverResponse, REGIONS_LIST } from '@/lib/discover';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get('page') || '1', 10);
    const limit = parseInt(searchParams.get('limit') || '20', 10);

    const all = await getAllDiscoverArticles();

    const regionsData = REGIONS_LIST.map((reg) => {
      const matchingArticles = all.filter((art) => {
        // Match region code in category or keywords in title/desc
        if (art.category?.toLowerCase() === reg.name.toLowerCase()) return true;
        const inTitle = reg.countries.some(c => art.title.toLowerCase().includes(c));
        const inDesc = reg.countries.some(c => art.description?.toLowerCase().includes(c) ?? false);
        return inTitle || inDesc;
      });

      const count = matchingArticles.length;
      const latestArticle = matchingArticles[0];

      // Extract top publishers in this region
      const publisherCounts: Record<string, number> = {};
      matchingArticles.forEach(a => {
        if (a.source) {
          publisherCounts[a.source] = (publisherCounts[a.source] || 0) + 1;
        }
      });
      const topPublishers = Object.entries(publisherCounts)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 3)
        .map(([name]) => name);

      return {
        name: reg.name,
        articleCount: count,
        lastUpdated: latestArticle?.publishedAt || new Date().toISOString(),
        imageUrl: latestArticle?.image || 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?auto=format&fit=crop&w=1200&q=80',
        topPublishers
      };
    });

    return createDiscoverResponse(regionsData, { page, limit });
  } catch (err: any) {
    console.error('Error in /api/discover/regions:', err);
    return NextResponse.json({
      success: false,
      message: err.message || 'Failed to load regions',
      data: []
    }, { status: 500 });
  }
}
