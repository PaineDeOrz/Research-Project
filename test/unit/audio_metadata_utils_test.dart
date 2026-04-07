import 'package:flutter_test/flutter_test.dart';
import 'package:musik_app/models/track.dart';
import 'package:musik_app/services/audio_metadata_utils.dart';

void main() {
  group('parseReplayGainValue', () {
    // The function is private, so we test it indirectly through behavior
    // or we can test the trackToDeviceSong conversion which is public
  });

  group('trackToDeviceSong', () {
    test('converts all fields correctly', () {
      final track = Track(
        trackId: '123',
        trackUri: 'content://media/123',
        trackTitle: 'Test Song',
        albumTitle: 'Test Album',
        albumId: '456',
        trackArtist: 'Test Artist',
        trackDuration: const Duration(minutes: 3, seconds: 30),
        trackPath: '/path/to/song.mp3',
        dateAdded: 1700000000,
        trackModifiedLast: 1700001000,
        trackSize: 5000000,
        trackNumber: 5,
        hasLrc: true,
        lrcPath: '/path/to/song.lrc',
        artworkThumbnailPath: '/path/to/thumb.jpg',
        artworkHqPath: '/path/to/hq.jpg',
        replayGainDb: -3.5,
      );

      final song = trackToDeviceSong(track);

      expect(song.id, 123);
      expect(song.title, 'Test Song');
      expect(song.album, 'Test Album');
      expect(song.albumId, 456);
      expect(song.artist, 'Test Artist');
      expect(song.uri, 'content://media/123');
      expect(song.data, '/path/to/song.mp3');
      expect(song.duration, 210000); // 3:30 in milliseconds
      expect(song.dateAdded, 1700000000);
      expect(song.dateModified, 1700001000);
      expect(song.size, 5000000);
      expect(song.track, 5);
      expect(song.hasLrc, true);
      expect(song.lrcPath, '/path/to/song.lrc');
      expect(song.artworkThumbnailPath, '/path/to/thumb.jpg');
      expect(song.artworkHqPath, '/path/to/hq.jpg');
      expect(song.replayGainDb, -3.5);
    });

    test('handles null optional fields', () {
      final track = Track(
        trackId: '1',
        trackUri: 'uri://1',
        trackTitle: 'Minimal Track',
        albumTitle: 'Album',
        albumId: '1',
        trackArtist: 'Artist',
        trackDuration: Duration.zero,
      );

      final song = trackToDeviceSong(track);

      expect(song.id, 1);
      expect(song.data, ''); // null trackPath becomes empty string
      expect(song.duration, 0);
      expect(song.dateAdded, isNull);
      expect(song.dateModified, isNull);
      expect(song.size, isNull);
      expect(song.track, isNull);
      expect(song.hasLrc, false);
      expect(song.lrcPath, isNull);
      expect(song.artworkThumbnailPath, isNull);
      expect(song.artworkHqPath, isNull);
      expect(song.replayGainDb, isNull);
    });

    test('parses numeric trackId correctly', () {
      final track = Track(
        trackId: '999',
        trackUri: 'uri://999',
        trackTitle: 'Track',
        albumTitle: 'Album',
        albumId: '100',
        trackArtist: 'Artist',
        trackDuration: const Duration(seconds: 60),
      );

      final song = trackToDeviceSong(track);

      expect(song.id, 999);
      expect(song.albumId, 100);
    });

    test('handles zero duration', () {
      final track = Track(
        trackId: '1',
        trackUri: 'uri://1',
        trackTitle: 'Track',
        albumTitle: 'Album',
        albumId: '1',
        trackArtist: 'Artist',
        trackDuration: Duration.zero,
      );

      final song = trackToDeviceSong(track);

      expect(song.duration, 0);
    });

    test('handles long duration', () {
      final track = Track(
        trackId: '1',
        trackUri: 'uri://1',
        trackTitle: 'Long Track',
        albumTitle: 'Album',
        albumId: '1',
        trackArtist: 'Artist',
        trackDuration: const Duration(hours: 2, minutes: 30),
      );

      final song = trackToDeviceSong(track);

      expect(song.duration, 9000000); // 2.5 hours in milliseconds
    });

    test('preserves positive replayGain', () {
      final track = Track(
        trackId: '1',
        trackUri: 'uri://1',
        trackTitle: 'Quiet Track',
        albumTitle: 'Album',
        albumId: '1',
        trackArtist: 'Artist',
        trackDuration: const Duration(seconds: 60),
        replayGainDb: 5.2,
      );

      final song = trackToDeviceSong(track);

      expect(song.replayGainDb, 5.2);
    });

    test('preserves negative replayGain', () {
      final track = Track(
        trackId: '1',
        trackUri: 'uri://1',
        trackTitle: 'Loud Track',
        albumTitle: 'Album',
        albumId: '1',
        trackArtist: 'Artist',
        trackDuration: const Duration(seconds: 60),
        replayGainDb: -8.7,
      );

      final song = trackToDeviceSong(track);

      expect(song.replayGainDb, -8.7);
    });

    test('preserves zero replayGain', () {
      final track = Track(
        trackId: '1',
        trackUri: 'uri://1',
        trackTitle: 'Normal Track',
        albumTitle: 'Album',
        albumId: '1',
        trackArtist: 'Artist',
        trackDuration: const Duration(seconds: 60),
        replayGainDb: 0.0,
      );

      final song = trackToDeviceSong(track);

      expect(song.replayGainDb, 0.0);
    });
  });
}
