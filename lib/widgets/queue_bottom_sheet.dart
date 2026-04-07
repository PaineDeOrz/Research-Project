import 'dart:io';
import 'package:flutter/material.dart';
import 'package:musik_app/playback/playback_controller.dart';
import 'package:musik_app/models/track.dart';

import '../models/app_language.dart';

class QueueBottomSheet extends StatelessWidget {
  final PlaybackController playbackController;

  const QueueBottomSheet({
    super.key,
    required this.playbackController,
  });

  @override
  Widget build(BuildContext context) {
    final queue = playbackController.playbackQueue;
    final tracks = queue.tracks;
    final currentIndex = queue.currentIndex;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  AppLanguage.get('queue'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${tracks.length} ${AppLanguage.get('tracks')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final Track track = tracks[index];
                final bool isCurrent = index == currentIndex;
                final artworkPath = track.artworkThumbnailPath;
                final hasArtwork = artworkPath != null && artworkPath.isNotEmpty;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                        border: isCurrent
                            ? Border.all(color: colorScheme.primary, width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: hasArtwork
                            ? Image.file(
                                File(artworkPath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.music_note,
                                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                                ),
                              )
                            : Icon(
                                Icons.music_note,
                                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                              ),
                      ),
                    ),
                  ),
                  title: Text(
                    track.trackTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: isCurrent
                        ? TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          )
                        : null,
                  ),
                  subtitle: Text(
                    track.trackArtist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    await playbackController.playTrackAtIndex(index);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}