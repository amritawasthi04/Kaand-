import { NextRequest, NextResponse } from 'next/server';
import { getAllDiscoverArticles } from '@/lib/discover';
import { deduplicateArticles } from '@/lib/home';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  try {
    const rawArticles = await getAllDiscoverArticles();
    const all = deduplicateArticles(rawArticles);

    // Compute simple publisher-coverage trending score
    const publisherCounts: Record<string, number> = {};
    all.forEach(a => {
      if (a.source) {
        publisherCounts[a.source] = (publisherCounts[a.source] || 0) + 1;
      }
    });

    const trending = all.slice(0, 5).map(a => ({
      topic: a.title,
      imageUrl: a.image || 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?auto=format&fit=crop&w=1200&q=80',
      articleCount: a.source ? (publisherCounts[a.source] || 1) : 1,
      publishers: a.source ? [a.source] : ['News'],
      lastUpdated: a.publishedAt || new Date().toISOString()
    }));

    return NextResponse.json({
      success: true,
      data: trending,
      timestamp: new Date().toISOString()
    });
  } catch (err: any) {
    console.error('Error in /api/home/trending:', err);
    return NextResponse.json({ success: false, data: [] }, { status: 500 });
  }
}
