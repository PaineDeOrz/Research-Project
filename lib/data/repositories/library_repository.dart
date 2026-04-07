// -----------------------------------------------------------------------------
// LIBRARY REPOSITORY
// -----------------------------------------------------------------------------
//
// Business logic layer for the music library. Wraps LibraryDao and provides:
// caching, album lookups, and genre tag syncing. Notifies listeners when the library data changes
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

import '../../core/log_debug.dart';
import '../../db/daos/library_dao.dart';
import '../../db/daos/tags_dao.dart';
import '../../models/album.dart';
import '../../models/device_song.dart';
import '../../models/track.dart';

class LibraryRepository extends ChangeNotifier {
  LibraryRepository({LibraryDao? dao, TagsDao? tagsDao})
      : _dao = dao ?? LibraryDao(),
        _tagsDao = tagsDao ?? TagsDao();

  final LibraryDao _dao;
  final TagsDao _tagsDao;

  // ---------------------------------------------------------------------------
  // Cache
  // ---------------------------------------------------------------------------

  List<Album>? _albumsCache;
  void _invalidateAlbumsCache() {
    _albumsCache = null;
  }

  // ---------------------------------------------------------------------------
  // Sync
  // ---------------------------------------------------------------------------

  /// Sync albums and tracks from device query results into SQLite.
  /// Also saves genre metadata as tags and removes orphaned tracks.
  Future<void> syncLibraryFromDevice(List<DeviceSong> tracks) async {
    try {
      await _dao.syncLibraryFromDevice(tracks);
      logDebug('LibraryRepository: synced ${tracks.length} device tracks');
    } catch (exception) {
      logDebug('LibraryRepository: sync failed, error=$exception');
      rethrow;
    }

    // Remove tracks that are no longer on the device
    try {
      final currentTrackIds = tracks.map((track) => track.id.toString()).toSet();
      await _dao.removeTracksNotInSet(currentTrackIds);
    } catch (exception) {
      logDebug('LibraryRepository: orphan cleanup failed (non-fatal), error=$exception');
    }

    // Genre tag sync is non fatal so library sync still works
    try {
      await _syncGenreTags(tracks);
    } catch (exception) {
      logDebug('LibraryRepository: tag sync failed (non-fatal), error=$exception');
    }

    _invalidateAlbumsCache();
    notifyListeners();
  }

  /// Extracts genres from DeviceSongs and saves them as tags.
  /// Uses simple inserts instead of transactions to avoid locking issues.
  Future<void> _syncGenreTags(List<DeviceSong> tracks) async {
    int taggedCount = 0;

    for (final track in tracks) {
      if (track.genre == null || track.genre!.isEmpty) continue;

      final trackId = track.id.toString();

      // Genre can be comma separated if multiple
      final genres = track.genre!
          .split(',')
          .map((genre) => genre.trim())
          .where((genre) => genre.isNotEmpty)
          .toList();

      if (genres.isNotEmpty) {
        await _tagsDao.addTagsToTrack(trackId, genres, tagType: 'genre');
        taggedCount++;
      }
    }

    if (taggedCount > 0) {
      logDebug('LibraryRepository: tagged $taggedCount tracks with genres');
    }
  }

  /// Batch updates track_path and track_uri for tracks whose paths went stale.
  Future<void> updateTrackPaths(Map<String, String> trackIdToNewPath) async {
    await _dao.updateTrackPaths(trackIdToNewPath);
  }

  // ---------------------------------------------------------------------------
  // Tracks
  // ---------------------------------------------------------------------------

  Future<List<Track>> getAllTracks() async => _dao.getAllTracks();

  Future<Track?> getTrackById(String trackId) async => _dao.getTrackById(trackId);

  Future<List<Track>> search(String query) => _dao.searchTracks(query);

  // ---------------------------------------------------------------------------
  // Albums
  // ---------------------------------------------------------------------------

  /// All albums sorted by artist then title. Cached until invalidated.
  Future<List<Album>> getAllAlbums() async {
    _albumsCache ??= await _dao.getAllAlbums();
    return _albumsCache!;
  }

  /// Finds an album by ID. Returns null if not found.
  Future<Album?> getAlbumById(String albumId) async {
    final albums = await getAllAlbums();
    for (final album in albums) {
      if (album.albumId == albumId) return album;
    }
    return null;
  }

  /// All tracks belonging to an album, ordered by track number.
  Future<List<Track>> getTracksForAlbum(String albumId) async {
    return _dao.getTracksForAlbum(albumId);
  }

  /// Returns the track count for an album without loading track objects.
  Future<int> getTrackCountForAlbum(String albumId) async {
    return _dao.getTrackCountForAlbum(albumId);
  }

  /// Returns just the first track for an album (for artwork fallback).
  Future<Track?> getFirstTrackForAlbum(String albumId) async {
    return _dao.getFirstTrackForAlbum(albumId);
  }

  /// Total duration of all tracks in an album using SUM query.
  Future<Duration> getAlbumDuration(String albumId) async {
    return _dao.getAlbumDurationSum(albumId);
  }

  // ---------------------------------------------------------------------------
  // Batch queries (avoid N+1 patterns in list screens)
  // ---------------------------------------------------------------------------

  /// Returns track counts for ALL albums in a single query.
  Future<Map<String, int>> getAllAlbumTrackCounts() async {
    return _dao.getAllAlbumTrackCounts();
  }

  /// Returns first track artwork for ALL albums in a single query.
  Future<Map<String, String?>> getAllAlbumFirstTrackArtwork() async {
    return _dao.getAllAlbumFirstTrackArtwork();
  }

  /// Force refresh albums from database.
  Future<void> refreshAlbums() async {
    _invalidateAlbumsCache();
    await getAllAlbums();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Artists
  // ---------------------------------------------------------------------------

  /// All distinct artist names sorted alphabetically.
  /// Uses efficient DISTINCT query instead of loading all albums.
  Future<List<String>> getAllArtists() async {
    return _dao.getAllArtistNames();
  }

  /// Returns album counts for ALL artists in a single query.
  Future<Map<String, int>> getAllArtistAlbumCounts() async {
    return _dao.getAllArtistAlbumCounts();
  }

  /// All albums by a given artist, sorted by title.
  Future<List<Album>> getAlbumsForArtist(String artistName) async {
    final albums = await getAllAlbums();
    return albums
        .where((album) => album.albumArtist == artistName)
        .toList();
  }

  /// Returns the track count for an artist without loading track objects.
  Future<int> getTrackCountForArtist(String artistName) async {
    return _dao.getTrackCountForArtist(artistName);
  }

  /// All tracks by a given artist using single query.
  Future<List<Track>> getTracksForArtist(String artistName) async {
    return _dao.getTracksForArtistDirect(artistName);
  }

  // ---------------------------------------------------------------------------
  // Genres
  // ---------------------------------------------------------------------------

  /// All genre names with their track counts, sorted by count descending.
  Future<Map<String, int>> getGenreTagCounts() async {
    return _tagsDao.getTagCounts();
  }

  /// All tracks tagged with a given genre.
  Future<List<Track>> getTracksForGenre(String genreName) async {
    return _tagsDao.getTracksWithTag(genreName);
  }
}
