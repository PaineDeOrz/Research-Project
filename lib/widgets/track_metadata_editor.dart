// -----------------------------------------------------------------------------
// TRACK METADATA EDITOR
// -----------------------------------------------------------------------------
//
// Dialog for editing track metadata (title, artist, album, year, track number).
// Saves to SQLite only.
// Marks the track as user managed so sync won't overwrite.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../db/daos/library_dao.dart';
import '../models/app_language.dart';
import '../models/track.dart';

/// Opens the metadata editor dialog. Returns true if changes were saved.
Future<bool?> showMetadataEditorDialog({
  required BuildContext context,
  required Track track,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _MetadataEditorDialog(track: track),
  );
}

class _MetadataEditorDialog extends StatefulWidget {
  final Track track;

  const _MetadataEditorDialog({required this.track});

  @override
  State<_MetadataEditorDialog> createState() => _MetadataEditorDialogState();
}

class _MetadataEditorDialogState extends State<_MetadataEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  late final TextEditingController _albumController;
  late final TextEditingController _yearController;
  late final TextEditingController _trackNumberController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.track.trackTitle);
    _artistController = TextEditingController(text: widget.track.trackArtist);
    _albumController = TextEditingController(text: widget.track.albumTitle);
    _yearController = TextEditingController(
      text: widget.track.year?.toString() ?? '',
    );
    _trackNumberController = TextEditingController(
      text: widget.track.trackNumber?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _yearController.dispose();
    _trackNumberController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final artist = _artistController.text.trim();
    final albumTitle = _albumController.text.trim();
    if (title.isEmpty || artist.isEmpty || albumTitle.isEmpty) return;

    setState(() => _isSaving = true);

    final year = int.tryParse(_yearController.text.trim());
    final trackNumber = int.tryParse(_trackNumberController.text.trim());

    final dao = LibraryDao();
    await dao.updateTrackMetadata(
      trackId: widget.track.trackId,
      title: title,
      artist: artist,
      albumTitle: albumTitle,
      year: year,
      trackNumber: trackNumber,
    );

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLanguage.get('editMetadata')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppLanguage.get('metadataTitle'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _artistController,
              decoration: InputDecoration(
                labelText: AppLanguage.get('metadataArtist'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _albumController,
              decoration: InputDecoration(
                labelText: AppLanguage.get('metadataAlbum'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLanguage.get('metadataYear'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _trackNumberController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLanguage.get('metadataTrackNumber'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: Text(AppLanguage.get('Cancel')),
        ),
        TextButton(
          onPressed: _isSaving ? null : _save,
          child: Text(AppLanguage.get('Save')),
        ),
      ],
    );
  }
}
