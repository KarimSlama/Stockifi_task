// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:firebase_auth/firebase_auth.dart';

import 'session_recorder.dart';

class SessionRecorderWeb extends SessionRecorder {
  @override
  void init(User user) {
    final data = ['7i2wGBq3INBeLvmx9QxSmSji', user.uid, user.email];
    html.window.dispatchEvent(
      html.MessageEvent('cohere', data: data),
    );
  }
}

SessionRecorder getSessionRecorder() => SessionRecorderWeb();
