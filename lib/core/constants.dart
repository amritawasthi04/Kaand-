class Constants {
  static const String workerBaseUrl = 'https://kaand-worker.amritawasthi04.workers.dev';
  static const String guardianBaseUrl = 'https://content.guardianapis.com';
  static const String guardianApiKey = 'test';

  static const String hiveNewsBox = 'news_cache_box_v2';
  static const String hiveUserBox = 'user_profile_box_v2';
  
  static const Duration headlinesTtl = Duration(minutes: 15);
  static const Duration detailTtl = Duration(hours: 24);
}
