import 'package:flutter/foundation.dart';

abstract class PlatformUtil {
  static String getPlatform() {
    String platform;

    if (defaultTargetPlatform == TargetPlatform.android) {
      platform = 'android';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      platform = 'ios';
    } else {
      platform = 'web';
    }

    return platform;
  }
}
