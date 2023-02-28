import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/models/shortcut.dart';
import 'package:stocklio_flutter/providers/data/auth.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';
import '../../services/shortcut_service.dart';
import '../../utils/logger_util.dart';

class ShortcutProvider extends ChangeNotifier {
  late ShortcutService _shortcutService;
  AuthProvider? auth;
  ShortcutProvider({
    ShortcutService? shortcutservice,
    this.auth,
  }) {
    auth?.user;
    _shortcutService = GetIt.instance<ShortcutService>();
  }

  List<Shortcut> _shortcuts = [];

  bool _isLoading = true;
  bool _isInit = false;

  bool get isLoading => _isLoading;

  StreamSubscription<List<Shortcut>>? _shortcutsSub;

  List<Shortcut> get shortcuts {
    try {
      _shortcutsSub ?? _listenToGlobalShortcutsStream();
      logger.i('ShortcutProvider - get shortcuts is successful');
    } catch (error, stackTrace) {
      logger.e('ShortcutProvider - get shortcuts failed\n$error\n$stackTrace');
      SentryUtil.error('ShortcutProvider get shortcuts error!',
          'ShortcutProvider class', error, stackTrace);
    }
    return [..._shortcuts];
  }

  void _listenToGlobalShortcutsStream() {
    final user = auth?.user ?? FirebaseAuth.instance.currentUser;
    if (user == null) {
      _shortcuts = [];
      return;
    }

    _shortcutsSub = _shortcutService.getGlobalShortcutsStream().listen(
      (List<Shortcut> shortcuts) {
        _shortcuts = shortcuts;
        if (!_isInit) {
          _isInit = true;
          _isLoading = false;
        }
        logger.i(
            'ShortcutProvider - _listenToShortcutsStream is successful ${shortcuts.length}');
        notifyListeners();
      },
      onError: (e) {
        logger.e('ShortcutProvider - _listenToShortcutsStream failed\n$e');
      },
    );
  }

  Future<void>? cancelStreamSubscriptions() {
    return _shortcutsSub?.cancel();
  }

  @override
  void dispose() {
    cancelStreamSubscriptions();
    super.dispose();
  }
}
