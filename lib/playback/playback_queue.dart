// -----------------------------------------------------------------------------
// PLAYBACK QUEUE
// -----------------------------------------------------------------------------
//
// Manages the ordered list of tracks for playback.
// Handles shuffle, repeat, and navigation (next/previous).
// Notifies listeners on any queue change.
// -----------------------------------------------------------------------------

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/repeat_mode.dart';
import '../models/track.dart';

class PlaybackQueue with ChangeNotifier {

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  final List<Track> _tracks = [];
  List<Track>? _shuffledTracks;
  int _currentIndex = -1;
  bool _shuffleEnabled = false;
  RepeatMode _repeatMode = RepeatMode.off;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  // Returns the active track list (shuffled or original order)
  List<Track> get _activeTracks =>
      _shuffleEnabled && _shuffledTracks != null
          ? _shuffledTracks!
          : _tracks;

  List<Track> get tracks => List.unmodifiable(_activeTracks);
  int get length => _activeTracks.length;
  int get currentIndex => _currentIndex;

  Track? get current =>
      _currentIndex >= 0 && _currentIndex < _activeTracks.length
          ? _activeTracks[_currentIndex]
          : null;

  bool get hasNext => _currentIndex >= 0 && _currentIndex < _activeTracks.length - 1;
  bool get hasPrevious => _currentIndex > 0 && _currentIndex < _activeTracks.length;
  bool get shuffleEnabled => _shuffleEnabled;
  RepeatMode get repeatMode => _repeatMode;

  // ---------------------------------------------------------------------------
  // Queue management
  // ---------------------------------------------------------------------------

  void setQueue(List<Track> tracks, {int startIndex = 0}) {
    _tracks
      ..clear()
      ..addAll(tracks);

    if (_tracks.isEmpty) {
      _currentIndex = -1;
      _shuffledTracks = null;
    } else if (_shuffleEnabled) {
      _generateShuffledTracks();
      _currentIndex = startIndex.clamp(0, _shuffledTracks!.length - 1);
    } else {
      _currentIndex = startIndex.clamp(0, _tracks.length - 1);
    }
    notifyListeners();
  }

  void addToEnd(Track track) {
    _tracks.add(track);
    if (_shuffleEnabled && _shuffledTracks != null) {
      _shuffledTracks!.add(track);
    }
    notifyListeners();
  }

  void addAllToEnd(Iterable<Track> tracks) {
    _tracks.addAll(tracks);
    if (_shuffleEnabled && _shuffledTracks != null) {
      _shuffledTracks!.addAll(tracks);
    }
    notifyListeners();
  }

  void append(Track track) {
    _tracks.add(track);
    notifyListeners();
  }

  void appendAll(Iterable<Track> tracks) {
    _tracks.addAll(tracks);
    notifyListeners();
  }

  void clear() {
    _tracks.clear();
    _shuffledTracks = null;
    _currentIndex = -1;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void setCurrentIndex(int index) {
    if (index < 0 || index >= _activeTracks.length) return;
    _currentIndex = index;
    notifyListeners();
  }

  Track? next() {
    if (_activeTracks.isEmpty) return null;

    if (_repeatMode == RepeatMode.one) {
      notifyListeners();
      return current;
    }

    if (_currentIndex < _activeTracks.length - 1) {
      _currentIndex++;
    } else if (_repeatMode == RepeatMode.all) {
      _currentIndex = 0;
    } else {
      return null;
    }

    notifyListeners();
    return current;
  }

  Track? previous() {
    if (_activeTracks.isEmpty) return null;

    if (_repeatMode == RepeatMode.one) {
      notifyListeners();
      return current;
    }

    if (_currentIndex > 0) {
      _currentIndex--;
    } else if (_repeatMode == RepeatMode.all) {
      _currentIndex = _activeTracks.length - 1;
    } else {
      return null;
    }

    notifyListeners();
    return current;
  }

  // ---------------------------------------------------------------------------
  // Shuffle and repeat
  // ---------------------------------------------------------------------------

  void setShuffleEnabled(bool enabled) {
    if (_shuffleEnabled == enabled) return;

    // Get current track BEFORE changing mode, so we read from the correct list
    final currentTrack = current;
    _shuffleEnabled = enabled;

    if (_shuffleEnabled) {
      _generateShuffledTracks();
    } else {
      if (currentTrack != null) {
        _currentIndex = _tracks.indexOf(currentTrack);
      }
      _shuffledTracks = null;
    }

    notifyListeners();
  }

  void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
    notifyListeners();
  }

  // Shuffles all tracks except the current one, placing current first
  void _generateShuffledTracks() {
    final currentTrack = current;
    final remaining = _tracks
        .where((t) => t != currentTrack)
        .toList()
      ..shuffle(Random());

    _shuffledTracks = [
      if (currentTrack != null) currentTrack,
      ...remaining,
    ];
    _currentIndex = currentTrack != null ? 0 : -1;
  }
}
