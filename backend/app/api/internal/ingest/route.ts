import { NextRequest, NextResponse } from 'next/server';
import { ingestAll } from '@/lib/ingest';

export const dynamic = 'force-dynamic';
export const maxDuration = 300;

export async function GET(request: NextRequest) {
  const secret = process.env.INGEST_SECRET;

  if (secret) {
    const provided =
      request.headers.get('authorization')?.replace('Bearer ', '') ??
      new URL(request.url).searchParams.get('secret');
    if (provided !== secret) {
      return NextResponse.json(
        { success: false, message: 'Unauthorized' },
        { status: 401 }
      );
    }
  }

  const report = await ingestAll();
  return NextResponse.json({
    success: report.ok,
    data: report,
    timestamp: new Date().toISOString(),
  });
}

export async function POST(request: NextRequest) {
  return GET(request);
}
