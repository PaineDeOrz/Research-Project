import 'package:flutter_test/flutter_test.dart';
import 'package:musik_app/models/lyrics/lrc_line.dart';
import 'package:musik_app/models/lyrics/lyrics.dart';

void main() {
  group('LrcLine', () {
    test('stores timestamp and text', () {
      const line = LrcLine(timestampMs: 5000, text: 'Hello world');

      expect(line.timestampMs, 5000);
      expect(line.text, 'Hello world');
    });

    test('equality based on timestamp and text', () {
      const line1 = LrcLine(timestampMs: 5000, text: 'Hello');
      const line2 = LrcLine(timestampMs: 5000, text: 'Hello');
      const line3 = LrcLine(timestampMs: 5000, text: 'World');
      const line4 = LrcLine(timestampMs: 6000, text: 'Hello');

      expect(line1, equals(line2));
      expect(line1, isNot(equals(line3)));
      expect(line1, isNot(equals(line4)));
    });

    test('toString format', () {
      const line = LrcLine(timestampMs: 5000, text: 'Test');
      expect(line.toString(), '[5000 ms] Test');
    });
  });

  group('Lyrics', () {

    group('isEmpty / isNotEmpty', () {
      test('isEmpty is true when no lines', () {
        const lyrics = Lyrics(lines: []);
        expect(lyrics.isEmpty, isTrue);
        expect(lyrics.isNotEmpty, isFalse);
      });

      test('isNotEmpty is true when has lines', () {
        const lyrics = Lyrics(lines: [
          LrcLine(timestampMs: 0, text: 'Line 1'),
        ]);
        expect(lyrics.isEmpty, isFalse);
        expect(lyrics.isNotEmpty, isTrue);
      });
    });


    group('metadata', () {
      test('stores optional metadata', () {
        const lyrics = Lyrics(
          lines: [],
          title: 'Song Title',
          artist: 'Artist Name',
          album: 'Album Name',
          creator: 'LRC Creator',
          offset: 500,
        );

        expect(lyrics.title, 'Song Title');
        expect(lyrics.artist, 'Artist Name');
        expect(lyrics.album, 'Album Name');
        expect(lyrics.creator, 'LRC Creator');
        expect(lyrics.offset, 500);
      });

      test('metadata defaults to null', () {
        const lyrics = Lyrics(lines: []);

        expect(lyrics.title, isNull);
        expect(lyrics.artist, isNull);
        expect(lyrics.album, isNull);
        expect(lyrics.creator, isNull);
        expect(lyrics.offset, isNull);
      });
    });


    group('getLineAtPosition()', () {
      test('returns null for empty lyrics', () {
        const lyrics = Lyrics(lines: []);

        expect(lyrics.getLineAtPosition(const Duration(seconds: 5)), isNull);
      });

      test('returns null before first line', () {
        const lyrics = Lyrics(lines: [
          LrcLine(timestampMs: 5000, text: 'First line'),
        ]);

        expect(lyrics.getLineAtPosition(const Duration(seconds: 2)), isNull);
        expect(lyrics.getLineAtPosition(Duration.zero), isNull);
      });

      test('returns first line at exact timestamp', () {
        const lyrics = Lyrics(lines: [
          LrcLine(timestampMs: 5000, text: 'First line'),
          LrcLine(timestampMs: 10000, text: 'Second line'),
        ]);

        final line = lyrics.getLineAtPosition(const Duration(milliseconds: 5000));
        expect(line?.text, 'First line');
      });

      test('returns current line between timestamps', () {
        const lyrics = Lyrics(lines: [
          LrcLine(timestampMs: 5000, text: 'First line'),
          LrcLine(timestampMs: 10000, text: 'Second line'),
          LrcLine(timestampMs: 15000, text: 'Third line'),
        ]);

        // At 7 seconds, should show first line
        var line = lyrics.getLineAtPosition(const Duration(seconds: 7));
        expect(line?.text, 'First line');

        // At 12 seconds, should show second line
        line = lyrics.getLineAtPosition(const Duration(seconds: 12));
        expect(line?.text, 'Second line');
      });

      test('returns last line after all timestamps', () {
        const lyrics = Lyrics(lines: [
          LrcLine(timestampMs: 5000, text: 'First line'),
          LrcLine(timestampMs: 10000, text: 'Last line'),
        ]);

        final line = lyrics.getLineAtPosition(const Duration(minutes: 5));
        expect(line?.text, 'Last line');
      });

      test('applies positive offset', () {
        // Positive offset means lyrics are ahead, so we add to position
        const lyrics = Lyrics(
          lines: [
            LrcLine(timestampMs: 5000, text: 'First line'),
          ],
          offset: 2000, // +2 seconds
        );

        // At 3 seconds real time, with +2s offset, effective time is 5s
        final line = lyrics.getLineAtPosition(const Duration(seconds: 3));
        expect(line?.text, 'First line');

        // At 2 seconds real time, effective time is 4s, still before first line
        final lineBefore = lyrics.getLineAtPosition(const Duration(seconds: 2));
        expect(lineBefore, isNull);
      });

      test('applies negative offset', () {
        // Negative offset means lyrics are behind
        const lyrics = Lyrics(
          lines: [
            LrcLine(timestampMs: 5000, text: 'First line'),
          ],
          offset: -2000, // -2 seconds
        );

        // At 5 seconds real time, with -2s offset, effective time is 3s
        final line = lyrics.getLineAtPosition(const Duration(seconds: 5));
        expect(line, isNull);

        // At 7 seconds real time, effective time is 5s
        final lineAfter = lyrics.getLineAtPosition(const Duration(seconds: 7));
        expect(lineAfter?.text, 'First line');
      });
    });


    group('getLineIndexAtPosition()', () {
      test('returns -1 for empty lyrics', () {
        const lyrics = Lyrics(lines: []);

        expect(lyrics.getLineIndexAtPosition(const Duration(seconds: 5)), -1);
      });

      test('returns -1 before first line', () {
        const lyrics = Lyrics(lines: [
          LrcLine(timestampMs: 5000, text: 'First line'),
        ]);

        expect(lyrics.getLineIndexAtPosition(const Duration(seconds: 2)), -1);
      });

      test('returns correct index at each line', () {
        const lyrics = Lyrics(lines: [
          LrcLine(timestampMs: 5000, text: 'Line 0'),
          LrcLine(timestampMs: 10000, text: 'Line 1'),
          LrcLine(timestampMs: 15000, text: 'Line 2'),
        ]);

        expect(lyrics.getLineIndexAtPosition(const Duration(seconds: 5)), 0);
        expect(lyrics.getLineIndexAtPosition(const Duration(seconds: 7)), 0);
        expect(lyrics.getLineIndexAtPosition(const Duration(seconds: 10)), 1);
        expect(lyrics.getLineIndexAtPosition(const Duration(seconds: 12)), 1);
        expect(lyrics.getLineIndexAtPosition(const Duration(seconds: 15)), 2);
        expect(lyrics.getLineIndexAtPosition(const Duration(seconds: 100)), 2);
      });

      test('applies offset to index lookup', () {
        const lyrics = Lyrics(
          lines: [
            LrcLine(timestampMs: 5000, text: 'Line 0'),
            LrcLine(timestampMs: 10000, text: 'Line 1'),
          ],
          offset: 3000,
        );

        // At 2 seconds + 3s offset = 5s effective, should be index 0
        expect(lyrics.getLineIndexAtPosition(const Duration(seconds: 2)), 0);

        // At 1 second + 3s offset = 4s effective, still before first line
        expect(lyrics.getLineIndexAtPosition(const Duration(seconds: 1)), -1);
      });
    });


    group('toString()', () {
      test('includes line count and metadata', () {
        const lyrics = Lyrics(
          lines: [
            LrcLine(timestampMs: 0, text: 'Line 1'),
            LrcLine(timestampMs: 5000, text: 'Line 2'),
          ],
          title: 'Test Song',
          artist: 'Test Artist',
        );

        final str = lyrics.toString();
        expect(str, contains('lines: 2'));
        expect(str, contains('title: Test Song'));
        expect(str, contains('artist: Test Artist'));
      });
    });


    group('edge cases', () {
      test('handles lines at timestamp 0', () {
        const lyrics = Lyrics(lines: [
          LrcLine(timestampMs: 0, text: 'Starts immediately'),
          LrcLine(timestampMs: 5000, text: 'Second line'),
        ]);

        expect(lyrics.getLineAtPosition(Duration.zero)?.text, 'Starts immediately');
        expect(lyrics.getLineIndexAtPosition(Duration.zero), 0);
      });

      test('handles single line', () {
        const lyrics = Lyrics(lines: [
          LrcLine(timestampMs: 5000, text: 'Only line'),
        ]);

        expect(lyrics.getLineAtPosition(const Duration(seconds: 4)), isNull);
        expect(lyrics.getLineAtPosition(const Duration(seconds: 5))?.text, 'Only line');
        expect(lyrics.getLineAtPosition(const Duration(minutes: 10))?.text, 'Only line');
      });

      test('handles empty text lines', () {
        const lyrics = Lyrics(lines: [
          LrcLine(timestampMs: 5000, text: ''),
          LrcLine(timestampMs: 10000, text: 'Has text'),
        ]);

        expect(lyrics.getLineAtPosition(const Duration(seconds: 7))?.text, '');
        expect(lyrics.getLineIndexAtPosition(const Duration(seconds: 7)), 0);
      });

      test('handles very long duration', () {
        const lyrics = Lyrics(lines: [
          LrcLine(timestampMs: 5000, text: 'Line'),
        ]);

        // 24 hours
        final line = lyrics.getLineAtPosition(const Duration(hours: 24));
        expect(line?.text, 'Line');
      });
    });
  });
}
