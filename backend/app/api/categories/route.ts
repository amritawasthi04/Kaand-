import { NextResponse } from 'next/server';
import { categoryFeeds } from '@/lib/feeds';

export async function GET() {
  const categories = Object.entries(categoryFeeds).map(([id, feeds]) => ({
    id,
    name: id.charAt(0).toUpperCase() + id.slice(1),
    feedCount: feeds.length
  }));

  return NextResponse.json({
    success: true,
    message: `${categories.length} categories available.`,
    data: categories,
    timestamp: new Date().toISOString()
  });
}
