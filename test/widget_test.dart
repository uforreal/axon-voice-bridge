import 'package:flutter_test/flutter_test.dart';
import 'package:rufen_app/main.dart';

void main() {
  testWidgets('RUFEN app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RufenApp());
    expect(find.byType(RufenApp), findsOneWidget);
  });
}
