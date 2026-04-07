import 'package:flutter/material.dart';
import '../db/daos/tags_dao.dart';
import '../models/track.dart';
import '../models/app_language.dart';
import 'track_metadata_editor.dart';

/// Shows a dialog with detailed track information including tags/genres.
void showTrackInfoDialog({
  required BuildContext context,
  required Track track,
  required Duration duration,
  VoidCallback? onMetadataChanged,
}) {
  showDialog(
    context: context,
    builder: (context) => _TrackInfoDialog(
      track: track,
      duration: duration,
      onMetadataChanged: onMetadataChanged,
    ),
  );
}

class _TrackInfoDialog extends StatefulWidget {
  final Track track;
  final Duration duration;
  final VoidCallback? onMetadataChanged;

  const _TrackInfoDialog({
    required this.track,
    required this.duration,
    this.onMetadataChanged,
  });

  @override
  State<_TrackInfoDialog> createState() => _TrackInfoDialogState();
}

class _TrackInfoDialogState extends State<_TrackInfoDialog> {
  final TagsDao _tagsDao = TagsDao();
  List<String> _tags = [];
  bool _loadingTags = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final tags = await _tagsDao.getTagsForTrack(widget.track.trackId);
      if (mounted) {
        setState(() {
          _tags = tags;
          _loadingTags = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingTags = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final track = widget.track;
    final duration = widget.duration;

    final path = track.trackPath ?? '';
    final format = path.isNotEmpty
        ? path.split('.').last.toUpperCase()
        : AppLanguage.get('unknown');

    // Calculate approximate bitrate from file size and duration
    String bitrate = AppLanguage.get('unknown');
    if (track.trackSize != null && duration.inSeconds > 0) {
      final kbps = ((track.trackSize! * 8) / duration.inSeconds / 1000).round();
      bitrate = '$kbps kbps';
    }

    // Format file size
    String fileSize = AppLanguage.get('unknown');
    if (track.trackSize != null) {
      final mb = track.trackSize! / (1024 * 1024);
      fileSize = '${mb.toStringAsFixed(2)} MB';
    }

    // Format duration
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final durationStr = '$minutes:$seconds';

    return AlertDialog(
      title: Text(AppLanguage.get('Track Info')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: AppLanguage.get('metadataTitle'), value: track.trackTitle),
            _InfoRow(label: AppLanguage.get('metadataArtist'), value: track.trackArtist),
            _InfoRow(label: AppLanguage.get('metadataAlbum'), value: track.albumTitle),
            if (track.year != null) _InfoRow(label: AppLanguage.get('metadataYear'), value: '${track.year}'),
            if (track.trackNumber != null) _InfoRow(label: AppLanguage.get('trackNumberShort'), value: '${track.trackNumber}'),

            // Tags/Genres section
            if (_loadingTags)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_tags.isNotEmpty)
              _InfoRow(label: AppLanguage.get('genre'), value: _tags.join(', ')),

            const Divider(height: 24),
            _InfoRow(label: AppLanguage.get('format'), value: format),
            _InfoRow(label: AppLanguage.get('duration'), value: durationStr),
            _InfoRow(label: AppLanguage.get('bitrate'), value: bitrate),
            _InfoRow(label: AppLanguage.get('fileSize'), value: fileSize),
            if (path.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                AppLanguage.get('path'),
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                path,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLanguage.get('Close')),
        ),
        TextButton(
          onPressed: () async {
            final saved = await showMetadataEditorDialog(
              context: context,
              track: track,
            );
            if (saved == true && context.mounted) {
              Navigator.of(context).pop();
              widget.onMetadataChanged?.call();
            }
          },
          child: Text(AppLanguage.get('editMetadata')),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
