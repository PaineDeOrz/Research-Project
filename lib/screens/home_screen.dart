// -----------------------------------------------------------------------------
// HOME SCREEN
// -----------------------------------------------------------------------------
//
// Shows personalized recommendations based on listening history.
// Displays generated playlists and track suggestions in horizontal rows.
// All data loaded is read only from cache, safe for initState (due to flutter hot reload running on init)
//
// -----------------------------------------------------------------------------

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../data/repositories/library_repository.dart';
import '../data/repositories/playlists_repository.dart';
import '../models/app_language.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../playback/playback_controller.dart';
import '../widgets/home_widgets.dart';
import '../widgets/player_dialog.dart';
import 'genre_tracks_screen.dart';
import 'listening_history_screen.dart';
import 'playlist_tracks_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  final PlaybackController playbackController;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
    required this.playbackController,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Data
  List<Track> _recentlyPlayed = [];
  List<Track> _mostPlayed = [];
  List<Track> _discover = [];
  List<_PlaylistWithTracks> _generatedPlaylists = [];
  List<_GenreMix> _genreMixes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ---------------------------------------------------------------------------
  // Data loading (read-only, safe for initState)
  // ---------------------------------------------------------------------------

  Future<void> _loadData() async {
    if (!GetIt.I.isRegistered<PlaylistsRepository>()) {
      setState(() => _isLoading = false);
      return;
    }

    final repo = GetIt.I<PlaylistsRepository>();

    // Load track lists from repository (read-only queries)
    final recentlyPlayed = await repo.getRecentlyPlayedTracks(days: 30, limit: 10);
    final mostPlayed = await repo.getMostPlayedTracks(days: 90, limit: 10);
    final discover = await repo.getUnderplayedTracks(limit: 10);

    // Load generated playlists with their tracks
    final playlists = await repo.getGeneratedPlaylists();
    final playlistsWithTracks = <_PlaylistWithTracks>[];
    for (final playlist in playlists) {
      final tracks = await repo.getPlaylistTracks(playlist.playlistId);
      if (tracks.isNotEmpty) {
        playlistsWithTracks.add(_PlaylistWithTracks(
          playlist: playlist,
          tracks: tracks,
        ));
      }
    }

    // Load top genres for genre mixes (only genres with 3+ tracks)
    final libraryRepo = LibraryRepository();
    final genreTagCounts = await libraryRepo.getGenreTagCounts();
    final genreMixes = genreTagCounts.entries
        .where((entry) => entry.value >= 3)
        .take(10)
        .map((entry) => _GenreMix(name: entry.key, trackCount: entry.value))
        .toList();

    if (mounted) {
      setState(() {
        _recentlyPlayed = recentlyPlayed;
        _mostPlayed = mostPlayed;
        _discover = discover;
        _generatedPlaylists = playlistsWithTracks;
        _genreMixes = genreMixes;
        _isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeMode == ThemeMode.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(isDark),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ),
      title: Text(
        AppLanguage.get('titleHomeScreen'),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () => _navigateToHistory(),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _regeneratePlaylists(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    final hasContent = _recentlyPlayed.isNotEmpty ||
        _mostPlayed.isNotEmpty ||
        _discover.isNotEmpty ||
        _generatedPlaylists.isNotEmpty ||
        _genreMixes.isNotEmpty;

    if (!hasContent) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _regeneratePlaylists();
      },
      child: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
          bottom: 100,
        ),
        children: [
          // Recently played tracks
          if (_recentlyPlayed.isNotEmpty) ...[
            HomeSectionHeader(
              title: AppLanguage.get('recentlyPlayed'),
              onSeeAll: () => _navigateToHistory(),
            ),
            HomeHorizontalRow<Track>(
              items: _recentlyPlayed,
              itemBuilder: (track) => HomeTrackCard(
                track: track,
                onTap: () => _playTrack(track, _recentlyPlayed),
              ),
            ),
          ],

          // Generated playlists (as cards)
          if (_generatedPlaylists.isNotEmpty) ...[
            HomeSectionHeader(title: AppLanguage.get('madeForYou')),
            HomeHorizontalRow<_PlaylistWithTracks>(
              items: _generatedPlaylists,
              itemBuilder: (playlistData) {
                final firstTrackArtwork = playlistData.tracks.isNotEmpty
                    ? playlistData.tracks.first.artworkThumbnailPath
                    : null;
                return HomePlaylistCard(
                  playlist: playlistData.playlist,
                  displayName: AppLanguage.getGeneratedPlaylistName(
                    playlistData.playlist.playlistName,
                  ),
                  artworkPath: firstTrackArtwork,
                  trackCount: playlistData.tracks.length,
                  gradientColors: _gradientForPlaylist(playlistData.playlist.playlistName),
                  icon: _iconForPlaylist(playlistData.playlist.playlistName),
                  onTap: () => _navigateToPlaylist(playlistData.playlist),
                );
              },
            ),
          ],

          // Genre mixes
          if (_genreMixes.isNotEmpty) ...[
            HomeSectionHeader(title: AppLanguage.get('genreMixes')),
            HomeHorizontalRow<_GenreMix>(
              items: _genreMixes,
              itemBuilder: (mix) => HomeGenreMixCard(
                genreName: mix.name,
                trackCount: mix.trackCount,
                gradientColors: _gradientForGenreMix(_genreMixes.indexOf(mix)),
                onTap: () => _navigateToGenreMix(mix.name),
              ),
            ),
          ],

          // Most played tracks
          if (_mostPlayed.isNotEmpty) ...[
            HomeSectionHeader(title: AppLanguage.get('mostPlayed')),
            HomeHorizontalRow<Track>(
              items: _mostPlayed,
              itemBuilder: (track) => HomeTrackCard(
                track: track,
                onTap: () => _playTrack(track, _mostPlayed),
              ),
            ),
          ],

          // Discover (underplayed tracks)
          if (_discover.isNotEmpty) ...[
            HomeSectionHeader(title: AppLanguage.get('discover')),
            HomeHorizontalRow<Track>(
              items: _discover,
              itemBuilder: (track) => HomeTrackCard(
                track: track,
                onTap: () => _playTrack(track, _discover),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_outlined,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              AppLanguage.get('startListening'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppLanguage.get('playMusicToSeeRecommendations'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  List<Color> _gradientForPlaylist(String name) {
    switch (name) {
      case 'Recently Played':
        return const [Color(0xFF667EEA), Color(0xFF764BA2)];
      case 'Most Played':
        return const [Color(0xFFF093FB), Color(0xFFF5576C)];
      case 'Rediscover':
        return const [Color(0xFF4ECDC4), Color(0xFF44A08D)];
      case 'Discover':
        return const [Color(0xFFFA709A), Color(0xFFFEE140)];
      case 'More Like This':
        return const [Color(0xFF43E97B), Color(0xFF38F9D7)];
      default:
        return const [Color(0xFF667EEA), Color(0xFF764BA2)];
    }
  }

  IconData _iconForPlaylist(String name) {
    switch (name) {
      case 'Recently Played':
        return Icons.history;
      case 'Most Played':
        return Icons.trending_up;
      case 'Rediscover':
        return Icons.refresh;
      case 'Discover':
        return Icons.explore;
      case 'More Like This':
        return Icons.auto_awesome;
      default:
        return Icons.playlist_play;
    }
  }

  static const _genreGradients = <List<Color>>[
    [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
    [Color(0xFF667EEA), Color(0xFF764BA2)],
    [Color(0xFF43E97B), Color(0xFF38F9D7)],
    [Color(0xFFF093FB), Color(0xFFF5576C)],
    [Color(0xFF4ECDC4), Color(0xFF44A08D)],
    [Color(0xFFFA709A), Color(0xFFFEE140)],
    [Color(0xFF30CFD0), Color(0xFF330867)],
    [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
    [Color(0xFFFF9A9E), Color(0xFFFAD0C4)],
    [Color(0xFF89F7FE), Color(0xFF66A6FF)],
  ];

  List<Color> _gradientForGenreMix(int index) {
    return _genreGradients[index % _genreGradients.length];
  }

  void _navigateToGenreMix(String genreName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GenreTracksScreen(
          genreName: genreName,
          displayName: genreName,
          playbackController: widget.playbackController,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation and playback
  // ---------------------------------------------------------------------------

  void _playTrack(Track track, List<Track> queue) {
    final index = queue.indexOf(track);
    widget.playbackController.playQueue(
      queue,
      startIndex: index >= 0 ? index : 0,
      autoPlay: true,
    );
    showFullPlayerDialog(context);
  }

  void _navigateToPlaylist(Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistTracksScreen(
          playlist: playlist,
          playbackController: widget.playbackController,
        ),
      ),
    );
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  Future<void> _regeneratePlaylists() async {
    if (!GetIt.I.isRegistered<PlaylistsRepository>()) return;

    setState(() => _isLoading = true);

    final repo = GetIt.I<PlaylistsRepository>();
    await repo.regenerateAllGeneratedPlaylists();
    await _loadData();
  }
}

// ---------------------------------------------------------------------------
// View model
// ---------------------------------------------------------------------------

class _PlaylistWithTracks {
  final Playlist playlist;
  final List<Track> tracks;

  _PlaylistWithTracks({required this.playlist, required this.tracks});
}

class _GenreMix {
  final String name;
  final int trackCount;

  _GenreMix({required this.name, required this.trackCount});
}
