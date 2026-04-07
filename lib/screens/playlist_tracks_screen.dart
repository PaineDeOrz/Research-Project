// -----------------------------------------------------------------------------
// PLAYLIST TRACKS SCREEN
// -----------------------------------------------------------------------------
//
// Shows all tracks in a playlist with a collapsible header featuring artwork, playlist name, track count, and play/shuffle buttons.
// rename and delete via the overflow menu.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../data/repositories/playlists_repository.dart';
import '../models/app_language.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../playback/playback_controller.dart';
import '../widgets/artwork_thumbnail.dart';
import '../widgets/detail_header.dart';
import '../widgets/format_duration.dart';
import '../widgets/player_dialog.dart';
import '../widgets/playlist_track_options_bottom_sheet.dart';
import '../widgets/styled_bottom_sheet.dart';

class PlaylistTracksScreen extends StatefulWidget {
  final Playlist playlist;
  final PlaybackController playbackController;

  const PlaylistTracksScreen({
    super.key,
    required this.playlist,
    required this.playbackController,
  });

  @override
  State<PlaylistTracksScreen> createState() => _PlaylistTracksScreenState();
}

class _PlaylistTracksScreenState extends State<PlaylistTracksScreen> {
  final PlaylistsRepository _playlistsRepo = GetIt.I<PlaylistsRepository>();

  List<Track> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);
    final tracks = await _playlistsRepo.getPlaylistTracks(
      widget.playlist.playlistId,
    );
    setState(() {
      _tracks = tracks;
      _isLoading = false;
    });
  }

  String get _displayName => widget.playlist.isGenerated
      ? AppLanguage.getGeneratedPlaylistName(widget.playlist.playlistName)
      : widget.playlist.playlistName;

  String? get _headerArtworkPath {
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
              slivers: [
                _buildSliverAppBar(context),
                _buildTrackList(),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sliver app bar
  // ---------------------------------------------------------------------------

  Widget _buildSliverAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final artworkPath = _headerArtworkPath;
    final hasArtwork = artworkPath != null && artworkPath.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      stretch: true,
      actions: [
        if (!widget.playlist.isGenerated)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'rename') _showRenameDialog(context);
              if (value == 'delete') _showDeleteDialog(context);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    const Icon(Icons.edit),
                    const SizedBox(width: 12),
                    Text(AppLanguage.get('Rename Playlist')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: colorScheme.error),
                    const SizedBox(width: 12),
                    Text(
                      AppLanguage.get('Delete Playlist'),
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
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
                  title: _displayName,
                  subtitle: '${_tracks.length} ${AppLanguage.get('Tracks')}',
                  artworkPath: artworkPath,
                  placeholderIcon: Icons.queue_music,
                ),
              ),
            ),
            background: ExpandedDetailHeader(
              artworkPath: artworkPath,
              hasArtwork: hasArtwork,
              title: _displayName,
              subtitle: '${_tracks.length} ${AppLanguage.get('Tracks')}',
              placeholderIcon: Icons.queue_music,
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
        child: Center(child: Text(AppLanguage.get('Playlist is empty'))),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _PlaylistTrackTile(
          track: _tracks[index],
          onTap: () => _onTrackTap(index),
          onLongPress: () => _onTrackLongPress(_tracks[index]),
        ),
        childCount: _tracks.length,
      ),
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
      builder: (context) => PlaylistTrackOptionsBottomSheet(
        track: track,
        playlist: widget.playlist,
        playbackController: widget.playbackController,
        onTrackRemoved: _loadTracks,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(
      text: _displayName,
    );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(AppLanguage.get('Rename Playlist')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: AppLanguage.get('Playlist name'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLanguage.get('Cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              await _playlistsRepo.renamePlaylist(
                widget.playlist.playlistId,
                newName,
              );
              if (!context.mounted) return;
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(AppLanguage.get('Save')),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(AppLanguage.get('Delete this Playlist')),
        content: Text(
          AppLanguage.get('Are you sure you want to delete this playlist?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLanguage.get("No, don't delete")),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () async {
              await _playlistsRepo.deletePlaylist(widget.playlist.playlistId);
              if (!context.mounted) return;
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(AppLanguage.get('Yes, delete')),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Playlist track tile
// ---------------------------------------------------------------------------

class _PlaylistTrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PlaylistTrackTile({
    required this.track,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ArtworkThumbnail(artworkPath: track.artworkThumbnailPath),
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
