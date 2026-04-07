// -----------------------------------------------------------------------------
// PLAYBACK CONTROLLER
// -----------------------------------------------------------------------------
//
// Main controller for audio playback. Handles queue, shuffle, repeat, sleep timer and listening history. Has two modes: single track (loads one at a time, small gap between songs) and gapless (preloads multiple tracks for seamless transitions). Gapless logic lives in GaplessPlaybackHandler.
//
// -----------------------------------------------------------------------------

import 'dart:async';
import 'dart:math' as math;
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musik_app/playback/playback_queue.dart';
import 'package:musik_app/playback/gapless_playback_handler.dart';
import 'package:musik_app/playback/musik_audio_handler.dart';
import 'package:musik_app/data/repositories/listening_history_repository.dart';
import 'package:musik_app/data/repositories/playlists_repository.dart';
import 'package:musik_app/data/repositories/settings_repository.dart';
import 'package:musik_app/services/audio_library_service.dart';
import '../core/log_debug.dart';
import '../models/track.dart';
import '../models/repeat_mode.dart';

class PlaybackController extends ChangeNotifier {
  final AudioPlayer _player;
  final MusikAudioHandler _audioHandler;
  final AudioLibraryService _audioLibraryService;
  final PlaybackQueue _playbackQueue;
  final ListeningHistoryRepository _listeningHistoryRepository;
  final SettingsRepository _settings = GetIt.I<SettingsRepository>();

  late final GaplessPlaybackHandler _gaplessHandler;

  // State
  Track? _currentTrack;
  Duration _position = Duration.zero;
  bool _wasSingleTrackPlay = false;

  // UI notifiers
  final ValueNotifier<Track?> _currentTrackNotifier = ValueNotifier<Track?>(null);
  final ValueNotifier<bool> _isPlayingNotifier = ValueNotifier<bool>(false);

  // Player subscriptions
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;

  // History tracking
  int? _activeHistoryEventId;
  String? _activeHistoryTrackId;
  bool _lastPlaying = false;

  // Sleep timer
  Timer? _sleepTimer;
  Timer? _sleepTickTimer;
  DateTime? _sleepTimerEndTime;
  final ValueNotifier<Duration?> _sleepTimerRemainingNotifier = ValueNotifier<Duration?>(null);

  // Getters
  AudioLibraryService get audioLibraryService => _audioLibraryService;
  Track? get currentTrack => _currentTrack;
  Duration get position => _position;
  bool get isPlaying => _player.playing;
  Duration get duration => _currentTrack?.trackDuration ?? Duration.zero;
  double get speed => _player.speed;
  PlaybackQueue get playbackQueue => _playbackQueue;
  Stream<Duration> get positionStream => _player.positionStream;

  ValueListenable<Track?> get currentTrackListenable => _currentTrackNotifier;
  ValueListenable<bool> get isPlayingListenable => _isPlayingNotifier;
  ValueListenable<Duration?> get sleepTimerRemainingListenable => _sleepTimerRemainingNotifier;

  bool get hasSleepTimer => _sleepTimerEndTime != null;
  Duration? get sleepTimerRemaining => _sleepTimerRemainingNotifier.value;

  PlaybackController({
    required AudioLibraryService audioLibraryService,
    required AudioPlayer player,
    required MusikAudioHandler audioHandler,
    PlaybackQueue? playbackQueue,
    ListeningHistoryRepository? listeningHistoryRepository,
  })  : _audioLibraryService = audioLibraryService,
        _player = player,
        _audioHandler = audioHandler,
        _playbackQueue = playbackQueue ?? PlaybackQueue(),
        _listeningHistoryRepository = listeningHistoryRepository ?? ListeningHistoryRepository() {
    _gaplessHandler = GaplessPlaybackHandler(
      player: _player,
      audioLibraryService: _audioLibraryService,
      onTrackChanged: _onGaplessTrackChanged,
    );
    _gaplessHandler.startListening();

    _playbackQueue.addListener(notifyListeners);
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    _positionSub = _player.positionStream.listen((pos) {
      _position = pos;
    });

    // Player sometimes reports more accurate duration than metadata
    _durationSub = _player.durationStream.listen((duration) {
      if (duration != null && _currentTrack != null) {
        _currentTrack = _currentTrack!.copyWithDuration(duration);
        _currentTrackNotifier.value = _currentTrack;
      }
    });

    _stateSub = _player.playerStateStream.listen((state) async {
      // Gapless mode handles completion via currentIndexStream
      if (state.processingState == ProcessingState.completed && !_gaplessHandler.isActive) {
        await _handleTrackCompleted();
      }

      final playing = state.playing &&
          state.processingState != ProcessingState.completed &&
          state.processingState != ProcessingState.idle;

      if (_lastPlaying && !playing) {
        await _pauseActiveHistorySegmentIfAny();
      }
      _lastPlaying = playing;
      _isPlayingNotifier.value = playing;
    });
  }

  Future<void> _onGaplessTrackChanged(Track newTrack, bool isPlaying) async {
    if (_currentTrack != null && _currentTrack!.trackId != newTrack.trackId) {
      await _finalizeActiveHistoryIfAny(completed: true);
    }

    _currentTrack = newTrack;
    _currentTrackNotifier.value = newTrack;
    _playbackQueue.setCurrentIndex(_gaplessHandler.tracks.indexOf(newTrack));
    _position = Duration.zero;
    _applyVolumeNormalization(newTrack);

    // Update notification / Control Center
    _audioHandler.updateMediaItem(_buildMediaItem(newTrack));
    notifyListeners();

    if (isPlaying) {
      await _resumeOrStartHistoryForTrack(newTrack);
    }
  }

  // ---------------------------------------------------------------------------
  // Playback
  // ---------------------------------------------------------------------------

  Future<void> playSingleTrack(Track track, {bool autoPlay = true}) async {
    logDebug("trackPath is: ${track.trackPath ?? "null"}");
    _wasSingleTrackPlay = true;
    _playbackQueue.setQueue([track], startIndex: 0);
    _gaplessHandler.deactivate();
    await _loadAndPlayTrack(track, autoPlay: autoPlay);
  }

  Future<void> playQueue(List<Track> tracks, {int startIndex = 0, bool autoPlay = true}) async {
    _wasSingleTrackPlay = false;
    _playbackQueue.setQueue(tracks, startIndex: startIndex);
    final track = _playbackQueue.current;
    if (track == null) return;

    if (_settings.gaplessPlayback) {
      await _startGaplessPlayback(autoPlay: autoPlay);
    } else {
      _gaplessHandler.deactivate();
      await _loadAndPlayTrack(track, autoPlay: autoPlay);
    }
  }

  Future<void> playTrackAtIndex(int trackIndex, {bool autoPlay = true}) async {
    if (trackIndex < 0 || trackIndex >= _playbackQueue.length) return;

    if (_gaplessHandler.isActive) {
      await _gaplessHandler.seekToIndex(trackIndex);
      if (autoPlay && !_player.playing) await _player.play();
    } else {
      _playbackQueue.setCurrentIndex(trackIndex);
      final track = _playbackQueue.current;
      if (track != null) await _loadAndPlayTrack(track, autoPlay: autoPlay);
    }
  }

  Future<void> addTrackToQueueEnd(Track track) async {
    _playbackQueue.addToEnd(track);
    if (_gaplessHandler.isActive) await _gaplessHandler.addTrack(track);
    notifyListeners();
  }

  Future<void> addTracksToQueueEnd(List<Track> tracks) async {
    _playbackQueue.addAllToEnd(tracks);
    if (_gaplessHandler.isActive) await _gaplessHandler.addTracks(tracks);
    notifyListeners();
  }

  Future<void> play() async {
    if (_player.playing) return;
    await _player.play();
    _isPlayingNotifier.value = true;
    if (_currentTrack != null) await _resumeOrStartHistoryForTrack(_currentTrack!);
  }

  Future<void> pause() async {
    await _pauseActiveHistorySegmentIfAny();
    await _player.pause();
    _isPlayingNotifier.value = false;
  }

  Future<void> togglePlay() async => isPlaying ? pause() : play();

  Future<void> seekTo(Duration target) async {
    final max = duration;
    if (max == Duration.zero) return;

    var t = target;
    if (t < Duration.zero) t = Duration.zero;
    if (t > max) t = max;

    await _player.seek(t);
  }

  Future<void> skipForward() async {
    await _player.seek(_player.position + const Duration(seconds: 10));
  }

  Future<void> skipBackward() async {
    await _player.seek(_player.position - const Duration(seconds: 10));
  }

  Future<void> setSpeed(double value) async {
    await _player.setSpeed(value.clamp(0.5, 2.0));
  }

  Future<void> next() async {
    if (_gaplessHandler.isActive) {
      if (_player.hasNext) await _player.seekToNext();
    } else {
      await _finalizeActiveHistoryIfAny(completed: false);
      final nextTrack = _playbackQueue.next();
      if (nextTrack != null) await _loadAndPlayTrack(nextTrack, autoPlay: true);
    }
  }

  Future<void> previous() async {
    if (_gaplessHandler.isActive) {
      if (_player.hasPrevious) await _player.seekToPrevious();
    } else {
      await _finalizeActiveHistoryIfAny(completed: false);
      final prevTrack = _playbackQueue.previous();
      if (prevTrack != null) await _loadAndPlayTrack(prevTrack, autoPlay: true);
    }
  }

  // ---------------------------------------------------------------------------
  // Shuffle and repeat
  // ---------------------------------------------------------------------------

  Future<void> setRepeatMode(RepeatMode mode) async {
    _playbackQueue.setRepeatMode(mode);
    if (_gaplessHandler.isActive) await _gaplessHandler.syncLoopMode(mode);
    notifyListeners();
  }

  Future<void> setShuffle(bool enabled) async {
    final savedPosition = _player.position;
    final currentTrack = _currentTrack;
    final wasPlaying = _player.playing;

    _playbackQueue.setShuffleEnabled(enabled);

    // Rebuild playlist in gapless mode when shuffle changes
    if (_gaplessHandler.isActive && _playbackQueue.tracks.isNotEmpty) {
      await _startGaplessPlayback(autoPlay: wasPlaying);
      if (currentTrack != null && _currentTrack?.trackId == currentTrack.trackId) {
        await _player.seek(savedPosition);
      }
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Sleep timer
  // ---------------------------------------------------------------------------

  void setSleepTimer(Duration duration) {
    cancelSleepTimer();
    _sleepTimerEndTime = DateTime.now().add(duration);
    _sleepTimerRemainingNotifier.value = duration;

    _sleepTimer = Timer(duration, () {
      pause();
      cancelSleepTimer();
    });

    _sleepTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_sleepTimerEndTime == null) return;
      final remaining = _sleepTimerEndTime!.difference(DateTime.now());
      _sleepTimerRemainingNotifier.value = remaining.isNegative ? Duration.zero : remaining;
    });
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTickTimer?.cancel();
    _sleepTimer = null;
    _sleepTickTimer = null;
    _sleepTimerEndTime = null;
    _sleepTimerRemainingNotifier.value = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Volume Normalization
  // ---------------------------------------------------------------------------

  /// Applies volume normalization based on ReplayGain tag.
  /// Uses track's replayGainDb value to adjust volume.
  void _applyVolumeNormalization(Track? track) {
    if (!_settings.volumeNormalization) {
      _player.setVolume(1.0);
      return;
    }

    final gainDb = track?.replayGainDb;
    if (gainDb == null) {
      _player.setVolume(1.0);
      return;
    }

    // Convert dB to linear multiplier: 10^(dB/20)
    // Clamp to prevent excessive boost or complete silence
    final multiplier = math.pow(10, gainDb / 20).clamp(0.25, 2.0);
    _player.setVolume(multiplier.toDouble());
    logDebug('VolumeNorm: ${track?.trackTitle} gain=${gainDb}dB volume=$multiplier');
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  Future<void> _startGaplessPlayback({required bool autoPlay}) async {
    if (_activeHistoryEventId != null) {
      await _finalizeActiveHistoryIfAny(completed: false);
    }

    final tracks = _playbackQueue.tracks;
    final startIndex = _playbackQueue.currentIndex;
    final track = tracks[startIndex];

    _currentTrack = track;
    _currentTrackNotifier.value = track;
    _position = Duration.zero;
    notifyListeners();

    final success = await _gaplessHandler.startPlayback(
      tracks: tracks,
      startIndex: startIndex,
      repeatMode: _playbackQueue.repeatMode,
    );

    if (success && autoPlay) {
      await _player.play();
      _isPlayingNotifier.value = true;
      await _resumeOrStartHistoryForTrack(track);
    } else if (!success) {
      _isPlayingNotifier.value = false;
    }
  }

  Future<void> _loadAndPlayTrack(Track track, {required bool autoPlay}) async {
    if (_activeHistoryEventId != null && _activeHistoryTrackId != track.trackId) {
      await _finalizeActiveHistoryIfAny(completed: false);
    }

    _currentTrack = track;
    _currentTrackNotifier.value = track;
    _position = Duration.zero;
    notifyListeners();

    try {
      final uri = await _audioLibraryService.getTrackUri(track);
      await _player.setAudioSource(AudioSource.uri(uri));
      _applyVolumeNormalization(track);

      // Update notification / Control Center
      _audioHandler.updateMediaItem(_buildMediaItem(track));

      if (autoPlay) {
        await _player.play();
        _isPlayingNotifier.value = true;
        await _resumeOrStartHistoryForTrack(track);
      } else {
        _isPlayingNotifier.value = false;
      }
    } catch (exception) {
      logDebug('PlaybackController: Failed to set audio source: $exception');
      _isPlayingNotifier.value = false;
    }
  }

  /// Builds a MediaItem for notification display from a Track.
  MediaItem _buildMediaItem(Track track) {
    Uri? artUri;
    final artworkPath = track.artworkThumbnailPath ?? track.artworkHqPath;
    if (artworkPath != null && artworkPath.isNotEmpty) {
      artUri = Uri.file(artworkPath);
    }

    return MediaItem(
      id: track.trackId,
      title: track.trackTitle,
      artist: track.trackArtist,
      album: track.albumTitle,
      duration: track.trackDuration,
      artUri: artUri,
    );
  }

  Future<void> _handleTrackCompleted() async {
    await _finalizeActiveHistoryIfAny(completed: true);

    final nextTrack = _playbackQueue.next();
    if (nextTrack != null) {
      await _loadAndPlayTrack(nextTrack, autoPlay: true);
      return;
    }

    // End of queue reached. Apply single track behavior if this was a single track play.
    if (_wasSingleTrackPlay) {
      final behavior = _settings.singleTrackBehavior;

      if (behavior == SingleTrackBehavior.repeat && _currentTrack != null) {
        await _player.seek(Duration.zero);
        await _player.play();
        _isPlayingNotifier.value = true;
        await _resumeOrStartHistoryForTrack(_currentTrack!);
        return;
      }

      if (behavior == SingleTrackBehavior.playSimilar && _currentTrack != null) {
        await _playSimilarTracks(_currentTrack!.trackId);
        return;
      }
    }

    // Default: stop playback
    await _player.stop();
    _position = duration;
    _isPlayingNotifier.value = false;
    notifyListeners();
  }

  Future<void> _playSimilarTracks(String trackId) async {
    if (!GetIt.I.isRegistered<PlaylistsRepository>()) return;

    final repo = GetIt.I<PlaylistsRepository>();
    final similarTracks = await repo.getSimilarTracks(trackId, limit: 10);
    if (similarTracks.isEmpty) {
      await _player.stop();
      _isPlayingNotifier.value = false;
      notifyListeners();
      return;
    }

    final shuffled = List<Track>.from(similarTracks)..shuffle();
    _wasSingleTrackPlay = false;
    await playQueue(shuffled, startIndex: 0, autoPlay: true);
  }

  // ---------------------------------------------------------------------------
  // Listening history
  // ---------------------------------------------------------------------------

  Future<void> _finalizeActiveHistoryIfAny({required bool completed}) async {
    final eventId = _activeHistoryEventId;
    if (eventId == null) return;

    _activeHistoryEventId = null;
    _activeHistoryTrackId = null;

    try {
      await _listeningHistoryRepository.finalize(
        eventId: eventId,
        endPositionMs: _player.position.inMilliseconds,
        completed: completed,
      );
    } catch (e) {
      logDebug('ListeningHistory: finalize failed: $e');
    }
  }

  Future<void> _pauseActiveHistorySegmentIfAny() async {
    final eventId = _activeHistoryEventId;
    if (eventId == null) return;

    try {
      await _listeningHistoryRepository.markPaused(
        eventId: eventId,
        endPositionMs: _player.position.inMilliseconds,
      );
    } catch (e) {
      logDebug('ListeningHistory: markPaused failed: $e');
    }
  }

  Future<void> _resumeOrStartHistoryForTrack(Track track) async {
    final eventId = _activeHistoryEventId;

    if (eventId != null && _activeHistoryTrackId == track.trackId) {
      try {
        await _listeningHistoryRepository.markResumed(
          eventId: eventId,
          positionMs: _player.position.inMilliseconds,
        );
      } catch (e) {
        logDebug('ListeningHistory: markResumed failed: $e');
      }
      return;
    }

    try {
      final id = await _listeningHistoryRepository.logPlayStart(
        trackId: track.trackId,
        startPositionMs: _player.position.inMilliseconds,
      );
      _activeHistoryEventId = id;
      _activeHistoryTrackId = track.trackId;
    } catch (e) {
      logDebug('ListeningHistory: logPlayStart failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  Future<void> close() async {
    await _finalizeActiveHistoryIfAny(completed: false);
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _stateSub?.cancel();
    await _gaplessHandler.dispose();
    _sleepTimer?.cancel();
    _sleepTickTimer?.cancel();
    await _player.dispose();
    playbackQueue.dispose();
    _currentTrackNotifier.dispose();
    _isPlayingNotifier.dispose();
    _sleepTimerRemainingNotifier.dispose();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _gaplessHandler.dispose();
    _sleepTimer?.cancel();
    _sleepTickTimer?.cancel();
    _player.dispose();
    playbackQueue.dispose();
    _currentTrackNotifier.dispose();
    _isPlayingNotifier.dispose();
    _sleepTimerRemainingNotifier.dispose();
    super.dispose();
  }
}

extension _TrackExtension on Track {
  Track copyWithDuration(Duration duration) {
    return Track(
      trackId: trackId,
      trackUri: trackUri,
      trackTitle: trackTitle,
      albumTitle: albumTitle,
      albumId: albumId,
      trackArtist: trackArtist,
      trackDuration: duration,
      trackPath: trackPath,
      year: year,
      artworkThumbnailPath: artworkThumbnailPath,
      artworkHqPath: artworkHqPath,
      artworkUrl: artworkUrl,
      dateAdded: dateAdded,
      trackModifiedLast: trackModifiedLast,
      trackSize: trackSize,
      trackNumber: trackNumber,
      hasLrc: hasLrc,
      lrcPath: lrcPath,
    );
  }
}
