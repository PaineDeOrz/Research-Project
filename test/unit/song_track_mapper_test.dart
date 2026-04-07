import 'package:flutter_test/flutter_test.dart';
import 'package:musik_app/models/device_song.dart';
import 'package:musik_app/models/track.dart';
import 'package:musik_app/models/mappers/song_track_mapper.dart';

void main() {
  group('deviceSongToTrack', () {
    test('converts all fields correctly', () {
      const song = DeviceSong(
        id: 123,
        title: 'Test Song',
        data: '/path/to/song.mp3',
        albumId: 456,
        album: 'Test Album',
        artist: 'Test Artist',
        uri: 'content://media/123',
        duration: 210000,
        dateAdded: 1700000000,
        dateModified: 1700001000,
        size: 5000000,
        track: 5,
        hasLrc: true,
        lrcPath: '/path/to/song.lrc',
        artworkThumbnailPath: '/path/to/thumb.jpg',
        artworkHqPath: '/path/to/hq.jpg',
        replayGainDb: -3.5,
      );

      final track = deviceSongToTrack(song);

      expect(track.trackId, '123');
      expect(track.trackTitle, 'Test Song');
      expect(track.trackPath, '/path/to/song.mp3');
      expect(track.albumId, '456');
      expect(track.albumTitle, 'Test Album');
      expect(track.trackArtist, 'Test Artist');
      expect(track.trackUri, 'content://media/123');
      expect(track.trackDuration, const Duration(milliseconds: 210000));
      expect(track.dateAdded, 1700000000);
      expect(track.trackModifiedLast, 1700001000);
      expect(track.trackSize, 5000000);
      expect(track.trackNumber, 5);
      expect(track.hasLrc, true);
      expect(track.lrcPath, '/path/to/song.lrc');
      expect(track.artworkThumbnailPath, '/path/to/thumb.jpg');
      expect(track.artworkHqPath, '/path/to/hq.jpg');
      expect(track.replayGainDb, -3.5);
    });

    test('handles null artist with fallback', () {
      const song = DeviceSong(
        id: 1,
        title: 'Track',
        data: '/path.mp3',
        artist: null,
      );

      final track = deviceSongToTrack(song);

      expect(track.trackArtist, 'Unknown Artist');
    });

    test('handles empty artist with fallback', () {
      const song = DeviceSong(
        id: 1,
        title: 'Track',
        data: '/path.mp3',
        artist: '',
      );

      final track = deviceSongToTrack(song);

      expect(track.trackArtist, 'Unknown Artist');
    });

    test('handles null duration as zero', () {
      const song = DeviceSong(
        id: 1,
        title: 'Track',
        data: '/path.mp3',
        duration: null,
      );

      final track = deviceSongToTrack(song);

      expect(track.trackDuration, Duration.zero);
    });

    test('converts null album to string "null"', () {
      const song = DeviceSong(
        id: 1,
        title: 'Track',
        data: '/path.mp3',
        album: null,
      );

      final track = deviceSongToTrack(song);

      expect(track.albumTitle, 'null');
    });
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
      expect(song.data, '/path/to/song.mp3');
      expect(song.albumId, 456);
      expect(song.album, 'Test Album');
      expect(song.artist, 'Test Artist');
      expect(song.uri, 'content://media/123');
      expect(song.duration, 210000);
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

    test('handles non-numeric trackId with fallback to 0', () {
      final track = Track(
        trackId: 'not-a-number',
        trackUri: 'uri://1',
        trackTitle: 'Track',
        albumTitle: 'Album',
        albumId: '1',
        trackArtist: 'Artist',
        trackDuration: Duration.zero,
      );

      final song = trackToDeviceSong(track);

      expect(song.id, 0);
    });

    test('handles null trackPath as empty string', () {
      final track = Track(
        trackId: '1',
        trackUri: 'uri://1',
        trackTitle: 'Track',
        albumTitle: 'Album',
        albumId: '1',
        trackArtist: 'Artist',
        trackDuration: Duration.zero,
        trackPath: null,
      );

      final song = trackToDeviceSong(track);

      expect(song.data, '');
    });
  });

  group('round-trip conversion', () {
    test('DeviceSong -> Track -> DeviceSong preserves data', () {
      const original = DeviceSong(
        id: 999,
        title: 'Round Trip Song',
        data: '/music/song.mp3',
        albumId: 100,
        album: 'Round Trip Album',
        artist: 'Round Trip Artist',
        uri: 'content://999',
        duration: 180000,
        dateAdded: 1600000000,
        dateModified: 1600001000,
        size: 3000000,
        track: 3,
        hasLrc: true,
        lrcPath: '/music/song.lrc',
        artworkThumbnailPath: '/art/thumb.jpg',
        artworkHqPath: '/art/hq.jpg',
        replayGainDb: 2.5,
      );

      final track = deviceSongToTrack(original);
      final converted = trackToDeviceSong(track);

      expect(converted.id, original.id);
      expect(converted.title, original.title);
      expect(converted.data, original.data);
      expect(converted.albumId, original.albumId);
      expect(converted.album, original.album);
      expect(converted.artist, original.artist);
      expect(converted.uri, original.uri);
      expect(converted.duration, original.duration);
      expect(converted.dateAdded, original.dateAdded);
      expect(converted.dateModified, original.dateModified);
      expect(converted.size, original.size);
      expect(converted.track, original.track);
      expect(converted.hasLrc, original.hasLrc);
      expect(converted.lrcPath, original.lrcPath);
      expect(converted.artworkThumbnailPath, original.artworkThumbnailPath);
      expect(converted.artworkHqPath, original.artworkHqPath);
      expect(converted.replayGainDb, original.replayGainDb);
    });

    test('Track -> DeviceSong -> Track preserves data', () {
      final original = Track(
        trackId: '888',
        trackUri: 'content://888',
        trackTitle: 'Another Song',
        albumTitle: 'Another Album',
        albumId: '200',
        trackArtist: 'Another Artist',
        trackDuration: const Duration(minutes: 4),
        trackPath: '/path/another.mp3',
        dateAdded: 1500000000,
        trackModifiedLast: 1500001000,
        trackSize: 4000000,
        trackNumber: 8,
        hasLrc: false,
        artworkThumbnailPath: '/thumb.jpg',
        replayGainDb: -1.0,
      );

      final song = trackToDeviceSong(original);
      final converted = deviceSongToTrack(song);

      expect(converted.trackId, original.trackId);
      expect(converted.trackTitle, original.trackTitle);
      expect(converted.trackPath, original.trackPath);
      expect(converted.albumId, original.albumId);
      expect(converted.albumTitle, original.albumTitle);
      expect(converted.trackArtist, original.trackArtist);
      expect(converted.trackUri, original.trackUri);
      expect(converted.trackDuration, original.trackDuration);
      expect(converted.dateAdded, original.dateAdded);
      expect(converted.trackModifiedLast, original.trackModifiedLast);
      expect(converted.trackSize, original.trackSize);
      expect(converted.trackNumber, original.trackNumber);
      expect(converted.hasLrc, original.hasLrc);
      expect(converted.artworkThumbnailPath, original.artworkThumbnailPath);
      expect(converted.replayGainDb, original.replayGainDb);
    });

    test('handles minimal data round-trip', () {
      const original = DeviceSong(
        id: 1,
        title: 'Minimal',
        data: '/m.mp3',
      );

      final track = deviceSongToTrack(original);
      final converted = trackToDeviceSong(track);

      expect(converted.id, original.id);
      expect(converted.title, original.title);
      expect(converted.data, original.data);
    });
  });

  group('DeviceSong equality', () {
    test('songs with same id are equal', () {
      const song1 = DeviceSong(id: 1, title: 'Song A', data: '/a.mp3');
      const song2 = DeviceSong(id: 1, title: 'Song B', data: '/b.mp3');

      expect(song1, equals(song2));
    });

    test('songs with different id are not equal', () {
      const song1 = DeviceSong(id: 1, title: 'Same', data: '/same.mp3');
      const song2 = DeviceSong(id: 2, title: 'Same', data: '/same.mp3');

      expect(song1, isNot(equals(song2)));
    });

    test('hashCode based on id', () {
      const song = DeviceSong(id: 42, title: 'Test', data: '/test.mp3');

      expect(song.hashCode, 42.hashCode);
    });
  });
}
