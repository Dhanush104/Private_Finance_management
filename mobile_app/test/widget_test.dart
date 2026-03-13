// Basic smoke test for the Royal Star Boys app
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RoyalStarBoysApp());
    // App should render without errors
    expect(find.text('Royal Star Boys'), findsAny);
  });
}
