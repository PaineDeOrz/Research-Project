// -----------------------------------------------------------------------------
// IOS AUDIO LIBRARY SERVICE
// -----------------------------------------------------------------------------
//
// Handles music library for iOS. Manages imported audio files in the app's
// documents directory, extracts metadata (genre, ReplayGain), and syncs to SQLite.
//
// -----------------------------------------------------------------------------

import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:musik_app/data/repositories/library_repository.dart';
import 'package:musik_app/data/repositories/artwork_repository.dart';
import 'package:musik_app/models/device_song.dart';
import 'package:musik_app/models/track.dart';
import 'package:musik_app/services/audio_library_service.dart';
import 'package:musik_app/services/audio_metadata_utils.dart';

import '../core/log_debug.dart';

class IOSAudioLibraryService implements AudioLibraryService {
  final LibraryRepository _libraryRepository;
  final ArtworkRepository _artworkRepository;

  IOSAudioLibraryService({
    LibraryRepository? libraryRepository,
    ArtworkRepository? artworkRepository,
  })  : _libraryRepository = libraryRepository ?? LibraryRepository(),
        _artworkRepository = artworkRepository ?? ArtworkRepository();

  // ---------------------------------------------------------------------------
  // AudioLibraryService Interface
  // ---------------------------------------------------------------------------

  @override
  Future<bool> ensurePermission() async => true;

  @override
  Future<List<DeviceSong>> loadSongs({bool warmArtworkCache = true}) async {
    try {
      logDebug('IOSAudioLibraryService: loading songs');
      final importDir = await _getImportDirectory();

      if (!await importDir.exists()) {
        await importDir.create(recursive: true);
      }

      final files = importDir
          .listSync()
          .whereType<File>()
          .where((file) => _isAudioFile(file.path))
          .toList();

      final deviceSongs = <DeviceSong>[];
      for (final file in files) {
        final song = await _fileToDeviceSong(file);
        deviceSongs.add(song);
      }

      await _libraryRepository.syncLibraryFromDevice(deviceSongs);
      final tracksFromDb = await _libraryRepository.getAllTracks();

      return tracksFromDb.map(trackToDeviceSong).toList();
    } catch (exception) {
      logDebug('IOSAudioLibraryService: loadSongs failed: $exception');
      return [];
    }
  }

  @override
  Future<List<DeviceSong>> loadSongsFromDatabase() async {
    await _refreshStaleTrackPaths();
    final tracksFromDb = await _libraryRepository.getAllTracks();
    return tracksFromDb.map(trackToDeviceSong).toList();
  }

  @override
  Future<Uri> getTrackUri(Track track) async {
    final storedPath = track.trackPath;
    if (storedPath != null && storedPath.isNotEmpty && await File(storedPath).exists()) {
      return Uri.file(storedPath);
    }

    // Stored path is stale. Resolve from filename against current import directory.
    final resolvedPath = await _resolveTrackPath(track);
    if (resolvedPath != null) return Uri.file(resolvedPath);

    // No valid path found
    return Uri.file(storedPath ?? '');
  }

  // ---------------------------------------------------------------------------
  // File Import
  // ---------------------------------------------------------------------------

  Future<int> importAudioFiles() async {
    logDebug('IOSAudioLibraryService: importAudioFiles called');

    try {
      // FileType.any because iOS doesn't recognize .lrc as a UTI
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      logDebug('IOSAudioLibraryService: picker result = $result');

      if (result == null) {
        logDebug('IOSAudioLibraryService: user cancelled picker');
        return 0;
      }

      logDebug('IOSAudioLibraryService: picked ${result.files.length} files');

      final importDir = await _getImportDirectory();
      int importedCount = 0;

      final importableFiles = result.files.where((file) => _isImportableFile(file.name));

      for (final file in importableFiles) {
        logDebug('IOSAudioLibraryService: processing file ${file.name}, path=${file.path}');
        if (file.path == null) continue;
        final destPath = '${importDir.path}/${file.name}';
        if (await File(destPath).exists()) {
          logDebug('IOSAudioLibraryService: file already exists, skipping');
          continue;
        }
        await File(file.path!).copy(destPath);
        importedCount++;
        logDebug('IOSAudioLibraryService: copied to $destPath');
      }

      await loadSongs();
      return importedCount;
    } catch (exception, stackTrace) {
      logDebug('IOSAudioLibraryService: importAudioFiles error: $exception');
      logDebug('IOSAudioLibraryService: $stackTrace');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Metadata Extraction
  // ---------------------------------------------------------------------------

  Future<DeviceSong> _fileToDeviceSong(File file) async {
    final stat = await file.stat();
    final fileName = file.path.split('/').last;

    // Stable ID derived from filename so it survives file reordering and sandbox path changes
    final stableId = fileName.hashCode.abs();

    // Fallback values
    String title = _formatFallbackTitle(fileName);
    String artist = 'Unknown Artist';
    String album = 'Unknown Album';
    int albumId = fileName.hashCode.abs();
    int? duration;
    int? trackNumber;
    String? genre;
    double? replayGainDb;

    try {
      final metadata = readMetadata(file, getImage: true);

      if (metadata.title != null && metadata.title!.isNotEmpty) {
        title = metadata.title!;
      }
      if (metadata.artist != null && metadata.artist!.isNotEmpty) {
        artist = metadata.artist!;
      }
      if (metadata.album != null && metadata.album!.isNotEmpty) {
        album = metadata.album!;
      }
      if (metadata.duration != null) {
        duration = metadata.duration!.inMilliseconds;
      }
      if (metadata.trackNumber != null) {
        trackNumber = metadata.trackNumber;
      }
      if (album.isNotEmpty) {
        albumId = album.hashCode.abs();
      }
      if (metadata.genres.isNotEmpty) {
        genre = metadata.genres.join(', ');
      }

      // Extract ReplayGain from ID3 tags
      replayGainDb = await extractReplayGain(file);

      // Save artwork if available
      if (metadata.pictures.isNotEmpty) {
        final bytes = metadata.pictures.first.bytes;
        await _artworkRepository.saveTrackArtwork(stableId.toString(), bytes);
        await _artworkRepository.saveAlbumArtwork(albumId.toString(), bytes);
        logDebug('IOSAudioLibraryService: Artwork extracted for $title');
      }
    } catch (exception) {
      logDebug('IOSAudioLibraryService: Metadata extraction failed for $fileName: $exception');
    }

    return DeviceSong(
      id: stableId,
      title: title,
      data: file.path,
      uri: fileName,
      artist: artist,
      album: album,
      albumId: albumId,
      duration: duration,
      dateAdded: stat.modified.millisecondsSinceEpoch,
      dateModified: stat.modified.millisecondsSinceEpoch,
      size: stat.size,
      track: trackNumber,
      genre: genre,
      replayGainDb: replayGainDb,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<Directory> _getImportDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return Directory('${appDocDir.path}/imported_music');
  }

  /// iOS can change the app sandbox container UUID between launches.
  /// This checks all stored track paths and updates any that point to the old container.
  Future<void> _refreshStaleTrackPaths() async {
    final importDir = await _getImportDirectory();
    final importPath = importDir.path;
    final tracks = await _libraryRepository.getAllTracks();
    if (tracks.isEmpty) return;

    final pathUpdates = <String, String>{};
    for (final track in tracks) {
      final storedPath = track.trackPath;
      if (storedPath == null || storedPath.isEmpty) continue;
      if (await File(storedPath).exists()) continue;

      // Extract filename and resolve against current import directory
      final fileName = storedPath.split('/').last;
      final newPath = '$importPath/$fileName';
      if (await File(newPath).exists()) {
        pathUpdates[track.trackId] = newPath;
      }
    }

    if (pathUpdates.isNotEmpty) {
      logDebug('IOSAudioLibraryService: refreshing ${pathUpdates.length} stale track paths');
      await _libraryRepository.updateTrackPaths(pathUpdates);
    }
  }

  /// Resolves a track's file path from its filename against the current import directory.
  Future<String?> _resolveTrackPath(Track track) async {
    // Try the URI field which stores just the filename on iOS
    final uri = track.trackUri;
    if (uri.isNotEmpty && !uri.contains('/')) {
      final importDir = await _getImportDirectory();
      final resolved = '${importDir.path}/$uri';
      if (await File(resolved).exists()) return resolved;
    }

    // Try extracting filename from the stored absolute path
    final storedPath = track.trackPath;
    if (storedPath != null && storedPath.isNotEmpty) {
      final fileName = storedPath.split('/').last;
      final importDir = await _getImportDirectory();
      final resolved = '${importDir.path}/$fileName';
      if (await File(resolved).exists()) return resolved;
    }

    return null;
  }

  bool _isAudioFile(String path) {
    final extension = path.toLowerCase().split('.').last;
    return ['mp3', 'm4a', 'aac', 'wav', 'flac'].contains(extension);
  }

  bool _isImportableFile(String path) {
    final extension = path.toLowerCase().split('.').last;
    return ['mp3', 'm4a', 'aac', 'wav', 'flac', 'alac', 'aiff', 'lrc'].contains(extension);
  }

  String _formatFallbackTitle(String fileName) {
    return fileName
        .split('.')
        .first
        .replaceAll(RegExp(r'[-_]'), ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
