import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('App should build successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HomeSweetHomeApp());

    // Verify that the app loads.
    expect(find.byType(HomeSweetHomeApp), findsOneWidget);
  });
}