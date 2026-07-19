import { NextRequest, NextResponse } from 'next/server';
import { getAllDiscoverArticles } from '@/lib/discover';
import { 
  getHeroStory, 
  getBreakingNews, 
  getEditorsHighlights, 
  getCategoryHighlights, 
  deduplicateArticles 
} from '@/lib/home';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const cursorStr = searchParams.get('cursor');
    const limit = parseInt(searchParams.get('limit') || '10', 10);

    const rawArticles = await getAllDiscoverArticles();
    const all = deduplicateArticles(rawArticles);

    // If requesting continuous feed pages via cursor
    if (cursorStr) {
      const cursorIndex = parseInt(cursorStr, 10);
      const feedSlice = all.slice(cursorIndex, cursorIndex + limit);
      const hasNext = cursorIndex + limit < all.length;
      
      return NextResponse.json({
        success: true,
        data: feedSlice,
        pagination: {
          cursor: hasNext ? (cursorIndex + limit).toString() : null,
          hasNext
        }
      });
    }

    // Full layout response for primary load
    const hero = getHeroStory(all);
    const breaking = getBreakingNews(all);
    const highlights = getEditorsHighlights(all);
    const categories = getCategoryHighlights(all);
    
    // Latest: top 10 articles excluding the hero
    const latest = all.filter(a => a.url !== hero?.url).slice(0, 10);

    // Trending: compute simple publisher-coverage score
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

    // Continuous feed starting index
    const feedStartIndex = 15;
    const feed = all.slice(feedStartIndex, feedStartIndex + limit);
    const hasNext = feedStartIndex + limit < all.length;

    const expiresAt = new Date(Date.now() + 300 * 1000).toISOString();

    return NextResponse.json({
      success: true,
      lastUpdated: new Date().toISOString(),
      sections: {
        breaking,
        hero: hero || {},
        highlights,
        trending,
        latest,
        categories,
        feed
      },
      pagination: {
        cursor: hasNext ? (feedStartIndex + limit).toString() : null,
        hasNext
      },
      cache: {
        cached: true,
        expiresAt
      }
    });
  } catch (err: any) {
    console.error('Error in /api/home aggregator:', err);
    return NextResponse.json({
      success: false,
      message: err.message || 'Failed to assemble home page',
      sections: {
        breaking: [],
        hero: {},
        highlights: [],
        trending: [],
        latest: [],
        categories: [],
        feed: []
      }
    }, { status: 500 });
  }
}
