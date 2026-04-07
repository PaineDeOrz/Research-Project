// -----------------------------------------------------------------------------
// GENRE TRACKS SCREEN
// -----------------------------------------------------------------------------
//
// Shows all tracks tagged with a specific genre.
// Provides play all and shuffle buttons in the app bar.
// Track rows show artwork, title, and artist.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../data/repositories/library_repository.dart';
import '../models/app_language.dart';
import '../models/mappers/song_track_mapper.dart';
import '../models/track.dart';
import '../playback/playback_controller.dart';
import '../widgets/artwork_thumbnail.dart';
import '../widgets/player_dialog.dart';
import '../widgets/song_options_bottom_sheet.dart';
import '../widgets/styled_bottom_sheet.dart';

class GenreTracksScreen extends StatefulWidget {
  final String genreName;
  final String displayName;
  final PlaybackController playbackController;

  const GenreTracksScreen({
    super.key,
    required this.genreName,
    required this.displayName,
    required this.playbackController,
  });

  @override
  State<GenreTracksScreen> createState() => _GenreTracksScreenState();
}

class _GenreTracksScreenState extends State<GenreTracksScreen> {
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
    final tracks = await _libraryRepo.getTracksForGenre(widget.genreName);
    setState(() {
      _tracks = tracks;
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
        title: Text(widget.displayName),
        actions: [
          if (_tracks.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.shuffle_rounded),
              tooltip: AppLanguage.get('Shuffle'),
              onPressed: _shuffleAll,
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow_rounded),
              tooltip: AppLanguage.get('Play'),
              onPressed: _playAll,
            ),
          ],
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tracks.isEmpty) {
      return Center(
        child: Text(
          AppLanguage.get('No tracks'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.builder(
      itemCount: _tracks.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final track = _tracks[index];
        return _GenreTrackTile(
          track: track,
          onTap: () => _onTrackTap(index),
          onLongPress: () => _onTrackLongPress(track),
        );
      },
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
// Genre track tile
// ---------------------------------------------------------------------------

class _GenreTrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _GenreTrackTile({
    required this.track,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
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
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
