// -----------------------------------------------------------------------------
// INTEGRATION TEST - APP
// -----------------------------------------------------------------------------
//
// End-to-end test that launches the full app and verifies basic functionality.
// Run with: flutter test integration_test/app_test.dart
//
// Platform requirements:
// - Android: Any runner (Linux/macOS/Windows) + emulator or device
// - iOS: macOS only + simulator or device
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:musik_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Reset GetIt between tests to avoid "already registered" errors
  setUp(() async {
    await GetIt.I.reset();
  });

  testWidgets('app launches and shows UI', (tester) async {
    // Launch the app
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // App should show either onboarding or main navigation
    final hasOnboarding =
        find.textContaining('Welcome').evaluate().isNotEmpty ||
            find.textContaining('Get Started').evaluate().isNotEmpty ||
            find.textContaining('Musik').evaluate().isNotEmpty;
    final hasMainNav = find.byType(BottomNavigationBar).evaluate().isNotEmpty;
    final hasMaterialApp = find.byType(MaterialApp).evaluate().isNotEmpty;

    expect(
      hasOnboarding || hasMainNav || hasMaterialApp,
      isTrue,
      reason: 'App should show onboarding, main navigation, or at least MaterialApp',
    );

    // If we see a "Get Started" or similar button, tap it
    final getStartedButton = find.textContaining('Get Started');
    if (getStartedButton.evaluate().isNotEmpty) {
      await tester.tap(getStartedButton.first);
      await tester.pumpAndSettle();
    }

    // Verify app is still running (didn't crash)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
