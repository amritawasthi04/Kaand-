import { NextRequest, NextResponse } from 'next/server';
import { cache } from '@/lib/cache';
import { getCategoryArticlesFromStore } from '@/lib/ingest';
import { fetchCategoryNews } from '@/lib/rss';
import { extractScoresFromArticles, SportsScore } from '@/lib/scores';

export const dynamic = 'force-dynamic';

/**
 * GET /api/scores/league/:league
 *
 * Filters extracted scores to ones whose league/source match the route param.
 */
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ league: string }> }
) {
  try {
    const { league } = await params;
    const leagueKey = decodeURIComponent(league).toLowerCase();

    const cacheKey = `scores_league_${leagueKey}`;
    let filtered = cache.get<SportsScore[]>(cacheKey);

    if (!filtered) {
      let articles = await getCategoryArticlesFromStore('sports', 300);
      if (!articles || articles.length === 0) {
        articles = await fetchCategoryNews('sports');
      }

      const scores = extractScoresFromArticles(
        articles.map((a) => ({
          title: a.title,
          description: a.description,
          url: a.url,
          source: a.source,
          publishedAt: a.publishedAt,
          image: a.image,
        }))
      );

      filtered = scores.filter(
        (s) =>
          s.league.toLowerCase().includes(leagueKey) ||
          (s.sport ?? '').toLowerCase() === leagueKey ||
          (s.tournament ?? '').toLowerCase().includes(leagueKey)
      );

      cache.set(cacheKey, filtered, 300);
    }

    return NextResponse.json({
      success: true,
      message: `Retrieved ${filtered.length} scores for "${league}".`,
      data: {
        scores: filtered,
        total: filtered.length,
        liveCount: filtered.filter((s) => s.isLive).length,
      },
      timestamp: new Date().toISOString(),
    });
  } catch (err: any) {
    console.error('Error in /api/scores/league:', err);
    return NextResponse.json(
      {
        success: false,
        message: err?.message || 'Internal Server Error',
        data: { scores: [], total: 0, liveCount: 0 },
        timestamp: new Date().toISOString(),
      },
      { status: 500 }
    );
  }
}
