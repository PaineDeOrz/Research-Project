import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../data/repositories/library_repository.dart';
import '../models/app_language.dart';
import '../models/track.dart';
import '../playback/playback_controller.dart';
import '../widgets/artwork_thumbnail.dart';
import '../widgets/player_dialog.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final LibraryRepository _repository = LibraryRepository();
  List<Track> _foundSongs = [];
  String _searchQuery = '';

  void _runFilter(String enteredKeyword) async {
    _searchQuery = enteredKeyword;

    if (enteredKeyword.trim().isEmpty) {
      // Clear results when search is empty
      if (mounted) {
        setState(() => _foundSongs = []);
      }
      return;
    }

    // Only search if query is at least 2 characters
    if (enteredKeyword.trim().length < 2) return;

    // Search the repository for matches based on the keyword
    final results = await _repository.search(enteredKeyword);
    if (mounted && _searchQuery == enteredKeyword) {
      // Only update if this is still the current search
      setState(() => _foundSongs = results);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLanguage.get('search')),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              onChanged: (value) => _runFilter(value),
              decoration: InputDecoration(
                labelText: AppLanguage.get('searchForSongs'),
                suffixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _searchQuery.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              itemCount: _foundSongs.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final track = _foundSongs[index];

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
                  onTap: () {
                    GetIt.I<PlaybackController>().playQueue(_foundSongs, startIndex: index);
                    showFullPlayerDialog(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            AppLanguage.get('Start typing to search'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}