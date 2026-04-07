// -----------------------------------------------------------------------------
// TAGS DAO
// -----------------------------------------------------------------------------
//
// Handles database operations for track tags/genres.
// Tags are stored in a many-to-many relationship with tracks.
//
// Tag types:
// - 'genre': Music genre from file metadata (Rock, Pop, etc.)
// - 'mood': Mood-based tags (energetic, chill, etc.) - for future use
// - 'user': User-defined tags - for future use
//
// -----------------------------------------------------------------------------

import 'package:sqflite/sqflite.dart';
import '../application_database.dart';
import 'library_dao.dart';
import '../../models/track.dart';

class TagsDao {
  Future<Database> get _db async => ApplicationDatabase.instance;
  final _libraryDao = LibraryDao();

  // ---------------------------------------------------------------------------
  // Tag CRUD
  // ---------------------------------------------------------------------------

  /// Creates a tag if it doesn't exist, returns the tag ID.
  /// Tag names are case-insensitive (stored lowercase).
  Future<int> getOrCreateTag(String tagName, {String tagType = 'genre'}) async {
    final db = await _db;
    final normalizedName = tagName.trim().toLowerCase();

    if (normalizedName.isEmpty) {
      throw ArgumentError('Tag name cannot be empty');
    }

    // Check if tag exists
    final existing = await db.query(
      'tags',
      columns: ['tag_id'],
      where: 'tag_name = ?',
      whereArgs: [normalizedName],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return existing.first['tag_id'] as int;
    }

    // Create new tag
    return db.insert('tags', {
      'tag_name': normalizedName,
      'tag_type': tagType,
    });
  }

  /// Gets all tags, optionally filtered by type.
  Future<List<Map<String, dynamic>>> getAllTags({String? tagType}) async {
    final db = await _db;

    if (tagType != null) {
      return db.query(
        'tags',
        where: 'tag_type = ?',
        whereArgs: [tagType],
        orderBy: 'tag_name COLLATE NOCASE',
      );
    }

    return db.query('tags', orderBy: 'tag_name COLLATE NOCASE');
  }

  /// Gets all unique tag names.
  Future<List<String>> getAllTagNames({String? tagType}) async {
    final tags = await getAllTags(tagType: tagType);
    return tags.map((t) => t['tag_name'] as String).toList();
  }

  // ---------------------------------------------------------------------------
  // Track-Tag Operations
  // ---------------------------------------------------------------------------

  /// Adds a tag to a track.
  Future<void> addTagToTrack(String trackId, String tagName, {String tagType = 'genre'}) async {
    final db = await _db;
    final tagId = await getOrCreateTag(tagName, tagType: tagType);

    await db.insert(
      'track_tags',
      {'track_id': trackId, 'tag_id': tagId},
      conflictAlgorithm: ConflictAlgorithm.ignore, // Ignore if already exists
    );
  }

  /// Adds multiple tags to a track.
  Future<void> addTagsToTrack(String trackId, List<String> tagNames, {String tagType = 'genre'}) async {
    for (final tagName in tagNames) {
      await addTagToTrack(trackId, tagName, tagType: tagType);
    }
  }

  /// Removes a tag from a track.
  Future<void> removeTagFromTrack(String trackId, String tagName) async {
    final db = await _db;
    final normalizedName = tagName.trim().toLowerCase();

    await db.rawDelete('''
      DELETE FROM track_tags
      WHERE track_id = ?
      AND tag_id = (SELECT tag_id FROM tags WHERE tag_name = ?)
    ''', [trackId, normalizedName]);
  }

  /// Gets all tags for a track.
  Future<List<String>> getTagsForTrack(String trackId) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT t.tag_name
      FROM track_tags tt
      JOIN tags t ON t.tag_id = tt.tag_id
      WHERE tt.track_id = ?
      ORDER BY t.tag_name COLLATE NOCASE
    ''', [trackId]);

    return rows.map((r) => r['tag_name'] as String).toList();
  }

  /// Gets all tracks with a specific tag.
  Future<List<Track>> getTracksWithTag(String tagName) async {
    final db = await _db;
    final normalizedName = tagName.trim().toLowerCase();

    final rows = await db.rawQuery('''
      SELECT tr.*
      FROM tracks tr
      JOIN track_tags tt ON tt.track_id = tr.track_id
      JOIN tags t ON t.tag_id = tt.tag_id
      WHERE t.tag_name = ?
      ORDER BY tr.track_artist COLLATE NOCASE, tr.album_title COLLATE NOCASE
    ''', [normalizedName]);

    return rows.map(_libraryDao.getTrackFromRow).toList();
  }

  /// Gets all tracks with any of the specified tags.
  Future<List<Track>> getTracksWithAnyTag(List<String> tagNames) async {
    if (tagNames.isEmpty) return [];

    final db = await _db;
    final normalized = tagNames.map((t) => t.trim().toLowerCase()).toList();
    final placeholders = List.filled(normalized.length, '?').join(', ');

    final rows = await db.rawQuery('''
      SELECT DISTINCT tr.*
      FROM tracks tr
      JOIN track_tags tt ON tt.track_id = tr.track_id
      JOIN tags t ON t.tag_id = tt.tag_id
      WHERE t.tag_name IN ($placeholders)
      ORDER BY tr.track_artist COLLATE NOCASE, tr.album_title COLLATE NOCASE
    ''', normalized);

    return rows.map(_libraryDao.getTrackFromRow).toList();
  }

  /// Gets track count for each tag.
  Future<Map<String, int>> getTagCounts() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT t.tag_name, COUNT(tt.track_id) as count
      FROM tags t
      LEFT JOIN track_tags tt ON tt.tag_id = t.tag_id
      GROUP BY t.tag_id
      ORDER BY count DESC
    ''');

    return {
      for (final row in rows)
        row['tag_name'] as String: row['count'] as int
    };
  }

  /// Clears all tags from a track.
  Future<void> clearTagsForTrack(String trackId) async {
    final db = await _db;
    await db.delete('track_tags', where: 'track_id = ?', whereArgs: [trackId]);
  }

  /// Sets the tags for a track (replaces existing tags).
  Future<void> setTagsForTrack(String trackId, List<String> tagNames, {String tagType = 'genre'}) async {
    final db = await _db;
    await db.transaction((txn) async {
      // Clear existing tags
      await txn.delete('track_tags', where: 'track_id = ?', whereArgs: [trackId]);

      // Add new tags
      for (final tagName in tagNames) {
        final normalizedName = tagName.trim().toLowerCase();
        if (normalizedName.isEmpty) continue;

        // Get or create tag
        final existing = await txn.query(
          'tags',
          columns: ['tag_id'],
          where: 'tag_name = ?',
          whereArgs: [normalizedName],
          limit: 1,
        );

        int tagId;
        if (existing.isNotEmpty) {
          tagId = existing.first['tag_id'] as int;
        } else {
          tagId = await txn.insert('tags', {
            'tag_name': normalizedName,
            'tag_type': tagType,
          });
        }

        await txn.insert(
          'track_tags',
          {'track_id': trackId, 'tag_id': tagId},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }
}
