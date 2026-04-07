import 'package:sqflite/sqflite.dart';
import 'package:musik_app/db/application_database.dart';
import 'package:musik_app/models/track.dart';
import 'package:musik_app/models/playlist.dart';
import 'library_dao.dart';

/// SQL helpers for the playlists
/// Responsible for SQLite reads and writes only.
/// `playlists` are the playlists, `playlist_items` are the tracks inside a corresponding playlist.
class PlaylistsDao {
  Future<Database> get _db async => ApplicationDatabase.instance;
  final _library = LibraryDao();
  
  /// Maps a `playlist` row to a [Playlist]
  Playlist getPlaylistFromRow(Map<String, Object?> r) {
    return Playlist(
      playlistId: r['playlist_id'] as String,
      playlistName: r['playlist_name'] as String,
      isGenerated: (r['is_generated'] as int) == 1,
      createdAt: r['created_at_ms'] as int,
      updatedAt: r['updated_at_ms'] as int,
    );
  }
  
  /// Creates a new playlist
  Future<void> createPlaylist({
    required String playlistId,
    required String playlistName,
    required bool isGenerated,
    required int createdAt,
  }) async {
    final db = await _db;
    await db.insert('playlists', {
      'playlist_id': playlistId,
      'playlist_name': playlistName,
      'is_generated': isGenerated ? 1 : 0,
      'created_at_ms': createdAt,
      'updated_at_ms': createdAt, // the last update is the creation date here
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }
  
  /// Returns all playlists sorted by name order.
  Future<List<Playlist>> getAllPlaylists() async {
    final db = await _db;
    final rows = await db.query(
      'playlists',
      orderBy: 'playlist_name COLLATE NOCASE',
    );
    return rows.map(getPlaylistFromRow).toList();
  }
  

  /// ADJUSTED: Adds a track to the end of a playlist if it does not already exist.
  /// Checks for duplicates and ignores the track if it is already present.
  /// Updates the playlist's `updated_at` timestamp after insertion.
  /// Runs all operations inside a database transaction to ensure consistency.
  /// Maintains track order by calculating the next position automatically.
  Future<void> addTrackToPlaylist({
    required String playlistId,
    required String trackId,
    }) 
    async {
      final db = await _db;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.transaction((t) 
        async { // run inside transaction

          // Check if track already exists
          final existingRows = await t.query(
            'playlist_items',
            where: 'playlist_id = ? AND track_id = ?',
            whereArgs: [playlistId, trackId],
          );

          if (existingRows.isNotEmpty) {
            // Track already exists, ignore
            return;
          }

          // Add track
          final rows = await t.rawQuery(
            'SELECT MAX(position) AS max_pos FROM playlist_items WHERE playlist_id = ?',
            [playlistId],
          );
          final maxPosition = (rows.first['max_pos'] as int?) ?? -1;
          final nextPosition = maxPosition + 1;

          await t.insert('playlist_items', {
            'playlist_id': playlistId,
            'track_id': trackId,
            'position': nextPosition,
            'date_added_ms': now,
          }, conflictAlgorithm: ConflictAlgorithm.abort);

          // ADJUSTED: Update playlist "updated_at" timestamp
          await t.update(
            'playlists',
            {'updated_at_ms': now},
            where: 'playlist_id = ?',
            whereArgs: [playlistId],
          );
        }
      );
  }

  



  /// Removes a track from the playlist.
  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.transaction((t) async {
      await t.delete(
        'playlist_items',
        where: 'playlist_id = ? AND track_id = ?',
        whereArgs: [playlistId, trackId],
      );

      await t.update(
        'playlists',
        {'updated_at_ms': now},
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );
    });
  }
  
  /// Returns the tracks inside a playlist
  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    final db = await _db;
    // pi is an alias
    final rows = await db.rawQuery('''
      SELECT t.*
      FROM playlist_items pi
      JOIN tracks t ON t.track_id = pi.track_id
      WHERE pi.playlist_id = ?
      ORDER BY pi.position ASC
    ''', [playlistId]);

    return rows.map(_library.getTrackFromRow).toList();
  }
  
  /// Updates track order in a playlist
  /// `orderedTrackIds` should include all track ids currently in the playlist
  /// Every time the user reorders the playlist, the entire new `orderedTrackIds` should be passed.
  Future<void> reorderPlaylistWithFullUpdatedOrder(String playlistId, List<String> orderedTrackIds) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((t) async {
      final batch = t.batch();
      for (var i = 0; i < orderedTrackIds.length; i++) {
        batch.update(
          'playlist_items',
          {'position': i},
          where: 'playlist_id = ? AND track_id = ?',
          whereArgs: [playlistId, orderedTrackIds[i]],
        );
      }
      batch.update(
        'playlists',
        {'updated_at_ms': now},
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );
      await batch.commit(noResult: true);
    });
  }




  /// ADDED: Renames an existing playlist in the database.
  /// Updates the playlist name and sets the last updated timestamp.
  /// Requires the playlist ID and the new name as parameters.
  Future<void> renamePlaylist(String playlistId, String newName) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      'playlists',
      {
        'playlist_name': newName,
        'updated_at_ms': now,
      },
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );
  }


  /// Returns the count of tracks in a playlist without loading track objects.
  /// More efficient than getPlaylistTracks when only the count is needed.
  Future<int> getTrackCountForPlaylist(String playlistId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM playlist_items WHERE playlist_id = ?',
      [playlistId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Returns just the first track of a playlist (for artwork display).
  Future<Track?> getFirstTrackForPlaylist(String playlistId) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT t.*
      FROM playlist_items pi
      JOIN tracks t ON t.track_id = pi.track_id
      WHERE pi.playlist_id = ?
      ORDER BY pi.position ASC
      LIMIT 1
    ''', [playlistId]);

    if (rows.isEmpty) return null;
    return _library.getTrackFromRow(rows.first);
  }

  // ---------------------------------------------------------------------------
  // Batch queries (avoid N+1 patterns)
  // ---------------------------------------------------------------------------

  /// Returns track counts for ALL playlists in a single query.
  Future<Map<String, int>> getAllPlaylistTrackCounts() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT playlist_id, COUNT(*) as count FROM playlist_items GROUP BY playlist_id',
    );
    final result = <String, int>{};
    for (final row in rows) {
      result[row['playlist_id'] as String] = row['count'] as int;
    }
    return result;
  }

  /// Returns the first track's artwork path for ALL playlists in a single query.
  Future<Map<String, String?>> getAllPlaylistFirstTrackArtwork() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT pi.playlist_id, t.artwork_thumbnail_path
      FROM playlist_items pi
      JOIN tracks t ON t.track_id = pi.track_id
      WHERE pi.position = (
        SELECT MIN(position) FROM playlist_items WHERE playlist_id = pi.playlist_id
      )
    ''');
    final result = <String, String?>{};
    for (final row in rows) {
      result[row['playlist_id'] as String] = row['artwork_thumbnail_path'] as String?;
    }
    return result;
  }

  /// ADDED: Deletes a playlist from the database, but keeps the tracks intact.
  /// This method removes the playlist entry and its associated items (tracks) from the playlist.
  /// The tracks themselves are not deleted, only their association with the playlist is removed.
  Future<void> deletePlaylist(String playlistId) async {
    final db = await _db;
    await db.transaction((t) async {
      /// Deletes only the associations (tracks) in the playlist
      await t.delete(
        'playlist_items',
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );
      /// Deletes the playlist itself
      await t.delete(
        'playlists',
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );
    });
  }

}