import 'package:flutter/foundation.dart';

abstract class SentryUtil {
  static void error(
    String message,
    String culprit,
    dynamic hint,
    dynamic stackTrace,
  ) {
    if (kDebugMode) {
      return;
    }
  }

  static void log(
    String message,
    String culprit,
    dynamic hint,
    dynamic stackTrace,
  ) {
    if (kDebugMode) {
      return;
    }
  }
}
