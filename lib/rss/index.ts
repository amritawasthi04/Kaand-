import Parser from 'rss-parser';
import { Article } from '../models/article';
import { md5 } from '../utils/hash';
import { CATEGORY_FEEDS } from '../constants';

export function titleSimilarity(t1: string, t2: string): number {
  const getWords = (str: string) => 
    new Set(
      str
        .toLowerCase()
        .replace(/[^\w\s]/g, '')
        .split(/\s+/)
        .filter(Boolean)
    );
  
  const words1 = getWords(t1);
  const words2 = getWords(t2);
  
  if (words1.size === 0 || words2.size === 0) return 0;
  
  let intersection = 0;
  for (const w of words1) {
    if (words2.has(w)) {
      intersection++;
    }
  }
  return intersection / (words1.size + words2.size - intersection);
}

export async function fetchRssFeedForCategory(category: string): Promise<Article[]> {
  const parser = new Parser({
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.5',
    },
    timeout: 10000,
  });

  const normalizedCategory = category.toLowerCase().trim();
  const feedKey = normalizedCategory === 'nation' ? 'india' : normalizedCategory;
  const feeds = CATEGORY_FEEDS[feedKey] || [];

  console.log(`[RSS INFO] Requested Category: "${category}"`);
  console.log(`[RSS INFO] Feed Key: "${feedKey}"`);
  console.log(`[RSS INFO] Configured Feeds: ${feeds.length}`);
  console.log(`[RSS INFO] Feed URLs:`, feeds);

  if (feeds.length === 0) return [];

  const promises = feeds.map(async (feedUrl) => {
    console.log(`[RSS INFO] Fetching RSS: ${feedUrl}`);
    try {
      const feed = await parser.parseURL(feedUrl);
      console.log(`[RSS INFO] Feed Title: "${feed.title || 'Unknown'}" | Items Count: ${feed.items?.length || 0}`);
      
      const mapped = feed.items.map((item) => {
        const url = item.link || '';
        const rawTitle = item.title || 'No Title';
        
        // Clean title if it contains source suffix (e.g. "Headline - Source")
        let title = rawTitle;
        let source = feed.title || 'Unknown Source';
        const hyphen = rawTitle.lastIndexOf(' - ');
        if (hyphen !== -1) {
          source = rawTitle.substring(hyphen + 3).trim();
          title = rawTitle.substring(0, hyphen).trim();
        }

        const id = md5(url);
        
        return {
          id,
          title,
          description: item.contentSnippet || item.content || '',
          summary: '', // Filled on-demand by scraper/AI
          image: (item.enclosure && item.enclosure.url) ? item.enclosure.url : '',
          url,
          author: item.creator || item.author || 'Staff',
          source,
          publishedAt: item.isoDate || item.pubDate || new Date().toISOString(),
          category,
          content: '',
          readTime: 0,
          language: 'en'
        } as Article;
      });

      console.log(`[RSS INFO] Mapped ${mapped.length} articles from ${feedUrl}`);
      return mapped;
    } catch (err: any) {
      console.error(`[RSS ERROR] RSS FAILED\nURL: ${feedUrl}\nReason: ${err?.message || err}\nStack: ${err?.stack || 'No Stack'}`);
      return [];
    }
  });

  const results = await Promise.allSettled(promises);
  const rawArticles: Article[] = [];
  for (const res of results) {
    if (res.status === 'fulfilled') {
      rawArticles.push(...res.value);
    }
  }

  console.log(`[RSS FILTER] Raw Articles: ${rawArticles.length}`);

  // Deduplicate and filter out items without URLs
  const deduped: Article[] = [];
  const seenUrls = new Set<string>();
  let urlFilterCount = 0;
  let dupeFilterCount = 0;

  for (const art of rawArticles) {
    if (!art.url) {
      urlFilterCount++;
      continue;
    }
    
    // Check direct URL duplicate
    if (seenUrls.has(art.url)) {
      dupeFilterCount++;
      continue;
    }

    // Check title similarity duplicate
    let isDupe = false;
    for (const existing of deduped) {
      if (titleSimilarity(existing.title, art.title) > 0.6) {
        isDupe = true;
        break;
      }
    }

    if (!isDupe) {
      deduped.push(art);
      seenUrls.add(art.url);
    } else {
      dupeFilterCount++;
    }
  }

  console.log(`[RSS FILTER] After URL Filter: ${rawArticles.length - urlFilterCount}`);
  console.log(`[RSS FILTER] After Duplicate Filter: ${deduped.length}`);
  console.log(`[RSS FILTER] Mapped: ${rawArticles.length} -> Deduplicated: ${dupeFilterCount} -> Final: ${deduped.length}`);

  // Sort by date: newest first
  const sorted = deduped.sort((a, b) => new Date(b.publishedAt).getTime() - new Date(a.publishedAt).getTime());
  console.log(`[RSS INFO] Final returned article count: ${sorted.length}`);
  return sorted;
}
export default Parser;
