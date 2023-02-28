import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:stocklio_flutter/utils/platform_util.dart';

abstract class Analytics {
  static final _analytics = FirebaseAnalytics.instance;

  static Future logEvent(String name, [String? userId, String? userName]) {
    return _analytics.logEvent(
      name: name,
      parameters: {
        'userId': userId,
        'userName': userName,
        'platform': PlatformUtil.getPlatform(),
      },
    );
  }
}
