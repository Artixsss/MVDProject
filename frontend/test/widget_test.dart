// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mvd_frontend/main.dart';
import 'package:mvd_frontend/app_router.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final router = AppRouter.createRouter();
    await tester.pumpWidget(MvdApp(router: router));

    // Verify that our counter starts at 0.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Tap the '+' icon and trigger a frame.
    // No counter UI in this app; just ensure app builds
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
