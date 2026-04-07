import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:musik_app/playback/playback_controller.dart';
import 'package:musik_app/screens/home_screen.dart';
import 'package:musik_app/screens/library_screen.dart';
import 'package:musik_app/screens/search_screen.dart';
import 'package:musik_app/screens/settings_screen.dart';
import 'package:musik_app/widgets/mini_player.dart';
import '../models/app_language.dart';

class MainNavigation extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  final VoidCallback onLanguageChange;
  const MainNavigation({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
    required this.onLanguageChange,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // Zugriff auf den globalen PlaybackController
  final PlaybackController _playback = GetIt.I<PlaybackController>();

  // Track whether we have a current track to avoid unnecessary rebuilds
  bool _hasTrack = false;

  @override
  void initState() {
    super.initState();
    // Load songs from database only (no device sync on init)
    _playback.audioLibraryService.loadSongsFromDatabase();
    _hasTrack = _playback.currentTrack != null;
    // Listen to playback changes to update mini player visibility
    _playback.addListener(_onPlaybackChanged);
  }

  @override
  void dispose() {
    _playback.removeListener(_onPlaybackChanged);
    super.dispose();
  }

  void _onPlaybackChanged() {
    final hasTrackNow = _playback.currentTrack != null;
    // Only rebuild when track presence changes
    if (hasTrackNow != _hasTrack && mounted) {
      setState(() {
        _hasTrack = hasTrackNow;
      });
    }
  }

  /// ADJUSTED: Builds the main UI with bottom navigation screens.
  /// Selects the appropriate theme based on the current theme mode.
  /// Passes the playback controller to relevant screens to manage audio playback.
  /// Updates language settings and refreshes the UI when the user changes the language.
  /// Returns a list of screens for navigation including Home, Search, Library, and Settings.
  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeMode == ThemeMode.dark;

    final screens = [
      HomeScreen(onToggleTheme: widget.onToggleTheme, themeMode: widget.themeMode, playbackController: _playback,),
      const SearchScreen(),
      LibraryScreen(playbackController: _playback,),
      SettingsScreen(
        onToggleTheme: widget.onToggleTheme,
        themeMode: widget.themeMode,
        onLanguageChange: () {
          setState(() {}); 
          widget.onLanguageChange();
        },
      ),
    ];


    final showMiniPlayer = _selectedIndex != 3 && _playback.currentTrack != null; // dont show miniplayer when on settings (3)
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Offstage(
            offstage: !showMiniPlayer,
            child: MiniPlayer(key: const ValueKey('mini_player'), controller: _playback),
          ),
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha:0.5)
                      : Colors.white.withValues(alpha:0.8),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha:0.1)
                          : Colors.black.withValues(alpha:0.1),
                    ),
                  ),
                ),
                child: NavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                    // Sync library when user clicks Search or Library tab
                    if (index == 1 || index == 2) {
                      _playback.audioLibraryService.loadSongs();
                    }
                  },
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home_rounded),
                      label: AppLanguage.get('home'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.search_outlined),
                      selectedIcon: const Icon(Icons.search_rounded),
                      label: AppLanguage.get('search'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.library_music_outlined),
                      selectedIcon: const Icon(Icons.library_music_rounded),
                      label: AppLanguage.get('library'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.settings_outlined),
                      selectedIcon: const Icon(Icons.settings_rounded),
                      label: AppLanguage.get('settings'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}