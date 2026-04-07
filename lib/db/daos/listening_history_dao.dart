import 'package:sqflite/sqflite.dart';
import 'package:musik_app/db/application_database.dart';
import '../../core/log_debug.dart';
import '../../models/listening_history_entry.dart';

// TODO: this class is difficult to understand, make more readable
class ListeningHistoryDao {
  Future<Database> get _db async => ApplicationDatabase.instance;

  /// Creates a new playback event row.
  /// `segment_started_at_ms` stores wall-clock time when segment started.
  /// `total_listened_ms` accumulates actual time spent playing.
  Future<int> logPlayStart({
    required String trackId,
    int startPositionMs = 0,
  }) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    logDebug('ListeningHistoryDao: logPlayStart() trackId=$trackId startPositionMs=$startPositionMs');
    final id = await db.insert('played_tracks', {
      'track_id': trackId,
      'started_at_ms': now,
      'start_position_ms': startPositionMs,
      'end_position_ms': startPositionMs,
      'total_listened_ms': 0,
      'segment_started_at_ms': now,
      'segment_start_position_ms': startPositionMs,
      'completed': 0,
    });
    logDebug('ListeningHistoryDao: logPlayStart -> eventId=$id');
    return id;
  }

  /// Called when playback transitions into playing.
  /// If we already have an open segment for this event then do nothing.
  Future<void> markResumed({required int eventId, required int positionMs}) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    logDebug('ListeningHistoryDao: markResumed eventId=$eventId positionMs=$positionMs');

    final row = await db.query(
      'played_tracks',
      columns: ['segment_started_at_ms'],
      where: 'id = ?',
      whereArgs: [eventId],
      limit: 1,
    );

    if (row.isEmpty) {
      logDebug('ListeningHistoryDao: markResumed eventId=$eventId not found');
      return;
    }

    final segmentStartedAt = row.first['segment_started_at_ms'] as int?;
    // Segment is already open, do nothing
    if (segmentStartedAt != null) {
      logDebug('ListeningHistoryDao: markResumed no operation, segment already open');
      return;
    }

    final updated = await db.update(
      'played_tracks',
      {
        'segment_started_at_ms': now,
        'segment_start_position_ms': positionMs,
      },
      where: 'id = ?',
      whereArgs: [eventId],
    );
    logDebug('ListeningHistoryDao: markResumed opened segment (updated=$updated)');
  }

  /// Called when playback transitions out of playing.
  /// Closes the active segment and adds wall-clock elapsed time to `total_listened_ms`.
  Future<void> markPaused({
    required int eventId,
    required int endPositionMs,
  }) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    logDebug('ListeningHistoryDao: markPaused eventId=$eventId endPositionMs=$endPositionMs');

    await db.transaction((txn) async {
      final row = await txn.query(
        'played_tracks',
        columns: ['segment_started_at_ms', 'total_listened_ms'],
        where: 'id = ?',
        whereArgs: [eventId],
        limit: 1,
      );

      if (row.isEmpty) {
        logDebug('ListeningHistoryDao: markPaused eventId=$eventId not found');
        return;
      }

      final segmentStartedAt = row.first['segment_started_at_ms'] as int?;
      // keep end_position_ms up to date
      if (segmentStartedAt == null) {
        final updated = await txn.update(
          'played_tracks',
          {'end_position_ms': endPositionMs},
          where: 'id = ?',
          whereArgs: [eventId],
        );
        logDebug('ListeningHistoryDao: markPaused no open segment (updated=$updated)');
        return;
      }

      final totalListened = (row.first['total_listened_ms'] as int?) ?? 0;
      // Use wall clock time elapsed, not position delta
      final elapsedMs = now - segmentStartedAt;
      final safeElapsed = elapsedMs < 0 ? 0 : elapsedMs;

      final updated = await txn.update(
        'played_tracks',
        {
          'end_position_ms': endPositionMs,
          'total_listened_ms': totalListened + safeElapsed,
          'segment_started_at_ms': null,
          'segment_start_position_ms': null,
        },
        where: 'id = ?',
        whereArgs: [eventId],
      );
      logDebug('ListeningHistoryDao: markPaused closed segment (elapsed=${safeElapsed}ms, updated=$updated)');
    });
  }

  /// Final write for an event.
  /// Closes any open segment so totals stay consistent.
  Future<void> finalize({
    required int eventId,
    required int endPositionMs,
    required bool completed,
  }) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    logDebug('ListeningHistoryDao: finalize eventId=$eventId endPositionMs=$endPositionMs completed=$completed');

    await db.transaction((txn) async {
      final row = await txn.query(
        'played_tracks',
        columns: ['segment_started_at_ms', 'total_listened_ms'],
        where: 'id = ?',
        whereArgs: [eventId],
        limit: 1,
      );

      if (row.isEmpty) {
        logDebug('ListeningHistoryDao: finalize eventId=$eventId not found');
        return;
      }

      final segmentStartedAt = row.first['segment_started_at_ms'] as int?;
      final totalListened = (row.first['total_listened_ms'] as int?) ?? 0;

      // Use wall-clock time elapsed if segment is open
      final elapsedMs = segmentStartedAt == null ? 0 : (now - segmentStartedAt);
      final safeElapsed = elapsedMs < 0 ? 0 : elapsedMs;

      final updated = await txn.update(
        'played_tracks',
        {
          'ended_at_ms': now,
          'end_position_ms': endPositionMs,
          'total_listened_ms': totalListened + safeElapsed,
          'segment_started_at_ms': null,
          'segment_start_position_ms': null,
          'completed': completed ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [eventId],
      );

      final segmentInfo = segmentStartedAt == null
          ? 'no open segment'
          : 'closed segment +${safeElapsed}ms';
      logDebug('ListeningHistoryDao: finalize completed ($segmentInfo, updated=$updated)');
    });
  }

  Future<List<ListeningHistoryEntry>> getRecentHistory({int limit = 500}) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT
        pt.id AS event_id,
        pt.track_id AS track_id,
        pt.started_at_ms AS started_at_ms,
        COALESCE(pt.total_listened_ms, 0) AS total_listened_ms,
        COALESCE(NULLIF(TRIM(t.track_title), ''), 'Unknown track') AS track_title,
        COALESCE(NULLIF(TRIM(t.track_artist), ''), 'Unknown artist') AS track_artist,
        COALESCE(t.artwork_thumbnail_path, a.artwork_thumbnail_path) AS artwork_thumb_path
      FROM played_tracks pt
      LEFT JOIN tracks t ON t.track_id = pt.track_id
      LEFT JOIN albums a ON a.album_id = t.album_id
      ORDER BY pt.started_at_ms DESC
      LIMIT ?
    ''', [limit]);

    return rows.map((r) {
      return ListeningHistoryEntry(
        eventId: (r['event_id'] as int?) ?? -1,
        trackId: (r['track_id'] as String?) ?? '',
        startedAtMs: (r['started_at_ms'] as int?) ?? 0,
        totalListenedMs: (r['total_listened_ms'] as int?) ?? 0,
        trackTitle: (r['track_title'] as String?) ?? 'Unknown track',
        trackArtist: (r['track_artist'] as String?) ?? 'Unknown artist',
        artworkThumbPath: (r['artwork_thumb_path'] as String?)?.trim(),
      );
    }).toList(growable: false);
  }

  Future<void> deleteEntry(int eventId) async {
    final db = await _db;
    await db.delete('played_tracks', where: 'id = ?', whereArgs: [eventId]);
  }
}