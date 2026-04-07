import 'package:flutter/foundation.dart';
import 'lrc_line.dart';

/// Represents parsed lyrics from an LRC file
@immutable
class Lyrics {
  /// List of lyric lines sorted by timestamp
  final List<LrcLine> lines;

  /// Metadata from LRC file
  final String? title;
  final String? artist;
  final String? album;
  final String? creator; // Person who made the LRC file
  final int? offset; // Time offset in milliseconds

  const Lyrics({
    required this.lines,
    this.title,
    this.artist,
    this.album,
    this.creator,
    this.offset,
  });

  /// Returns true if lyrics are empty
  bool get isEmpty => lines.isEmpty;

  /// Returns true if lyrics exist
  bool get isNotEmpty => lines.isNotEmpty;

  /// Get the lyric line that should be displayed at the given position
  /// Returns null if no line should be shown yet
  LrcLine? getLineAtPosition(Duration position) {
    if (lines.isEmpty) return null;

    final positionMs = position.inMilliseconds + (offset ?? 0);

    // Find the last line whose timestamp is <= current position
    LrcLine? currentLine;
    for (final line in lines) {
      if (line.timestampMs <= positionMs) {
        currentLine = line;
      } else {
        break; // Lines are sorted, so we can stop
      }
    }

    return currentLine;
  }

  /// Get the index of the line at the given position
  /// Returns -1 if no line should be shown yet
  int getLineIndexAtPosition(Duration position) {
    if (lines.isEmpty) return -1;

    final positionMs = position.inMilliseconds + (offset ?? 0);

    int currentIndex = -1;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].timestampMs <= positionMs) {
        currentIndex = i;
      } else {
        break;
      }
    }
    return currentIndex;
  }

  @override
  String toString() {
    return 'Lyrics(lines: ${lines.length}, title: $title, artist: $artist)';
  }
}