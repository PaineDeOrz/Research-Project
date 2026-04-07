// -----------------------------------------------------------------------------
// TRACKS SCREEN
// -----------------------------------------------------------------------------
//
// Shows all songs on the device.
// Supports multi select for batch adding to playlists and pull to refresh for resyncing the library from device storage.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../core/log_debug.dart';
import '../data/repositories/playlists_repository.dart';
import '../models/app_language.dart';
import '../models/device_song.dart';
import '../models/mappers/song_track_mapper.dart';
import '../models/playlist.dart';
import '../playback/playback_controller.dart';
import '../services/audio_library_service_factory.dart';
import '../services/iOS_audio_library_service.dart';
import '../widgets/artwork_thumbnail.dart';
import '../widgets/player_dialog.dart';
import '../widgets/song_options_bottom_sheet.dart';
import '../widgets/styled_bottom_sheet.dart';

class TracksScreen extends StatefulWidget {
  final PlaybackController playbackController;

  const TracksScreen({super.key, required this.playbackController});

  @override
  State<TracksScreen> createState() => _TracksScreenState();
}

class _TracksScreenState extends State<TracksScreen> {
  final PlaylistsRepository _playlistsRepo = GetIt.I<PlaylistsRepository>();

  List<DeviceSong> _songs = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Multi select
  bool _isMultiSelectMode = false;
  final Set<int> _selectedSongIds = {};

  @override
  void initState() {
    super.initState();
    _loadFromDatabase();
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  Future<void> _loadFromDatabase() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final songs = await widget.playbackController.audioLibraryService
          .loadSongsFromDatabase();
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (exception) {
      setState(() {
        _isLoading = false;
        _errorMessage = exception.toString();
      });
    }
  }

  Future<void> _syncLibrary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final songs = await widget.playbackController.audioLibraryService
          .loadSongs();
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (exception) {
      setState(() {
        _isLoading = false;
        _errorMessage = exception.toString();
      });
    }
  }

  Future<void> _importFiles() async {
    final service = widget.playbackController.audioLibraryService;
    logDebug('TracksScreen: _importFiles called, service type = ${service.runtimeType}');

    if (service is! IOSAudioLibraryService) {
      logDebug('TracksScreen: not iOS service, returning');
      return;
    }

    logDebug('TracksScreen: calling importAudioFiles');
    try {
      final importedCount = await service.importAudioFiles();
      if (!mounted) return;

      setState(() => _isLoading = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLanguage.get('importedFilesCount').replaceFirst('{count}', '$importedCount')),
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() => _isLoading = false);
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to import files: $exception';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $exception'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Multi select
  // ---------------------------------------------------------------------------

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) _selectedSongIds.clear();
    });
  }

  void _toggleSelection(DeviceSong song) {
    setState(() {
      if (_selectedSongIds.contains(song.id)) {
        _selectedSongIds.remove(song.id);
      } else {
        _selectedSongIds.add(song.id);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLanguage.get('Tracks')),
        actions: _buildAppBarActions(),
      ),
      body: RefreshIndicator(
        onRefresh: _syncLibrary,
        child: _buildBody(context),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isMultiSelectMode) {
      return [
        if (_selectedSongIds.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: AppLanguage.get('Add selected to Playlist'),
            onPressed: _showAddSelectedToPlaylistPopup,
          ),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: AppLanguage.get('Cancel'),
          onPressed: _toggleMultiSelectMode,
        ),
      ];
    }

    return [
      if (AudioLibraryServiceFactory.isIOS)
        IconButton(
          icon: const Icon(Icons.file_upload_outlined),
          tooltip: AppLanguage.get('importFiles'),
          onPressed: _importFiles,
        ),
    ];
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    if (_songs.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      itemCount: _songs.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) => _SongListTile(
        song: _songs[index],
        isMultiSelectMode: _isMultiSelectMode,
        isSelected: _selectedSongIds.contains(_songs[index].id),
        onTap: () => _onSongTap(index),
        onLongPress: () => _onSongLongPress(_songs[index]),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLanguage.get('noSongsFound'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (AudioLibraryServiceFactory.isIOS) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _importFiles,
              icon: const Icon(Icons.file_upload_outlined),
              label: Text(AppLanguage.get('importAudioFiles')),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Interactions
  // ---------------------------------------------------------------------------

  void _onSongTap(int index) {
    if (_isMultiSelectMode) {
      _toggleSelection(_songs[index]);
      return;
    }

    final track = deviceSongToTrack(_songs[index]);
    widget.playbackController.playSingleTrack(track, autoPlay: true);
    showFullPlayerDialog(context);
  }

  void _onSongLongPress(DeviceSong song) {
    if (_isMultiSelectMode) return;

    showStyledBottomSheet(
      context: context,
      builder: (context) => SongOptionsBottomSheet(
        song: song,
        playbackController: widget.playbackController,
        onSelect: () {
          setState(() {
            _isMultiSelectMode = true;
            _selectedSongIds.add(song.id);
          });
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Add to playlist popup
  // ---------------------------------------------------------------------------

  void _showAddSelectedToPlaylistPopup() {
    final selectedTracks = _songs
        .where((song) => _selectedSongIds.contains(song.id))
        .map(deviceSongToTrack)
        .toList();

    showStyledBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: FutureBuilder<List<Playlist>>(
            future: _playlistsRepo.getUserPlaylists(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return _buildPlaylistPicker(
                context,
                playlists: snapshot.data!,
                selectedTracks: selectedTracks,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPlaylistPicker(
    BuildContext context, {
    required List<Playlist> playlists,
    required List selectedTracks,
  }) {
    final header = ListTile(
      leading: const Icon(Icons.playlist_add),
      title: Text(AppLanguage.get('Add to Playlist')),
      subtitle: Text('${_selectedSongIds.length} ${AppLanguage.get('Tracks')}'),
    );

    if (playlists.isEmpty) {
      return Wrap(
        children: [
          header,
          const Divider(height: 1),
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(AppLanguage.get('No playlists available')),
            ),
          ),
        ],
      );
    }

    return Wrap(
      children: [
        header,
        const Divider(height: 1),
        ...playlists.map(
          (playlist) => ListTile(
            leading: const Icon(Icons.queue_music),
            title: Text(playlist.playlistName),
            onTap: () async {
              final trackIds = selectedTracks
                  .map((track) => track.trackId as String)
                  .toList();
              await _playlistsRepo.addTracks(playlist.playlistId, trackIds);

              if (!context.mounted) return;
              Navigator.pop(context);
              setState(() {
                _selectedSongIds.clear();
                _isMultiSelectMode = false;
              });

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${AppLanguage.get('addedToPlaylist')} "${playlist.playlistName}"'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Song list tile
// -----------------------------------------------------------------------------

class _SongListTile extends StatelessWidget {
  final DeviceSong song;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SongListTile({
    required this.song,
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ArtworkThumbnail(artworkPath: song.artworkThumbnailPath),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        (song.artist?.isNotEmpty ?? false) ? song.artist! : AppLanguage.get('unknownArtist'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      tileColor: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.5)
          : null,
      trailing: isMultiSelectMode
          ? Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? colorScheme.primary : colorScheme.outline,
            )
          : null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

