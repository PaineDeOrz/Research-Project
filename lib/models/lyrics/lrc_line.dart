import 'package:flutter/foundation.dart';

/// Represents a single line of lyrics with its timestamp
@immutable
class LrcLine {
  /// Timestamp in milliseconds when this line should be displayed
  final int timestampMs;
  
  /// The lyrics text for this line
  final String text;

  const LrcLine({
    required this.timestampMs,
    required this.text,
  });

  @override
  String toString() => '[$timestampMs ms] $text';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LrcLine &&
        other.timestampMs == timestampMs &&
        other.text == text;
  }

  @override
  int get hashCode => Object.hash(timestampMs, text);
}