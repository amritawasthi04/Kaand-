import { JSDOM } from 'jsdom';
import { Readability } from '@mozilla/readability';
import * as cheerio from 'cheerio';
import { Article } from './types';
import { resolveGoogleNewsUrl } from './rss';
import { normalizeSource } from './feeds';

const PUBLISHER_ADAPTERS: Record<string, {
  content?: string[];
  author?: string[];
  title?: string[];
}> = {
  'techcrunch': {
    content: ['.article-content p', '.entry-content p', '.article__content-wrap p'],
    author: ['.article__author-name', '.author-name'],
  },
  'bbc': {
    content: ['article p', '.story-body__inner p', '.story-body p'],
    author: ['.reporter-name', '.author-unit', '.byline__name'],
  },
  'theguardian': {
    content: ['.article-body-commercial-selector p', '.content__article-body p', '#maincontent p'],
    author: ['address a[rel="author"]', '.byline'],
  },
  'nytimes': {
    content: ['section[name="articleBody"] p', '.StoryBodyCompanionColumn p', 'article p'],
    author: ['.g-author', '.byline'],
  }
};

function cleanHtmlText(text: string): string {
  if (!text) return '';
  let cleaned = text.replace(/<(script|style|iframe|form|noscript)[^>]*>[\s\S]*?<\/\1>/gi, '');
  cleaned = cleaned.replace(/<[^>]+>/g, ' ');
  cleaned = cleaned
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&#8217;', "'")
    .replaceAll('&#8220;', '"')
    .replaceAll('&#8221;', '"')
    .replaceAll('&#8212;', '—')
    .replaceAll('&#8216;', "'")
    .replaceAll('&mdash;', '—')
    .replaceAll('&ndash;', '–')
    .replaceAll('&rsquo;', "'")
    .replaceAll('&lsquo;', "'")
    .replaceAll('&ldquo;', '"')
    .replaceAll('&rdquo;', '"');
  cleaned = cleaned.replace(/[ \t]+/g, ' ');
  return cleaned.split('\n').map(line => line.trim()).filter(Boolean).join('\n\n').trim();
}

async function validateImageUrl(url: string): Promise<boolean> {
  if (!url || !url.startsWith('https://')) return false;
  const lower = url.toLowerCase();
  
  // Keyword exclusion criteria
  const exclusions = ['favicon', 'logo', 'sprite', 'placeholder', 'avatar', 'tracker', 'pixel', 'icon', 'ad-', 'ads-'];
  if (exclusions.some(exc => lower.includes(exc))) {
    return false;
  }

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 2000);
    const res = await fetch(url, { method: 'HEAD', signal: controller.signal });
    clearTimeout(timeoutId);
    if (res.ok) {
      const contentType = res.headers.get('content-type') || '';
      if (contentType.startsWith('image/')) {
        const contentLength = parseInt(res.headers.get('content-length') || '0', 10);
        if (contentLength > 1000) {
          return true;
        }
      }
    }
  } catch (_) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 2000);
      const res = await fetch(url, { signal: controller.signal });
      clearTimeout(timeoutId);
      if (res.ok) {
        const contentType = res.headers.get('content-type') || '';
        if (contentType.startsWith('image/')) {
          const buf = await res.arrayBuffer();
          if (buf.byteLength > 1000) {
            return true;
          }
        }
      }
    } catch (_) {}
  }
  return false;
}

export async function extractArticleDetails(articleUrl: string): Promise<Article> {
  const targetUrl = await resolveGoogleNewsUrl(articleUrl);

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 12000);

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

  // Metadata Extraction Helper
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

  const title = cleanHtmlText(getMeta(['og:title', 'twitter:title']) || $('h1').first().text().trim() || 'No Title');
  const description = cleanHtmlText(getMeta(['og:description', 'description', 'twitter:description']));

  // --- Gather Image Candidates by Priority ---
  const candidates: string[] = [];

  // P1: og:image
  const ogImg = getMeta(['og:image']);
  if (ogImg) candidates.push(ogImg);

  // P2: twitter:image
  const twImg = getMeta(['twitter:image']);
  if (twImg) candidates.push(twImg);

  // P3: Schema.org JSON-LD NewsArticle image
  $('script[type="application/ld+json"]').each((_, el) => {
    try {
      const jsonText = $(el).html();
      if (jsonText) {
        const data = JSON.parse(jsonText);
        const items = Array.isArray(data) ? data : [data];
        for (const item of items) {
          if (item['@type'] === 'NewsArticle' || item['@type'] === 'Article') {
            if (typeof item.image === 'string') {
              candidates.push(item.image);
            } else if (item.image && typeof item.image === 'object') {
              if (item.image.url) candidates.push(item.image.url);
            }
          }
        }
      }
    } catch (_) {}
  });

  // P4: link[rel="image_src"]
  const imageSrc = $('link[rel="image_src"]').attr('href');
  if (imageSrc) candidates.push(imageSrc);

  // P6: Body primary images
  $('article img, main img, img').each((_, el) => {
    const src = $(el).attr('src') || $(el).attr('data-src') || '';
    if (src) {
      candidates.push(src);
    }
  });

  // Resolve relative URLs to absolute
  const absoluteCandidates = candidates.map(c => {
    try {
      return new URL(c, targetUrl).href;
    } catch (_) {
      return '';
    }
  }).filter(Boolean);

  // Validate and select top candidate
  let heroImage = '';
  let extractionMethodUsed = 'Fallback Default';
  
  for (let i = 0; i < absoluteCandidates.length; i++) {
    const candidate = absoluteCandidates[i];
    const isValid = await validateImageUrl(candidate);
    if (isValid) {
      heroImage = candidate;
      if (candidate === ogImg) extractionMethodUsed = 'og:image (P1)';
      else if (candidate === twImg) extractionMethodUsed = 'twitter:image (P2)';
      else if (candidate === imageSrc) extractionMethodUsed = 'image_src (P4)';
      else if (candidate.includes('ld+json')) extractionMethodUsed = 'JSON-LD (P3)';
      else extractionMethodUsed = 'Article Body (P6)';
      break;
    }
  }

  // Final fallback default high-res workspace/news placeholder image
  if (!heroImage) {
    heroImage = 'https://images.unsplash.com/photo-1504711434969-e33886168f5c?auto=format&fit=crop&w=1200&q=80';
    extractionMethodUsed = 'Default Fallback Placeholder';
  }

  // Author and Date
  let author = getMeta(['og:author', 'author', 'article:author', 'twitter:creator']);
  const publishedAt = getMeta(['article:published_time', 'pubdate', 'datePublished']) || new Date().toISOString();

  // Tags/Keywords
  const tagsString = getMeta(['keywords', 'news_keywords', 'article:tag']);
  const tags = tagsString ? tagsString.split(',').map(t => cleanHtmlText(t)).filter(Boolean) : [];

  // Canonical URL
  const canonicalUrl = $('link[rel="canonical"]').attr('href') || getMeta(['og:url']) || targetUrl;

  // Language
  const language = ($('html').attr('lang') || 'en').split('-')[0].toLowerCase();

  // Publisher Adapter Matching
  let content = '';
  const domain = new URL(targetUrl).hostname.toLowerCase();
  let matchedAdapterKey = Object.keys(PUBLISHER_ADAPTERS).find(k => domain.includes(k));

  if (matchedAdapterKey) {
    const adapter = PUBLISHER_ADAPTERS[matchedAdapterKey];
    if (adapter.author && !author) {
      for (const sel of adapter.author) {
        const val = $(sel).first().text().trim();
        if (val) {
          author = val;
          break;
        }
      }
    }
    if (adapter.content) {
      const paragraphs: string[] = [];
      for (const sel of adapter.content) {
        $(sel).each((_, el) => {
          const pText = cleanHtmlText($(el).text());
          if (pText.length > 20) {
            paragraphs.push(pText);
          }
        });
        if (paragraphs.length > 0) {
          content = paragraphs.join('\n\n');
          break;
        }
      }
    }
  }

  // Fallback to Readability
  if (!content) {
    try {
      const dom = new JSDOM(html, { url: targetUrl });
      const reader = new Readability(dom.window.document);
      const parsed = reader.parse();
      if (parsed?.textContent?.trim()) {
        content = cleanHtmlText(parsed.textContent);
      }
    } catch (domErr) {
      console.warn(`JSDOM/Readability parsing failed for ${targetUrl}:`, domErr);
      // Cheerio fallback paragraph scraping
      const paragraphs: string[] = [];
      $('p').each((_, el) => {
        const text = cleanHtmlText($(el).text());
        if (text.length > 30) {
          paragraphs.push(text);
        }
      });
      if (paragraphs.length > 0) {
        content = paragraphs.join('\n\n');
      }
    }
  }

  const finalContent = content || description || 'No content extracted.';
  const wordCount = finalContent.split(/\s+/).length;
  const readTime = Math.max(1, Math.ceil(wordCount / 200));

  return {
    title,
    description: description,
    summary: description,
    image: heroImage,
    url: targetUrl,
    canonical_url: canonicalUrl,
    author: author || 'Staff',
    source: normalizeSource(targetUrl),
    publishedAt,
    content: finalContent,
    readTime,
    tags,
    language,
    metadata: {
      og: ogImg ? { 'og:image': ogImg } : undefined,
      twitter: twImg ? { 'twitter:image': twImg } : undefined,
      schema: { extraction_method: extractionMethodUsed }
    }
  };
}
