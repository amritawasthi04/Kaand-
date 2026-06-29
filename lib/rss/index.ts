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
  const parser = new Parser();
  const feeds = CATEGORY_FEEDS[category] || [];
  if (feeds.length === 0) return [];

  const promises = feeds.map(async (feedUrl) => {
    try {
      const feed = await parser.parseURL(feedUrl);
      return feed.items.map((item) => {
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
    } catch (err) {
      console.error(`Error parsing RSS feed ${feedUrl}:`, err);
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

  // Deduplicate and filter out items without URLs
  const deduped: Article[] = [];
  const seenUrls = new Set<string>();

  for (const art of rawArticles) {
    if (!art.url) continue;
    
    // Check direct URL duplicate
    if (seenUrls.has(art.url)) continue;

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
    }
  }

  // Sort by date: newest first
  return deduped.sort((a, b) => new Date(b.publishedAt).getTime() - new Date(a.publishedAt).getTime());
}
export default Parser;
