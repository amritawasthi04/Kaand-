import Parser from 'rss-parser';
import { Article } from '../models/article';
import { md5 } from '../utils/hash';
import { CATEGORY_FEEDS } from '../constants';
import * as cheerio from 'cheerio';
import { db } from '../firebase/config';

const normalizeSource = (raw: string): string => {
  const s = raw.toLowerCase();
  if (s.includes('hindu')) return 'The Hindu';
  if (s.includes('ndtv')) return 'NDTV';
  if (s.includes('bbc')) return 'BBC News';
  if (s.includes('reuters')) return 'Reuters';
  if (s.includes('cnn')) return 'CNN';
  if (s.includes('google')) return 'Google News';
  if (s.includes('guardian')) return 'The Guardian';
  if (s.includes('espn')) return 'ESPN';
  if (s.includes('mint')) return 'Mint';
  if (s.includes('times')) return 'Times of India';
  
  if (raw.length > 20 && raw.includes(':')) {
    return raw.split(':')[0].trim();
  }
  return raw.length > 20 ? raw.substring(0, 20).trim() + '...' : raw;
};

function makeAbsoluteUrl(base: string, relative: string): string {
  try {
    const absolute = new URL(relative, base).href;
    if (absolute.startsWith('http://')) {
      return 'https://' + absolute.substring(7);
    }
    return absolute;
  } catch {
    return relative;
  }
}

function isValidImageUrl(urlStr: string): boolean {
  if (!urlStr || !urlStr.startsWith('https://')) return false;
  if (urlStr.startsWith('data:')) return false;
  return true;
}

const extractImage = async (url: string, content: string): Promise<string> => {
  if (content) {
    const match = content.match(/<img[^>]+src="([^">]+)"/i);
    if (match && match[1]) {
      const absUrl = makeAbsoluteUrl(url, match[1]);
      if (isValidImageUrl(absUrl)) return absUrl;
    }
  }
  if (!url) return '';
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 4000);
    const res = await fetch(url, {
      signal: controller.signal,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
      }
    });
    const html = await res.text();
    clearTimeout(timer);

    const $ = cheerio.load(html);
    const getMeta = (props: string[]) => {
      for (const p of props) {
        const v = $(`meta[property="${p}"]`).attr('content') || $(`meta[name="${p}"]`).attr('content');
        if (v) return v.trim();
      }
      return '';
    };

    // 1. og:image
    const ogImage = getMeta(['og:image', 'twitter:image', 'thumbnailUrl']);
    if (ogImage) {
      const absUrl = makeAbsoluteUrl(url, ogImage);
      if (isValidImageUrl(absUrl)) return absUrl;
    }
    
    // 2. twitter:image
    const twitterImage = getMeta(['twitter:image']);
    if (twitterImage) {
      const absUrl = makeAbsoluteUrl(url, twitterImage);
      if (isValidImageUrl(absUrl)) return absUrl;
    }

    // 3. JSON-LD image/thumbnailUrl
    let jsonImage = '';
    $('script[type="application/ld+json"]').each((_, el) => {
      try {
        const parsed = JSON.parse($(el).html() || '{}');
        const graph = parsed['@graph'] || (Array.isArray(parsed) ? parsed : [parsed]);
        for (const item of graph) {
          const img = item.image || item.thumbnailUrl;
          if (img) {
            if (typeof img === 'string') {
              jsonImage = img;
            } else if (img.url) {
              jsonImage = img.url;
            } else if (Array.isArray(img) && img.length > 0) {
              jsonImage = typeof img[0] === 'string' ? img[0] : img[0].url;
            }
            if (jsonImage) break;
          }
        }
      } catch (e) {}
    });
    if (jsonImage) {
      const absUrl = makeAbsoluteUrl(url, jsonImage);
      if (isValidImageUrl(absUrl)) return absUrl;
    }
    
    // 4. First body image (ignore logo, avatars, SVGs)
    let bodyImage = '';
    $('img').each((_, el) => {
      const src = $(el).attr('src');
      if (!src) return;

      const absUrl = makeAbsoluteUrl(url, src.trim());
      if (!isValidImageUrl(absUrl)) return;

      const lowerSrc = absUrl.toLowerCase();
      if (
        lowerSrc.includes('logo') ||
        lowerSrc.includes('icon') ||
        lowerSrc.includes('avatar') ||
        lowerSrc.includes('pixel') ||
        lowerSrc.includes('addec') ||
        lowerSrc.includes('tracker') ||
        lowerSrc.endsWith('.svg') ||
        lowerSrc.includes('sprite') ||
        lowerSrc.includes('placeholder')
      ) {
        return;
      }

      const width = parseInt($(el).attr('width') || '', 10);
      const height = parseInt($(el).attr('height') || '', 10);
      if (!isNaN(width) && !isNaN(height)) {
        if (width < 200 || height < 150) return;
      }

      bodyImage = absUrl;
      return false; // Break Cheerio
    });

    if (bodyImage) return bodyImage;
  } catch (err) {}
  return '';
};

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
        
        let title = rawTitle;
        let source = normalizeSource(feed.title || 'Unknown Source');
        const hyphen = rawTitle.lastIndexOf(' - ');
        if (hyphen !== -1) {
          const suffixSource = rawTitle.substring(hyphen + 3).trim();
          source = normalizeSource(suffixSource.length > 3 ? suffixSource : source);
          title = rawTitle.substring(0, hyphen).trim();
        }

        const id = md5(url);
        const description = item.contentSnippet || item.content || '';
        const image = (item.enclosure && item.enclosure.url) ? item.enclosure.url : '';
        
        return {
          id,
          title,
          description,
          summary: '', // Filled on-demand by scraper/AI
          image,
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

  // Single-Round-Trip Firestore Caching checking step
  if (db && deduped.length > 0) {
    try {
      console.log(`[RSS CACHE] Checking Firestore cache for ${deduped.length} articles.`);
      const docRefs = deduped.map(art => db.collection('article_cache').doc(art.id));
      const snapshots = await db.getAll(...docRefs);
      const cachedImages = new Map<string, string>();
      for (const snap of snapshots) {
        if (snap.exists) {
          const data = snap.data();
          if (data && data.image) {
            cachedImages.set(snap.id, data.image);
          }
        }
      }
      for (const art of deduped) {
        if (cachedImages.has(art.id)) {
          art.image = cachedImages.get(art.id)!;
        }
      }
      console.log(`[RSS CACHE] Found ${cachedImages.size} hits from Firestore cache.`);
    } catch (cacheErr) {
      console.error('[RSS ERROR] Failed to fetch batch article cache:', cacheErr);
    }
  }

  // Find articles that still need image scraping
  const needsScrape = deduped.filter(art => !art.image);
  console.log(`[RSS SCRAPE] ${needsScrape.length} articles need image scraping.`);

  const concurrency = 5;
  const scrapePromises = needsScrape.map(art => async () => {
    const scrapedImage = await extractImage(art.url, art.description || '');
    if (scrapedImage) {
      art.image = scrapedImage;
      if (db) {
        db.collection('article_cache').doc(art.id).set({
          ...art,
          cachedAt: new Date().toISOString(),
          expiresAt: new Date(Date.now() + 86400000 * 7).toISOString(), // 7 days TTL
        }).catch(err => console.error(`[RSS ERROR] Failed to cache article ${art.url}:`, err));
      }
    }
  });

  // Run image scraping with concurrency pooling
  for (let i = 0; i < scrapePromises.length; i += concurrency) {
    const batch = scrapePromises.slice(i, i + concurrency).map(fn => fn());
    await Promise.allSettled(batch);
  }

  // Sort by date: newest first
  const sorted = deduped.sort((a, b) => new Date(b.publishedAt).getTime() - new Date(a.publishedAt).getTime());
  console.log(`[RSS INFO] Final returned article count: ${sorted.length}`);
  return sorted;
}
export default Parser;
