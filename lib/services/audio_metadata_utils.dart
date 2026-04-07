// -----------------------------------------------------------------------------
// AUDIO METADATA UTILITIES
// -----------------------------------------------------------------------------
//
// Shared utilities for audio metadata extraction. Handles ReplayGain tag parsing and Track to DeviceSong conversion for platform services.
//
// -----------------------------------------------------------------------------

import 'dart:io';
import 'dart:math' as math;

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:id3_codec/id3_codec.dart';
import 'package:musik_app/models/device_song.dart';
import 'package:musik_app/models/track.dart';

// -----------------------------------------------------------------------------
// ReplayGain Extraction
// -----------------------------------------------------------------------------

/// Extracts ReplayGain track gain from audio files.
/// Supports MP3 (ID3 TXXX), FLAC, and OGG (Vorbis comments).
Future<double?> extractReplayGain(File file) async {
  final path = file.path.toLowerCase();

  try {
    if (path.endsWith('.mp3')) {
      return await _extractMp3ReplayGain(file);
    } else if (path.endsWith('.flac') || path.endsWith('.ogg') || path.endsWith('.opus')) {
      return _extractVorbisReplayGain(file);
    }
  } catch (_) {
    // ReplayGain extraction is optional, fail silently
  }
  return null;
}

/// Extracts ReplayGain from MP3 files using ID3 TXXX frames.
Future<double?> _extractMp3ReplayGain(File file) async {
  final bytes = await file.readAsBytes();
  final decoder = ID3Decoder(bytes);
  final metadatas = decoder.decodeSync();

  for (final metadata in metadatas) {
    final tagMap = metadata.toTagMap();
    final result = _searchForReplayGain(tagMap);
    if (result != null) return result;
  }
  return null;
}

/// Extracts ReplayGain from FLAC/OGG/Opus files using Vorbis comments.
double? _extractVorbisReplayGain(File file) {
  final reader = file.openSync();
  try {
    final path = file.path.toLowerCase();
    dynamic tag;

    if (path.endsWith('.flac')) {
      tag = FlacParser(fetchImage: false).parse(reader);
    } else if (path.endsWith('.ogg') || path.endsWith('.opus')) {
      tag = OGGParser(fetchImage: false).parse(reader);
    }

    if (tag is VorbisMetadata) {
      final gains = tag.replayGainTrackGain;
      if (gains.isNotEmpty) {
        return _parseReplayGainValue(gains.first);
      }
    }
  } finally {
    reader.closeSync();
  }
  return null;
}

/// Recursively searches a tag map for ReplayGain values.
double? _searchForReplayGain(Map<String, dynamic> map) {
  for (final entry in map.entries) {
    final key = entry.key.toLowerCase();
    final value = entry.value;

    // Direct ReplayGain key match
    if (key.contains('replaygain_track_gain') || key.contains('rg_track_gain')) {
      if (value is String) return _parseReplayGainValue(value);
    }

    // Check TXXX frame content for Description/Value pairs
    if (key.contains('frame[txxx]') || key == 'content') {
      if (value is Map<String, dynamic>) {
        final description = value['Description']?.toString().toLowerCase() ?? '';
        if (description.contains('replaygain_track_gain') || description.contains('rg_track_gain')) {
          final gainValue = value['Value'];
          if (gainValue is String) return _parseReplayGainValue(gainValue);
        }
        final nested = _searchForReplayGain(value);
        if (nested != null) return nested;
      }
    }

    // Recurse into nested maps
    if (value is Map<String, dynamic>) {
      final nested = _searchForReplayGain(value);
      if (nested != null) return nested;
    }
  }
  return null;
}

/// Parses ReplayGain value from string like "-3.5 dB"
double? _parseReplayGainValue(String value) {
  final cleaned = value.replaceAll(RegExp(r'\s*dB\s*', caseSensitive: false), '').trim();
  return double.tryParse(cleaned);
}

/// Converts dB gain to volume multiplier, clamped to [0.25, 2.0].
double replayGainToVolume(double? gainDb) {
  if (gainDb == null) return 1.0;
  return math.pow(10, gainDb / 20).clamp(0.25, 2.0).toDouble();
}

// -----------------------------------------------------------------------------
// Model Conversion
// -----------------------------------------------------------------------------

/// Converts a Track from database to DeviceSong for interface compatibility.
DeviceSong trackToDeviceSong(Track track) {
  return DeviceSong(
    id: int.parse(track.trackId),
    albumId: int.parse(track.albumId),
    album: track.albumTitle,
    artist: track.trackArtist,
    title: track.trackTitle,
    uri: track.trackUri,
    data: track.trackPath ?? '',
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
