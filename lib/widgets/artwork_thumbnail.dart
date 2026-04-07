// -----------------------------------------------------------------------------
// ARTWORK THUMBNAIL
// -----------------------------------------------------------------------------
//
// Reusable artwork widget for list tiles.
// Shows an image from a file path with a colored placeholder and icon fallback on error or missing path.
//
// -----------------------------------------------------------------------------

import 'dart:io';

import 'package:flutter/material.dart';

class ArtworkThumbnail extends StatelessWidget {
  final String? artworkPath;
  final double size;
  final double borderRadius;
  final IconData placeholderIcon;

  const ArtworkThumbnail({
    super.key,
    required this.artworkPath,
    this.size = 52,
    this.borderRadius = 8,
    this.placeholderIcon = Icons.music_note,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasArtwork = artworkPath != null && artworkPath!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        child: hasArtwork
            ? Image.file(
                File(artworkPath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  placeholderIcon,
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              )
            : Icon(
                placeholderIcon,
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
              ),
      ),
    );
  }
}
