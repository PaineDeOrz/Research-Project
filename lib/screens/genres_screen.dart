// -----------------------------------------------------------------------------
// GENRES SCREEN
// -----------------------------------------------------------------------------
//
// Lists all genres from the library sorted by track count.
// Each row shows the genre name and how many tracks have that genre tag.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../data/repositories/library_repository.dart';
import '../models/app_language.dart';
import '../playback/playback_controller.dart';
import 'genre_tracks_screen.dart';

class GenresScreen extends StatefulWidget {
  final PlaybackController playbackController;

  const GenresScreen({super.key, required this.playbackController});

  @override
  State<GenresScreen> createState() => _GenresScreenState();
}

class _GenresScreenState extends State<GenresScreen> {
  final LibraryRepository _libraryRepo = LibraryRepository();

  List<_GenreWithCount> _genres = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  Future<void> _loadGenres() async {
    setState(() => _isLoading = true);

    final tagCounts = await _libraryRepo.getGenreTagCounts();

    final genres =
        tagCounts.entries
            .map(
              (entry) =>
                  _GenreWithCount(name: entry.key, trackCount: entry.value),
            )
            .where((genre) => genre.trackCount > 0)
            .toList()
          ..sort((a, b) {
            final countCompare = b.trackCount.compareTo(a.trackCount);
            if (countCompare != 0) return countCompare;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

    setState(() {
      _genres = genres;
      _isLoading = false;
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLanguage.get('Genres'))),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_genres.isEmpty) {
      return Center(
        child: Text(
          AppLanguage.get('No genres found'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGenres,
      child: ListView.builder(
        itemCount: _genres.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final item = _genres[index];
          // Tags are stored lowercase so we capitalize for display
          final displayName = item.name
              .split(' ')
              .map(
                (word) => word.isEmpty
                    ? word
                    : '${word[0].toUpperCase()}${word.substring(1)}',
              )
              .join(' ');

          return _GenreListTile(
            displayName: displayName,
            trackCount: item.trackCount,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GenreTracksScreen(
                    genreName: item.name,
                    displayName: displayName,
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

class _GenreWithCount {
  final String name;
  final int trackCount;

  _GenreWithCount({required this.name, required this.trackCount});
}

// ---------------------------------------------------------------------------
// Genre list tile
// ---------------------------------------------------------------------------

class _GenreListTile extends StatelessWidget {
  final String displayName;
  final int trackCount;
  final VoidCallback onTap;

  const _GenreListTile({
    required this.displayName,
    required this.trackCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.35),
        child: Icon(
          Icons.category,
          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
        ),
      ),
      title: Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
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
