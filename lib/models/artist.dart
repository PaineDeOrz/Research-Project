// -----------------------------------------------------------------------------
// ARTIST MODEL
// -----------------------------------------------------------------------------
//
// Immutable model for cached artist metadata from MusicBrainz/Wikidata.
//
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

@immutable
class Artist {
  final String artistName;
  final String? mbid;
  final String? wikidataId;
  final String? imagePath;
  final String? imageThumbnailPath;
  final String? bio;
  final int? fetchedAtMs;

  const Artist({
    required this.artistName,
    this.mbid,
    this.wikidataId,
    this.imagePath,
    this.imageThumbnailPath,
    this.bio,
    this.fetchedAtMs,
  });

  Artist copyWith({
    String? artistName,
    String? mbid,
    String? wikidataId,
    String? imagePath,
    String? imageThumbnailPath,
    String? bio,
    int? fetchedAtMs,
  }) {
    return Artist(
      artistName: artistName ?? this.artistName,
      mbid: mbid ?? this.mbid,
      wikidataId: wikidataId ?? this.wikidataId,
      imagePath: imagePath ?? this.imagePath,
      imageThumbnailPath: imageThumbnailPath ?? this.imageThumbnailPath,
      bio: bio ?? this.bio,
      fetchedAtMs: fetchedAtMs ?? this.fetchedAtMs,
    );
  }

  Map<String, Object?> toMap() => {
    'artist_name': artistName,
    'mbid': mbid,
    'wikidata_id': wikidataId,
    'image_path': imagePath,
    'image_thumbnail_path': imageThumbnailPath,
    'bio': bio,
    'fetched_at_ms': fetchedAtMs,
  };

  factory Artist.fromMap(Map<String, Object?> map) => Artist(
    artistName: map['artist_name'] as String,
    mbid: map['mbid'] as String?,
    wikidataId: map['wikidata_id'] as String?,
    imagePath: map['image_path'] as String?,
    imageThumbnailPath: map['image_thumbnail_path'] as String?,
    bio: map['bio'] as String?,
    fetchedAtMs: map['fetched_at_ms'] as int?,
  );
}
