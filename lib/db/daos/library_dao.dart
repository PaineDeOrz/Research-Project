import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:musik_app/db/application_database.dart';
import 'package:musik_app/models/track.dart';
import 'package:musik_app/models/album.dart';
import 'package:musik_app/models/device_song.dart';
import '../../core/log_debug.dart';

/// SQL helpers for the music library
/// Responsible for SQLite reads and writes only.
class LibraryDao {
  Future<Database> get _db async => ApplicationDatabase.instance;

  /// Checks if an LRC file exists for the given audio file path
  /// Returns a tuple of (hasLrc, lrcPath)
  (bool, String?) _checkForLrcFile(String audioFilePath) {
    try {
      final audioFile = File(audioFilePath);
      final directory = audioFile.parent.path;
      final fileName = audioFile.path.split('/').last;
      final nameWithoutExt = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
      final lrcPath = '$directory/$nameWithoutExt.lrc';
      final lrcFile = File(lrcPath);
      
      if (lrcFile.existsSync()) {
        return (true, lrcPath);
      }
    } catch (e) {
      logDebug('LibraryDao: LRC check failed for $audioFilePath: $e');
    }
    return (false, null);
  }


  Future<void> updateAlbumArtworkPaths({
    required String albumId,
    String? thumbnailPath,
    String? hqPath,
  }) async {
    final values = <String, Object?>{};
    if (thumbnailPath != null) values['artwork_thumbnail_path'] = thumbnailPath;
    if (hqPath != null) values['artwork_hq_path'] = hqPath;
    if (values.isEmpty) return; //

    final db = await _db;
    await db.update(
      'albums',
      values,
      where: 'album_id = ?',
      whereArgs: [albumId],
    );
  }

  Future<void> updateTrackArtworkPaths({
    required String trackId,
    String? thumbnailPath,
    String? hqPath,
  }) async {
    final values = <String, Object?>{};
    if (thumbnailPath != null) values['artwork_thumbnail_path'] = thumbnailPath;
    if (hqPath != null) values['artwork_hq_path'] = hqPath;
    if (values.isEmpty) return; //

    final db = await _db;
    await db.update(
      'tracks',
      values,
      where: 'track_id = ?',
      whereArgs: [trackId],
    );
  }

  /// Updates albums and tracks from device query results.
  /// Inserts Albums first
  Future<void> syncLibraryFromDevice(List<DeviceSong> tracks) async {
    if (tracks.isEmpty) return;
    logDebug('LibraryDao: sync start (${tracks.length} device tracks)');

    final db = await _db;
    final now = DateTime
        .now()
        .millisecondsSinceEpoch;

    await db.transaction((txn) async {
      final batch = txn.batch();

      // Albums sync
      for (final track in tracks) {
        // Use '0' as fallback if albumId is missing to avoid skipping the track
        final albumId = (track.albumId?.toString() ?? '0').trim().isEmpty 
            ? '0' 
            : track.albumId.toString();

        final values = {
          'album_id': albumId,
          'album_title': (track.album ?? 'Unknown Album').trim(),
          'album_artist': (track.artist ?? 'Unknown Artist').trim(),
          'year': null, // TODO: get year correctly instead of returning null.
          'date_added_ms': track.dateAdded ?? now,
        };
        batch.update(
          'albums',
          values,
          where: 'album_id = ?',
          whereArgs: [albumId],
        );
        batch.insert(
          'albums',
          values,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }


      // Tracks sync
      for (final track in tracks) {
        final trackId = track.id.toString();
        // Use the same fallback logic for the track's album reference
        final albumId = (track.albumId?.toString() ?? '0').trim().isEmpty 
            ? '0' 
            : track.albumId.toString();

        final uri = (track.uri ?? '').trim();
        if (uri.isEmpty) continue;

        // Check for LRC file based on the track's file path
        final (hasLrc, lrcPath) = _checkForLrcFile(track.data);

        final trackData = {
          'track_uri': uri,
          'track_title': (track.title).trim(),
          'album_title': (track.album ?? 'Unknown Album').trim(),
          'album_id': albumId,
          'track_artist': (track.artist ?? 'Unknown Artist').trim(),
          'track_duration_ms': track.duration ?? 0,
          'track_path': track.data,
          'year': null,
          'artwork_url': null,
          'date_added_ms': track.dateAdded ?? now,
          'track_modified_last_ms': track.dateModified,
          'track_size': track.size,
          'track_number': track.track,
          'has_lrc': hasLrc ? 1 : 0,
          'lrc_path': lrcPath,
          'replay_gain_db': track.replayGainDb,
        };

        // Only overwrite metadata for device managed tracks
        batch.update(
          'tracks',
          trackData,
          where: 'track_id = ? AND is_metadata_managed = 1',
          whereArgs: [trackId],
        );

        batch.insert(
          'tracks',
          {...trackData, 'track_id': trackId},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    });
    logDebug('LibraryDao: sync completed');
  }

  /// Removes tracks and their listening history that no longer exist on the device.
  /// playlist_items and track_tags are cleaned up via ON DELETE CASCADE.
  /// played_tracks uses ON DELETE NO ACTION so we delete those explicitly first.
  Future<void> removeTracksNotInSet(Set<String> currentTrackIds) async {
    if (currentTrackIds.isEmpty) return;

    final db = await _db;
    final allRows = await db.query('tracks', columns: ['track_id']);
    final allTrackIds = allRows.map((row) => row['track_id'] as String).toSet();
    final orphanedIds = allTrackIds.difference(currentTrackIds);
    if (orphanedIds.isEmpty) return;

    logDebug('LibraryDao: removing ${orphanedIds.length} orphaned tracks');

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final trackId in orphanedIds) {
        batch.delete('played_tracks', where: 'track_id = ?', whereArgs: [trackId]);
        batch.delete('tracks', where: 'track_id = ?', whereArgs: [trackId]);
      }
      await batch.commit(noResult: true);
    });
  }

  /// Batch updates track_path for tracks with stale absolute paths.
  /// Called on iOS startup when the sandbox container UUID changes.
  Future<void> updateTrackPaths(Map<String, String> trackIdToNewPath) async {
    if (trackIdToNewPath.isEmpty) return;
    logDebug('LibraryDao: updating ${trackIdToNewPath.length} stale track paths');

    final db = await _db;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final entry in trackIdToNewPath.entries) {
        batch.update(
          'tracks',
          {'track_path': entry.value},
          where: 'track_id = ?',
          whereArgs: [entry.key],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Updates user editable metadata fields and marks the track as user managed.
  Future<void> updateTrackMetadata({
    required String trackId,
    required String title,
    required String artist,
    required String albumTitle,
    int? year,
    int? trackNumber,
  }) async {
    final db = await _db;
    await db.update(
      'tracks',
      {
        'track_title': title.trim(),
        'track_artist': artist.trim(),
        'album_title': albumTitle.trim(),
        'year': year,
        'track_number': trackNumber,
        'is_metadata_managed': 0,
        'track_modified_last_ms': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'track_id = ?',
      whereArgs: [trackId],
    );
    logDebug('LibraryDao: updated metadata for track $trackId');
  }

  /// Inserts or updates an album row.
  /// `dateAdded` in milliseconds (for now)
  Future<void> upsertAlbum({
    required String albumId,
    required String albumTitle,
    required String albumArtist,
    int? year,
    int? dateAdded,
  }) async {
    final db = await _db;
    if (kDebugMode) {
      print('LibraryDao: upsertAlbum albumId=$albumId title="$albumTitle"');
    }
    await db.insert('albums', {
      'album_id': albumId,
      'album_title': albumTitle,
      'album_artist': albumArtist,
      'year': year,
      'date_added_ms': dateAdded,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Returns raw album rows.
  Future<List<Map<String, Object?>>> getAlbumsRaw() async {
    final db = await _db;
    logDebug('LibraryDao: getAlbumsRaw()');
    return db.query(
      'albums',
      orderBy: 'album_artist COLLATE NOCASE, album_title COLLATE NOCASE',
    );
  }

  /// Maps a database row to an [Album].
  Album getAlbumFromRow(Map<String, Object?> r) {
    return Album(
      albumId: r['album_id'] as String,
      albumTitle: r['album_title'] as String,
      albumArtist: r['album_artist'] as String,
      year: r['year'] as int?,
      artworkThumbnailPath: r['artwork_thumbnail_path'] as String?,
      artworkHqPath: r['artwork_hq_path'] as String?,
      dateAdded: r['date_added_ms'] as int?,
    );
  }

  /// Loads all albums sorted by artist
  Future<List<Album>> getAllAlbums() async {
    final rows = await getAlbumsRaw();
    return rows.map(getAlbumFromRow).toList();
  }

  /// Inserts or updates track(s).
  /// Each row map must match the `tracks` table column name.
  Future<void> upsertTracksBatch(List<Map<String, Object?>> rows) async {
    final db = await _db;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final row in rows) {
        batch.update(
          'tracks',
          row,
          where: 'track_id = ?',
          whereArgs: [row['track_id']],
        );
        batch.insert(
          'tracks',
          row,
          conflictAlgorithm: ConflictAlgorithm.ignore, //since already in db
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Map a database row to a [Track]
  Track getTrackFromRow(Map<String, Object?> r) {
    final trackId = r['track_id'] as String;
    final trackPath = r["track_path"] as String?;

    if (trackPath == null || trackPath.isEmpty) {
      logDebug('LibraryDao: Track $trackId has null/empty track_path');
    }

    return Track(
      trackId: r['track_id'] as String,
      trackUri: r['track_uri'] as String,
      trackTitle: r['track_title'] as String,
      albumTitle: r['album_title'] as String,
      albumId: r['album_id'] as String,
      trackArtist: r['track_artist'] as String,
      trackDuration: Duration(milliseconds: r['track_duration_ms'] as int),
      trackPath: r["track_path"] as String?,
      year: r['year'] as int?,
      artworkThumbnailPath: r['artwork_thumbnail_path'] as String?,
      artworkHqPath: r['artwork_hq_path'] as String?,
      dateAdded: r['date_added_ms'] as int?,
      trackModifiedLast: r['track_modified_last_ms'] as int?,
      trackSize: r['track_size'] as int?,
      trackNumber: r['track_number'] as int?,
      hasLrc: (r['has_lrc'] as int?) == 1,
      lrcPath: r['lrc_path'] as String?,
      replayGainDb: r['replay_gain_db'] as double?,
      isMetadataManaged: (r['is_metadata_managed'] as int?) != 0,
    );
  }

  /// Standard columns for track queries
  static const _trackColumns = [
    'track_id', 'track_uri', 'track_title', 'album_title', 'album_id',
    'track_artist', 'track_duration_ms', 'track_path', 'year',
    'artwork_thumbnail_path', 'artwork_hq_path', 'date_added_ms',
    'track_modified_last_ms', 'track_size', 'track_number',
    'has_lrc', 'lrc_path', 'replay_gain_db', 'is_metadata_managed',
  ];

  /// Loads all tracks sorted by artist, album, track number.
  Future<List<Track>> getAllTracks() async {
    final db = await _db;
    final rows = await db.query(
      'tracks',
      columns: _trackColumns,
      orderBy: 'track_artist COLLATE NOCASE, album_title COLLATE NOCASE, track_number IS NULL, track_number',
    );
    logDebug('LibraryDao: getAllTracks returned ${rows.length} rows');
    return rows.map(getTrackFromRow).toList();
  }

  /// Loads all tracks for an album ordered by track number.
  Future<List<Track>> getTracksForAlbum(String albumId) async {
    final db = await _db;
    final rows = await db.query(
      'tracks',
      columns: _trackColumns,
      where: 'album_id = ?',
      whereArgs: [albumId],
      orderBy: 'track_number IS NULL, track_number',
    );
    return rows.map(getTrackFromRow).toList();
  }

  /// Finds a [Track] row by its Uri.
  /// Returns `null` if the [Track] isn't found.
  Future<Map<String, Object?>?> findTrackByUri(String uri) async {
    final db = await _db;
    final rows = await db.query(
      'tracks',
      where: 'track_uri = ?',
      whereArgs: [uri],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }


  /// Gets a single track by ID.
  Future<Track?> getTrackById(String trackId) async {
    final db = await _db;
    final rows = await db.query(
      'tracks',
      columns: _trackColumns,
      where: 'track_id = ?',
      whereArgs: [trackId],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final track = getTrackFromRow(rows.first);
    logDebug('LibraryDao: getTrackById($trackId) -> trackPath=${track.trackPath}');
    return track;
  }

  /// Returns the count of tracks for an album without loading track objects.
  /// More efficient than getTracksForAlbum when only the count is needed.
  Future<int> getTrackCountForAlbum(String albumId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tracks WHERE album_id = ?',
      [albumId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Returns just the first track for an album (for artwork fallback).
  Future<Track?> getFirstTrackForAlbum(String albumId) async {
    final db = await _db;
    final rows = await db.query(
      'tracks',
      columns: _trackColumns,
      where: 'album_id = ?',
      whereArgs: [albumId],
      orderBy: 'track_number IS NULL, track_number',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return getTrackFromRow(rows.first);
  }

  /// Returns the count of tracks for an artist without loading track objects.
  Future<int> getTrackCountForArtist(String artistName) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tracks WHERE track_artist = ? COLLATE NOCASE',
      [artistName],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // Batch queries (avoid N+1 patterns)
  // ---------------------------------------------------------------------------

  /// Returns track counts for ALL albums in a single query.
  /// Much more efficient than calling getTrackCountForAlbum N times.
  Future<Map<String, int>> getAllAlbumTrackCounts() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT album_id, COUNT(*) as count FROM tracks GROUP BY album_id',
    );
    final result = <String, int>{};
    for (final row in rows) {
      result[row['album_id'] as String] = row['count'] as int;
    }
    return result;
  }

  /// Returns the first track's artwork path for ALL albums in a single query.
  /// Used for artwork fallback when album has no artwork.
  Future<Map<String, String?>> getAllAlbumFirstTrackArtwork() async {
    final db = await _db;
    // Get first track per album using a subquery for the minimum track_number
    final rows = await db.rawQuery('''
      SELECT t.album_id, t.artwork_thumbnail_path
      FROM tracks t
      INNER JOIN (
        SELECT album_id, MIN(COALESCE(track_number, 999999)) as min_track
        FROM tracks
        GROUP BY album_id
      ) first ON t.album_id = first.album_id
        AND COALESCE(t.track_number, 999999) = first.min_track
      GROUP BY t.album_id
    ''');
    final result = <String, String?>{};
    for (final row in rows) {
      result[row['album_id'] as String] = row['artwork_thumbnail_path'] as String?;
    }
    return result;
  }

  /// Returns all distinct artist names sorted alphabetically.
  /// Much more efficient than loading all albums and extracting names.
  Future<List<String>> getAllArtistNames() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT DISTINCT album_artist FROM albums ORDER BY album_artist COLLATE NOCASE',
    );
    return rows.map((r) => r['album_artist'] as String).toList();
  }

  /// Returns album counts for ALL artists in a single query.
  Future<Map<String, int>> getAllArtistAlbumCounts() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT album_artist, COUNT(*) as count FROM albums GROUP BY album_artist COLLATE NOCASE',
    );
    final result = <String, int>{};
    for (final row in rows) {
      result[row['album_artist'] as String] = row['count'] as int;
    }
    return result;
  }

  /// Returns all tracks for an artist in a single query.
  Future<List<Track>> getTracksForArtistDirect(String artistName) async {
    final db = await _db;
    final rows = await db.query(
      'tracks',
      columns: _trackColumns,
      where: 'track_artist = ? COLLATE NOCASE',
      whereArgs: [artistName],
      orderBy: 'album_title COLLATE NOCASE, track_number IS NULL, track_number',
    );
    return rows.map(getTrackFromRow).toList();
  }

  /// Returns total duration for an album using SUM query.
  /// More efficient than loading all tracks and summing in Dart.
  Future<Duration> getAlbumDurationSum(String albumId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT SUM(track_duration_ms) as total FROM tracks WHERE album_id = ?',
      [albumId],
    );
    final totalMs = Sqflite.firstIntValue(result) ?? 0;
    return Duration(milliseconds: totalMs);
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  /// Search tracks by title or artist with result limit.
  Future<List<Track>> searchTracks(String query, {int limit = 100}) async {
    final db = await _db;
    final rows = await db.query(
      'tracks',
      columns: _trackColumns,
      where: 'track_title LIKE ? OR track_artist LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'track_title COLLATE NOCASE',
      limit: limit,
    );
    return rows.map(getTrackFromRow).toList();
  }


}