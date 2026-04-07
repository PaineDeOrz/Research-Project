import 'dart:io';
import 'package:flutter/material.dart';
import '../models/track.dart';

/// Displays album artwork for a [Track].
/// Uses cached artwork from database and falls back to an icon if no artwork is available.
class TrackArtwork extends StatelessWidget {
  /// Track for which the artwork should be shown.
  final Track track;
  /// Width and height of the artwork container.
  final double size;
  /// Border radius applied to the artwork container and clip.
  final BorderRadius borderRadius;
  /// Background gradient colors behind the artwork.
  final List<Color> gradientColors;
  /// Box shadow applied to the artwork container.
  final List<BoxShadow> boxShadow;
  /// Icon shown when no artwork is available.
  final IconData fallbackIcon;
  /// Color used for the fallback icon.
  final Color? fallbackColor;

  const TrackArtwork({
    super.key,
    required this.track,
    required this.size,
    required this.borderRadius,
    required this.gradientColors,
    required this.boxShadow,
    this.fallbackIcon = Icons.music_note_rounded,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      fallbackIcon,
      color: fallbackColor ?? Theme.of(context).colorScheme.onPrimary,
      size: size * 0.45,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(colors: gradientColors),
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: _buildArtwork(track, fallback),
      ),
    );
  }

  /// Builds the artwork widget for [track] or [fallback] if needed.
  Widget _buildArtwork(Track track, Widget fallback) {
    // Prefer HQ artwork for full player, fall back to thumbnail
    final artworkPath = track.artworkHqPath ?? track.artworkThumbnailPath;

    if (artworkPath == null || artworkPath.isEmpty) {
      return fallback;
    }

    return Image.file(
      File(artworkPath),
      key: ValueKey<String>(artworkPath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}