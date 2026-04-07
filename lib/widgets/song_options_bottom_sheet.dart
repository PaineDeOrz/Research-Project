import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:musik_app/models/device_song.dart';
import 'package:musik_app/models/app_language.dart';
import 'package:musik_app/models/track.dart';
import 'package:musik_app/playback/playback_controller.dart';
import 'package:musik_app/widgets/track_info_dialog.dart';
import '../models/mappers/song_track_mapper.dart';
import 'package:musik_app/data/repositories/playlists_repository.dart';
import 'package:musik_app/models/playlist.dart';

/// A bottom sheet widget providing options for a single device song.
/// Allows playing, queueing, adding to a playlist, or deleting the song.
class SongOptionsBottomSheet extends StatelessWidget {
  final DeviceSong song;
  final PlaybackController playbackController;
  final VoidCallback? onSelect;

  final PlaylistsRepository _playlistsRepo = GetIt.I<PlaylistsRepository>();

  /// Creates a bottom sheet for a device song.
  /// Requires the song and the playback controller.
  /// Optional [onSelect] callback to trigger multi-select mode.
  SongOptionsBottomSheet({
    super.key,
    required this.song,
    required this.playbackController,
    this.onSelect,
  });

  /// ADDED: Builds the UI of the bottom sheet.
  /// Shows song info and actions: play, queue, add to playlist, delete.
  @override
  Widget build(BuildContext context) {
    final track = deviceSongToTrack(song);

    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.music_note),
            title: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              (song.artist?.isNotEmpty ?? false) ? song.artist! : AppLanguage.get('unknownArtist'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          if (onSelect != null)
            ListTile(
              leading: const Icon(Icons.checklist),
              title: Text(AppLanguage.get('Select')),
              onTap: () {
                Navigator.of(context).pop();
                onSelect!();
              },
            ),
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: Text(AppLanguage.get('play')),
            onTap: () {
              Navigator.of(context).pop();
              playbackController.playSingleTrack(track, autoPlay: true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue_music),
            title: Text(AppLanguage.get('addToQueue')),
            onTap: () {
              Navigator.of(context).pop();
              playbackController.addTrackToQueueEnd(track);
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: Text(AppLanguage.get('Add to a Playlist')),
            onTap: () {
              Navigator.of(context).pop();
              _showAddToPlaylistPopup(context, track);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(AppLanguage.get('Track Info')),
            onTap: () {
              Navigator.of(context).pop();
              showTrackInfoDialog(
                context: context,
                track: track,
                duration: track.trackDuration,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(AppLanguage.get('delete song')),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: implement remove / delete action
            },
          ),
        ],
      ),
    );
  }

  /// Shows a bottom sheet listing all playlists.
  /// Allows adding the given track to a selected playlist.
  void _showAddToPlaylistPopup(BuildContext context, Track track) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return FutureBuilder<List<Playlist>>(
          future: _playlistsRepo.getUserPlaylists(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final playlists = snapshot.data!;
            if (playlists.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(16),
                child: Text(AppLanguage.get('No playlists available')),
              );
            }

            return ListView(
              shrinkWrap: true,
              children: playlists.map((playlist) {
                return ListTile(
                  leading: const Icon(Icons.queue_music),
                  title: Text(playlist.playlistName),
                  onTap: () async {
                    await _playlistsRepo.addTrack(
                      playlist.playlistId,
                      track.trackId,
                    );

                    if (!context.mounted) return;
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${AppLanguage.get('addedToPlaylist')} "${playlist.playlistName}"',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
