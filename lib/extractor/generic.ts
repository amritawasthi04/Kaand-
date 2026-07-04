import * as cheerio from 'cheerio';
import { ExtractedArticle } from './types';

export async function extractGeneric(
  html: string, 
  $: cheerio.CheerioAPI, 
  url: string
): Promise<ExtractedArticle> {
  // 1. JSON-LD Extraction
  let jsonld: any = {};
  $('script[type="application/ld+json"]').each((_, el) => {
    try {
      const text = $(el).html()?.trim();
      if (!text) return;
      const parsed = JSON.parse(text);
      const graph = parsed['@graph'] || (Array.isArray(parsed) ? parsed : [parsed]);
      for (const item of graph) {
        if (
          item['@type'] === 'NewsArticle' || 
          item['@type'] === 'Article' || 
          item['@type'] === 'BlogPosting' ||
          item['@type'] === 'ReportageNewsArticle'
        ) {
          jsonld = item;
          break;
        }
      }
      if (!jsonld.headline && (parsed.headline || parsed.name)) {
        jsonld = parsed;
      }
    } catch {
      // Ignore JSON parsing errors for malformed structures
    }
  });

  // 2. OpenGraph / Meta Tag Extraction
  const getMeta = (props: string[]) => {
    for (const p of props) {
      const v = $(`meta[property="${p}"]`).attr('content') || 
                $(`meta[name="${p}"]`).attr('content') ||
                $(`meta[itemprop="${p}"]`).attr('content');
      if (v) return v.trim();
    }
    return '';
  };

  const ogTitle = getMeta(['og:title', 'twitter:title']);
  const ogDescription = getMeta(['og:description', 'description', 'twitter:description']);
  const ogImage = getMeta(['og:image', 'twitter:image', 'thumbnailUrl']);
  const ogAuthor = getMeta(['article:author', 'author', 'twitter:creator']);
  const ogDate = getMeta(['article:published_time', 'publish-date', 'pubdate', 'og:pubdate']);

  // Resolve basic metadata priorities
  const title = ogTitle || jsonld.headline || $('h1').first().text().trim() || $('title').text().trim() || 'No Title';
  const description = ogDescription || jsonld.description || '';
  let finalImage = getMeta(['og:image']) || 
                   getMeta(['twitter:image']) || 
                   (jsonld.image && (typeof jsonld.image === 'string' ? jsonld.image : jsonld.image.url)) || 
                   getMeta(['thumbnailUrl']) ||
                   '';

  if (!finalImage) {
    $('article img, main img, .entry-content img, .post-content img, img').each((_, imgEl) => {
      const src = $(imgEl).attr('src') || $(imgEl).attr('data-src') || $(imgEl).attr('data-lazy-src');
      if (src && src.startsWith('http') && !src.includes('logo') && !src.includes('icon') && !src.includes('pixel')) {
        finalImage = src;
        return false;
      }
    });
  }

  const image = finalImage;
  const author = ogAuthor || 
                 (jsonld.author && (typeof jsonld.author === 'string' ? jsonld.author : jsonld.author.name)) || 
                 'Staff';
  
  const rawDate = ogDate || jsonld.datePublished || new Date().toISOString();
  let publishedAt = new Date().toISOString();
  try {
    publishedAt = new Date(rawDate).toISOString();
  } catch {}

  // 3. Cheerio-based Content Extraction (High-Speed HTML Parser, No Native JSDOM)
  let content = '';
  
  // List of standard article main selectors, ordered by priority
  const articleContainers = [
    'article',
    '[itemprop="articleBody"]',
    '.article-body',
    '.story-body',
    '.entry-content',
    '.post-content',
    '.article__body',
    '.story-content',
    'main',
    '#main-content'
  ];

  for (const container of articleContainers) {
    const el = $(container);
    if (el.length > 0) {
      const paragraphs: string[] = [];
      el.find('p').each((_, pEl) => {
        const txt = $(pEl).text().trim();
        // Exclude short blocks, buttons, and advertisement placeholders
        if (
          txt.length > 30 && 
          !txt.toLowerCase().includes('cookie') && 
          !txt.toLowerCase().includes('subscribe') &&
          !txt.toLowerCase().includes('sign up')
        ) {
          paragraphs.push(txt);
        }
      });
      if (paragraphs.length > 0) {
        content = paragraphs.join('\n\n');
        break;
      }
    }
  }

  // Fallback: extract all p tags in the document if no container matched or content is too short
  if (!content || content.split(/\s+/).filter(Boolean).length < 50) {
    const paragraphs: string[] = [];
    $('p').each((_, el) => {
      const txt = $(el).text().trim();
      if (
        txt.length > 30 && 
        !txt.toLowerCase().includes('cookie') && 
        !txt.toLowerCase().includes('subscribe') &&
        !txt.toLowerCase().includes('sign up')
      ) {
        paragraphs.push(txt);
      }
    });
    content = paragraphs.join('\n\n');
  }

  return {
    title,
    description,
    content: content || description || 'Content unavailable.',
    image,
    author,
    source: new URL(url).hostname.replace(/^www\./, ''),
    publishedAt,
    language: 'en'
  };
}
