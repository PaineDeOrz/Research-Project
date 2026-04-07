import 'package:flutter_test/flutter_test.dart';
import 'package:musik_app/widgets/format_duration.dart';

void main() {
  group('formatDuration', () {
    test('formats zero duration', () {
      expect(formatDuration(Duration.zero), '0:00');
    });

    test('formats seconds only', () {
      expect(formatDuration(const Duration(seconds: 5)), '0:05');
      expect(formatDuration(const Duration(seconds: 30)), '0:30');
      expect(formatDuration(const Duration(seconds: 59)), '0:59');
    });

    test('formats minutes and seconds', () {
      expect(formatDuration(const Duration(minutes: 1)), '1:00');
      expect(formatDuration(const Duration(minutes: 1, seconds: 5)), '1:05');
      expect(formatDuration(const Duration(minutes: 3, seconds: 30)), '3:30');
      expect(formatDuration(const Duration(minutes: 9, seconds: 59)), '9:59');
    });

    test('formats double-digit minutes', () {
      expect(formatDuration(const Duration(minutes: 10)), '10:00');
      expect(formatDuration(const Duration(minutes: 59, seconds: 59)), '59:59');
    });

    test('formats hours as minutes', () {
      // 1 hour = 60 minutes
      expect(formatDuration(const Duration(hours: 1)), '60:00');
      expect(formatDuration(const Duration(hours: 1, minutes: 30)), '90:00');
      expect(formatDuration(const Duration(hours: 2, minutes: 15, seconds: 30)), '135:30');
    });

    test('pads seconds with leading zero', () {
      expect(formatDuration(const Duration(minutes: 5, seconds: 1)), '5:01');
      expect(formatDuration(const Duration(minutes: 5, seconds: 9)), '5:09');
    });

    test('does not pad minutes', () {
      expect(formatDuration(const Duration(minutes: 1)), '1:00');
      expect(formatDuration(const Duration(minutes: 5)), '5:00');
    });
  });
}
