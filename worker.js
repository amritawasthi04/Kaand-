var __defProp = Object.defineProperty;
var __name = (target, value) => __defProp(target, "name", { value, configurable: true });

// worker.js
var CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
  "Content-Type": "application/json"
};
function json(body, status = 200, extra = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, ...extra }
  });
}
__name(json, "json");
var SCRAPE_HEADERS = {
  "User-Agent": "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
  Accept: "text/html,application/xhtml+xml,application/xhtml+xml;q=0.9,*/*;q=0.8",
  "Accept-Language": "en-US,en;q=0.9,hi;q=0.8",
  "Cache-Control": "no-cache"
};
var SITE_EXTRACTORS = {
  // INDIA GENERAL
  "ndtv.com": ["sp-cn", "content_text", "Art-exp"],
  "timesofindia.indiatimes.com": ["ga-headlines", "artText", "_3YYSt"],
  "hindustantimes.com": ["storyDetails", "detail"],
  "thehindu.com": ["article", "storyline"],
  "indianexpress.com": ["full-details", "pcl-full-content"],
  "indiatoday.in": ["story-right", "description"],
  "news18.com": ["article_body", "blog-content"],
  "zeenews.india.com": ["article-body", "pbody"],
  "aajtak.in": ["story-detail", "nstory-content"],
  "abplive.com": ["abp-story-detail"],
  "thewire.in": ["entry-content"],
  "theprint.in": ["innerarticle", "story-content"],
  "scroll.in": ["article-content"],
  "thequint.com": ["story-content"],
  "deccanherald.com": ["articlebodycontent"],
  "telegraphindia.com": ["story-body"],
  "outlookindia.com": ["article-content"],
  "firstpost.com": ["article-content"],
  "wionews.com": ["article__content"],
  "dnaindia.com": ["article-body"],
  "newindianexpress.com": ["article-txt"],
  "mid-day.com": ["article_content"],
  // INDIA BUSINESS
  "livemint.com": ["articleBody", "lm-story-text"],
  "businesstoday.in": ["story-details"],
  "financialexpress.com": ["content-body-14300012"],
  "moneycontrol.com": ["article_wrapper", "arti-flow"],
  "economictimes.indiatimes.com": ["artText", "article_content"],
  "businessstandard.com": ["p-content"],
  "cnbctv18.com": ["article_content"],
  "inc42.com": ["article-content"],
  "ndtvprofit.com": ["sp-cn", "content_text"],
  // INDIA TECH
  "gadgets360.com": ["article__details", "_3Ogif"],
  "91mobiles.com": ["article-body"],
  "digit.in": ["article-body"],
  "mysmartprice.com": ["entry-content"],
  "bgr.in": ["entry-content"],
  // INDIA SPORTS
  "espncricinfo.com": ["article__body", "StoryContent"],
  "cricbuzz.com": ["cb-nws-intr"],
  "sportstar.thehindu.com": ["article"],
  "sportskeeda.com": ["article-content"],
  // UK
  "theguardian.com": ["article-body-commercial-selector", "body"],
  "bbc.com": ["text-block", "Paragraph"],
  "bbc.co.uk": ["text-block"],
  "independent.co.uk": ["article-body-content"],
  "telegraph.co.uk": ["article-body-content"],
  "ft.com": ["article__content-body"],
  "economist.com": ["article__body"],
  "dailymail.co.uk": ["article-text"],
  "mirror.co.uk": ["article-body"],
  "thesun.co.uk": ["article__content"],
  // USA
  "reuters.com": ["article-body", "text__text"],
  "apnews.com": ["RichTextStoryBody", "article"],
  "nytimes.com": ["articleBody"],
  "washingtonpost.com": ["article-body"],
  "cnn.com": ["article__content"],
  "foxnews.com": ["article-body"],
  "nbcnews.com": ["article-body"],
  "abcnews.go.com": ["Article__Content"],
  "cbsnews.com": ["content__body"],
  "usatoday.com": ["gnt_ar_b"],
  "wsj.com": ["article-content"],
  "bloomberg.com": ["body-content"],
  "forbes.com": ["article-body"],
  "time.com": ["article-content"],
  "politico.com": ["story-text"],
  "npr.org": ["storytext"],
  "techcrunch.com": ["article-content"],
  "wired.com": ["ArticleBodyWrapper"],
  "theverge.com": ["duet--article--article-body-component"],
  "arstechnica.com": ["article-content"],
  "engadget.com": ["caas-body"],
  "cnet.com": ["article-body"],
  "axios.com": ["gtm-story-text"],
  "theatlantic.com": ["l-article__content"],
  "vox.com": ["c-entry-content"],
  "huffpost.com": ["entry__content"],
  "thehill.com": ["article__text"],
  // GLOBAL
  "aljazeera.com": ["wysiwyg", "article-p-wrapper"],
  "dw.com": ["article__content", "rich-text"],
  "france24.com": ["t-content__body"],
  "euronews.com": ["c-article-content"],
  "scmp.com": ["article-content"],
  "straitstimes.com": ["article-content"],
  "channelnewsasia.com": ["text-long"],
  "dawn.com": ["story__content"],
  "thedailystar.net": ["field-body"],
  "haaretz.com": ["ArticleBody"],
  "timesofisrael.com": ["the-content"],
  "arabnews.com": ["field-body"],
  "news24.com": ["article__body"],
  "smh.com.au": ["article-body"],
  "abc.net.au": ["article-content"],
  "cbc.ca": ["story", "detailMainContent"],
  "globeandmail.com": ["c-article-body"],
  "japantimes.co.jp": ["article-content"]
};
var NOISE_PATTERNS = [
  /^(by |new delhi|mumbai|kolkata|chennai|bengaluru|hyderabad)/i,
  /^(reuters|pti|ani|ians|afp|ap |staff reporter|our correspondent)/i,
  /(subscribe|cookie policy|javascript required|sign in to read)/i,
  /(all rights reserved|terms of use|privacy policy)/i,
  /^(updated:|published:|last modified:)/i,
  /^\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}/,
  /(enable javascript|browser not supported)/i
];
var IMAGE_REJECT = /logo|icon|favicon|avatar|placeholder|spinner|loading|pixel|tracking|beacon|blank\.gif|spacer|1x1|transparent|gstatic\.com/i;
function decodeEntities(str) {
  return str.replace(/&nbsp;/gi, " ").replace(/&amp;/gi, "&").replace(/&lt;/gi, "<").replace(/&gt;/gi, ">").replace(/&quot;/gi, '"').replace(/&#39;/gi, "'").replace(/&mdash;/gi, "\u2014").replace(/&ndash;/gi, "\u2013").replace(/&hellip;/gi, "\u2026");
}
__name(decodeEntities, "decodeEntities");
function stripTags(html) {
  return html.replace(/<[^>]*>/g, "");
}
__name(stripTags, "stripTags");
function cleanText(html) {
  if (!html)
    return "";
  let t = stripTags(html);
  t = decodeEntities(t);
  t = t.replace(/\s+/g, " ").trim();
  return t;
}
__name(cleanText, "cleanText");
function stripNoiseTags(html) {
  const noiseTags = [
    "script",
    "style",
    "nav",
    "header",
    "footer",
    "aside",
    "form",
    "button",
    "iframe",
    "noscript",
    "figure",
    "figcaption",
    "svg",
    "template",
    "dialog"
  ];
  let cleaned = html;
  for (const tag of noiseTags) {
    const re = new RegExp(
      `<${tag}[\\s>][\\s\\S]*?<\\/${tag}>`,
      "gi"
    );
    cleaned = cleaned.replace(re, "");
  }
  cleaned = cleaned.replace(/<!--[\s\S]*?-->/g, "");
  return cleaned;
}
__name(stripNoiseTags, "stripNoiseTags");
async function resolveRedirect(url) {
  if (!url.includes("news.google.com"))
    return url;
  try {
    return await decodeGoogleNewsUrl(url);
  } catch {
    return url;
  }
}
__name(resolveRedirect, "resolveRedirect");
async function decodeGoogleNewsUrl(articleUrl) {
  try {
    const parsedUrl = new URL(articleUrl);
    const pathParts = parsedUrl.pathname.split("/");
    const articlesIdx = pathParts.indexOf("articles");
    if (articlesIdx === -1 || articlesIdx + 1 >= pathParts.length)
      return articleUrl;
    const base64 = pathParts[articlesIdx + 1];
    if (!base64)
      return articleUrl;
    let str;
    try {
      let base64Standard = base64.replace(/-/g, "+").replace(/_/g, "/");
      while (base64Standard.length % 4) {
        base64Standard += "=";
      }
      str = atob(base64Standard);
    } catch {
      return articleUrl;
    }
    const prefix = String.fromCharCode(8, 19, 34);
    if (str.startsWith(prefix)) {
      str = str.substring(prefix.length);
    } else if (str.charCodeAt(0) === 8) {
      str = str.substring(1);
    }
    const suffix = String.fromCharCode(210, 1, 0);
    if (str.endsWith(suffix)) {
      str = str.substring(0, str.length - suffix.length);
    }
    if (str.length === 0)
      return articleUrl;
    const len = str.charCodeAt(0);
    if (len >= 128) {
      str = str.substring(2, len + 2);
    } else {
      str = str.substring(1, len + 1);
    }
    if (str.startsWith("AU_yqL")) {
      return await fetchDecodedBatchExecute(base64, articleUrl);
    }
    if (str.startsWith("http://") || str.startsWith("https://")) {
      return str;
    }
    return articleUrl;
  } catch {
    return articleUrl;
  }
}
__name(decodeGoogleNewsUrl, "decodeGoogleNewsUrl");
async function fetchDecodedBatchExecute(id, defaultUrl) {
  try {
    const innerPayload = [
      "garturlreq",
      [
        ["en-US", "US", ["FINANCE_TOP_INDICES", "WEB_TEST_1_0_0"], null, null, 1, 1, "US:en", null, 180, null, null, null, null, null, 0, null, null, [1608992183, 723341e3]],
        "en-US",
        "US",
        1,
        [2, 3, 4, 8],
        1,
        0,
        "655000234",
        0,
        0,
        null,
        0
      ],
      id
    ];
    const outerPayload = [[[
      "Fbv4je",
      JSON.stringify(innerPayload),
      null,
      "generic"
    ]]];
    const resp = await fetch(
      "https://news.google.com/_/DotsSplashUi/data/batchexecute?rpcids=Fbv4je",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded;charset=utf-8",
          Referer: "https://news.google.com/",
          "User-Agent": SCRAPE_HEADERS["User-Agent"]
        },
        body: "f.req=" + encodeURIComponent(JSON.stringify(outerPayload)),
        signal: AbortSignal.timeout(5e3)
      }
    );
    if (resp.status !== 200)
      return defaultUrl;
    const text = await resp.text();
    const header = '[\\"garturlres\\",\\"';
    const footer = '\\",';
    if (!text.includes(header)) {
      return defaultUrl;
    }
    const startIdx = text.indexOf(header) + header.length;
    const start = text.substring(startIdx);
    const endIdx = start.indexOf(footer);
    if (endIdx === -1)
      return defaultUrl;
    let resolvedUrl = start.substring(0, endIdx);
    resolvedUrl = resolvedUrl.replace(/\\\//g, "/");
    return resolvedUrl;
  } catch {
    return defaultUrl;
  }
}
__name(fetchDecodedBatchExecute, "fetchDecodedBatchExecute");
function isValidImageUrl(url) {
  if (!url || typeof url !== "string")
    return false;
  const trimmed = url.trim();
  if (!trimmed)
    return false;
  if (!trimmed.startsWith("http://") && !trimmed.startsWith("https://") && !trimmed.startsWith("//"))
    return false;
  if (trimmed.endsWith(".svg"))
    return false;
  if (IMAGE_REJECT.test(trimmed))
    return false;
  return true;
}
__name(isValidImageUrl, "isValidImageUrl");
function normalizeImageUrl(url) {
  if (!url)
    return null;
  let u = url.trim();
  if (u.startsWith("//"))
    u = "https:" + u;
  return u;
}
__name(normalizeImageUrl, "normalizeImageUrl");
function extractImage(html) {
  const ldBlocks = [];
  const ldRegex = /<script[^>]*type\s*=\s*["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;
  let ldMatch;
  while ((ldMatch = ldRegex.exec(html)) !== null) {
    if (ldMatch[1]) {
      try {
        const parsed = JSON.parse(ldMatch[1]);
        const objects = [];
        if (parsed["@graph"] && Array.isArray(parsed["@graph"])) {
          objects.push(...parsed["@graph"]);
        } else {
          objects.push(parsed);
        }
        for (const obj of objects) {
          const candidates = [
            obj.image?.url,
            typeof obj.image === "string" ? obj.image : null,
            Array.isArray(obj.image) && typeof obj.image[0] === "string" ? obj.image[0] : null,
            Array.isArray(obj.image) && obj.image[0]?.url ? obj.image[0].url : null,
            obj.thumbnailUrl
          ];
          for (const c of candidates) {
            if (isValidImageUrl(c))
              return normalizeImageUrl(c);
          }
        }
      } catch {
      }
    }
  }
  const ogMatch = html.match(
    /<meta[^>]*property\s*=\s*["']og:image["'][^>]*content\s*=\s*["']([^"']+)["'][^>]*\/?>/i
  ) || html.match(
    /<meta[^>]*content\s*=\s*["']([^"']+)["'][^>]*property\s*=\s*["']og:image["'][^>]*\/?>/i
  );
  if (ogMatch && isValidImageUrl(ogMatch[1])) {
    return normalizeImageUrl(ogMatch[1]);
  }
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
__name(extractImage, "extractImage");
function extractParagraphs(html) {
  const paras = [];
  const pRegex = /<p[^>]*>([\s\S]*?)<\/p>/gi;
  let m;
  while ((m = pRegex.exec(html)) !== null) {
    const text = cleanText(m[1]);
    if (text.length >= 30)
      paras.push(text);
  }
  return paras;
}
__name(extractParagraphs, "extractParagraphs");
function getDomainKey(url) {
  try {
    const host = new URL(url).hostname.replace(/^www\./, "");
    if (SITE_EXTRACTORS[host])
      return host;
    const parts = host.split(".");
    for (let i = 1; i < parts.length - 1; i++) {
      const parent = parts.slice(i).join(".");
      if (SITE_EXTRACTORS[parent])
        return parent;
    }
    return null;
  } catch {
    return null;
  }
}
__name(getDomainKey, "getDomainKey");
function extractSiteSpecificParagraphs(html, classHints) {
  const allParas = [];
  for (const hint of classHints) {
    const escaped = hint.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const containerRegex = new RegExp(
      `<(?:div|section|article|main)[^>]*(?:class|id)\\s*=\\s*["'][^"']*${escaped}[^"']*["'][^>]*>([\\s\\S]*?)(?=<\\/(?:div|section|article|main)>)`,
      "gi"
    );
    let cm;
    while ((cm = containerRegex.exec(html)) !== null) {
      const paras = extractParagraphs(cm[1]);
      allParas.push(...paras);
    }
  }
  return allParas;
}
__name(extractSiteSpecificParagraphs, "extractSiteSpecificParagraphs");
function extractUniversalParagraphs(html) {
  const cleaned = stripNoiseTags(html);
  const articleMatch = cleaned.match(/<article[^>]*>([\s\S]*?)<\/article>/i);
  if (articleMatch) {
    const p = extractParagraphs(articleMatch[1]);
    if (p.length >= 2)
      return p;
  }
  const itemPropMatch = cleaned.match(
    /<[^>]*itemprop\s*=\s*["']articleBody["'][^>]*>([\s\S]*?)<\/(?:div|section|article)>/i
  );
  if (itemPropMatch) {
    const p = extractParagraphs(itemPropMatch[1]);
    if (p.length >= 2)
      return p;
  }
  const contentClasses = [
    "article-body",
    "article__body",
    "story-body",
    "post-content",
    "entry-content",
    "content-body",
    "article-content",
    "main-content"
  ];
  for (const cls of contentClasses) {
    const escaped = cls.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const re = new RegExp(
      `<[^>]*class\\s*=\\s*["'][^"']*${escaped}[^"']*["'][^>]*>([\\s\\S]*?)<\\/(?:div|section|article|main)>`,
      "gi"
    );
    const m = re.exec(cleaned);
    if (m) {
      const p = extractParagraphs(m[1]);
      if (p.length >= 2)
        return p;
    }
  }
  const mainMatch = cleaned.match(/<main[^>]*>([\s\S]*?)<\/main>/i);
  if (mainMatch) {
    const p = extractParagraphs(mainMatch[1]);
    if (p.length >= 2)
      return p;
  }
  const all = extractParagraphs(cleaned);
  if (all.length > 2)
    return all.slice(2);
  return all;
}
__name(extractUniversalParagraphs, "extractUniversalParagraphs");
function jaccard(a, b) {
  if (!a || !b)
    return 0;
  const setA = new Set(a.toLowerCase().split(/\s+/).filter(Boolean));
  const setB = new Set(b.toLowerCase().split(/\s+/).filter(Boolean));
  if (setA.size === 0 || setB.size === 0)
    return 0;
  let intersection = 0;
  for (const w of setA) {
    if (setB.has(w))
      intersection++;
  }
  return intersection / (setA.size + setB.size - intersection);
}
__name(jaccard, "jaccard");
function isNoise(text) {
  for (const p of NOISE_PATTERNS) {
    if (p.test(text))
      return true;
  }
  return false;
}
__name(isNoise, "isNoise");
function scoreCandidate(text, sourceBonus, title) {
  if (!text || text.length < 60)
    return 0;
  if (isNoise(text))
    return 0;
  let score = sourceBonus;
  if (text.length >= 100 && text.length <= 350)
    score += 30;
  else if (text.length >= 60 && text.length <= 99)
    score += 15;
  else if (text.length > 350)
    score += 10;
  const sim = jaccard(text, title);
  if (sim > 0.65)
    return 0;
  if (sim < 0.25)
    score += 20;
  if (/[.?!]\s[A-Z]/.test(text))
    score += 15;
  if (/\d/.test(text))
    score += 10;
  if (text.split(/\s+/).length > 15)
    score += 10;
  return score;
}
__name(scoreCandidate, "scoreCandidate");
function extractMetaContent(html, nameOrProp, value) {
  const r1 = new RegExp(
    `<meta[^>]*(?:${nameOrProp})\\s*=\\s*["']${value}["'][^>]*content\\s*=\\s*["']([^"']+)["'][^>]*\\/?>`,
    "i"
  );
  const m1 = r1.exec(html);
  if (m1)
    return cleanText(m1[1]);
  const r2 = new RegExp(
    `<meta[^>]*content\\s*=\\s*["']([^"']+)["'][^>]*(?:${nameOrProp})\\s*=\\s*["']${value}["'][^>]*\\/?>`,
    "i"
  );
  const m2 = r2.exec(html);
  if (m2)
    return cleanText(m2[1]);
  return null;
}
__name(extractMetaContent, "extractMetaContent");
function extractBestDescription(html, title, resolvedUrl) {
  const candidates = [];
  const ldRegex = /<script[^>]*type\s*=\s*["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;
  let ldMatch;
  while ((ldMatch = ldRegex.exec(html)) !== null) {
    try {
      const parsed = JSON.parse(ldMatch[1]);
      const objects = [];
      if (parsed["@graph"] && Array.isArray(parsed["@graph"])) {
        objects.push(...parsed["@graph"]);
      } else {
        objects.push(parsed);
      }
      for (const obj of objects) {
        if (obj.description) {
          candidates.push({ text: cleanText(obj.description), source: "jsonld" });
        }
        if (obj.abstract) {
          candidates.push({ text: cleanText(obj.abstract), source: "jsonld" });
        }
      }
    } catch {
    }
  }
  const ogDesc = extractMetaContent(html, "property", "og:description");
  if (ogDesc)
    candidates.push({ text: ogDesc, source: "og" });
  const twDesc = extractMetaContent(html, "name|property", "twitter:description");
  if (twDesc)
    candidates.push({ text: twDesc, source: "twitter" });
  const metaDesc = extractMetaContent(html, "name", "description");
  if (metaDesc)
    candidates.push({ text: metaDesc, source: "meta" });
  const cleaned = stripNoiseTags(html);
  let bodyParas = [];
  const domainKey = getDomainKey(resolvedUrl);
  if (domainKey) {
    bodyParas = extractSiteSpecificParagraphs(cleaned, SITE_EXTRACTORS[domainKey]);
  }
  if (bodyParas.length < 2) {
    bodyParas = extractUniversalParagraphs(html);
  }
  const bodySlice = bodyParas.length > 1 ? bodyParas.slice(1, 6) : bodyParas;
  for (const p of bodySlice) {
    candidates.push({ text: p, source: "body" });
  }
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
  if (!best || bestScore <= 0)
    return null;
  if (best.length > 350) {
    const cut = best.lastIndexOf(" ", 350);
    best = best.slice(0, cut > 0 ? cut : 350) + "\u2026";
  }
  return best;
}
__name(extractBestDescription, "extractBestDescription");
async function scrapePage(url, title) {
  try {
    const resp = await fetch(url, {
      headers: SCRAPE_HEADERS,
      signal: AbortSignal.timeout(5e3)
    });
    if (resp.status !== 200)
      return { imageUrl: null, description: null };
    const html = await resp.text();
    const imageUrl = extractImage(html);
    const description = extractBestDescription(html, title || "", url);
    return { imageUrl, description };
  } catch {
    return { imageUrl: null, description: null };
  }
}
__name(scrapePage, "scrapePage");
function parseRSS(xml) {
  const items = [];
  const itemRegex = /<item>([\s\S]*?)<\/item>/gi;
  let m;
  while ((m = itemRegex.exec(xml)) !== null) {
    const content = m[1];
    const titleM = content.match(
      /<title><!\[CDATA\[([\s\S]*?)\]\]><\/title>|<title[^>]*>([\s\S]*?)<\/title>/i
    );
    let rawTitle = titleM ? (titleM[1] ?? titleM[2] ?? '').trim() : '';
    const linkM = content.match(/<link[^>]*>([\s\S]*?)<\/link>/i);
    const link = linkM ? linkM[1].trim() : '';
    const dateM = content.match(/<pubDate[^>]*>([\s\S]*?)<\/pubDate>/i);
    const pubDate = dateM ? dateM[1].trim() : '';
    const srcM = content.match(
      /<source[^>]*><!\[CDATA\[([\s\S]*?)\]\]><\/source>|<source[^>]*>([\s\S]*?)<\/source>/i
    );
    let source = srcM ? (srcM[1] ?? srcM[2] ?? 'Google News').trim() : 'Google News';
    const hyphen = rawTitle.lastIndexOf(' - ');
    if (hyphen !== -1) {
      source   = rawTitle.substring(hyphen + 3).trim();
      rawTitle = rawTitle.substring(0, hyphen).trim();
    }
    if (link) items.push({ title: rawTitle, link, pubDate, source });
  }
  return items;
}
__name(parseRSS, "parseRSS");
function handleHealth() {
  return json({ status: "ok", timestamp: (/* @__PURE__ */ new Date()).toISOString() });
}
__name(handleHealth, "handleHealth");
async function handleNews(url) {
  const params = url.searchParams;
  const hl = params.get("hl") || "en-IN";
  const gl = params.get("gl") || "IN";
  const cat = params.get("cat");
  const q = params.get("q");
  let rssUrl;
  if (q) {
    rssUrl = `https://news.google.com/rss/search?q=${encodeURIComponent(q)}&hl=${hl}&gl=${gl}&ceid=${gl}:en`;
  } else if (cat) {
    rssUrl = `https://news.google.com/rss/headlines/section/topic/${encodeURIComponent(cat)}?hl=${hl}&gl=${gl}&ceid=${gl}:en`;
  } else {
    rssUrl = `https://news.google.com/rss?hl=${hl}&gl=${gl}&ceid=${gl}:en`;
  }

  let rssResp;
  try {
    rssResp = await fetch(rssUrl, {
      headers: { 'User-Agent': 'Mozilla/5.0' },
      signal: AbortSignal.timeout(10000),
      cf: { cacheTtl: 900 }
    });
  } catch (e) {
    return json(
      { error: "RSS fetch connection timed out or failed", message: e.message },
      502
    );
  }

  if (!rssResp.ok) {
    return json(
      { error: 'RSS fetch failed', status: rssResp.status },
      502
    );
  }

  const rssText = await rssResp.text();
  const parsedItems = parseRSS(rssText).slice(0, 20);

  if (parsedItems.length === 0) {
    return json({ status: 'ok', count: 0, articles: [] });
  }

  const articles = parsedItems.map(item => ({
    title:       item.title,
    url:         item.link,
    source:      item.source,
    publishedAt: item.pubDate,
    imageUrl:    null,
    description: null,
  }));

  return json(
    { status: 'ok', count: articles.length, articles },
    200,
    { 'Cache-Control': 'public, max-age=900' }
  );
}
__name(handleNews, "handleNews");
async function handleArticle(url) {
  const params     = url.searchParams;
  const articleUrl = params.get('url');
  const title      = params.get('title') || '';

  if (!articleUrl) 
    return json({ error: 'Missing url parameter' }, 400);

  if (articleUrl.includes('news.google.com')) {
    return json({
      status: 'ok', url: articleUrl,
      imageUrl: null, description: null,
    }, 200, { 'Cache-Control': 'public, max-age=300' });
  }

  const scraped = await scrapePage(articleUrl, title);
  return json(
    {
      status:      'ok',
      url:         articleUrl,
      imageUrl:    scraped.imageUrl,
      description: scraped.description,
    },
    200,
    { 'Cache-Control': 'public, max-age=3600' }
  );
}
__name(handleArticle, "handleArticle");
async function handleGuardian(url, env) {
  const params = url.searchParams;
  const section = params.get("section") || "world";
  const q = params.get("q");
  const key = params.get("key") || env.GUARDIAN_API_KEY || "test";
  let apiUrl;
  if (q) {
    apiUrl = `https://content.guardianapis.com/search?q=${encodeURIComponent(q)}&show-fields=headline,trailText,thumbnail,byline&order-by=relevance&page-size=20&api-key=${key}`;
  } else {
    apiUrl = `https://content.guardianapis.com/search?section=${encodeURIComponent(section)}&show-fields=headline,trailText,thumbnail,byline&order-by=newest&page-size=20&api-key=${key}`;
  }
  const resp = await fetch(apiUrl, {
    signal: AbortSignal.timeout(5e3)
  });
  if (resp.status !== 200) {
    return json(
      { error: "Guardian API fetch failed", status: resp.status },
      502
    );
  }
  const data = await resp.json();
  const results = data?.response?.results || [];
  const articles = results.map((item) => {
    const fields = item.fields || {};
    return {
      title: fields.headline || item.webTitle || "No Title",
      url: item.webUrl || "",
      source: "The Guardian",
      publishedAt: item.webPublicationDate || "",
      imageUrl: fields.thumbnail || null,
      description: fields.trailText ? cleanText(fields.trailText) : null
    };
  });
  return json(
    { status: "ok", count: articles.length, articles },
    200,
    { "Cache-Control": "public, max-age=900" }
  );
}
__name(handleGuardian, "handleGuardian");
var worker_default = {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: CORS });
    }
    try {
      const url = new URL(request.url);
      const path = url.pathname.replace(/\/+$/, "") || "/";
      switch (path) {
        case "/health":
          return handleHealth();
        case "/news":
          return await handleNews(url);
        case "/article":
          return await handleArticle(url);
        case "/guardian":
          return await handleGuardian(url, env);
        default:
          return json({ error: "Not found" }, 404);
      }
    } catch (err) {
      return json(
        { error: "Internal error", message: err.message || "Unknown" },
        500
      );
    }
  }
};
export {
  worker_default as default
};
//# sourceMappingURL=worker.js.map
