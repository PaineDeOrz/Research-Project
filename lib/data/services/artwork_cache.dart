// -----------------------------------------------------------------------------
// ARTWORK CACHE
// -----------------------------------------------------------------------------
//
// Manages on disk caching of album and track artwork at two quality tiers
// (thumbnail and HQ). Uses OnAudioQuery to fetch artwork from the system
// media library when not already cached.
//
// -----------------------------------------------------------------------------

import 'dart:io';
import 'dart:typed_data';

import 'package:on_audio_query/on_audio_query.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

enum ArtworkQualityTier { thumb, hq }

class ArtworkCache {
  ArtworkCache({OnAudioQuery? onAudioQuery})
      : _onAudioQuery = onAudioQuery ?? OnAudioQuery();

  final OnAudioQuery _onAudioQuery;

  static const int _thumbSize = 300;
  static const int _thumbQuality = 85;
  static const int _hqSize = 1200;
  static const int _hqQuality = 95;

  Future<Directory> _baseDir() async {
    final tempDirectory = await getTemporaryDirectory();
    final cacheDirectory = Directory(path.join(tempDirectory.path, 'artwork_cache'));
    if (!await cacheDirectory.exists()) {
      await cacheDirectory.create(recursive: true);
    }
    return cacheDirectory;
  }

  // ---------------------------------------------------------------------------
  // Save raw bytes extracted from audio files
  // ---------------------------------------------------------------------------

  Future<String> saveTrackThumb({required String trackId, required Uint8List bytes}) async {
    final dir = await _baseDir();
    final file = File(path.join(dir.path, 'track_${trackId}_thumb.jpg'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<String> saveTrackHq({required String trackId, required Uint8List bytes}) async {
    final dir = await _baseDir();
    final file = File(path.join(dir.path, 'track_${trackId}_hq.jpg'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<String> saveAlbumThumb({required String albumId, required Uint8List bytes}) async {
    final dir = await _baseDir();
    final file = File(path.join(dir.path, 'album_${albumId}_thumb.jpg'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<String> saveAlbumHq({required String albumId, required Uint8List bytes}) async {
    final dir = await _baseDir();
    final file = File(path.join(dir.path, 'album_${albumId}_hq.jpg'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  // ---------------------------------------------------------------------------
  // Cache existence checks
  // ---------------------------------------------------------------------------

  Future<bool> hasTrackArtwork(String trackId) async {
    final dir = await _baseDir();
    final file = File(path.join(dir.path, 'track_${trackId}_thumb.jpg'));
    return await file.exists();
  }

  Future<bool> hasAlbumArtwork(String albumId) async {
    final dir = await _baseDir();
    final file = File(path.join(dir.path, 'album_${albumId}_thumb.jpg'));
    return await file.exists();
  }

  // ---------------------------------------------------------------------------
  // Tiered caching from system media library
  // ---------------------------------------------------------------------------

  Future<String?> cacheAlbumArtworkTiered({
    required String albumId,
    required ArtworkQualityTier tier,
  }) async {
    final id = int.tryParse(albumId);
    if (id == null) return null;
    final dir = await _baseDir();
    final file = File(path.join(dir.path, 'album_${albumId}_${tier.name}.jpg'));
    if (await file.exists() && await file.length() > 0) return file.path;

    final bytes = await _onAudioQuery.queryArtwork(
      id,
      ArtworkType.ALBUM,
      size: tier == ArtworkQualityTier.thumb ? _thumbSize : _hqSize,
      quality: tier == ArtworkQualityTier.thumb ? _thumbQuality : _hqQuality,
    );

    if (bytes == null || bytes.isEmpty) return null;
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<String?> cacheTrackArtworkTiered({
    required String trackId,
    required ArtworkQualityTier tier,
  }) async {
    final id = int.tryParse(trackId);
    if (id == null) return null;
    final dir = await _baseDir();
    final file = File(path.join(dir.path, 'track_${trackId}_${tier.name}.jpg'));
    if (await file.exists() && await file.length() > 0) return file.path;

    final bytes = await _onAudioQuery.queryArtwork(
      id,
      ArtworkType.AUDIO,
      size: tier == ArtworkQualityTier.thumb ? _thumbSize : _hqSize,
      quality: tier == ArtworkQualityTier.thumb ? _thumbQuality : _hqQuality,
    );

    if (bytes == null || bytes.isEmpty) return null;
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  // Convenience wrappers
  Future<String?> cacheAlbumThumb({required String albumId}) => cacheAlbumArtworkTiered(albumId: albumId, tier: ArtworkQualityTier.thumb);
  Future<String?> cacheAlbumHq({required String albumId}) => cacheAlbumArtworkTiered(albumId: albumId, tier: ArtworkQualityTier.hq);
  Future<String?> cacheTrackThumb({required String trackId}) => cacheTrackArtworkTiered(trackId: trackId, tier: ArtworkQualityTier.thumb);
  Future<String?> cacheTrackHq({required String trackId}) => cacheTrackArtworkTiered(trackId: trackId, tier: ArtworkQualityTier.hq);
}
