// -----------------------------------------------------------------------------
// LIBRARY SCREEN
// -----------------------------------------------------------------------------
//
// Shows a grid of library categories with nested navigation.
// Uses a nested Navigator to keep bottom bar and mini player visible.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../models/app_language.dart';
import '../playback/playback_controller.dart';
import '../widgets/library_category_card.dart';
import 'albums_screen.dart';
import 'artists_screen.dart';
import 'genres_screen.dart';
import 'playlists_screen.dart';
import 'tracks_screen.dart';

class LibraryScreen extends StatefulWidget {
  final PlaybackController playbackController;

  const LibraryScreen({super.key, required this.playbackController});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => _LibraryCategoryGrid(
            playbackController: widget.playbackController,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Category grid
// ---------------------------------------------------------------------------

class _LibraryCategoryGrid extends StatelessWidget {
  final PlaybackController playbackController;

  const _LibraryCategoryGrid({required this.playbackController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLanguage.get('library')),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1,
          children: [
            LibraryCategoryCard(
              title: AppLanguage.get('Tracks'),
              icon: Icons.music_note,
              gradientColors: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              onTap: () => _navigateToTracks(context),
            ),
            LibraryCategoryCard(
              title: AppLanguage.get('Albums'),
              icon: Icons.album,
              gradientColors: const [Color(0xFFEC4899), Color(0xFFF472B6)],
              onTap: () => _navigateToAlbums(context),
            ),
            LibraryCategoryCard(
              title: AppLanguage.get('Playlists'),
              icon: Icons.playlist_play,
              gradientColors: const [Color(0xFF10B981), Color(0xFF34D399)],
              onTap: () => _navigateToPlaylists(context),
            ),
            LibraryCategoryCard(
              title: AppLanguage.get('Artists'),
              icon: Icons.person,
              gradientColors: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
              onTap: () => _navigateToArtists(context),
            ),
            LibraryCategoryCard(
              title: AppLanguage.get('Genres'),
              icon: Icons.category,
              gradientColors: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
              onTap: () => _navigateToGenres(context),
            ),
            const SizedBox(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _navigateToTracks(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TracksScreen(playbackController: playbackController),
      ),
    );
  }

  void _navigateToAlbums(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AlbumsScreen(playbackController: playbackController),
      ),
    );
  }

  void _navigateToPlaylists(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PlaylistsScreen(playbackController: playbackController),
      ),
    );
  }

  void _navigateToArtists(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ArtistsScreen(playbackController: playbackController),
      ),
    );
  }

  void _navigateToGenres(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GenresScreen(playbackController: playbackController),
      ),
    );
  }
}
