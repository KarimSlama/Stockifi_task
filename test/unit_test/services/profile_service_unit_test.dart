import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocklio_flutter/models/profile.dart';
import 'package:stocklio_flutter/services/admin_service.dart';
import 'package:stocklio_flutter/services/auth_service.dart';
import 'package:stocklio_flutter/services/organization_service.dart';
import 'package:stocklio_flutter/services/profile_service.dart';

void main() {
  late FirebaseFirestore firestore;
  late FirebaseAuth firebaseAuth;
  late AuthService authService;
  late ProfileService profileService;

  setUp(() async {
    // A FakeFirebaseFirestore instance
    firestore = FakeFirebaseFirestore();
    // A MockFirebaseAuth instance
    firebaseAuth = MockFirebaseAuth();
    await firebaseAuth.signInAnonymously();

    // Mocks of admin service and organization service
    final adminService = MockAdminService();
    final organizationService = MockOrganizationService();

    // An AuthService instance with a fake Firestore instance
    authService = AuthServiceImpl(
      firebaseAuth: firebaseAuth,
      adminService: adminService,
      organizationService: organizationService,
    );
    // An InvoiceService instance with a fake Firestore instance and AuthService instance
    profileService = ProfileServiceImpl(
      authService: authService,
      firestore: firestore,
    );
  });

  test('Profile should be updated from profile service', () async {
    final profile = Profile(
      id: '123',
      email: 'test@email.com',
      name: 'Test Name',
    );

    final docRef = firestore.doc('users/${firebaseAuth.currentUser?.uid}');

    await docRef.set(profile.toJson());

    final response =
        await profileService.updateProfile(profile.copyWith(name: 'New Name'));

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });
}
