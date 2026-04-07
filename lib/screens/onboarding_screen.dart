// -----------------------------------------------------------------------------
// ONBOARDING SCREEN
// -----------------------------------------------------------------------------
//
// Onboarding for first launch.
// Lets the user pick language, theme mode, and accent color before entering the app for the first time.
//
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../data/repositories/settings_repository.dart';
import '../models/app_language.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final SettingsRepository _settings = GetIt.I<SettingsRepository>();
  int _currentPage = 0;

  // Local state for selections (before saving)
  late String _selectedLanguage;
  late ThemeMode _selectedTheme;
  late ThemeColorMode _selectedThemeColorMode;
  late bool _selectedVolumeNormalization;
  late bool _selectedGaplessPlayback;
  late SingleTrackBehavior _selectedSingleTrackBehavior;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = _settings.language;
    _selectedTheme = _settings.themeMode;
    _selectedThemeColorMode = _settings.themeColorMode;
    _selectedVolumeNormalization = _settings.volumeNormalization;
    _selectedGaplessPlayback = _settings.gaplessPlayback;
    _selectedSingleTrackBehavior = _settings.singleTrackBehavior;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    // Save settings and mark onboarding complete
    await _settings.setLanguage(_selectedLanguage);
    await _settings.setThemeMode(_selectedTheme);
    await _settings.setThemeColorMode(_selectedThemeColorMode);
    await _settings.setVolumeNormalization(_selectedVolumeNormalization);
    await _settings.setGaplessPlayback(_selectedGaplessPlayback);
    await _settings.setSingleTrackBehavior(_selectedSingleTrackBehavior);
    await _settings.setOnboardingComplete(true);

    // Notify parent to initialize services and show main app
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Page indicators
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Container(
                    width: index == _currentPage ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index == _currentPage
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildLanguagePage(colorScheme),
                  _buildThemePage(colorScheme),
                  _buildColorPage(colorScheme),
                  _buildPlaybackPage(colorScheme),
                  _buildFinishPage(colorScheme),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Back button
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: Text(AppLanguage.get('Back')),
                    )
                  else
                    const SizedBox(width: 80),

                  const Spacer(),

                  // Next / Get Started button
                  FilledButton(
                    onPressed: _currentPage == 4 ? _completeOnboarding : _nextPage,
                    child: Text(
                      _currentPage == 4
                          ? AppLanguage.get('Get Started')
                          : AppLanguage.get('Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagePage(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.language_rounded,
            size: 80,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            AppLanguage.get('Choose Language'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLanguage.get('chooseLanguageMessage'),
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Language options
          _OptionCard(
            icon: Icons.flag_rounded,
            title: 'Deutsch',
            isSelected: _selectedLanguage == 'de',
            onTap: () {
              setState(() {
                _selectedLanguage = 'de';
                AppLanguage.setLanguage('de');
              });
            },
          ),
          const SizedBox(height: 12),
          _OptionCard(
            icon: Icons.flag_outlined,
            title: 'English',
            isSelected: _selectedLanguage == 'en',
            onTap: () {
              setState(() {
                _selectedLanguage = 'en';
                AppLanguage.setLanguage('en');
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemePage(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.palette_rounded,
            size: 80,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            AppLanguage.get('Choose Theme'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLanguage.get('chooseThemeMessage'),
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Theme options
          _OptionCard(
            icon: Icons.light_mode_rounded,
            title: AppLanguage.get('Light'),
            isSelected: _selectedTheme == ThemeMode.light,
            onTap: () {
              setState(() {
                _selectedTheme = ThemeMode.light;
              });
            },
          ),
          const SizedBox(height: 12),
          _OptionCard(
            icon: Icons.dark_mode_rounded,
            title: AppLanguage.get('Dark'),
            isSelected: _selectedTheme == ThemeMode.dark,
            onTap: () {
              setState(() {
                _selectedTheme = ThemeMode.dark;
              });
            },
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

  Widget _buildColorPage(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.color_lens_rounded,
            size: 80,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            AppLanguage.get('Theme Color'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLanguage.get('themeColorSubtitle'),
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Color options
          _OptionCard(
            icon: Icons.palette_rounded,
            title: AppLanguage.get('Default Purple'),
            isSelected: _selectedThemeColorMode == ThemeColorMode.defaultPurple,
            onTap: () {
              setState(() {
                _selectedThemeColorMode = ThemeColorMode.defaultPurple;
              });
            },
          ),
          const SizedBox(height: 12),
          _OptionCard(
            icon: Icons.album_rounded,
            title: AppLanguage.get('Dynamic (Album Art)'),
            isSelected: _selectedThemeColorMode == ThemeColorMode.dynamic,
            onTap: () {
              setState(() {
                _selectedThemeColorMode = ThemeColorMode.dynamic;
              });
            },
          ),
          if (Platform.isAndroid) ...[
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.android_rounded,
              title: AppLanguage.get('Material You'),
              isSelected: _selectedThemeColorMode == ThemeColorMode.materialYou,
              onTap: () {
                setState(() {
                  _selectedThemeColorMode = ThemeColorMode.materialYou;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaybackPage(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.headphones_rounded,
            size: 80,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            AppLanguage.get('Playback Settings'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLanguage.get('playbackSettingsMessage'),
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Audio Normalizer toggle
          _ToggleOptionCard(
            icon: Icons.volume_up_rounded,
            title: AppLanguage.get('audioNormalizer'),
            subtitle: AppLanguage.get('volumeLevel'),
            isEnabled: _selectedVolumeNormalization,
            onChanged: (value) {
              setState(() {
                _selectedVolumeNormalization = value;
              });
            },
          ),
          const SizedBox(height: 12),

          // Gapless Playback toggle
          _ToggleOptionCard(
            icon: Icons.music_note_rounded,
            title: AppLanguage.get('gaplessPlayback'),
            subtitle: AppLanguage.get('seamlessPlay'),
            isEnabled: _selectedGaplessPlayback,
            onChanged: (value) {
              setState(() {
                _selectedGaplessPlayback = value;
              });
            },
          ),
          const SizedBox(height: 12),

          // After Song Ends selection
          _OptionCard(
            icon: Icons.play_circle_outline_rounded,
            title: AppLanguage.get('afterSongEnds'),
            subtitle: _getSingleTrackBehaviorName(_selectedSingleTrackBehavior),
            isSelected: true,
            onTap: () => _showSingleTrackBehaviorDialog(),
          ),
        ],
      ),
    );
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

  void _showSingleTrackBehaviorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLanguage.get('afterSongEnds')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogOption(
              title: AppLanguage.get('afterSongEndRepeat'),
              isSelected: _selectedSingleTrackBehavior == SingleTrackBehavior.repeat,
              onTap: () {
                setState(() {
                  _selectedSingleTrackBehavior = SingleTrackBehavior.repeat;
                });
                Navigator.pop(context);
              },
            ),
            _DialogOption(
              title: AppLanguage.get('afterSongEndStop'),
              isSelected: _selectedSingleTrackBehavior == SingleTrackBehavior.stop,
              onTap: () {
                setState(() {
                  _selectedSingleTrackBehavior = SingleTrackBehavior.stop;
                });
                Navigator.pop(context);
              },
            ),
            _DialogOption(
              title: AppLanguage.get('afterSongEndSimilar'),
              isSelected: _selectedSingleTrackBehavior == SingleTrackBehavior.playSimilar,
              onTap: () {
                setState(() {
                  _selectedSingleTrackBehavior = SingleTrackBehavior.playSimilar;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishPage(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 80,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            AppLanguage.get('All Set!'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLanguage.get('allSetMessage'),
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Summary of selections
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _SummaryRow(
                  icon: Icons.language_rounded,
                  text: _selectedLanguage == 'de' ? 'Deutsch' : 'English',
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  icon: _selectedTheme == ThemeMode.dark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  text: _selectedTheme == ThemeMode.dark
                      ? AppLanguage.get('Dark')
                      : AppLanguage.get('Light'),
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  icon: Icons.color_lens_rounded,
                  text: _getThemeColorModeName(_selectedThemeColorMode),
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  icon: Icons.volume_up_rounded,
                  text: '${AppLanguage.get('audioNormalizer')}: ${_selectedVolumeNormalization ? AppLanguage.get('On') : AppLanguage.get('Off')}',
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  icon: Icons.music_note_rounded,
                  text: '${AppLanguage.get('gaplessPlayback')}: ${_selectedGaplessPlayback ? AppLanguage.get('On') : AppLanguage.get('Off')}',
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  icon: Icons.play_circle_outline_rounded,
                  text: _getSingleTrackBehaviorName(_selectedSingleTrackBehavior),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected && subtitle == null)
              Icon(
                Icons.check_circle_rounded,
                color: colorScheme.primary,
              ),
            if (subtitle != null)
              Icon(
                Icons.chevron_right_rounded,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
          ],
        ),
      ),
    );
  }
}

class _ToggleOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const _ToggleOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => onChanged(!isEnabled),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isEnabled
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.2),
            width: isEnabled ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isEnabled
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isEnabled ? FontWeight.w600 : FontWeight.normal,
                      color: isEnabled
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isEnabled
                          ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isEnabled,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DialogOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      title: Text(title),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SummaryRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
