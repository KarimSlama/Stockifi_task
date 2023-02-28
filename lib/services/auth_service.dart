import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/models/response.dart';
import 'package:stocklio_flutter/services/organization_service.dart';
import 'package:stocklio_flutter/utils/logger_util.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';

import 'admin_service.dart';

abstract class AuthService {
  Stream<User?> authStateChanges();
  Stream<User?> userChanges();
  Future<Response<User?>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<Response<User?>> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<Response> signOut();
  User? get currentFirebaseUser;
  String? get uid;
}

class AuthServiceImpl implements AuthService {
  late final FirebaseAuth _firebaseAuth;
  late final AdminService _adminService;
  late final OrganizationService _organizationService;

  AuthServiceImpl({
    FirebaseAuth? firebaseAuth,
    AdminService? adminService,
    OrganizationService? organizationService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _adminService = adminService ?? GetIt.instance<AdminService>(),
        _organizationService =
            organizationService ?? GetIt.instance<OrganizationService>();

  @override
  String? get uid =>
      _organizationService.selectedSubsidiaryId ??
      _adminService.selectedProfileId ??
      _firebaseAuth.currentUser?.uid;

  @override
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  @override
  Stream<User?> userChanges() {
    return _firebaseAuth.userChanges();
  }

  @override
  Future<Response<User?>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    UserCredential? userCredential;
    String? responseMessage;
    var hasError = false;

    try {
      userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      responseMessage = 'Login successful';
    } on FirebaseAuthException catch (error, stackTrace) {
      responseMessage = 'Invalid username or password';
      hasError = true;
      logger.e(
          'AuthService - FirebaseAuthException signInWithEmailAndPassword failed with code ${error.code}');
      SentryUtil.log(
          'AuthService.signInWithEmailAndPassword() FirebaseAuthException error: email $email, password $password, errorCode ${error.code}',
          'AuthService class',
          error,
          stackTrace);
    } catch (error, stackTrace) {
      logger.e('AuthService - signInWithEmailAndPassword failed');
      responseMessage = 'Please try again later';
      hasError = true;
      SentryUtil.error(
          'AuthService.signInWithEmailAndPassword() error: userCredential $userCredential',
          'AuthService class',
          error,
          stackTrace);
    }

    return Response<User?>(
      message: responseMessage,
      data: userCredential?.user,
      hasError: hasError,
    );
  }

  @override
  Future<Response<User?>> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    UserCredential? credential;
    String? responseMessage;
    var hasError = false;

    try {
      credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error, stackTrace) {
      logger.e(
          'AuthService - FirebaseAuthException createUserWithEmailAndPassword failed');
      responseMessage = 'Please try again later';
      hasError = true;
      SentryUtil.error(
          'AuthService.createUserWithEmailAndPassword() FirebaseAuthException error: email $email, password $password',
          'AuthService class',
          error,
          stackTrace);
    } catch (error, stackTrace) {
      logger.e('AuthService - createUserWithEmailAndPassword failed');
      responseMessage = 'Please try again later';
      hasError = true;
      SentryUtil.error(
          'AuthService.createUserWithEmailAndPassword() error: email $email, password $password',
          'AuthService class',
          error,
          stackTrace);
    }

    return Response<User?>(
      data: credential?.user,
      message: responseMessage,
      hasError: hasError,
    );
  }

  @override
  Future<Response> signOut() async {
    String? responseMessage;
    var hasError = false;

    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (error, stackTrace) {
      logger.e('AuthService - FirebaseAuthException signOut failed');
      responseMessage = 'Please try again later';
      hasError = true;
      SentryUtil.error('AuthService.signOut() FirebaseAuthException error',
          'AuthService class', error, stackTrace);
    } catch (error, stackTrace) {
      logger.e('AuthService - signOut failed');
      responseMessage = 'Please try again later';
      hasError = true;
      SentryUtil.error('AuthService.signOut() error', 'AuthService class',
          error, stackTrace);
    }

    return Response(
      message: responseMessage,
      hasError: hasError,
    );
  }

  @override
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  // @override
  // String? get uid => _firebaseAuth.currentUser?.uid;
}
