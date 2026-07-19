import { NextRequest, NextResponse } from 'next/server';
import { getAllDiscoverArticles, createDiscoverResponse } from '@/lib/discover';
import { publisherList } from '@/lib/feeds';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get('page') || '1', 10);
    const limit = parseInt(searchParams.get('limit') || '20', 10);

    const all = await getAllDiscoverArticles();

    const publishersData = publisherList.map((pub) => {
      const matchingArticles = all.filter((art) => 
        (art.source ?? '').toLowerCase().includes(pub.name.toLowerCase())
      );

      const count = matchingArticles.length;
      const latestArticle = matchingArticles[0];

      return {
        name: pub.name,
        logoText: pub.name.substring(0, 1).toUpperCase(),
        stats: `${count} stories`,
        bio: `Leading publisher for news and editorial content globally.`,
        articleCount: count,
        lastUpdated: latestArticle?.publishedAt || new Date().toISOString(),
        latestArticle: latestArticle || null
      };
    });

    // Sort by article count descending
    publishersData.sort((a, b) => b.articleCount - a.articleCount);

    return createDiscoverResponse(publishersData, { page, limit });
  } catch (err: any) {
    console.error('Error in /api/discover/publishers:', err);
    return NextResponse.json({
      success: false,
      message: err.message || 'Failed to load publishers',
      data: []
    }, { status: 500 });
  }
}
