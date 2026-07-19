import { NextRequest, NextResponse } from 'next/server';
import { getAllDiscoverArticles, createDiscoverResponse, TOPICS_LIST } from '@/lib/discover';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get('page') || '1', 10);
    const limit = parseInt(searchParams.get('limit') || '20', 10);

    const all = await getAllDiscoverArticles();
    const now = Date.now();

    const trendingTopics = TOPICS_LIST.map((topic) => {
      const matchingArticles = all.filter((art) => {
        const titleMatch = topic.keywords.some((kw) => art.title.toLowerCase().includes(kw));
        const descMatch = topic.keywords.some((kw) => art.description?.toLowerCase().includes(kw) ?? false);
        return titleMatch || descMatch;
      });

      const uniquePublishers = new Set(matchingArticles.map(a => a.source).filter(Boolean));
      
      // Calculate recency score: weight newer articles higher
      let recencyScore = 0;
      matchingArticles.forEach((art) => {
        const artTime = art.publishedAt ? new Date(art.publishedAt).getTime() : 0;
        const ageHours = (now - artTime) / (1000 * 60 * 60);
        if (ageHours < 24) {
          recencyScore += 5; // high weight for today's news
        } else if (ageHours < 72) {
          recencyScore += 2; // medium weight for past 3 days
        } else {
          recencyScore += 0.5; // low weight for older news
        }
      });

      // Score formula
      const score = matchingArticles.length * uniquePublishers.size + recencyScore;
      const latestArticle = matchingArticles[0];

      return {
        name: topic.name,
        score: Math.round(score * 10) / 10,
        articleCount: matchingArticles.length,
        publisherCount: uniquePublishers.size,
        lastUpdated: latestArticle?.publishedAt || new Date().toISOString(),
        imageUrl: latestArticle?.image || 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?auto=format&fit=crop&w=1200&q=80',
      };
    });

    // Sort by trending score descending
    trendingTopics.sort((a, b) => b.score - a.score);

    return createDiscoverResponse(trendingTopics, { page, limit });
  } catch (err: any) {
    console.error('Error in /api/discover/trending:', err);
    return NextResponse.json({
      success: false,
      message: err.message || 'Failed to load trending topics',
      data: []
    }, { status: 500 });
  }
}
