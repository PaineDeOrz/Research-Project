// -----------------------------------------------------------------------------
// EQUALIZER SERVICE
// -----------------------------------------------------------------------------
//
// Opens the system equalizer on Android. iOS does not have a system equalizer
// accessible via intent, so this is Android only.
//
// -----------------------------------------------------------------------------

import 'dart:io';

import 'package:flutter/services.dart';

class EqualizerService {
  static const _channel = MethodChannel('com.example.musik_app/equalizer');

  /// Opens the system equalizer panel on Android.
  /// Returns true if successful, false if no equalizer app is available.
  /// On iOS, always returns false since there's no system equalizer.
  static Future<bool> openEqualizer({int audioSessionId = 0}) async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await _channel.invokeMethod<bool>(
        'openEqualizer',
        {'audioSessionId': audioSessionId},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Checks if a system equalizer is available on this device.
  /// Always returns false on iOS.
  static Future<bool> isAvailable() async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isEqualizerAvailable');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
