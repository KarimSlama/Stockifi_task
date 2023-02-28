import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocklio_flutter/services/admin_service.dart';
import 'package:stocklio_flutter/services/auth_service.dart';
import 'package:stocklio_flutter/services/organization_service.dart';

void main() async {
  late FirebaseAuth firebaseAuth;
  late AuthService authService;

  setUp(() async {
    // A MockFirebaseAuth instance
    firebaseAuth = MockFirebaseAuth();

    // Mocks of admin service and organization service
    final adminService = MockAdminService();
    final organizationService = MockOrganizationService();

    // An AuthService instance with a fake Firestore instance
    authService = AuthServiceImpl(
      firebaseAuth: firebaseAuth,
      adminService: adminService,
      organizationService: organizationService,
    );
    // An ItemService instance with a fake Firestore instance and AuthService instance
  });

  test('Sign in with email and password service works', () async {
    final response = await authService.signInWithEmailAndPassword(
        email: 'demo4@stockl.io',
        password: r'$XQYBnhY9HUikibhX%bO@94!Ud@o7WvU32y5GK1B');

    expect(response, isNotNull);
    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });

  test('Sign out service works', () async {
    final response = await authService.signOut();

    expect(response, isNotNull);
    expect(response.hasError, false);
  });
}
