import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:musik_app/widgets/queue_bottom_sheet.dart';
import 'package:musik_app/widgets/track_artwork.dart';
import 'package:musik_app/widgets/track_info_dialog.dart';
import 'package:musik_app/widgets/lyrics_sheet.dart';
import '../playback/playback_controller.dart';
import '../models/app_language.dart';
import '../models/track.dart';
import '../models/repeat_mode.dart' as repeat;
import '../screens/artist_albums_screen.dart';

class FullPlayerSheet extends StatefulWidget {
  const FullPlayerSheet({super.key});

  @override
  State<FullPlayerSheet> createState() => _FullPlayerSheetState();
}

class _FullPlayerSheetState extends State<FullPlayerSheet> {
  final PlaybackController _playbackController = GetIt.I<PlaybackController>();
  
  bool _shuffleOn = false;
  repeat.RepeatMode _repeatMode = repeat.RepeatMode.off;

  void _openLyricsSheet(Track track) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => LyricsSheet(
          track: track,
          positionStream: _playbackController.positionStream,
          onClose: () => Navigator.of(context).pop(),
          totalDuration: _playbackController.duration,
          controller: _playbackController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ValueListenableBuilder<Track?>(
      valueListenable: _playbackController.currentTrackListenable,
      builder: (context, track, _) {
        if (track == null) return const SizedBox.shrink();

        final duration = _playbackController.duration;
        final maxSeconds = duration.inSeconds.clamp(1, 1 << 31);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          extendBodyBehindAppBar: true,
          extendBody: true,
          body: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                children: [
                  _FullPlayerTopBar(
                    theme: theme,
                    track: track,
                    duration: duration,
                  ),
                  const Spacer(flex: 1),
                  Hero(
                    tag: 'album_art_${track.trackId}',
                    child: _FullPlayerArtwork(
                      track: track,
                      colorScheme: colorScheme,
                    ),
                  ),
                  const Spacer(flex: 1),
                  _FullPlayerTitleArtist(
                    track: track,
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 16),
                  _ShuffleRepeatRow(
                    colorScheme: colorScheme,
                    shuffleOn: _shuffleOn,
                    repeatMode: _repeatMode,
                    onToggleShuffle: _toggleShuffle,
                    onCycleRepeat: _cycleRepeat,
                  ),
                  _FullPlayerPositionSection(
                    controller: _playbackController,
                    duration: duration,
                    maxSeconds: maxSeconds,
                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _FullPlayerControlsRow(
                      controller: _playbackController,
                      colorScheme: colorScheme,
                    ),
                  ),
                  const Spacer(flex: 3),
                  _FullPlayerBottomButtons(
                    controller: _playbackController,
                    currentSpeed: _playbackController.speed,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleShuffle() {
    setState(() => _shuffleOn = !_shuffleOn);
    _playbackController.setShuffle(_shuffleOn);
  }

  void _cycleRepeat() {
    setState(() {
      switch (_repeatMode) {
        case repeat.RepeatMode.off: _repeatMode = repeat.RepeatMode.all; break;
        case repeat.RepeatMode.all: _repeatMode = repeat.RepeatMode.one; break;
        case repeat.RepeatMode.one: _repeatMode = repeat.RepeatMode.off; break;
      }
    });
    _playbackController.setRepeatMode(_repeatMode);
  }

  void _showSpeedOptions(BuildContext context) {
    final speeds = const [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLanguage.get('playbackSpeed'), style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            ...speeds.map((s) => ListTile(
              leading: const Icon(Icons.speed_rounded),
              title: Text('${s}x'),
              trailing: _playbackController.speed == s ? const Icon(Icons.check_circle_rounded) : null,
              onTap: () {
                _playbackController.setSpeed(s);
                Navigator.pop(context);
                setState(() {});
              },
            )),
          ],
        ),
      ),
    );
  }
}

class _FullPlayerTopBar extends StatelessWidget {
  final ThemeData theme;
  final Track track;
  final Duration duration;

  const _FullPlayerTopBar({
    required this.theme,
    required this.track,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        Text(
          AppLanguage.get('nowPlaying'),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => showTrackInfoDialog(
              context: context,
              track: track,
              duration: duration,
            ),
          ),
        ),
      ],
    );
  }
}

class _FullPlayerArtwork extends StatelessWidget {
  final Track track;
  final ColorScheme colorScheme;
  const _FullPlayerArtwork({required this.track, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.8;
    return TrackArtwork(
      track: track,
      size: size,
      borderRadius: BorderRadius.circular(28),
      gradientColors: [
        colorScheme.primaryContainer,
        colorScheme.primary,
      ],
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha:0.3),
          blurRadius: 30,
          offset: const Offset(0, 15),
        ),
      ],
      fallbackIcon: Icons.music_note_rounded,
    );
  }
}

class _FullPlayerTitleArtist extends StatelessWidget {
  final Track track;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _FullPlayerTitleArtist({
    required this.track,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          track.trackTitle,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            final playbackController = GetIt.I<PlaybackController>();
            // Close the full player, then navigate to artist albums
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ArtistAlbumsScreen(
                  artistName: track.trackArtist,
                  playbackController: playbackController,
                ),
              ),
            );
          },
          child: Text(
            track.trackArtist,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha:0.6),
            ),
          ),
        ),
      ],
    );
  }
}

class _FullPlayerPositionSection extends StatelessWidget {
  final PlaybackController controller;
  final Duration duration;
  final int maxSeconds;
  final ThemeData theme;
  const _FullPlayerPositionSection({
    required this.controller,
    required this.duration,
    required this.maxSeconds,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: controller.positionStream,
      initialData: Duration.zero,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        return Column(
          children: [
            Slider(
              min: 0,
              max: maxSeconds.toDouble(),
              value: position.inSeconds.clamp(0, maxSeconds).toDouble(),
              activeColor: theme.colorScheme.primary,
              inactiveColor: theme.colorScheme.primary.withValues(alpha:0.2),
              onChanged: (v) => controller.seekTo(Duration(seconds: v.round())),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_format(position), style: theme.textTheme.bodySmall),
                  Text(_format(duration), style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _ShuffleRepeatRow extends StatelessWidget {
  final ColorScheme colorScheme;
  final bool shuffleOn;
  final repeat.RepeatMode repeatMode;
  final VoidCallback onToggleShuffle;
  final VoidCallback onCycleRepeat;

  const _ShuffleRepeatRow({
    required this.colorScheme,
    required this.shuffleOn,
    required this.repeatMode,
    required this.onToggleShuffle,
    required this.onCycleRepeat,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.shuffle_rounded),
            onPressed: onToggleShuffle,
            color: shuffleOn ? colorScheme.primary : colorScheme.onSurface.withValues(alpha:0.5),
          ),
          IconButton(
            icon: Icon(repeatMode == repeat.RepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded),
            onPressed: onCycleRepeat,
            color: repeatMode == repeat.RepeatMode.off ? colorScheme.onSurface.withValues(alpha:0.5) : colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _FullPlayerControlsRow extends StatelessWidget {
  final PlaybackController controller;
  final ColorScheme colorScheme;

  const _FullPlayerControlsRow({
    required this.controller,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 40,
          icon: const Icon(Icons.skip_previous_rounded),
          onPressed: controller.previous
        ),
        const SizedBox(width: 4),
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.replay_10_rounded),
          onPressed: controller.skipBackward,
        ),
        const SizedBox(width: 16),
        ValueListenableBuilder<bool>(
          valueListenable: controller.isPlayingListenable,
          builder: (context, isPlaying, _) {
            return GestureDetector(
              onTap: controller.togglePlay,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary,
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 44,
                  color: colorScheme.onPrimary,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.forward_10_rounded),
          onPressed: controller.skipForward,
        ),
        const SizedBox(width: 4),
        IconButton(
          iconSize: 40,
          icon: const Icon(Icons.skip_next_rounded),
          onPressed: controller.next
        ),
      ],
    );
  }
}

class _FullPlayerBottomButtons extends StatelessWidget {
  final PlaybackController controller;
  final double currentSpeed;

  const _FullPlayerBottomButtons({
    required this.controller,
    required this.currentSpeed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSpeedModified = currentSpeed != 1.0;

    return ValueListenableBuilder<Track?>(
      valueListenable: controller.currentTrackListenable,
      builder: (context, track, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              iconSize: 22,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: const Icon(Icons.queue_music_rounded),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: colorScheme.surface,
                  builder: (context) => QueueBottomSheet(
                    playbackController: controller,
                  ),
                );
              },
            ),
            IconButton(
              iconSize: 22,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: Icon(
                Icons.speed_rounded,
                color: isSpeedModified ? colorScheme.primary : null,
              ),
              onPressed: () {
                final state = context.findAncestorStateOfType<_FullPlayerSheetState>();
                state?._showSpeedOptions(context);
              },
            ),
            ValueListenableBuilder<Duration?>(
              valueListenable: controller.sleepTimerRemainingListenable,
              builder: (context, remaining, _) {
                final hasTimer = remaining != null;
                return IconButton(
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  icon: hasTimer
                      ? _SleepTimerIcon(remaining: remaining, color: colorScheme.primary)
                      : const Icon(Icons.bedtime_outlined),
                  onPressed: () => _showSleepTimerOptions(context, controller, colorScheme),
                );
              },
            ),
            IconButton(
              iconSize: 22,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: track?.hasLrc == true
                  ? () {
                      final state = context.findAncestorStateOfType<_FullPlayerSheetState>();
                      if (state != null && track != null) {
                        state._openLyricsSheet(track);
                      }
                    }
                  : null,
              icon: Icon(
                Icons.lyrics_rounded,
                color: track?.hasLrc == true
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha:0.2),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSleepTimerOptions(BuildContext context, PlaybackController controller, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final hasTimer = controller.hasSleepTimer;

    final timerOptions = <(String, Duration)>[
      (AppLanguage.get('5 minutes'), const Duration(minutes: 5)),
      (AppLanguage.get('10 minutes'), const Duration(minutes: 10)),
      (AppLanguage.get('15 minutes'), const Duration(minutes: 15)),
      (AppLanguage.get('30 minutes'), const Duration(minutes: 30)),
      (AppLanguage.get('45 minutes'), const Duration(minutes: 45)),
      (AppLanguage.get('1 hour'), const Duration(hours: 1)),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLanguage.get('Sleep Timer'), style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            if (hasTimer) ...[
              ValueListenableBuilder<Duration?>(
                valueListenable: controller.sleepTimerRemainingListenable,
                builder: (context, remaining, _) {
                  final mins = remaining?.inMinutes ?? 0;
                  final secs = (remaining?.inSeconds ?? 0) % 60;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${AppLanguage.get('Time remaining')}: ${mins}m ${secs}s',
                      style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.primary),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel_outlined, color: colorScheme.error),
                title: Text(AppLanguage.get('Cancel Timer'), style: TextStyle(color: colorScheme.error)),
                onTap: () {
                  controller.cancelSleepTimer();
                  Navigator.pop(context);
                },
              ),
              const Divider(),
            ],
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...timerOptions.map((option) => ListTile(
                      leading: const Icon(Icons.bedtime_outlined),
                      title: Text(option.$1),
                      onTap: () {
                        controller.setSleepTimer(option.$2);
                        Navigator.pop(context);
                      },
                    )),
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(AppLanguage.get('Custom')),
                      onTap: () {
                        Navigator.pop(context);
                        _showCustomTimerDialog(context, controller);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomTimerDialog(BuildContext context, PlaybackController controller) {
    int hours = 0;
    int minutes = 30;

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(AppLanguage.get('Set custom time')),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppLanguage.get('Hours'), style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: hours > 0 ? () => setState(() => hours--) : null,
                          icon: const Icon(Icons.remove, size: 20),
                        ),
                        SizedBox(
                          width: 32,
                          child: Text(
                            hours.toString(),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: hours < 12 ? () => setState(() => hours++) : null,
                          icon: const Icon(Icons.add, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(':', style: theme.textTheme.titleLarge),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppLanguage.get('Minutes'), style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: (hours > 0 || minutes > 5) ? () => setState(() {
                            minutes -= 5;
                            if (minutes < 0) {
                              minutes = 55;
                              if (hours > 0) hours--;
                            }
                          }) : null,
                          icon: const Icon(Icons.remove, size: 20),
                        ),
                        SizedBox(
                          width: 32,
                          child: Text(
                            minutes.toString().padLeft(2, '0'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() {
                            minutes += 5;
                            if (minutes >= 60) {
                              minutes = 0;
                              if (hours < 12) hours++;
                            }
                          }),
                          icon: const Icon(Icons.add, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLanguage.get('Cancel')),
              ),
              FilledButton(
                onPressed: (hours > 0 || minutes > 0) ? () {
                  final duration = Duration(hours: hours, minutes: minutes);
                  controller.setSleepTimer(duration);
                  Navigator.pop(context);
                } : null,
                child: Text(AppLanguage.get('Set Timer')),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SleepTimerIcon extends StatelessWidget {
  final Duration remaining;
  final Color color;

  const _SleepTimerIcon({required this.remaining, required this.color});

  @override
  Widget build(BuildContext context) {
    final mins = remaining.inMinutes;
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(Icons.bedtime, color: color, size: 22),
          Positioned(
            bottom: -4,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                mins > 0 ? '${mins}m' : '<1m',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}