import 'package:flutter_test/flutter_test.dart';
import 'package:musik_app/services/lrc_parser_service.dart';

void main() {
  group('LrcParserService.parseString', () {
    test('parses metadata tags', () {
      final lyrics = LrcParserService.parseString('''
      [ti:Test Song]
      [ar:Test Artist]
      [al:Test Album]
      [by:Test Creator]
      [offset:500]
      [00:01.00]First line
      ''');

      expect(lyrics, isNotNull);
      expect(lyrics!.title, 'Test Song');
      expect(lyrics.artist, 'Test Artist');
      expect(lyrics.album, 'Test Album');
      expect(lyrics.creator, 'Test Creator');
      expect(lyrics.offset, 500);
    });

    test('parses timed lyrics with centiseconds', () {
      final lyrics = LrcParserService.parseString('''
      [00:05.20]Hello world
      [00:10.50]Second line
      ''');

      expect(lyrics, isNotNull);
      expect(lyrics!.lines.length, 2);
      expect(lyrics.lines[0].text, 'Hello world');
      expect(lyrics.lines[0].timestampMs, 5200);
      expect(lyrics.lines[1].text, 'Second line');
      expect(lyrics.lines[1].timestampMs, 10500);
    });

    test('parses timestamps without centiseconds', () {
      final lyrics = LrcParserService.parseString('[01:30]No centiseconds');

      expect(lyrics, isNotNull);
      expect(lyrics!.lines.first.timestampMs, 90000);
    });

    test('handles multiple timestamps on one line', () {
      final lyrics = LrcParserService.parseString(
        '[00:10.00][00:30.00]Repeated lyric',
      );

      expect(lyrics, isNotNull);
      expect(lyrics!.lines.length, 2);
      expect(lyrics.lines[0].timestampMs, 10000);
      expect(lyrics.lines[1].timestampMs, 30000);
      expect(lyrics.lines[0].text, 'Repeated lyric');
      expect(lyrics.lines[1].text, 'Repeated lyric');
    });

    test('sorts lines by timestamp', () {
      final lyrics = LrcParserService.parseString('''
      [00:20.00]Second
      [00:05.00]First
      [00:40.00]Third
      ''');

      expect(lyrics!.lines[0].text, 'First');
      expect(lyrics.lines[1].text, 'Second');
      expect(lyrics.lines[2].text, 'Third');
    });

    test('returns null for empty content', () {
      expect(LrcParserService.parseString(''), isNull);
    });

    test('returns null for content with no timed lines', () {
      expect(LrcParserService.parseString('[ti:Just metadata]'), isNull);
    });
  });

  group('LrcParserService.formatTimestamp', () {
    test('formats zero', () {
      expect(LrcParserService.formatTimestamp(0), '00:00.00');
    });

    test('formats minutes and seconds', () {
      expect(LrcParserService.formatTimestamp(90000), '01:30.00');
    });

    test('formats with centiseconds', () {
      expect(LrcParserService.formatTimestamp(5200), '00:05.20');
    });
  });
}
