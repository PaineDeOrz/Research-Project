// -----------------------------------------------------------------------------
// ARTISTS SCREEN
// -----------------------------------------------------------------------------
//
// Lists all artists from the library. Each row shows the artist name and album count.
// Tapping navigates to the artist's albums.
//
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../data/repositories/library_repository.dart';
import '../data/repositories/artist_metadata_repository.dart';
import '../models/app_language.dart';
import '../models/artist.dart';
import '../playback/playback_controller.dart';
import 'artist_albums_screen.dart';

class ArtistsScreen extends StatefulWidget {
  final PlaybackController playbackController;

  const ArtistsScreen({super.key, required this.playbackController});

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  final LibraryRepository _libraryRepo = LibraryRepository();

  List<_ArtistWithMeta> _artists = [];
  Map<String, Artist> _cachedArtists = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  @override
  void dispose() {
    // Cancel batch fetch when leaving the screen
    if (GetIt.I.isRegistered<ArtistMetadataRepository>()) {
      GetIt.I<ArtistMetadataRepository>().cancelBatchFetch();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  Future<void> _loadArtists() async {
    setState(() => _isLoading = true);

    // Batch load: 2 queries instead of N+1
    final artists = await _libraryRepo.getAllArtists();
    final albumCounts = await _libraryRepo.getAllArtistAlbumCounts();

    // Load cached artist metadata (read-only, safe for initState)
    Map<String, Artist> cachedMap = {};
    if (GetIt.I.isRegistered<ArtistMetadataRepository>()) {
      final repo = GetIt.I<ArtistMetadataRepository>();
      cachedMap = await repo.getAllCachedArtistsMap();
    }

    final artistsWithMeta = artists.map((name) {
      return _ArtistWithMeta(
        name: name,
        albumCount: albumCounts[name] ?? 0,
      );
    }).toList();

    setState(() {
      _artists = artistsWithMeta;
      _cachedArtists = cachedMap;
      _isLoading = false;
    });

    // Start background fetch for missing artists
    _fetchMissingArtists(artists);
  }

  void _fetchMissingArtists(List<String> artistNames) {
    if (!GetIt.I.isRegistered<ArtistMetadataRepository>()) return;
    final repo = GetIt.I<ArtistMetadataRepository>();

    repo.fetchMissingArtists(
      artistNames,
      onProgress: (artistName, result) {
        if (!mounted) return;
        if (result != null) {
          setState(() {
            _cachedArtists[artistName] = result;
          });
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLanguage.get('Artists'))),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_artists.isEmpty) {
      return Center(
        child: Text(
          AppLanguage.get('No artists found'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadArtists,
      child: ListView.builder(
        itemCount: _artists.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final item = _artists[index];
          final cached = _cachedArtists[item.name];
          return _ArtistListTile(
            artist: item,
            imagePath: cached?.imageThumbnailPath,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArtistAlbumsScreen(
                    artistName: item.name,
                    playbackController: widget.playbackController,
                  ),
                ),
              ).then((_) => _loadArtists()); // Refresh after returning
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

class _ArtistWithMeta {
  final String name;
  final int albumCount;

  _ArtistWithMeta({required this.name, required this.albumCount});
}

// ---------------------------------------------------------------------------
// Artist list tile
// ---------------------------------------------------------------------------

class _ArtistListTile extends StatelessWidget {
  final _ArtistWithMeta artist;
  final String? imagePath;
  final VoidCallback onTap;

  const _ArtistListTile({
    required this.artist,
    required this.onTap,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _buildAvatar(colorScheme),
      title: Text(artist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${artist.albumCount} ${artist.albumCount == 1 ? AppLanguage.get('Album') : AppLanguage.get('Albums')}',
        style: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 13,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme) {
    if (imagePath != null && imagePath!.isNotEmpty) {
      final file = File(imagePath!);
      return CircleAvatar(
        radius: 26,
        backgroundImage: FileImage(file),
        onBackgroundImageError: (error, stackTrace) {},
        backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.35),
      );
    }

    return CircleAvatar(
      radius: 26,
      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Icon(
        Icons.person,
        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
      ),
    );
  }
}
