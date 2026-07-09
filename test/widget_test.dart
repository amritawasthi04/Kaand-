import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:application/main.dart';

void main() {
  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
  });

  tearDown(() async {
    await Hive.close();
  });

  testWidgets('Splash Screen Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(const KaandApp());

    expect(find.text('KAAND'), findsOneWidget);
    expect(find.text('Stay Connected.\nStay Informed.'), findsOneWidget);
  });
}
