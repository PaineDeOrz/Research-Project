// -----------------------------------------------------------------------------
// SONG TRACK MAPPER
// -----------------------------------------------------------------------------
//
// Conversion utilities between different song representations.
//
// -----------------------------------------------------------------------------

import 'package:on_audio_query/on_audio_query.dart';

import '../device_song.dart';
import '../track.dart';

/// Convert Android SongModel to Track.
Track songModelToTrack(SongModel song) {
  return Track(
    trackId: song.id.toString(),
    trackUri: song.uri.toString(),
    albumTitle: song.album.toString(),
    albumId: song.albumId.toString(),
    trackTitle: song.title,
    trackArtist: (song.artist?.isNotEmpty ?? false) ? song.artist! : 'Unknown Artist',
    trackDuration: Duration(milliseconds: song.duration ?? 0),
    trackPath: song.data,
    dateAdded: song.dateAdded,
    trackModifiedLast: song.dateModified,
    trackSize: song.size,
    trackNumber: song.track,
  );
}

/// Convert Track back to DeviceSong for legacy bottom sheets.
DeviceSong trackToDeviceSong(Track track) {
  return DeviceSong(
    id: int.tryParse(track.trackId) ?? 0,
    title: track.trackTitle,
    data: track.trackPath ?? '',
    albumId: int.tryParse(track.albumId),
    album: track.albumTitle,
    artist: track.trackArtist,
    uri: track.trackUri,
    duration: track.trackDuration.inMilliseconds,
    dateAdded: track.dateAdded,
    dateModified: track.trackModifiedLast,
    size: track.trackSize,
    track: track.trackNumber,
    hasLrc: track.hasLrc,
    lrcPath: track.lrcPath,
    artworkThumbnailPath: track.artworkThumbnailPath,
    artworkHqPath: track.artworkHqPath,
    replayGainDb: track.replayGainDb,
  );
}

/// Convert DeviceSong to Track.
Track deviceSongToTrack(DeviceSong song) {
  return Track(
    trackId: song.id.toString(),
    trackUri: song.uri.toString(),
    albumTitle: song.album.toString(),
    albumId: song.albumId.toString(),
    trackTitle: song.title,
    trackArtist: (song.artist?.isNotEmpty ?? false) ? song.artist! : 'Unknown Artist',
    trackDuration: Duration(milliseconds: song.duration ?? 0),
    dateAdded: song.dateAdded,
    trackPath: song.data,
    trackModifiedLast: song.dateModified,
    trackSize: song.size,
    trackNumber: song.track,
    hasLrc: song.hasLrc,
    lrcPath: song.lrcPath,
    artworkThumbnailPath: song.artworkThumbnailPath,
    artworkHqPath: song.artworkHqPath,
    replayGainDb: song.replayGainDb,
  );
}
