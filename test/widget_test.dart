import 'package:flutter_test/flutter_test.dart';
import 'package:application/main.dart';

void main() {
  testWidgets('Splash Screen Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(const KaandApp());

    expect(find.text('KAAND'), findsOneWidget);
    expect(find.text('Stay Connected.\nStay Informed.'), findsOneWidget);
  });
}
