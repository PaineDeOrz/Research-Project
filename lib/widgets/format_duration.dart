// -----------------------------------------------------------------------------
// FORMAT DURATION
// -----------------------------------------------------------------------------
//
// Formats a Duration as "M:SS" for display in track lists.
//
// -----------------------------------------------------------------------------

String formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
