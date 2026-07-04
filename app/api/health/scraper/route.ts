import { NextResponse } from 'next/server';
import { getScraperHealth } from '../../../../lib/firebase/firestore';

export async function GET() {
  try {
    const health = await getScraperHealth();
    if (!health) {
      return NextResponse.json({
        success: true,
        message: "No health metrics recorded yet.",
        data: {
          totalPublishers: 44,
          passed: 0,
          failed: 0,
          averageScrapeTimeMs: 0,
          cacheHitRate: 0,
          failureReasons: {},
          lastRunTimestamp: new Date(0).toISOString()
        }
      });
    }

    return NextResponse.json({
      success: true,
      message: "Scraper health metrics retrieved successfully.",
      data: health
    });
  } catch (error: any) {
    return NextResponse.json(
      {
        success: false,
        message: "Failed to retrieve scraper health.",
        error: error.message || String(error)
      },
      { status: 500 }
    );
  }
}
