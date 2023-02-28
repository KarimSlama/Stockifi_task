import 'package:cobrowseio_flutter/cobrowseio_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'session_recorder.dart';

class SessionRecorderMobile extends SessionRecorder {
  @override
  void init(User user) {
    CobrowseIO.start('UHLiE3vgRvjAqA', {
      'userId': user.uid,
      'userName': user.email,
    });
  }
}

SessionRecorder getSessionRecorder() => SessionRecorderMobile();
