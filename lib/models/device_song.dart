// -----------------------------------------------------------------------------
// DEVICE SONG MODEL
// -----------------------------------------------------------------------------
//
// Platform agnostic representation of a song from the device's music library.
// Serves as an intermediary between platform specific APIs (SongModel on
// Android, MPMediaItem on iOS) and the repository/DAO layer.
//
// -----------------------------------------------------------------------------

class DeviceSong {
  final int id;
  final int? albumId;
  final String? album;
  final String? artist;
  final String title;
  final String? uri;
  final String data;
  final int? duration;
  final int? dateAdded;
  final int? dateModified;
  final int? size;
  final int? track;
  final String? genre;
  final bool hasLrc;
  final String? lrcPath;
  final String? artworkThumbnailPath;
  final String? artworkHqPath;

  /// ReplayGain value in decibels for volume normalization
  final double? replayGainDb;

  const DeviceSong({
    required this.id,
    required this.title,
    required this.data,
    this.albumId,
    this.album,
    this.artist,
    this.uri,
    this.duration,
    this.dateAdded,
    this.dateModified,
    this.size,
    this.track,
    this.genre,
    this.hasLrc = false,
    this.lrcPath,
    this.artworkThumbnailPath,
    this.artworkHqPath,
    this.replayGainDb,
  });

  @override
  String toString() {
    return 'DeviceSong(id: $id, title: "$title", artist: "$artist", album: "$album")';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceSong && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}