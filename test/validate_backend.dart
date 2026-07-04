import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final baseUrl = 'https://kaand-mauve.vercel.app/api';
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
    final request = await client.getUrl(Uri.parse('$baseUrl/news?limit=3'));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body);

    if (response.statusCode == 200 && json['success'] == true && json['data'] is List) {
      final list = json['data'] as List;
      print('✅ News general feed query passed! Returned ${list.length} articles.');
      if (list.isNotEmpty) {
        print('   First Article Headline: "${list[0]['title']}" from "${list[0]['source']}"');
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
    final request = await client.getUrl(Uri.parse('$baseUrl/news?category=NATION&limit=2'));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body);

    if (response.statusCode == 200 && json['success'] == true && json['data'] is List) {
      final list = json['data'] as List;
      print('✅ News nation category query passed! Returned ${list.length} articles.');
      if (list.isNotEmpty) {
        print('   First Article: "${list[0]['title']}"');
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
  print('\n=== TEST RUN CONCLUSION ===');
  if (allPassed) {
    print('🚀 ALL TESTS PASSED SUCCESSFULLY! The backend is operational and standardized.');
  } else {
    print('⚠️ SOME TESTS FAILED. Check the error outputs above.');
  }

  client.close();
}
