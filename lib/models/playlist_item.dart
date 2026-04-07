import 'package:flutter/foundation.dart';

@immutable
class PlaylistItem {
  final String playlistUUID;
  final String trackId;

  final int positionInPlaylist;
  final int addedAt;

  const PlaylistItem({
    required this.playlistUUID,
    required this.trackId,
    required this.positionInPlaylist,
    required this.addedAt,
  });
}