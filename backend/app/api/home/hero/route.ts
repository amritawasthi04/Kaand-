import { NextRequest, NextResponse } from 'next/server';
import { getAllDiscoverArticles } from '@/lib/discover';
import { getHeroStory, deduplicateArticles } from '@/lib/home';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  try {
    const rawArticles = await getAllDiscoverArticles();
    const all = deduplicateArticles(rawArticles);
    const hero = getHeroStory(all);

    return NextResponse.json({
      success: true,
      data: hero || {},
      timestamp: new Date().toISOString()
    });
  } catch (err: any) {
    console.error('Error in /api/home/hero:', err);
    return NextResponse.json({ success: false, data: {} }, { status: 500 });
  }
}
