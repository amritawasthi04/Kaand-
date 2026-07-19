import { NextRequest, NextResponse } from 'next/server';
import { getAllDiscoverArticles, createDiscoverResponse } from '@/lib/discover';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get('page') || '1', 10);
    const limit = parseInt(searchParams.get('limit') || '20', 10);

    const all = await getAllDiscoverArticles();
    return createDiscoverResponse(all, { page, limit });
  } catch (err: any) {
    console.error('Error in /api/discover:', err);
    return NextResponse.json({
      success: false,
      message: err.message || 'Failed to load discover articles',
      data: []
    }, { status: 500 });
  }
}
