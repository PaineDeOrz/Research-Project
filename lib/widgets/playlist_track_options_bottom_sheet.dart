import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:musik_app/models/track.dart';
import 'package:musik_app/playback/playback_controller.dart';
import 'package:musik_app/data/repositories/playlists_repository.dart';
import 'package:musik_app/models/playlist.dart';
import 'package:musik_app/models/app_language.dart';

/// A bottom sheet widget that provides options for a specific track within a playlist.
///
/// Allows playing the track or removing it from the playlist.
/// Displays track title and artist at the top.
class PlaylistTrackOptionsBottomSheet extends StatelessWidget {
  final Track track;
  final Playlist playlist;
  final PlaybackController playbackController;
  final VoidCallback? onTrackRemoved;
  final PlaylistsRepository _playlistsRepo = GetIt.I<PlaylistsRepository>();

  /// Creates a bottom sheet for a track in a playlist.
  /// Requires the track, the playlist it belongs to, and the playback controller.
  /// Optional [onTrackRemoved] callback to refresh the playlist after removal.
  PlaylistTrackOptionsBottomSheet({
    super.key,
    required this.track,
    required this.playlist,
    required this.playbackController,
    this.onTrackRemoved,
  });

  /// ADDED: Builds the UI of the bottom sheet.
  /// Shows track info and options to play or remove the track.
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: [
          // Track title and artist
          ListTile(
            leading: const Icon(Icons.music_note),
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
          ),
          const Divider(height: 1),

          // Play track option
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: Text(AppLanguage.get('play')),
            onTap: () {
              Navigator.pop(context); // Close the bottom sheet
              playbackController.playSingleTrack(track, autoPlay: true);
            },
          ),

          // Remove track from playlist
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(AppLanguage.get('Remove from Playlist')),
            onTap: () async {
              Navigator.pop(context); // Close the bottom sheet

              await _playlistsRepo.removeTrack(
                playlist.playlistId,
                track.trackId,
              );

              onTrackRemoved?.call();

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${AppLanguage.get('removedFromPlaylist')} "${playlist.playlistName}"',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
