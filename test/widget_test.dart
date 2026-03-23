import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stuff_crawler/main.dart';

void main() {
  testWidgets('Stuff Crawler loads and shows greeting', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const StuffCrawlerApp());

    // Initially we should see a loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
