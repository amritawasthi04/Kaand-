class Constants {
  static const String guardianBaseUrl = 'https://content.guardianapis.com';

  static const String hiveNewsBox = 'news_cache_box_v2';
  static const String hiveUserBox = 'user_profile_box_v2';

  static const Duration headlinesTtl = Duration(minutes: 30);

  static const Map<String, List<String>> categoryFeeds = {
    'general': [
      'https://news.google.com/rss?hl=en-IN&gl=IN&ceid=IN:en',
      'http://feeds.bbci.co.uk/news/rss.xml'
    ],
    'technology': [
      'https://techcrunch.com/feed/',
      'https://news.google.com/rss/headlines/section/topic/TECHNOLOGY?hl=en-IN&gl=IN&ceid=IN:en'
    ],
    'business': [
      'https://news.google.com/rss/headlines/section/topic/BUSINESS?hl=en-IN&gl=IN&ceid=IN:en'
    ],
    'sports': [
      'https://www.espn.com/espn/rss/news',
      'https://news.google.com/rss/headlines/section/topic/SPORTS?hl=en-IN&gl=IN&ceid=IN:en'
    ],
    'health': [
      'https://news.google.com/rss/headlines/section/topic/HEALTH?hl=en-IN&gl=IN&ceid=IN:en'
    ],
    'science': [
      'https://news.google.com/rss/headlines/section/topic/SCIENCE?hl=en-IN&gl=IN&ceid=IN:en'
    ],
    'world': [
      'https://www.theguardian.com/international/rss',
      'http://feeds.bbci.co.uk/news/rss.xml',
      'https://news.google.com/rss/headlines/section/topic/WORLD?hl=en-IN&gl=IN&ceid=IN:en'
    ],
    'india': [
      'https://www.thehindu.com/news/national/feeder/default.rss',
      'https://indianexpress.com/feed/',
      'https://feeds.feedburner.com/ndtvnews-top-stories',
      'https://news.google.com/rss/headlines/section/topic/NATION?hl=en-IN&gl=IN&ceid=IN:en'
    ],
    'entertainment': [
      'https://news.google.com/rss/headlines/section/topic/ENTERTAINMENT?hl=en-IN&gl=IN&ceid=IN:en'
    ]
  };
}
