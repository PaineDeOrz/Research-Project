class ListeningHistoryEntry {
  ListeningHistoryEntry({
    required this.eventId,
    required this.trackId,
    required this.startedAtMs,
    required this.totalListenedMs,
    required this.trackTitle,
    required this.trackArtist,
    required this.artworkThumbPath,
  });

  final int eventId;
  final String trackId;
  final int startedAtMs;
  final int totalListenedMs;
  final String trackTitle;
  final String trackArtist;
  final String? artworkThumbPath;
}