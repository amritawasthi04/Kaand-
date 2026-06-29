import * as cheerio from 'cheerio';
import { JSDOM } from 'jsdom';
import { Readability } from '@mozilla/readability';
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
          item['@type'] === 'BlogPosting'
        ) {
          jsonld = item;
          break;
        }
      }
      if (!jsonld.headline && (parsed.headline || parsed.name)) {
        jsonld = parsed;
      }
    } catch {
      // Ignore json syntax errors
    }
  });

  // 2. OpenGraph & Twitter Metas
  const getMeta = (props: string[]) => {
    for (const p of props) {
      const v = $(`meta[property="${p}"]`).attr('content') || 
                $(`meta[name="${p}"]`).attr('content');
      if (v) return v.trim();
    }
    return '';
  };

  const ogTitle = getMeta(['og:title', 'twitter:title']);
  const ogDescription = getMeta(['og:description', 'description', 'twitter:description']);
  const ogImage = getMeta(['og:image', 'twitter:image', 'thumbnailUrl']);
  const ogAuthor = getMeta(['article:author', 'author', 'twitter:creator']);
  const ogDate = getMeta(['article:published_time', 'publish-date', 'pubdate']);

  // 3. Mozilla Readability Engine over JSDOM
  let readabilityTitle = '';
  let readabilityExcerpt = '';
  let readabilityByline = '';
  let readabilityContent = '';

  try {
    const dom = new JSDOM(html, { url });
    const reader = new Readability(dom.window.document);
    const parsed = reader.parse();
    if (parsed) {
      readabilityTitle = parsed.title || '';
      readabilityExcerpt = parsed.excerpt || '';
      readabilityByline = parsed.byline || '';
      readabilityContent = parsed.textContent || '';
    }
  } catch (err) {
    console.error('Generic Readability execution failed:', err);
  }

  // 4. Resolve Metadata Priorities
  const title = ogTitle || readabilityTitle || $('title').text() || 'No Title';
  const description = ogDescription || readabilityExcerpt || '';
  const image = ogImage || 
                (jsonld.image && (typeof jsonld.image === 'string' ? jsonld.image : jsonld.image.url)) || 
                '';
  const author = ogAuthor || 
                 readabilityByline || 
                 (jsonld.author && (typeof jsonld.author === 'string' ? jsonld.author : jsonld.author.name)) || 
                 'Staff';
  
  const rawDate = ogDate || jsonld.datePublished || new Date().toISOString();
  let publishedAt = new Date().toISOString();
  try {
    publishedAt = new Date(rawDate).toISOString();
  } catch {}

  // 5. Fallback Paragraphs Extraction if Readability Returned Short Content
  let content = readabilityContent.trim();
  if (content.split(/\s+/).filter(Boolean).length < 50) {
    const paras: string[] = [];
    $('p').each((_, el) => {
      const txt = $(el).text().trim();
      if (
        txt.length > 35 && 
        !txt.toLowerCase().includes('cookie') && 
        !txt.toLowerCase().includes('subscribe')
      ) {
        paras.push(txt);
      }
    });
    content = paras.join('\n\n');
  }

  // Resolve source hostname
  let source = 'External Web';
  try {
    source = new URL(url).hostname.replace(/^www\./, '');
  } catch {}

  return {
    title: title.trim(),
    description: description.trim(),
    content,
    image: image.trim(),
    author: author.trim(),
    source,
    publishedAt,
    language: 'en'
  };
}
