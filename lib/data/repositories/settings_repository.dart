// -----------------------------------------------------------------------------
// SETTINGS REPOSITORY
// -----------------------------------------------------------------------------
//
// Persists user preferences via SharedPreferences.
// Exposes cached getters and setter methods that notify listeners on change.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Theme color source options
enum ThemeColorMode {
  defaultPurple,  // Current purple theme
  dynamic,        // Based on currently playing album art
  materialYou,    // System Material You color
  custom,         // User selected color
}

/// What happens when a single track finishes playing
enum SingleTrackBehavior {
  repeat,
  stop,
  playSimilar,
}

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class SettingsRepository extends ChangeNotifier {

  // Preference keys
  static const _keyThemeMode = 'theme_mode';
  static const _keyLanguage = 'language';
  static const _keyGaplessPlayback = 'gapless_playback';
  static const _keyOnboardingComplete = 'onboarding_complete';
  static const _keyThemeColorMode = 'theme_color_mode';
  static const _keyCustomThemeColor = 'custom_theme_color';
  static const _keyVolumeNormalization = 'volume_normalization';
  static const _keySingleTrackBehavior = 'single_track_behavior';

  late SharedPreferences _prefs;

  // Cached values
  ThemeMode _themeMode = ThemeMode.dark;
  String _language = 'de';
  bool _gaplessPlayback = true;
  bool _onboardingComplete = false;
  ThemeColorMode _themeColorMode = ThemeColorMode.defaultPurple;
  Color _customThemeColor = const Color(0xFF6366F1);
  bool _volumeNormalization = true;
  SingleTrackBehavior _singleTrackBehavior = SingleTrackBehavior.playSimilar;

  // Getters
  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  bool get gaplessPlayback => _gaplessPlayback;
  bool get onboardingComplete => _onboardingComplete;
  ThemeColorMode get themeColorMode => _themeColorMode;
  Color get customThemeColor => _customThemeColor;
  bool get volumeNormalization => _volumeNormalization;
  SingleTrackBehavior get singleTrackBehavior => _singleTrackBehavior;

  // ---------------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------------

  /// Must be called before using any other methods.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  void _loadSettings() {
    // Theme mode
    final themeModeString = _prefs.getString(_keyThemeMode);
    if (themeModeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeModeString == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.dark; // default
    }

    // Language
    _language = _prefs.getString(_keyLanguage) ?? 'de';

    // Gapless playback
    _gaplessPlayback = _prefs.getBool(_keyGaplessPlayback) ?? true;

    // Onboarding complete
    _onboardingComplete = _prefs.getBool(_keyOnboardingComplete) ?? false;

    // Theme color mode
    final colorModeString = _prefs.getString(_keyThemeColorMode);
    _themeColorMode = ThemeColorMode.values.firstWhere(
      (mode) => mode.name == colorModeString,
      orElse: () => ThemeColorMode.defaultPurple,
    );

    // Custom theme color
    final colorValue = _prefs.getInt(_keyCustomThemeColor);
    if (colorValue != null) {
      _customThemeColor = Color(colorValue);
    }

    // Volume normalization
    _volumeNormalization = _prefs.getBool(_keyVolumeNormalization) ?? true;

    // Single track behavior
    final behaviorString = _prefs.getString(_keySingleTrackBehavior);
    _singleTrackBehavior = SingleTrackBehavior.values.firstWhere(
      (behavior) => behavior.name == behaviorString,
      orElse: () => SingleTrackBehavior.playSimilar,
    );
  }

  // ---------------------------------------------------------------------------
  // Setters
  // ---------------------------------------------------------------------------

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;

    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
      case ThemeMode.system:
        value = 'system';
      case ThemeMode.dark:
        value = 'dark';
    }

    await _prefs.setString(_keyThemeMode, value);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    if (_language == lang) return;
    _language = lang;
    await _prefs.setString(_keyLanguage, lang);
    notifyListeners();
  }

  Future<void> setGaplessPlayback(bool enabled) async {
    if (_gaplessPlayback == enabled) return;
    _gaplessPlayback = enabled;
    await _prefs.setBool(_keyGaplessPlayback, enabled);
    notifyListeners();
  }

  Future<void> setOnboardingComplete(bool complete) async {
    if (_onboardingComplete == complete) return;
    _onboardingComplete = complete;
    await _prefs.setBool(_keyOnboardingComplete, complete);
    notifyListeners();
  }

  Future<void> setThemeColorMode(ThemeColorMode mode) async {
    if (_themeColorMode == mode) return;
    _themeColorMode = mode;
    await _prefs.setString(_keyThemeColorMode, mode.name);
    notifyListeners();
  }

  Future<void> setCustomThemeColor(Color color) async {
    if (_customThemeColor.toARGB32() == color.toARGB32()) return;
    _customThemeColor = color;
    await _prefs.setInt(_keyCustomThemeColor, color.toARGB32());
    notifyListeners();
  }

  Future<void> setVolumeNormalization(bool enabled) async {
    if (_volumeNormalization == enabled) return;
    _volumeNormalization = enabled;
    await _prefs.setBool(_keyVolumeNormalization, enabled);
    notifyListeners();
  }

  Future<void> setSingleTrackBehavior(SingleTrackBehavior behavior) async {
    if (_singleTrackBehavior == behavior) return;
    _singleTrackBehavior = behavior;
    await _prefs.setString(_keySingleTrackBehavior, behavior.name);
    notifyListeners();
  }
}
