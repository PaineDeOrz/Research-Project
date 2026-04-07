// -----------------------------------------------------------------------------
// MUSIK AUDIO HANDLER
// -----------------------------------------------------------------------------
//
// Custom audio handler for audio_service integration.
// Bridges just_audio AudioPlayer with system media controls on both Android (notification) and iOS (Control Center).
// NOTE: iOS Control Center on the simulator doesn't include a music widget, no way to test this actually works, but it should in theory
//
// -----------------------------------------------------------------------------

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MusikAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;

  MusikAudioHandler(this._player) {
    _initStreams();
  }

  // ---------------------------------------------------------------------------
  // Stream Initialization
  // ---------------------------------------------------------------------------

  void _initStreams() {
    // Broadcast playback state changes
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _mapProcessingState(_player.processingState),
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  // ---------------------------------------------------------------------------
  // Media Item Updates
  // ---------------------------------------------------------------------------

  /// Update the current media item shown in notifications/Control Center.
  @override
  Future<void> updateMediaItem(MediaItem item) async {
    mediaItem.add(item);
  }

  /// Clear the current media item.
  void clearMediaItem() {
    mediaItem.add(null);
  }

  // ---------------------------------------------------------------------------
  // Playback Controls (called from system UI)
  // ---------------------------------------------------------------------------

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);
}
