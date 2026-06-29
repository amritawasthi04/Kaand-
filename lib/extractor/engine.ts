import axios from 'axios';
import * as cheerio from 'cheerio';
import { getAdapterForUrl } from './registry';
import { cleanHtmlDom, cleanCleanedContent } from './cleaner';
import { extractGeneric } from './generic';
import { scoreExtraction } from './scoring';
import { ExtractedArticle } from './types';

export interface EngineOutput {
  article: ExtractedArticle;
  score: number;
  reasons: string[];
  extractorUsed: string;
}

export async function runExtractionEngine(url: string): Promise<EngineOutput> {
  const headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
  };

  console.log(`Universal Engine: starting crawl for ${url}`);
  
  const response = await axios.get(url, { 
    headers, 
    timeout: 8000,
    maxRedirects: 5,
  });

  const html = response.data;
  if (!html || typeof html !== 'string') {
    throw new Error('Target website returned empty or invalid HTML body.');
  }

  // Parse HTML DOM via Cheerio
  const $ = cheerio.load(html);

  // Clean DOM elements (cookie consent layers, banners, scripts, ads)
  cleanHtmlDom($);

  const adapter = getAdapterForUrl(url);
  let article: ExtractedArticle;
  let extractorUsed = 'generic';

  if (adapter) {
    console.log(`Universal Engine: Registry dispatched adapter [${adapter.name}]`);
    try {
      article = await adapter.extract(html, $, url);
      extractorUsed = adapter.name;
    } catch (err) {
      console.warn(`Universal Engine: Adapter [${adapter.name}] failed, falling back to generic:`, err);
      article = await extractGeneric(html, $, url);
      extractorUsed = 'generic_fallback';
    }
  } else {
    console.log('Universal Engine: No custom adapter matched. Loading generic pipeline.');
    article = await extractGeneric(html, $, url);
  }

  // Scorer checks
  let { score, reasons } = scoreExtraction(article);
  console.log(`Universal Engine: [${extractorUsed}] extraction score is ${score}`);

  // Fallback trigger: If custom adapter scored poorly (< 0.6), trigger generic fallback
  if (score < 0.6 && adapter && extractorUsed !== 'generic_fallback') {
    console.log(`Universal Engine: Custom adapter score ${score} below threshold (0.6). Executing generic fallback...`);
    try {
      const fallbackArticle = await extractGeneric(html, $, url);
      const fallbackMetrics = scoreExtraction(fallbackArticle);
      if (fallbackMetrics.score > score) {
        article = fallbackArticle;
        score = fallbackMetrics.score;
        reasons = fallbackMetrics.reasons;
        extractorUsed = 'generic_fallback';
        console.log(`Universal Engine: Generic fallback improved quality score to ${score}`);
      }
    } catch (err) {
      console.error('Universal Engine: Generic fallback parser crashed:', err);
    }
  }

  // Normalise final body block spacings
  article.content = cleanCleanedContent(article.content);

  return {
    article,
    score,
    reasons,
    extractorUsed,
  };
}
export default runExtractionEngine;
