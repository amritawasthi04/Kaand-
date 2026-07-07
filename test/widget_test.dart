import 'package:flutter_test/flutter_test.dart';
import 'package:application/main.dart';

void main() {
  testWidgets('Design System Showcase Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(const KaandApp());

    expect(find.text('KAAND DESIGN SYSTEM'), findsOneWidget);
  });
}
