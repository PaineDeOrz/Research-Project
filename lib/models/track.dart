// -----------------------------------------------------------------------------
// TRACK MODEL
// -----------------------------------------------------------------------------
//
// Immutable representation of a track stored in SQLite. Used throughout the UI.
//
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

@immutable
class Track {
  final String trackId;

  /// Content URI from device media library
  final String trackUri;

  final String trackTitle;
  final String albumTitle;
  final String albumId;
  final String trackArtist;
  final Duration trackDuration;

  /// Absolute file system path for playback
  final String? trackPath;

  final int? year;

  final String? artworkThumbnailPath;
  final String? artworkHqPath;
  final String? artworkUrl;

  final int? dateAdded;
  final int? trackModifiedLast;
  final int? trackSize;
  final int? trackNumber;

  /// Whether an LRC lyrics file exists for this track
  final bool hasLrc;

  /// Full path to the LRC file if it exists
  final String? lrcPath;

  /// ReplayGain value in decibels for volume normalization.
  /// Positive values boost quiet tracks, negative values reduce loud tracks.
  /// Null means no ReplayGain tag was found in the file.
  final double? replayGainDb;

  /// Whether this track's metadata is managed by the device sync.
  /// When false, the user has edited metadata and sync will not overwrite it.
  final bool isMetadataManaged;

  const Track({
    required this.trackId,
    required this.trackUri,
    required this.trackTitle,
    required this.albumTitle,
    required this.albumId,
    required this.trackArtist,
    required this.trackDuration,
    this.trackPath,
    this.year,
    this.artworkThumbnailPath,
    this.artworkHqPath,
    this.artworkUrl,
    this.dateAdded,
    this.trackModifiedLast,
    this.trackSize,
    this.trackNumber,
    this.hasLrc = false,
    this.lrcPath,
    this.replayGainDb,
    this.isMetadataManaged = true,
  });
}