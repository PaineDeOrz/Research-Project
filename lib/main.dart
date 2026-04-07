import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musik_app/widgets/main_navigation.dart';
import 'package:musik_app/screens/onboarding_screen.dart';
import 'package:musik_app/theme/app_theme.dart';

// Import necessary services and controllers for dependency injection
import 'package:musik_app/services/audio_library_service_factory.dart';
import 'package:musik_app/services/audio_library_service.dart';
import 'package:musik_app/playback/playback_controller.dart';
import 'package:musik_app/playback/musik_audio_handler.dart';
import 'package:musik_app/data/repositories/settings_repository.dart';
import 'package:musik_app/data/repositories/playlists_repository.dart';
import 'package:musik_app/data/repositories/artist_metadata_repository.dart';
import 'package:musik_app/models/app_language.dart';

// Create a global instance of GetIt for service location
final GetIt getIt = GetIt.instance;

/// Initialize only the settings repository (needed for onboarding check)
Future<void> setupInitialServices() async {
  final settingsRepository = SettingsRepository();
  await settingsRepository.init();
  getIt.registerSingleton<SettingsRepository>(settingsRepository);

  // Apply saved language setting
  AppLanguage.setLanguage(settingsRepository.language);
}

/// Initialize the main services (called after onboarding or if already complete)
/// These services trigger database initialization, so we defer them until user action.
Future<void> setupMainServices() async {
  // Skip if already registered
  if (getIt.isRegistered<AudioLibraryService>()) return;

  // Create and register the Audio Library Service (handles file scanning)
  final libraryService = AudioLibraryServiceFactory.create();
  getIt.registerSingleton<AudioLibraryService>(libraryService);

  // Create the shared AudioPlayer instance
  final player = AudioPlayer();
  getIt.registerSingleton<AudioPlayer>(player);

  // Initialize audio_service with our custom handler for notifications and
  // Control Center integration (iOS)
  final audioHandler = await AudioService.init(
    builder: () => MusikAudioHandler(player),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.example.musik_app.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
      preloadArtwork: true,
      artDownscaleWidth: 300,
      artDownscaleHeight: 300,
    ),
  );
  getIt.registerSingleton<MusikAudioHandler>(audioHandler);

  // Create and register the Playback Controller (handles music playing)
  getIt.registerSingleton<PlaybackController>(
    PlaybackController(
      audioLibraryService: libraryService,
      player: player,
      audioHandler: audioHandler,
    ),
  );

  // Create and register the Playlists Repository (handles playlist operations)
  getIt.registerSingleton<PlaylistsRepository>(PlaylistsRepository());

  // Create and register the Artist Metadata Repository (MusicBrainz integration)
  getIt.registerSingleton<ArtistMetadataRepository>(ArtistMetadataRepository());
}

void main() async {
  // REQUIRED: Ensure Flutter is initialized before calling platform-specific services
  WidgetsFlutterBinding.ensureInitialized();

  // Configure audio session for music playback (especially important for iOS)
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  // Initialize only settings first (to check onboarding status)
  await setupInitialServices();

  runApp(const MusikApp());
}

class MusikApp extends StatefulWidget {
  const MusikApp({super.key});
  @override
  State<MusikApp> createState() => _MusikAppState();
}

class _MusikAppState extends State<MusikApp> {
  final SettingsRepository _settings = GetIt.I<SettingsRepository>();
  bool _mainServicesReady = false;

  // For dynamic album-based theming
  Color? _dynamicAlbumColor;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);

    // If onboarding is already complete, initialize main services
    if (_settings.onboardingComplete) {
      _initMainServices();
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  Future<void> _initMainServices() async {
    await setupMainServices();
    if (mounted) {
      setState(() {
        _mainServicesReady = true;
      });
      // Start listening to playback for dynamic theming
      _setupDynamicThemeListener();
    }
  }

  void _setupDynamicThemeListener() {
    if (!getIt.isRegistered<PlaybackController>()) return;
    final playback = GetIt.I<PlaybackController>();
    playback.addListener(_onPlaybackChanged);
  }

  void _onPlaybackChanged() {
    if (_settings.themeColorMode == ThemeColorMode.dynamic) {
      // Defer color extraction to avoid blocking UI during track change
      Future.delayed(const Duration(milliseconds: 300), _updateDynamicColor);
    }
  }

  Future<void> _updateDynamicColor() async {
    if (!getIt.isRegistered<PlaybackController>()) return;
    final playback = GetIt.I<PlaybackController>();
    final track = playback.currentTrack;

    final artworkPath = track?.artworkThumbnailPath ?? track?.artworkHqPath;
    if (artworkPath != null && artworkPath.isNotEmpty) {
      try {
        final file = File(artworkPath);
        if (await file.exists()) {
          // Use Flutter's built-in ColorScheme.fromImageProvider
          final scheme = await ColorScheme.fromImageProvider(
            provider: FileImage(file),
          );

          if (mounted) {
            setState(() {
              _dynamicAlbumColor = scheme.primary;
            });
          }
        }
      } catch (e) {
        debugPrint('Failed to extract album color: $e');
      }
    }
  }

  void _onOnboardingComplete() {
    // Initialize main services after onboarding
    _initMainServices();
  }

  // FUNCTION: Dark/Light mode toggle
  void _toggleTheme() {
    final newMode = _settings.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    _settings.setThemeMode(newMode);
  }

  void _changeLanguage() {
    setState(() {});
  }

  /// Get the current seed color based on theme color mode
  Color _getSeedColor(ColorScheme? systemLightScheme, ColorScheme? systemDarkScheme) {
    switch (_settings.themeColorMode) {
      case ThemeColorMode.defaultPurple:
        return AppTheme.defaultSeedColor;
      case ThemeColorMode.dynamic:
        return _dynamicAlbumColor ?? AppTheme.defaultSeedColor;
      case ThemeColorMode.materialYou:
        // Use system primary color if available
        return systemLightScheme?.primary ?? AppTheme.defaultSeedColor;
      case ThemeColorMode.custom:
        return _settings.customThemeColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use DynamicColorBuilder to get system Material You colors
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final seedColor = _getSeedColor(lightDynamic, darkDynamic);

        // Determine themes based on color mode
        ThemeData lightTheme;
        ThemeData darkTheme;

        if (_settings.themeColorMode == ThemeColorMode.materialYou &&
            lightDynamic != null && darkDynamic != null) {
          // Use full Material You color schemes
          lightTheme = AppTheme.lightFromScheme(lightDynamic);
          darkTheme = AppTheme.darkFromScheme(darkDynamic);
        } else {
          // Generate from seed color
          lightTheme = AppTheme.lightFromSeed(seedColor);
          darkTheme = AppTheme.darkFromSeed(seedColor);
        }

        return MaterialApp(
          title: 'Musik App',
          debugShowCheckedModeBanner: false,
          themeMode: _settings.themeMode,
          theme: lightTheme,
          darkTheme: darkTheme,
          home: _buildHome(),
        );
      },
    );
  }

  Widget _buildHome() {
    // Show onboarding if not complete
    if (!_settings.onboardingComplete) {
      return OnboardingScreen(onComplete: _onOnboardingComplete);
    }

    // Show loading while main services are initializing
    if (!_mainServicesReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show main app
    return MainNavigation(
      onToggleTheme: _toggleTheme,
      themeMode: _settings.themeMode,
      onLanguageChange: _changeLanguage,
    );
  }
}
