import { NextRequest, NextResponse } from 'next/server';
import { getAllDiscoverArticles, createDiscoverResponse, TOPICS_LIST } from '@/lib/discover';
import { publisherList } from '@/lib/feeds';

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const q = searchParams.get('q') || '';
    const category = searchParams.get('category');
    const publisher = searchParams.get('publisher');
    const page = parseInt(searchParams.get('page') || '1', 10);
    const limit = parseInt(searchParams.get('limit') || '20', 10);
    const suggestions = searchParams.get('suggestions') === 'true';

    const all = await getAllDiscoverArticles();

    if (suggestions) {
      // Incremental suggestion mode
      const normalizedQ = q.toLowerCase().trim();
      if (!normalizedQ) {
        return NextResponse.json({
          success: true,
          data: {
            topics: [],
            publishers: [],
            categories: [],
            titles: [],
            popular: ['#SensexRecord', '#ISRO', '#CricketChampionship', '#StartupsFunding']
          }
        });
      }

      // Filter matching entities
      const matchingTopics = TOPICS_LIST.filter(t => 
        t.name.toLowerCase().includes(normalizedQ) || 
        t.keywords.some(k => k.includes(normalizedQ))
      ).map(t => t.name).slice(0, 3);

      const matchingPublishers = publisherList.filter(p => 
        p.name.toLowerCase().includes(normalizedQ)
      ).map(p => p.name).slice(0, 3);

      const categoriesList = Array.from(new Set(all.map(a => a.category).filter(Boolean)));
      const matchingCategories = categoriesList.filter(c => 
        c!.toLowerCase().includes(normalizedQ)
      ).slice(0, 3);

      const matchingTitles = all.filter(a => 
        a.title.toLowerCase().includes(normalizedQ)
      ).map(a => a.title).slice(0, 5);

      return NextResponse.json({
        success: true,
        data: {
          topics: matchingTopics,
          publishers: matchingPublishers,
          categories: matchingCategories,
          titles: matchingTitles,
          popular: ['#SensexRecord', '#ISRO', '#CricketChampionship', '#StartupsFunding']
        }
      });
    }

    // Standard search execution
    const normalizedQ = q.toLowerCase().trim();
    const filtered = all.filter((art) => {
      if (category && art.category?.toLowerCase() !== category.toLowerCase()) return false;
      if (publisher && art.source?.toLowerCase() !== publisher.toLowerCase()) return false;

      if (normalizedQ) {
        const titleMatch = art.title.toLowerCase().includes(normalizedQ);
        const descMatch = art.description?.toLowerCase().includes(normalizedQ) ?? false;
        const sourceMatch = art.source?.toLowerCase().includes(normalizedQ) ?? false;
        const categoryMatch = art.category?.toLowerCase().includes(normalizedQ) ?? false;
        const tagsMatch = art.tags?.some(tag => tag.toLowerCase().includes(normalizedQ)) ?? false;
        return titleMatch || descMatch || sourceMatch || categoryMatch || tagsMatch;
      }
      return true;
    });

    return createDiscoverResponse(filtered, { page, limit });
  } catch (err: any) {
    console.error('Error in /api/discover/search:', err);
    return NextResponse.json({
      success: false,
      message: err.message || 'Failed to search articles',
      data: []
    }, { status: 500 });
  }
}
