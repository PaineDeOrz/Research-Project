import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:musik_app/data/repositories/playlists_repository.dart';
import 'package:musik_app/models/playlist.dart';
import 'package:musik_app/playback/playback_controller.dart';
import 'package:musik_app/screens/playlist_tracks_screen.dart';
import 'package:musik_app/models/app_language.dart';

/// Bottom sheet widget displaying the user's playlists.
/// Short tap plays the selected playlist immediately.
/// Long press opens the playlist details screen.
class MyPlaylistsBottomSheet extends StatelessWidget {
  final PlaybackController playbackController;

  const MyPlaylistsBottomSheet({super.key, required this.playbackController});

  @override
  Widget build(BuildContext context) {
    final playlistsRepo = GetIt.I<PlaylistsRepository>();

    return FutureBuilder<List<Playlist>>(
      future: playlistsRepo.getUserPlaylists(),
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

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ADDED: Header showing "My Playlists"
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                AppLanguage.get('My Playlists'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),

            const Divider(height: 1),

            // ADDED: List of playlists
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: playlists.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final playlist = playlists[index];

                  return ListTile(
                    leading: const Icon(Icons.queue_music),
                    title: Text(playlist.playlistName),

                    // Tap plays the playlist immediately
                    onTap: () async {
                      final tracks =
                          await playlistsRepo.getPlaylistTracks(playlist.playlistId);

                      if (tracks.isNotEmpty) {
                        await playbackController.playQueue(
                          tracks,
                          startIndex: 0,
                          autoPlay: true,
                        );
                      }

                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },

                    // ADDED: Long press opens playlist tracks screen
                    onLongPress: () {
                      Navigator.pop(context); // Close the bottom sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaylistTracksScreen(
                            playlist: playlist,
                            playbackController: playbackController,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

