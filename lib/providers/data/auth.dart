// Flutter Packages
import 'dart:async';
import 'package:flutter/foundation.dart';

// 3rd-Party Packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/models/response.dart';
import 'package:stocklio_flutter/utils/analytics_util.dart';
import 'package:stocklio_flutter/utils/logger_util.dart';

// Services
import '../../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  late final AuthService _authService;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? GetIt.instance<AuthService>();

  final StreamController<IdTokenResult?> _idTokenResultController =
      StreamController.broadcast();

  Stream get idTokenResultStream => _idTokenResultController.stream;

  // States
  IdTokenResult? _idTokenResult;
  bool _isLoading = true;
  bool _isInit = false;
  StreamSubscription<User?>? _userStreamSub;
  User? _user;

  // Getters
  bool get isLoading => _isLoading;
  bool get isInit => _isInit;

  Future<void>? cancelStreamSubscriptions() {
    return _userStreamSub?.cancel();
  }

  User? get user {
    _userStreamSub ?? _listenToUserStreamSub();
    return _user;
  }

  bool get isAdmin {
    if (_idTokenResult == null) {
    } else {
      final claims = _idTokenResult!.claims ?? {};
      if (claims.containsKey('admin')) {
        return claims['admin'];
      }

      if (claims.containsKey('dev')) {
        return true;
      }
    }

    return false;
  }

  bool get isOrg {
    if (_idTokenResult == null) {
    } else {
      final claims = _idTokenResult!.claims ?? {};
      if (claims.containsKey('organization')) {
        return claims['organization'];
      }
    }

    return false;
  }

  void _listenToUserStreamSub() {
    _userStreamSub = _authService.authStateChanges().listen(
      (user) async {
        _user = user;

        if (!_isInit) {
          _isInit = true;
          _isLoading = false;
        }

        if (user == null) {
          _resetIdTokenResult();
        } else {
          await _getIdTokenResult();
        }

        logger.i('PROVIDER - _listenToNotificationStream is successful');

        notifyListeners();
      },
      onError: (e) {
        logger.e('PROVIDER - _listenToUserStreamSub failed\n$e');
      },
    );
  }

  Stream<User?> authStateChanges() {
    return _authService.authStateChanges();
  }

  Stream<User?> userChanges() {
    return _authService.userChanges();
  }

  Future<Response<User?>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final response = await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return response;
  }

  Future<void> _getIdTokenResult() async {
    _idTokenResult ??=
        await _authService.currentFirebaseUser?.getIdTokenResult();

    _idTokenResultController.add(_idTokenResult!);
  }

  Future<Response<User?>> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final response = await _authService.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    return response;
  }

  Future<void> signOut() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await Analytics.logEvent('logout', user.uid, user.email);
    }
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  void _resetIdTokenResult() {
    _idTokenResult = null;
    _idTokenResultController.add(null);
  }
}
