// -----------------------------------------------------------------------------
// ARTIST DAO
// -----------------------------------------------------------------------------
//
// SQL helpers for artist metadata cache. Handles CRUD for the artists table.
//
// -----------------------------------------------------------------------------

import 'package:sqflite/sqflite.dart';
import 'package:musik_app/db/application_database.dart';
import 'package:musik_app/models/artist.dart';

class ArtistDao {
  Future<Database> get _db async => ApplicationDatabase.instance;

  /// Returns a cached artist row, or null.
  Future<Artist?> getArtist(String artistName) async {
    final db = await _db;
    final rows = await db.query(
      'artists',
      where: 'artist_name = ?',
      whereArgs: [artistName],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Artist.fromMap(rows.first);
  }

  /// Inserts or replaces an artist row.
  Future<void> upsertArtist(Artist artist) async {
    final db = await _db;
    await db.insert(
      'artists',
      artist.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Updates only the local image path for a cached artist.
  Future<void> updateImagePath(String artistName, String imagePath) async {
    final db = await _db;
    await db.update(
      'artists',
      {'image_path': imagePath},
      where: 'artist_name = ?',
      whereArgs: [artistName],
    );
  }

  /// Returns all cached artists that have metadata.
  Future<List<Artist>> getAllCachedArtists() async {
    final db = await _db;
    final rows = await db.query('artists');
    return rows.map(Artist.fromMap).toList();
  }
}
