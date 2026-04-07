import 'package:flutter/foundation.dart';

void logDebug(String message, {StackTrace? stackTrace}) {
  if (!kDebugMode) return;
  debugPrint(message);
}