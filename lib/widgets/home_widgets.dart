// -----------------------------------------------------------------------------
// HOME WIDGETS
// -----------------------------------------------------------------------------
//
// Reusable widgets for the home screen.
// Includes section headers, horizontal scrolling rows, and squircle cards for tracks and playlists.
//
// -----------------------------------------------------------------------------

import 'dart:io';

import 'package:flutter/material.dart';

import '../models/app_language.dart';
import '../models/playlist.dart';
import '../models/track.dart';

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class HomeSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const HomeSectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                AppLanguage.get('seeAll'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Horizontal scroll row (lazy loading)
// ---------------------------------------------------------------------------

class HomeHorizontalRow<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final double itemWidth;
  final double spacing;

  const HomeHorizontalRow({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.itemWidth = 120,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemWidth + 48, // Card height + text below
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: index < items.length - 1 ? spacing : 0),
            child: itemBuilder(items[index]),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Track card (squircle with artwork, title, artist)
// ---------------------------------------------------------------------------

class HomeTrackCard extends StatelessWidget {
  final Track track;
  final double size;
  final VoidCallback? onTap;

  const HomeTrackCard({
    super.key,
    required this.track,
    this.size = 120,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasArtwork = track.artworkThumbnailPath != null &&
        track.artworkThumbnailPath!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork squircle
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: size,
                height: size,
                color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                child: hasArtwork
                    ? Image.file(
                        File(track.artworkThumbnailPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(colorScheme),
                      )
                    : _buildPlaceholder(colorScheme),
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              track.trackTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            // Artist
            Text(
              track.trackArtist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Center(
      child: Icon(
        Icons.music_note,
        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
        size: size * 0.4,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Playlist card (squircle with gradient/artwork, title, track count)
// ---------------------------------------------------------------------------

class HomePlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final String? artworkPath;
  final String? displayName;
  final int trackCount;
  final double size;
  final List<Color>? gradientColors;
  final IconData icon;
  final VoidCallback? onTap;

  const HomePlaylistCard({
    super.key,
    required this.playlist,
    this.artworkPath,
    this.displayName,
    this.trackCount = 0,
    this.size = 120,
    this.gradientColors,
    this.icon = Icons.playlist_play,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasArtwork = artworkPath != null && artworkPath!.isNotEmpty;
    final colors = gradientColors ?? [colorScheme.primary, colorScheme.tertiary];

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork/gradient squircle
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: size,
                height: size,
                decoration: hasArtwork
                    ? null
                    : BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: colors,
                        ),
                      ),
                child: hasArtwork
                    ? Image.file(
                        File(artworkPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildGradientPlaceholder(colors),
                      )
                    : _buildGradientPlaceholder(colors),
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              displayName ?? playlist.playlistName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            // Track count
            Text(
              '$trackCount ${AppLanguage.get('tracks')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientPlaceholder(List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.9),
          size: size * 0.4,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Genre mix card (squircle with gradient, genre name, track count)
// ---------------------------------------------------------------------------

class HomeGenreMixCard extends StatelessWidget {
  final String genreName;
  final int trackCount;
  final double size;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const HomeGenreMixCard({
    super.key,
    required this.genreName,
    required this.trackCount,
    this.size = 120,
    required this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.music_note,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: size * 0.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              genreName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            Text(
              '$trackCount ${AppLanguage.get('tracks')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Large feature card (for highlighting a playlist/mix)
// ---------------------------------------------------------------------------

class HomeFeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? artworkPath;
  final List<Color> gradientColors;
  final IconData icon;
  final VoidCallback? onTap;

  const HomeFeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.artworkPath,
    required this.gradientColors,
    this.icon = Icons.play_circle_filled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasArtwork = artworkPath != null && artworkPath!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: hasArtwork
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
          image: hasArtwork
              ? DecorationImage(
                  image: FileImage(File(artworkPath!)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            // Gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Play icon
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: gradientColors.first,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
