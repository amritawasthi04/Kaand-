/**
 * Cloudflare Worker Backend for News Aggregation App (Newstler)
 * Single file implementation, no npm dependencies.
 */

// Hostname mapping for 100+ major news outlets
const SITE_EXTRACTORS = {
  // India General
  'ndtv.com': { body: ['.sp-cn', '.story_body', '#ins_storybody'], skip: 1 },
  'timesofindia.indiatimes.com': { body: ['._story_content', '.article_body', '.story-body'], skip: 1 },
  'indiatimes.com': { body: ['._story_content', '.article_body'], skip: 1 },
  'hindustantimes.com': { body: ['.storyDetail', '.detail', '.storyBody'], skip: 1 },
  'thehindu.com': { body: ['.articleblock', '.article-body-container'], skip: 1 },
  'indianexpress.com': { body: ['.story_details', '#story_details', '.story-body'], skip: 1 },
  'indiatoday.in': { body: ['.story-right', '.story-body', '.description'], skip: 1 },
  'news18.com': { body: ['.article-body', '.article_body'], skip: 1 },
  'zeenews.india.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'aajtak.in': { body: ['.story-detail', '.story-body'], skip: 1 },
  'abplive.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'jagran.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'bhaskar.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'divyabhaskar.co.in': { body: ['.article-body', '.story-body'], skip: 1 },
  'amarujala.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'thewire.in': { body: ['.body-text', '.post-content'], skip: 1 },
  'theprint.in': { body: ['.post-content', '.entry-content'], skip: 1 },
  'scroll.in': { body: ['.article-body', '.story-body'], skip: 1 },
  'thequint.com': { body: ['.story-card-wrapper', '.post-content'], skip: 1 },
  'deccanherald.com': { body: ['.story-body', '.article-body'], skip: 1 },
  'telegraphindia.com': { body: ['.story-body', '.article-body'], skip: 1 },
  'outlookindia.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'firstpost.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'wionews.com': { body: ['.article-body', '.story-body'], skip: 1 },
  // India Business
  'livemint.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'businesstoday.in': { body: ['.story-body', '.article-body'], skip: 1 },
  'financialexpress.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'moneycontrol.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'economictimes.indiatimes.com': { body: ['.artText', '.article-body'], skip: 1 },
  'business-standard.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'cnbctv18.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'inc42.com': { body: ['.article-body', '.story-body'], skip: 1 },
  // India Tech
  'gadgets360.com': { body: ['.content_text', '.story-body'], skip: 1 },
  '91mobiles.com': { body: ['.entry-content', '.story-body'], skip: 1 },
  'digit.in': { body: ['.article-body', '.story-body'], skip: 1 },
  'mysmartprice.com': { body: ['.entry-content', '.story-body'], skip: 1 },
  'bgr.in': { body: ['.entry-content', '.story-body'], skip: 1 },
  // India Sports
  'espncricinfo.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'cricbuzz.com': { body: ['.cb-col-100', '.story-body'], skip: 1 },
  'sportstar.thehindu.com': { body: ['.articleblock', '.article-body-container'], skip: 1 },
  'sportskeeda.com': { body: ['.article-body', '.story-body'], skip: 1 },
  // UK
  'theguardian.com': { body: ['.article-body-commercial-selector', '#maincontent', '.article-body-viewer-wrapper'], skip: 1 },
  'bbc.com': { body: ['.article__body-content', 'article', '.story-body'], skip: 1 },
  'bbc.co.uk': { body: ['.article__body-content', 'article', '.story-body'], skip: 1 },
  'independent.co.uk': { body: ['#main', '.article-body'], skip: 1 },
  'telegraph.co.uk': { body: ['.article-body-text', '.story-body'], skip: 1 },
  'thetimes.co.uk': { body: ['.article-body', '.story-body'], skip: 1 },
  'thesun.co.uk': { body: ['.article-body', '.story-body'], skip: 1 },
  'dailymail.co.uk': { body: ['.article-text', '.story-body'], skip: 1 },
  'ft.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'economist.com': { body: ['.article__body', '.story-body'], skip: 1 },
  // USA
  'reuters.com': { body: ['.article-body__content', '.story-body'], skip: 1 },
  'apnews.com': { body: ['.RichTextStoryBody', '.article-body'], skip: 1 },
  'nytimes.com': { body: ['.StoryBodyCompanionColumn', '.article-body'], skip: 1 },
  'washingtonpost.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'cnn.com': { body: ['.article__content', '.story-body'], skip: 1 },
  'foxnews.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'nbcnews.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'abcnews.go.com': { body: ['.Article__Content', '.story-body'], skip: 1 },
  'cbsnews.com': { body: ['.content__body', '.story-body'], skip: 1 },
  'usatoday.com': { body: ['.gnt_ar_b', '.story-body'], skip: 1 },
  'wsj.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'bloomberg.com': { body: ['.body-copy', '.story-body'], skip: 1 },
  'forbes.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'time.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'politico.com': { body: ['.story-text', '.article-body'], skip: 1 },
  'npr.org': { body: ['.storytext', '.article-body'], skip: 1 },
  'techcrunch.com': { body: ['.article-content', '.entry-content'], skip: 1 },
  'wired.com': { body: ['.body__inner-container', '.article-body'], skip: 1 },
  'theverge.com': { body: ['.duet--article--article-body', '.entry-content'], skip: 1 },
  'arstechnica.com': { body: ['.article-content', '.entry-content'], skip: 1 },
  'engadget.com': { body: ['.article-body', '.entry-content'], skip: 1 },
  'cnet.com': { body: ['.article-body', '.entry-content'], skip: 1 },
  // Global
  'aljazeera.com': { body: ['.wysiwyg', '.article-body'], skip: 1 },
  'dw.com': { body: ['.longText', '.article-body'], skip: 1 },
  'france24.com': { body: ['.t-content__body', '.article-body'], skip: 1 },
  'euronews.com': { body: ['.c-article-content', '.article-body'], skip: 1 },
  'scmp.com': { body: ['.article-details__body', '.story-body'], skip: 1 },
  'straitstimes.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'dawn.com': { body: ['.story__content', '.article-body'], skip: 1 },
  'thedailystar.net': { body: ['.article-body', '.story-body'], skip: 1 },
  'haaretz.com': { body: ['.art-body', '.article-body'], skip: 1 },
  'timesofisrael.com': { body: ['.the-single-content', '.article-body'], skip: 1 },
  'arabnews.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'news24.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'smh.com.au': { body: ['.article__body-primary', '.story-body'], skip: 1 },
  'abc.net.au': { body: ['.yc7pp', '.article-body'], skip: 1 },
  'cbc.ca': { body: ['.story', '.article-body'], skip: 1 },
  // Additional Outlets
  'yahoo.com': { body: ['.caas-body', '.article-body'], skip: 1 },
  'huffpost.com': { body: ['.entry__text', '.article-body'], skip: 1 },
  'thedailybeast.com': { body: ['.Body', '.article-body'], skip: 1 },
  'gizmodo.com': { body: ['.entry-content', '.article-body'], skip: 1 },
  'kotaku.com': { body: ['.entry-content', '.article-body'], skip: 1 },
  'mashable.com': { body: ['.article-body', '.entry-content'], skip: 1 },
  'lifehacker.com': { body: ['.entry-content', '.article-body'], skip: 1 },
  'vox.com': { body: ['.c-entry-content', '.entry-content'], skip: 1 },
  'slate.com': { body: ['.article__body', '.entry-content'], skip: 1 },
  'salon.com': { body: ['.article-body', '.entry-content'], skip: 1 },
  'theatlantic.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'newyorker.com': { body: ['.body', '.article-body'], skip: 1 },
  'politico.eu': { body: ['.story-text', '.article-body'], skip: 1 },
  'news.sky.com': { body: ['.sdc-article-body', '.article-body'], skip: 1 },
  'mirror.co.uk': { body: ['.article-body', '.story-body'], skip: 1 },
  'express.co.uk': { body: ['.article-body', '.story-body'], skip: 1 },
  'dailystar.co.uk': { body: ['.article-body', '.story-body'], skip: 1 },
  'standard.co.uk': { body: ['.article-body', '.story-body'], skip: 1 },
  'theage.com.au': { body: ['.article__body-primary', '.story-body'], skip: 1 },
  'heraldsun.com.au': { body: ['.article-body', '.story-body'], skip: 1 },
  'news.com.au': { body: ['.story-content', '.article-body'], skip: 1 },
  'thestar.com': { body: ['.main-story', '.article-body'], skip: 1 },
  'theglobeandmail.com': { body: ['.article-body', '.story-body'], skip: 1 },
  'nationalpost.com': { body: ['.article-body', '.story-body'], skip: 1 }
};

export default {
  async fetch(request, env, ctx) {
    const urlObj = new URL(request.url);
    
    // Enable CORS
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Content-Type': 'application/json'
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Edge Caching Configuration
    const cache = caches.default;
    const cacheKey = new Request(urlObj.toString(), request);
    
    // Serve from cache if available (except for /health)
    if (urlObj.pathname !== '/health') {
      const cachedResponse = await cache.match(cacheKey);
      if (cachedResponse) {
        return cachedResponse;
      }
    }

    try {
      if (urlObj.pathname === '/health') {
        const responseData = {
          status: 'ok',
          timestamp: new Date().toISOString()
        };
        return new Response(JSON.stringify(responseData), { headers: corsHeaders });
      }

      if (urlObj.pathname === '/news') {
        const hl = urlObj.searchParams.get('hl') || 'en-US';
        const gl = urlObj.searchParams.get('gl') || 'US';
        const cat = urlObj.searchParams.get('cat');
        const q = urlObj.searchParams.get('q');
        
        let rssUrl = `https://news.google.com/rss?hl=${hl}&gl=${gl}&ceid=${gl}:${hl}`;
        if (q) {
          rssUrl = `https://news.google.com/rss/search?q=${encodeURIComponent(q)}&hl=${hl}&gl=${gl}`;
        } else if (cat) {
          rssUrl = `https://news.google.com/news/rss/headlines/section/topic/${cat.toUpperCase()}?hl=${hl}&gl=${gl}`;
        }

        // Fetch RSS Feed with cache TTL 15 minutes on edge
        const rssResponse = await fetch(rssUrl, {
          cf: { cacheTtl: 900 },
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
          }
        });

        if (!rssResponse.ok) {
          return new Response(JSON.stringify({ status: 'error', message: 'Failed to fetch news feed' }), {
            status: rssResponse.status,
            headers: corsHeaders
          });
        }

        const xmlText = await rssResponse.text();
        const rawArticles = parseRssXml(xmlText).slice(0, 20); // Limit to 20 articles

        // Scrape in parallel
        const scrapePromises = rawArticles.map(async (art) => {
          try {
            // 1. Resolve redirect URL (5 seconds timeout)
            const resolvedUrl = await resolveRedirect(art.url, 5000);
            
            // 2. Scrape full content (5 seconds timeout)
            const details = await scrapeArticle(resolvedUrl, art.title, 5000);
            
            return {
              title: art.title,
              url: resolvedUrl,
              source: art.source || details.source || new URL(resolvedUrl).hostname.replace('www.', ''),
              publishedAt: art.publishedAt,
              imageUrl: details.imageUrl || null,
              description: details.description || art.title
            };
          } catch (err) {
            // Fallback if scraping fails for a single article
            return {
              title: art.title,
              url: art.url,
              source: art.source || 'Google News',
              publishedAt: art.publishedAt,
              imageUrl: null,
              description: art.title
            };
          }
        });

        const results = await Promise.allSettled(scrapePromises);
        const articles = results
          .filter(r => r.status === 'fulfilled')
          .map(r => r.value);

        const responseData = {
          status: 'ok',
          count: articles.length,
          articles: articles
        };

        const finalResponse = new Response(JSON.stringify(responseData), { headers: corsHeaders });
        // Cache in Cloudflare Edge for 15 minutes (900 seconds)
        finalResponse.headers.set('Cache-Control', 'public, max-age=900');
        ctx.waitUntil(cache.put(cacheKey, finalResponse.clone()));
        
        return finalResponse;
      }

      if (urlObj.pathname === '/article') {
        const targetUrl = urlObj.searchParams.get('url');
        const title = urlObj.searchParams.get('title') || '';

        if (!targetUrl) {
          return new Response(JSON.stringify({ status: 'error', message: 'Missing url parameter' }), {
            status: 400,
            headers: corsHeaders
          });
        }

        let resolvedUrl = targetUrl;
        if (targetUrl.includes('news.google.com')) {
          resolvedUrl = await resolveRedirect(targetUrl, 5000);
        }

        const details = await scrapeArticle(resolvedUrl, title, 5000);

        const responseData = {
          status: 'ok',
          url: resolvedUrl,
          imageUrl: details.imageUrl || null,
          description: details.description || title
        };

        const finalResponse = new Response(JSON.stringify(responseData), { headers: corsHeaders });
        // Cache article details in Edge for 1 hour (3600 seconds)
        finalResponse.headers.set('Cache-Control', 'public, max-age=3600');
        ctx.waitUntil(cache.put(cacheKey, finalResponse.clone()));
        
        return finalResponse;
      }

      return new Response(JSON.stringify({ status: 'error', message: 'Not found' }), {
        status: 404,
        headers: corsHeaders
      });

    } catch (e) {
      return new Response(JSON.stringify({ status: 'error', message: e.message }), {
        status: 500,
        headers: corsHeaders
      });
    }
  }
};

// --- HELPER FUNCTIONS ---

// Parse RSS XML using regex
function parseRssXml(xml) {
  const articles = [];
  const itemMatches = xml.matchAll(/<item>([\s\S]*?)<\/item>/g);
  for (const match of itemMatches) {
    const itemHtml = match[1];
    const titleMatch = itemHtml.match(/<title>([\s\S]*?)<\/title>/);
    const linkMatch = itemHtml.match(/<link>([\s\S]*?)<\/link>/);
    const pubDateMatch = itemHtml.match(/<pubDate>([\s\S]*?)<\/pubDate>/);
    const sourceMatch = itemHtml.match(/<source[^>]*>([\s\S]*?)<\/source>/);

    if (titleMatch && linkMatch) {
      articles.push({
        title: decodeHtmlEntities(titleMatch[1].replace(/ - [^-]+$/, '').trim()), // Clean trailing source names
        url: linkMatch[1].trim(),
        publishedAt: pubDateMatch ? pubDateMatch[1].trim() : '',
        source: sourceMatch ? decodeHtmlEntities(sourceMatch[1].trim()) : ''
      });
    }
  }
  return articles;
}

// Decode HTML entities
function decodeHtmlEntities(str) {
  if (!str) return '';
  return str
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&apos;/g, "'")
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1')
    .trim();
}

// Resolve Google News redirect URLs via batchexecute
async function resolveRedirect(googleNewsUrl, timeoutMs) {
  try {
    const url = new URL(googleNewsUrl);
    const pathParts = url.pathname.split('/');
    const base64Id = pathParts[pathParts.length - 1];

    if (!base64Id || base64Id === 'articles') {
      return googleNewsUrl; // Fail-safe: return original url
    }

    const controller = new AbortController();
    const id = setTimeout(() => controller.abort(), timeoutMs);

    const reqPayload = `[[["Fbv4je","[\\"garturlreq\\",[[\\"en-US\\",\\"US\\",[\\"FINANCE_TOP_INDICES\\",\\"WEB_TEST_1_0_0\\"],null,null,1,1,\\"US:en\\",null,180,null,null,null,null,null,0,null,null,[1608992183,723341000]],\\"en-US\\",\\"US\\",1,[2,3,4,8],1,0,\\"655000234\\",0,0,null,0],\\"${base64Id}\\]",null,"generic"]]]`;

    const response = await fetch('https://news.google.com/_/DotsSplashUi/data/batchexecute?rpcids=Fbv4je', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8',
        'Referer': 'https://news.google.com/',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      },
      body: new URLSearchParams({ 'f.req': reqPayload }),
      signal: controller.signal
    });

    clearTimeout(id);

    if (!response.ok) return googleNewsUrl;

    const text = await response.text();
    const header = '[\\"garturlres\\",\\"';
    const footer = '\\"';
    
    const startIndex = text.indexOf(header);
    if (startIndex === -1) return googleNewsUrl;
    
    const start = text.substring(startIndex + header.length);
    const endIndex = start.indexOf(footer);
    if (endIndex === -1) return googleNewsUrl;
    
    return start.substring(0, endIndex);
  } catch (e) {
    return googleNewsUrl; // Fallback to original
  }
}

// Scrape article details
async function scrapeArticle(url, title, timeoutMs) {
  try {
    const controller = new AbortController();
    const id = setTimeout(() => controller.abort(), timeoutMs);

    const response = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
      },
      signal: controller.signal
    });

    clearTimeout(id);

    if (!response.ok) return { imageUrl: '', description: title };

    const html = await response.text();
    const hostname = new URL(url).hostname.replace('www.', '');

    // 1. Extract Images
    const ogImage = extractMeta(html, 'og:image');
    const twitterImage = extractMeta(html, 'twitter:image');
    
    const jsonLdBlocks = extractJsonLd(html);
    let jsonLdImage = '';
    let jsonLdDesc = '';
    
    for (const block of jsonLdBlocks) {
      if (!jsonLdImage) jsonLdImage = findImageInJsonLd(block);
      if (!jsonLdDesc) jsonLdDesc = findDescInJsonLd(block);
    }

    const firstBodyImg = extractFirstBodyImg(html);
    const imageUrl = ogImage || twitterImage || jsonLdImage || firstBodyImg || '';

    // 2. Extract and Score Descriptions
    const ogDesc = extractMeta(html, 'og:description');
    const twitterDesc = extractMeta(html, 'twitter:description');
    const metaDesc = extractMeta(html, 'description');
    
    // Find matching site extractor config
    let bodySelectors = null;
    let skipCount = 0;
    
    const matchedKey = Object.keys(SITE_EXTRACTORS).find(k => hostname.endsWith(k));
    if (matchedKey) {
      bodySelectors = SITE_EXTRACTORS[matchedKey].body;
      skipCount = SITE_EXTRACTORS[matchedKey].skip || 0;
    }
    
    const paragraphs = extractParagraphsFromHtml(html, bodySelectors);
    
    // Extract candidates
    const candidates = [];
    if (ogDesc) candidates.push({ source: 'og', text: ogDesc });
    if (twitterDesc) candidates.push({ source: 'twitter', text: twitterDesc });
    if (metaDesc) candidates.push({ source: 'meta', text: metaDesc });
    if (jsonLdDesc) candidates.push({ source: 'jsonld', text: jsonLdDesc });
    
    // Add first few body paragraphs as candidates
    const bodyParagraphs = paragraphs.slice(skipCount, skipCount + 3);
    bodyParagraphs.forEach((p, i) => {
      candidates.push({ source: `body-${i}`, text: p });
    });

    // Score candidates
    let bestDesc = title;
    let highestScore = -999;
    
    for (const cand of candidates) {
      const score = scoreDescription(cand.text, title);
      if (score > highestScore) {
        highestScore = score;
        bestDesc = cand.text;
      }
    }

    // Cap description length at 350 chars
    if (bestDesc.length > 350) {
      bestDesc = bestDesc.substring(0, 347) + '...';
    }

    return {
      imageUrl: imageUrl,
      description: bestDesc
    };

  } catch (e) {
    return { imageUrl: '', description: title };
  }
}

// Extract Meta tags
function extractMeta(html, nameOrProperty) {
  const regex1 = new RegExp(`<meta[^>]+(?:property|name)=["']${nameOrProperty}["'][^>]*content=["']([^"']+)["']`, 'i');
  const match1 = html.match(regex1);
  if (match1) return decodeHtmlEntities(match1[1]);
  
  const regex2 = new RegExp(`<meta[^>]+content=["']([^"']+)["'][^>]+(?:property|name)=["']${nameOrProperty}["']`, 'i');
  const match2 = html.match(regex2);
  if (match2) return decodeHtmlEntities(match2[1]);
  
  return '';
}

// Extract JSON-LD scripts
function extractJsonLd(html) {
  const jsonLdBlocks = [];
  const regex = /<script[^>]+type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;
  let match;
  while ((match = regex.exec(html)) !== null) {
    try {
      const data = JSON.parse(match[1].trim());
      jsonLdBlocks.push(data);
    } catch (e) {
      // Ignore parser errors
    }
  }
  return jsonLdBlocks;
}

function findImageInJsonLd(json) {
  if (!json) return '';
  if (typeof json === 'string') return json;
  if (Array.isArray(json)) {
    for (const item of json) {
      const img = findImageInJsonLd(item);
      if (img) return img;
    }
  }
  if (typeof json === 'object') {
    if (json.image) {
      if (typeof json.image === 'string') return json.image;
      if (Array.isArray(json.image) && json.image.length > 0) return json.image[0];
      if (typeof json.image === 'object' && json.image.url) return json.image.url;
    }
    if (json.thumbnailUrl) return json.thumbnailUrl;
    for (const key of ['@graph', 'publisher', 'author', 'mainEntityOfPage']) {
      if (json[key]) {
        const img = findImageInJsonLd(json[key]);
        if (img) return img;
      }
    }
  }
  return '';
}

function findDescInJsonLd(json) {
  if (!json) return '';
  if (typeof json === 'string') return '';
  if (Array.isArray(json)) {
    for (const item of json) {
      const desc = findDescInJsonLd(item);
      if (desc) return desc;
    }
  }
  if (typeof json === 'object') {
    if (json.description && typeof json.description === 'string') return json.description;
    if (json.articleBody && typeof json.articleBody === 'string') return json.articleBody.substring(0, 300);
    for (const key of ['@graph', 'mainEntityOfPage', 'about']) {
      if (json[key]) {
        const desc = findDescInJsonLd(json[key]);
        if (desc) return desc;
      }
    }
  }
  return '';
}

// Extract first large-looking image from body if no meta image is present
function extractFirstBodyImg(html) {
  const regex = /<img[^>]+src=["']([^"']+)["']/gi;
  let match;
  while ((match = regex.exec(html)) !== null) {
    const src = match[1];
    // Avoid small icons/tracking pixels
    if (src.startsWith('http') && !src.includes('icon') && !src.includes('logo') && !src.includes('pixel') && !src.includes('spacer')) {
      return src;
    }
  }
  return '';
}

// Extract body paragraphs using selectors or fallbacks
function extractParagraphsFromHtml(html, bodySelectors) {
  const selectors = bodySelectors || ['article', '.article-body', '.story-body', '.entry-content', '.post-content', '#article-body', '.body'];
  let bodyHtml = html;
  
  // Try to find the primary content block container
  for (const selector of selectors) {
    let match = null;
    if (selector.startsWith('.')) {
      const className = selector.slice(1);
      const regex = new RegExp(`<div[^>]+class=["'][^"']*(?:${className})[^"']*["'][^>]*>([\\s\\S]*?)<\/div>`, 'i');
      match = html.match(regex);
    } else if (selector.startsWith('#')) {
      const idName = selector.slice(1);
      const regex = new RegExp(`<div[^>]+id=["']${idName}["'][^>]*>([\\s\\S]*?)<\/div>`, 'i');
      match = html.match(regex);
    } else {
      const regex = new RegExp(`<${selector}[^>]*>([\\s\\S]*?)<\/${selector}>`, 'i');
      match = html.match(regex);
    }
    
    if (match && match[1] && match[1].length > 200) {
      bodyHtml = match[1];
      break;
    }
  }
  
  const paragraphs = [];
  const pRegex = /<p[^>]*>([\s\S]*?)<\/p>/gi;
  let pMatch;
  while ((pMatch = pRegex.exec(bodyHtml)) !== null) {
    const text = cleanHtmlText(pMatch[1]);
    if (text.length > 30) {
      paragraphs.push(text);
    }
  }
  
  return paragraphs;
}

function cleanHtmlText(html) {
  return html
    .replace(/<[^>]+>/g, '') // Strip inline HTML
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\s+/g, ' ') // Clean whitespace
    .trim();
}

// Calculate Jaccard similarity between two strings
function calculateJaccardSimilarity(str1, str2) {
  const getWords = (str) => new Set(str.toLowerCase().match(/\b\w+\b/g) || []);
  const words1 = getWords(str1);
  const words2 = getWords(str2);
  
  if (words1.size === 0 || words2.size === 0) return 0;
  
  let intersection = 0;
  for (const word of words1) {
    if (words2.has(word)) intersection++;
  }
  
  const union = words1.size + words2.size - intersection;
  return intersection / union;
}

// Scoring pipeline for descriptions
function scoreDescription(candidate, headline) {
  if (!candidate || typeof candidate !== 'string') return -9999;
  candidate = candidate.trim();
  const len = candidate.length;
  if (len < 20) return -1000;
  
  // 1. Jaccard similarity check (headline clones)
  const similarity = calculateJaccardSimilarity(candidate, headline);
  if (similarity > 0.65) return -9999;
  
  let score = 0;
  
  // 2. Length scoring (80-300 characters is ideal)
  if (len >= 80 && len <= 300) {
    score += 50;
  } else if (len > 300) {
    score += Math.max(0, 50 - (len - 300) * 0.1);
  } else {
    score += Math.max(0, 50 - (80 - len) * 0.5);
  }
  
  // 3. Sentence Structure check
  const startsWithCapital = /^[A-Z"']/.test(candidate);
  const endsWithPunctuation = /[.!?"]$/.test(candidate);
  if (startsWithCapital) score += 10;
  if (endsWithPunctuation) score += 10;
  
  // 4. Noise Pattern checking
  const noisePatterns = [
    /accept\s+cookies/i,
    /cookie\s+policy/i,
    /subscribe\s+to/i,
    /please\s+enable\s+javascript/i,
    /all\s+rights\s+reserved/i,
    /sign\s+in\s+to/i,
    /register\s+now/i,
    /read\s+more/i,
    /photo\s+by/i,
    /written\s+by/i,
    /published\s+by/i
  ];
  
  for (const pattern of noisePatterns) {
    if (pattern.test(candidate)) {
      score -= 100;
    }
  }
  
  // 5. Too many numbers (e.g. list elements or tracking indexes)
  const numberCount = (candidate.match(/\d/g) || []).length;
  if (numberCount > len * 0.1) {
    score -= 20;
  }
  
  return score;
}
