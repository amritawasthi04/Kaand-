import { NextRequest, NextResponse } from 'next/server';
import { getAllDiscoverArticles } from '@/lib/discover';
import { deduplicateArticles } from '@/lib/home';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const cursorStr = searchParams.get('cursor');
    const limit = parseInt(searchParams.get('limit') || '10', 10);

    const rawArticles = await getAllDiscoverArticles();
    const all = deduplicateArticles(rawArticles);

    const cursorIndex = cursorStr ? parseInt(cursorStr, 10) : 15; // default offset is 15 to skip hero/highlights
    const feedSlice = all.slice(cursorIndex, cursorIndex + limit);
    const hasNext = cursorIndex + limit < all.length;

    return NextResponse.json({
      success: true,
      data: feedSlice,
      pagination: {
        cursor: hasNext ? (cursorIndex + limit).toString() : null,
        hasNext
      },
      timestamp: new Date().toISOString()
    });
  } catch (err: any) {
    console.error('Error in /api/home/feed:', err);
    return NextResponse.json({ success: false, data: [] }, { status: 500 });
  }
}
