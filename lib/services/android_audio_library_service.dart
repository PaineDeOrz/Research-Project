// -----------------------------------------------------------------------------
// ANDROID AUDIO LIBRARY SERVICE
// -----------------------------------------------------------------------------
//
// Handles music library sync for Android. Queries MediaStore, extracts
// metadata (genre, ReplayGain), syncs to SQLite, and warms artwork cache.
//
// -----------------------------------------------------------------------------

import 'dart:async';
import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:musik_app/data/repositories/library_repository.dart';
import 'package:musik_app/data/repositories/artwork_repository.dart';
import 'package:musik_app/models/device_song.dart';
import 'package:musik_app/services/audio_library_service.dart';
import 'package:musik_app/services/audio_metadata_utils.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../core/log_debug.dart';
import '../models/track.dart';

class AndroidAudioLibraryService implements AudioLibraryService {
  final OnAudioQuery _onAudioQuery = OnAudioQuery();
  final LibraryRepository _libraryRepository;
  final ArtworkRepository _artworkRepository;

  AndroidAudioLibraryService({
    LibraryRepository? libraryRepository,
    ArtworkRepository? artworkRepository,
  })  : _libraryRepository = libraryRepository ?? LibraryRepository(),
        _artworkRepository = artworkRepository ?? ArtworkRepository();

  // ---------------------------------------------------------------------------
  // AudioLibraryService Interface
  // ---------------------------------------------------------------------------

  @override
  Future<bool> ensurePermission() async {
    final permissionStatus = await _onAudioQuery.permissionsStatus();
    if (permissionStatus) return true;
    return _onAudioQuery.permissionsRequest();
  }

  @override
  Future<List<DeviceSong>> loadSongs({bool warmArtworkCache = true}) async {
    final hasPermission = await ensurePermission();
    if (!hasPermission) return [];

    final songs = await _onAudioQuery.querySongs(
      sortType: SongSortType.DISPLAY_NAME,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    final deviceSongs = <DeviceSong>[];
    for (final song in songs) {
      final deviceSong = await _convertToDeviceSong(song);
      deviceSongs.add(deviceSong);
    }

    await _libraryRepository.syncLibraryFromDevice(deviceSongs);

    if (warmArtworkCache) {
      unawaited(_warmArtworkCache(songs).catchError((exception, stackTrace) {
        logDebug('AndroidAudioLibraryService: warmArtworkCache failed: $exception');
      }));
    }

    final tracksFromDb = await _libraryRepository.getAllTracks();
    return tracksFromDb.map(trackToDeviceSong).toList();
  }

  @override
  Future<List<DeviceSong>> loadSongsFromDatabase() async {
    final tracksFromDb = await _libraryRepository.getAllTracks();
    return tracksFromDb.map(trackToDeviceSong).toList();
  }

  @override
  Future<Uri> getTrackUri(Track track) async {
    final path = track.trackPath;
    if (path == null || path.isEmpty) {
      throw StateError(
        'Track "${track.trackTitle}" has no file path. Try refreshing the library.',
      );
    }
    return Uri.file(path);
  }

  // ---------------------------------------------------------------------------
  // Metadata Extraction
  // ---------------------------------------------------------------------------

  /// Converts Android SongModel to platform independent DeviceSong.
  Future<DeviceSong> _convertToDeviceSong(SongModel song) async {
    String? genre;
    double? replayGainDb;

    try {
      final file = File(song.data);
      if (await file.exists()) {
        final metadata = readMetadata(file, getImage: false);
        if (metadata.genres.isNotEmpty) {
          genre = metadata.genres.join(', ');
        }
        replayGainDb = await extractReplayGain(file);
      }
    } catch (exception) {
      logDebug('AndroidAudioLibraryService: Metadata extraction failed for ${song.title}: $exception');
    }

    return DeviceSong(
      id: song.id,
      albumId: song.albumId,
      album: song.album,
      artist: song.artist,
      title: song.title,
      uri: song.uri,
      data: song.data,
      duration: song.duration,
      dateAdded: song.dateAdded,
      dateModified: song.dateModified,
      size: song.size,
      track: song.track,
      genre: genre,
      replayGainDb: replayGainDb,
    );
  }

  // ---------------------------------------------------------------------------
  // Artwork Cache
  // ---------------------------------------------------------------------------

  Future<void> _warmArtworkCache(List<SongModel> songs) async {
    final albumIds = <String>{};
    for (final song in songs) {
      final id = (song.albumId?.toString() ?? '').trim();
      if (id.isNotEmpty) albumIds.add(id);
    }

    logDebug('WarmArtwork: caching albums count=${albumIds.length}');
    await _runWithConcurrencyLimit(
      items: albumIds.toList(growable: false),
      limit: 3,
      task: (albumId) => _artworkRepository.ensureAlbumArtworkCached(albumId),
    );

    logDebug('WarmArtwork: caching tracks count=${songs.length}');
    final trackIds = songs.map((song) => song.id.toString()).toList(growable: false);
    await _runWithConcurrencyLimit(
      items: trackIds,
      limit: 2,
      task: (trackId) => _artworkRepository.ensureTrackArtworkCached(trackId),
    );
  }

  Future<void> _runWithConcurrencyLimit<T>({
    required List<T> items,
    required int limit,
    required Future<void> Function(T item) task,
  }) async {
    final queue = Stream<T>.fromIterable(items);
    final semaphore = _AsyncSemaphore(limit);
    final futures = <Future<void>>[];

    await for (final item in queue) {
      await semaphore.acquire();
      futures.add(Future(() async {
        try {
          await task(item);
        } catch (exception, stackTrace) {
          logDebug('WarmArtwork: task failed for item=$item error=$exception');
          logDebug('WarmArtwork: $stackTrace');
        } finally {
          semaphore.release();
        }
      }));
    }
    await Future.wait(futures);
  }
}

// -----------------------------------------------------------------------------
// Async Semaphore
// -----------------------------------------------------------------------------

class _AsyncSemaphore {
  _AsyncSemaphore(this._max);

  final int _max;
  int _current = 0;
  final _waiters = <Completer<void>>[];

  Future<void> acquire() {
    if (_current < _max) {
      _current++;
      return Future.value();
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
      return;
    }
    _current = (_current - 1).clamp(0, _max);
  }
}
