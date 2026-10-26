import 'package:flutter_test/flutter_test.dart';
import 'package:metrolist_pro/main.dart';

void main() {
  testWidgets('Metrolist App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MetrolistApp());
    expect(find.text('Metrolist Pro'), findsOneWidget);
  });
}
