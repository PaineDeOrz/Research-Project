import 'dart:io';
import 'package:musik_app/services/audio_library_service.dart';
import 'package:musik_app/services/android_audio_library_service.dart';
import 'package:musik_app/services/iOS_audio_library_service.dart';

/// Factory for creating platform-specific audio library services
class AudioLibraryServiceFactory {
  /// Creates the appropriate audio library service for the current platform
  static AudioLibraryService create() {
    if (Platform.isAndroid) {
      return AndroidAudioLibraryService();
    } else if (Platform.isIOS) {
      return IOSAudioLibraryService();
    } else {
      throw UnsupportedError(
        'Platform ${Platform.operatingSystem} is not supported',
      );
    }
  }

  /// Check if the current platform is iOS
  static bool get isIOS => Platform.isIOS;

  /// Check if the current platform is Android
  static bool get isAndroid => Platform.isAndroid;
}