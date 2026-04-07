// -----------------------------------------------------------------------------
// LISTENING HISTORY REPOSITORY
// -----------------------------------------------------------------------------
//
// Thin wrapper over ListeningHistoryDao for logging playback sessions.
// Tracks play start, pause, resume, and finalization events.
//
// -----------------------------------------------------------------------------

import '../../core/log_debug.dart';
import '../../db/daos/listening_history_dao.dart';
import '../../models/listening_history_entry.dart';

class ListeningHistoryRepository {
  ListeningHistoryRepository({ListeningHistoryDao? dao})
      : _dao = dao ?? ListeningHistoryDao();

  final ListeningHistoryDao _dao;

  /// Logs the start of a playback session.
  /// Returns the inserted event id to be passed to [finalize].
  Future<int> logPlayStart({
    required String trackId,
    int startPositionMs = 0,
  }) async {
    try {
      final id = await _dao.logPlayStart(trackId: trackId, startPositionMs: startPositionMs);
      logDebug('ListeningHistory: start trackId=$trackId startPositionMs=$startPositionMs -> eventId=$id');
      return id;
    } catch (error) {
      logDebug('ListeningHistory: start failed trackId=$trackId error=$error');
      rethrow;
    }
  }

  Future<void> markResumed({required int eventId, required int positionMs}) async {
    try {
      await _dao.markResumed(eventId: eventId, positionMs: positionMs);
      logDebug('ListeningHistory: resumed eventId=$eventId');
    } catch (error) {
      logDebug('ListeningHistory: resumed failed eventId=$eventId error=$error');
      rethrow;
    }
  }

  Future<void> markPaused({required int eventId, required int endPositionMs}) async {
    try {
      await _dao.markPaused(eventId: eventId, endPositionMs: endPositionMs);
      logDebug('ListeningHistory: paused eventId=$eventId endPos=$endPositionMs');
    } catch (error) {
      logDebug('ListeningHistory: paused failed eventId=$eventId error=$error');
      rethrow;
    }
  }

  Future<void> finalize({
    required int eventId,
    required int endPositionMs,
    required bool completed,
  }) async {
    try {
      await _dao.finalize(eventId: eventId, endPositionMs: endPositionMs, completed: completed);
      logDebug('ListeningHistory: finalize eventId=$eventId endPositionMs=$endPositionMs completed=$completed');
    } catch (error) {
      logDebug('ListeningHistory: finalize failed eventId=$eventId error=$error');
      rethrow;
    }
  }

  Future<List<ListeningHistoryEntry>> getRecentHistory({int limit = 500}) {
    return _dao.getRecentHistory(limit: limit);
  }

  Future<void> deleteEntry(int eventId) {
    return _dao.deleteEntry(eventId);
  }
}
