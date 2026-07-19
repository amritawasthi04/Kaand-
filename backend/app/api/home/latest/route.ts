import { NextRequest, NextResponse } from 'next/server';
import { getAllDiscoverArticles } from '@/lib/discover';
import { deduplicateArticles } from '@/lib/home';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get('page') || '1', 10);
    const limit = parseInt(searchParams.get('limit') || '20', 10);

    const rawArticles = await getAllDiscoverArticles();
    const all = deduplicateArticles(rawArticles);

    const startIndex = (page - 1) * limit;
    const endIndex = page * limit;
    const sliced = all.slice(startIndex, endIndex);

    return NextResponse.json({
      success: true,
      data: sliced,
      pagination: {
        page,
        limit,
        hasNext: endIndex < all.length
      },
      timestamp: new Date().toISOString()
    });
  } catch (err: any) {
    console.error('Error in /api/home/latest:', err);
    return NextResponse.json({ success: false, data: [] }, { status: 500 });
  }
}
