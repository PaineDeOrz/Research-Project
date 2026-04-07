# Tests

Tests are split by type, not by where the source code lives.

## unit/

Pure Dart tests. No Flutter framework, no platform plugins and no mocks needed.
These test logic like parsing, string lookups, queue operations etc...

Run with:
```bash
flutter test test/unit/
```

## widget/

Flutter widget tests using `WidgetTester`.
For testing individual widgets in isolation so not the entire app.
Add tests here when a widget has enough standalone logic to be worth testing on its own.

Run with:
```bash
flutter test test/widget/
```

## integration/ (in `integration_test/` directory)

End-to-end tests that run the full app on a device or emulator.
These use the `integration_test` package and require a running device.

**Platform requirements:**

| Platform | Runner Requirements |
|----------|---------------------|
| Android  | Linux, macOS, or Windows + Android emulator/device |
| iOS      | **macOS only** + iOS Simulator/device |

This is a key cross-platform limitation: iOS integration tests cannot run on Linux CI runners.

Run locally with:
```bash
# Android (on any platform with emulator running)
flutter test integration_test/app_test.dart -d android

# iOS (macOS only, with simulator running)
flutter test integration_test/app_test.dart -d ios
```

Or using flutter drive:
```bash
flutter drive --driver=integration_test/test_driver/integration_test.dart --target=integration_test/app_test.dart
```

## CI/CD Notes

Our GitLab CI uses a Linux Docker image which can run:
- Unit tests
- Widget tests (headless)

It cannot run integration tests for either platform because:
- Android: No emulator in the Docker image
- iOS: Requires macOS (Xcode, iOS Simulator)

To run iOS integration tests in CI, you would need:
- A macOS runner (GitLab shared runners, self-hosted Mac, or cloud Mac service)
- Xcode installed
- iOS Simulator or connected device
