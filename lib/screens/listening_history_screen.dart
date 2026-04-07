import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../data/repositories/library_repository.dart';
import '../data/repositories/listening_history_repository.dart';
import '../models/app_language.dart';
import '../playback/playback_controller.dart';
import '../widgets/artwork_thumbnail.dart';
import '../widgets/player_dialog.dart';

// -----------------------------------------------------------------------------
// LISTENING HISTORY SCREEN
// -----------------------------------------------------------------------------
//
// Shows a list of recently played tracks with the ability to replay or remove individual entries.
//
// -----------------------------------------------------------------------------

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLanguage.get('listeningHistory')),
      ),
      body: const _ListeningHistoryList(),
    );
  }
}

class _ListeningHistoryList extends StatefulWidget {
  const _ListeningHistoryList();

  @override
  State<_ListeningHistoryList> createState() => _ListeningHistoryListState();
}

class _ListeningHistoryListState extends State<_ListeningHistoryList> {
  final ListeningHistoryRepository _repo = ListeningHistoryRepository();
  late Future<List<_ListeningHistoryRowVm>> _future = _load();

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<List<_ListeningHistoryRowVm>> _load() async {
    final entries = await _repo.getRecentHistory(limit: 500);
    return entries.map((entry) {
      return _ListeningHistoryRowVm(
        eventId: entry.eventId,
        trackId: entry.trackId,
        title: entry.trackTitle,
        artist: entry.trackArtist,
        artworkPath: entry.artworkThumbPath,
      );
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_ListeningHistoryRowVm>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Failed to load listening history.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final items = snapshot.data ?? const <_ListeningHistoryRowVm>[];
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                AppLanguage.get('listeningHistoryDisplay'),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            return _ListeningHistoryTile(item: item, onRemove: _refresh);
          },
        );
      },
    );
  }
}

class _ListeningHistoryTile extends StatelessWidget {
  const _ListeningHistoryTile({required this.item, required this.onRemove});

  final _ListeningHistoryRowVm item;
  final VoidCallback onRemove;

  Future<void> _playTrack(BuildContext context) async {
    final repository = LibraryRepository();
    final track = await repository.getTrackById(item.trackId);
    if (track != null) {
      GetIt.I<PlaybackController>().playSingleTrack(track, autoPlay: true);
      if (context.mounted) {
        showFullPlayerDialog(context);
      }
    }
  }

  Future<void> _removeEntry(BuildContext context) async {
    final historyRepository = ListeningHistoryRepository();
    await historyRepository.deleteEntry(item.eventId);
    onRemove();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ArtworkThumbnail(artworkPath: item.artworkPath, size: 44),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        item.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => _removeEntry(context),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () => _playTrack(context),
    );
  }
}

class _ListeningHistoryRowVm {
  _ListeningHistoryRowVm({
    required this.eventId,
    required this.trackId,
    required this.title,
    required this.artist,
    required this.artworkPath,
  });

  final int eventId;
  final String trackId;
  final String title;
  final String artist;
  final String? artworkPath;
}