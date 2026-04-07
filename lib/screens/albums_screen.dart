// -----------------------------------------------------------------------------
// ALBUMS SCREEN
// -----------------------------------------------------------------------------
//
// Lists all albums from the library as a scrollable list.
// Each row shows album artwork, title, artist, and track count.
// Tapping navigates to the album detail screen.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../data/repositories/library_repository.dart';
import '../models/album.dart';
import '../models/app_language.dart';
import '../playback/playback_controller.dart';
import '../widgets/artwork_thumbnail.dart';
import 'album_tracks_screen.dart';

class AlbumsScreen extends StatefulWidget {
  final PlaybackController playbackController;

  const AlbumsScreen({super.key, required this.playbackController});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  final LibraryRepository _libraryRepo = LibraryRepository();

  List<_AlbumWithMeta> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  Future<void> _loadAlbums() async {
    setState(() => _isLoading = true);

    // Batch load: 3 queries total instead of N+1
    final albums = await _libraryRepo.getAllAlbums();
    final trackCounts = await _libraryRepo.getAllAlbumTrackCounts();
    final firstTrackArtwork = await _libraryRepo.getAllAlbumFirstTrackArtwork();

    final albumsWithMeta = albums.map((album) {
      // Use album artwork, fall back to first track artwork
      final artworkPath = (album.artworkThumbnailPath?.isNotEmpty == true)
          ? album.artworkThumbnailPath
          : firstTrackArtwork[album.albumId];

      return _AlbumWithMeta(
        album: album,
        trackCount: trackCounts[album.albumId] ?? 0,
        artworkPath: artworkPath,
      );
    }).toList();

    setState(() {
      _albums = albumsWithMeta;
      _isLoading = false;
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLanguage.get('Albums'))),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_albums.isEmpty) {
      return Center(
        child: Text(
          AppLanguage.get('No albums found'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAlbums,
      child: ListView.builder(
        itemCount: _albums.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final item = _albums[index];
          return _AlbumListTile(
            album: item.album,
            trackCount: item.trackCount,
            artworkPath: item.artworkPath,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlbumTracksScreen(
                    album: item.album,
                    playbackController: widget.playbackController,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// View model
// ---------------------------------------------------------------------------

class _AlbumWithMeta {
  final Album album;
  final int trackCount;
  final String? artworkPath;

  _AlbumWithMeta({
    required this.album,
    required this.trackCount,
    required this.artworkPath,
  });
}

// ---------------------------------------------------------------------------
// Album list tile
// ---------------------------------------------------------------------------

class _AlbumListTile extends StatelessWidget {
  final Album album;
  final int trackCount;
  final String? artworkPath;
  final VoidCallback onTap;

  const _AlbumListTile({
    required this.album,
    required this.trackCount,
    required this.artworkPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ArtworkThumbnail(
        artworkPath: artworkPath,
        placeholderIcon: Icons.album,
      ),
      title: Text(
        album.albumTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        album.albumArtist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '$trackCount ${AppLanguage.get('Tracks')}',
        style: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 13,
        ),
      ),
      onTap: onTap,
    );
  }
}

