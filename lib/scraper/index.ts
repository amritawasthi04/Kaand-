import axios from 'axios';
import * as cheerio from 'cheerio';
import { JSDOM } from 'jsdom';
import { Readability } from '@mozilla/readability';

export interface ScrapedDetails {
  title: string;
  description: string;
  image: string;
  author: string;
  source: string;
  publishedAt: string;
  content: string;
}

export async function scrapeArticleUrl(url: string): Promise<ScrapedDetails> {
  const headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
  };

  const response = await axios.get(url, {
    headers,
    timeout: 8000,
    maxRedirects: 5,
  });

  const html = response.data;
  if (!html || typeof html !== 'string') {
    throw new Error('Target URL returned empty HTML content.');
  }

  const $ = cheerio.load(html);

  // 1. Extract metadata via Cheerio (OpenGraph & Schema.org JSON-LD)
  const ogTitle = $('meta[property="og:title"]').attr('content') || $('meta[name="twitter:title"]').attr('content') || '';
  const ogDescription = $('meta[property="og:description"]').attr('content') || $('meta[name="description"]').attr('content') || '';
  const ogImage = $('meta[property="og:image"]').attr('content') || $('meta[name="twitter:image"]').attr('content') || '';
  const ogAuthor = $('meta[property="article:author"]').attr('content') || $('meta[name="author"]').attr('content') || '';
  const ogPublishDate = $('meta[property="article:published_time"]').attr('content') || $('meta[name="publish-date"]').attr('content') || '';

  // JSON-LD fallback
  let jsonldImage = '';
  let jsonldAuthor = '';
  let jsonldPublishDate = '';
  let jsonldDescription = '';

  $('script[type="application/ld+json"]').each((_, el) => {
    try {
      const innerHtml = $(el).html()?.trim();
      if (!innerHtml) return;
      
      const data = JSON.parse(innerHtml);
      const objects = Array.isArray(data) ? data : (data['@graph'] ? data['@graph'] : [data]);
      for (const obj of objects) {
        if (obj.image) {
          jsonldImage = typeof obj.image === 'string' ? obj.image : (obj.image.url || jsonldImage);
        }
        if (obj.thumbnailUrl) {
          jsonldImage = obj.thumbnailUrl;
        }
        if (obj.author) {
          jsonldAuthor = typeof obj.author === 'string' ? obj.author : (obj.author.name || jsonldAuthor);
        }
        if (obj.datePublished) {
          jsonldPublishDate = obj.datePublished;
        }
        if (obj.description) {
          jsonldDescription = obj.description;
        }
      }
    } catch {
      // Ignore JSON parse errors
    }
  });

  // 2. Extract content using Mozilla Readability
  let readabilityTitle = '';
  let readabilityContent = '';
  let readabilityExcerpt = '';
  let readabilityByline = '';

  try {
    const dom = new JSDOM(html, { url });
    const reader = new Readability(dom.window.document);
    const parsed = reader.parse();
    if (parsed) {
      readabilityTitle = parsed.title || '';
      readabilityContent = parsed.textContent || '';
      readabilityExcerpt = parsed.excerpt || '';
      readabilityByline = parsed.byline || '';
    }
  } catch (err) {
    console.error('Readability extraction failed, falling back to Cheerio:', err);
  }

  // 3. Coordinate best estimates
  const finalTitle = ogTitle || readabilityTitle || $('title').text() || 'No Title';
  const finalDescription = ogDescription || readabilityExcerpt || jsonldDescription || '';
  const finalImage = ogImage || jsonldImage || '';
  const finalAuthor = ogAuthor || readabilityByline || jsonldAuthor || 'Staff';
  
  // Format publish date
  const rawDate = ogPublishDate || jsonldPublishDate;
  let finalPublishDate = new Date().toISOString();
  if (rawDate) {
    try {
      finalPublishDate = new Date(rawDate).toISOString();
    } catch {
      // Ignore invalid date strings
    }
  }

  // Fallback for body content if Readability fails
  let finalContent = readabilityContent.trim();
  if (!finalContent) {
    const paras: string[] = [];
    $('p').each((_, el) => {
      const text = $(el).text().trim();
      if (text.length > 30) {
        paras.push(text);
      }
    });
    finalContent = paras.join('\n\n');
  }

  // Extract source hostname
  let source = '';
  try {
    source = new URL(url).hostname.replace(/^www\./, '');
  } catch {
    source = 'External Web';
  }

  return {
    title: finalTitle.trim(),
    description: finalDescription.trim(),
    image: finalImage.trim(),
    author: finalAuthor.trim(),
    source,
    publishedAt: finalPublishDate,
    content: finalContent,
  };
}
