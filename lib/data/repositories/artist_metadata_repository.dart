// -----------------------------------------------------------------------------
// ARTIST METADATA REPOSITORY
// -----------------------------------------------------------------------------
//
// Orchestrates artist metadata fetch chain: MusicBrainz -> Wikidata -> Wikipedia.
// Read-only cache access is safe for initState.
//
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:musik_app/core/log_debug.dart';
import 'package:musik_app/db/daos/artist_dao.dart';
import 'package:musik_app/models/artist.dart';
import 'package:musik_app/data/services/musicbrainz_service.dart';

class ArtistMetadataRepository {
  final ArtistDao _dao = ArtistDao();
  final MusicBrainzService _mbService = MusicBrainzService();

  static const Duration _cacheMaxAge = Duration(days: 30);

  // ACHTUNG: MusicBrainz Abfragen sind nur im Rahmen eines Forschungsprojekts erlaubt. Siehe https://metabrainz.org/supporters/account-type
  static const bool musicBrainzEnabled = true;

  bool _isBatchFetching = false;
  final Set<String> _currentlyFetching = {};

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Returns the cache directory for artist images.
  Future<Directory> _imageDir() async {
    final dir = await getTemporaryDirectory();
    final out = Directory(path.join(dir.path, 'artwork_cache'));
    if (!await out.exists()) {
      await out.create(recursive: true);
    }
    return out;
  }

  /// Sanitizes artist name for use as a filename.
  String _sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns cached artist metadata, or null. Read-only, safe for initState.
  Future<Artist?> getArtistMetadata(String artistName) async {
    return _dao.getArtist(artistName);
  }

  /// Returns all cached artists as a map keyed by artist name.
  Future<Map<String, Artist>> getAllCachedArtistsMap() async {
    final artists = await _dao.getAllCachedArtists();
    return {for (final artist in artists) artist.artistName: artist};
  }

  /// True if cached data is older than 30 days.
  bool isCacheStale(Artist artist) {
    if (artist.fetchedAtMs == null) return true;
    final fetchedAt = DateTime.fromMillisecondsSinceEpoch(artist.fetchedAtMs!);
    return DateTime.now().difference(fetchedAt) > _cacheMaxAge;
  }

  /// True if artist record exists but is missing bio or image.
  bool isMetadataIncomplete(Artist? artist) {
    if (artist == null) return true;
    return artist.bio == null || artist.imagePath == null;
  }

  /// True if a batch fetch is currently in progress.
  bool get isBatchFetching => _isBatchFetching;

  /// Fetches metadata for artists that don't have cached data.
  /// Skips if a batch fetch is already in progress or if MusicBrainz is disabled.
  /// Calls [onProgress] after each artist is fetched (for UI updates).
  Future<void> fetchMissingArtists(
    List<String> artistNames, {
    void Function(String artistName, Artist? result)? onProgress,
  }) async {
    if (!musicBrainzEnabled) return;
    if (_isBatchFetching) {
      logDebug('ArtistMetadataRepo: batch fetch already in progress, skipping');
      return;
    }
    _isBatchFetching = true;

    try {
      final cachedMap = await getAllCachedArtistsMap();

      // Filter to artists that need fetching (missing, stale, or incomplete)
      final toFetch = artistNames.where((name) {
        final cached = cachedMap[name];
        if (cached == null) return true;
        if (isMetadataIncomplete(cached)) return true;
        return isCacheStale(cached);
      }).toList();

      if (toFetch.isEmpty) {
        logDebug('ArtistMetadataRepo: all artists already cached');
        return;
      }

      logDebug('ArtistMetadataRepo: batch fetching ${toFetch.length} artists');

      for (final artistName in toFetch) {
        // Check if batch was cancelled
        if (!_isBatchFetching) break;

        final result = await fetchAndCacheArtist(artistName);
        onProgress?.call(artistName, result);
      }

      logDebug('ArtistMetadataRepo: batch fetch complete');
    } finally {
      _isBatchFetching = false;
    }
  }

  /// Cancels the current batch fetch (if any).
  void cancelBatchFetch() {
    _isBatchFetching = false;
  }

  /// Fetches artist metadata from MusicBrainz/Wikidata/Wikipedia and caches it.
  /// Set [forceRefetch] to true to retry even if we have cached (incomplete) data.
  /// Returns null if MusicBrainz is disabled.
  Future<Artist?> fetchAndCacheArtist(String artistName, {bool forceRefetch = false}) async {
    if (!musicBrainzEnabled) return null;

    // Prevent duplicate fetches for the same artist
    if (_currentlyFetching.contains(artistName)) {
      logDebug('ArtistMetadataRepo: already fetching "$artistName", skipping');
      return null;
    }

    // Skip if we have complete data and not forcing
    if (!forceRefetch) {
      final cached = await _dao.getArtist(artistName);
      if (cached != null && !isMetadataIncomplete(cached) && !isCacheStale(cached)) {
        logDebug('ArtistMetadataRepo: "$artistName" already has complete data');
        return cached;
      }
    }

    _currentlyFetching.add(artistName);
    try {
      return await _doFetch(artistName);
    } finally {
      _currentlyFetching.remove(artistName);
    }
  }

  Future<Artist?> _doFetch(String artistName) async {
    logDebug('ArtistMetadataRepo: fetching "$artistName"');

    // Step 1: Search MusicBrainz for MBID
    final mbid = await _mbService.searchArtistMbid(artistName);
    if (mbid == null) {
      // Cache a minimal record so we don't re-fetch
      final artist = Artist(
        artistName: artistName,
        fetchedAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      await _dao.upsertArtist(artist);
      return artist;
    }

    // Step 2: Lookup relations (Wikidata, Wikipedia)
    final relations = await _mbService.lookupArtistRelations(mbid);
    String? wikidataId;
    if (relations.wikidataUrl != null) {
      final uri = Uri.tryParse(relations.wikidataUrl!);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        wikidataId = uri.pathSegments.last;
      }
    }

    // Step 3: Fetch image filename and Wikipedia title from Wikidata
    String? imageFilename;
    String? wikipediaTitle = relations.wikipediaTitle;
    if (wikidataId != null) {
      final wikidataResult = await _mbService.fetchWikidataEntity(wikidataId);
      imageFilename = wikidataResult.imageFilename;
      wikipediaTitle ??= wikidataResult.wikipediaTitle;
    }

    // Step 4: Fetch bio from Wikipedia
    String? bio;
    if (wikipediaTitle != null) {
      bio = await _mbService.fetchWikipediaSummary(wikipediaTitle);
    }

    // Step 5: Download images if available (full + thumbnail)
    String? imagePath;
    String? imageThumbnailPath;
    if (imageFilename != null) {
      final dir = await _imageDir();
      final ext = path.extension(imageFilename).isNotEmpty
          ? path.extension(imageFilename)
          : '.jpg';
      final sanitizedName = _sanitizeFilename(artistName);

      // Download full resolution image
      final fullPath = path.join(dir.path, 'artist_$sanitizedName$ext');
      final fullSuccess = await _mbService.downloadImage(imageFilename, fullPath);
      if (fullSuccess) {
        imagePath = fullPath;
      }

      // Download thumbnail (for performance)
      final thumbPath = path.join(dir.path, 'artist_${sanitizedName}_thumb$ext');
      final thumbSuccess = await _mbService.downloadImageThumbnail(
        imageFilename,
        thumbPath,
        width: 200,
      );
      if (thumbSuccess) {
        imageThumbnailPath = thumbPath;
      }
    }

    // Step 6: Cache and return
    final artist = Artist(
      artistName: artistName,
      mbid: mbid,
      wikidataId: wikidataId,
      imagePath: imagePath,
      imageThumbnailPath: imageThumbnailPath,
      bio: bio,
      fetchedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _dao.upsertArtist(artist);

    return artist;
  }
}
