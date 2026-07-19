import { NextRequest, NextResponse } from 'next/server';
import { getAllDiscoverArticles, createDiscoverResponse } from '@/lib/discover';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get('page') || '1', 10);
    const limit = parseInt(searchParams.get('limit') || '5', 10);

    const all = await getAllDiscoverArticles();
    
    // Select editors' picks: articles with a good descriptions, high-quality sources, and not too old
    const picks = all.filter(a => 
      a.description && 
      a.description.length > 50 &&
      ['The Hindu', 'BBC', 'The Guardian', 'Bloomberg', 'Reuters'].includes(a.source || '')
    ).slice(0, 10);

    const fallbackPicks = picks.length >= 3 ? picks : all.slice(0, 10);

    return createDiscoverResponse(fallbackPicks, { page, limit });
  } catch (err: any) {
    console.error('Error in /api/discover/editors-picks:', err);
    return NextResponse.json({
      success: false,
      message: err.message || 'Failed to load editors picks',
      data: []
    }, { status: 500 });
  }
}
