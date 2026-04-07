// -----------------------------------------------------------------------------
// GAPLESS PLAYBACK HANDLER
// -----------------------------------------------------------------------------
//
// Handles seamless track transitions using just_audio's playlist API. Loads
// multiple tracks at once so the player can prebuffer the next song while the
// current one plays. Separated from PlaybackController to keep things clean.
//
// -----------------------------------------------------------------------------

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';
import '../models/repeat_mode.dart';
import '../services/audio_library_service.dart';
import '../core/log_debug.dart';

typedef OnGaplessTrackChanged = Future<void> Function(Track newTrack, bool isPlaying);

class GaplessPlaybackHandler {
  final AudioPlayer player;
  final AudioLibraryService audioLibraryService;
  final OnGaplessTrackChanged onTrackChanged;

  bool _active = false;
  List<Track> _tracks = [];
  StreamSubscription<int?>? _indexSub;

  bool get isActive => _active;
  List<Track> get tracks => _tracks;

  GaplessPlaybackHandler({
    required this.player,
    required this.audioLibraryService,
    required this.onTrackChanged,
  });

  void startListening() {
    _indexSub = player.currentIndexStream.listen(_handleIndexChange);
  }

  Future<void> _handleIndexChange(int? index) async {
    if (!_active || index == null) return;
    if (index < 0 || index >= _tracks.length) return;

    final newTrack = _tracks[index];
    await onTrackChanged(newTrack, player.playing);
  }

  Future<bool> startPlayback({
    required List<Track> tracks,
    required int startIndex,
    required RepeatMode repeatMode,
  }) async {
    if (tracks.isEmpty) return false;

    _tracks = List.from(tracks);
    _active = true;

    try {
      final audioSources = await _buildAudioSources(tracks);
      await player.setAudioSources(audioSources, initialIndex: startIndex);
      await syncLoopMode(repeatMode);
      return true;
    } catch (e) {
      if (kDebugMode) print('GaplessPlaybackHandler: Failed to set audio sources: $e');
      _active = false;
      return false;
    }
  }

  Future<List<AudioSource>> _buildAudioSources(List<Track> tracks) async {
    final sources = <AudioSource>[];
    for (final track in tracks) {
      final uri = await audioLibraryService.getTrackUri(track);
      sources.add(AudioSource.uri(uri));
    }
    return sources;
  }

  Future<void> syncLoopMode(RepeatMode repeatMode) async {
    if (!_active) return;

    logDebug('GaplessHandler: Syncing loop mode to $repeatMode');

    switch (repeatMode) {
      case RepeatMode.off:
        await player.setLoopMode(LoopMode.off);
      case RepeatMode.one:
        await player.setLoopMode(LoopMode.one);
      case RepeatMode.all:
        await player.setLoopMode(LoopMode.all);
    }
  }

  Future<void> addTrack(Track track) async {
    if (!_active) return;

    _tracks.add(track);
    final uri = await audioLibraryService.getTrackUri(track);
    await player.addAudioSource(AudioSource.uri(uri));
  }

  Future<void> addTracks(List<Track> tracks) async {
    if (!_active) return;

    _tracks.addAll(tracks);
    final sources = await _buildAudioSources(tracks);
    await player.addAudioSources(sources);
  }

  Future<void> seekToIndex(int index) async {
    if (!_active || index < 0 || index >= _tracks.length) return;
    await player.seek(Duration.zero, index: index);
  }

  void deactivate() {
    _active = false;
    _tracks = [];
  }

  Future<void> dispose() async {
    await _indexSub?.cancel();
    _indexSub = null;
    _active = false;
    _tracks = [];
  }
}
