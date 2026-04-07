// -----------------------------------------------------------------------------
// ARTWORK REPOSITORY
// -----------------------------------------------------------------------------
//
// Saves and caches artwork images for tracks and albums.
// Writes raw bytes to disk via ArtworkCache and updates DB paths via LibraryDao.
//
// -----------------------------------------------------------------------------

import 'dart:typed_data';

import '../../core/log_debug.dart';
import '../../db/daos/library_dao.dart';
import '../services/artwork_cache.dart';

class ArtworkRepository {
  ArtworkRepository({LibraryDao? dao, ArtworkCache? cache})
      : _dao = dao ?? LibraryDao(),
        _cache = cache ?? ArtworkCache();

  final LibraryDao _dao;
  final ArtworkCache _cache;

  /// Saves raw bytes for a track's artwork and updates DB paths
  Future<void> saveTrackArtwork(String trackId, Uint8List bytes) async {
    try {
      final thumb = await _cache.saveTrackThumb(trackId: trackId, bytes: bytes);
      final hq = await _cache.saveTrackHq(trackId: trackId, bytes: bytes);

      await _dao.updateTrackArtworkPaths(
        trackId: trackId,
        thumbnailPath: thumb,
        hqPath: hq,
      );
    } catch (error) {
      logDebug('ArtworkRepository: Failed to save track artwork for $trackId: $error');
    }
  }

  /// Saves raw bytes for an album's artwork and updates DB paths
  Future<void> saveAlbumArtwork(String albumId, Uint8List bytes) async {
    try {
      final thumb = await _cache.saveAlbumThumb(albumId: albumId, bytes: bytes);
      final hq = await _cache.saveAlbumHq(albumId: albumId, bytes: bytes);

      await _dao.updateAlbumArtworkPaths(
        albumId: albumId,
        thumbnailPath: thumb,
        hqPath: hq,
      );
    } catch (error) {
      logDebug('ArtworkRepository: Failed to save album artwork for $albumId: $error');
    }
  }

  Future<void> ensureAlbumArtworkCached(String albumId) async {
    final thumb = await _cache.cacheAlbumThumb(albumId: albumId);
    final hq = await _cache.cacheAlbumHq(albumId: albumId);

    await _dao.updateAlbumArtworkPaths(
      albumId: albumId,
      thumbnailPath: thumb,
      hqPath: hq,
    );
  }

  Future<void> ensureTrackArtworkCached(String trackId) async {
    final thumb = await _cache.cacheTrackThumb(trackId: trackId);
    final hq = await _cache.cacheTrackHq(trackId: trackId);

    await _dao.updateTrackArtworkPaths(
      trackId: trackId,
      thumbnailPath: thumb,
      hqPath: hq,
    );
  }
}
