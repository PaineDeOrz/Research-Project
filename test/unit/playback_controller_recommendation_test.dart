// Tests for the recommendation/queue system so what happens after a song ends,
// shuffle behavior, gapless playback, etc.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musik_app/data/repositories/settings_repository.dart';
import 'package:musik_app/models/repeat_mode.dart';
import 'package:musik_app/models/track.dart';
import 'package:musik_app/playback/playback_queue.dart';
import 'package:musik_app/playback/gapless_playback_handler.dart';
import 'package:musik_app/services/audio_library_service.dart';

// Mocks for gapless playback tests
class MockAudioPlayer extends Mock implements AudioPlayer {}
class MockAudioLibraryService extends Mock implements AudioLibraryService {}
class FakeTrack extends Fake implements Track {}
class FakeAudioSource extends Fake implements AudioSource {}

Track _track(int id, {String? artist, String? album, double? replayGainDb}) => Track(
      trackId: '$id',
      trackUri: 'uri://$id',
      trackTitle: 'Track $id',
      albumTitle: album ?? 'Album',
      albumId: '1',
      trackArtist: artist ?? 'Artist',
      trackDuration: const Duration(seconds: 180),
      trackPath: '/path/to/track$id.mp3',
      replayGainDb: replayGainDb,
    );

List<Track> _tracks(int count, {String? artist}) =>
    List.generate(count, (i) => _track(i + 1, artist: artist));

class FakeSettingsRepository extends SettingsRepository {
  SingleTrackBehavior _singleTrackBehavior = SingleTrackBehavior.playSimilar;
  bool _volumeNormalization = true;
  bool _gaplessPlayback = true;

  @override
  SingleTrackBehavior get singleTrackBehavior => _singleTrackBehavior;

  @override
  bool get volumeNormalization => _volumeNormalization;

  @override
  bool get gaplessPlayback => _gaplessPlayback;

  void setBehavior(SingleTrackBehavior b) => _singleTrackBehavior = b;
  void setNormalization(bool v) => _volumeNormalization = v;
  void setGapless(bool v) => _gaplessPlayback = v;
}

class FakePlaylistsRepository {
  List<Track> _similarTracks = [];
  int callCount = 0;
  String? lastTrackId;

  void setSimilarTracks(List<Track> tracks) {
    _similarTracks = tracks;
  }

  Future<List<Track>> getSimilarTracks(String trackId, {int limit = 20}) async {
    callCount++;
    lastTrackId = trackId;
    return _similarTracks.take(limit).toList();
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTrack());
    registerFallbackValue(FakeAudioSource());
    registerFallbackValue(LoopMode.off);
    registerFallbackValue(Duration.zero);
    registerFallbackValue(<AudioSource>[]);
  });

  late FakeSettingsRepository fakeSettings;
  late FakePlaylistsRepository fakePlaylistsRepo;
  late PlaybackQueue queue;

  setUp(() {
    fakeSettings = FakeSettingsRepository();
    fakePlaylistsRepo = FakePlaylistsRepository();
    queue = PlaybackQueue();

    GetIt.I.reset();
    GetIt.I.registerSingleton<SettingsRepository>(fakeSettings);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  group('queue behavior after song ends', () {
    group('single track', () {
      test('returns null when done and repeat is off', () {
        queue.setQueue([_track(1)]);
        queue.setRepeatMode(RepeatMode.off);

        final nextTrack = queue.next();

        expect(nextTrack, isNull);
        expect(queue.currentIndex, 0);
      });

      test('keeps playing same track with repeat one', () {
        queue.setQueue([_track(1)]);
        queue.setRepeatMode(RepeatMode.one);

        final nextTrack = queue.next();

        expect(nextTrack, isNotNull);
        expect(nextTrack?.trackId, '1');
      });

      test('loops with repeat all even for single track', () {
        queue.setQueue([_track(1)]);
        queue.setRepeatMode(RepeatMode.all);

        final nextTrack = queue.next();

        expect(nextTrack, isNotNull);
        expect(nextTrack?.trackId, '1');
      });
    });

    group('multi-track queue', () {
      test('advances through all tracks then stops', () {
        queue.setQueue(_tracks(3));
        queue.setRepeatMode(RepeatMode.off);

        expect(queue.current?.trackId, '1');
        expect(queue.next()?.trackId, '2');
        expect(queue.next()?.trackId, '3');
        expect(queue.next(), isNull);
      });

      test('loops back to start with repeat all', () {
        queue.setQueue(_tracks(3));
        queue.setRepeatMode(RepeatMode.all);

        queue.next();
        queue.next();
        final looped = queue.next();

        expect(looped?.trackId, '1');
      });

      test('stays on same track with repeat one', () {
        queue.setQueue(_tracks(3));
        queue.setRepeatMode(RepeatMode.one);

        expect(queue.current?.trackId, '1');
        expect(queue.next()?.trackId, '1');
        expect(queue.next()?.trackId, '1');
      });
    });

    group('shuffle', () {
      test('current track moves to position 0 when enabled', () {
        queue.setQueue(_tracks(5), startIndex: 2);
        final currentBefore = queue.current;

        queue.setShuffleEnabled(true);

        expect(queue.currentIndex, 0);
        expect(queue.current?.trackId, currentBefore?.trackId);
      });

      test('with repeat all loops through shuffled order', () {
        queue.setQueue(_tracks(3));
        queue.setShuffleEnabled(true);
        queue.setRepeatMode(RepeatMode.all);

        final firstTrack = queue.current;
        queue.next();
        queue.next();
        final afterLoop = queue.next();

        expect(afterLoop?.trackId, firstTrack?.trackId);
      });

      test('repeat one ignores shuffle - stays on same track', () {
        queue.setQueue(_tracks(5), startIndex: 2);
        queue.setShuffleEnabled(true);
        queue.setRepeatMode(RepeatMode.one);

        final current = queue.current;
        final next1 = queue.next();
        final next2 = queue.next();

        expect(next1?.trackId, current?.trackId);
        expect(next2?.trackId, current?.trackId);
      });

      test('disabling restores original order', () {
        queue.setQueue(_tracks(5), startIndex: 2);
        queue.setShuffleEnabled(true);
        queue.setShuffleEnabled(false);

        expect(queue.current?.trackId, '3');
        expect(queue.shuffleEnabled, isFalse);
      });

      test('all tracks still present after shuffle', () {
        final tracks = _tracks(10);
        queue.setQueue(tracks);
        queue.setShuffleEnabled(true);

        final shuffledIds = queue.tracks.map((t) => t.trackId).toSet();
        final originalIds = tracks.map((t) => t.trackId).toSet();

        expect(shuffledIds, equals(originalIds));
      });
    });
  });

  group('single track behavior', () {
    test('playSimilar is the default', () {
      expect(fakeSettings.singleTrackBehavior, SingleTrackBehavior.playSimilar);
    });

    test('can change to repeat', () {
      fakeSettings.setBehavior(SingleTrackBehavior.repeat);
      expect(fakeSettings.singleTrackBehavior, SingleTrackBehavior.repeat);
    });

    test('can change to stop', () {
      fakeSettings.setBehavior(SingleTrackBehavior.stop);
      expect(fakeSettings.singleTrackBehavior, SingleTrackBehavior.stop);
    });
  });

  group('similar tracks', () {
    test('returns configured tracks', () async {
      final similarTracks = _tracks(5, artist: 'Similar Artist');
      fakePlaylistsRepo.setSimilarTracks(similarTracks);

      final result = await fakePlaylistsRepo.getSimilarTracks('1', limit: 10);

      expect(result.length, 5);
      expect(result.first.trackArtist, 'Similar Artist');
    });

    test('respects limit', () async {
      fakePlaylistsRepo.setSimilarTracks(_tracks(20));

      final result = await fakePlaylistsRepo.getSimilarTracks('1', limit: 5);

      expect(result.length, 5);
    });

    test('returns empty when none exist', () async {
      fakePlaylistsRepo.setSimilarTracks([]);

      final result = await fakePlaylistsRepo.getSimilarTracks('1');

      expect(result, isEmpty);
    });

    test('remembers which track ID was requested', () async {
      fakePlaylistsRepo.setSimilarTracks(_tracks(3));

      await fakePlaylistsRepo.getSimilarTracks('42', limit: 10);

      expect(fakePlaylistsRepo.lastTrackId, '42');
    });
  });

  group('edge cases', () {
    test('empty queue is safe to call next/previous', () {
      expect(queue.next(), isNull);
      expect(queue.previous(), isNull);
      expect(queue.current, isNull);
    });

    test('single track with shuffle still works', () {
      queue.setQueue([_track(1)]);
      queue.setShuffleEnabled(true);

      expect(queue.length, 1);
      expect(queue.current?.trackId, '1');
      expect(queue.hasNext, isFalse);
    });

    test('clear resets everything but keeps shuffle state', () {
      queue.setQueue(_tracks(5), startIndex: 2);
      queue.setShuffleEnabled(true);

      queue.clear();

      expect(queue.length, 0);
      expect(queue.currentIndex, -1);
      expect(queue.shuffleEnabled, isTrue);
    });

    // regression - calling setShuffleEnabled(true) twice was reshuffling
    test('setting shuffle true twice does not reshuffle', () {
      queue.setQueue(_tracks(5));
      queue.setShuffleEnabled(true);
      final firstOrder = queue.tracks.map((t) => t.trackId).toList();

      queue.setShuffleEnabled(true);

      expect(queue.tracks.map((t) => t.trackId).toList(), equals(firstOrder));
    });

    test('bad start index gets clamped', () {
      queue.setQueue(_tracks(3), startIndex: -10);
      expect(queue.currentIndex, 0);

      queue.setQueue(_tracks(3), startIndex: 100);
      expect(queue.currentIndex, 2);
    });
  });

  group('settings defaults', () {
    test('volume normalization on by default', () {
      expect(fakeSettings.volumeNormalization, isTrue);
    });

    test('gapless playback on by default', () {
      expect(fakeSettings.gaplessPlayback, isTrue);
    });

    test('track replayGain value is preserved', () {
      final track = _track(1, replayGainDb: -3.5);
      expect(track.replayGainDb, -3.5);

      final noGain = _track(2);
      expect(noGain.replayGainDb, isNull);
    });
  });

  group('tricky scenarios', () {
    test('same track multiple times in queue', () {
      final track = _track(1);
      queue.setQueue([track, track, track]);

      expect(queue.length, 3);
      expect(queue.next()?.trackId, '1');
      expect(queue.next()?.trackId, '1');
      expect(queue.next(), isNull);
    });

    test('rapid next/prev stays consistent', () {
      queue.setQueue(_tracks(5), startIndex: 2);

      queue.next();     // 3
      queue.previous(); // 2
      queue.next();     // 3
      queue.next();     // 4
      queue.previous(); // 3
      queue.previous(); // 2

      expect(queue.current?.trackId, '3');
    });

    test('shuffle toggle spam preserves current track', () {
      queue.setQueue(_tracks(10), startIndex: 5);
      final original = queue.current;

      for (var i = 0; i < 20; i++) {
        queue.setShuffleEnabled(i.isOdd);
      }

      expect(queue.current?.trackId, original?.trackId);
    });

    // regression - adding track at end when already at end
    test('add track at end of queue makes it reachable', () {
      queue.setQueue(_tracks(2));
      queue.next();
      queue.next(); // null, at end

      queue.addToEnd(_track(3));

      expect(queue.hasNext, isTrue);
      expect(queue.next()?.trackId, '3');
    });

    test('changing repeat mode at end of queue', () {
      queue.setQueue(_tracks(3));
      queue.next();
      queue.next();
      expect(queue.next(), isNull); // at end

      queue.setRepeatMode(RepeatMode.all);

      expect(queue.next()?.trackId, '1'); // now loops
    });
  });

  group('single track behavior + queue', () {
    test('stop behavior - queue ends normally', () {
      fakeSettings.setBehavior(SingleTrackBehavior.stop);
      queue.setQueue([_track(1)]);

      expect(queue.next(), isNull);
    });

    test('playSimilar with no similar tracks returns empty', () async {
      fakeSettings.setBehavior(SingleTrackBehavior.playSimilar);
      fakePlaylistsRepo.setSimilarTracks([]);

      final result = await fakePlaylistsRepo.getSimilarTracks('1');

      expect(result, isEmpty);
    });

    // SingleTrackBehavior only applies to single track plays, not queues
    test('queue play ignores SingleTrackBehavior', () {
      fakeSettings.setBehavior(SingleTrackBehavior.stop);
      queue.setQueue(_tracks(3));

      expect(queue.next()?.trackId, '2');
      expect(queue.next()?.trackId, '3');
      expect(queue.next(), isNull);
    });
  });

  group('listeners', () {
    test('setQueue notifies', () {
      var called = false;
      queue.addListener(() => called = true);

      queue.setQueue(_tracks(3));

      expect(called, isTrue);
    });

    test('next at end does NOT notify', () {
      queue.setQueue([_track(1)]);
      var called = false;
      queue.addListener(() => called = true);

      queue.next();

      expect(called, isFalse);
    });

    test('all listeners get called', () {
      var a = 0, b = 0, c = 0;
      queue.addListener(() => a++);
      queue.addListener(() => b++);
      queue.addListener(() => c++);

      queue.setQueue(_tracks(3));

      expect(a, 1);
      expect(b, 1);
      expect(c, 1);
    });
  });

  group('stress tests', () {
    test('100 track queue with lots of operations', () {
      queue.setQueue(_tracks(100), startIndex: 50);

      for (var i = 0; i < 25; i++) queue.next();
      for (var i = 0; i < 10; i++) queue.previous();

      queue.setShuffleEnabled(true);
      queue.addAllToEnd(_tracks(20));

      expect(queue.length, 120);
      expect(queue.current, isNotNull);
    });

    test('toggle shuffle 100 times', () {
      queue.setQueue(_tracks(20), startIndex: 10);
      final original = queue.current;

      for (var i = 0; i < 100; i++) {
        queue.setShuffleEnabled(i.isEven);
      }

      expect(queue.shuffleEnabled, isFalse);
      expect(queue.current?.trackId, original?.trackId);
    });
  });

  group('GaplessPlaybackHandler', () {
    late MockAudioPlayer mockPlayer;
    late MockAudioLibraryService mockLibrary;
    late GaplessPlaybackHandler handler;
    late List<(Track, bool)> trackChanges;
    late StreamController<int?> indexStreamController;

    setUp(() {
      mockPlayer = MockAudioPlayer();
      mockLibrary = MockAudioLibraryService();
      trackChanges = [];
      indexStreamController = StreamController<int?>.broadcast();

      when(() => mockPlayer.currentIndexStream)
          .thenAnswer((_) => indexStreamController.stream);
      when(() => mockPlayer.playing).thenReturn(false);

      handler = GaplessPlaybackHandler(
        player: mockPlayer,
        audioLibraryService: mockLibrary,
        onTrackChanged: (track, playing) async {
          trackChanges.add((track, playing));
        },
      );
    });

    tearDown(() async {
      await indexStreamController.close();
      await handler.dispose();
    });

    test('starts inactive', () {
      expect(handler.isActive, isFalse);
      expect(handler.tracks, isEmpty);
    });

    test('startPlayback activates handler and sets tracks', () async {
      final tracks = _tracks(3);

      when(() => mockLibrary.getTrackUri(any()))
          .thenAnswer((inv) async => Uri.parse('file:///track.mp3'));
      when(() => mockPlayer.setAudioSources(any(), initialIndex: any(named: 'initialIndex')))
          .thenAnswer((_) async => null);
      when(() => mockPlayer.setLoopMode(any()))
          .thenAnswer((_) async {});

      final success = await handler.startPlayback(
        tracks: tracks,
        startIndex: 0,
        repeatMode: RepeatMode.off,
      );

      expect(success, isTrue);
      expect(handler.isActive, isTrue);
      expect(handler.tracks.length, 3);
    });

    test('startPlayback fails with empty tracks', () async {
      final success = await handler.startPlayback(
        tracks: [],
        startIndex: 0,
        repeatMode: RepeatMode.off,
      );

      expect(success, isFalse);
      expect(handler.isActive, isFalse);
    });

    test('track change callback fires on index change', () async {
      final tracks = _tracks(3);

      when(() => mockLibrary.getTrackUri(any()))
          .thenAnswer((_) async => Uri.parse('file:///track.mp3'));
      when(() => mockPlayer.setAudioSources(any(), initialIndex: any(named: 'initialIndex')))
          .thenAnswer((_) async => null);
      when(() => mockPlayer.setLoopMode(any()))
          .thenAnswer((_) async {});
      when(() => mockPlayer.playing).thenReturn(true);

      await handler.startPlayback(
        tracks: tracks,
        startIndex: 0,
        repeatMode: RepeatMode.off,
      );

      handler.startListening();
      indexStreamController.add(1);

      // give stream time to process
      await Future.delayed(Duration.zero);

      expect(trackChanges.length, 1);
      expect(trackChanges.first.$1.trackId, '2');
      expect(trackChanges.first.$2, isTrue);
    });

    test('deactivate clears state', () async {
      final tracks = _tracks(3);

      when(() => mockLibrary.getTrackUri(any()))
          .thenAnswer((_) async => Uri.parse('file:///track.mp3'));
      when(() => mockPlayer.setAudioSources(any(), initialIndex: any(named: 'initialIndex')))
          .thenAnswer((_) async => null);
      when(() => mockPlayer.setLoopMode(any()))
          .thenAnswer((_) async {});

      await handler.startPlayback(
        tracks: tracks,
        startIndex: 0,
        repeatMode: RepeatMode.off,
      );

      handler.deactivate();

      expect(handler.isActive, isFalse);
      expect(handler.tracks, isEmpty);
    });

    test('syncLoopMode maps repeat modes correctly', () async {
      final tracks = _tracks(2);

      when(() => mockLibrary.getTrackUri(any()))
          .thenAnswer((_) async => Uri.parse('file:///track.mp3'));
      when(() => mockPlayer.setAudioSources(any(), initialIndex: any(named: 'initialIndex')))
          .thenAnswer((_) async => null);
      when(() => mockPlayer.setLoopMode(any()))
          .thenAnswer((_) async {});

      await handler.startPlayback(
        tracks: tracks,
        startIndex: 0,
        repeatMode: RepeatMode.off,
      );

      // clear calls from startPlayback
      clearInteractions(mockPlayer);

      await handler.syncLoopMode(RepeatMode.one);
      verify(() => mockPlayer.setLoopMode(LoopMode.one)).called(1);

      await handler.syncLoopMode(RepeatMode.all);
      verify(() => mockPlayer.setLoopMode(LoopMode.all)).called(1);

      await handler.syncLoopMode(RepeatMode.off);
      verify(() => mockPlayer.setLoopMode(LoopMode.off)).called(1);
    });

    test('addTrack appends to active playlist', () async {
      final tracks = _tracks(2);

      when(() => mockLibrary.getTrackUri(any()))
          .thenAnswer((_) async => Uri.parse('file:///track.mp3'));
      when(() => mockPlayer.setAudioSources(any(), initialIndex: any(named: 'initialIndex')))
          .thenAnswer((_) async => null);
      when(() => mockPlayer.setLoopMode(any()))
          .thenAnswer((_) async {});
      when(() => mockPlayer.addAudioSource(any()))
          .thenAnswer((_) async {});

      await handler.startPlayback(
        tracks: tracks,
        startIndex: 0,
        repeatMode: RepeatMode.off,
      );

      await handler.addTrack(_track(99));

      expect(handler.tracks.length, 3);
      expect(handler.tracks.last.trackId, '99');
    });

    test('seekToIndex does nothing when inactive', () async {
      await handler.seekToIndex(0);

      verifyNever(() => mockPlayer.seek(any(), index: any(named: 'index')));
    });

    test('seekToIndex does nothing for invalid index', () async {
      final tracks = _tracks(3);

      when(() => mockLibrary.getTrackUri(any()))
          .thenAnswer((_) async => Uri.parse('file:///track.mp3'));
      when(() => mockPlayer.setAudioSources(any(), initialIndex: any(named: 'initialIndex')))
          .thenAnswer((_) async => null);
      when(() => mockPlayer.setLoopMode(any()))
          .thenAnswer((_) async {});

      await handler.startPlayback(
        tracks: tracks,
        startIndex: 0,
        repeatMode: RepeatMode.off,
      );

      await handler.seekToIndex(-1);
      await handler.seekToIndex(100);

      verifyNever(() => mockPlayer.seek(any(), index: any(named: 'index')));
    });

    test('seekToIndex works for valid index', () async {
      final tracks = _tracks(3);

      when(() => mockLibrary.getTrackUri(any()))
          .thenAnswer((_) async => Uri.parse('file:///track.mp3'));
      when(() => mockPlayer.setAudioSources(any(), initialIndex: any(named: 'initialIndex')))
          .thenAnswer((_) async => null);
      when(() => mockPlayer.setLoopMode(any()))
          .thenAnswer((_) async {});
      when(() => mockPlayer.seek(any(), index: any(named: 'index')))
          .thenAnswer((_) async {});

      await handler.startPlayback(
        tracks: tracks,
        startIndex: 0,
        repeatMode: RepeatMode.off,
      );

      await handler.seekToIndex(2);

      verify(() => mockPlayer.seek(Duration.zero, index: 2)).called(1);
    });

    test('ignores index changes when not active', () async {
      handler.startListening();
      indexStreamController.add(0);

      await Future.delayed(Duration.zero);

      expect(trackChanges, isEmpty);
    });

    test('ignores null index', () async {
      final tracks = _tracks(3);

      when(() => mockLibrary.getTrackUri(any()))
          .thenAnswer((_) async => Uri.parse('file:///track.mp3'));
      when(() => mockPlayer.setAudioSources(any(), initialIndex: any(named: 'initialIndex')))
          .thenAnswer((_) async => null);
      when(() => mockPlayer.setLoopMode(any()))
          .thenAnswer((_) async {});

      await handler.startPlayback(
        tracks: tracks,
        startIndex: 0,
        repeatMode: RepeatMode.off,
      );

      handler.startListening();
      indexStreamController.add(null);

      await Future.delayed(Duration.zero);

      expect(trackChanges, isEmpty);
    });

    test('ignores out of bounds index', () async {
      final tracks = _tracks(3);

      when(() => mockLibrary.getTrackUri(any()))
          .thenAnswer((_) async => Uri.parse('file:///track.mp3'));
      when(() => mockPlayer.setAudioSources(any(), initialIndex: any(named: 'initialIndex')))
          .thenAnswer((_) async => null);
      when(() => mockPlayer.setLoopMode(any()))
          .thenAnswer((_) async {});

      await handler.startPlayback(
        tracks: tracks,
        startIndex: 0,
        repeatMode: RepeatMode.off,
      );

      handler.startListening();
      indexStreamController.add(99);

      await Future.delayed(Duration.zero);

      expect(trackChanges, isEmpty);
    });
  });
}
