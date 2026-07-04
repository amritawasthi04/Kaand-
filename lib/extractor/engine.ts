import axios from 'axios';
import * as cheerio from 'cheerio';
import { getAdapterForUrl } from './registry';
import { cleanHtmlDom, cleanCleanedContent } from './cleaner';
import { extractGeneric } from './generic';
import { scoreExtraction } from './scoring';
import { ExtractedArticle } from './types';
import { recordScrapeMetric } from '../firebase/firestore';

export interface EngineOutput {
  article: ExtractedArticle;
  score: number;
  reasons: string[];
  extractorUsed: string;
}

const USER_AGENTS = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/119.0',
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36',
];

const getRandomUserAgent = () => USER_AGENTS[Math.floor(Math.random() * USER_AGENTS.length)];

/**
 * Resolves a Google News wrapper URL to the final publisher URL by fetching the HTML redirect body
 * or base64 decoding the token.
 */
export async function resolveGoogleNewsUrl(url: string): Promise<string> {
  if (!url.includes('news.google.com')) return url;
  try {
    console.log(`Google News Resolver: attempting to resolve ${url}`);
    
    // First try: parse from base64 token if path is simple
    const segments = new URL(url).pathname.split('/');
    const b64Token = segments[segments.length - 1] || segments[segments.length - 2];
    if (b64Token && b64Token.startsWith('CBM')) {
      try {
        const decoded = Buffer.from(b64Token, 'base64').toString('utf-8');
        const urlMatch = decoded.match(/https?:\/\/[^\s\x00-\x1F\x7F-\x9F\u00A0-\uFFFF]+/);
        if (urlMatch) {
          let decodedUrl = urlMatch[0];
          while (decodedUrl.length > 0 && decodedUrl.charCodeAt(decodedUrl.length - 1) > 126) {
            decodedUrl = decodedUrl.substring(0, decodedUrl.length - 1);
          }
          console.log(`Google News Resolver: Base64 decoded to ${decodedUrl}`);
          return decodedUrl;
        }
      } catch (e) {
        console.warn('Google News Resolver: Base64 decode failed, falling back to HTTP fetch');
      }
    }

    // Second try: request the redirection page and search HTML body for non-google links
    const response = await axios.get(url, {
      headers: {
        'User-Agent': getRandomUserAgent(),
      },
      timeout: 5000,
    });
    
    const html = response.data;
    if (typeof html === 'string') {
      // Look for meta refresh tag
      const metaMatch = html.match(/<meta[^>]+http-equiv="refresh"[^>]+url=([^">\s]+)/i);
      if (metaMatch && metaMatch[1]) {
        let target = metaMatch[1].replace(/['"]/g, '').trim();
        if (target.startsWith('http')) return target;
      }

      // Scan all href strings in HTML body and find the first external non-google link
      const linkMatches = html.match(/href="(https?:\/\/[^"]+)"/g);
      if (linkMatches) {
        for (const matchStr of linkMatches) {
          const cleanUrl = matchStr.substring(6, matchStr.length - 1);
          if (!cleanUrl.includes('google.com') && !cleanUrl.includes('gstatic.com')) {
            console.log(`Google News Resolver: parsed external link ${cleanUrl}`);
            return cleanUrl;
          }
        }
      }
    }
  } catch (err) {
    console.warn('Google News Resolver: Failed to resolve URL, using original:', err);
  }
  return url;
}

/**
 * Robust retry helper with exponential backoff for transient failures
 */
async function fetchWithRetry<T>(
  fn: () => Promise<T>,
  retries = 2,
  delay = 1000
): Promise<T> {
  try {
    return await fn();
  } catch (error: any) {
    const status = error?.response?.status;
    const isTransient = !status || [429, 500, 502, 503, 504].includes(status) || error.code === 'ECONNRESET' || error.message?.includes('timeout');
    if (retries > 0 && isTransient) {
      console.log(`Engine Fetch: transient error encountered. Retrying in ${delay}ms... (${retries} left)`);
      await new Promise((resolve) => setTimeout(resolve, delay));
      return fetchWithRetry(fn, retries - 1, delay * 2);
    }
    throw error;
  }
}

/**
 * progressive multi-stage fetch engine
 */
async function progressiveFetch(url: string, timeoutMs: number): Promise<string> {
  const userAgent = getRandomUserAgent();
  const headers = {
    'User-Agent': userAgent,
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'Accept-Language': 'en-US,en;q=0.9',
    'Accept-Encoding': 'gzip, deflate, br',
    'Cache-Control': 'max-age=0',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'none',
    'Sec-Fetch-User': '?1',
  };

  // Stage 4 support: Scraper Proxy service (via env PROXY_URL or SCRAPER_API_KEY)
  let requestUrl = url;
  if (process.env.SCRAPER_API_KEY) {
    requestUrl = `http://api.scraperapi.com?api_key=${process.env.SCRAPER_API_KEY}&url=${encodeURIComponent(url)}`;
    console.log(`Engine Fetch: Routing through ScraperAPI for ${url}`);
  }

  // Stage 1: Axios + realistic browser headers
  try {
    console.log(`Engine Fetch [Stage 1 - Axios]: downloading ${requestUrl}`);
    const response = await fetchWithRetry(() => axios.get(requestUrl, {
      headers,
      timeout: timeoutMs,
      maxRedirects: 5,
    }));
    if (response.data && typeof response.data === 'string') {
      return response.data;
    }
  } catch (err: any) {
    console.warn(`Engine Fetch: Axios Stage 1 failed (status: ${err?.response?.status || err.code || err.message}). Escalating to Stage 2...`);
  }

  // Stage 2: Node Native Fetch (Undici)
  try {
    console.log(`Engine Fetch [Stage 2 - Native Fetch]: downloading ${requestUrl}`);
    const response = await fetchWithRetry(async () => {
      const res = await fetch(requestUrl, {
        headers,
        signal: AbortSignal.timeout(timeoutMs),
      });
      if (!res.ok) throw new Error(`HTTP error ${res.status}`);
      return res.text();
    });
    if (response) return response;
  } catch (err: any) {
    console.warn(`Engine Fetch: Stage 2 failed (error: ${err.message || err}). Escalating to Stage 3...`);
  }

  // Stage 3: Playwright fallback (Graceful dynamic import)
  try {
    console.log(`Engine Fetch [Stage 3 - Playwright]: launching browser for ${requestUrl}`);
    const { chromium } = require('playwright');
    if (chromium) {
      const browser = await chromium.launch({ headless: true });
      const context = await browser.newContext({ userAgent });
      const page = await context.newPage();
      await page.goto(requestUrl, { waitUntil: 'domcontentloaded', timeout: timeoutMs });
      const html = await page.content();
      await browser.close();
      if (html) return html;
    }
  } catch (err: any) {
    console.warn(`Engine Fetch: Playwright not installed or failed to execute: ${err.message || err}`);
  }

  throw new Error(`Failed to crawl article content across all fetch stages for URL: ${url}`);
}

export async function runExtractionEngine(url: string): Promise<EngineOutput> {
  const start = Date.now();
  let success = false;
  let finalUrl = url;
  let errorMsg = '';

  try {
    // 1. Google News URL redirection resolution
    finalUrl = await resolveGoogleNewsUrl(url);

    const timeoutMs = parseInt(process.env.SCRAPER_TIMEOUT_MS || '', 10) || 8000;
    
    // 2. Fetch HTML using Multi-Stageprogressive fetch
    const html = await progressiveFetch(finalUrl, timeoutMs);
    if (!html || typeof html !== 'string') {
      throw new Error('Target website returned empty or invalid HTML body.');
    }

    // 3. Parse HTML DOM via Cheerio
    const $ = cheerio.load(html);

    // 4. Clean DOM elements
    cleanHtmlDom($);

    const adapter = getAdapterForUrl(finalUrl);
    let article: ExtractedArticle;
    let extractorUsed = 'generic';

    if (adapter) {
      console.log(`Universal Engine: Registry dispatched adapter [${adapter.name}]`);
      try {
        article = await adapter.extract(html, $, finalUrl);
        extractorUsed = adapter.name;
      } catch (err) {
        console.warn(`Universal Engine: Adapter [${adapter.name}] failed, falling back to generic:`, err);
        article = await extractGeneric(html, $, finalUrl);
        extractorUsed = 'generic_fallback';
      }
    } else {
      console.log('Universal Engine: No custom adapter matched. Loading generic pipeline.');
      article = await extractGeneric(html, $, finalUrl);
    }

    // 5. Scorer checks
    let { score, reasons } = scoreExtraction(article);
    console.log(`Universal Engine: [${extractorUsed}] extraction score is ${score}`);

    // Fallback trigger: If custom adapter scored poorly (< 0.6), trigger generic fallback
    if (score < 0.6 && adapter && extractorUsed !== 'generic_fallback') {
      console.log(`Universal Engine: Custom adapter score ${score} below threshold (0.6). Executing generic fallback...`);
      try {
        const fallbackArticle = await extractGeneric(html, $, finalUrl);
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
    success = score >= 0.5;

    // Record health metrics
    const elapsed = Date.now() - start;
    await recordScrapeMetric(success, elapsed);

    return {
      article,
      score,
      reasons,
      extractorUsed,
    };
  } catch (err: any) {
    const elapsed = Date.now() - start;
    errorMsg = err.message || String(err);
    await recordScrapeMetric(false, elapsed, errorMsg);
    throw err;
  }
}

export default runExtractionEngine;
