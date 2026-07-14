import { NextResponse } from 'next/server';
import { getCacheStats } from '@/lib/cache';

const startTime = Date.now();

export async function GET() {
  const cacheStats = getCacheStats();

  return NextResponse.json({
    success: true,
    message: 'KAAND Backend Platform Service is healthy.',
    data: {
      uptime: `${Math.floor((Date.now() - startTime) / 1000)}s`,
      environment: process.env.NODE_ENV || 'development',
      version: '1.0.0',
      cache: cacheStats
    },
    timestamp: new Date().toISOString()
  });
}
