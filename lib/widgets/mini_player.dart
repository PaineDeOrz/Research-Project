import 'package:flutter/material.dart';
import 'package:musik_app/widgets/track_artwork.dart';
import '../models/track.dart';
import '../playback/playback_controller.dart';
import 'full_player_sheet.dart';

/// Small player overlay that remains visible at the bottom of the screen.
/// It uses a shared PlaybackController to stay in sync with the FullPlayer.
class MiniPlayer extends StatelessWidget {
  final PlaybackController controller;

  const MiniPlayer({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Listen to changes in the current track to rebuild the MiniPlayer UI
    return ValueListenableBuilder<Track?>(
      valueListenable: controller.currentTrackListenable,
      builder: (context, track, _) {
        // If no track is loaded, hide the MiniPlayer
        if (track == null) return const SizedBox.shrink();

        return Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          elevation: 8,
          child: InkWell(
            onTap: () => _openFullPlayer(context),
            child: SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Hero animation provides a smooth transition to the FullPlayer artwork
                        Hero(
                          tag: 'album_art_${track.trackId}',
                          child: _MiniPlayerArtwork(
                            track: track,
                            colorScheme: colorScheme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniPlayerTitleArea(
                            track: track,
                            colorScheme: colorScheme,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Only the Play/Pause button rebuilds when the playback state changes
                        ValueListenableBuilder<bool>(
                          valueListenable: controller.isPlayingListenable,
                          builder: (context, isPlaying, _) {
                            return IconButton(
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                              iconSize: 28,
                              onPressed: controller.togglePlay,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded),
                          iconSize: 28,
                          onPressed: controller.next,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Progress bar updates independently using a StreamBuilder for performance
                    _MiniPlayerProgressBar(controller: controller),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Opens the FullPlayerSheet using a general dialog with custom slide transition
  void _openFullPlayer(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha:0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const FullPlayerSheet();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

/// Helper widget to display the track title and artist
class _MiniPlayerTitleArea extends StatelessWidget {
  final Track track;
  final ColorScheme colorScheme;

  const _MiniPlayerTitleArea({
    required this.track,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          track.trackTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          track.trackArtist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha:0.7),
              ),
        ),
      ],
    );
  }
}

/// Linear progress indicator that reflects the current playback position
class _MiniPlayerProgressBar extends StatelessWidget {
  final PlaybackController controller;

  const _MiniPlayerProgressBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<Duration>(
      stream: controller.positionStream,
      initialData: Duration.zero,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = controller.duration;
        // Clamp duration to prevent division by zero errors
        final durationMs = duration.inMilliseconds.clamp(1, 2147483647);
        final progress = position.inMilliseconds / durationMs;

        return ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress.isNaN ? 0 : progress.clamp(0.0, 1.0),
            minHeight: 3,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(colorScheme.primary),
          ),
        );
      },
    );
  }
}

/// Compact artwork display for the MiniPlayer
class _MiniPlayerArtwork extends StatelessWidget {
  final Track track;
  final ColorScheme colorScheme;

  const _MiniPlayerArtwork({
    required this.track,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return TrackArtwork(
      track: track,
      size: 52,
      borderRadius: BorderRadius.circular(10),
      gradientColors: [
        colorScheme.primaryContainer,
        colorScheme.primary,
      ],
      boxShadow: [
        BoxShadow(
          color: colorScheme.primary.withValues(alpha:0.25),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      fallbackIcon: Icons.music_note,
      fallbackColor: Colors.white,
    );
  }
}