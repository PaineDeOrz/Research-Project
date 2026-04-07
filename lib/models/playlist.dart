import 'package:flutter/foundation.dart';

@immutable
class Playlist {
  final String playlistId;
  final String playlistName;
  final bool isGenerated;
  final int createdAt;
  final int updatedAt;

  const Playlist({
    required this.playlistId,
    required this.playlistName,
    required this.isGenerated,
    required this.createdAt,
    required this.updatedAt,
  });
}