import 'dart:io';
import '../core/log_debug.dart';
import '../models/lyrics/lrc_line.dart';
import '../models/lyrics/lyrics.dart';

/// Parser for LRC (Lyric) files
class LrcParserService {
  /// Parse an LRC file from a file path
  static Future<Lyrics?> parseFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        logDebug('LrcParser: file does not exist: $filePath');
        return null;
      }

      final content = await file.readAsString();
      return parseString(content);
    } catch (e, stackTrace) {
      logDebug('LrcParser: failed to parse file $filePath: $e');
      logDebug('LrcParser: $stackTrace');
      return null;
    }
  }

  /// Parse LRC content from a string
  static Lyrics? parseString(String content) {
    try {
      final lines = <LrcLine>[];
      String? title;
      String? artist;
      String? album;
      String? creator;
      int? offset;

      // Regular expressions for parsing
      // Matches: [00:12.34] or [00:12] or [0:12.34]
      final timeTagRegex = RegExp(r'\[(\d+):(\d+)(?:\.(\d+))?\]');
      // Matches metadata tags like [ti:Song Title]
      final metadataRegex = RegExp(r'\[(\w+):(.+?)\]');

      for (var line in content.split('\n')) {
        line = line.trim();
        if (line.isEmpty) continue;

        // Check for metadata tags
        if (line.startsWith('[') && !timeTagRegex.hasMatch(line)) {
          final metadataMatch = metadataRegex.firstMatch(line);
          if (metadataMatch != null) {
            final tag = metadataMatch.group(1)?.toLowerCase();
            final value = metadataMatch.group(2)?.trim();

            switch (tag) {
              case 'ti':
                title = value;
                break;
              case 'ar':
                artist = value;
                break;
              case 'al':
                album = value;
                break;
              case 'by':
                creator = value;
                break;
              case 'offset':
                offset = int.tryParse(value ?? '');
                break;
            }
          }
          continue;
        }

        // Parse time-stamped lyrics
        final matches = timeTagRegex.allMatches(line);
        if (matches.isEmpty) continue;

        // Extract the text after all timestamps
        String text = line;
        for (final match in matches) {
          text = text.replaceFirst(match.group(0)!, '');
        }
        text = text.trim();

        // A line can have multiple timestamps (for repeated lyrics)
        for (final match in matches) {
          final minutes = int.parse(match.group(1)!);
          final seconds = int.parse(match.group(2)!);
          final centiseconds = match.group(3) != null
              ? int.parse(match.group(3)!.padRight(2, '0').substring(0, 2))
              : 0;

          final timestampMs = (minutes * 60 * 1000) +
              (seconds * 1000) +
              (centiseconds * 10);

          lines.add(LrcLine(
            timestampMs: timestampMs,
            text: text,
          ));
        }
      }

      // Sort lines by timestamp
      lines.sort((a, b) => a.timestampMs.compareTo(b.timestampMs));

      if (lines.isEmpty) {
        logDebug('LrcParser: no lyrics found in content');
        return null;
      }

      return Lyrics(
        lines: lines,
        title: title,
        artist: artist,
        album: album,
        creator: creator,
        offset: offset,
      );
    } catch (e, stackTrace) {
      logDebug('LrcParser: failed to parse string: $e');
      logDebug('LrcParser: $stackTrace');
      return null;
    }
  }

  /// Format timestamp in milliseconds to [mm:ss.xx] format
  static String formatTimestamp(int milliseconds) {
    final minutes = milliseconds ~/ 60000;
    final seconds = (milliseconds % 60000) ~/ 1000;
    final centiseconds = (milliseconds % 1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${centiseconds.toString().padLeft(2, '0')}';
  }
}