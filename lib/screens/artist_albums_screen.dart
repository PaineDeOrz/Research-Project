// -----------------------------------------------------------------------------
// ARTIST ALBUMS SCREEN
// -----------------------------------------------------------------------------
//
// Shows all albums by a specific artist with a collapsible header.
// Header displays artist image, bio, album/track count, and play/shuffle buttons.
// Each album row shows artwork, title, and track count.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../data/repositories/library_repository.dart';
import '../data/repositories/artist_metadata_repository.dart';
import '../models/album.dart';
import '../models/app_language.dart';
import '../models/artist.dart';
import '../models/track.dart';
import '../playback/playback_controller.dart';
import '../widgets/artwork_thumbnail.dart';
import '../widgets/detail_header.dart';
import '../widgets/player_dialog.dart';
import 'album_tracks_screen.dart';

class ArtistAlbumsScreen extends StatefulWidget {
  final String artistName;
  final PlaybackController playbackController;

  const ArtistAlbumsScreen({
    super.key,
    required this.artistName,
    required this.playbackController,
  });

  @override
  State<ArtistAlbumsScreen> createState() => _ArtistAlbumsScreenState();
}

class _ArtistAlbumsScreenState extends State<ArtistAlbumsScreen> {
  final LibraryRepository _libraryRepo = LibraryRepository();

  List<_AlbumWithMeta> _albums = [];
  int _totalTrackCount = 0;
  Artist? _artistMetadata;
  bool _isLoading = true;
  bool _isFetchingMeta = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Batch load: fetch all counts in parallel, then filter
    final albums = await _libraryRepo.getAlbumsForArtist(widget.artistName);
    final trackCounts = await _libraryRepo.getAllAlbumTrackCounts();
    final firstTrackArtwork = await _libraryRepo.getAllAlbumFirstTrackArtwork();

    final albumsWithMeta = albums.map((album) {
      final artworkPath = (album.artworkThumbnailPath?.isNotEmpty == true)
          ? album.artworkThumbnailPath
          : firstTrackArtwork[album.albumId];

      return _AlbumWithMeta(
        album: album,
        trackCount: trackCounts[album.albumId] ?? 0,
        artworkPath: artworkPath,
      );
    }).toList();

    // Get total track count for artist (efficient count query)
    final totalTrackCount = await _libraryRepo.getTrackCountForArtist(widget.artistName);

    // Load cached artist metadata
    Artist? artistMeta;
    if (GetIt.I.isRegistered<ArtistMetadataRepository>()) {
      final repo = GetIt.I<ArtistMetadataRepository>();
      artistMeta = await repo.getArtistMetadata(widget.artistName);
    }

    setState(() {
      _albums = albumsWithMeta;
      _totalTrackCount = totalTrackCount;
      _artistMetadata = artistMeta;
      _isLoading = false;
    });
  }

  Future<void> _fetchArtistInfo() async {
    if (!GetIt.I.isRegistered<ArtistMetadataRepository>()) return;
    setState(() => _isFetchingMeta = true);

    final repo = GetIt.I<ArtistMetadataRepository>();
    // Force refetch if we have incomplete data (missing bio or image)
    final forceRefetch = repo.isMetadataIncomplete(_artistMetadata);
    final artist = await repo.fetchAndCacheArtist(
      widget.artistName,
      forceRefetch: forceRefetch,
    );

    if (mounted) {
      setState(() {
        _artistMetadata = artist;
        _isFetchingMeta = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Computed properties
  // ---------------------------------------------------------------------------

  String? get _headerArtworkPath => _artistMetadata?.imagePath;

  String get _subtitle {
    final albumCount = _albums.length;
    final albumText = albumCount == 1
        ? AppLanguage.get('Album')
        : AppLanguage.get('Albums');
    final trackText = _totalTrackCount == 1
        ? AppLanguage.get('Track')
        : AppLanguage.get('Tracks');
    return '$albumCount $albumText  •  $_totalTrackCount $trackText';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(context),
                _buildAlbumList(),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sliver app bar
  // ---------------------------------------------------------------------------

  Widget _buildSliverAppBar(BuildContext context) {
    final artworkPath = _headerArtworkPath;
    final hasArtwork = artworkPath != null && artworkPath.isNotEmpty;
    // Show fetch button if metadata is missing or incomplete (no bio or no image)
    final hasCompleteMeta = _artistMetadata != null &&
        _artistMetadata!.imagePath != null &&
        _artistMetadata!.bio != null;

    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      stretch: true,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final expandedHeight = 380.0;
          final collapsedHeight =
              kToolbarHeight + MediaQuery.of(context).padding.top;
          final currentHeight = constraints.maxHeight;
          final expandRatio =
              ((currentHeight - collapsedHeight) /
                      (expandedHeight - collapsedHeight))
                  .clamp(0.0, 1.0);
          final isCollapsed = expandRatio < 0.3;

          return FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(
              left: 56,
              bottom: 12,
              right: 48,
            ),
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: isCollapsed ? 1.0 : 0.0,
              child: CollapsedArtistDetailTitle(
                title: widget.artistName,
                subtitle: _subtitle,
                artworkPath: artworkPath,
              ),
            ),
            background: ExpandedArtistDetailHeader(
              artworkPath: artworkPath,
              hasArtwork: hasArtwork,
              title: widget.artistName,
              subtitle: _subtitle,
              bio: _artistMetadata?.bio,
              onPlay: _totalTrackCount == 0 ? null : _playAll,
              onShuffle: _totalTrackCount == 0 ? null : _shuffleAll,
              onFetchInfo: hasCompleteMeta ? null : _fetchArtistInfo,
              isFetching: _isFetchingMeta,
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Album list
  // ---------------------------------------------------------------------------

  Widget _buildAlbumList() {
    if (_albums.isEmpty) {
      return SliverFillRemaining(
        child: Center(child: Text(AppLanguage.get('No albums found'))),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = _albums[index];
            return _ArtistAlbumTile(
              album: item.album,
              trackCount: item.trackCount,
              artworkPath: item.artworkPath,
              onTap: () => _onAlbumTap(item.album),
            );
          },
          childCount: _albums.length,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Interactions
  // ---------------------------------------------------------------------------

  Future<void> _playAll() async {
    final tracks = await _libraryRepo.getTracksForArtist(widget.artistName);
    if (tracks.isEmpty) return;
    widget.playbackController.playQueue(
      tracks,
      startIndex: 0,
      autoPlay: true,
    );
    if (mounted) showFullPlayerDialog(context);
  }

  Future<void> _shuffleAll() async {
    final tracks = await _libraryRepo.getTracksForArtist(widget.artistName);
    if (tracks.isEmpty) return;
    final shuffled = List<Track>.from(tracks)..shuffle();
    widget.playbackController.playQueue(
      shuffled,
      startIndex: 0,
      autoPlay: true,
    );
    if (mounted) showFullPlayerDialog(context);
  }

  void _onAlbumTap(Album album) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlbumTracksScreen(
          album: album,
          playbackController: widget.playbackController,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// View model
// ---------------------------------------------------------------------------

class _AlbumWithMeta {
  final Album album;
  final int trackCount;
  final String? artworkPath;

  _AlbumWithMeta({
    required this.album,
    required this.trackCount,
    required this.artworkPath,
  });
}

// ---------------------------------------------------------------------------
// Artist album tile
// ---------------------------------------------------------------------------

class _ArtistAlbumTile extends StatelessWidget {
  final Album album;
  final int trackCount;
  final String? artworkPath;
  final VoidCallback onTap;

  const _ArtistAlbumTile({
    required this.album,
    required this.trackCount,
    required this.artworkPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ArtworkThumbnail(
        artworkPath: artworkPath,
        placeholderIcon: Icons.album,
      ),
      title: Text(
        album.albumTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '$trackCount ${trackCount == 1 ? AppLanguage.get('Track') : AppLanguage.get('Tracks')}',
        style: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 13,
        ),
      ),
      onTap: onTap,
    );
  }
}
