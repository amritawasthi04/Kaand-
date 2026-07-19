import { NextRequest, NextResponse } from 'next/server';
import { getAllDiscoverArticles, createDiscoverResponse, TOPICS_LIST } from '@/lib/discover';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get('page') || '1', 10);
    const limit = parseInt(searchParams.get('limit') || '20', 10);

    const all = await getAllDiscoverArticles();

    const topicsData = TOPICS_LIST.map((topic) => {
      const matchingArticles = all.filter((art) => {
        const titleMatch = topic.keywords.some((kw) => art.title.toLowerCase().includes(kw));
        const descMatch = topic.keywords.some((kw) => art.description?.toLowerCase().includes(kw) ?? false);
        return titleMatch || descMatch;
      });

      const count = matchingArticles.length;
      const latestArticle = matchingArticles[0];

      return {
        name: topic.name,
        description: topic.description,
        articleCount: count,
        lastUpdated: latestArticle?.publishedAt || new Date().toISOString(),
        imageUrl: latestArticle?.image || 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?auto=format&fit=crop&w=1200&q=80',
      };
    });

    // Sort by article count descending
    topicsData.sort((a, b) => b.articleCount - a.articleCount);

    return createDiscoverResponse(topicsData, { page, limit });
  } catch (err: any) {
    console.error('Error in /api/discover/topics:', err);
    return NextResponse.json({
      success: false,
      message: err.message || 'Failed to load topics',
      data: []
    }, { status: 500 });
  }
}
