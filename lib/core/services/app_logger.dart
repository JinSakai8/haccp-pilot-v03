import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static void warning(String message) {
    debugPrint(message);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    final buffer = StringBuffer(message);
    if (error != null) {
      buffer.write(' | error: $error');
    }
    if (stackTrace != null && kDebugMode) {
      buffer.write('\n$stackTrace');
    }
    debugPrint(buffer.toString());
  }
}
