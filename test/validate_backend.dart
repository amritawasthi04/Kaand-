import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final baseUrl = Platform.environment['API_URL'] ?? 'http://localhost:3000/api';
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
  bool allPassed = true;

  print('=== KAAND BACKEND API TEST SUITE ===\n');

  // Test 1: Health Endpoint
  try {
    print('[TEST 1] GET /health');
    final request = await client.getUrl(Uri.parse('$baseUrl/health'));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body);
    
    if (response.statusCode == 200 && json['success'] == true && json['data']['status'] == 'ok') {
      print('✅ Health endpoint check passed! Response: $body');
    } else {
      print('❌ Health endpoint check failed. Status: ${response.statusCode}, Body: $body');
      allPassed = false;
    }
  } catch (e) {
    print('❌ Health endpoint query crashed: $e');
    allPassed = false;
  }
  print('');

  // Test 2: News Endpoint (General/Default load)
  try {
    print('[TEST 2] GET /news (Default Category: general)');
    final request = await client.getUrl(Uri.parse('$baseUrl/news?limit=3&refresh=true'));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body);

    if (response.statusCode == 200 && json['success'] == true && json['data'] is Map && json['data']['articles'] is List) {
      final list = json['data']['articles'] as List;
      print('✅ News general feed query passed! Returned ${list.length} articles.');
      if (list.isNotEmpty) {
        print('   First Article Headline: "${list[0]['title']}" from "${list[0]['source']}"');
        print('   First Article Image: "${list[0]['image']}"');
        final hasImage = list.any((art) => art['image'] != null && (art['image'] as String).isNotEmpty);
        if (hasImage) {
          print('   🎉 SUCCESS: Extracted images found in news feed!');
        } else {
          print('   ⚠️ WARNING: All article images are empty in this response.');
        }
      }
    } else {
      print('❌ News general feed query failed. Status: ${response.statusCode}, Body: $body');
      allPassed = false;
    }
  } catch (e) {
    print('❌ News general feed query crashed: $e');
    allPassed = false;
  }
  print('');

  // Test 3: News Endpoint (Nation Category mapping)
  try {
    print('[TEST 3] GET /news?category=NATION (Casing and Key Mapping)');
    final request = await client.getUrl(Uri.parse('$baseUrl/news?category=NATION&limit=2&refresh=true'));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body);

    if (response.statusCode == 200 && json['success'] == true && json['data'] is Map && json['data']['articles'] is List) {
      final list = json['data']['articles'] as List;
      print('✅ News nation category query passed! Returned ${list.length} articles.');
      if (list.isNotEmpty) {
        print('   First Article: "${list[0]['title']}"');
        print('   First Article Image: "${list[0]['image']}"');
        final hasImage = list.any((art) => art['image'] != null && (art['image'] as String).isNotEmpty);
        if (hasImage) {
          print('   🎉 SUCCESS: Extracted images found in nation feed!');
        } else {
          print('   ⚠️ WARNING: All article images are empty in this response.');
        }
      }
    } else {
      print('❌ News nation query failed. Status: ${response.statusCode}, Body: $body');
      allPassed = false;
    }
  } catch (e) {
    print('❌ News nation query crashed: $e');
    allPassed = false;
  }
  print('');

  // Test 4: Guardian Endpoint
  try {
    print('[TEST 4] GET /guardian');
    final request = await client.getUrl(Uri.parse('$baseUrl/guardian?limit=2'));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body);

    if (response.statusCode == 200 && json['success'] == true && json['data'] is List) {
      final list = json['data'] as List;
      print('✅ Guardian feed query passed! Returned ${list.length} articles.');
      if (list.isNotEmpty) {
        print('   First Editorial: "${list[0]['title']}"');
      }
    } else {
      print('❌ Guardian query failed. Status: ${response.statusCode}, Body: $body');
      allPassed = false;
    }
  } catch (e) {
    print('❌ Guardian query crashed: $e');
    allPassed = false;
  }
  print('');

  // Test 5: SSRF Block Check
  try {
    print('[TEST 5] GET /article?url=http://127.0.0.1/admin (SSRF loopback block)');
    final request = await client.getUrl(Uri.parse('$baseUrl/article?url=http://127.0.0.1/admin'));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body);

    if (response.statusCode == 400 && json['success'] == false && json['code'] == 'SSRF_BLOCKED') {
      print('✅ SSRF blocker passed! Blocked private loopback access successfully. Body: $body');
    } else {
      print('❌ SSRF blocker failed. Status: ${response.statusCode}, Body: $body');
      allPassed = false;
    }
  } catch (e) {
    print('❌ SSRF check query crashed: $e');
    allPassed = false;
  }
  print('');

  // Test 6: SSRF DNS resolution block check
  try {
    print('[TEST 6] GET /article?url=http://localhost:8080/info (SSRF DNS resolve block)');
    final request = await client.getUrl(Uri.parse('$baseUrl/article?url=http://localhost:8080/info'));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body);

    if (response.statusCode == 400 && json['success'] == false && json['code'] == 'SSRF_BLOCKED') {
      print('✅ SSRF resolver blocker passed! Blocked local hostname resolution. Body: $body');
    } else {
      print('❌ SSRF resolver blocker failed. Status: ${response.statusCode}, Body: $body');
      allPassed = false;
    }
  } catch (e) {
    print('❌ SSRF resolver check query crashed: $e');
    allPassed = false;
  }
  // Test 7: Search Endpoint
  try {
    print('[TEST 7] GET /search?q=india');
    final request = await client.getUrl(Uri.parse('$baseUrl/search?q=india&limit=2'));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body);

    if (response.statusCode == 200 && json['success'] == true && json['data']['articles'] is List) {
      final list = json['data']['articles'] as List;
      print('✅ Search query passed! Returned ${list.length} articles matching "india".');
    } else {
      print('❌ Search query failed. Status: ${response.statusCode}, Body: $body');
      allPassed = false;
    }
  } catch (e) {
    print('❌ Search query crashed: $e');
    allPassed = false;
  }
  print('');

  // Test 8: Categories Endpoint
  try {
    print('[TEST 8] GET /categories');
    final request = await client.getUrl(Uri.parse('$baseUrl/categories'));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body);

    if (response.statusCode == 200 && json['success'] == true && json['data'] is List) {
      final list = json['data'] as List;
      print('✅ Categories query passed! Returned ${list.length} categories.');
    } else {
      print('❌ Categories query failed. Status: ${response.statusCode}, Body: $body');
      allPassed = false;
    }
  } catch (e) {
    print('❌ Categories query crashed: $e');
    allPassed = false;
  }
  print('');

  // Test 9: Category by ID Endpoint
  try {
    print('[TEST 9] GET /category/technology');
    final request = await client.getUrl(Uri.parse('$baseUrl/category/technology?limit=2'));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body);

    if (response.statusCode == 200 && json['success'] == true && json['data']['articles'] is List) {
      final list = json['data']['articles'] as List;
      print('✅ Category ID query passed! Returned ${list.length} articles in technology.');
    } else {
      print('❌ Category ID query failed. Status: ${response.statusCode}, Body: $body');
      allPassed = false;
    }
  } catch (e) {
    print('❌ Category ID query crashed: $e');
    allPassed = false;
  }
  print('');

  // Test 10: Publishers Endpoint
  try {
    print('[TEST 10] GET /publishers');
    final request = await client.getUrl(Uri.parse('$baseUrl/publishers'));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body);

    if (response.statusCode == 200 && json['success'] == true && json['data'] is List) {
      final list = json['data'] as List;
      print('✅ Publishers query passed! Returned ${list.length} publishers.');
    } else {
      print('❌ Publishers query failed. Status: ${response.statusCode}, Body: $body');
      allPassed = false;
    }
  } catch (e) {
    print('❌ Publishers query crashed: $e');
    allPassed = false;
  }
  print('');

  // Test 11: Publisher by ID Endpoint
  try {
    print('[TEST 11] GET /publisher/bbc');
    final request = await client.getUrl(Uri.parse('$baseUrl/publisher/bbc?limit=2'));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body);

    if (response.statusCode == 200 && json['success'] == true && json['data']['articles'] is List) {
      final list = json['data']['articles'] as List;
      print('✅ Publisher ID query passed! Returned ${list.length} articles from BBC.');
    } else {
      print('❌ Publisher ID query failed. Status: ${response.statusCode}, Body: $body');
      allPassed = false;
    }
  } catch (e) {
    print('❌ Publisher ID query crashed: $e');
    allPassed = false;
  }
  print('');

  // Test 12: Trending Endpoint
  try {
    print('[TEST 12] GET /trending');
    final request = await client.getUrl(Uri.parse('$baseUrl/trending?limit=3'));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body);

    if (response.statusCode == 200 && json['success'] == true && json['data'] is List) {
      final list = json['data'] as List;
      print('✅ Trending query passed! Returned ${list.length} trending articles.');
    } else {
      print('❌ Trending query failed. Status: ${response.statusCode}, Body: $body');
      allPassed = false;
    }
  } catch (e) {
    print('❌ Trending query crashed: $e');
    allPassed = false;
  }
  print('');

  print('=== TEST RUN CONCLUSION ===');
  if (allPassed) {
    print('🚀 ALL TESTS PASSED SUCCESSFULLY! The backend is operational and standardized.');
  } else {
    print('⚠️ SOME TESTS FAILED. Check the error outputs above.');
  }

  client.close();
}
