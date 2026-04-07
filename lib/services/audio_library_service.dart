import 'package:musik_app/models/device_song.dart';
import 'package:musik_app/models/track.dart';

/// Abstract interface for platform-specific audio library services.
///
/// Implementations:
/// - [AndroidAudioLibraryService] - Queries Android MediaStore
/// - [IOSAudioLibraryService] - Manages imported audio files
abstract class AudioLibraryService {
  /// Ensure necessary permissions are granted
  Future<bool> ensurePermission();

  /// Load songs from the device (syncs with device, updates database)
  Future<List<DeviceSong>> loadSongs({bool warmArtworkCache = true});

  /// Load songs from database only (no device sync, read-only)
  Future<List<DeviceSong>> loadSongsFromDatabase();

  /// Get playable URI for a track
  Future<Uri> getTrackUri(Track track);
}
