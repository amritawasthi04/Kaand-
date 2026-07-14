import { NextResponse } from 'next/server';
import { publisherList } from '@/lib/feeds';

export async function GET() {
  return NextResponse.json({
    success: true,
    message: `${publisherList.length} publishers available.`,
    data: publisherList,
    timestamp: new Date().toISOString()
  });
}
