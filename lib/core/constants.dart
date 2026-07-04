class Constants {
  static const String baseUrl = 'https://kaand-mauve.vercel.app/api';
  static const String workerBaseUrl = 'https://kaand.2024baiml013.workers.dev';
  static const String guardianBaseUrl = 'https://content.guardianapis.com';
  static const String guardianApiKey = 'cd760a37-962a-475d-a08f-75738e87a663';

  static const String hiveNewsBox = 'news_cache_box_v2';
  static const String hiveUserBox = 'user_profile_box_v2';

  static const Duration headlinesTtl = Duration(minutes: 30);
  static const Duration detailTtl = Duration(hours: 24);
}
