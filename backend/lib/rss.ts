import Parser from 'rss-parser';
import * as cheerio from 'cheerio';
import { Article } from './types';
import { categoryFeeds, normalizeSource } from './feeds';

const parser = new Parser({
  customFields: {
    item: [
      ['media:content', 'mediaContent'],
      ['media:thumbnail', 'mediaThumbnail'],
      ['enclosure', 'enclosure']
    ]
  }
});

function cleanAndValidateRssImage(url: string): string {
  if (!url || !url.startsWith('https://')) {
    return 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?auto=format&fit=crop&w=1200&q=80';
  }
  const lower = url.toLowerCase();
  const exclusions = ['favicon', 'logo', 'sprite', 'placeholder', 'avatar', 'tracker', 'pixel', 'icon', 'ad-', 'ads-'];
  if (exclusions.some(exc => lower.includes(exc))) {
    return 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?auto=format&fit=crop&w=1200&q=80';
  }
  return url;
}

// Calculate similarity between two titles using Jaccard index
function getTitleSimilarity(t1: string, t2: string): number {
  const getWords = (str: string): Set<string> => {
    return new Set(
      str
        .toLowerCase()
        .replace(/[^\w\s]/g, '')
        .split(/\s+/)
        .filter((w) => w.length > 0)
    );
  };

  const words1 = getWords(t1);
  const words2 = getWords(t2);

  if (words1.size === 0 || words2.size === 0) return 0;

  const intersection = new Set([...words1].filter((w) => words2.has(w)));
  const union = new Set([...words1, ...words2]);

  return intersection.size / union.size;
}

// Port of the complex Google News link resolver
export async function resolveGoogleNewsUrl(link: string): Promise<string> {
  if (!link.includes('news.google.com/rss/articles/')) return link;

  try {
    const urlObj = new URL(link);
    const segments = urlObj.pathname.split('/').filter(Boolean);
    if (segments.length < 3) return link;
    const b64 = segments[2];

    // Method 1: Base64 decoding (fast & direct)
    try {
      let normalized = b64.replace(/-/g, '+').replace(/_/g, '/');
      while (normalized.length % 4 !== 0) {
        normalized += '=';
      }
      const decoded = Buffer.from(normalized, 'base64').toString('utf8');
      const match = decoded.match(/https?:\/\/[^\s\x00-\x1F\x7F-\x9F\u00A0-\uFFFF]+/);
      if (match) {
        let urlStr = match[0];
        while (urlStr.length > 0 && urlStr.charCodeAt(urlStr.length - 1) > 126) {
          urlStr = urlStr.slice(0, -1);
        }
        return urlStr;
      }
    } catch (_) {}

    // Method 2: BatchExecute fallback (same HTTP RPC as the Flutter app)
    const headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36'
    };

    const res = await fetch(link, { headers }).then(r => r.text());
    const tsMatch = res.match(/data-n-a-ts="(\d+)"/);
    const sgMatch = res.match(/data-n-a-sg="([^"]+)"/);

    if (tsMatch && sgMatch) {
      const ts = tsMatch[1];
      const sg = sgMatch[1];
      const rpcUrl = 'https://news.google.com/_/DotsSplashUi/data/batchexecute?rpcids=Fbv4je';
      const param = JSON.stringify([
        "garturlreq",
        [
          ["X", "X", ["X", "X"], null, null, 1, 1, "US:en", null, 1, null, null, null, null, null, 0, 1],
          "X",
          "X",
          1,
          [1, 1, 1],
          1,
          1,
          null,
          0,
          0,
          null,
          0
        ],
        b64,
        parseInt(ts, 10),
        sg
      ]);

      const envelope = ["Fbv4je", param];
      const fReq = JSON.stringify([[envelope]]);

      const postRes = await fetch(rpcUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36'
        },
        body: `f.req=${encodeURIComponent(fReq)}`
      }).then(r => r.text());

      const splitParts = postRes.split('\n\n');
      if (splitParts.length > 1) {
        const cleaned = splitParts[1];
        const rawData = JSON.parse(cleaned);
        const innerDataStr = rawData[0][2];
        const innerData = JSON.parse(innerDataStr);
        const resolvedUrl = innerData[1];
        if (resolvedUrl && typeof resolvedUrl === 'string') {
          return resolvedUrl;
        }
      }
    }
  } catch (err) {
    console.error('Failed to resolve Google News URL server-side:', err);
  }

  return link;
}

export async function fetchCategoryNews(category: string): Promise<Article[]> {
  const feeds = categoryFeeds[category] || [];
  const allArticles: Article[] = [];

  const promises = feeds.map(async (feedUrl) => {
    try {
      // 10-second timeout fetch
      const controller = new AbortController();
      const id = setTimeout(() => controller.abort(), 10000);
      
      const res = await fetch(feedUrl, {
        signal: controller.signal,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        }
      });
      clearTimeout(id);

      if (!res.ok) return;

      const xmlText = await res.text();
      const feed = await parser.parseString(xmlText);

      for (const item of feed.items) {
        const rawTitle = item.title || 'No Title';
        const link = item.link?.trim() || '';
        if (!link) continue;

        let title = rawTitle;
        let source = normalizeSource(feedUrl);

        // Normalize title / source from Google News titles formatted as "Title - Source"
        const hyphenIndex = rawTitle.lastIndexOf(' - ');
        if (hyphenIndex !== -1) {
          title = rawTitle.substring(0, hyphenIndex).trim();
          source = rawTitle.substring(hyphenIndex + 3).trim();
        }

        let imageUrl = '';
        const itemMediaContent = (item as any).mediaContent;
        const itemMediaThumbnail = (item as any).mediaThumbnail;

        if (item.enclosure && item.enclosure.url) {
          imageUrl = item.enclosure.url;
        } else if (itemMediaContent && itemMediaContent.$ && itemMediaContent.$.url) {
          imageUrl = itemMediaContent.$.url;
        } else if (itemMediaThumbnail && itemMediaThumbnail.$ && itemMediaThumbnail.$.url) {
          imageUrl = itemMediaThumbnail.$.url;
        } else {
          const textToParse = ((item as any).content || '') + ((item as any).description || '');
          if (textToParse.includes('<img')) {
            try {
              const $img = cheerio.load(textToParse);
              const src = $img('img').first().attr('src');
              if (src) {
                imageUrl = src;
              }
            } catch (_) {}
          }
        }

        const validImage = cleanAndValidateRssImage(imageUrl);

        allArticles.push({
          title,
          description: item.contentSnippet || item.summary || '',
          url: link,
          image: validImage,
          author: item.creator || 'Staff',
          source: source,
          publishedAt: item.pubDate || new Date().toISOString(),
          category: category
        });
      }
    } catch (err) {
      console.error(`Error fetching feed ${feedUrl}:`, err);
    }
  });

  await Promise.all(promises);

  // Deduplication based on URL & title similarity
  const deduped: Article[] = [];
  const seenUrls = new Set<string>();

  for (const art of allArticles) {
    if (seenUrls.has(art.url)) continue;

    let isDupe = false;
    for (const existing of deduped) {
      if (getTitleSimilarity(existing.title, art.title) > 0.6) {
        isDupe = true;
        break;
      }
    }

    if (!isDupe) {
      seenUrls.add(art.url);
      deduped.push(art);
    }
  }

  // Sort by publication date (descending)
  return deduped.sort((a, b) => {
    const timeA = a.publishedAt ? new Date(a.publishedAt).getTime() : 0;
    const timeB = b.publishedAt ? new Date(b.publishedAt).getTime() : 0;
    return timeB - timeA;
  });
}
