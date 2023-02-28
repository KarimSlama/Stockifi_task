import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
// ignore: depend_on_referenced_packages
import 'package:cloud_functions_platform_interface/src/platform_interface/platform_interface_firebase_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocklio_flutter/models/count.dart';
import 'package:stocklio_flutter/services/admin_service.dart';
import 'package:stocklio_flutter/services/auth_service.dart';
import 'package:stocklio_flutter/services/count_service.dart';
import 'package:stocklio_flutter/services/organization_service.dart';

void main() {
  late FirebaseFirestore firestore;
  late FirebaseAuth firebaseAuth;
  late FirebaseFunctions firebaseFunctions;
  late AuthService authService;
  late CountService countService;

  setUp(() async {
    // A FakeFirebaseFirestore instance
    firestore = FakeFirebaseFirestore();
    // A MockFirebaseAuth instance
    firebaseAuth = MockFirebaseAuth();
    firebaseFunctions = MockFirebaseFunctions();

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
    countService = CountServiceImpl(
      firestore: firestore,
      authService: authService,
      functions: firebaseFunctions,
    );

    // An already existing user document
    await firestore.doc('users/${authService.uid}').set(
      {
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  });

  test('Create count service works', () async {
    final response = await countService.createCount(Count(state: 'started'));

    expect(response.hasError, false);
    expect(response.data, isNotNull);
  });

  test('Update count service works', () async {
    final count = await countService.createCount(Count(state: 'started'));
    final newCount = Count(state: 'pending');

    final response =
        await countService.updateCount(newCount.copyWith(id: count.data));

    expect(response.hasError, false);
    expect(response.data, isNotNull);
  });

  test('Soft delete count service works', () async {
    final count = await countService.createCount(Count(state: 'started'));

    final response = await countService.softDeleteCount(count.data!);

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });
}

class MockFirebaseFunctions implements FirebaseFunctions {
  @override
  // TODO: implement app
  FirebaseApp get app => throw UnimplementedError();

  @override
  // TODO: implement delegate
  FirebaseFunctionsPlatform get delegate => throw UnimplementedError();

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    // TODO: implement httpsCallable
    throw UnimplementedError();
  }

  @override
  // TODO: implement pluginConstants
  Map get pluginConstants => throw UnimplementedError();

  @override
  void useFunctionsEmulator(String host, int port) {
    // TODO: implement useFunctionsEmulator
  }
}
