export const categoryFeeds: Record<string, string[]> = {
  general: [
    'https://news.google.com/rss?hl=en-IN&gl=IN&ceid=IN:en',
    'http://feeds.bbci.co.uk/news/rss.xml'
  ],
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

export function normalizeSource(url: string): string {
  const lower = url.toLowerCase();
  if (lower.includes('techcrunch')) return 'TechCrunch';
  if (lower.includes('bbc')) return 'BBC';
  if (lower.includes('theguardian')) return 'The Guardian';
  if (lower.includes('thehindu')) return 'The Hindu';
  if (lower.includes('indianexpress')) return 'Indian Express';
  if (lower.includes('ndtv')) return 'NDTV';
  if (lower.includes('espn')) return 'ESPN';
  if (lower.includes('hindustantimes')) return 'Hindustan Times';
  if (lower.includes('moneycontrol')) return 'Moneycontrol';
  if (lower.includes('livemint')) return 'LiveMint';
  if (lower.includes('economictimes')) return 'Economic Times';
  if (lower.includes('zeenews')) return 'Zee News';
  if (lower.includes('indiatoday')) return 'India Today';
  if (lower.includes('republicworld')) return 'Republic World';
  if (lower.includes('aninews')) return 'ANI';
  return 'News';
}
