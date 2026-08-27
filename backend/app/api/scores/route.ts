import { NextRequest, NextResponse } from 'next/server';
import { cache } from '@/lib/cache';
import { getCategoryArticlesFromStore } from '@/lib/ingest';
import { fetchCategoryNews } from '@/lib/rss';
import { extractScoresFromArticles, SportsScore } from '@/lib/scores';

export const dynamic = 'force-dynamic';

/**
 * GET /api/scores?sport=cricket
 *
 * Extracts live/finished match scores from the sports article store.
 * Falls back to live RSS fetch when the store is empty.
 */
export async function GET(request: NextRequest) {
  try {
    const sport = request.nextUrl.searchParams.get('sport')?.trim().toLowerCase() || null;

    const cacheKey = 'scores_all_v1';
    let scores = cache.get<SportsScore[]>(cacheKey);

    if (!scores) {
      let articles = await getCategoryArticlesFromStore('sports', 300);
      if (!articles || articles.length === 0) {
        articles = await fetchCategoryNews('sports');
      }

      scores = extractScoresFromArticles(
        articles.map((a) => ({
          title: a.title,
          description: a.description,
          url: a.url,
          source: a.source,
          publishedAt: a.publishedAt,
          image: a.image,
        }))
      );

      // Scores go stale fast — 5-minute cache
      cache.set(cacheKey, scores, 300);
    }

    const filtered =
      sport && sport !== 'all'
        ? scores.filter((s) => (s.sport ?? '').toLowerCase() === sport)
        : scores;

    return NextResponse.json({
      success: true,
      message: `Retrieved ${filtered.length} scores.`,
      data: {
        scores: filtered,
        total: filtered.length,
        liveCount: filtered.filter((s) => s.isLive).length,
      },
      timestamp: new Date().toISOString(),
    });
  } catch (err: any) {
    console.error('Error in /api/scores:', err);
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
