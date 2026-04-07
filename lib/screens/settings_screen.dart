import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../models/app_language.dart';
import '../data/repositories/settings_repository.dart';
import '../services/equalizer_service.dart';
import '../theme/app_theme.dart';

// -----------------------------------------------------------------------------
// SETTINGS SCREEN
// -----------------------------------------------------------------------------
//
// App settings: language, theme, equalizer, volume normalization, gapless playback, and single track behavior.
//
// Survey:
// Dark Mode 84.9%, Deutsch 61 / English 3,
// Equalizer 41.4%, Normalizer 51.4%, Gapless 52.9%
//
// -----------------------------------------------------------------------------

class SettingsScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;
  final VoidCallback onLanguageChange;

  const SettingsScreen({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
    required this.onLanguageChange,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsRepository _settings = GetIt.I<SettingsRepository>();

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLanguage.get('settings')),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),

          // Change language
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(AppLanguage.get('language')),
            subtitle: Text(
                AppLanguage.currentLanguage == 'de'
                    ? AppLanguage.get('german')
                    : AppLanguage.get('english')
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showLanguageDialog(context);
            },
          ),

          const Divider(),

          // Dark mode
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(AppLanguage.get('darkMode')),
            trailing: Switch(
              value: isDark,
              onChanged: (value) => widget.onToggleTheme(),
            ),
          ),

          // Theme color
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(AppLanguage.get('Theme Color')),
            subtitle: Text(_getThemeColorModeName(_settings.themeColorMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeColorDialog(context),
          ),

          const Divider(),

          // Equalizer
          ListTile(
            leading: const Icon(Icons.graphic_eq_outlined),
            title: Text(AppLanguage.get('equalizer')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openEqualizer(context),
          ),

          // Audio Normalizer (ReplayGain-based)
          ListTile(
            leading: const Icon(Icons.volume_up_outlined),
            title: Text(AppLanguage.get('audioNormalizer')),
            subtitle: Text(AppLanguage.get('volumeLevel')),
            trailing: Switch(
              value: _settings.volumeNormalization,
              onChanged: (value) => _settings.setVolumeNormalization(value),
            ),
          ),

          // Gapless Playback
          ListTile(
            leading: const Icon(Icons.music_note_outlined),
            title: Text(AppLanguage.get('gaplessPlayback')),
            subtitle: Text(AppLanguage.get('seamlessPlay')),
            trailing: Switch(
              value: _settings.gaplessPlayback,
              onChanged: (value) => _settings.setGaplessPlayback(value),
            ),
          ),

          const Divider(),

          // After song ends
          ListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: Text(AppLanguage.get('afterSongEnds')),
            subtitle: Text(_getSingleTrackBehaviorName(_settings.singleTrackBehavior)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSingleTrackBehaviorDialog(context),
          ),
        ],
      ),
    );
  }

  String _getThemeColorModeName(ThemeColorMode mode) {
    switch (mode) {
      case ThemeColorMode.defaultPurple:
        return AppLanguage.get('Default Purple');
      case ThemeColorMode.dynamic:
        return AppLanguage.get('Dynamic (Album Art)');
      case ThemeColorMode.materialYou:
        return AppLanguage.get('Material You');
      case ThemeColorMode.custom:
        return AppLanguage.get('Custom Color');
    }
  }

  void _showThemeColorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLanguage.get('Theme Color')),
        content: RadioGroup<ThemeColorMode>(
          groupValue: _settings.themeColorMode,
          onChanged: (ThemeColorMode? value) {
            if (value == null) return;
            _settings.setThemeColorMode(value);
            Navigator.pop(context);
            if (value == ThemeColorMode.custom) {
              _showColorPickerDialog(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeColorMode>(
                title: Text(AppLanguage.get('Default Purple')),
                value: ThemeColorMode.defaultPurple,
              ),
              RadioListTile<ThemeColorMode>(
                title: Text(AppLanguage.get('Dynamic (Album Art)')),
                value: ThemeColorMode.dynamic,
              ),
              if (Platform.isAndroid)
                RadioListTile<ThemeColorMode>(
                  title: Text(AppLanguage.get('Material You')),
                  value: ThemeColorMode.materialYou,
                ),
              RadioListTile<ThemeColorMode>(
                title: Text(AppLanguage.get('Custom Color')),
                value: ThemeColorMode.custom,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorPickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLanguage.get('Choose Color')),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AppTheme.presetColors.map((color) {
            final isSelected = _settings.customThemeColor.toARGB32() == color.toARGB32();
            return GestureDetector(
              onTap: () {
                _settings.setCustomThemeColor(color);
                Navigator.pop(context);
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _openEqualizer(BuildContext context) async {
    if (Platform.isAndroid) {
      final success = await EqualizerService.openEqualizer();
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLanguage.get('No equalizer app found'))),
        );
      }
    } else {
      // iOS: show instructions to access EQ via Settings
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLanguage.get('equalizer')),
          content: Text(AppLanguage.get('iOS EQ instructions')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLanguage.get('OK')),
            ),
          ],
        ),
      );
    }
  }

  String _getSingleTrackBehaviorName(SingleTrackBehavior behavior) {
    switch (behavior) {
      case SingleTrackBehavior.repeat:
        return AppLanguage.get('afterSongEndRepeat');
      case SingleTrackBehavior.stop:
        return AppLanguage.get('afterSongEndStop');
      case SingleTrackBehavior.playSimilar:
        return AppLanguage.get('afterSongEndSimilar');
    }
  }

  void _showSingleTrackBehaviorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLanguage.get('afterSongEnds')),
        content: RadioGroup<SingleTrackBehavior>(
          groupValue: _settings.singleTrackBehavior,
          onChanged: (SingleTrackBehavior? value) {
            if (value == null) return;
            _settings.setSingleTrackBehavior(value);
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<SingleTrackBehavior>(
                title: Text(AppLanguage.get('afterSongEndRepeat')),
                value: SingleTrackBehavior.repeat,
              ),
              RadioListTile<SingleTrackBehavior>(
                title: Text(AppLanguage.get('afterSongEndStop')),
                value: SingleTrackBehavior.stop,
              ),
              RadioListTile<SingleTrackBehavior>(
                title: Text(AppLanguage.get('afterSongEndSimilar')),
                value: SingleTrackBehavior.playSimilar,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLanguage.get('language')),
        content: RadioGroup<String>(
          groupValue: AppLanguage.currentLanguage,
          onChanged: (String? value) {
            if (value == null) return;
            AppLanguage.setLanguage(value);
            _settings.setLanguage(value);
            widget.onLanguageChange();
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(AppLanguage.get('german')),
                leading: Radio<String>(value: 'de'),
              ),
              ListTile(
                title: Text(AppLanguage.get('english')),
                leading: Radio<String>(value: 'en'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}