import { JSDOM } from 'jsdom';
import { Readability } from '@mozilla/readability';
import * as cheerio from 'cheerio';
import { Article } from './types';
import { resolveGoogleNewsUrl } from './rss';
import { normalizeSource } from './feeds';

export async function extractArticleDetails(articleUrl: string): Promise<Article> {
  const targetUrl = await resolveGoogleNewsUrl(articleUrl);

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 12000); // 12-second timeout

  const response = await fetch(targetUrl, {
    signal: controller.signal,
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.5',
    }
  });
  
  clearTimeout(timeoutId);

  if (!response.ok) {
    throw new Error(`Failed to fetch article. Status code: ${response.status}`);
  }

  const html = await response.text();
  const $ = cheerio.load(html);

  // Helper to extract metadata
  const getMeta = (names: string[]): string => {
    for (const name of names) {
      const content = $(`meta[property="${name}"]`).attr('content') ||
                      $(`meta[name="${name}"]`).attr('content') ||
                      $(`meta[itemprop="${name}"]`).attr('content');
      if (content?.trim()) {
        return content.trim();
      }
    }
    return '';
  };

  const title = getMeta(['og:title', 'twitter:title']) || $('h1').first().text().trim() || 'No Title';
  const description = getMeta(['og:description', 'description', 'twitter:description']);
  const image = getMeta(['og:image', 'twitter:image', 'thumbnailUrl']);
  const author = getMeta(['og:author', 'author']) || 'Staff';
  const publishedAt = getMeta(['article:published_time', 'pubdate', 'datePublished']) || new Date().toISOString();
  
  // Extract tags/keywords
  const tagsString = getMeta(['keywords', 'news_keywords', 'article:tag']);
  const tags = tagsString ? tagsString.split(',').map(t => t.trim()).filter(Boolean) : [];

  // Use Readability to extract main content body cleanly
  const dom = new JSDOM(html, { url: targetUrl });
  const reader = new Readability(dom.window.document);
  const parsed = reader.parse();

  const finalContent = parsed?.textContent?.trim() || description || 'No content extracted.';
  const wordCount = finalContent.split(/\s+/).length;
  const readTime = Math.max(1, Math.ceil(wordCount / 200));

  return {
    title,
    description,
    image,
    url: targetUrl,
    author,
    source: normalizeSource(targetUrl),
    publishedAt,
    content: finalContent,
    readTime,
    tags
  };
}
