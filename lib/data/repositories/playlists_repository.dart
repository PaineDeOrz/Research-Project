// -----------------------------------------------------------------------------
// PLAYLISTS REPOSITORY
// -----------------------------------------------------------------------------
//
// Business logic layer for playlist operations. This wraps the PlaylistsDao
// and provides a cleaner API for the UI layer.
//
// Why a repository?
// - DAOs should only handle raw database operations
// - Repositories handle business logic, caching, and provide a cleaner API
// - Makes it easier to swap out the data source later if needed
// - UI code doesn't need to know about database details
//
// This class also extends ChangeNotifier so the UI can react to changes.
//
// Generated Playlists:
// - Based on listening history, tags, and various algorithms
// - Stored in the playlists table with is_generated = true
// - Can be refreshed/regenerated on demand
//
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../db/application_database.dart';
import '../../db/daos/playlists_dao.dart';
import '../../db/daos/tags_dao.dart';
import '../../db/daos/library_dao.dart';
import '../../models/playlist.dart';
import '../../models/track.dart';

class PlaylistsRepository extends ChangeNotifier {
  final _dao = PlaylistsDao();
  final _tagsDao = TagsDao();
  final _libraryDao = LibraryDao();
  final _uuid = const Uuid();

  Future<Database> get _db async => ApplicationDatabase.instance;

  // Cache for playlists - avoids repeated DB queries
  List<Playlist>? _playlistsCache;

  // ---------------------------------------------------------------------------
  // Basic CRUD Operations
  // ---------------------------------------------------------------------------

  /// Creates a new user playlist with the given name.
  /// Returns the created playlist.
  Future<Playlist> createPlaylist(String name) async {
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    await _dao.createPlaylist(
      playlistId: id,
      playlistName: name.trim(),
      isGenerated: false,
      createdAt: now,
    );

    _invalidateCache();
    notifyListeners();

    return Playlist(
      playlistId: id,
      playlistName: name.trim(),
      isGenerated: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Gets all playlists, optionally filtered by type.
  /// Results are cached until invalidated.
  Future<List<Playlist>> getAllPlaylists({bool? generatedOnly}) async {
    _playlistsCache ??= await _dao.getAllPlaylists();

    if (generatedOnly == null) {
      return _playlistsCache!;
    }

    return _playlistsCache!
        .where((p) => p.isGenerated == generatedOnly)
        .toList();
  }

  /// Gets only user-created playlists (not generated).
  Future<List<Playlist>> getUserPlaylists() async {
    return getAllPlaylists(generatedOnly: false);
  }

  /// Gets only generated playlists.
  Future<List<Playlist>> getGeneratedPlaylists() async {
    return getAllPlaylists(generatedOnly: true);
  }

  /// Gets a playlist by its ID. Returns null if not found.
  Future<Playlist?> getPlaylistById(String playlistId) async {
    final playlists = await getAllPlaylists();
    try {
      return playlists.firstWhere((p) => p.playlistId == playlistId);
    } catch (_) {
      return null;
    }
  }

  /// Renames a playlist.
  Future<void> renamePlaylist(String playlistId, String newName) async {
    await _dao.renamePlaylist(playlistId, newName.trim());
    _invalidateCache();
    notifyListeners();
  }

  /// Deletes a playlist and all its track associations.
  /// The tracks themselves are not deleted.
  Future<void> deletePlaylist(String playlistId) async {
    await _dao.deletePlaylist(playlistId);
    _invalidateCache();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Track Operations
  // ---------------------------------------------------------------------------

  /// Gets all tracks in a playlist, ordered by position.
  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    return _dao.getPlaylistTracks(playlistId);
  }

  /// Gets the number of tracks in a playlist without loading track objects.
  Future<int> getTrackCount(String playlistId) async {
    return _dao.getTrackCountForPlaylist(playlistId);
  }

  /// Returns just the first track of a playlist (for artwork display).
  Future<Track?> getFirstTrackForPlaylist(String playlistId) async {
    return _dao.getFirstTrackForPlaylist(playlistId);
  }

  // ---------------------------------------------------------------------------
  // Batch queries (avoid N+1 patterns in list screens)
  // ---------------------------------------------------------------------------

  /// Returns track counts for ALL playlists in a single query.
  Future<Map<String, int>> getAllPlaylistTrackCounts() async {
    return _dao.getAllPlaylistTrackCounts();
  }

  /// Returns first track artwork for ALL playlists in a single query.
  Future<Map<String, String?>> getAllPlaylistFirstTrackArtwork() async {
    return _dao.getAllPlaylistFirstTrackArtwork();
  }

  /// Adds a single track to the end of a playlist.
  /// Silently ignores if the track is already in the playlist.
  Future<void> addTrack(String playlistId, String trackId) async {
    await _dao.addTrackToPlaylist(playlistId: playlistId, trackId: trackId);
    _invalidateCache();
    notifyListeners();
  }

  /// Adds multiple tracks to the end of a playlist.
  /// Tracks already in the playlist are silently ignored.
  Future<void> addTracks(String playlistId, List<String> trackIds) async {
    for (final trackId in trackIds) {
      await _dao.addTrackToPlaylist(playlistId: playlistId, trackId: trackId);
    }
    _invalidateCache();
    notifyListeners();
  }

  /// Removes a track from a playlist.
  Future<void> removeTrack(String playlistId, String trackId) async {
    await _dao.removeTrackFromPlaylist(
      playlistId: playlistId,
      trackId: trackId,
    );
    _invalidateCache();
    notifyListeners();
  }

  /// Reorders tracks in a playlist.
  /// Pass the full list of track IDs in the new order.
  Future<void> reorderTracks(String playlistId, List<String> trackIds) async {
    await _dao.reorderPlaylistWithFullUpdatedOrder(playlistId, trackIds);
    _invalidateCache();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Utility
  // ---------------------------------------------------------------------------

  /// Clears the cache, forcing a fresh fetch on the next query.
  void _invalidateCache() {
    _playlistsCache = null;
  }

  /// Force refresh from database.
  Future<void> refresh() async {
    _invalidateCache();
    await getAllPlaylists();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Generated Playlists
  // ---------------------------------------------------------------------------

  /// Gets tracks recently played, ordered by most recent first.
  /// Uses listening history to find tracks played in the last [days] days.
  Future<List<Track>> getRecentlyPlayedTracks({int days = 30, int limit = 50}) async {
    final db = await _db;
    final cutoffMs = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;

    final rows = await db.rawQuery('''
      SELECT DISTINCT t.*
      FROM played_tracks pt
      JOIN tracks t ON t.track_id = pt.track_id
      WHERE pt.started_at_ms >= ?
      ORDER BY pt.started_at_ms DESC
      LIMIT ?
    ''', [cutoffMs, limit]);

    return rows.map(_libraryDao.getTrackFromRow).toList();
  }

  /// Gets the most frequently played tracks.
  /// Counts plays per track and returns the top ones.
  Future<List<Track>> getMostPlayedTracks({int days = 90, int limit = 50}) async {
    final db = await _db;
    final cutoffMs = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;

    final rows = await db.rawQuery('''
      SELECT t.*, COUNT(pt.id) as play_count
      FROM played_tracks pt
      JOIN tracks t ON t.track_id = pt.track_id
      WHERE pt.started_at_ms >= ?
      GROUP BY t.track_id
      ORDER BY play_count DESC
      LIMIT ?
    ''', [cutoffMs, limit]);

    return rows.map(_libraryDao.getTrackFromRow).toList();
  }

  /// Gets tracks that haven't been played recently but were played before.
  /// Good for "rediscover" type playlists.
  Future<List<Track>> getForgottenFavorites({int minDaysAgo = 30, int limit = 30}) async {
    final db = await _db;
    final cutoffMs = DateTime.now()
        .subtract(Duration(days: minDaysAgo))
        .millisecondsSinceEpoch;

    // Find tracks that were played multiple times but not recently
    final rows = await db.rawQuery('''
      SELECT t.*, COUNT(pt.id) as play_count, MAX(pt.started_at_ms) as last_played
      FROM played_tracks pt
      JOIN tracks t ON t.track_id = pt.track_id
      GROUP BY t.track_id
      HAVING play_count >= 2 AND last_played < ?
      ORDER BY play_count DESC
      LIMIT ?
    ''', [cutoffMs, limit]);

    return rows.map(_libraryDao.getTrackFromRow).toList();
  }

  /// Gets tracks never played or played only once.
  Future<List<Track>> getUnderplayedTracks({int limit = 50}) async {
    final db = await _db;

    final rows = await db.rawQuery('''
      SELECT t.*, COALESCE(pc.play_count, 0) as play_count
      FROM tracks t
      LEFT JOIN (
        SELECT track_id, COUNT(*) as play_count
        FROM played_tracks
        GROUP BY track_id
      ) pc ON pc.track_id = t.track_id
      WHERE COALESCE(pc.play_count, 0) <= 1
      ORDER BY t.date_added_ms DESC
      LIMIT ?
    ''', [limit]);

    return rows.map(_libraryDao.getTrackFromRow).toList();
  }

  /// Gets tracks similar to the given track based on shared tags.
  /// Returns tracks that share at least one tag with the input track.
  Future<List<Track>> getSimilarTracks(String trackId, {int limit = 20}) async {
    final db = await _db;

    // Get tracks that share tags with the given track, excluding the track itself
    // Ordered by number of shared tags (more shared = more similar)
    final rows = await db.rawQuery('''
      SELECT t.*, COUNT(shared.tag_id) as shared_tag_count
      FROM tracks t
      JOIN track_tags tt ON tt.track_id = t.track_id
      JOIN (
        SELECT tag_id FROM track_tags WHERE track_id = ?
      ) shared ON shared.tag_id = tt.tag_id
      WHERE t.track_id != ?
      GROUP BY t.track_id
      ORDER BY shared_tag_count DESC, t.track_artist COLLATE NOCASE
      LIMIT ?
    ''', [trackId, trackId, limit]);

    return rows.map(_libraryDao.getTrackFromRow).toList();
  }

  /// Gets tracks similar to what the user has been listening to recently.
  /// Finds the most common tags from recent plays and returns tracks with those tags.
  Future<List<Track>> getMoreLikeRecent({int days = 14, int limit = 30}) async {
    final db = await _db;
    final cutoffMs = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;

    // Get top tags from recent listening
    final topTags = await db.rawQuery('''
      SELECT t.tag_id, COUNT(*) as count
      FROM played_tracks pt
      JOIN track_tags t ON t.track_id = pt.track_id
      WHERE pt.started_at_ms >= ?
      GROUP BY t.tag_id
      ORDER BY count DESC
      LIMIT 5
    ''', [cutoffMs]);

    if (topTags.isEmpty) {
      return [];
    }

    final tagIds = topTags.map((r) => r['tag_id'] as int).toList();
    final placeholders = List.filled(tagIds.length, '?').join(', ');

    // Get tracks with those tags that haven't been played recently
    final rows = await db.rawQuery('''
      SELECT DISTINCT t.*
      FROM tracks t
      JOIN track_tags tt ON tt.track_id = t.track_id
      WHERE tt.tag_id IN ($placeholders)
      AND t.track_id NOT IN (
        SELECT DISTINCT track_id FROM played_tracks WHERE started_at_ms >= ?
      )
      ORDER BY RANDOM()
      LIMIT ?
    ''', [...tagIds, cutoffMs, limit]);

    return rows.map(_libraryDao.getTrackFromRow).toList();
  }

  /// Gets tracks by a specific tag/genre.
  Future<List<Track>> getTracksByTag(String tagName, {int limit = 50}) async {
    final tracks = await _tagsDao.getTracksWithTag(tagName);
    return tracks.take(limit).toList();
  }

  /// Creates or updates a generated playlist with the given tracks.
  /// If a playlist with the same name exists, it's updated. Otherwise created.
  Future<Playlist> createOrUpdateGeneratedPlaylist({
    required String name,
    required List<Track> tracks,
  }) async {
    final db = await _db;

    // Check if generated playlist with this name exists
    final existing = await db.query(
      'playlists',
      where: 'playlist_name = ? AND is_generated = 1',
      whereArgs: [name],
      limit: 1,
    );

    String playlistId;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (existing.isNotEmpty) {
      // Update existing
      playlistId = existing.first['playlist_id'] as String;

      // Clear existing tracks
      await db.delete('playlist_items', where: 'playlist_id = ?', whereArgs: [playlistId]);

      // Update timestamp
      await db.update(
        'playlists',
        {'updated_at_ms': now},
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );
    } else {
      // Create new
      playlistId = _uuid.v4();
      await _dao.createPlaylist(
        playlistId: playlistId,
        playlistName: name,
        isGenerated: true,
        createdAt: now,
      );
    }

    // Add tracks
    for (var i = 0; i < tracks.length; i++) {
      await db.insert('playlist_items', {
        'playlist_id': playlistId,
        'track_id': tracks[i].trackId,
        'position': i,
        'date_added_ms': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    _invalidateCache();
    notifyListeners();

    return Playlist(
      playlistId: playlistId,
      playlistName: name,
      isGenerated: true,
      createdAt: existing.isNotEmpty ? existing.first['created_at_ms'] as int : now,
      updatedAt: now,
    );
  }

  /// Regenerates all generated playlists with fresh data.
  Future<void> regenerateAllGeneratedPlaylists() async {
    // Recently Played
    final recentTracks = await getRecentlyPlayedTracks(days: 30, limit: 50);
    if (recentTracks.isNotEmpty) {
      await createOrUpdateGeneratedPlaylist(
        name: 'Recently Played',
        tracks: recentTracks,
      );
    }

    // Most Played
    final mostPlayed = await getMostPlayedTracks(days: 90, limit: 50);
    if (mostPlayed.isNotEmpty) {
      await createOrUpdateGeneratedPlaylist(
        name: 'Most Played',
        tracks: mostPlayed,
      );
    }

    // Forgotten Favorites
    final forgotten = await getForgottenFavorites(minDaysAgo: 30, limit: 30);
    if (forgotten.isNotEmpty) {
      await createOrUpdateGeneratedPlaylist(
        name: 'Rediscover',
        tracks: forgotten,
      );
    }

    // Discover New (underplayed tracks)
    final underplayed = await getUnderplayedTracks(limit: 50);
    if (underplayed.isNotEmpty) {
      await createOrUpdateGeneratedPlaylist(
        name: 'Discover',
        tracks: underplayed,
      );
    }

    // More Like Recent
    final moreLikeRecent = await getMoreLikeRecent(days: 14, limit: 30);
    if (moreLikeRecent.isNotEmpty) {
      await createOrUpdateGeneratedPlaylist(
        name: 'More Like This',
        tracks: moreLikeRecent,
      );
    }
  }
}
