import { NextRequest, NextResponse } from 'next/server';
import { getAllDiscoverArticles } from '@/lib/discover';
import { getEditorsHighlights, deduplicateArticles } from '@/lib/home';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  try {
    const rawArticles = await getAllDiscoverArticles();
    const all = deduplicateArticles(rawArticles);
    const highlights = getEditorsHighlights(all);

    return NextResponse.json({
      success: true,
      data: highlights,
      timestamp: new Date().toISOString()
    });
  } catch (err: any) {
    console.error('Error in /api/home/editors-highlights:', err);
    return NextResponse.json({ success: false, data: [] }, { status: 500 });
  }
}
