import 'package:flutter/foundation.dart';

@immutable
class Album {
  final String albumId;
  final String albumTitle;
  final String albumArtist;
  final int? year;
  final String? artworkThumbnailPath;
  final String? artworkHqPath;
  final int? dateAdded;

  const Album({
    required this.albumId,
    required this.albumTitle,
    required this.albumArtist,
    this.year,
    this.artworkThumbnailPath,
    this.artworkHqPath,
    this.dateAdded,
  });
}