// -----------------------------------------------------------------------------
// DETAIL HEADER
// -----------------------------------------------------------------------------
//
// Shared collapsible header widgets used by album, artist, and playlist detail screens.
//
// -----------------------------------------------------------------------------

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/app_language.dart';

// ---------------------------------------------------------------------------
// Collapsed title (shown when scrolled up)
// ---------------------------------------------------------------------------

class CollapsedDetailTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? artworkPath;
  final IconData placeholderIcon;

  const CollapsedDetailTitle({
    super.key,
    required this.title,
    required this.subtitle,
    required this.artworkPath,
    required this.placeholderIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasArtwork = artworkPath != null && artworkPath!.isNotEmpty;

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 32,
            height: 32,
            color: colorScheme.primaryContainer,
            child: hasArtwork
                ? Image.file(
                    File(artworkPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      placeholderIcon,
                      size: 16,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  )
                : Icon(
                    placeholderIcon,
                    size: 16,
                    color: colorScheme.onPrimaryContainer,
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Expanded header (background of sliver app bar)
// ---------------------------------------------------------------------------

class ExpandedDetailHeader extends StatelessWidget {
  final String? artworkPath;
  final bool hasArtwork;
  final String title;
  final String subtitle;
  final IconData placeholderIcon;
  final VoidCallback? onPlay;
  final VoidCallback? onShuffle;

  const ExpandedDetailHeader({
    super.key,
    required this.artworkPath,
    required this.hasArtwork,
    required this.title,
    required this.subtitle,
    required this.placeholderIcon,
    required this.onPlay,
    required this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred background
        IgnorePointer(
          child: hasArtwork
              ? ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Image.file(
                    File(artworkPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: colorScheme.primaryContainer),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [colorScheme.primaryContainer, colorScheme.surface],
                    ),
                  ),
                ),
        ),

        // Gradient overlay for readability
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ),

        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DetailHeaderArtwork(
                  artworkPath: artworkPath,
                  hasArtwork: hasArtwork,
                  placeholderIcon: placeholderIcon,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DetailActionButton(
                      icon: Icons.play_arrow_rounded,
                      label: AppLanguage.get('Play'),
                      onTap: onPlay,
                      isPrimary: true,
                    ),
                    const SizedBox(width: 12),
                    DetailActionButton(
                      icon: Icons.shuffle_rounded,
                      label: AppLanguage.get('Shuffle'),
                      onTap: onShuffle,
                      isPrimary: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header artwork (120x120 centered image with shadow)
// ---------------------------------------------------------------------------

class DetailHeaderArtwork extends StatelessWidget {
  final String? artworkPath;
  final bool hasArtwork;
  final IconData placeholderIcon;

  const DetailHeaderArtwork({
    super.key,
    required this.artworkPath,
    required this.hasArtwork,
    required this.placeholderIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: hasArtwork
            ? Image.file(
                File(artworkPath!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(colorScheme),
              )
            : _buildPlaceholder(colorScheme),
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primaryContainer,
      child: Icon(
        placeholderIcon,
        size: 64,
        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action button (Play / Shuffle pill)
// ---------------------------------------------------------------------------

class DetailActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;

  const DetailActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = isPrimary
        ? colorScheme.primary
        : Colors.white.withValues(alpha: 0.2);
    final foreground = isPrimary ? colorScheme.onPrimary : Colors.white;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Collapsed artist title (shown when scrolled up): circular thumbnail
// ---------------------------------------------------------------------------

class CollapsedArtistDetailTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? artworkPath;

  const CollapsedArtistDetailTitle({
    super.key,
    required this.title,
    required this.subtitle,
    required this.artworkPath,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasArtwork = artworkPath != null && artworkPath!.isNotEmpty;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primaryContainer,
          ),
          child: ClipOval(
            child: hasArtwork
                ? Image.file(
                    File(artworkPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person,
                      size: 16,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 16,
                    color: colorScheme.onPrimaryContainer,
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Expanded artist header (circular image, bio, action buttons)
// ---------------------------------------------------------------------------

class ExpandedArtistDetailHeader extends StatelessWidget {
  final String? artworkPath;
  final bool hasArtwork;
  final String title;
  final String subtitle;
  final String? bio;
  final VoidCallback? onPlay;
  final VoidCallback? onShuffle;
  final VoidCallback? onFetchInfo;
  final bool isFetching;

  const ExpandedArtistDetailHeader({
    super.key,
    required this.artworkPath,
    required this.hasArtwork,
    required this.title,
    required this.subtitle,
    this.bio,
    required this.onPlay,
    required this.onShuffle,
    this.onFetchInfo,
    this.isFetching = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred background
        IgnorePointer(
          child: hasArtwork
              ? ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: Image.file(
                    File(artworkPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: colorScheme.primaryContainer),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [colorScheme.primaryContainer, colorScheme.surface],
                    ),
                  ),
                ),
        ),

        // Gradient overlay for readability
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
        ),

        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Circular artist image
                ArtistDetailHeaderArtwork(
                  artworkPath: artworkPath,
                  hasArtwork: hasArtwork,
                  isFetching: isFetching,
                  onFetchInfo: onFetchInfo,
                ),
                const SizedBox(height: 12),

                // Artist name
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),

                // Subtitle (album/track count)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),

                // Bio text (if available) - flexible to avoid overflow
                if (bio != null && bio!.isNotEmpty)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        bio!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Play / Shuffle buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DetailActionButton(
                      icon: Icons.play_arrow_rounded,
                      label: AppLanguage.get('Play'),
                      onTap: onPlay,
                      isPrimary: true,
                    ),
                    const SizedBox(width: 12),
                    DetailActionButton(
                      icon: Icons.shuffle_rounded,
                      label: AppLanguage.get('Shuffle'),
                      onTap: onShuffle,
                      isPrimary: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Artist header artwork (140x140 circular image with shadow)
// ---------------------------------------------------------------------------

class ArtistDetailHeaderArtwork extends StatelessWidget {
  final String? artworkPath;
  final bool hasArtwork;
  final bool isFetching;
  final VoidCallback? onFetchInfo;

  const ArtistDetailHeaderArtwork({
    super.key,
    required this.artworkPath,
    required this.hasArtwork,
    this.isFetching = false,
    this.onFetchInfo,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: !hasArtwork && onFetchInfo != null && !isFetching
          ? onFetchInfo
          : null,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipOval(
          child: hasArtwork
              ? Image.file(
                  File(artworkPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholder(colorScheme),
                )
              : _buildPlaceholder(colorScheme),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primaryContainer,
      child: isFetching
          ? Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.6),
                ),
              ),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.person,
                  size: 64,
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
                ),
                if (onFetchInfo != null)
                  Positioned(
                    bottom: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_download_outlined,
                            size: 12,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLanguage.get('Tap to fetch'),
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
