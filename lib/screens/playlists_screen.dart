// -----------------------------------------------------------------------------
// PLAYLISTS SCREEN
// -----------------------------------------------------------------------------
//
// Shows all user playlists with artwork, create button, and inline play.
// Tapping a playlist navigates to its tracks screen.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../data/repositories/playlists_repository.dart';
import '../models/app_language.dart';
import '../models/playlist.dart';
import '../playback/playback_controller.dart';
import '../widgets/artwork_thumbnail.dart';
import 'playlist_tracks_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  final PlaybackController playbackController;

  const PlaylistsScreen({super.key, required this.playbackController});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final PlaylistsRepository _playlistsRepo = GetIt.I<PlaylistsRepository>();

  List<_PlaylistWithMeta> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  Future<void> _loadPlaylists() async {
    setState(() => _isLoading = true);

    // Batch load: 3 queries instead of N+1
    final playlists = await _playlistsRepo.getUserPlaylists();
    final trackCounts = await _playlistsRepo.getAllPlaylistTrackCounts();
    final firstTrackArtwork = await _playlistsRepo.getAllPlaylistFirstTrackArtwork();

    final playlistsWithMeta = playlists.map((playlist) {
      return _PlaylistWithMeta(
        playlist: playlist,
        artworkPath: firstTrackArtwork[playlist.playlistId],
        trackCount: trackCounts[playlist.playlistId] ?? 0,
      );
    }).toList();

    setState(() {
      _playlists = playlistsWithMeta;
      _isLoading = false;
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLanguage.get('Playlists')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: AppLanguage.get('Create Playlist'),
            onPressed: () => _showCreatePlaylistDialog(context),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLanguage.get('No playlists yet'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showCreatePlaylistDialog(context),
              icon: const Icon(Icons.add),
              label: Text(AppLanguage.get('Create Playlist')),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPlaylists,
      child: ListView.builder(
        itemCount: _playlists.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final item = _playlists[index];
          return _PlaylistListTile(
            item: item,
            onPlay: () async {
              if (item.trackCount > 0) {
                final tracks = await _playlistsRepo.getPlaylistTracks(item.playlist.playlistId);
                if (tracks.isNotEmpty) {
                  await widget.playbackController.playQueue(
                    tracks,
                    startIndex: 0,
                    autoPlay: true,
                  );
                }
              }
            },
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaylistTracksScreen(
                    playlist: item.playlist,
                    playbackController: widget.playbackController,
                  ),
                ),
              ).then((_) => _loadPlaylists());
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Create playlist dialog
  // ---------------------------------------------------------------------------

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLanguage.get('Create Playlist')),
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
                final name = controller.text.trim();
                if (name.isEmpty) return;

                await _playlistsRepo.createPlaylist(name);
                if (!context.mounted) return;
                Navigator.pop(context);
                _loadPlaylists();
              },
              child: Text(AppLanguage.get('Save')),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// View model
// ---------------------------------------------------------------------------

class _PlaylistWithMeta {
  final Playlist playlist;
  final String? artworkPath;
  final int trackCount;

  _PlaylistWithMeta({
    required this.playlist,
    required this.artworkPath,
    required this.trackCount,
  });
}

// ---------------------------------------------------------------------------
// Playlist list tile
// ---------------------------------------------------------------------------

class _PlaylistListTile extends StatelessWidget {
  final _PlaylistWithMeta item;
  final VoidCallback onPlay;
  final VoidCallback onTap;

  const _PlaylistListTile({
    required this.item,
    required this.onPlay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ArtworkThumbnail(
        artworkPath: item.artworkPath,
        placeholderIcon: Icons.queue_music,
      ),
      title: Text(
        item.playlist.playlistName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.play_circle_outline),
        onPressed: onPlay,
      ),
      onTap: onTap,
    );
  }
}

