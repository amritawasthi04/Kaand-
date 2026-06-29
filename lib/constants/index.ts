export const CATEGORY_FEEDS: Record<string, string[]> = {
  technology: [
    'https://techcrunch.com/feed/',
    'https://news.google.com/rss/headlines/section/topic/TECHNOLOGY?hl=en-IN&gl=IN&ceid=IN:en'
  ],
  business: [
    'https://news.google.com/rss/headlines/section/topic/BUSINESS?hl=en-IN&gl=IN&ceid=IN:en'
  ],
  sports: [
    'https://www.espn.com/espn/rss/news',
    'https://news.google.com/rss/headlines/section/topic/SPORTS?hl=en-IN&gl=IN&ceid=IN:en'
  ],
  health: [
    'https://news.google.com/rss/headlines/section/topic/HEALTH?hl=en-IN&gl=IN&ceid=IN:en'
  ],
  science: [
    'https://news.google.com/rss/headlines/section/topic/SCIENCE?hl=en-IN&gl=IN&ceid=IN:en'
  ],
  world: [
    'https://www.theguardian.com/international/rss',
    'http://feeds.bbci.co.uk/news/rss.xml',
    'https://news.google.com/rss/headlines/section/topic/WORLD?hl=en-IN&gl=IN&ceid=IN:en'
  ],
  india: [
    'https://www.thehindu.com/news/national/feeder/default.rss',
    'https://indianexpress.com/feed/',
    'https://feeds.feedburner.com/ndtvnews-top-stories',
    'https://news.google.com/rss/headlines/section/topic/NATION?hl=en-IN&gl=IN&ceid=IN:en'
  ],
  entertainment: [
    'https://news.google.com/rss/headlines/section/topic/ENTERTAINMENT?hl=en-IN&gl=IN&ceid=IN:en'
  ]
};

// Caching parameters (in milliseconds)
export const TTL_FEED = 15 * 60 * 1000;      // 15 Minutes
export const TTL_ARTICLE = 24 * 60 * 60 * 1000; // 24 Hours

export const DEFAULT_LIMIT = 20;
export const MAX_LIMIT = 50;
