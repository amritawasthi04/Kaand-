import { NextRequest, NextResponse } from 'next/server';
import { extractArticleDetails } from '@/lib/extractor';
import { cache } from '@/lib/cache';
import { ApiResponse, Article } from '@/lib/types';
import { isPrivateUrl } from '@/lib/ssrf';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const url = searchParams.get('url')?.trim();

    if (!url) {
      return NextResponse.json({
        success: false,
        message: 'Missing required query parameter: url',
        data: null,
        timestamp: new Date().toISOString()
      }, { status: 400 });
    }

    if (isPrivateUrl(url)) {
      return NextResponse.json({
        success: false,
        code: 'SSRF_BLOCKED',
        message: 'Access to private or loopback addresses is blocked.',
        data: null,
        timestamp: new Date().toISOString()
      }, { status: 400 });
    }

    const cacheKey = `article_${url}`;
    let article = cache.get<Article>(cacheKey);

    if (!article) {
      article = await extractArticleDetails(url);
      // Cache for 24 hours (86400 seconds)
      cache.set(cacheKey, article, 86400);
    }

    const response: ApiResponse<Article> = {
      success: true,
      message: 'Article details extracted successfully.',
      data: article,
      timestamp: new Date().toISOString()
    };

    return NextResponse.json(response);
  } catch (err: any) {
    console.error('Error in /api/article:', err);
    return NextResponse.json({
      success: false,
      message: err.message || 'Failed to extract article details.',
      data: null,
      timestamp: new Date().toISOString()
    }, { status: 500 });
  }
}
