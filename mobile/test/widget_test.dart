import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart'; // Changed to a relative import

void main() {
  testWidgets('App should build successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HomeSweetHomeApp());

    // Verify that the app loads.
    expect(find.byType(HomeSweetHomeApp), findsOneWidget);
  });
}