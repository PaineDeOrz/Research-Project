// -----------------------------------------------------------------------------
// ALBUM TRACKS SCREEN
// -----------------------------------------------------------------------------
//
// Shows all tracks in an album with a collapsible header containing artwork, title, artist, and play/shuffle buttons.
// Track rows display track number on the left instead of artwork thumbnails.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../data/repositories/library_repository.dart';
import '../models/album.dart';
import '../models/app_language.dart';
import '../models/mappers/song_track_mapper.dart';
import '../models/track.dart';
import '../playback/playback_controller.dart';
import '../widgets/detail_header.dart';
import '../widgets/format_duration.dart';
import '../widgets/player_dialog.dart';
import '../widgets/song_options_bottom_sheet.dart';
import '../widgets/styled_bottom_sheet.dart';

class AlbumTracksScreen extends StatefulWidget {
  final Album album;
  final PlaybackController playbackController;

  const AlbumTracksScreen({
    super.key,
    required this.album,
    required this.playbackController,
  });

  @override
  State<AlbumTracksScreen> createState() => _AlbumTracksScreenState();
}

class _AlbumTracksScreenState extends State<AlbumTracksScreen> {
  final LibraryRepository _libraryRepo = LibraryRepository();

  List<Track> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);
    final tracks = await _libraryRepo.getTracksForAlbum(widget.album.albumId);
    setState(() {
      _tracks = tracks;
      _isLoading = false;
    });
  }

  // Resolve album artwork, falling back to first track artwork
  String? get _headerArtworkPath {
    final albumArt = widget.album.artworkThumbnailPath;
    if (albumArt != null && albumArt.isNotEmpty) return albumArt;
    if (_tracks.isEmpty) return null;
    return _tracks.first.artworkThumbnailPath;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [_buildSliverAppBar(context), _buildTrackList()],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sliver app bar
  // ---------------------------------------------------------------------------

  Widget _buildSliverAppBar(BuildContext context) {
    final artworkPath = _headerArtworkPath;
    final hasArtwork = artworkPath != null && artworkPath.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      stretch: true,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final expandedHeight = 340.0;
          final collapsedHeight =
              kToolbarHeight + MediaQuery.of(context).padding.top;
          final currentHeight = constraints.maxHeight;
          final expandRatio =
              ((currentHeight - collapsedHeight) /
                      (expandedHeight - collapsedHeight))
                  .clamp(0.0, 1.0);
          final isCollapsed = expandRatio < 0.3;

          return FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(
              left: 56,
              bottom: 12,
              right: 48,
            ),
            title: IgnorePointer(
              ignoring: !isCollapsed,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: isCollapsed ? 1.0 : 0.0,
                child: CollapsedDetailTitle(
                  title: widget.album.albumTitle,
                  subtitle: widget.album.albumArtist,
                  artworkPath: artworkPath,
                  placeholderIcon: Icons.album,
                ),
              ),
            ),
            background: ExpandedDetailHeader(
              artworkPath: artworkPath,
              hasArtwork: hasArtwork,
              title: widget.album.albumTitle,
              subtitle:
                  '${widget.album.albumArtist}  •  ${_tracks.length} ${AppLanguage.get('Tracks')}',
              placeholderIcon: Icons.album,
              onPlay: _tracks.isEmpty ? null : _playAll,
              onShuffle: _tracks.isEmpty ? null : _shuffleAll,
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Track list
  // ---------------------------------------------------------------------------

  Widget _buildTrackList() {
    if (_tracks.isEmpty) {
      return SliverFillRemaining(
        child: Center(child: Text(AppLanguage.get('No tracks'))),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final track = _tracks[index];
        // Android MediaStore encodes disc number in the thousands place
        // (e.g. disc 1 track 2 = 1002), so strip it with % 1000
        final displayNumber = track.trackNumber != null
            ? track.trackNumber! % 1000
            : index + 1;

        return _AlbumTrackTile(
          track: track,
          displayNumber: displayNumber,
          onTap: () => _onTrackTap(index),
          onLongPress: () => _onTrackLongPress(track),
        );
      }, childCount: _tracks.length),
    );
  }

  // ---------------------------------------------------------------------------
  // Interactions
  // ---------------------------------------------------------------------------

  void _playAll() {
    widget.playbackController.playQueue(_tracks, startIndex: 0, autoPlay: true);
  }

  void _shuffleAll() {
    final shuffled = List<Track>.from(_tracks)..shuffle();
    widget.playbackController.playQueue(
      shuffled,
      startIndex: 0,
      autoPlay: true,
    );
  }

  void _onTrackTap(int index) {
    widget.playbackController.playQueue(
      _tracks,
      startIndex: index,
      autoPlay: true,
    );
    showFullPlayerDialog(context);
  }

  void _onTrackLongPress(Track track) {
    showStyledBottomSheet(
      context: context,
      builder: (context) => SongOptionsBottomSheet(
        song: trackToDeviceSong(track),
        playbackController: widget.playbackController,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Album track tile
// ---------------------------------------------------------------------------

class _AlbumTrackTile extends StatelessWidget {
  final Track track;
  final int displayNumber;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AlbumTrackTile({
    required this.track,
    required this.displayNumber,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SizedBox(
        width: 36,
        child: Center(
          child: Text(
            '$displayNumber',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
      title: Text(
        track.trackTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.trackArtist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        formatDuration(track.trackDuration),
        style: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 13,
        ),
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
