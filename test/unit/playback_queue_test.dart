import 'package:flutter_test/flutter_test.dart';
import 'package:musik_app/models/repeat_mode.dart';
import 'package:musik_app/models/track.dart';
import 'package:musik_app/playback/playback_queue.dart';

Track _track(int id) => Track(
      trackId: '$id',
      trackUri: 'uri://$id',
      trackTitle: 'Track $id',
      albumTitle: 'Album',
      albumId: '1',
      trackArtist: 'Artist',
      trackDuration: const Duration(seconds: 180),
    );

void main() {
  group('PlaybackQueue', () {
    late PlaybackQueue queue;

    setUp(() {
      queue = PlaybackQueue();
    });

    group('initial state', () {
      test('starts empty', () {
        expect(queue.length, 0);
        expect(queue.tracks, isEmpty);
        expect(queue.currentIndex, -1);
        expect(queue.current, isNull);
      });

      test('has no next or previous', () {
        expect(queue.hasNext, isFalse);
        expect(queue.hasPrevious, isFalse);
      });

      test('shuffle is disabled by default', () {
        expect(queue.shuffleEnabled, isFalse);
      });

      test('repeat mode is off by default', () {
        expect(queue.repeatMode, RepeatMode.off);
      });
    });

    group('setQueue', () {
      test('sets tracks and starts at index 0 by default', () {
        final tracks = [_track(1), _track(2), _track(3)];
        queue.setQueue(tracks);

        expect(queue.length, 3);
        expect(queue.currentIndex, 0);
        expect(queue.current?.trackId, '1');
      });

      test('can start at a specific index', () {
        final tracks = [_track(1), _track(2), _track(3)];
        queue.setQueue(tracks, startIndex: 2);

        expect(queue.currentIndex, 2);
        expect(queue.current?.trackId, '3');
      });

      test('clamps startIndex to valid range', () {
        final tracks = [_track(1), _track(2)];

        queue.setQueue(tracks, startIndex: 100);
        expect(queue.currentIndex, 1); // clamped to last index

        queue.setQueue(tracks, startIndex: -5);
        expect(queue.currentIndex, 0); // clamped to 0
      });

      test('handles empty list', () {
        queue.setQueue([]);

        expect(queue.length, 0);
        expect(queue.currentIndex, -1);
        expect(queue.current, isNull);
      });

      test('replaces existing queue', () {
        queue.setQueue([_track(1), _track(2)]);
        queue.setQueue([_track(10), _track(20), _track(30)]);

        expect(queue.length, 3);
        expect(queue.tracks.map((t) => t.trackId), ['10', '20', '30']);
      });
    });

    group('addToEnd', () {
      test('adds track to end of queue', () {
        queue.setQueue([_track(1), _track(2)]);
        queue.addToEnd(_track(3));

        expect(queue.length, 3);
        expect(queue.tracks.last.trackId, '3');
      });

      test('does not change current index', () {
        queue.setQueue([_track(1), _track(2)], startIndex: 1);
        queue.addToEnd(_track(3));

        expect(queue.currentIndex, 1);
        expect(queue.current?.trackId, '2');
      });
    });

    group('addAllToEnd', () {
      test('adds multiple tracks to end', () {
        queue.setQueue([_track(1)]);
        queue.addAllToEnd([_track(2), _track(3), _track(4)]);

        expect(queue.length, 4);
        expect(queue.tracks.map((t) => t.trackId), ['1', '2', '3', '4']);
      });
    });


    group('clear', () {
      test('removes all tracks', () {
        queue.setQueue([_track(1), _track(2), _track(3)]);
        queue.clear();

        expect(queue.length, 0);
        expect(queue.currentIndex, -1);
        expect(queue.current, isNull);
      });
    });


    group('next()', () {
      test('advances to next track', () {
        queue.setQueue([_track(1), _track(2), _track(3)]);

        final next = queue.next();

        expect(next?.trackId, '2');
        expect(queue.currentIndex, 1);
      });

      test('returns null at end of queue (repeat off)', () {
        queue.setQueue([_track(1), _track(2)], startIndex: 1);

        final next = queue.next();

        expect(next, isNull);
        expect(queue.currentIndex, 1); // stays at last
      });

      test('wraps to beginning when repeat all', () {
        queue.setQueue([_track(1), _track(2)], startIndex: 1);
        queue.setRepeatMode(RepeatMode.all);

        final next = queue.next();

        expect(next?.trackId, '1');
        expect(queue.currentIndex, 0);
      });

      test('returns same track when repeat one', () {
        queue.setQueue([_track(1), _track(2)], startIndex: 0);
        queue.setRepeatMode(RepeatMode.one);

        final next = queue.next();

        expect(next?.trackId, '1');
        expect(queue.currentIndex, 0);
      });

      test('returns null on empty queue', () {
        expect(queue.next(), isNull);
      });
    });


    group('previous()', () {
      test('goes to previous track', () {
        queue.setQueue([_track(1), _track(2), _track(3)], startIndex: 2);

        final prev = queue.previous();

        expect(prev?.trackId, '2');
        expect(queue.currentIndex, 1);
      });

      test('returns null at beginning of queue (repeat off)', () {
        queue.setQueue([_track(1), _track(2)], startIndex: 0);

        final prev = queue.previous();

        expect(prev, isNull);
        expect(queue.currentIndex, 0); // stays at first
      });

      test('wraps to end when repeat all', () {
        queue.setQueue([_track(1), _track(2), _track(3)], startIndex: 0);
        queue.setRepeatMode(RepeatMode.all);

        final prev = queue.previous();

        expect(prev?.trackId, '3');
        expect(queue.currentIndex, 2);
      });

      test('returns same track when repeat one', () {
        queue.setQueue([_track(1), _track(2)], startIndex: 1);
        queue.setRepeatMode(RepeatMode.one);

        final prev = queue.previous();

        expect(prev?.trackId, '2');
        expect(queue.currentIndex, 1);
      });

      test('returns null on empty queue', () {
        expect(queue.previous(), isNull);
      });
    });


    group('setCurrentIndex', () {
      test('changes current track', () {
        queue.setQueue([_track(1), _track(2), _track(3)]);
        queue.setCurrentIndex(2);

        expect(queue.currentIndex, 2);
        expect(queue.current?.trackId, '3');
      });

      test('ignores invalid index (too high)', () {
        queue.setQueue([_track(1), _track(2)]);
        queue.setCurrentIndex(10);

        expect(queue.currentIndex, 0); // unchanged
      });

      test('ignores invalid index (negative)', () {
        queue.setQueue([_track(1), _track(2)]);
        queue.setCurrentIndex(-1);

        expect(queue.currentIndex, 0); // unchanged
      });
    });


    group('hasNext / hasPrevious', () {
      test('hasNext is true when not at end', () {
        queue.setQueue([_track(1), _track(2), _track(3)], startIndex: 0);
        expect(queue.hasNext, isTrue);

        queue.setCurrentIndex(1);
        expect(queue.hasNext, isTrue);
      });

      test('hasNext is false at last track', () {
        queue.setQueue([_track(1), _track(2)], startIndex: 1);
        expect(queue.hasNext, isFalse);
      });

      test('hasPrevious is true when not at beginning', () {
        queue.setQueue([_track(1), _track(2), _track(3)], startIndex: 2);
        expect(queue.hasPrevious, isTrue);

        queue.setCurrentIndex(1);
        expect(queue.hasPrevious, isTrue);
      });

      test('hasPrevious is false at first track', () {
        queue.setQueue([_track(1), _track(2)], startIndex: 0);
        expect(queue.hasPrevious, isFalse);
      });
    });


    group('shuffle', () {
      test('enabling shuffle keeps current track at index 0', () {
        queue.setQueue([_track(1), _track(2), _track(3), _track(4), _track(5)], startIndex: 2);
        final currentBefore = queue.current;

        queue.setShuffleEnabled(true);

        expect(queue.shuffleEnabled, isTrue);
        expect(queue.currentIndex, 0);
        expect(queue.current?.trackId, currentBefore?.trackId);
      });

      test('disabling shuffle restores original order', () {
        queue.setQueue([_track(1), _track(2), _track(3)], startIndex: 1);
        queue.setShuffleEnabled(true);
        queue.setShuffleEnabled(false);

        expect(queue.shuffleEnabled, isFalse);
        // Current track should still be track 2
        expect(queue.current?.trackId, '2');
      });

      test('shuffle contains all tracks', () {
        final tracks = [_track(1), _track(2), _track(3), _track(4)];
        queue.setQueue(tracks);
        queue.setShuffleEnabled(true);

        final shuffledIds = queue.tracks.map((t) => t.trackId).toSet();
        final originalIds = tracks.map((t) => t.trackId).toSet();

        expect(shuffledIds, originalIds);
      });

      test('tracks added while shuffled appear in both lists', () {
        queue.setQueue([_track(1), _track(2)]);
        queue.setShuffleEnabled(true);
        queue.addToEnd(_track(3));

        expect(queue.length, 3);
        expect(queue.tracks.map((t) => t.trackId).contains('3'), isTrue);
      });
    });


    group('repeat mode', () {
      test('setRepeatMode changes mode', () {
        queue.setRepeatMode(RepeatMode.all);
        expect(queue.repeatMode, RepeatMode.all);

        queue.setRepeatMode(RepeatMode.one);
        expect(queue.repeatMode, RepeatMode.one);

        queue.setRepeatMode(RepeatMode.off);
        expect(queue.repeatMode, RepeatMode.off);
      });
    });


    group('notifies listeners', () {
      test('setQueue notifies', () {
        var notified = false;
        queue.addListener(() => notified = true);

        queue.setQueue([_track(1)]);

        expect(notified, isTrue);
      });

      test('next notifies', () {
        queue.setQueue([_track(1), _track(2)]);
        var notified = false;
        queue.addListener(() => notified = true);

        queue.next();

        expect(notified, isTrue);
      });

      test('setShuffleEnabled notifies', () {
        queue.setQueue([_track(1), _track(2)]);
        var notified = false;
        queue.addListener(() => notified = true);

        queue.setShuffleEnabled(true);

        expect(notified, isTrue);
      });

      test('clear notifies', () {
        queue.setQueue([_track(1)]);
        var notified = false;
        queue.addListener(() => notified = true);

        queue.clear();

        expect(notified, isTrue);
      });
    });
  });
}
