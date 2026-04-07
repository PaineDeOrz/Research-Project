import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/app_language.dart';
import '../models/track.dart';
import '../models/lyrics/lyrics.dart';
import 'package:musik_app/services/lrc_parser_service.dart';
import '../playback/playback_controller.dart';
import '../core/log_debug.dart';

class LyricsSheet extends StatefulWidget {
  final Track track;
  final Stream<Duration> positionStream;
  final VoidCallback onClose;
  final Duration totalDuration;
  final PlaybackController controller;

  const LyricsSheet({
    super.key,
    required this.track,
    required this.positionStream,
    required this.onClose,
    required this.totalDuration,
    required this.controller,
  });

  @override
  State<LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<LyricsSheet> {
  Lyrics? _lyrics;
  bool _isLoading = true;
  int _currentLineIndex = -1;
  final ScrollController _scrollController = ScrollController();
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
    _listenToPosition();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLyrics() async {
    if (!widget.track.hasLrc || widget.track.lrcPath == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final lyrics = await LrcParserService.parseFile(widget.track.lrcPath!);
      if (mounted) setState(() { _lyrics = lyrics; _isLoading = false; });
    } catch (e) {
      logDebug('LyricsSheet: Failed to load lyrics: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _listenToPosition() {
    widget.positionStream.listen((position) {
      if (!mounted) return;
      setState(() => _currentPosition = position);
      if (_lyrics != null) {
        final newIndex = _lyrics!.getLineIndexAtPosition(position);
        if (newIndex != _currentLineIndex) {
          setState(() => _currentLineIndex = newIndex);
          _scrollToCurrentLine();
        }
      }
    });
  }

  void _scrollToCurrentLine() {
    if (_currentLineIndex < 0 || !_scrollController.hasClients) return;

    // Approximate item height: padding (32) + text (~32 for fontSize 24-30)
    const double estimatedItemHeight = 64.0;

    // Get viewport height to center the current line
    final viewportHeight = _scrollController.position.viewportDimension;
    final centerOffset = viewportHeight / 3; // Position line at 1/3 from top

    final double targetOffset = (_currentLineIndex * estimatedItemHeight) - centerOffset;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = colorScheme.onSurface;
    final foregroundDim = foreground.withValues(alpha: 0.4);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_down, color: foreground, size: 32),
          onPressed: widget.onClose,
        ),
        title: Column(
          children: [
            Text(widget.track.trackTitle.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: foreground)),
            Text(widget.track.trackArtist, style: TextStyle(fontSize: 12, color: foreground.withValues(alpha: 0.6))),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: colorScheme.surface)),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: colorScheme.surface.withValues(alpha: 0.5)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(child: _buildLyricsList(foreground, foregroundDim)),
                _buildPlayerSection(colorScheme, foreground),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsList(Color foreground, Color foregroundDim) {
    if (_isLoading) return Center(child: CircularProgressIndicator(color: foreground));
    if (_lyrics == null || _lyrics!.isEmpty) return Center(child: Text(AppLanguage.get('noLyricsFound'), style: TextStyle(color: foreground)));

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      itemCount: _lyrics!.lines.length,
      itemBuilder: (context, index) {
        final line = _lyrics!.lines[index];
        final isCurrentLine = index == _currentLineIndex;
        final isEmpty = line.text.trim().isEmpty;

        return GestureDetector(
          onTap: () {
            widget.controller.seekTo(Duration(milliseconds: line.timestampMs));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: isEmpty
                ? Icon(
                    Icons.music_note_rounded,
                    size: isCurrentLine ? 30 : 24,
                    color: isCurrentLine ? foreground : foregroundDim,
                  )
                : Text(
                    line.text,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: isCurrentLine ? 30 : 24,
                      fontWeight: FontWeight.w900,
                      color: isCurrentLine ? foreground : foregroundDim,
                      height: 1.3,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerSection(ColorScheme colorScheme, Color foreground) {
    final max = widget.totalDuration.inSeconds.toDouble();
    final value = _currentPosition.inSeconds.toDouble().clamp(0.0, max);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
              activeTrackColor: foreground,
              inactiveTrackColor: foreground.withValues(alpha: 0.24),
            ),
            child: Slider(
              min: 0,
              max: max == 0 ? 1 : max,
              value: value,
              onChanged: (v) => widget.controller.seekTo(Duration(seconds: v.toInt())),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_format(_currentPosition), style: TextStyle(color: foreground.withValues(alpha: 0.7), fontSize: 12)),
                Text(_format(widget.totalDuration), style: TextStyle(color: foreground.withValues(alpha: 0.7), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<bool>(
            valueListenable: widget.controller.isPlayingListenable,
            builder: (context, isPlaying, _) {
              return GestureDetector(
                onTap: widget.controller.togglePlay,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(color: foreground, shape: BoxShape.circle),
                  child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: colorScheme.surface, size: 40),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
