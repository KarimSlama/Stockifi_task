import 'package:firebase_auth/firebase_auth.dart';

import 'session_recorder_locator.dart'
    if (dart.library.js) 'session_recorder_web.dart'
    if (dart.library.io) 'session_recorder_mobile.dart';

abstract class SessionRecorder {
  static SessionRecorder? _instance;

  static SessionRecorder? get instance {
    _instance ??= getSessionRecorder();
    return _instance;
  }

  void init(User user);
}
