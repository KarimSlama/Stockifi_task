import 'dart:async';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/models/tutorial_media.dart';
import 'package:stocklio_flutter/providers/data/auth.dart';
import 'package:stocklio_flutter/services/tutorial_service.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';
import '../../models/tutorial.dart';
import '../../utils/logger_util.dart';

class TutorialProvider extends ChangeNotifier {
  late TutorialService _tutorialService;
  AuthProvider? auth;
  TutorialProvider({
    TutorialService? tutorialService,
    this.auth,
  }) {
    auth?.user;
    _tutorialService = GetIt.instance<TutorialService>();
  }

  List<Tutorial> _tutorials = [];
  bool _isLoading = true;
  bool _isInit = false;

  bool get isLoading => _isLoading;

  StreamSubscription<List<Tutorial>>? _tutorialsSub;

  List<Tutorial> get tutorials {
    try {
      _tutorialsSub ?? _listenToTutorialsStream();
      logger.i('TutorialProvider - get tutorials is successful');
    } catch (error, stackTrace) {
      logger.e('TutorialProvider - get tutorials failed\n$error\n$stackTrace');
      SentryUtil.error('TutorialProvider get tutorials error!',
          'TutorialProvider class', error, stackTrace);
    }
    return [..._tutorials];
  }

  void _listenToTutorialsStream() {
    final user = auth?.user ?? FirebaseAuth.instance.currentUser;
    if (user == null) {
      _tutorials = [];
      return;
    }
    _tutorialsSub = _tutorialService.getTutorialsStream().listen(
      (List<Tutorial> tutorials) {
        _tutorials = tutorials;
        if (!_isInit) {
          _isInit = true;
          _isLoading = false;
        }
        logger.i(
            'TutorialProvider - _listenToTutorialsStream is successful ${tutorials.length}');
        notifyListeners();
      },
      onError: (e) {
        logger.e('TutorialProvider - _listenToTutorialsStream failed\n$e');
      },
    );
  }

  Tutorial? findByName(String name) {
    return _tutorials.firstWhereOrNull((element) => element.name == name);
  }

  Future<TutorialMedia?> getTutorialMedia(String path) async {
    final response = await _tutorialService.getTutorialMedia(path);

    if (!response.hasError) {
      return response.data;
    }

    return null;
  }

  Future<void>? cancelStreamSubscriptions() {
    return _tutorialsSub?.cancel();
  }

  @override
  void dispose() {
    cancelStreamSubscriptions();
    super.dispose();
  }
}
