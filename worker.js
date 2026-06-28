// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Kaand Worker — Production-ready Cloudflare Worker
// Single file. Zero dependencies. V8 isolate runtime.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// ─── CORS HEADERS ────────────────────────────────
const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Content-Type': 'application/json',
};

function json(body, status = 200, extra = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, ...extra },
  });
}

// ─── SCRAPE FETCH HEADERS ────────────────────────
const SCRAPE_HEADERS = {
  'User-Agent':
    'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
  Accept:
    'text/html,application/xhtml+xml,application/xhtml+xml;q=0.9,*/*;q=0.8',
  'Accept-Language': 'en-US,en;q=0.9,hi;q=0.8',
  'Cache-Control': 'no-cache',
};

// ─── SITE EXTRACTORS MAP ─────────────────────────
const SITE_EXTRACTORS = {
  // INDIA GENERAL
  'ndtv.com': ['sp-cn', 'content_text', 'Art-exp'],
  'timesofindia.indiatimes.com': ['ga-headlines', 'artText', '_3YYSt'],
  'hindustantimes.com': ['storyDetails', 'detail'],
  'thehindu.com': ['article', 'storyline'],
  'indianexpress.com': ['full-details', 'pcl-full-content'],
  'indiatoday.in': ['story-right', 'description'],
  'news18.com': ['article_body', 'blog-content'],
  'zeenews.india.com': ['article-body', 'pbody'],
  'aajtak.in': ['story-detail', 'nstory-content'],
  'abplive.com': ['abp-story-detail'],
  'thewire.in': ['entry-content'],
  'theprint.in': ['innerarticle', 'story-content'],
  'scroll.in': ['article-content'],
  'thequint.com': ['story-content'],
  'deccanherald.com': ['articlebodycontent'],
  'telegraphindia.com': ['story-body'],
  'outlookindia.com': ['article-content'],
  'firstpost.com': ['article-content'],
  'wionews.com': ['article__content'],
  'dnaindia.com': ['article-body'],
  'newindianexpress.com': ['article-txt'],
  'mid-day.com': ['article_content'],
  // INDIA BUSINESS
  'livemint.com': ['articleBody', 'lm-story-text'],
  'businesstoday.in': ['story-details'],
  'financialexpress.com': ['content-body-14300012'],
  'moneycontrol.com': ['article_wrapper', 'arti-flow'],
  'economictimes.indiatimes.com': ['artText', 'article_content'],
  'businessstandard.com': ['p-content'],
  'cnbctv18.com': ['article_content'],
  'inc42.com': ['article-content'],
  'ndtvprofit.com': ['sp-cn', 'content_text'],
  // INDIA TECH
  'gadgets360.com': ['article__details', '_3Ogif'],
  '91mobiles.com': ['article-body'],
  'digit.in': ['article-body'],
  'mysmartprice.com': ['entry-content'],
  'bgr.in': ['entry-content'],
  // INDIA SPORTS
  'espncricinfo.com': ['article__body', 'StoryContent'],
  'cricbuzz.com': ['cb-nws-intr'],
  'sportstar.thehindu.com': ['article'],
  'sportskeeda.com': ['article-content'],
  // UK
  'theguardian.com': ['article-body-commercial-selector', 'body'],
  'bbc.com': ['text-block', 'Paragraph'],
  'bbc.co.uk': ['text-block'],
  'independent.co.uk': ['article-body-content'],
  'telegraph.co.uk': ['article-body-content'],
  'ft.com': ['article__content-body'],
  'economist.com': ['article__body'],
  'dailymail.co.uk': ['article-text'],
  'mirror.co.uk': ['article-body'],
  'thesun.co.uk': ['article__content'],
  // USA
  'reuters.com': ['article-body', 'text__text'],
  'apnews.com': ['RichTextStoryBody', 'article'],
  'nytimes.com': ['articleBody'],
  'washingtonpost.com': ['article-body'],
  'cnn.com': ['article__content'],
  'foxnews.com': ['article-body'],
  'nbcnews.com': ['article-body'],
  'abcnews.go.com': ['Article__Content'],
  'cbsnews.com': ['content__body'],
  'usatoday.com': ['gnt_ar_b'],
  'wsj.com': ['article-content'],
  'bloomberg.com': ['body-content'],
  'forbes.com': ['article-body'],
  'time.com': ['article-content'],
  'politico.com': ['story-text'],
  'npr.org': ['storytext'],
  'techcrunch.com': ['article-content'],
  'wired.com': ['ArticleBodyWrapper'],
  'theverge.com': ['duet--article--article-body-component'],
  'arstechnica.com': ['article-content'],
  'engadget.com': ['caas-body'],
  'cnet.com': ['article-body'],
  'axios.com': ['gtm-story-text'],
  'theatlantic.com': ['l-article__content'],
  'vox.com': ['c-entry-content'],
  'huffpost.com': ['entry__content'],
  'thehill.com': ['article__text'],
  // GLOBAL
  'aljazeera.com': ['wysiwyg', 'article-p-wrapper'],
  'dw.com': ['article__content', 'rich-text'],
  'france24.com': ['t-content__body'],
  'euronews.com': ['c-article-content'],
  'scmp.com': ['article-content'],
  'straitstimes.com': ['article-content'],
  'channelnewsasia.com': ['text-long'],
  'dawn.com': ['story__content'],
  'thedailystar.net': ['field-body'],
  'haaretz.com': ['ArticleBody'],
  'timesofisrael.com': ['the-content'],
  'arabnews.com': ['field-body'],
  'news24.com': ['article__body'],
  'smh.com.au': ['article-body'],
  'abc.net.au': ['article-content'],
  'cbc.ca': ['story', 'detailMainContent'],
  'globeandmail.com': ['c-article-body'],
  'japantimes.co.jp': ['article-content'],
};

// ─── NOISE PATTERNS ──────────────────────────────
const NOISE_PATTERNS = [
  /^(by |new delhi|mumbai|kolkata|chennai|bengaluru|hyderabad)/i,
  /^(reuters|pti|ani|ians|afp|ap |staff reporter|our correspondent)/i,
  /(subscribe|cookie policy|javascript required|sign in to read)/i,
  /(all rights reserved|terms of use|privacy policy)/i,
  /^(updated:|published:|last modified:)/i,
  /^\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}/,
  /(enable javascript|browser not supported)/i,
];

// ─── IMAGE REJECT PATTERN ────────────────────────
const IMAGE_REJECT =
  /logo|icon|favicon|avatar|placeholder|spinner|loading|pixel|tracking|beacon|blank\.gif|spacer|1x1|transparent|gstatic\.com/i;

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TEXT UTILITIES
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function decodeEntities(str) {
  return str
    .replace(/&nbsp;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>')
    .replace(/&quot;/gi, '"')
    .replace(/&#39;/gi, "'")
    .replace(/&mdash;/gi, '—')
    .replace(/&ndash;/gi, '–')
    .replace(/&hellip;/gi, '…');
}

function stripTags(html) {
  return html.replace(/<[^>]*>/g, '');
}

function cleanText(html) {
  if (!html) return '';
  let t = stripTags(html);
  t = decodeEntities(t);
  t = t.replace(/\s+/g, ' ').trim();
  return t;
}

function stripCdata(str) {
  return str.replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1');
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// HTML NOISE STRIPPING
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function stripNoiseTags(html) {
  const noiseTags = [
    'script', 'style', 'nav', 'header', 'footer', 'aside',
    'form', 'button', 'iframe', 'noscript', 'figure',
    'figcaption', 'svg', 'template', 'dialog',
  ];
  let cleaned = html;
  for (const tag of noiseTags) {
    const re = new RegExp(
      `<${tag}[\\s>][\\s\\S]*?<\\/${tag}>`,
      'gi'
    );
    cleaned = cleaned.replace(re, '');
  }
  // Remove HTML comments
  cleaned = cleaned.replace(/<!--[\s\S]*?-->/g, '');
  return cleaned;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// RSS PARSER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function parseRss(xml) {
  const items = [];
  const itemRegex = /<item>([\s\S]*?)<\/item>/gi;
  let match;
  while ((match = itemRegex.exec(xml)) !== null && items.length < 20) {
    const block = match[1];

    // title
    let title = '';
    const titleMatch = block.match(/<title>([\s\S]*?)<\/title>/i);
    if (titleMatch) {
      title = cleanText(stripCdata(titleMatch[1]));
    }

    // link
    let link = '';
    const linkMatch = block.match(/<link>([\s\S]*?)<\/link>/i);
    if (linkMatch) {
      link = cleanText(stripCdata(linkMatch[1]));
    }

    // pubDate
    let pubDate = '';
    const pubMatch = block.match(/<pubDate>([\s\S]*?)<\/pubDate>/i);
    if (pubMatch) {
      pubDate = cleanText(stripCdata(pubMatch[1]));
    }

    // source
    let source = 'Google News';
    const srcMatch = block.match(/<source[^>]*>([\s\S]*?)<\/source>/i);
    if (srcMatch) {
      source = cleanText(stripCdata(srcMatch[1]));
    }

    // Strip " - Source Name" suffix from title
    const suffix = ` - ${source}`;
    if (title.endsWith(suffix)) {
      title = title.slice(0, -suffix.length);
    }

    items.push({ title, link, pubDate, source });
  }
  return items;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// REDIRECT RESOLVER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

async function resolveRedirect(url) {
  if (!url.includes('news.google.com')) return url;
  try {
    const resp = await fetch(url, {
      redirect: 'follow',
      headers: SCRAPE_HEADERS,
      signal: AbortSignal.timeout(5000),
    });
    return resp.url || url;
  } catch {
    return url;
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// IMAGE EXTRACTOR
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function isValidImageUrl(url) {
  if (!url || typeof url !== 'string') return false;
  const trimmed = url.trim();
  if (!trimmed) return false;
  if (
    !trimmed.startsWith('http://') &&
    !trimmed.startsWith('https://') &&
    !trimmed.startsWith('//')
  )
    return false;
  if (trimmed.endsWith('.svg')) return false;
  if (IMAGE_REJECT.test(trimmed)) return false;
  return true;
}

function normalizeImageUrl(url) {
  if (!url) return null;
  let u = url.trim();
  if (u.startsWith('//')) u = 'https:' + u;
  return u;
}

function extractImage(html) {
  // 1. JSON-LD
  const ldBlocks = [];
  const ldRegex =
    /<script[^>]*type\s*=\s*["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;
  let ldMatch;
  while ((ldMatch = ldRegex.exec(html)) !== null) {
    ldBlocks.push(ldMatch[1]);
  }
  for (const block of ldBlocks) {
    try {
      const parsed = JSON.parse(block);
      const objects = [];
      if (parsed['@graph'] && Array.isArray(parsed['@graph'])) {
        objects.push(...parsed['@graph']);
      } else {
        objects.push(parsed);
      }
      for (const obj of objects) {
        const candidates = [
          obj.image?.url,
          typeof obj.image === 'string' ? obj.image : null,
          Array.isArray(obj.image) && typeof obj.image[0] === 'string'
            ? obj.image[0]
            : null,
          Array.isArray(obj.image) && obj.image[0]?.url
            ? obj.image[0].url
            : null,
          obj.thumbnailUrl,
        ];
        for (const c of candidates) {
          if (isValidImageUrl(c)) return normalizeImageUrl(c);
        }
      }
    } catch {
      // ignore malformed JSON-LD
    }
  }

  // 2. og:image
  const ogMatch = html.match(
    /<meta[^>]*property\s*=\s*["']og:image["'][^>]*content\s*=\s*["']([^"']+)["'][^>]*\/?>/i
  ) || html.match(
    /<meta[^>]*content\s*=\s*["']([^"']+)["'][^>]*property\s*=\s*["']og:image["'][^>]*\/?>/i
  );
  if (ogMatch && isValidImageUrl(ogMatch[1])) {
    return normalizeImageUrl(ogMatch[1]);
  }

  // 3. twitter:image
  const twMatch = html.match(
    /<meta[^>]*(?:name|property)\s*=\s*["']twitter:image["'][^>]*content\s*=\s*["']([^"']+)["'][^>]*\/?>/i
  ) || html.match(
    /<meta[^>]*content\s*=\s*["']([^"']+)["'][^>]*(?:name|property)\s*=\s*["']twitter:image["'][^>]*\/?>/i
  );
  if (twMatch && isValidImageUrl(twMatch[1])) {
    return normalizeImageUrl(twMatch[1]);
  }

  return null;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PARAGRAPH EXTRACTION
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function extractParagraphs(html) {
  const paras = [];
  const pRegex = /<p[^>]*>([\s\S]*?)<\/p>/gi;
  let m;
  while ((m = pRegex.exec(html)) !== null) {
    const text = cleanText(m[1]);
    if (text.length >= 30) paras.push(text);
  }
  return paras;
}

function getDomainKey(url) {
  try {
    const host = new URL(url).hostname.replace(/^www\./, '');
    // check exact match first
    if (SITE_EXTRACTORS[host]) return host;
    // check if a parent domain matches (e.g. sportstar.thehindu.com → thehindu.com)
    const parts = host.split('.');
    for (let i = 1; i < parts.length - 1; i++) {
      const parent = parts.slice(i).join('.');
      if (SITE_EXTRACTORS[parent]) return parent;
    }
    return null;
  } catch {
    return null;
  }
}

function extractSiteSpecificParagraphs(html, classHints) {
  const allParas = [];
  for (const hint of classHints) {
    // Build a regex that finds elements whose class or id contains the hint,
    // then grabs the inner content to find <p> tags within.
    const escaped = hint.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const containerRegex = new RegExp(
      `<(?:div|section|article|main)[^>]*(?:class|id)\\s*=\\s*["'][^"']*${escaped}[^"']*["'][^>]*>([\\s\\S]*?)(?=<\\/(?:div|section|article|main)>)`,
      'gi'
    );
    let cm;
    while ((cm = containerRegex.exec(html)) !== null) {
      const paras = extractParagraphs(cm[1]);
      allParas.push(...paras);
    }
  }
  return allParas;
}

function extractUniversalParagraphs(html) {
  const cleaned = stripNoiseTags(html);

  // 1. <article> tags
  const articleMatch = cleaned.match(/<article[^>]*>([\s\S]*?)<\/article>/i);
  if (articleMatch) {
    const p = extractParagraphs(articleMatch[1]);
    if (p.length >= 2) return p;
  }

  // 2. itemprop="articleBody"
  const itemPropMatch = cleaned.match(
    /<[^>]*itemprop\s*=\s*["']articleBody["'][^>]*>([\s\S]*?)<\/(?:div|section|article)>/i
  );
  if (itemPropMatch) {
    const p = extractParagraphs(itemPropMatch[1]);
    if (p.length >= 2) return p;
  }

  // 3. Common content class names
  const contentClasses = [
    'article-body', 'article__body', 'story-body', 'post-content',
    'entry-content', 'content-body', 'article-content', 'main-content',
  ];
  for (const cls of contentClasses) {
    const escaped = cls.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const re = new RegExp(
      `<[^>]*class\\s*=\\s*["'][^"']*${escaped}[^"']*["'][^>]*>([\\s\\S]*?)<\\/(?:div|section|article|main)>`,
      'gi'
    );
    const m = re.exec(cleaned);
    if (m) {
      const p = extractParagraphs(m[1]);
      if (p.length >= 2) return p;
    }
  }

  // 4. <main> tag
  const mainMatch = cleaned.match(/<main[^>]*>([\s\S]*?)<\/main>/i);
  if (mainMatch) {
    const p = extractParagraphs(mainMatch[1]);
    if (p.length >= 2) return p;
  }

  // 5. All <p> from full body, skip first 2
  const all = extractParagraphs(cleaned);
  if (all.length > 2) return all.slice(2);
  return all;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DESCRIPTION SCORING
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function jaccard(a, b) {
  if (!a || !b) return 0;
  const setA = new Set(a.toLowerCase().split(/\s+/).filter(Boolean));
  const setB = new Set(b.toLowerCase().split(/\s+/).filter(Boolean));
  if (setA.size === 0 || setB.size === 0) return 0;
  let intersection = 0;
  for (const w of setA) {
    if (setB.has(w)) intersection++;
  }
  return intersection / (setA.size + setB.size - intersection);
}

function isNoise(text) {
  for (const p of NOISE_PATTERNS) {
    if (p.test(text)) return true;
  }
  return false;
}

function scoreCandidate(text, sourceBonus, title) {
  if (!text || text.length < 60) return 0;
  if (isNoise(text)) return 0;

  let score = sourceBonus;

  // Length scoring
  if (text.length >= 100 && text.length <= 350) score += 30;
  else if (text.length >= 60 && text.length <= 99) score += 15;
  else if (text.length > 350) score += 10;

  // Jaccard similarity vs title
  const sim = jaccard(text, title);
  if (sim > 0.65) return 0; // headline clone
  if (sim < 0.25) score += 20;

  // Sentence structure
  if (/[.?!]\s[A-Z]/.test(text)) score += 15;

  // Contains digit
  if (/\d/.test(text)) score += 10;

  // Word count > 15
  if (text.split(/\s+/).length > 15) score += 10;

  return score;
}

function extractMetaContent(html, nameOrProp, value) {
  // Try property="value" content="..." first
  const r1 = new RegExp(
    `<meta[^>]*(?:${nameOrProp})\\s*=\\s*["']${value}["'][^>]*content\\s*=\\s*["']([^"']+)["'][^>]*\\/?>`,
    'i'
  );
  const m1 = r1.exec(html);
  if (m1) return cleanText(m1[1]);

  // Try content="..." property="value"
  const r2 = new RegExp(
    `<meta[^>]*content\\s*=\\s*["']([^"']+)["'][^>]*(?:${nameOrProp})\\s*=\\s*["']${value}["'][^>]*\\/?>`,
    'i'
  );
  const m2 = r2.exec(html);
  if (m2) return cleanText(m2[1]);

  return null;
}

function extractBestDescription(html, title, resolvedUrl) {
  const candidates = [];

  // 1. JSON-LD description / abstract
  const ldRegex =
    /<script[^>]*type\s*=\s*["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;
  let ldMatch;
  while ((ldMatch = ldRegex.exec(html)) !== null) {
    try {
      const parsed = JSON.parse(ldMatch[1]);
      const objects = [];
      if (parsed['@graph'] && Array.isArray(parsed['@graph'])) {
        objects.push(...parsed['@graph']);
      } else {
        objects.push(parsed);
      }
      for (const obj of objects) {
        if (obj.description) {
          candidates.push({ text: cleanText(obj.description), source: 'jsonld' });
        }
        if (obj.abstract) {
          candidates.push({ text: cleanText(obj.abstract), source: 'jsonld' });
        }
      }
    } catch {
      // ignore
    }
  }

  // 2. og:description
  const ogDesc = extractMetaContent(html, 'property', 'og:description');
  if (ogDesc) candidates.push({ text: ogDesc, source: 'og' });

  // 3. twitter:description
  const twDesc = extractMetaContent(html, 'name|property', 'twitter:description');
  if (twDesc) candidates.push({ text: twDesc, source: 'twitter' });

  // 4. meta[name="description"]
  const metaDesc = extractMetaContent(html, 'name', 'description');
  if (metaDesc) candidates.push({ text: metaDesc, source: 'meta' });

  // 5. Body paragraphs
  const cleaned = stripNoiseTags(html);
  let bodyParas = [];

  // Try site-specific first
  const domainKey = getDomainKey(resolvedUrl);
  if (domainKey) {
    bodyParas = extractSiteSpecificParagraphs(cleaned, SITE_EXTRACTORS[domainKey]);
  }
  if (bodyParas.length < 2) {
    bodyParas = extractUniversalParagraphs(html);
  }

  // Skip first paragraph (usually byline/dateline), take paragraphs 2-6
  const bodySlice = bodyParas.length > 1 ? bodyParas.slice(1, 6) : bodyParas;
  for (const p of bodySlice) {
    candidates.push({ text: p, source: 'body' });
  }

  // Score all candidates
  const sourceBonus = { jsonld: 25, og: 20, twitter: 15, meta: 15, body: 10 };
  let best = null;
  let bestScore = 0;

  for (const c of candidates) {
    const s = scoreCandidate(c.text, sourceBonus[c.source] || 0, title);
    if (s > bestScore) {
      bestScore = s;
      best = c.text;
    }
  }

  if (!best || bestScore <= 0) return null;

  // Cap at 350 chars
  if (best.length > 350) {
    const cut = best.lastIndexOf(' ', 350);
    best = best.slice(0, cut > 0 ? cut : 350) + '…';
  }

  return best;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PAGE SCRAPER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

async function scrapePage(url, title) {
  try {
    const resp = await fetch(url, {
      headers: SCRAPE_HEADERS,
      signal: AbortSignal.timeout(5000),
    });
    if (resp.status !== 200) return { imageUrl: null, description: null };

    const html = await resp.text();
    const imageUrl = extractImage(html);
    const description = extractBestDescription(html, title || '', url);

    return { imageUrl, description };
  } catch {
    return { imageUrl: null, description: null };
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ROUTE: /health
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

function handleHealth() {
  return json({ status: 'ok', timestamp: new Date().toISOString() });
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ROUTE: /news
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

async function handleNews(url) {
  const params = url.searchParams;
  const hl = params.get('hl') || 'en-IN';
  const gl = params.get('gl') || 'IN';
  const cat = params.get('cat');
  const q = params.get('q');

  let rssUrl;
  if (q) {
    rssUrl = `https://news.google.com/rss/search?q=${encodeURIComponent(q)}&hl=${hl}&gl=${gl}&ceid=${gl}:en`;
  } else if (cat) {
    rssUrl = `https://news.google.com/rss/headlines/section/topic/${encodeURIComponent(cat)}?hl=${hl}&gl=${gl}&ceid=${gl}:en`;
  } else {
    rssUrl = `https://news.google.com/rss?hl=${hl}&gl=${gl}&ceid=${gl}:en`;
  }

  const proxyUrl = `https://feed2json.org/convert?url=${encodeURIComponent(rssUrl)}`;
  let feedResp;
  try {
    feedResp = await fetch(proxyUrl, {
      signal: AbortSignal.timeout(10000),
      cf: { cacheTtl: 900 },
    });
  } catch (e) {
    return json(
      { error: 'News proxy fetch connection timed out or failed', message: e.message },
      502
    );
  }

  if (feedResp.status !== 200) {
    return json(
      { error: 'News proxy returned non-200 status', status: feedResp.status },
      502
    );
  }

  const data = await feedResp.json();
  const rawItems = data.items || [];
  const items = rawItems.slice(0, 20); // Limit to top 20 items

  // Parse items and extract source/clean title
  const parsedItems = items.map((item) => {
    let source = 'Google News';
    let title = item.title || '';
    const lastHyphen = title.lastIndexOf(' - ');
    if (lastHyphen !== -1) {
      source = title.substring(lastHyphen + 3).trim();
      title = title.substring(0, lastHyphen).trim();
    }
    return {
      title,
      link: item.url || '',
      pubDate: item.date_published || '',
      source,
    };
  });

  // Resolve ALL redirects in parallel (this is fast, just follows headers)
  const redirectResults = await Promise.allSettled(
    parsedItems.map((item) => resolveRedirect(item.link))
  );
  const resolvedUrls = redirectResults.map((r, i) =>
    r.status === 'fulfilled' ? r.value : parsedItems[i].link
  );

  // Scrape ONLY the first 5 pages in parallel to prevent execution timeouts
  const scrapeUrls = resolvedUrls.slice(0, 5);
  const scrapeResults = await Promise.allSettled(
    scrapeUrls.map((u, i) => scrapePage(u, parsedItems[i].title))
  );

  const articles = parsedItems.map((item, i) => {
    let scraped = { imageUrl: null, description: null };
    if (i < 5 && scrapeResults[i] && scrapeResults[i].status === 'fulfilled') {
      scraped = scrapeResults[i].value;
    }
    return {
      title: item.title,
      url: resolvedUrls[i],
      source: item.source,
      publishedAt: item.pubDate,
      imageUrl: scraped.imageUrl,
      description: scraped.description,
    };
  });

  return json(
    { status: 'ok', count: articles.length, articles },
    200,
    { 'Cache-Control': 'public, max-age=900' }
  );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ROUTE: /article
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

async function handleArticle(url) {
  const params = url.searchParams;
  const articleUrl = params.get('url');
  const title = params.get('title') || '';

  if (!articleUrl) {
    return json({ error: 'Missing url parameter' }, 400);
  }

  const resolved = await resolveRedirect(articleUrl);
  const scraped = await scrapePage(resolved, title);

  return json(
    {
      status: 'ok',
      url: resolved,
      imageUrl: scraped.imageUrl,
      description: scraped.description,
    },
    200,
    { 'Cache-Control': 'public, max-age=3600' }
  );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ROUTE: /guardian
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

async function handleGuardian(url, env) {
  const params = url.searchParams;
  const section = params.get('section') || 'world';
  const q = params.get('q');
  const key = params.get('key') || env.GUARDIAN_API_KEY || 'test';

  let apiUrl;
  if (q) {
    apiUrl =
      `https://content.guardianapis.com/search?q=${encodeURIComponent(q)}` +
      `&show-fields=headline,trailText,thumbnail,byline` +
      `&order-by=relevance&page-size=20&api-key=${key}`;
  } else {
    apiUrl =
      `https://content.guardianapis.com/search?section=${encodeURIComponent(section)}` +
      `&show-fields=headline,trailText,thumbnail,byline` +
      `&order-by=newest&page-size=20&api-key=${key}`;
  }

  const resp = await fetch(apiUrl, {
    signal: AbortSignal.timeout(5000),
  });
  if (resp.status !== 200) {
    return json(
      { error: 'Guardian API fetch failed', status: resp.status },
      502
    );
  }

  const data = await resp.json();
  const results = data?.response?.results || [];

  const articles = results.map((item) => {
    const fields = item.fields || {};
    return {
      title: fields.headline || item.webTitle || 'No Title',
      url: item.webUrl || '',
      source: 'The Guardian',
      publishedAt: item.webPublicationDate || '',
      imageUrl: fields.thumbnail || null,
      description: fields.trailText ? cleanText(fields.trailText) : null,
    };
  });

  return json(
    { status: 'ok', count: articles.length, articles },
    200,
    { 'Cache-Control': 'public, max-age=900' }
  );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MAIN ENTRY POINT
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

export default {
  async fetch(request, env) {
    // OPTIONS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS });
    }

    try {
      const url = new URL(request.url);
      const path = url.pathname.replace(/\/+$/, '') || '/';

      switch (path) {
        case '/health':
          return handleHealth();
        case '/news':
          return await handleNews(url);
        case '/article':
          return await handleArticle(url);
        case '/guardian':
          return await handleGuardian(url, env);
        default:
          return json({ error: 'Not found' }, 404);
      }
    } catch (err) {
      return json(
        { error: 'Internal error', message: err.message || 'Unknown' },
        500
      );
    }
  },
};
