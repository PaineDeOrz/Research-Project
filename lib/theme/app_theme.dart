import 'package:flutter/material.dart';

class AppTheme {
  static const Color defaultSeedColor = Color(0xFF6366F1);

  /// Text theme with medium weight for a bolder look
  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.w600),
      displayMedium: base.displayMedium?.copyWith(fontWeight: FontWeight.w600),
      displaySmall: base.displaySmall?.copyWith(fontWeight: FontWeight.w600),
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w500),
      bodyLarge: base.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      bodyMedium: base.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      bodySmall: base.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w500),
      labelSmall: base.labelSmall?.copyWith(fontWeight: FontWeight.w500),
    );
  }

  /// Preset color options for custom theme selection
  static const List<Color> presetColors = [
    Color(0xFF6366F1), // Default purple
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFFEAB308), // Yellow
    Color(0xFF22C55E), // Green
    Color(0xFF14B8A6), // Teal
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
  ];

  /// Generate light theme from seed color
  static ThemeData lightFromSeed(Color seedColor) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
    );
    return base.copyWith(textTheme: _buildTextTheme(base.textTheme));
  }

  /// Generate dark theme from seed color
  static ThemeData darkFromSeed(Color seedColor) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
    );
    return base.copyWith(textTheme: _buildTextTheme(base.textTheme));
  }

  /// Generate light theme from ColorScheme (for Material You)
  static ThemeData lightFromScheme(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
    );
    return base.copyWith(textTheme: _buildTextTheme(base.textTheme));
  }

  /// Generate dark theme from ColorScheme (for Material You)
  static ThemeData darkFromScheme(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
    );
    return base.copyWith(textTheme: _buildTextTheme(base.textTheme));
  }

  // Legacy static themes (using default color)
  static final ThemeData light = lightFromSeed(defaultSeedColor);
  static final ThemeData dark = darkFromSeed(defaultSeedColor);
}
