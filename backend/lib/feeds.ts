export const categoryFeeds: Record<string, string[]> = {
  general: [
    'https://news.google.com/rss?hl=en-IN&gl=IN&ceid=IN:en',
    'http://feeds.bbci.co.uk/news/rss.xml'
  ],
  technology: [
    'https://techcrunch.com/feed/',
    'https://www.wired.com/feed/rss',
    'https://www.engadget.com/rss.xml',
    'https://9to5google.com/feed/',
    'https://www.androidauthority.com/feed/',
    'https://news.google.com/rss/headlines/section/topic/TECHNOLOGY?hl=en-IN&gl=IN&ceid=IN:en'
  ],
  business: [
    'https://www.cnbc.com/id/100003114/device/rss/rss.html',
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
    'https://www.aljazeera.com/xml/rss/all.xml',
    'https://rss.nytimes.com/services/xml/rss/nyt/World.xml',
    'https://news.google.com/rss/headlines/section/topic/WORLD?hl=en-IN&gl=IN&ceid=IN:en'
  ],
  india: [
    'https://www.thehindu.com/news/national/feeder/default.rss',
    'https://indianexpress.com/feed/',
    'https://feeds.feedburner.com/ndtvnews-top-stories',
    'https://timesofindia.indiatimes.com/rssfeeds/-2128936835.cms',
    'https://www.hindustantimes.com/feeds/rss/india-news/rssfeed.xml',
    'https://www.news18.com/rss/india.xml',
    'https://www.livemint.com/rss/news',
    'https://news.google.com/rss/headlines/section/topic/NATION?hl=en-IN&gl=IN&ceid=IN:en'
  ],
  entertainment: [
    'https://variety.com/feed/',
    'https://deadline.com/feed/',
    'https://www.ign.com/articles.rss',
    'https://news.google.com/rss/headlines/section/topic/ENTERTAINMENT?hl=en-IN&gl=IN&ceid=IN:en'
  ]
};

// Mapping of URL substring -> display name
const SOURCE_MAP: [string, string][] = [
  ['techcrunch', 'TechCrunch'],
  ['bbc', 'BBC'],
  ['theguardian', 'The Guardian'],
  ['thehindu', 'The Hindu'],
  ['indianexpress', 'Indian Express'],
  ['ndtv', 'NDTV'],
  ['espn', 'ESPN'],
  ['hindustantimes', 'Hindustan Times'],
  ['moneycontrol', 'Moneycontrol'],
  ['livemint', 'LiveMint'],
  ['economictimes', 'Economic Times'],
  ['zeenews', 'Zee News'],
  ['indiatoday', 'India Today'],
  ['republicworld', 'Republic World'],
  ['aninews', 'ANI'],
  ['timesofindia', 'Times of India'],
  ['news18', 'News18'],
  ['cnbc', 'CNBC'],
  ['nytimes', 'New York Times'],
  ['aljazeera', 'Al Jazeera'],
  ['cnn', 'CNN'],
  ['wired', 'Wired'],
  ['engadget', 'Engadget'],
  ['9to5google', '9to5Google'],
  ['androidauthority', 'Android Authority'],
  ['variety', 'Variety'],
  ['deadline', 'Deadline'],
  ['ign', 'IGN'],
  ['rollingstone', 'Rolling Stone'],
];

export function normalizeSource(url: string): string {
  const lower = url.toLowerCase();
  for (const [key, name] of SOURCE_MAP) {
    if (lower.includes(key)) return name;
  }
  return 'News';
}

export const publisherList = SOURCE_MAP.map(([id, name]) => ({ id, name }));
